---
name: django-bolt
description: Use when building high-performance APIs with django-bolt - routing, JWT auth, msgspec serializers, WebSockets, SSE streaming, file uploads, ORM patterns, runbolt deployment, or migrating from DRF
metadata:
  author: MT
  version: 3.0.0
  tags: python, django, bolt, api, rust, performance, async
---

# Django Bolt

Django Bolt is a high-performance Django framework that bypasses the Python GIL using Rust, delivering **300k+ RPS** for simple endpoints.

## Overview

Django Bolt combines Django's ORM and ecosystem with Rust's performance. Built on top of:

- **Hyper** (Rust HTTP server)
- **Tokio** (async runtime)
- **msgspec** (5-10x faster than Pydantic)

Key features:

- **Async ORM** - Native async/await support for Django ORM
- **Built-in WebSocket** - Real-time communication without channels
- **SSE Streaming** - Server-Sent Events for live updates
- **JWT Authentication** - Built-in auth with refresh token rotation
- **msgspec Serializers** - Fast schema validation and serialization
- **OpenAPI Docs** - Auto-generated at `/docs`

---

## Installation

```bash
pip install django-bolt
```

Add to `INSTALLED_APPS`:

```python
INSTALLED_APPS = [
    ...
    "django_bolt",
]
```

---

## Quick Start

```python
# myapp/api.py
from django_bolt import BoltAPI

api = BoltAPI()

@api.get("/")
async def hello():
    return {"message": "Hello, World!"}

@api.get("/users")
async def list_users():
    users = await User.objects.all()
    return [{"id": u.id, "username": u.username} for u in users]
```

Mount in `urls.py`:

```python
# myproject/urls.py
from django.urls import path
from myapp.api import api

urlpatterns = [
    path("api/", api.urls),
]
```

Run:

```bash
python manage.py runbolt --dev
```

---

## Routing

### Basic Routes

```python
@api.get("/users")
@api.post("/users")
@api.put("/users/{pk}")
@api.delete("/users/{pk}")
@api.patch("/users/{pk}")
```

### Path Parameters

```python
@api.get("/users/{user_id}")
async def get_user(user_id: int):
    user = await User.objects.aget(id=user_id)
    return {"id": user.id, "username": user.username}
```

### Query Parameters

```python
@api.get("/users")
async def list_users(page: int = 1, limit: int = 10):
    users = await User.objects.all()[limit*(page-1):limit*page]
    return [{"id": u.id} for u in users]
```

### Request Body

```python
import msgspec

class UserCreate(msgspec.Struct):
    username: str
    email: str

@api.post("/users")
async def create_user(data: UserCreate):
    user = await User.objects.acreate(username=data.username, email=data.email)
    return {"id": user.id}, 201
```

### Middleware

```python
from django_bolt.middleware import CompressionMiddleware

api.add_middleware(CompressionMiddleware())
```

---

## Class-Based Views

### ViewSet

```python
from django_bolt.views import ViewSet, route

class UserViewSet(ViewSet):
    @route.get("/users")
    async def list(self, request):
        users = await User.objects.alist()
        return {"users": [{"id": u.id, "username": u.username} for u in users]}

    @route.get("/users/{pk}")
    async def retrieve(self, request, pk: int):
        user = await User.objects.aget(id=pk)
        return {"id": user.id, "username": user.username}

    @route.post("/users")
    async def create(self, request):
        data = await request.json()
        user = await User.objects.acreate(**data)
        return {"id": user.id}

    @route.put("/users/{pk}")
    async def update(self, request, pk: int):
        data = await request.json()
        user = await User.objects.aget(id=pk)
        for k, v in data.items():
            setattr(user, k, v)
        await user.asave()
        return {"id": user.id}

    @route.delete("/users/{pk}")
    async def destroy(self, request, pk: int):
        user = await User.objects.aget(id=pk)
        await user.adelete()
        return {"deleted": True}

api.register_viewset(UserViewSet, prefix="/api")
```

### ModelViewSet

```python
from django_bolt.views import ModelViewSet
from django.contrib.auth import get_user_model
from django_bolt.serializers import ModelSerializer

User = get_user_model()

class UserSerializer(ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "username", "email"]

class UserModelViewSet(ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

api.register_viewset(UserModelViewSet, prefix="/api")
```

---

## OpenAPI / API Documentation

Django Bolt auto-generates OpenAPI 3.1 documentation.

### Access Docs

- **Swagger**: `/docs`
- **ReDoc**: `/redoc`
- **Scalar**: `/scalar`
- **RapidDoc**: `/rapiddoc`

### Configure OpenAPI

```python
from django_bolt import BoltAPI
from django_bolt.openapi import OpenAPIInfo

api = BoltAPI(
    info=OpenAPIInfo(
        title="My API",
        version="1.0.0",
        description="API description",
    )
)
```

### Include/Exclude from Schema (v0.10.2+/0.11.0+)

```python
@api.get("/internal", include_in_schema=False)
async def internal_handler():
    return {"secret": True}
```

---

## Testing

### Test Client

```python
from django_bolt.test import AsyncAPITestClient

class UserAPITest(AsyncAPITestClient):
    async def test_create_user(self):
        response = await self.post(
            "/api/users",
            json={"username": "testuser", "email": "test@example.com"}
        )
        self.assertEqual(response.status_code, 201)
        data = await response.json()
        self.assertEqual(data["username"], "testuser")

    async def test_get_user(self):
        user = await User.objects.acreate(username="testuser", email="test@example.com")
        response = await self.get(f"/api/users/{user.id}")
        self.assertEqual(response.status_code, 200)
```

**Note:** TestClient shares DB connection with handler threads for accurate concurrency testing.

---

## Performance Benchmarks

**Conditions:** 8 processes, C=100, loopback, AMD Ryzen 5 5600G

| Endpoint Type | Requests/sec |
|--------------|-------------|
| Hello-world (10KB JSON) | **~311,000 RPS** |
| 10KB JSON response | **~187,000 RPS** |
| 10-row ORM query | **~21,000–27,000 RPS** |

Source: https://bolt.farhana.li/benchmarks/

---

## Configuration

### Settings

```python
# settings.py

# Django-Bolt Configuration
BOLT = {
    "HOST": "0.0.0.0",
    "PORT": 8000,
    "PROCESSES": 4,
    "BACKLOG": 2048,
    "KEEP_ALIVE": 30,
    "DEBUG": False,
    "EMIT_SIGNALS": False,
}

# JWT Configuration
JWT_SECRET_KEY = "your-secret-key"
JWT_ALGORITHM = "HS256"
JWT_EXPIRATION = 3600

# File Upload Settings
from django_bolt import FileSize
BOLT_MAX_UPLOAD_SIZE = FileSize.MB_50
BOLT_MEMORY_SPOOL_THRESHOLD = 5 * 1024 * 1024

# CORS Configuration
BOLT_CORS = {
    "allow_origins": ["https://example.com"],
    "allow_methods": ["GET", "POST", "PUT", "DELETE"],
    "allow_headers": ["*"],
    "allow_credentials": True,
}
```

---

## Production Server: runbolt

### Worker Recycling (v0.11.0+)

```bash
# Recycle workers after memory threshold
python manage.py runbolt --max-rss 512000

# Limit worker lifetime
python manage.py runbolt --workers-lifetime 3600

# Auto-respawn failed workers
python manage.py runbolt --respawn-failed-workers
```

### Development Mode (v0.11.0+)

```bash
# Native Rust reloader
python manage.py runbolt --dev

# Custom reload directory
python manage.py runbolt --dev --reload-dir src/
```

---

## Best Practices

### Performance

1. **Use async ORM methods** - Always use `aget()`, `alist()`, `acreate()` in handlers
2. **Avoid N+1 queries** - Use `select_related()` for ForeignKey, `prefetch_related()` for ManyToMany
3. **Enable compression** - Use `CompressionMiddleware` for responses > 500 bytes
4. **Tune process count** - Set `--processes` to CPU core count for CPU-bound workloads

### Security

1. **Always validate input** - Use msgspec structs for request body validation
2. **Use HTTPS in production** - Terminate TLS at nginx/load balancer
3. **Configure BOLT_TRUSTED_PROXIES** - Required behind reverse proxies for accurate rate limiting
4. **Rotate JWT secrets** - Implement key rotation for long-lived deployments

### Maintainability

1. **Organize by feature** - Group related endpoints in feature modules
2. **Use dependency injection** - Extract reusable logic with `Depends()`
3. **Write tests** - Use `AsyncAPITestClient` for integration tests
4. **Document APIs** - Leverage auto-generated OpenAPI docs at `/docs`

---

## Command-Line Reference

```bash
# Development server with native Rust reloader
python manage.py runbolt --dev

# Production with custom settings
python manage.py runbolt --host 0.0.0.0 --port 8000 --processes 4

# Worker recycling
python manage.py runbolt --max-rss 512000 --workers-lifetime 3600

# Increase socket backlog
python manage.py runbolt --processes 4 --backlog 2048

# Adjust keep-alive timeout
python manage.py runbolt --processes 4 --keep-alive 30

# Skip startup checks
python manage.py runbolt --skip-checks
```

---

## Version Migration Gates

| Version | Breaking Change |
|---------|-----------------|
| v0.4.0 | Python 3.12+ required |
| v0.6.0 | SessionAuthentication removed |
| v0.10.0 | bolt-mcp 0.2 API + cookie-JWT CSRF check ON by default |
| v0.10.3 | BOLT_TRUSTED_PROXIES required behind proxies |
| v0.11.0 | Nested() removed — use plain type hints |

---

## References

- **Official Docs**: https://bolt.farhana.li/
- **LLMs.txt**: https://bolt.farhana.li/llms.txt
- **Releases**: https://github.com/dj-bolt/django-bolt/releases
- **CHANGELOG**: https://github.com/dj-bolt/django-bolt/blob/main/CHANGELOG.md
- **Benchmarks**: https://bolt.farhana.li/benchmarks/
- **MCP Guide**: https://bolt.farhana.li/topics/mcp/

---

## Deep Dives

The following reference files contain detailed coverage of advanced topics. Load them on demand when working on specific features:

1. **auth-security.md** — Authentication, Permissions & Guards, Middleware, Rate Limiting, Error Handling
2. **responses-serialization.md** — Responses, msgspec Serializers, Pagination, Request Object, Dependency Injection
3. **websockets-uploads.md** — WebSockets, File Uploads
4. **orm-background.md** — Django ORM Patterns, Background Tasks
5. **deployment.md** — Deployment, MCP Servers
6. **drf-migration.md** — Comparison with DRF/Django Ninja, Migration from DRF

---