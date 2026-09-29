<!-- This file is loaded on demand from frameworks/django/SKILL.md -->

## Django Tasks Framework (Django 6.0+)

Django 6.0 introduced a built-in tasks framework - an abstraction without a production-ready worker.

### Define a Task

```python
from django.tasks import task

@task(priority=2, queue_name="emails", backend="default")
def send_welcome_email(user_id):
    user = User.objects.get(id=user_id)
    send_mail("Welcome!", "Thanks for signing up.", "noreply@example.com", [user.email])
```

**Parameters:**
- `priority` (int): -100 to 100, defaults to 0
- `queue_name` (str): defaults to "default"
- `backend` (str): backend alias
- `takes_context` (bool): whether function accepts TaskContext

### Enqueue the Task

```python
# Synchronous
send_welcome_email.enqueue(user_id=user.id)

# Asynchronous
await send_welcome_email.aenqueue(user_id=user.id)
```

### Built-in Backends (Development Only)

| Backend | Behavior | Use Case |
| ------- |----------|----------|
| `ImmediateBackend` (default) | Runs synchronously | Development |
| `DummyBackend` | Stores without executing | Testing |

### Production: django-tasks-local

```python
# settings.py
INSTALLED_APPS = ["django_tasks_local"]

TASKS = {
    "default": {
        "BACKEND": "django_tasks_local.ThreadPoolBackend",
        "OPTIONS": {"MAX_WORKERS": 10}
    }
}
```

**When to use Django Tasks vs Celery:**

- **Django Tasks**: Fire-and-forget, no infrastructure (emails, webhooks, MVPs)
- **Celery**: Scheduled tasks, retries, persistence, distributed processing

---


---

## Django 6.0 Essentials

### Middleware Changes

- **CommonMiddleware deprecated** → Use `StaticFileMiddleware` for static file serving
- **CSP nonce improvements** - Built-in nonce support via `{% csp_nonce %}` template tag

### Test Client

- **`django.test.Client` class removed** → Use `LiveServerTestCase` for integration tests

### Static Files

- **`STATICFILES_STORAGE` removed** → Use `STORAGES` dict:
```python
STORAGES = {
    "staticfiles": {
        "BACKEND": "django.contrib.staticfiles.storage.ManifestStaticFilesStorage"
    }
}
```

### Tasks Framework (NEW - replacing Celery for simple needs)

```python
from django.tasks import task

@task
def send_email_task(user_id):
    # Background work
    pass

# Enqueue
send_email_task.enqueue(user.id)

# settings.py
TASKS = {
    "default": {"BACKEND": "django_tasks.backends.database.DatabaseBackend"},
}
```

### CSP (Content Security Policy) - Built-in

```python
MIDDLEWARE = ["django.middleware.csp.ContentSecurityPolicyMiddleware"]

SECURE_CSP_REPORT_ONLY = {
    "script-src": ["'self'", "'nonce-{{ csp_nonce }}'"],
    "object-src": ["'none'"],
}
```

### Dynamic Field Refresh on Save() - NO more refresh_from_db()

```python
# Now works automatically with GeneratedField and expressions
video = Video.objects.get(id=1)
video.title = "New"
video.save()
print(video.full_title)  # Already updated! No refresh_from_db() needed
```

Uses `RETURNING` clause (SQLite, PostgreSQL, Oracle).

---


---

## Multi-Database Routing

Django supports multiple databases via `DATABASES['alias']`, `.using('alias')`, and `db_manager('alias')`. Use this for read-only replicas, external/legacy data sources, and per-app database isolation instead of reaching for SQLAlchemy.

### Router class

A `Router` decides which database each model uses for reads, writes, relation checks, and migrations. **`allow_relation` must return a boolean** — returning `None` silently breaks relation checks and produces subtle `ValueError` in admin and serializers.

```python
# settings.py
DATABASES = {
    "default": {"ENGINE": "django.db.backends.postgresql", "NAME": "billing"},
    "data_source": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "legacy",
        "OPTIONS": {"options": "-c default_transaction_read_only=on"},
    },
}

DATABASE_ROUTERS = ["myapp.routers.Router"]
```

```python
# myapp/routers.py
class Router:
    route_app_labels = {"data_source"}

    def db_for_read(self, model, **hints):
        if model._meta.app_label in self.route_app_labels:
            return "data_source"
        return None

    def db_for_write(self, model, **hints):
        if model._meta.app_label in self.route_app_labels:
            raise RuntimeError("data_source is read-only")
        return None

    def allow_relation(self, obj1, obj2, **hints):
        # MUST return True/False, never None, when models span databases
        db_set = {obj1._state.db, obj2._state.db}
        if db_set <= {"default", "data_source"}:
            return True
        return None

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        if app_label in self.route_app_labels:
            return db == "data_source"
        return db == "default"
```

### Querying an external database

```python
from django.db import connections

# Raw SQL on the external DB
with connections["data_source"].cursor() as cursor:
    cursor.execute("SELECT id, name FROM legacy_customers")
    rows = cursor.fetchall()

# ORM on a model bound to the external DB via Router
LegacyCustomer.objects.using("data_source").filter(active=True)

# Manager scoped to a specific DB
class LegacyCustomerManager(models.Manager):
    def get_queryset(self):
        return super().get_queryset().using("data_source")

db_manager("data_source")  # alternative for managers that need DB-level operations
```

### Migrations on a non-default database

```bash
python manage.py migrate --database=data_source
python manage.py makemigrations myapp
python manage.py sqlmigrate myapp 0001 --database=data_source
```

### Testing pitfall: module-level `connections` import

When a management command does `from django.db import connections` at module load time, a test that patches `django.db.connections` globally does **not** reach the command's local reference. Patch the module's own attribute instead:

```python
# WRONG — the command already bound `connections` at import time
@patch("django.db.connections", mock_connections)

# RIGHT — patch the name the command actually uses
@patch("cron.management.commands.import_legacy_data.connections", mock_connections)
```

`patch.object` cannot mock dunder methods (`__getitem__`) on an instance; target the class or substitute a wrapper dict that defines `__getitem__`.

---


---

## Model Field Conventions

### `null=True` on string fields is an anti-pattern

`CharField`, `TextField`, `SlugField`, `EmailField` with `null=True` produce two distinct "empty" representations (`NULL` and `""`) and break `__exact` lookups. Ruff rule DJ001 flags this. Use `blank=True, default=""` instead:

```python
# WRONG
notes = models.TextField(null=True, blank=True)

# RIGHT
notes = models.TextField(blank=True, default="")
code = models.CharField(max_length=20, blank=True, default="")
```

Removing `null=True` from an existing field requires a migration and updating any test that asserted `None` — it now receives `""`.

### `auto_now_add=True` fields cannot be set at creation

A `DateTimeField(auto_now_add=True)` populates on first `save()` and ignores any value passed to the constructor. To set a specific timestamp in tests, save first, then update:

```python
issued_at = models.DateTimeField(auto_now_add=True)

# In tests — the value passed here is discarded
invoice = Invoice(customer=c, issued_at=some_time)
invoice.save()
invoice.issued_at = some_time
invoice.save()
```

---


---

## App Naming: Check for Package Collisions at Creation Time

Before running `startapp`, check that the chosen app name does not collide with an installed third-party package or a well-known PyPI package (app label or import path). A local app that shadows an external package breaks imports in ways that surface late — in admin, serializers, or migrations.

```bash
pip index versions <candidate-name> 2>/dev/null || pip show django-<candidate-name>
python -c "import <candidate_name>"  # must fail with ModuleNotFoundError
```

If the name is taken, prefix it with a project-specific namespace (e.g. `<project>_<feature>`) from the start — renaming an app later means updating `INSTALLED_APPS`, `AppConfig.label`, every import, and the DB tables.

---


