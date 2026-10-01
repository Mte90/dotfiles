---
name: django-ninja
description: Use when building Django REST APIs with django-ninja - Pydantic schemas, routers, CRUD endpoints, authentication, pagination, file uploads, async views, OpenAPI docs, or migrating from DRF
metadata:
  author: mte90
  version: 2.0.0
  tags:
    - python
    - django
    - rest-api
    - pydantic
    - openapi
    - type-safe
---

# Django Ninja

Complete reference for building fast, type-safe REST APIs with Django and Pydantic.

## Overview

Django Ninja is a web framework for building APIs with Django and Python 3.6+ type hints.

**Versions**: django-ninja 1.6.x + Django 6.0 compatible. Requires Pydantic v2. It provides automatic request validation, response serialization, and generates OpenAPI documentation.

**Key Features:**
- Fast: Built on Pydantic for high performance
- Type-safe: Full IDE autocomplete and type checking
- Auto docs: Automatic OpenAPI/Swagger documentation
- Easy: Django integration with minimal boilerplate
- Async support: Native async/await support

### DRF to Django Ninja Migration

**What has no clean equivalent:** browsable API, `get_serializer_class()` polymorphism, complex nested serializers with dynamic depth.

**Mapping table:**

| DRF pattern | Django Ninja equivalent |
|-------------|------------------------|
| `ModelSerializer` | `ModelSchema` (generated from model) |
| `ViewSet` | `Router` + `api.get`/`api.post` decorators |
| `perform_create()` | resolver body (function body) |
| `APIView` class | function-based handler |
| `IsAuthenticated` | operation-level auth callback (`auth=`) |
| `PageNumberPagination` | `paginate(PageNumberPagination)` decorator |

**Before (DRF):**

```python
# serializers.py
class PostSerializer(serializers.ModelSerializer):
    class Meta:
        model = Post
        fields = ['id', 'title', 'body']

# views.py
class PostViewSet(viewsets.ModelViewSet):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [IsAuthenticated]
    
    def perform_create(self, serializer):
        serializer.save(author=self.request.user)
```

**After (Django Ninja):**

```python
# schemas.py
class PostSchema(ModelSchema):
    class Config:
        model = Post
        model_fields = ['id', 'title', 'body']

# api.py
@api.get("/posts", response=List[PostSchema], auth=IsAuthenticated())
def list_posts(request):
    return Post.objects.all()

@api.post("/posts", response=PostSchema, auth=IsAuthenticated())
def create_post(request, payload: PostCreateSchema):
    return Post.objects.create(author=request.user, **payload.dict())
```

## Installation

```bash
pip install django-ninja
```

### Django Integration

```python
# settings.py
INSTALLED_APPS = [
    # ...
    'ninja',
]
```

### Basic Setup

```python
# api.py
from ninja import NinjaAPI

api = NinjaAPI()

@api.get("/hello")
def hello(request):
    return {"message": "Hello World"}

# urls.py
from django.urls import path
from .api import api

urlpatterns = [
    path("api/", api.urls),
]
```

### Project Structure

```
myproject/
├── api/           # NinjaAPI, routers, schemas
├── models.py
└── settings.py
```

## Schema Definitions

### Pydantic v2 Context Support (Django 6.0+)

```python
class Payload(Schema):
    id: int
    request_path: str
    
    @staticmethod
    def resolve_request_path(data, context):
        return context["request"].get_full_path()
```

### Basic Schema

```python
from ninja import Schema
from datetime import datetime
from typing import Optional, List

class UserIn(Schema):
    username: str
    email: str
    password: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None

class UserOut(Schema):
    id: int
    username: str
    email: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    created_at: datetime

class UserUpdate(Schema):
    username: Optional[str] = None
    email: Optional[str] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
```

### ModelSchema (from Django Models)

```python
from ninja import ModelSchema
from .models import User, Post

class UserSchema(ModelSchema):
    class Config:
        model = User
        model_fields = ['id', 'username', 'email', 'first_name', 'last_name']

class PostSchema(ModelSchema):
    author: UserSchema  # Nested schema
    
    class Config:
        model = Post
        model_fields = ['id', 'title', 'slug', 'body', 'publish', 'status']

class PostCreateSchema(ModelSchema):
    class Config:
        model = Post
        model_fields = ['title', 'body', 'status']
        model_fields_optional = ['status']  # Optional fields

class PostUpdateSchema(ModelSchema):
    class Config:
        model = Post
        model_fields = ['title', 'body', 'status']
        model_fields_optional = '__all__'  # All fields optional
```

### Nested Schemas

```python
from typing import List

class CommentSchema(Schema):
    id: int
    content: str

class PostDetailSchema(Schema):
    id: int
    title: str
    author: UserSchema
    comments: List[CommentSchema]
```

### Pydantic-in-Django specifics

For full validator/type reference, see https://docs.pydantic.dev/. Focus on these Django-specific patterns:

```python
from ninja import Schema, ModelSchema
from pydantic import ConfigDict, field_validator
from typing import Optional, Partial

# DjangoGetter for lazy model field access (avoids N+1)
class UserSchema(ModelSchema):
    class Config:
        model = User
        model_fields = ['id', 'username', 'email']

# ConfigDict(extra="forbid") for strict input validation
class CreatePostSchema(Schema):
    title: str
    body: str
    
    model_config = ConfigDict(extra="forbid")  # reject unknown fields

# Partial[ModelSchema] for PATCH requests
class UpdatePostSchema(Schema):
    title: Optional[str] = None
    body: Optional[str] = None

# Handling deferred/annotated values
class PostWithAnnotations(Schema):
    # Works with annotated/deferred model fields
    comment_count: int
    
    @staticmethod
    def resolve_comment_count(data, context):
        # Access request context for custom resolution
        return data.get("_comment_count", 0)
```

**Key points:**
- `ConfigDict(from_attributes=True)` required when reading from Django model instances (auto-set by `ModelSchema`)
- `extra="forbid"` prevents silent data loss on unknown input fields
- Use `Partial[]` or optional fields with defaults for PATCH operations

## Router & API

### HTTP Methods

```python
from ninja import NinjaAPI
from .schemas import UserIn, UserOut, PostSchema

api = NinjaAPI()

# GET - Retrieve resources
@api.get("/users", response=List[UserOut])
def list_users(request):
    return User.objects.all()

@api.get("/users/{user_id}", response=UserOut)
def get_user(request, user_id: int):
    user = get_object_or_404(User, id=user_id)
    return user

# POST - Create resources
@api.post("/users", response=UserOut)
def create_user(request, payload: UserIn):
    user = User.objects.create_user(**payload.dict())
    return user

# PUT - Full update
@api.put("/users/{user_id}", response=UserOut)
def update_user(request, user_id: int, payload: UserUpdate):
    user = get_object_or_404(User, id=user_id)
    for attr, value in payload.dict(exclude_unset=True).items():
        setattr(user, attr, value)
    user.save()
    return user

# PATCH - Partial update
@api.patch("/users/{user_id}", response=UserOut)
def partial_update_user(request, user_id: int, payload: UserUpdate):
    user = get_object_or_404(User, id=user_id)
    for attr, value in payload.dict(exclude_unset=True).items():
        setattr(user, attr, value)
    user.save()
    return user

# DELETE
@api.delete("/users/{user_id}")
def delete_user(request, user_id: int):
    user = get_object_or_404(User, id=user_id)
    user.delete()
    return {"success": True}
```

### Path Parameters

```python
from ninja import Path

@api.get("/posts/{post_id}/comments/{comment_id}")
def get_comment(request, post_id: int, comment_id: int):
    comment = get_object_or_404(Comment, id=comment_id, post_id=post_id)
    return {"comment": comment.content}

# UUID path parameters
import uuid

@api.get("/orders/{order_id}")
def get_order(request, order_id: uuid.UUID):
    return get_object_or_404(Order, id=order_id)
```

### Query Parameters

```python
from ninja import Query, Schema
from typing import Optional, List
from datetime import date

class FilterParams(Schema):
    search: Optional[str] = None
    status: Optional[str] = None
    ordering: Optional[str] = "-created_at"
    page: int = 1
    page_size: int = 20

@api.get("/posts", response=List[PostSchema])
def list_posts(request, filters: FilterParams = Query(...)):
    posts = Post.objects.all()
    
    if filters.search:
        posts = posts.filter(Q(title__icontains=filters.search))
    if filters.status:
        posts = posts.filter(status=filters.status)
    
    posts = posts.order_by(filters.ordering)
    return posts[(filters.page - 1) * filters.page_size:filters.page * filters.page_size]
```

### Request Body

```python
from ninja import Body, Schema
from typing import List

class PostCreate(Schema):
    title: str
    body: str
    category_ids: List[int]
    tags: List[str] = []

@api.post("/posts", response=PostSchema)
def create_post(request, payload: PostCreate):
    post = Post.objects.create(title=payload.title, body=payload.body, author=request.user)
    if payload.category_ids:
        post.categories.set(payload.category_ids)
    return post

# Multiple body parameters
@api.post("/posts/{post_id}/comments")
def add_comment(request, post_id: int, content: str = Body(...), author_name: str = Body(...)):
    return Comment.objects.create(post_id=post_id, content=content, author_name=author_name)
```

### Form Data

```python
from ninja import Form, Schema, File
from django.core.files.uploadedfile import UploadedFile

class ContactForm(Schema):
    name: str
    email: str
    message: str

@api.post("/contact")
def contact_form(request, data: ContactForm = Form(...)):
    send_contact_email(data.name, data.email, data.message)
    return {"status": "sent"}

@api.post("/upload")
def upload_file(request, file: UploadedFile = File(...), description: str = Form(...)):
    pass
```

## Deep Dives

For detailed coverage of advanced topics, load these reference files on demand:

- **references/auth-pagination-errors.md** — Authentication methods (JWT, API keys, session), pagination strategies (LimitOffset, PageNumber, cursor-based), and error handling patterns
- **references/crud-patterns.md** — Complete CRUD operations with Django ORM, bulk operations, and relationship handling
- **references/files-async-openapi.md** — File uploads, async view support, and OpenAPI/Swagger documentation customization
- **references/django-integration.md** — Django model integration, middleware, signals, and production best practices
- **references/testing-troubleshooting.md** — Testing with pytest, authentication testing, and common issue resolutions

## Runtime Behavior

### Validation Timing

Validation happens **before** the resolver function executes. If input fails validation:
- The operation body never runs
- A 422 response is returned immediately
- You cannot "catch" validation errors inside the resolver

```python
# This never runs if payload fails validation
@api.post("/posts", response=PostSchema)
def create_post(request, payload: PostCreateSchema):
    # payload is guaranteed valid here
    return Post.objects.create(**payload.dict())
```

### The `response=` Parameter

The `response=` annotation affects **both** runtime serialization AND OpenAPI schema generation:

```python
# Without response= — OpenAPI shows 200 with empty schema
@api.get("/health")
def health(request):
    return {"status": "ok"}  # Works, but docs are incomplete

# With response= — OpenAPI documents the actual response
@api.get("/health", response=dict)
def health(request):
    return {"status": "ok"}  # Docs show {"status": "string"}
```

**Common mistake:** omitting `response=` on endpoints that return data. The endpoint works, but generated clients (from OpenAPI) have no type information.

### `dict`/`list` Annotations Bypass Validation

```python
# Bypasses Pydantic validation — raw dict passthrough
@api.post("/raw", response=dict)
def raw_handler(request, payload: dict):
    return payload  # No validation, no type safety

# Use Schema for validation
@api.post("/typed", response=PostSchema)
def typed_handler(request, payload: PostCreateSchema):
    return Post.objects.create(**payload.dict())  # Validated
```

### `operation_id` Contract

The `operation_id` is used by code generation tools. Changing it breaks generated clients:

```python
# Stable operation IDs for client generation
@api.get("/posts/{id}", operation_id="get_post")
def get_post(request, id: int):
    ...

# Bad: changing this breaks existing generated clients
@api.get("/posts/{id}", operation_id="fetch_post")  # Breaking change!
```

## Testing

### TestClient from django-ninja

```python
from ninja.testing import TestClient
from .api import api  # Your NinjaAPI instance

client = TestClient(api)

def test_list_posts():
    response = client.get("/posts")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["title"] == "Test Post"

def test_create_post():
    payload = {"title": "New Post", "body": "Content here"}
    response = client.post("/posts", json=payload)
    assert response.status_code == 200
    assert response.json()["id"] == 1

def test_validation_error():
    payload = {"title": ""}  # Missing required field
    response = client.post("/posts", json=payload)
    assert response.status_code == 422  # Validation error
```

### Testing Auth Callbacks

```python
from ninja.security import HttpBearer

class CustomAuth(HttpBearer):
    def __call__(self, request, token: str):
        if not is_valid_token(token):
            raise PermissionError("Invalid token")
        request.user = get_user_by_token(token)
        return request.user

# Test the auth callback directly
def test_custom_auth_invalid():
    auth = CustomAuth()
    try:
        auth(None, "invalid_token")
        assert False, "Should have raised"
    except PermissionError:
        pass  # Expected

# Test endpoint with auth
@api.get("/protected", auth=CustomAuth())
def protected(request):
    return {"user": request.user.username}

def test_protected_endpoint():
    response = client.get("/protected")
    assert response.status_code == 401  # No auth header
    
    response = client.get("/protected", headers={"Authorization": "Bearer valid_token"})
    assert response.status_code == 200
```

### Separating Resolver Logic from HTTP

```python
# business_logic.py — pure functions, no HTTP dependencies
def create_post_data(title: str, body: str, author_id: int) -> dict:
    """Pure function — easy to test without Django."""
    return {
        "title": title.strip(),
        "body": body.strip(),
        "author_id": author_id,
    }

# api.py — thin HTTP layer
class PostCreateSchema(Schema):
    title: str
    body: str

@api.post("/posts", response=PostSchema)
def create_post(request, payload: PostCreateSchema):
    data = create_post_data(payload.title, payload.body, request.user.id)
    return Post.objects.create(**data)
```

## Ecosystem Libraries

### django-ninja-extra
**PyPI**: `django-ninja-extra` | **URL**: https://github.com/eadwinCode/django-ninja-extra

Use when you need class-based controllers (`@api_controller`) or DRF-style permission classes. Adds dependency injection via `Injector` library. **Tradeoff:** adds complexity; prefer function-based handlers for simple APIs.

### django-ninja-jwt
**PyPI**: `django-ninja-jwt` | **URL**: https://github.com/eadwinCode/django-ninja-jwt

Use for JWT authentication (obtain/refresh/verify tokens). **Tradeoff:** pulls in `django-ninja-extra` as a dependency. For custom token logic, write your own `HttpBearer` subclass instead.

### django-ninja-aio-crud
**PyPI**: `django-ninja-aio-crud` | **URL**: https://github.com/caspel26/django-ninja-aio-crud

Use for auto-generated async CRUD endpoints with built-in filtering/pagination. **Tradeoff:** opinionated structure; harder to customize than hand-written handlers.

### django-contract-tester
**PyPI**: `django-contract-tester` | **URL**: https://github.com/maticardenas/django-contract-tester

Use to validate test requests/responses against OpenAPI schemas. **Tradeoff:** only needed for strict contract testing; regular pytest assertions work for most cases.

## References

- **Official Documentation**: https://django-ninja.dev/
- **GitHub Repository**: https://github.com/vitalik/django-ninja
- **Pydantic Documentation**: https://docs.pydantic.dev/
- **OpenAPI Specification**: https://swagger.io/specification/
- **Django Documentation**: https://docs.djangoproject.com/
