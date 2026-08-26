---
name: turbodrf
description: "TurboDRF - fast Django REST framework with automatic OpenAPI, serializers, views, routers, and caching"
metadata:
  author: mte90
  version: 1.1.0
  tags:
    - python
    - django
    - rest-api
    - openapi
    - serializers
    - caching
---

# turbodrf

**TurboDRF** - Dead simple Django REST API generator with role-based permissions

Turn your Django models into fully-featured REST APIs with a mixin and a configuration method. Zero boilerplate.

## Overview

TurboDRF is a Django REST Framework mixin-based library that automatically generates CRUD API endpoints for your models. Unlike traditional DRF setups requiring ViewSets and serializers, TurboDRF uses a simple mixin pattern where you declare your model inherits from `TurboDRFMixin` and define a `turbodrf()` configuration method.

**Key Features:**
- Automatic CRUD endpoints from model declaration
- Role-based access control (RBAC)
- Field-level permissions
- Built-in search, filtering, ordering, and pagination
- Nested field support for relationships
- Client-side field selection (`?fields=`)
- Auto-generated API documentation (Swagger UI, ReDoc)
- Performance optimizations with compiled read path
  - Security: sensitive fields deny-list, FK injection defense, startup safety gates

## Installation

### PyPI

```bash
pip install turbodrf

# Optional: faster JSON rendering (7x faster than stdlib)
pip install turbodrf[fast]
```

### GitHub

```bash
pip install git+https://github.com/AlexanderCollins/TurboDRF.git
```

### Requirements

- Python >=3.10 (tested: 3.10, 3.11, 3.12, 3.13, 3.14)
- Django >=4.2 (tested: 4.2, 5.2, 6.0)
- Django REST Framework >=3.14.0
- drf-yasg >=1.21.0, django-filter >=23.0
- Optional extras: `turbodrf[fast]` (msgspec/orjson ~7x faster JSON), `turbodrf[allauth]` (django-allauth >=0.57.0)

Verified against TurboDRF v0.5.1 (2026-07-12).
## Quick Start

### 1. Add to `INSTALLED_APPS`

```python
# settings.py
INSTALLED_APPS = [
    # Django apps
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    
    # Third-party apps
    'rest_framework',
    'django_filters',
    
    # TurboDRF
    'turbodrf',
    
    # Your apps
    'myapp',
]
```

### 2. Add the mixin to your model

```python
# myapp/models.py
from django.db import models
from turbodrf.mixins import TurboDRFMixin

class Book(models.Model, TurboDRFMixin):
    title = models.CharField(max_length=200)
    author = models.CharField(max_length=100)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    published_date = models.DateField()
    
    # Define searchable fields
    searchable_fields = ['title', 'author']
    
    @classmethod
    def turbodrf(cls):
        return {
            'fields': ['title', 'author', 'price', 'published_date']
        }
```

### 3. Add the router

```python
# urls.py
from django.contrib import admin
from django.urls import path, include
from turbodrf.router import TurboDRFRouter

router = TurboDRFRouter()

urlpatterns = [
    # Admin
    path('admin/', admin.site.urls),

    # API with auto-configured documentation
    path('api/', include(router.urls)),
]
```

### 4. Configure TurboDRF roles

```python
# settings.py
TURBODRF_ROLES = {
    'admin': [
        # Model-level permissions
        'myapp.book.read',
        'myapp.book.create',
        'myapp.book.update',
        'myapp.book.delete',
        
        # Field-level permissions
        'myapp.book.price.read',
        'myapp.book.price.write',
    ],
    'editor': [
        'myapp.book.read',
        'myapp.book.update',
        'myapp.book.price.read',  # Read-only access to price
    ],
    'viewer': [
        'myapp.book.read',
        # No access to price field
    ]
}
```

### 5. Extend User Model with Roles

```python
# myapp/apps.py
from django.apps import AppConfig
from django.contrib.auth import get_user_model

class MyAppConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'myapp'
    
    def ready(self):
        User = get_user_model()
        
        def get_user_roles(self):
            # Example: Use Django groups as roles
            return [group.name for group in self.groups.all()]
        
        if not hasattr(User, 'roles'):
            User.add_to_class('roles', property(get_user_roles))
```

**Done!** You now have a full REST API at `/api/` with:

```
GET    /api/books/                          # List all books
POST   /api/books/                          # Create a new book
GET    /api/books/1/                        # Get a specific book
PUT    /api/books/1/                        # Update a book
DELETE /api/books/1/                        # Delete a book
```

**Query parameters:**
```
GET /api/books/?search=django              # Search
GET /api/books/?author__name=Smith         # Filter
GET /api/books/?ordering=-price            # Order
GET /api/books/?page=2&page_size=10        # Paginate
GET /api/books/?fields=title,price         # Client field selection
```

## Model Configuration

### Basic Configuration

```python
@classmethod
def turbodrf(cls):
    return {
        'enabled': True,              # Enable/disable API (default: True)
        'endpoint': 'books',          # Custom endpoint name (default: pluralized model name)
        'fields': ['title', 'author'], # Fields to expose (see below)
        'public_access': False,       # Allow unauthenticated GET (default: False)
        'lookup_field': 'pk',         # URL lookup field (default: 'pk', or 'slug')
        'compiled': True,             # Use compiled read path (default: True)
    }
```

### Fields Specification

**All database fields:**
```python
'fields': '__all__'
```

**Specific fields (same for list and detail):**
```python
'fields': ['title', 'author', 'price']
```

**Different fields for list vs detail:**
```python
'fields': {
    'list': ['title', 'author', 'price'],
    'detail': ['title', 'description', 'author', 'author__email', 'price']
}
```

### Nested Fields

Access related model fields with `__` notation:

```python
'fields': [
    'title',
    'author__name',              # ForeignKey (1 level)
    'author__publisher__name',   # Multi-level (2 levels)
    'tags__name',               # ManyToMany
]
```

FK fields are flattened in responses (`author__name` becomes `author_name`). M2M fields are arrays of objects:

```json
{
    "title": "Django for APIs",
    "author_name": "William Vincent",
    "tags": [{"name": "Python"}, {"name": "Django"}]
}
```

Maximum nesting depth is 3 by default. Change with `TURBODRF_MAX_NESTING_DEPTH` in settings.

### Property Fields

Model `@property` methods work in the compiled path:

```python
class Book(models.Model, TurboDRFMixin):
    title = models.CharField(max_length=200)
    price = models.DecimalField(max_digits=10, decimal_places=2)

    @property
    def display_title(self):
        return self.title.upper()

    @classmethod
    def turbodrf(cls):
        return {
            'fields': ['title', 'price', 'display_title']
        }
```

Properties that access related objects (e.g., `self.author.name`) won't work in the compiled path — use `author__name` in the field config instead.

### List/Detail Field Separation

```python
class Book(models.Model, TurboDRFMixin):
    title = models.CharField(max_length=200)
    author = models.CharField(max_length=100)
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    
    @classmethod
    def turbodrf(cls):
        return {
            'fields': {
                'list': ['title', 'author', 'price'],
                'detail': ['title', 'author', 'description', 'price']
            }
        }
```

## Permissions

### Permission Modes

TurboDRF supports three permission modes:

1. **No permissions (development):**
   ```python
   TURBODRF_DISABLE_PERMISSIONS = True
   ```

2. **Django default permissions:**
   ```python
   TURBODRF_USE_DEFAULT_PERMISSIONS = True
   ```

3. **Role-based permissions (default):**
   ```python
   TURBODRF_ROLES = {
       'admin': [
           'myapp.book.read',
           'myapp.book.create',
           'myapp.book.update',
           'myapp.book.delete',
           'myapp.book.price.read',
           'myapp.book.price.write',
       ],
       'editor': [
           'myapp.book.read',
           'myapp.book.update',
           'myapp.book.price.read',
       ],
       'viewer': [
           'myapp.book.read',
       ]
   }
   ```

### Permission Format

- Model-level: `app_label.model_name.action` (read, create, update, delete)
- Field-level: `app_label.model_name.field_name.read` or `.write`

### Field Permissions

1. If ANY role defines an explicit field rule (e.g., `price.read`), that field requires explicit permission for ALL roles
2. Fields without explicit rules fall back to model-level permission
3. To restrict `price` for viewers, add `price.read` to at least one role (like admin)

### How It Works

TurboDRF reads `user.roles` — a property that returns a list of role names:

```python
# From Django groups
User.add_to_class('roles', property(lambda self: [g.name for g in self.groups.all()]))

# From a JSONField
class User(AbstractUser):
    user_roles = models.JSONField(default=list)

    @property
    def roles(self):
        return self.user_roles
```

Authenticated users with no roles get 403 on all endpoints.

### Database-Backed Permissions

For runtime changes without redeployment:

```python
TURBODRF_PERMISSION_MODE = 'database'
TURBODRF_PERMISSION_CACHE_TIMEOUT = 300  # 5 minutes

from turbodrf.models import TurboDRFRole, RolePermission, UserRole

role = TurboDRFRole.objects.create(name='editor')
RolePermission.objects.create(role=role, app_label='books', model_name='book', action='read')
UserRole.objects.create(user=user, role=role)
```

### Nested Field Permissions

Permissions are checked at each level of a nested field path. For `author__publisher__name`:

1. Can user read `author` on Book?
2. Can user read `publisher` on Author?
3. Can user read `name` on Publisher?

If any level fails, the field is excluded.

### Filter Permissions

Users can only filter on fields they have read permission for. Filters on hidden fields are silently ignored.

### Custom Actions (v0.5.0)

TurboDRF supports custom actions attached to a model's config, inheriting tenant and predicate scoping:

```python
from turbodrf.decorators import turbodrf_action

class Book(models.Model, TurboDRFMixin):
    @classmethod
    def turbodrf(cls):
        return {
            'actions': [
                turbodrf_action(detail=True, methods=["post"], url_path="resend")(cls.resend)
            ],
        }

    def resend(self, request):
        # tenant-scoped; predicate stack enforced
        ...
```

### Read-Only and HTTP Method Control (v0.5.0)

- `read_only: True` — restricts a model to GET endpoints only
- `http_methods: ['list', 'retrieve']` — whitelist specific HTTP methods
- `full_clean: True` — runs `model.full_clean()` before save

### Computed Fields on Both Read Paths (v0.5.0)

`@property` fields work on both the standard and compiled read paths via `DictProxy`. Models with unsupported fields (GenericFK) auto-fallback to the serializer path.

### Strict Swagger Role Preview (v0.5.0)

The `?role=` query parameter is honored in Swagger only for roles the caller actually holds. A user cannot preview another role's permissions.
## Tenancy & Row-Level Access

### Multi-Tenant SaaS

```python
class Project(models.Model, TurboDRFMixin):
    workspace = models.ForeignKey(Workspace, on_delete=models.CASCADE)
    owner = models.ForeignKey(User, on_delete=models.CASCADE)

    @classmethod
    def turbodrf(cls):
        return {
            'tenant_field': 'workspace',          # mandatory wall
            'owner_field': 'owner',               # within-tenant rule
            'bypass_owner_roles': ['manager', 'admin'],  # roles ignore owner check
            'fields': ['title', 'workspace', 'owner'],
        }

```python
TURBODRF_TENANT_MODEL = 'accounts.Workspace'
TURBODRF_TENANT_USER_FIELD = 'workspace'  # request.user.workspace → tenant
```

### Request Flow

A request `GET /api/projects/` from Alice (member at ABC workspace) goes through:

1. **Permission gate** — Alice's role `member` has `app.project.read`. Pass.
2. **Tenant filter** (mandatory, applied first, never bypassable): `WHERE project.workspace_id = <Alice's workspace>`
3. **Owner filter** (Alice has no bypass role, so this layer applies): `AND project.owner_id = <Alice's user id>`
4. **Field stripping** — Alice's role has read on `title`, `workspace`, `owner` but maybe not all configured fields. Hidden ones are removed from the response.

### Quick Recipes

```python
# Multi-tenant SaaS — most common case
{'tenant_field': 'store', 'owner_field': 'customer', 'bypass_owner_roles': ['staff']}

# Personal data app (no tenant)
{'owner_field': 'author', 'bypass_owner_roles': ['admin']}

# Reference data (currencies, country codes — not tenant-scoped)
{'tenancy': 'shared'}

# M2M membership (Slack channels, Linear projects)
{'visibility': [Tenant('workspace'), Members('participants')]}

# Power-form composition (when sugar doesn't fit)
{'visibility': [Tenant('workspace'), Either(Owner('owner'), Members('shared_with'))]}
```

See `docs/tenancy.md` for the full predicate vocabulary, hard-fail-at-startup behavior, and 404-vs-403 semantics.

### Full Predicate Vocabulary (v0.4.0+)

Predicate primitives in `turbodrf.predicates`:

- `Tenant(field='tenant')` — mandatory tenant boundary, applied as AND outside the algebra (OR-composition can never escape it)
- `Owner(field='owner')` — row belongs to `request.user`
- `Members(field='members')` — row's M2M members contains user (read-only: raises `NotImplementedError` on writes)
- `Group(field='group')` — row's group field matches user's group (read-only: raises `NotImplementedError` on writes)
- `Either(left, right)` — logical OR of two predicates
- `Conditional(q_func, write_validator=...)` — custom predicate; `write_validator` is mandatory (read-only if omitted: raises `NotImplementedError` on writes)
- `Custom(q_func, write_validator=...)` — fully custom; `write_validator` required

> `Tenant()` inside `Either()` is prohibited — the tenant boundary must not be OR-able away.

## Security

### Sensitive Fields

Fields like `password`, `token`, and `secret_key` are never exposed:

```python
TURBODRF_SENSITIVE_FIELDS = [
    'password', 'password_hash', 'secret_key', 'api_key',
    'token', 'access_token', 'refresh_token', 'session_key',
]
```

### Fail-Closed Design

If a permission check fails due to an error, access is denied. TurboDRF never grants access on exception.

### Error Responses

```python
REST_FRAMEWORK = {
    'EXCEPTION_HANDLER': 'turbodrf.exceptions.turbodrf_exception_handler',
}
```

```json
{
    "error": {
        "status": 403,
        "code": "permission_denied",
        "message": "You do not have permission to perform this action."
    }
}
```

### Security Gates

TurboDRF runs 5 startup safety passes; each has a kill-switch setting:

1. **Tenancy declaration** — every model declares `tenant_field`/`visibility`/`tenancy: 'shared'` (kill-switch: `TURBODRF_REQUIRE_TENANCY=False`)
2. **Compiled-path FK safety** — validates FK annotations can't bypass predicates (kill-switch: `TURBODRF_ALLOW_UNSAFE_COMPILED_FK`)
3. **Compiled-path M2M safety** — validates M2M target traversal (kill-switch: `TURBODRF_ALLOW_UNSAFE_COMPILED_M2M`)
4. **Filter traversal safety** — validates searchable fields can't leak via filter joins (kill-switch: `TURBODRF_ALLOW_UNSAFE_FILTER_TRAVERSAL`)
5. **Custom predicate write-safety** — `Custom`/`Conditional` must carry explicit `write_validator` (kill-switch: `TURBODRF_ALLOW_UNSAFE_CUSTOM_WRITE`)
6. **Permission string typo check** — catches typos in `TURBODRF_ROLES` with difflib suggestions (kill-switch: `TURBODRF_ALLOW_UNKNOWN_PERMISSIONS`)

Additional protections:
- `Members`, `Group`, and `Conditional` predicates raise `NotImplementedError` on writes (read-only enforcement)
- `TURBODRF_MAX_FILTER_VALUE_LENGTH` (default 1000) caps filter value length
- `TURBODRF_LOG_UNRESTRICTED_CUSTOM` (default `True`) logs when unrestricted custom predicates run
- FK injection defense: every FK in create/update bodies validated against the target's predicate stack; cross-tenant targets return 400 indistinguishable from nonexistent

These gates refuse to boot if unsafe configurations are detected, preventing cross-permission read leaks.

## Documentation

Auto-generated Swagger UI and ReDoc:
- Swagger UI: `/api/swagger/`
- ReDoc: `/api/redoc/`

Disable in production:
```python
TURBODRF_ENABLE_DOCS = False
```

## Management Commands

```bash
# Validate configuration
python manage.py turbodrf_check

# Performance benchmark
python manage.py turbodrf_benchmark

# Explain query execution
python manage.py turbodrf_explain
```

## Settings Reference

Key settings:

| Setting | Description |
|---------|-------------|
| `TURBODRF_ROLES` | Role-based permissions dict |
| `TURBODRF_DISABLE_PERMISSIONS` | Disable all permissions |
| `TURBODRF_USE_DEFAULT_PERMISSIONS` | Use Django default permissions |
| `TURBODRF_PERMISSION_MODE` | 'static' or 'database' |
| `TURBODRF_PERMISSION_CACHE_TIMEOUT` | Permission cache TTL (seconds) |
| `TURBODRF_TENANT_MODEL` | Default tenant model |
| `TURBODRF_TENANT_USER_FIELD` | User's tenant field |
| `TURBODRF_SENSITIVE_FIELDS` | Fields to hide from all users |
| `TURBODRF_ENABLE_DOCS` | Enable Swagger/ReDoc |
| `TURBODRF_MAX_NESTING_DEPTH` | Max nested field depth |
| `TURBODRF_USE_FILTERS` | Enable Django filters |
| `TURBODRF_DEFAULT_PAGE_SIZE` | Default pagination page size |
| `TURBODRF_REQUIRE_TENANCY` | Force tenancy declaration on all models (default True) |
| `TURBODRF_ALLOW_UNSAFE_COMPILED_FK` | Kill-switch for compiled FK safety gate |
| `TURBODRF_ALLOW_UNSAFE_COMPILED_M2M` | Kill-switch for compiled M2M safety gate |
| `TURBODRF_ALLOW_UNSAFE_FILTER_TRAVERSAL` | Kill-switch for filter traversal safety gate |
| `TURBODRF_ALLOW_UNSAFE_CUSTOM_WRITE` | Kill-switch for custom predicate write-safety gate |
| `TURBODRF_ALLOW_UNKNOWN_PERMISSIONS` | Kill-switch for permission string typo check |
| `TURBODRF_MAX_FILTER_VALUE_LENGTH` | Max filter value length (default 1000) |
| `TURBODRF_LOG_UNRESTRICTED_CUSTOM` | Log unrestricted custom predicates (default True) |

## Examples

### Complete CRUD API

**models.py:**
```python
from django.db import models
from turbodrf.mixins import TurboDRFMixin

class Author(models.Model, TurboDRFMixin):
    name = models.CharField(max_length=100)
    email = models.EmailField()
    
    @classmethod
    def turbodrf(cls):
        return {
            'fields': ['name', 'email']
        }

class Book(models.Model, TurboDRFMixin):
    title = models.CharField(max_length=200)
    author = models.ForeignKey(Author, on_delete=models.CASCADE)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    
    @classmethod
    def turbodrf(cls):
        return {
            'fields': {
                'list': ['title', 'author__name'],
                'detail': ['title', 'author__name', 'author__email', 'price']
            }
        }
```

**settings.py:**
```python
INSTALLED_APPS = [
    'rest_framework',
    'turbodrf',
    'myapp',
]

TURBODRF_ROLES = {
    'admin': [
        'myapp.book.read',
        'myapp.book.create',
        'myapp.book.update',
        'myapp.book.delete',
        'myapp.book.price.read',
        'myapp.book.price.write',
    ],
    'editor': [
        'myapp.book.read',
        'myapp.book.update',
        'myapp.book.price.read',
    ],
    'viewer': [
        'myapp.book.read',
    ]
}
```

**urls.py:**
```python
from django.contrib import admin
from django.urls import path, include
from turbodrf.router import TurboDRFRouter

router = TurboDRFRouter()

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
]
```

## Best Practices

### 1. Use Meta Options

Define fields explicitly rather than `__all__` for better control.

### 2. Validate Input

Use Django's form validation or custom validators:

## Integrations

TurboDRF ships optional, experimental integrations (all settings-gated, marked experimental in docs):

- **Sentry** — security-event breadcrumbs
- **Keycloak** — role mapping (`STRICT_ROLES=True` default)
- **django-allauth** — group→role mapping (`pip install turbodrf[allauth]`)
- **drf-api-tracking** — request logging

Fast JSON: `pip install turbodrf[fast]` adds msgspec (~7x faster serialization; orjson auto-detected if present).

## AI Agent Guidance

The TurboDRF repository ships an `AGENTS.md` with canonical guidance for AI coding agents — the "what never to do" list (don't override `get_queryset`, don't use `Model.objects.all()` in custom actions, don't widen serializer fields, don't use `tenancy: 'shared'` as a test workaround) plus `invalidate_user_permissions()` cache API and testing patterns.

- **Repo AGENTS.md**: https://github.com/AlexanderCollins/TurboDRF/blob/main/AGENTS.md

> **Docs status:** The readthedocs and GitHub Pages sites are currently 404. The repo `docs/` folder is the only current documentation source.

## References

- **GitHub Repository**: https://github.com/AlexanderCollins/TurboDRF
- **PyPI Package**: https://pypi.org/project/turbodrf/
- **Documentation**: https://github.com/AlexanderCollins/TurboDRF/tree/main/docs
  - [Configuration](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/configuration.md)
  - [Permissions](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/permissions.md)
  - [Tenancy & row-level access](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/tenancy.md)
  - [Performance](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/performance.md)
  - [Filtering & Search](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/filtering.md)
  - [Integrations](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/integrations.md)
  - [Security](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/security.md)
  - [Management Commands](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/commands.md)
  - [Settings Reference](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/settings_reference.md)
- **AI Agent Guide (AGENTS.md)**: https://github.com/AlexanderCollins/TurboDRF/blob/main/AGENTS.md
def validate_title(value):
    if Book.objects.filter(title=value).exclude(pk=self.instance.pk).exists():
        raise serializers.ValidationError("Title already exists")
    return value
```

### 3. Use Permissions

Restrict access appropriately:

```python
TURBODRF_ROLES = {
    'public': ['myapp.book.read'],
    'staff': [
        'myapp.book.read',
        'myapp.book.create',
        'myapp.book.update',
        'myapp.book.delete',
    ],
}
```

### 4. Filter Usage

Users can only filter on fields they have read permission for.

### 5. Secure Sensitive Data

Always include sensitive fields in the deny-list:

```python
TURBODRF_SENSITIVE_FIELDS = [
    'password', 'token', 'api_key', 'secret_key',
]
```

## Troubleshooting

### Import Errors

If you get import errors, ensure TurboDRF is properly installed:

```bash
pip list | grep turbodrf
```

### No API Endpoints

If no endpoints appear, check that:
1. Your models inherit from `TurboDRFMixin`
2. Models have a `turbodrf()` classmethod
3. The model is not disabled (`'enabled': False`)

### Permission Denied

If you get 403 errors:
1. Check your user's roles
2. Verify role permissions in `TURBODRF_ROLES`
3. Ensure the User model has a `roles` property

### Compiled Path Safety Issues

If startup gate fires due to M2M/FK traversals:
- **Drop the path** from the parent's `turbodrf()` `fields` list
- **Set `'compiled': False`** on the parent model
- **Strip the target's row-level rules** if genuinely public
- **`TURBODRF_ALLOW_UNSAFE_COMPILED_M2M = True`** (not recommended)

## References

- **GitHub Repository**: https://github.com/AlexanderCollins/TurboDRF
- **PyPI Package**: https://pypi.org/project/turbodrf/
- **Documentation**: https://github.com/AlexanderCollins/TurboDRF/tree/main/docs
  - [Configuration](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/configuration.md)
  - [Permissions](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/permissions.md)
  - [Tenancy & row-level access](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/tenancy.md)
  - [Performance](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/performance.md)
  - [Filtering & Search](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/filtering.md)
  - [Integrations](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/integrations.md)
  - [Security](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/security.md)
  - [Management Commands](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/commands.md)
  - [Settings Reference](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/settings_reference.md)
