<!-- Loaded on demand from ../SKILL.md -->

# Security & Settings

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