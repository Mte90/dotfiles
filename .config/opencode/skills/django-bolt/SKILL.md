---
name: django-bolt
description: "Django Bolt - Rust-powered high-performance API framework, 60k+ RPS, decorator routing, built-in auth, async ORM"
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - python
    - django
    - bolt
    - api
    - rust
    - performance
    - async
    - high-performance
---

# Django Bolt

High-performance fully typed API framework for Django — **Faster than FastAPI, but with Django ORM, Django Admin, and Django packages**.

Django-Bolt is a Rust-powered API framework achieving **60k+ RPS**. Uses Actix Web for HTTP, PyO3 for Python bridging, and msgspec for serialization.

## Overview

**Architecture:**
- **HTTP Server**: Actix Web (Rust) — one of the fastest HTTP frameworks
- **Python Bridge**: PyO3 — seamless Rust-Python integration  
- **Serialization**: msgspec — 5-10x faster than stdlib
- **Routing**: matchit — zero-copy path matching
- **Async Runtime**: Tokio

**Why Django Bolt?**
- No gunicorn or uvicorn needed — deploy directly
- Full Django ORM integration with async support
- Built-in auth (JWT, API Key) in Rust (no Python GIL)
- OpenAPI auto-generation
- Compatible with existing Django packages

---

## Installation

```bash
pip install django-bolt
```

```python
# settings.py
INSTALLED_APPS = [
    ...
    "django_bolt"
    ...
]
```

---

## Quick Start

### Basic API

```python
# api.py
from django_bolt import BoltAPI
from django.contrib.auth import get_user_model
import msgspec

User = get_user_model()

api = BoltAPI()

class UserSchema(msgspec.Struct):
    id: int
    username: str

@api.get("/users/{user_id}")
async def get_user(user_id: int) -> UserSchema:
    # Response is type validated
    user = await User.objects.aget(id=user_id)
    # Django ORM works without any setup
    return {"id": user.id, "username": user.username}
```

### Running the Server

```bash
# Development
python manage.py runbolt --dev

# Production (standalone)
python manage.py runbolt
```

---

## Routing

### HTTP Methods

```python
from django_bolt import BoltAPI

api = BoltAPI()

@api.get("/endpoint")
async def get_handler(request):
    return {"message": "GET"}

@api.post("/endpoint")
async def post_handler(request):
    data = await request.json()
    return {"received": data}

@api.put("/endpoint")
async def put_handler(request):
    return {"message": "PUT"}

@api.delete("/endpoint/{id}")
async def delete_handler(id: int):
    return {"deleted": id}

@api.patch("/endpoint")
async def patch_handler(request):
    return {"message": "PATCH"}
```

### Path Parameters

```python
@api.get("/users/{user_id}")
async def get_user(user_id: int):
    return {"id": user_id}

@api.get("/posts/{post_id}/comments/{comment_id}")
async def get_comment(post_id: int, comment_id: int):
    return {"post_id": post_id, "comment_id": comment_id}
```

### Query Parameters

```python
from django_bolt import Query

@api.get("/search")
async def search_handler(
    query: str = Query(...),
    limit: int = Query(10),
    offset: int = Query(0)
):
    return {"query": query, "limit": limit, "offset": offset}
```

### Request Body

```python
import msgspec

class CreateUserRequest(msgspec.Struct):
    username: str
    email: str
    password: str

@api.post("/users")
async def create_user(request, body: CreateUserRequest):
    # body is automatically validated
    user = await User.objects.acreate(
        username=body.username,
        email=body.email
    )
    return {"id": user.id, "username": user.username}
```

---

## Authentication

### JWT Authentication

```python
from django_bolt.auth import JWTBearer, jwt_required
from django_bolt.response import Json

auth = JWTBearer(secret_key="your-secret-key")

@api.get("/protected", guards=[jwt_required])
async def protected_handler(request):
    return {"user": request.user.id}
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
            # Validate token
            user = await self.get_user(token)
            return AuthResult(user=user)
        return AuthResult()

async def get_user(self, token: str):
    # Your logic to get user from token
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
        # Your logic
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
        # Your Django middleware here
    ]
)
```

---

## Responses

### JSON Response

```python
from django_bolt.response import Json

@api.get("/json")
async def json_handler(request):
    return Json({"key": "value"})

# Or shorthand (automatically JSON serialized)
@api.get("/auto-json")
async def auto_json_handler(request):
    return {"key": "value"}
```

### HTML Response

```python
from django_bolt.response import Html

@api.get("/html")
async def html_handler(request):
    return Html("<h1>Hello World</h1>")
```

### Streaming Response (SSE)

```python
from django_bolt.response import StreamingResponse

async def event_stream():
    for i in range(10):
        yield f"data: message {i}\n\n"
    # Or use Server-Sent Events format
    yield {"event": "message", "data": {"count": i}}

@api.get("/stream")
async def stream_handler(request):
    return StreamingResponse(event_stream())
```

### File Response

```python
from django_bolt.response import FileResponse

@api.get("/download")
async def download_handler(request):
    return FileResponse(
        path="/path/to/file.pdf",
        filename="document.pdf",
        content_type="application/pdf"
    )
```

### Redirect Response

```python
from django_bolt.response import Redirect

@api.get("/redirect")
async def redirect_handler(request):
    return Redirect(url="https://example.com", status=302)
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

## Serializers (msgspec)

msgspec provides **5-10x faster** JSON serialization than Python's stdlib.

### Basic Struct

```python
import msgspec

class UserSchema(msgspec.Struct):
    id: int
    username: str
    email: str
    is_active: bool = True

@api.post("/users")
async def create_user(request, body: UserSchema):
    # body is automatically validated
    user = await User.objects.acreate(
        username=body.username,
        email=body.email,
        is_active=body.is_active
    )
    return {"id": user.id}
```

### With Validation

```python
import msgspec

class UserCreateSchema(msgspec.Struct):
    username: str
    email: str
    password: str
    
    def __post_init__(self):
        if len(self.password) < 8:
            raise msgspec.ValidationError("Password must be at least 8 characters")
        if "@" not in self.email:
            raise msgspec.ValidationError("Invalid email format")
```

### Nested Structures

```python
class AddressSchema(msgspec.Struct):
    street: str
    city: str
    zip_code: str
    country: str

class UserSchema(msgspec.Struct):
    id: int
    username: str
    address: AddressSchema | None = None

@api.get("/users/{user_id}")
async def get_user_with_address(user_id: int):
    user = await User.objects.aget(id=user_id)
    return {
        "id": user.id,
        "username": user.username,
        "address": {
            "street": user.street,
            "city": user.city,
            "zip_code": user.zip_code,
            "country": user.country
        } if user.street else None
    }
```

---

## OpenAPI / API Documentation

Django Bolt auto-generates OpenAPI documentation.

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
        # Create user first
        user = await User.objects.acreate(username="testuser", email="test@example.com")
        
        response = await self.get(f"/api/users/{user.id}")
        self.assertEqual(response.status_code, 200)
```

---

## Performance Benchmarks

### Standard Endpoints

| Endpoint Type | Requests/sec |
|--------------|-------------|
| Root endpoint | **~100,000 RPS** |
| JSON parsing/validation (10kb) | **~83,700 RPS** |
| Path + Query parameters | **~85,300 RPS** |
| HTML response | **~100,600 RPS** |
| Redirect response | **~96,300 RPS** |
| Form data handling | **~76,800 RPS** |
| ORM reads (SQLite, 10 records) | **~13,000 RPS** |

### Streaming (SSE)

**10,000 concurrent clients:**
- Total Throughput: 9,489 messages/sec
- Successful Connections: 100%
- CPU Usage: 11.9% average

---

## Configuration

### Settings

```python
# settings.py

# Optional: Configure Bolt
BOLT = {
    "HOST": "0.0.0.0",
    "PORT": 8000,
    "DEBUG": False,
    "workers": 4,  # Number of worker processes
}

# Optional: JWT settings
JWT_SECRET_KEY = "your-secret-key"
JWT_ALGORITHM = "HS256"
JWT_EXPIRATION = 3600  # seconds
```

### Production Deployment

```bash
# Run in production mode
python manage.py runbolt --workers 4
```

---

## Error Handling

### HTTP Exceptions

```python
from django_bolt.exceptions import HTTPException

@api.get("/users/{user_id}")
async def get_user(user_id: int):
    try:
        user = await User.objects.aget(id=user_id)
    except User.DoesNotExist:
        raise HTTPException(status_code=404, detail="User not found")
    return {"id": user.id, "username": user.username}

# Custom error with extra data
raise HTTPException(
    status_code=400,
    detail={
        "error": "validation_failed",
        "fields": {"email": "Invalid email format"}
    }
)
```

### Validation Error Formatting

```python
import msgspec

class CreateUserRequest(msgspec.Struct):
    username: str
    email: str
    age: int

# Automatic validation errors from msgspec
@api.post("/users")
async def create_user(request, body: CreateUserRequest):
    # If body doesn't match schema, returns 422 with details:
    # {"detail": [{"loc": ["body", "age"], "msg": "expected int", "type": "type_error"}]}
    return {"username": body.username}
```

### Global Exception Handler

```python
from django_bolt.exceptions import exception_handler

def custom_exception_handler(exc, request):
    # Log the exception
    import logging
    logger = logging.getLogger(__name__)
    logger.error(f"Unhandled exception: {exc}")
    
    return {"error": "internal_server_error", "detail": str(exc)}, 500

api = BoltAPI(exception_handler=custom_exception_handler)
```

---

## Pagination

### Offset Pagination

```python
from django_bolt import BoltAPI, Query

@api.get("/users")
async def list_users(
    request,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    offset = (page - 1) * page_size
    users = User.objects.all().order_by("id")
    
    total = await users.acount()
    items = await users[offset:offset + page_size].alist()
    
    return {
        "items": [{"id": u.id, "username": u.username} for u in items],
        "total": total,
        "page": page,
        "page_size": page_size,
        "pages": (total + page_size - 1) // page_size,
    }
```

### Cursor-Based Pagination

```python
from django_bolt import Query

@api.get("/posts")
async def list_posts(
    request,
    cursor: int = Query(None),
    limit: int = Query(20, le=100),
):
    posts = Post.objects.all().order_by("-id")
    
    if cursor:
        posts = posts.filter(id__lt=cursor)
    
    items = await posts[:limit + 1].alist()
    has_next = len(items) > limit
    items = items[:limit]
    
    return {
        "items": [{"id": p.id, "title": p.title} for p in items],
        "next_cursor": items[-1].id if has_next and items else None,
        "has_next": has_next,
    }
```

---

## Django ORM Patterns

### Async QuerySet Operations

```python
from django_bolt import BoltAPI

api = BoltAPI()

# Async iteration
@api.get("/posts")
async def list_posts(request):
    posts = []
    async for post in Post.objects.all().order_by("-created_at")[:20]:
        posts.append({"id": post.id, "title": post.title})
    return {"posts": posts}

# select_related / prefetch_related
@api.get("/articles/{article_id}")
async def get_article(article_id: int):
    article = await Article.objects.select_related("author", "category").aget(id=article_id)
    return {
        "id": article.id,
        "title": article.title,
        "author": article.author.name,
        "category": article.category.name,
    }

# Bulk operations
@api.post("/articles/bulk")
async def bulk_create_articles(request):
    articles = await Article.objects.abulk_create([
        Article(title=f"Article {i}", content="...")
        for i in range(100)
    ])
    return {"created": len(articles)}

# Count with Exists (optimized)
from django.db.models import Exists, OuterRef

@api.get("/posts/with-comments")
async def posts_with_comments(request):
    posts = Post.objects.annotate(
        has_comments=Exists(Comment.objects.filter(post_id=OuterRef("pk")))
    )
    result = []
    async for post in posts:
        result.append({"id": post.id, "has_comments": post.has_comments})
    return {"posts": result}
```

### Transactions

```python
from django.db import transaction

@api.post("/orders")
async def create_order(request):
    data = await request.json()
    
    async with transaction.atomic():
        order = await Order.objects.acreate(
            user_id=data["user_id"],
            total=data["total"],
        )
        for item in data["items"]:
            await OrderItem.objects.acreate(
                order=order,
                product_id=item["product_id"],
                quantity=item["quantity"],
            )
    
    return {"order_id": order.id}
```

---

## File Uploads

### Single File Upload

```python
from django_bolt import BoltAPI

@api.post("/upload")
async def upload_file(request):
    file = await request.file("document")
    if not file:
        return {"error": "No file provided"}, 400
    
    # file properties
    content = await file.read()
    filename = file.filename
    content_type = file.content_type
    
    # Save via Django's default storage
    from django.core.files.storage import default_storage
    path = default_storage.save(f"uploads/{filename}", file)
    
    return {"path": path, "size": len(content)}
```

### Multiple Files

```python
@api.post("/upload/multiple")
async def upload_multiple(request):
    files = await request.files("documents")
    paths = []
    for file in files:
        from django.core.files.storage import default_storage
        path = default_storage.save(f"uploads/{file.filename}", file)
        paths.append(path)
    return {"uploaded": len(paths), "paths": paths}
```

---

## Background Tasks with Django 6.0

Django Bolt works seamlessly with Django 6.0's built-in Tasks Framework:

```python
from django.tasks import task

@task
def process_video(video_path: str):
    # Heavy processing in background
    import subprocess
    subprocess.run(["ffmpeg", "-i", video_path, "-vcodec", "h264", f"{video_path}.mp4"])

@api.post("/videos")
async def upload_video(request):
    file = await request.file("video")
    from django.core.files.storage import default_storage
    path = default_storage.save(f"videos/{file.filename}", file)
    
    # Enqueue background task
    process_video.enqueue(path)
    
    return {"path": path, "status": "processing"}
```

---

## Comparison with Alternatives

### When to Choose Django Bolt

| Feature | Django Bolt | Django REST Framework | Django Ninja |
|---------|------------|----------------------|--------------|
| **RPS** | 60,000+ | ~1,000 | ~3,000 |
| **Auth in Rust** | ✅ | ❌ | ❌ |
| **msgspec serialization** | ✅ | ❌ | ❌ |
| **OpenAPI auto-gen** | ✅ | Needs drf-spectacular | ✅ |
| **Django Admin** | ✅ | ✅ | ✅ |
| **Django ORM** | ✅ (async) | ✅ (sync) | ✅ (async) |
| **Serializer** | msgspec | DRF Serializers | Pydantic |
| **Middleware in Rust** | ✅ | ❌ | ❌ |

### Choose Django Bolt when:
- You need maximum API throughput (10x+ over DRF)
- You want built-in JWT/API Key auth without extra packages
- You're building API-only Django services
- You need SSE/WebSocket at scale

### Choose DRF when:
- You need the mature DRF ecosystem (dry-rest-permissions, drf-writable-nested, etc.)
- Your team already knows DRF deeply
- You need browsable API for non-technical users

### Choose Django Ninja when:
- You want Pydantic validation (familiar to FastAPI users)
- You need a middle ground between DRF and Bolt performance

---

## Migration from Django REST Framework

### Step 1: Install Django Bolt alongside DRF

```bash
pip install django-bolt
```

```python
# settings.py - Keep DRF, add Bolt
INSTALLED_APPS = [
    ...
    "rest_framework",
    "django_bolt",
]
```

### Step 2: Create Bolt API alongside DRF

```python
# bolt_api.py - New file
from django_bolt import BoltAPI

api = BoltAPI()
```

### Step 3: Migrate views incrementally

```python
# Before: DRF ViewSet
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

# After: Django Bolt equivalent
from django_bolt.views import ModelViewSet
from django_bolt.serializers import ModelSerializer

class UserBoltSerializer(ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "username", "email"]

class UserBoltViewSet(ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserBoltSerializer

api.register_viewset(UserBoltViewSet, prefix="/api/v2/users")
```

### Step 4: Run both simultaneously

```bash
# DRF on standard Django server
python manage.py runserver 8000

# Bolt API on its own server
python manage.py runbolt 8001
```

### Step 5: Remove DRF when fully migrated

```python
# settings.py
INSTALLED_APPS = [
    ...
    "django_bolt",
    # "rest_framework",  # Remove when done
]
```

---

## Production Deployment

### systemd Service

```ini
# /etc/systemd/system/django-bolt.service
[Unit]
Description=Django Bolt API
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/myapp
ExecStart=/opt/myapp/venv/bin/python manage.py runbolt --workers 4
Restart=always
RestartSec=5
Environment=DJANGO_SETTINGS_MODULE=myapp.settings

[Install]
WantedBy=multi-user.target
```

### Docker

```dockerfile
FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

EXPOSE 8000
CMD ["python", "manage.py", "runbolt", "--workers", "4"]
```

### Nginx Reverse Proxy

```nginx
upstream bolt_api {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name api.example.com;

    location / {
        proxy_pass http://bolt_api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## Why So Fast?

- **Actix Web**: Rust HTTP framework (one of the fastest)
- **matchit**: Zero-copy path matching
- **msgspec**: 5-10x faster JSON serialization
- **PyO3**: Direct Rust-Python interop
- **No GIL for auth**: JWT/API Key validation in Rust

---

## Error Handling

Django-Bolt provides a structured exception hierarchy for HTTP errors and automatic error response formatting.

### HTTPException and Specialized Exceptions

The base class for all HTTP errors:

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

Add custom headers and extra data to error responses:

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

RequestValidationError provides structured validation error responses:

```python
from django_bolt.exceptions import RequestValidationError

# Manual validation errors
errors = [
    {"loc": ["body", "email"], "msg": "Invalid email format", "type": "value_error"},
    {"loc": ["body", "age"], "msg": "Must be positive", "type": "value_error"}
]
raise RequestValidationError(errors)
```

Response format for validation errors:

```json
{
    "detail": [
        {"loc": ["body", "email"], "msg": "Invalid email format", "type": "value_error"},
        {"loc": ["body", "age"], "msg": "Must be positive", "type": "value_error"}
    ]
}
```

### Error Handlers

Custom error handlers for different exception types:

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

In debug mode (`DEBUG=True`), unhandled exceptions return Django's HTML error page with full traceback:

```python
# debug=True: Full HTML traceback page
status, headers, body = handle_exception(exc, debug=True)

# debug=False: JSON error response
status, headers, body = handle_exception(exc, debug=False)
```

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

---

## Request Object

Access the full request using the `request` parameter for comprehensive request data.

### Request Properties

The request dict contains all HTTP request information:

```python
@api.get("/info")
async def request_info(request):
    return {
        "method": request.get("method"),      # GET, POST, etc.
        "path": request.get("path"),           # Request path
        "query": request.get("query"),         # Query parameters dict
        "params": request.get("params"),       # Path parameters dict
        "headers": request.get("headers"),     # Request headers dict
        "body": request.get("body", b""),      # Raw body bytes
        "context": request.get("context"),     # Authentication context
    }
```

### Type-Safe Request

For better IDE support, use the `Request` type:

```python
from django_bolt import Request
from django_bolt.auth import JWTAuthentication, IsAuthenticated

@api.get("/profile", auth=[JWTAuthentication()], guards=[IsAuthenticated()])
async def profile(request: Request):
    # IDE knows about .user, .session, .context, etc.
    user = await request.auser()
    return {"user_id": request.user.id, "username": request.user.username}
```

### Headers

Extract specific headers using the `Header` parameter:

```python
from typing import Annotated
from django_bolt.param_functions import Header

@api.get("/auth")
async def check_auth(
    authorization: Annotated[str, Header(alias="Authorization")]
):
    return {"auth": authorization}

# Optional headers
@api.get("/optional-header")
async def optional_header(
    custom: Annotated[str | None, Header(alias="X-Custom")] = None
):
    return {"custom": custom}

# All headers
@api.get("/headers")
async def all_headers(request):
    headers = request.get("headers", {})
    return {"headers": dict(headers)}
```

### Cookies

Extract cookie values:

```python
from typing import Annotated
from django_bolt.param_functions import Cookie

@api.get("/session")
async def get_session(
    session_id: Annotated[str, Cookie(alias="sessionid")]
):
    return {"session_id": session_id}
```

### Sessions

Access Django sessions when using Django middleware:

```python
from django_bolt import BoltAPI, Request
from django.contrib.auth import alogin, alogout
from datetime import datetime

api = BoltAPI(django_middleware=True)

@api.post("/login")
async def login(request: Request, username: str, password: str):
    user = await User.objects.filter(username=username).afirst()
    if user and user.check_password(password):
        await alogin(request, user)
        await request.session.aset("login_time", str(datetime.now()))
        return {"status": "ok"}
    return {"status": "error"}

@api.get("/profile")
async def profile(request: Request):
    user = await request.auser()
    if not user.is_authenticated:
        return {"error": "not logged in"}
    return {
        "username": user.username,
        "login_time": await request.session.aget("login_time"),
    }

@api.post("/logout")
async def logout(request: Request):
    await alogout(request)
    return {"status": "logged out"}
```

### Session Async Methods

| Method | Description |
|--------|-------------|
| `await session.aget(key, default)` | Get a session value |
| `await session.aset(key, value)` | Set a session value |
| `await session.apop(key, default)` | Remove and return a value |
| `await session.akeys()` | Get all session keys |
| `await session.aitems()` | Get all key-value pairs |
| `await session.aflush()` | Delete session and create new |

---

## Dependency Injection

Django-Bolt provides dependency injection using the `Depends` marker for reusable parameter extractors.

### Basic Usage

```python
from django_bolt import BoltAPI, Depends

api = BoltAPI()

async def get_pagination(page: int = 1, limit: int = 20):
    return {"page": page, "limit": limit, "offset": (page - 1) * limit}

@api.get("/items")
async def list_items(pagination=Depends(get_pagination)):
    return {"pagination": pagination}
```

### Request Access in Dependencies

Dependencies receive the request dict:

```python
async def get_current_user(request):
    """Dependency that extracts the current user."""
    user_id = request.get("context", {}).get("user_id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return await User.objects.aget(id=user_id)

@api.get("/profile")
async def get_profile(user=Depends(get_current_user)):
    return {"id": user.id, "username": user.username}
```

### Authentication Dependency

```python
from django_bolt.auth import get_current_user

@api.get("/me")
async def me(user=Depends(get_current_user)):
    return {
        "id": user.id,
        "username": user.username,
        "email": user.email
    }
```

### Dependency Caching

By default, dependencies are cached per-request:

```python
call_count = 0

async def expensive_operation(request):
    global call_count
    call_count += 1
    return {"count": call_count}

@api.get("/test")
async def test(
    dep1=Depends(expensive_operation),
    dep2=Depends(expensive_operation)  # Same dependency
):
    # expensive_operation is called ONCE, result is reused
    return {"dep1": dep1, "dep2": dep2}

# Disable caching
@api.get("/fresh")
async def fresh(dep=Depends(some_dependency, use_cache=False)):
    return dep
```

### Nested Dependencies

Dependencies can depend on other dependencies:

```python
async def get_settings(request):
    return await Settings.objects.afirst()

async def get_feature_flags(settings=Depends(get_settings)):
    return {
        "new_ui": settings.enable_new_ui,
        "beta": settings.beta_features,
    }

@api.get("/features")
async def features(flags=Depends(get_feature_flags)):
    return flags
```

### Class-Based Dependencies

Classes can be used as dependencies:

```python
class DatabaseSession:
    def __init__(self, request):
        self.request = request
        self.connection = None

    async def __aenter__(self):
        self.connection = await get_connection()
        return self.connection

    async def __aexit__(self, *args):
        if self.connection:
            await self.connection.close()

@api.get("/data")
async def get_data(db=Depends(DatabaseSession)):
    async with db:
        # Use database connection
        pass
```

---

## File Uploads

Django-Bolt provides the `UploadFile` class for handling file uploads with Django integration.

### Basic File Upload

```python
from typing import Annotated
from django_bolt import UploadFile
from django_bolt.params import File

@api.post("/upload")
async def upload(file: Annotated[UploadFile, File()]):
    content = await file.read()
    return {
        "filename": file.filename,
        "size": file.size,
        "content_type": file.content_type,
    }
```

### UploadFile Properties

| Property | Type | Description |
|----------|------|-------------|
| `filename` | str | Original filename |
| `content_type` | str | MIME type |
| `size` | int | Size in bytes |
| `file` | Django File | Django File object for FileField |
| `headers` | dict | Multipart headers |

### File Validation

```python
from django_bolt import FileSize

@api.post("/upload")
async def upload(
    file: Annotated[UploadFile, File(
        max_size=FileSize.MB_10,           # Maximum 10MB
        min_size=1024,                    # Minimum 1KB
        allowed_types=["image/*", "application/pdf"],  # MIME types
    )]
):
    return {"filename": file.filename}
```

### FileSize Enum

```python
from django_bolt import FileSize

File(max_size=FileSize.KB_1)    # 1 KB
File(max_size=FileSize.MB_1)    # 1 MB
File(max_size=FileSize.MB_5)    # 5 MB
File(max_size=FileSize.MB_10)   # 10 MB
File(max_size=FileSize.MB_50)   # 50 MB
```

### Multiple File Uploads

```python
@api.post("/upload-multiple")
async def upload_multiple(
    files: Annotated[list[UploadFile], File(
        max_files=5,              # Maximum 5 files
        max_size=FileSize.MB_5,  # 5MB per file
    )]
):
    return {
        "count": len(files),
        "filenames": [f.filename for f in files],
    }
```

### Saving to Django FileField/ImageField

```python
from myapp.models import Document, UserProfile

# FileField
@api.post("/documents")
async def create_document(
    title: Annotated[str, Form()],
    upload: Annotated[UploadFile, File(max_size=FileSize.MB_10)],
):
    doc = Document(title=title)
    doc.file = upload.file  # Assign Django File to FileField
    await doc.asave()
    return {"id": doc.id, "url": doc.file.url}

# ImageField
@api.post("/avatar")
async def upload_avatar(
    avatar: Annotated[UploadFile, File(
        max_size=FileSize.MB_5,
        allowed_types=["image/*"],
    )],
    request,
):
    profile = await UserProfile.objects.aget(user=request.user)
    profile.avatar = avatar.file  # Assign Django File to ImageField
    await profile.asave()
    return {"avatar_url": profile.avatar.url}
```

### Global Upload Settings

```python
# settings.py
from django_bolt import FileSize

# Maximum upload size (requests exceeding this are rejected)
BOLT_MAX_UPLOAD_SIZE = FileSize.MB_10  # 10 MB global limit

# Memory threshold before spooling to disk (default: 1 MB)
BOLT_MEMORY_SPOOL_THRESHOLD = 5 * 1024 * 1024  # 5 MB
```

---

## Pagination

Django-Bolt provides three pagination styles for handling large datasets efficiently.

### PageNumber Pagination

Classic page-based pagination:

```python
from django_bolt import BoltAPI, PageNumberPagination, paginate

api = BoltAPI()

class ArticlePagination(PageNumberPagination):
    page_size = 20
    max_page_size = 100
    page_size_query_param = "page_size"  # Allow client to customize

@api.get("/articles")
@paginate(ArticlePagination)
async def list_articles(request) -> list[ArticleSerializer]:
    return Article.objects.all()
```

Response:

```json
{
    "count": 150,
    "page": 1,
    "page_size": 20,
    "total_pages": 8,
    "has_next": true,
    "has_previous": false,
    "next_page": 2,
    "previous_page": null,
    "items": [...]
}
```

### LimitOffset Pagination

Flexible offset-based pagination:

```python
from django_bolt import LimitOffsetPagination, paginate

@api.get("/articles", response_model=list[ArticleSerializer])
@paginate(LimitOffsetPagination)
async def list_articles(request):
    return Article.objects.all()
```

Query: `/articles?limit=10&offset=20`

### Cursor Pagination

Efficient pagination for large datasets and real-time feeds:

```python
from django_bolt import CursorPagination, paginate

class ArticlePagination(CursorPagination):
    page_size = 20
    ordering = "-created_at"  # Required: field to paginate by

@api.get("/articles")
@paginate(ArticlePagination)
async def list_articles(request) -> list[ArticleSerializer]:
    return Article.objects.all()
```

Query: `/articles?cursor=eyJ2IjoxMDB9`

### ViewSet with Pagination

```python
from django_bolt.views import ViewSet

@api.viewset("/articles")
class ArticleViewSet(ViewSet):
    queryset = Article.objects.all()

    @paginate(ArticlePagination)
    async def list(self, request) -> list[ArticleSerializer]:
        return await self.get_queryset()
```

### ModelViewSet with Pagination

```python
from django_bolt.views import ModelViewSet

@api.viewset("/articles")
class ArticleViewSet(ModelViewSet):
    queryset = Article.objects.all()
    serializer_class = ArticleDetailSerializer
    list_serializer_class = ArticleListSerializer
    pagination_class = ArticlePagination  # Automatically applied to list()
```

---

## WebSockets

Django-Bolt provides WebSocket support for real-time bidirectional communication.

### Basic WebSocket Endpoint

```python
from django_bolt import BoltAPI, WebSocket

api = BoltAPI()

@api.websocket("/ws/echo")
async def echo(websocket: WebSocket):
    await websocket.accept()
    async for message in websocket.iter_text():
        await websocket.send_text(f"Echo: {message}")
```

### Sending Messages

```python
# Text messages
await websocket.send_text("Hello, World!")

# Binary messages
await websocket.send_bytes(b"\x00\x01\x02\x03")

# JSON messages
await websocket.send_json({"type": "message", "data": "Hello"})
```

### Receiving Messages

```python
# Text messages
message = await websocket.receive_text()
async for message in websocket.iter_text():
    print(f"Received: {message}")

# Binary messages
data = await websocket.receive_bytes()

# JSON messages
data = await websocket.receive_json()
async for data in websocket.iter_json():
    print(f"Received: {data}")
```

### Path and Query Parameters

```python
# Path parameters
@api.websocket("/ws/room/{room_id}")
async def room(websocket: WebSocket, room_id: str):
    await websocket.accept()
    async for message in websocket.iter_text():
        await websocket.send_text(f"[{room_id}] {message}")

# Query parameters (for authentication)
@api.websocket("/ws/connect")
async def connect(websocket: WebSocket, token: str | None = None):
    if token != "secret":
        await websocket.close(code=4001, reason="Invalid token")
        return
    await websocket.accept()
```

### Closing Connections

```python
from django_bolt import WebSocketDisconnect

@api.websocket("/ws")
async def handler(websocket: WebSocket):
    await websocket.accept()
    try:
        async for message in websocket.iter_text():
            await websocket.send_text(message)
    except WebSocketDisconnect:
        print("Client disconnected")

# Close from server
await websocket.close(code=1000, reason="Normal closure")
```

### Authentication

Apply authentication to WebSocket endpoints:

```python
from django_bolt.auth import JWTAuthentication, IsAuthenticated

@api.websocket(
    "/ws/protected",
    auth=[JWTAuthentication()],
    guards=[IsAuthenticated()]
)
async def protected(websocket: WebSocket):
    user_id = websocket.context.get("user_id")
    await websocket.accept()
    await websocket.send_text(f"Welcome, user {user_id}")
```

### Real-Time Patterns

#### Broadcast to All Clients

```python
connected_clients = set()

@api.websocket("/ws/broadcast")
async def broadcast(websocket: WebSocket):
    await websocket.accept()
    connected_clients.add(websocket)

    try:
        async for message in websocket.iter_text():
            for client in connected_clients:
                await client.send_text(message)
    finally:
        connected_clients.discard(websocket)
```

#### Room-Based Chat

```python
rooms = {}  # room_id -> set of websockets

@api.websocket("/ws/room/{room_id}")
async def room(websocket: WebSocket, room_id: str):
    await websocket.accept()

    if room_id not in rooms:
        rooms[room_id] = set()
    rooms[room_id].add(websocket)

    try:
        async for message in websocket.iter_text():
            for client in rooms[room_id]:
                await client.send_text(f"[{room_id}] {message}")
    finally:
        rooms[room_id].discard(websocket)
```

---

## Background Tasks

Django-Bolt integrates with Django's task framework for asynchronous background processing.

### Integration with Celery

```python
# tasks.py
from celery import shared_task

@shared_task
def process_data_async(data_id: int):
    """Process data in background."""
    import asyncio
    from myapp.models import DataRecord

    async def process():
        record = await DataRecord.objects.aget(id=data_id)
        # Expensive processing
        record.status = "processed"
        await record.asave()

    asyncio.run(process())

# API handler
from myapp.tasks import process_data_async

@api.post("/process")
async def start_processing(data_id: int):
    process_data_async.delay(data_id)
    return {"status": "processing_started", "data_id": data_id}
```

### Django Q

```python
# Alternative: Django Q
@api.post("/process")
async def start_processing(data_id: int):
    from django_q.tasks import async_task

    async_task("myapp.functions.process_data", data_id)
    return {"status": "queued", "data_id": data_id}
```

### Using Channels for Real-Time Updates

```python
# For WebSocket + background task integration
@api.post("/long-task")
async def start_long_task(request: Request):
    task_id = str(uuid.uuid4())

    # Start background task
    asyncio.create_task(background_processing(task_id))

    return {"task_id": task_id, "status": "started"}

async def background_processing(task_id: str):
    # Simulate long task
    await asyncio.sleep(10)

    # Notify via WebSocket (store connected clients globally)
    if task_id in connected_tasks:
        await connected_tasks[task_id].send_json({
            "type": "task_complete",
            "task_id": task_id
        })
```

---

## Django ORM Patterns

Django-Bolt handlers use async, requiring Django's async ORM methods for maximum performance.

### Basic Async ORM Methods

```python
from myapp.models import Article

# Get a single object
article = await Article.objects.aget(id=1)

# Create an object
article = await Article.objects.acreate(
    title="My Article",
    content="Content here"
)

# Get or create
article, created = await Article.objects.aget_or_create(
    title="My Article",
    defaults={"content": "Default content"}
)

# Count
total = await Article.objects.acount()

# Check existence
exists = await Article.objects.filter(published=True).aexists()

# Delete
deleted_count, _ = await Article.objects.filter(draft=True).adelete()

# Update
updated_count = await Article.objects.filter(draft=True).aupdate(published=True)
```

### Avoiding N+1 Queries

Use `select_related` for ForeignKey and OneToOne:

```python
# Good: 1 query with JOIN
@api.get("/articles")
async def list_articles():
    articles = []
    async for article in Article.objects.select_related("author")[:20]:
        articles.append({
            "id": article.id,
            "author_name": article.author.username  # No extra query!
        })
    return {"articles": articles}
```

Use `prefetch_related` for ManyToMany and reverse ForeignKey:

```python
# Good: 2 queries (articles + tags)
@api.get("/articles")
async def list_articles():
    queryset = Article.objects.select_related("author").prefetch_related("tags")
    async for article in queryset[:20]:
        tags = [tag.name for tag in article.tags.all()]  # Already prefetched!
    return {"articles": [...]}
```

### Transactions

Use `sync_to_async` for database transactions:

```python
from asgiref.sync import sync_to_async
from django.db import transaction

@api.post("/transfer")
async def transfer_funds(from_id: int, to_id: int, amount: float):
    @sync_to_async
    def do_transfer():
        with transaction.atomic():
            from_account = Account.objects.select_for_update().get(id=from_id)
            to_account = Account.objects.select_for_update().get(id=to_id)
            from_account.balance -= amount
            to_account.balance += amount
            from_account.save()
            to_account.save()
        return {"success": True}

    return await do_transfer()
```

### Aggregations

```python
from django.db.models import Count, Avg, Q

@api.get("/stats")
async def article_stats():
    stats = await Article.objects.aaggregate(
        total=Count("id"),
        published=Count("id", filter=Q(published=True)),
        avg_comments=Avg("comment_count")
    )
    return stats
```

### Bulk Operations

```python
# Bulk create
articles = [
    Article(title=f"Article {i}", content="...")
    for i in range(100)
]
created = await Article.objects.abulk_create(articles)

# Bulk update
await Article.objects.filter(draft=True).aupdate(published=True)
```

---

## Settings Configuration

Full reference for Django-Bolt settings in `settings.py`:

```python
# settings.py

# Required: Add to INSTALLED_APPS
INSTALLED_APPS = [
    ...
    "django_bolt"
    ...
]

# Django-Bolt Configuration
BOLT = {
    # Server settings
    "HOST": "0.0.0.0",           # Server host
    "PORT": 8000,                # Server port
    "PROCESSES": 4,              # Number of worker processes
    "BACKLOG": 2048,             # Socket backlog size
    "KEEP_ALIVE": 30,            # Keep-alive timeout in seconds

    # Debug mode
    "DEBUG": False,

    # Enable signals (may impact performance)
    "EMIT_SIGNALS": False,
}

# JWT Configuration
JWT_SECRET_KEY = "your-secret-key"
JWT_ALGORITHM = "HS256"
JWT_EXPIRATION = 3600  # seconds

# File Upload Settings
from django_bolt import FileSize
BOLT_MAX_UPLOAD_SIZE = FileSize.MB_50  # 50 MB max
BOLT_MEMORY_SPOOL_THRESHOLD = 5 * 1024 * 1024  # 5 MB

# Compression Configuration
from django_bolt.middleware import CompressionConfig

BOLT_COMPRESSION = CompressionConfig(
    backend="gzip",
    minimum_size=500,  # Only compress responses > 500 bytes
)

# CORS Configuration
BOLT_CORS = {
    "allow_origins": ["https://example.com"],
    "allow_methods": ["GET", "POST", "PUT", "DELETE"],
    "allow_headers": ["*"],
    "allow_credentials": True,
}
```

### Command-Line Options

```bash
# Run development server
python manage.py runbolt --dev

# Run production server with multiple processes
python manage.py runbolt --host 0.0.0.0 --port 8000 --processes 4

# Increase socket backlog for high traffic
python manage.py runbolt --processes 4 --backlog 2048

# Adjust keep-alive timeout
python manage.py runbolt --processes 4 --keep-alive 30
```

---

## Deployment

Production deployment guide for Django-Bolt.

### Running as a Service

#### With systemd

Create `/etc/systemd/system/django-bolt.service`:

```ini
[Unit]
Description=Django-Bolt API Server
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/path/to/your/project
ExecStart=/path/to/venv/bin/python manage.py runbolt --host 127.0.0.1 --port 8000 --processes 4
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable django-bolt
sudo systemctl start django-bolt
sudo systemctl status django-bolt
```

#### With supervisor

Create `/etc/supervisor/conf.d/django-bolt.conf`:

```ini
[program:django-bolt]
command=/path/to/venv/bin/python manage.py runbolt --host 127.0.0.1 --port 8000 --processes 4
directory=/path/to/your/project
user=www-data
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/django-bolt.log
```

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start django-bolt
```

### Reverse Proxy with nginx

```nginx
upstream django_bolt {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name api.example.com;

    location / {
        proxy_pass http://django_bolt;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Database Connections

#### psycopg pool (recommended for Django 5.1+)

```python
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "mydb",
        "USER": "myuser",
        "PASSWORD": "mypassword",
        "HOST": "localhost",
        "CONN_MAX_AGE": 0,
        "OPTIONS": {
            "pool": {
                "min_size": 2,
                "max_size": 10,
            }
        },
    }
}
```

#### PgBouncer (external pooler)

```python
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "mydb",
        "HOST": "127.0.0.1",
        "PORT": "6432",  # PgBouncer port
        "CONN_MAX_AGE": 0,
        "DISABLE_SERVER_SIDE_CURSORS": True,
    }
}
```

### Docker Deployment

```dockerfile
# Dockerfile
FROM python:3.12-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

EXPOSE 8000

CMD ["python", "manage.py", "runbolt", "--host", "0.0.0.0", "--port", "8000", "--processes", "4"]
```

```yaml
# docker-compose.yml
services:
  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/mydb
    depends_on:
      - db

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: mydb
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
```

### Workers vs Processes

Django-Bolt uses processes for parallelism, not workers. Each process has its own GIL:

```bash
# Use processes for parallelism (not workers)
python manage.py runbolt --processes 4

# Rule of thumb: set --processes to number of CPU cores
```

---

## Comparison with DRF/Django Ninja

### When to Choose Django Bolt

| Feature | Django Bolt | Django REST Framework | Django Ninja |
|---------|-------------|----------------------|--------------|
| **Performance** | ~188k RPS | ~10-15k RPS | ~50-70k RPS |
| **Python GIL** | Bypassed via processes | Blocked | Blocked |
| **Django ORM** | Full async | Sync only | Full async |
| **Type Safety** | Full (msgspec) | Partial (serializers) | Full (Pydantic) |
| **Django Admin** | Compatible | Compatible | Compatible |
| **Django Packages** | Most work | All work | Most work |
| **Learning Curve** | Low | Low | Medium |
| **WebSocket** | Built-in | Via channels | Via channels |

### Choose Django Bolt When:

- You need maximum performance (60k+ RPS)
- You want to keep using Django ORM without async wrappers
- You're building new APIs and performance matters
- You want to bypass Python's GIL limitations
- You prefer msgspec over Pydantic for validation
- You want to incrementally migrate from DRF

### Choose Django REST Framework When:

- You have an existing DRF codebase
- You need extensive third-party packages
- You're new to async programming
- You need Django REST Framework's browserable API

### Choose Django Ninja When:

- You prefer Pydantic for validation
- You're building new APIs from scratch
- You need a more Pythonic async experience
- You want better IDE support via Pydantic

---

## Migration from DRF

Step-by-step guide to migrate Django REST Framework views to Django Bolt.

### Step 1: Install Django Bolt

```bash
pip install django-bolt
```

Add to `INSTALLED_APPS`:

```python
INSTALLED_APPS = [
    ...
    "django_bolt"
    ...
]
```

### Step 2: Convert Function-Based Views

**Before (DRF):**

```python
# views.py (DRF)
from rest_framework.decorators import api_view
from rest_framework.response import Response

@api_view(["GET", "POST"])
def user_list(request):
    if request.method == "GET":
        users = User.objects.all()
        serializer = UserSerializer(users, many=True)
        return Response(serializer.data)

    serializer = UserSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=201)
    return Response(serializer.errors, status=400)
```

**After (Django Bolt):**

```python
# api.py (Django Bolt)
from django_bolt import BoltAPI
import msgspec

api = BoltAPI()

class UserSchema(msgspec.Struct):
    id: int
    username: str
    email: str

@api.get("/users")
async def list_users():
    users = await User.objects.all()
    return [{"id": u.id, "username": u.username, "email": u.email} for u in users]

@api.post("/users")
async def create_user(data: UserSchema):
    user = await User.objects.acreate(
        username=data.username,
        email=data.email
    )
    return {"id": user.id, "username": user.username}, 201
```

### Step 3: Convert Class-Based Views

**Before (DRF):**

```python
# views.py (DRF)
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .serializers import UserSerializer

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]
```

**After (Django Bolt):**

```python
# api.py (Django Bolt)
from django_bolt import BoltAPI, ViewSet
from django_bolt.auth import JWTAuthentication, IsAuthenticated
from django.contrib.auth import get_user_model

User = get_user_model()
api = BoltAPI()

@api.viewset("/users", auth=[JWTAuthentication()], guards=[IsAuthenticated()])
class UserViewSet(ViewSet):
    async def list(self, request):
        users = await User.objects.all()
        return [{"id": u.id, "username": u.username} for u in users]

    async def retrieve(self, request, pk: int):
        user = await User.objects.aget(id=pk)
        return {"id": user.id, "username": user.username}

    async def create(self, request):
        data = await request.json()
        user = await User.objects.acreate(**data)
        return {"id": user.id}, 201

    async def destroy(self, request, pk: int):
        await User.objects.filter(id=pk).adelete()
        return {"deleted": True}
```

### Step 4: Convert Serializers

**Before (DRF):**

```python
# serializers.py (DRF)
from rest_framework import serializers
from .models import Article

class ArticleSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source="author.username", read_only=True)

    class Meta:
        model = Article
        fields = ["id", "title", "content", "author", "author_name", "created_at"]
```

**After (Django Bolt):**

```python
# schemas.py (Django Bolt)
import msgspec

class AuthorSchema(msgspec.Struct):
    id: int
    username: str

class ArticleSchema(msgspec.Struct):
    id: int
    title: str
    content: str
    author: AuthorSchema
    created_at: str
```

### Step 5: Convert URLs

**Before (DRF):**

```python
# urls.py (DRF)
from rest_framework.routers import DefaultRouter
from .views import UserViewSet

router = DefaultRouter()
router.register(r"users", UserViewSet)
urlpatterns = router.urls
```

**After (Django Bolt):**

```python
# myproject/urls.py
from django.urls import path
from myapp.api import api

urlpatterns = [
    path("api/", api.urls),
]
```

### Step 6: Running the Server

**Before (DRF):**

```bash
# Development
python manage.py runserver

# Production (with gunicorn)
gunicorn myproject.wsgi --workers 4
```

**After (Django Bolt):**

```bash
# Development
python manage.py runbolt --dev

# Production (standalone, no gunicorn needed)
python manage.py runbolt --processes 4
```

### Migration Checklist

- [ ] Install django-bolt and add to INSTALLED_APPS
- [ ] Convert function-based views to Django Bolt handlers
- [ ] Convert class-based views to ViewSets
- [ ] Replace DRF serializers with msgspec structs
- [ ] Update URL configuration
- [ ] Test authentication (JWT, API key)
- [ ] Test file uploads if applicable
- [ ] Run load tests to verify performance
- [ ] Remove DRF dependencies when ready

---

## Best Practices

### API Design

```python
# ✅ GOOD: Use decorators
from django_bolt.http import HttpRequest, JsonResponse
from django_bolt.utils.decorators import json_response

@json_response()
def get_users(request: HttpRequest) -> JsonResponse:
    return {"users": []}

# ✅ GOOD: Serializer validation
from django_bolt.serializers import Serializer

class UserSerializer(Serializer):
    name: str
    email: str
    
    def validate_email(self, value):
        if not value.endswith('@company.com'):
            raise ValidationError("Must use company email")
        return value
```

### Error Handling

```python
from django_bolt.errors import ApiError

# ✅ GOOD: Raise proper errors
def get_user(request, user_id):
    user = User.objects.get_or_404(user_id)
    if not user.is_active:
        raise ApiError(400, "User not active")
    return user
```

### Performance

```python
# ✅ GOOD: Use built-in caching
from django_bolt.cache import cache_page

@cache_page(60 * 15)
def get_data(request):
    ...

# ✅ GOOD: Query optimization
users = User.objects.select_related('profile').prefetch_related('posts')
```

### Do:
- Use decorators for common patterns
- Leverage built-in serializers
- Enable caching for static data

### Don't:
- Mix Django ORM with Bolt models
- Skip error handling

---

## References

- **GitHub**: https://github.com/dj-bolt/django-bolt
- **Documentation**: https://bolt.farhana.li
- **Performance Comparison**: Faster than FastAPI, similar to Go/Node.js performance