<!-- This file is loaded on demand from frameworks/django-bolt/SKILL.md -->

## Authentication

### JWT Authentication (v0.9.1+)

```python
from django_bolt.auth import JWTAuthentication

# Cookie-based JWT (default, CSRF protection enabled)
api = BoltAPI(auth=[JWTAuthentication(cookie=True)])

# Bearer token (stateless, no CSRF)
api = BoltAPI(auth=[JWTAuthentication(cookie=False)])
```

### Asymmetric JWT (v0.9.1–v0.10.0)

Supports PS256/PS384/PS512 and EdDSA algorithms with JWKS:

```python
from django_bolt.auth import JWTAuthentication

# JWKS endpoint for public key retrieval
api = BoltAPI(
    auth=[JWTAuthentication(
        jwks_url="https://your-auth-server.com/.well-known/jwks.json",
        algorithm="RS256"  # or PS256, PS384, PS512, EdDSA
    )]
)
```

Works with Clerk, Auth0, Okta, and any OAuth 2.1 provider.

### Access/Refresh Token Pairs (v0.10.0+)

```python
from django_bolt.auth import JWTAuthentication

auth = JWTAuthentication(
    access_lifetime=900,      # 15 minutes
    refresh_lifetime=604800,  # 7 days
    rotate_refresh=True,      # Rotate on each use
    detect_reuse=True,        # Flag token reuse (security alert)
    revoke_all_on_reuse=True  # Bulk revoke on detected reuse
)
```

Access tokens include `jti` (JWT ID) for tracking and revocation.

### CSRF Protection (v0.10.0, Breaking Change)

When `cookie=True` (default), CSRF check is ON. Non-browser clients receive 403 unless `csrf=False`:

```python
# Browser clients (CSRF protected)
JWTAuthentication(cookie=True)  # default

# API clients (no CSRF)
JWTAuthentication(cookie=False)
```

### API Key Authentication

```python
from django_bolt.auth import APIKeyBearer, api_key_required

auth = APIKeyBearer()

@api.get("/api-protected", guards=[api_key_required])
async def api_protected_handler(request):
    return {"message": "API key authenticated"}
```

### Custom Authentication

```python
from django_bolt.auth import BaseAuth, AuthResult
from django.contrib.auth import get_user_model

User = get_user_model()

class CustomAuth(BaseAuth):
    async def authenticate(self, request) -> AuthResult:
        token = request.headers.get("Authorization")
        if token and token.startswith("Bearer "):
            user = await self.get_user(token)
            return AuthResult(user=user)
        return AuthResult()

    async def get_user(self, token: str):
        try:
            return await User.objects.aget(id=int(token.split("_")[1]))
        except:
            return None
```

---

## Permissions & Guards

### Built-in Guards

```python
from django_bolt.auth import IsAuthenticated, HasPermission, HasRole

# Require authentication
@api.get("/private", guards=[IsAuthenticated])
async def private_handler(request):
    return {"user_id": request.user.id}

# Require specific permission
@api.get("/edit-post", guards=[HasPermission("blog.change_post")])
async def edit_post_handler(request):
    return {"can_edit": True}

# Require role
@api.get("/admin-only", guards=[HasRole("admin")])
async def admin_handler(request):
    return {"access": "granted"}
```

### Custom Guards

```python
from django_bolt.auth import BaseGuard, AuthResult

class CustomGuard(BaseGuard):
    async def check(self, request) -> bool:
        return request.headers.get("X-Custom-Header") == "secret"
```

---

## Middleware

### Built-in Middleware

```python
from django_bolt.middleware import CORSMiddleware, RateLimitMiddleware, CompressionMiddleware

api = BoltAPI(
    middleware=[
        CORSMiddleware(
            allow_origins=["*"],
            allow_methods=["*"],
            allow_headers=["*"],
        ),
        RateLimitMiddleware(requests=100, window=60),  # 100 requests per minute
        CompressionMiddleware(),
    ]
)
```

### Django Middleware Integration

```python
from django.middleware.security import SecurityMiddleware

api = BoltAPI(
    django_middleware=[
        SecurityMiddleware,
    ]
)
```

---

## Rate Limiting

### Per-Identity Keys (v0.10.3+)

```python
from django_bolt import rate_limit

@api.get("/user-data", guards=[rate_limit(key="user")])
async def user_data(request):
    return {"data": "per-user rate limit"}

@api.get("/public", guards=[rate_limit(key="api_key")])
async def public_data(request):
    return {"data": "per-api-key rate limit"}
```

### BOLT_TRUSTED_PROXIES (v0.10.3+, Breaking Change)

When behind a proxy, configure `BOLT_TRUSTED_PROXIES` or all callers share one bucket:

```python
# settings.py
BOLT_TRUSTED_PROXIES = [
    "10.0.0.0/8",      # Internal network
    "172.16.0.0/12",
    "192.168.0.0/16",
]
```

---

## Error Handling

Django-Bolt provides a structured exception hierarchy for HTTP errors and automatic error response formatting.

### HTTPException and Specialized Exceptions

```python
from django_bolt.exceptions import HTTPException, NotFound, BadRequest, Unauthorized

# Basic usage
raise HTTPException(status_code=400, detail="Bad request")

# Specialized exceptions (pre-configured)
raise NotFound(detail="User not found")
raise BadRequest(detail="Invalid input")
raise Unauthorized(detail="Authentication required")
raise Forbidden(detail="Access denied")
raise Conflict(detail="Resource already exists")
raise TooManyRequests(detail="Rate limit exceeded")
```

### Custom Error Responses

```python
from django_bolt.exceptions import Unauthorized, BadRequest

# Custom headers
raise Unauthorized(
    detail="Authentication required",
    headers={"WWW-Authenticate": "Bearer", "X-Custom-Header": "value"}
)

# Extra data for debugging
raise BadRequest(
    detail="Invalid input",
    extra={
        "field": "email",
        "value": "invalid@",
        "reason": "Invalid email format"
    }
)
```

### Validation Errors

```python
from django_bolt.exceptions import RequestValidationError

errors = [
    {"loc": ["body", "email"], "msg": "Invalid email format", "type": "value_error"},
    {"loc": ["body", "age"], "msg": "Must be positive", "type": "value_error"}
]
raise RequestValidationError(errors)
```

Response format:

```json
{
    "detail": [
        {"loc": ["body", "email"], "msg": "Invalid email format", "type": "value_error"},
        {"loc": ["body", "age"], "msg": "Must be positive", "type": "value_error"}
    ]
}
```

### Error Handlers

```python
from django_bolt.error_handlers import (
    http_exception_handler,
    request_validation_error_handler,
    generic_exception_handler,
    handle_exception
)

# Handle specific exception types
exc = NotFound(detail="User not found")
status, headers, body = http_exception_handler(exc)

# Handle validation errors
errors = [{"loc": ["body"], "msg": "Invalid", "type": "value_error"}]
exc = RequestValidationError(errors)
status, headers, body = request_validation_error_handler(exc)

# Handle unexpected exceptions (debug mode)
exc = ValueError("Something went wrong")
status, headers, body = generic_exception_handler(exc, debug=False)

# Universal handler
status, headers, body = handle_exception(some_exception)
```

### Debug Mode

In debug mode (`DEBUG=True`), unhandled exceptions return Django's HTML error page with full traceback.

### Exception Reference

| Exception | Status Code | Default Message |
|-----------|-------------|-----------------|
| BadRequest | 400 | Bad Request |
| Unauthorized | 401 | Unauthorized |
| Forbidden | 403 | Forbidden |
| NotFound | 404 | Not Found |
| MethodNotAllowed | 405 | Method Not Allowed |
| Conflict | 409 | Conflict |
| UnprocessableEntity | 422 | Unprocessable Entity |
| TooManyRequests | 429 | Too Many Requests |
| InternalServerError | 500 | Internal Server Error |
| ServiceUnavailable | 503 | Service Unavailable |