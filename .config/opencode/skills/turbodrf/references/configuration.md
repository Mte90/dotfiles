<!-- Loaded on demand from ../SKILL.md -->

# Configuration Reference

## Model Meta Options

All options available in the `turbodrf()` classmethod:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | bool | `True` | Enable/disable API for this model |
| `endpoint` | str | model name | Custom endpoint name |
| `fields` | list/dict | `__all__` | Fields to expose (list or `{list: ..., detail: ...}`) |
| `public_access` | bool | `False` | Allow unauthenticated GET requests |
| `lookup_field` | str | `pk` | URL lookup field (`pk` or `slug`) |
| `compiled` | bool | `True` | Use compiled read path for performance |
| `visibility` | list | `None` | Predicate list for row-level access |
| `tenant_field` | str | `None` | Tenant ForeignKey field (mandatory for shared tenants) |
| `owner_field` | str | `None` | Owner ForeignKey field (within-tenant rule) |
| `bypass_owner_roles` | list | `[]` | Roles that skip the owner check |
| `tenancy` | str | `None` | Set to `'shared'` for reference data (no tenant scope) |
| `read_only` | bool | `False` | Restrict to GET endpoints only |
| `http_methods` | list | `None` | Whitelist specific HTTP methods |
| `full_clean` | bool | `False` | Run `model.full_clean()` before save |
| `actions` | list | `[]` | Custom actions (v0.5.0+) |

## Settings Reference

All `settings.py` configuration options:

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `TURBODRF_ROLES` | dict | `{}` | Role-based permissions mapping |
| `TURBODRF_DISABLE_PERMISSIONS` | bool | `False` | Disable all permissions (development) |
| `TURBODRF_USE_DEFAULT_PERMISSIONS` | bool | `False` | Use Django default permissions |
| `TURBODRF_PERMISSION_MODE` | str | `'static'` | Permission mode (`'static'` or `'database'`) |
| `TURBODRF_PERMISSION_CACHE_TIMEOUT` | int | `300` | Permission cache TTL in seconds |
| `TURBODRF_TENANT_MODEL` | str | `None` | Default tenant model path |
| `TURBODRF_TENANT_USER_FIELD` | str | `None` | User field pointing to tenant |
| `TURBODRF_SENSITIVE_FIELDS` | list | `[]` | Fields hidden from all users |
| `TURBODRF_ENABLE_DOCS` | bool | `True` | Enable Swagger/ReDoc documentation |
| `TURBODRF_MAX_NESTING_DEPTH` | int | `3` | Maximum nested field depth |
| `TURBODRF_USE_FILTERS` | bool | `True` | Enable Django filters |
| `TURBODRF_DEFAULT_PAGE_SIZE` | int | `None` | Default pagination page size |

## Startup Safety Gates

TurboDRF runs 6 startup safety passes. Each has a kill-switch:

| Gate | Description | Kill-switch |
|------|-------------|-------------|
| Tenancy declaration | Every model declares `tenant_field`/`visibility`/`tenancy: 'shared'` | `TURBODRF_REQUIRE_TENANCY=False` |
| Compiled-path FK safety | Validates FK annotations can't bypass predicates | `TURBODRF_ALLOW_UNSAFE_COMPILED_FK=True` |
| Compiled-path M2M safety | Validates M2M target traversal | `TURBODRF_ALLOW_UNSAFE_COMPILED_M2M=True` |
| Filter traversal safety | Validates searchable fields can't leak via filter joins | `TURBODRF_ALLOW_UNSAFE_FILTER_TRAVERSAL=True` |
| Custom predicate write-safety | `Custom`/`Conditional` must carry explicit `write_validator` | `TURBODRF_ALLOW_UNSAFE_CUSTOM_WRITE=True` |
| Permission string typo check | Catches typos in `TURBODRF_ROLES` with difflib suggestions | `TURBODRF_ALLOW_UNKNOWN_PERMISSIONS=True` |

Additional settings:
- `TURBODRF_MAX_FILTER_VALUE_LENGTH` (default 1000) — caps filter value length
- `TURBODRF_LOG_UNRESTRICTED_CUSTOM` (default `True`) — logs when unrestricted custom predicates run
