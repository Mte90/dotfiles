<!-- Loaded on demand from ../SKILL.md -->

# Permissions & Tenancy

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
```

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