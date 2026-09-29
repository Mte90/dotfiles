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

### Django Ninja vs Django REST Framework

| Feature | Django Ninja | DRF |
|---------|-------------|-----|
| Validation | Pydantic | Serializers |
| Performance | Very Fast | Fast |
| Type Safety | Full | Partial |
| OpenAPI | Auto | Manual (drf-spectacular) |
| Learning Curve | Easy | Moderate |
| Async | Native | Limited |

**Use Django Ninja when:**
- Building new REST APIs
- Need type safety and IDE support
- Want automatic OpenAPI docs
- Prefer Pydantic validation

**Use DRF when:**
- Have existing DRF codebase
- Need browsable API (HTML responses)
- Require specific DRF features

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
├── api/
│   ├── __init__.py
│   ├── urls.py
│   ├── schemas.py
│   ├── views/
│   │   ├── __init__.py
│   │   ├── users.py
│   │   └── posts.py
│   └── auth.py
├── models.py
└── settings.py
```

## Schema Definitions

### Pydantic v2 Context Support

```python
# Django 6.0+ context access in schemas
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
    author: str
    created_at: datetime

class PostDetailSchema(Schema):
    id: int
    title: str
    slug: str
    body: str
    author: UserSchema
    categories: List[str]
    comments: List[CommentSchema]
    created_at: datetime
    updated_at: datetime
```

### Validators

```python
from ninja import Schema
from pydantic import validator, root_validator
import re

class UserCreate(Schema):
    username: str
    email: str
    password: str
    
    @validator('username')
    def validate_username(cls, v):
        if len(v) < 3:
            raise ValueError('Username must be at least 3 characters')
        if not re.match(r'^[a-zA-Z0-9_]+$', v):
            raise ValueError('Username can only contain letters, numbers, and underscores')
        return v
    
    @validator('email')
    def validate_email(cls, v):
        if '@' not in v:
            raise ValueError('Invalid email format')
        return v.lower()
    
    @validator('password')
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')
        return v
    
    @root_validator
    def validate_all(cls, values):
        # Cross-field validation
        if values.get('username') == values.get('password'):
            raise ValueError('Password cannot be the same as username')
        return values
```

### Custom Types

```python
from ninja import Schema
from typing import Annotated, List
from pydantic import Field, HttpUrl

# Using Annotated for reusable validators
class PostCreate(Schema):
    title: Annotated[str, Field(min_length=5, max_length=200)]
    slug: Annotated[str, Field(pattern=r'^[a-z0-9-]+$')]
    body: Annotated[str, Field(min_length=10)]
    tags: Annotated[List[str], Field(max_items=10)] = []
    
# Custom type with validator
class URLSchema(Schema):
    url: HttpUrl  # Validates URL format

# Using constrint
from pydantic import constr

ShortStr = constr(max_length=50)
EmailStr = constr(regex=r'^[^@]+@[^@]+\.[^@]+$')

class ContactSchema(Schema):
    name: ShortStr
    email: EmailStr
```

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
def get_comment(
    request,
    post_id: int,
    comment_id: int
):
    """Path parameters with type hints are automatically validated."""
    comment = get_object_or_404(Comment, id=comment_id, post_id=post_id)
    return {"comment": comment.content}

# String path parameters
@api.get("/categories/{slug}/posts")
def category_posts(request, slug: str):
    category = get_object_or_404(Category, slug=slug)
    return category.posts.all()

# UUID path parameters
import uuid

@api.get("/orders/{order_id}")
def get_order(request, order_id: uuid.UUID):
    order = get_object_or_404(Order, id=order_id)
    return order
```

### Query Parameters

```python
from ninja import Query, Schema
from typing import Optional, List
from datetime import date

class FilterParams(Schema):
    search: Optional[str] = None
    status: Optional[str] = None
    category: Optional[int] = None
    tags: Optional[List[str]] = None
    created_after: Optional[date] = None
    created_before: Optional[date] = None
    ordering: Optional[str] = "-created_at"
    page: int = 1
    page_size: int = 20

@api.get("/posts", response=List[PostSchema])
def list_posts(request, filters: FilterParams = Query(...)):
    """Query parameters are automatically validated and parsed."""
    posts = Post.objects.all()
    
    if filters.search:
        posts = posts.filter(
            Q(title__icontains=filters.search) |
            Q(body__icontains=filters.search)
        )
    
    if filters.status:
        posts = posts.filter(status=filters.status)
    
    if filters.category:
        posts = posts.filter(categories__id=filters.category)
    
    if filters.tags:
        posts = posts.filter(tags__name__in=filters.tags)
    
    if filters.created_after:
        posts = posts.filter(created_at__gte=filters.created_after)
    
    if filters.created_before:
        posts = posts.filter(created_at__lte=filters.created_before)
    
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
    """Request body is automatically validated against schema."""
    # payload is a Pydantic model instance
    post = Post.objects.create(
        title=payload.title,
        body=payload.body,
        author=request.user
    )
    
    if payload.category_ids:
        post.categories.set(payload.category_ids)
    
    if payload.tags:
        post.tags.set(payload.tags)
    
    return post

# Multiple body parameters
@api.post("/posts/{post_id}/comments")
def add_comment(
    request,
    post_id: int,
    content: str = Body(...),
    author_name: str = Body(...),
    author_email: str = Body(...)
):
    post = get_object_or_404(Post, id=post_id)
    comment = Comment.objects.create(
        post=post,
        content=content,
        author_name=author_name,
        author_email=author_email
    )
    return {"id": comment.id}
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
    """Handle form submission."""
    send_contact_email(data.name, data.email, data.message)
    return {"status": "sent"}

# File uploads with form data
@api.post("/upload")
def upload_with_data(
    request,
    file: UploadedFile = File(...),
    description: str = Form(...),
    tags: List[str] = Form(default=[])
):
    """Upload file with metadata."""
    # Handle file and form data together
    pass
```

## Deep Dives

For detailed coverage of advanced topics, load these reference files on demand:

- **references/auth-pagination-errors.md** — Authentication methods (JWT, API keys, session), pagination strategies (LimitOffset, PageNumber, cursor-based), and error handling patterns
- **references/crud-patterns.md** — Complete CRUD operations with Django ORM, bulk operations, and relationship handling
- **references/files-async-openapi.md** — File uploads, async view support, and OpenAPI/Swagger documentation customization
- **references/django-integration.md** — Django model integration, middleware, signals, and production best practices
- **references/testing-troubleshooting.md** — Testing with pytest, authentication testing, and common issue resolutions

## Ecosystem Libraries

### django-ninja-extra
- **URL**: https://github.com/eadwinCode/django-ninja-extra
- **PyPI**: `django-ninja-extra`
- **Version**: 0.31.7 (requires Python >=3.7, Django >=2.2, django-ninja >=1.6.3)

Extension of Django Ninja that adds class-based views (controllers) and advanced features on top of the framework.

**Key features:**
- Class-based controllers via `@api_controller` and HTTP method decorators (`http_get`, etc.), registered with `api.register_controllers()`
- DRF-like permission system: controller-level permissions, route-level overrides, custom `PermissionBase` subclasses
- Dependency injection built on the `Injector` library; injectable service layer (`ModelController`/`ModelService` pattern)
- Inherits Django Ninja's core features (Pydantic validation, async, OpenAPI docs, throttling)

```bash
pip install django-ninja-extra
```
Add `'ninja_extra'` to `INSTALLED_APPS`.

### ninja-schema
- **URL**: https://github.com/eadwinCode/ninja-schema
- **PyPI**: `ninja-schema`
- **Version**: 0.14.3 (requires Python >=3.8)

Converts Django ORM models to Pydantic schemas with full Pydantic feature support. Inspired by django-ninja and djantic.

**Key features:**
- `ModelSchema` with `include`, `exclude`, `optional`, and `depth` config (nested relation schema generation)
- `model_validator` for field-level pre/post validation
- `from_orm()` to instantiate schemas from model instances; `apply_to_model()` to write schema data back to a model instance
- Supports Pydantic v1 and v2 (dual support since 0.13.4)

```bash
pip install ninja-schema
```

### django-ninja-jwt
- **URL**: https://github.com/eadwinCode/django-ninja-jwt
- **PyPI**: `django-ninja-jwt`
- **Version**: 5.4.5 (requires Python >=3.7, `django-ninja-extra>=0.30.5`, `pyjwt>=1.7.1,<3`)

JSON Web Token (JWT) plugin for Django-Ninja. Fork of Jazzband's Simple JWT that removes the DRF dependency and targets Django Ninja. Note: `django-ninja-jwt` depends on `django-ninja-extra`, so installing JWT pulls in Extra.

**Key features:**
- `NinjaJWTDefaultController` registering `obtain_token`, `refresh_token`, and `verify_token` routes
- Custom controllers by inheriting the token controller classes and registering via `api.register_controller()`
- Customizable token classes and claims; configuration via `pydantic-settings`
- Optional use with a plain Django Ninja `Router`

```bash
pip install django-ninja-jwt
```

### django-ninja-aio-crud
- **URL**: https://github.com/caspel26/django-ninja-aio-crud
- **PyPI**: `django-ninja-aio-crud`
- **Version**: 2.34.2 (requires Python >=3.10,<3.15; django-ninja >=1.3.0,<1.7.0)

Async CRUD framework for Django Ninja providing automatic schema generation, filtering, pagination, auth, and M2M management.

**Key features:**
- Fully async CRUD viewsets (create/list/retrieve/update/delete) via `@api.viewset(Model)` and `APIViewSet`
- Two schema styles: meta-driven `Serializer` (existing models) or `ModelSerializer` models with `Read/Create/UpdateSerializer` inner classes
- Auto Pydantic schemas (read/create/update) and dynamic query params via `pydantic.create_model`
- Per-method auth (incl. `AsyncJwtBearer` using `joserfc`), async pagination, M2M relation endpoints with filtering
- Bulk create/update/delete endpoints, `@action`/`@on` custom endpoints, lifecycle hooks
- ORJSON rendering; optional MCP extra exposing ViewSets as Model Context Protocol tools

```bash
pip install django-ninja-aio-crud
```
MCP support: `pip install "django-ninja-aio-crud[mcp]"`

### django-contract-tester
- **URL**: https://github.com/maticardenas/django-contract-tester
- **PyPI**: `django-contract-tester`
- **Version**: 1.8.2

Test utility for validating DRF and Django Ninja test requests/responses against OpenAPI 2.0/3.0.x/3.1.x schemas. Forked from `snok/drf-openapi-tester`.

**Key features:**
- `SchemaTester` with `validate_response()` / `validate_request()`; auto-detects `drf-yasg` or `drf-spectacular` schemas, or loads schema files
- `OpenAPIClient` (extends DRF `APIClient`) and `OpenAPINinjaClient` (extends the Django Ninja test client) for automatic per-request validation
- Built-in key-case testers (`is_camel_case`, `is_pascal_case`, `is_snake_case`, `is_kebab_case`), `ignore_case`, custom validators
- Config file support (`.django-contract-tester` INI or `[tool.django-contract-tester]` in `pyproject.toml`)

```bash
pip install django-contract-tester
```
Optional extras: `django-ninja`, `drf-yasg`, `drf-spectacular`.

## References

- **Official Documentation**: https://django-ninja.dev/
- **GitHub Repository**: https://github.com/vitalik/django-ninja
- **Pydantic Documentation**: https://docs.pydantic.dev/
- **OpenAPI Specification**: https://swagger.io/specification/
- **Django Documentation**: https://docs.djangoproject.com/