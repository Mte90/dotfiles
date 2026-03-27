---
name: django-ninja
description: "Fast Django REST framework with Pydantic validation, type hints, and automatic OpenAPI documentation for building type-safe APIs"
metadata:
  author: "OSS AI Skills"
  version: "1.0.0"
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

Django Ninja is a web framework for building APIs with Django and Python 3.6+ type hints. It provides automatic request validation, response serialization, and generates OpenAPI documentation.

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

## CRUD Operations

### Complete CRUD Example

```python
from ninja import NinjaAPI, ModelSchema, Schema
from django.shortcuts import get_object_or_404
from typing import List, Optional

api = NinjaAPI()

# Schemas
class CategoryOut(ModelSchema):
    class Config:
        model = Category
        model_fields = ['id', 'name', 'slug']

class PostOut(ModelSchema):
    author: UserSchema
    categories: List[CategoryOut]
    
    class Config:
        model = Post
        model_fields = ['id', 'title', 'slug', 'body', 'status', 'publish']

class PostIn(Schema):
    title: str
    slug: str
    body: str
    status: str = 'draft'
    category_ids: List[int] = []

class PostUpdate(Schema):
    title: Optional[str] = None
    slug: Optional[str] = None
    body: Optional[str] = None
    status: Optional[str] = None
    category_ids: Optional[List[int]] = None

# List
@api.get("/posts", response=List[PostOut])
def list_posts(request):
    return Post.objects.select_related('author').prefetch_related('categories').all()

# Retrieve
@api.get("/posts/{post_id}", response=PostOut)
def get_post(request, post_id: int):
    post = get_object_or_404(
        Post.objects.select_related('author').prefetch_related('categories'),
        id=post_id
    )
    return post

# Create
@api.post("/posts", response=PostOut)
def create_post(request, payload: PostIn):
    post = Post(
        title=payload.title,
        slug=payload.slug,
        body=payload.body,
        status=payload.status,
        author=request.user
    )
    post.save()
    
    if payload.category_ids:
        post.categories.set(payload.category_ids)
    
    return post

# Full Update
@api.put("/posts/{post_id}", response=PostOut)
def update_post(request, post_id: int, payload: PostIn):
    post = get_object_or_404(Post, id=post_id)
    
    post.title = payload.title
    post.slug = payload.slug
    post.body = payload.body
    post.status = payload.status
    post.save()
    
    post.categories.set(payload.category_ids)
    
    return post

# Partial Update
@api.patch("/posts/{post_id}", response=PostOut)
def partial_update_post(request, post_id: int, payload: PostUpdate):
    post = get_object_or_404(Post, id=post_id)
    
    update_data = payload.dict(exclude_unset=True)
    
    if 'category_ids' in update_data:
        category_ids = update_data.pop('category_ids')
        post.categories.set(category_ids)
    
    for attr, value in update_data.items():
        setattr(post, attr, value)
    
    post.save()
    return post

# Delete
@api.delete("/posts/{post_id}")
def delete_post(request, post_id: int):
    post = get_object_or_404(Post, id=post_id)
    post.delete()
    return {"success": True, "id": post_id}
```

### Bulk Operations

```python
from ninja import Schema
from typing import List

class BulkPostCreate(Schema):
    posts: List[PostIn]

@api.post("/posts/bulk", response=List[PostOut])
def bulk_create_posts(request, payload: BulkPostCreate):
    """Create multiple posts at once."""
    created_posts = []
    
    for post_data in payload.posts:
        post = Post.objects.create(
            **post_data.dict(exclude={'category_ids'}),
            author=request.user
        )
        if post_data.category_ids:
            post.categories.set(post_data.category_ids)
        created_posts.append(post)
    
    return created_posts

@api.post("/posts/bulk-delete")
def bulk_delete_posts(request, ids: List[int]):
    """Delete multiple posts."""
    deleted, _ = Post.objects.filter(id__in=ids).delete()
    return {"deleted": deleted}
```

## Authentication

### Global Authentication

```python
from ninja import NinjaAPI
from ninja.security import APIKeyQuery, APIKeyHeader, HttpBearer

# API Key in Header
class ApiKey(APIKeyHeader):
    param_name = "X-API-Key"
    
    def authenticate(self, request, key):
        try:
            return User.objects.get(api_key=key)
        except User.DoesNotExist:
            pass

# API Key in Query
class QueryApiKey(APIKeyQuery):
    param_name = "api_key"
    
    def authenticate(self, request, key):
        try:
            return User.objects.get(api_key=key)
        except User.DoesNotExist:
            pass

# Bearer Token (JWT)
class AuthBearer(HttpBearer):
    def authenticate(self, request, token):
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=['HS256'])
            user = User.objects.get(id=payload['user_id'])
            if user.is_active:
                return user
        except (jwt.DecodeError, User.DoesNotExist):
            pass

# Use authentication
api = NinjaAPI(auth=ApiKey())
```

### Per-Endpoint Authentication

```python
from ninja import NinjaAPI
from ninja.security import django_auth

public_api = NinjaAPI(auth=None)  # No auth by default
private_api = NinjaAPI(auth=AuthBearer())

# Public endpoints
@public_api.get("/public/data")
def public_data(request):
    return {"message": "This is public"}

# Private endpoints
@private_api.get("/private/data", auth=AuthBearer())
def private_data(request):
    # request.auth contains authenticated user
    return {"user": request.auth.username}

# Mix auth on same API
api = NinjaAPI()

@api.get("/public")
def public_endpoint(request):
    return {"public": True}

@api.get("/private", auth=AuthBearer())
def private_endpoint(request):
    return {"user": request.auth.username}

# Multiple auth methods
@api.get("/multi-auth", auth=[ApiKey(), AuthBearer()])
def multi_auth_endpoint(request):
    """Try multiple auth methods."""
    return {"user": request.auth.username}
```

### JWT Authentication

```python
from ninja import Schema, NinjaAPI
from ninja.security import HttpBearer
import jwt
from datetime import datetime, timedelta
from django.conf import settings

class AuthBearer(HttpBearer):
    def authenticate(self, request, token):
        try:
            payload = jwt.decode(
                token,
                settings.SECRET_KEY,
                algorithms=['HS256']
            )
            user = User.objects.get(id=payload['user_id'])
            if user.is_active:
                return user
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError, User.DoesNotExist):
            return None

class LoginSchema(Schema):
    username: str
    password: str

class TokenSchema(Schema):
    access: str
    refresh: str
    expires_in: int

api = NinjaAPI()

@api.post("/login", response=TokenSchema)
def login(request, credentials: LoginSchema):
    from django.contrib.auth import authenticate
    
    user = authenticate(
        username=credentials.username,
        password=credentials.password
    )
    
    if not user:
        return {"error": "Invalid credentials"}, 401
    
    # Generate tokens
    access_payload = {
        'user_id': user.id,
        'exp': datetime.utcnow() + timedelta(hours=1),
        'type': 'access'
    }
    
    refresh_payload = {
        'user_id': user.id,
        'exp': datetime.utcnow() + timedelta(days=7),
        'type': 'refresh'
    }
    
    return {
        'access': jwt.encode(access_payload, settings.SECRET_KEY, algorithm='HS256'),
        'refresh': jwt.encode(refresh_payload, settings.SECRET_KEY, algorithm='HS256'),
        'expires_in': 3600
    }

@api.post("/refresh", response=TokenSchema)
def refresh_token(request, refresh: str = Body(...)):
    try:
        payload = jwt.decode(refresh, settings.SECRET_KEY, algorithms=['HS256'])
        
        if payload.get('type') != 'refresh':
            return {"error": "Invalid token type"}, 401
        
        user = User.objects.get(id=payload['user_id'])
        
        access_payload = {
            'user_id': user.id,
            'exp': datetime.utcnow() + timedelta(hours=1),
            'type': 'access'
        }
        
        return {
            'access': jwt.encode(access_payload, settings.SECRET_KEY, algorithm='HS256'),
            'refresh': refresh,
            'expires_in': 3600
        }
    except jwt.InvalidTokenError:
        return {"error": "Invalid token"}, 401

# Protected endpoints
@api.get("/profile", auth=AuthBearer())
def profile(request):
    return {"username": request.auth.username, "email": request.auth.email}
```

### Session Authentication

```python
from ninja.security import django_auth

api = NinjaAPI(auth=django_auth)

@api.get("/me")
def current_user(request):
    # request.user is authenticated via Django session
    return {
        "id": request.user.id,
        "username": request.user.username,
        "email": request.user.email
    }
```

### Basic Authentication

```python
from ninja.security import HttpBasicAuth

class BasicAuth(HttpBasicAuth):
    def authenticate(self, request, username, password):
        from django.contrib.auth import authenticate
        user = authenticate(username=username, password=password)
        if user and user.is_active:
            return user
        return None

api = NinjaAPI(auth=BasicAuth())

@api.get("/protected")
def protected(request):
    return {"user": request.auth.username}
```

### Custom Authentication

```python
from ninja.security import APIKeyHeader
from functools import wraps

class CustomAuth(APIKeyHeader):
    param_name = "Authorization"
    
    def authenticate(self, request, token):
        # Custom token validation
        if not token.startswith("Bearer "):
            return None
        
        token = token[7:]  # Remove "Bearer "
        
        try:
            # Custom token validation logic
            user = validate_custom_token(token)
            return user
        except Exception:
            return None

# Function-based auth
def custom_authenticator(request):
    token = request.headers.get('X-Custom-Token')
    if not token:
        return None
    
    try:
        return validate_token(token)
    except Exception:
        return None

@api.get("/custom-auth", auth=custom_authenticator)
def custom_auth_endpoint(request):
    return {"authenticated": True}
```

## Pagination

### LimitOffsetPagination

```python
from ninja import NinjaAPI, Schema
from ninja.pagination import paginate, LimitOffsetPagination

api = NinjaAPI()

class PostOut(ModelSchema):
    class Config:
        model = Post
        model_fields = ['id', 'title', 'slug']

@api.get("/posts", response=List[PostOut])
@paginate(LimitOffsetPagination)
def list_posts(request):
    """Returns paginated results with limit and offset."""
    return Post.objects.all()

# Response format:
# {
#   "items": [...],
#   "count": 100
# }
# 
# Query: /posts?limit=10&offset=20
```

### PageNumberPagination

```python
from ninja.pagination import PageNumberPagination

class CustomPagination(PageNumberPagination):
    page_size = 20
    page_query_param = 'page'
    page_size_query_param = 'page_size'
    max_page_size = 100

@api.get("/posts", response=List[PostOut])
@paginate(CustomPagination)
def list_posts(request):
    """Returns paginated results with page number."""
    return Post.objects.all()

# Response format:
# {
#   "items": [...],
#   "count": 100,
#   "page": 1,
#   "page_size": 20,
#   "pages": 5
# }
#
# Query: /posts?page=2&page_size=50
```

### Custom Pagination

```python
from ninja.pagination import PaginationBase
from ninja import Schema
from typing import List, Any

class CustomPaginatedResponse(Schema):
    items: List[Any]
    total: int
    page: int
    per_page: int
    total_pages: int
    has_next: bool
    has_prev: bool

class CursorPagination(PaginationBase):
    """Cursor-based pagination for large datasets."""
    
    class Output(Schema):
        items: List[Any]
        next_cursor: str = None
        prev_cursor: str = None
        has_more: bool
    
    def paginate_queryset(self, queryset, request, **kwargs):
        cursor = request.GET.get('cursor')
        limit = int(request.GET.get('limit', 20))
        
        if cursor:
            queryset = queryset.filter(id__gt=cursor)
        
        items = list(queryset[:limit + 1])
        has_more = len(items) > limit
        
        if has_more:
            items = items[:-1]
        
        return {
            'items': items,
            'next_cursor': str(items[-1].id) if items and has_more else None,
            'prev_cursor': cursor,
            'has_more': has_more
        }

@api.get("/posts", response=CustomPaginatedResponse)
@paginate(CursorPagination)
def list_posts_cursor(request):
    return Post.objects.all().order_by('id')
```

## Error Handling

### Validation Errors

```python
from ninja import NinjaAPI
from ninja.errors import ValidationError
from pydantic import ValidationError as PydanticValidationError

api = NinjaAPI()

# Automatic validation
class UserCreate(Schema):
    username: str  # Required
    email: str  # Required
    age: int  # Must be integer

@api.post("/users")
def create_user(request, payload: UserCreate):
    # If validation fails, returns 422 with details
    user = User.objects.create_user(**payload.dict())
    return user

# Validation error response format:
# {
#   "detail": [
#     {
#       "loc": ["body", "username"],
#       "msg": "field required",
#       "type": "value_error.missing"
#     }
#   ]
# }
```

### Custom Exceptions

```python
from ninja import NinjaAPI, HttpError
from django.core.exceptions import ObjectDoesNotExist
from django.db import IntegrityError

api = NinjaAPI()

class CustomException(Exception):
    def __init__(self, message, code):
        self.message = message
        self.code = code

@api.exception_handler(CustomException)
def custom_exception_handler(request, exc):
    return api.create_response(
        request,
        {"error": exc.message, "code": exc.code},
        status=400
    )

@api.exception_handler(ObjectDoesNotExist)
def not_found_handler(request, exc):
    return api.create_response(
        request,
        {"error": "Resource not found"},
        status=404
    )

@api.exception_handler(IntegrityError)
def integrity_error_handler(request, exc):
    return api.create_response(
        request,
        {"error": "Database integrity error", "detail": str(exc)},
        status=409
    )

# Using HttpError
@api.get("/users/{user_id}")
def get_user(request, user_id: int):
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        raise HttpError(404, "User not found")
    return user

@api.post("/users")
def create_user(request, payload: UserCreate):
    if User.objects.filter(username=payload.username).exists():
        raise HttpError(409, "Username already exists")
    return User.objects.create_user(**payload.dict())
```

### Error Response Format

```python
from ninja import Schema
from typing import List, Optional

class ErrorDetail(Schema):
    loc: List[str]
    msg: str
    type: str

class ErrorResponse(Schema):
    detail: List[ErrorDetail]
    
# Configure custom error response
api = NinjaAPI(
    default_error_responses={
        400: ErrorResponse,
        422: ErrorResponse
    }
)

# Custom error renderer
def custom_error_renderer(request, errors):
    return {
        "success": False,
        "errors": [
            {
                "field": ".".join(str(loc) for loc in e["loc"]),
                "message": e["msg"]
            }
            for e in errors
        ]
    }

api = NinjaAPI(error_renderer=custom_error_renderer)
```

## File Uploads

### Single File Upload

```python
from ninja import File, NinjaAPI
from django.core.files.uploadedfile import UploadedFile

api = NinjaAPI()

@api.post("/upload")
def upload_file(request, file: UploadedFile = File(...)):
    """Upload a single file."""
    # Validate file
    if file.size > 10 * 1024 * 1024:  # 10MB
        raise HttpError(413, "File too large (max 10MB)")
    
    allowed_types = ['image/jpeg', 'image/png', 'application/pdf']
    if file.content_type not in allowed_types:
        raise HttpError(415, f"File type {file.content_type} not allowed")
    
    # Save file
    file_path = handle_uploaded_file(file)
    
    return {
        "filename": file.name,
        "size": file.size,
        "content_type": file.content_type,
        "path": file_path
    }

def handle_uploaded_file(f):
    import os
    from django.conf import settings
    
    upload_dir = os.path.join(settings.MEDIA_ROOT, 'uploads')
    os.makedirs(upload_dir, exist_ok=True)
    
    file_path = os.path.join(upload_dir, f.name)
    
    with open(file_path, 'wb+') as destination:
        for chunk in f.chunks():
            destination.write(chunk)
    
    return file_path
```

### Multiple File Uploads

```python
from typing import List

@api.post("/upload/multiple")
def upload_files(request, files: List[UploadedFile] = File(...)):
    """Upload multiple files."""
    results = []
    
    for file in files:
        if file.size > 10 * 1024 * 1024:
            continue  # Skip large files
        
        file_path = handle_uploaded_file(file)
        results.append({
            "filename": file.name,
            "size": file.size,
            "path": file_path
        })
    
    return {"uploaded": len(results), "files": results}
```

### File Upload with Schema

```python
from ninja import Schema, File, Form
from typing import Optional

class FileMetadata(Schema):
    title: str
    description: Optional[str] = None
    tags: List[str] = []

@api.post("/upload/with-metadata")
def upload_with_metadata(
    request,
    file: UploadedFile = File(...),
    metadata: FileMetadata = Form(...)
):
    """Upload file with metadata."""
    file_obj = UploadedFile.objects.create(
        file=file,
        title=metadata.title,
        description=metadata.description,
        tags=metadata.tags
    )
    return {"id": file_obj.id, "filename": file.name}
```

## Testing

### pytest with Django Ninja

```python
# tests/test_api.py
import pytest
from django.test import Client
from ninja.testing import TestClient
from myapp.api import api

@pytest.fixture
def api_client():
    return TestClient(api)

def test_list_posts(api_client):
    response = api_client.get("/posts")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_create_post(api_client):
    data = {
        "title": "Test Post",
        "slug": "test-post",
        "body": "Test content",
        "status": "draft"
    }
    response = api_client.post("/posts", json=data)
    assert response.status_code == 200
    result = response.json()
    assert result["title"] == "Test Post"
    assert result["id"] is not None

def test_get_post(api_client):
    # First create a post
    create_response = api_client.post("/posts", json={
        "title": "Test",
        "slug": "test",
        "body": "Content"
    })
    post_id = create_response.json()["id"]
    
    # Then retrieve it
    response = api_client.get(f"/posts/{post_id}")
    assert response.status_code == 200
    assert response.json()["title"] == "Test"

def test_update_post(api_client):
    # Create post
    create = api_client.post("/posts", json={
        "title": "Original",
        "slug": "original",
        "body": "Content"
    })
    post_id = create.json()["id"]
    
    # Update
    response = api_client.patch(f"/posts/{post_id}", json={
        "title": "Updated"
    })
    assert response.status_code == 200
    assert response.json()["title"] == "Updated"

def test_delete_post(api_client):
    # Create post
    create = api_client.post("/posts", json={
        "title": "To Delete",
        "slug": "to-delete",
        "body": "Content"
    })
    post_id = create.json()["id"]
    
    # Delete
    response = api_client.delete(f"/posts/{post_id}")
    assert response.status_code == 200
    
    # Verify deleted
    get_response = api_client.get(f"/posts/{post_id}")
    assert get_response.status_code == 404

def test_validation_error(api_client):
    response = api_client.post("/posts", json={
        "title": "Test"
        # Missing required fields
    })
    assert response.status_code == 422
```

### Testing Authentication

```python
from ninja.testing import TestClient
from myapp.api import api, AuthBearer

@pytest.fixture
def authenticated_client():
    client = TestClient(api)
    # Mock authentication
    user = User.objects.create_user(username="testuser", password="testpass")
    client.force_authenticate(user)
    return client

def test_authenticated_endpoint(authenticated_client):
    response = authenticated_client.get("/profile")
    assert response.status_code == 200
    assert response.json()["username"] == "testuser"

def test_unauthenticated():
    client = TestClient(api)
    response = client.get("/profile")
    assert response.status_code == 401

# Testing with JWT
def test_jwt_authentication():
    client = TestClient(api)
    
    # Login first
    login_response = client.post("/login", json={
        "username": "testuser",
        "password": "testpass"
    })
    token = login_response.json()["access"]
    
    # Use token
    response = client.get(
        "/profile",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
```

## Async Support

### Async Views

```python
from ninja import NinjaAPI
from asgiref.sync import sync_to_async

api = NinjaAPI()

@api.get("/async-posts")
async def async_list_posts(request):
    """Async endpoint for listing posts."""
    # Use async ORM
    posts = await sync_to_async(list)(Post.objects.all()[:10])
    return posts

@api.post("/async-posts")
async def async_create_post(request, payload: PostCreate):
    """Async endpoint for creating posts."""
    @sync_to_async
    def create_post_sync():
        return Post.objects.create(**payload.dict())
    
    post = await create_post_sync()
    return post

# Async with external API
import aiohttp

@api.get("/external-data")
async def fetch_external(request):
    """Fetch data from external API asynchronously."""
    async with aiohttp.ClientSession() as session:
        async with session.get('https://api.example.com/data') as response:
            data = await response.json()
            return data
```

### Async Authentication

```python
from ninja.security import HttpBearer

class AsyncAuthBearer(HttpBearer):
    async def authenticate(self, request, token):
        """Async token validation."""
        user = await validate_token_async(token)
        return user

async def validate_token_async(token):
    """Validate JWT token asynchronously."""
    import jwt
    from django.conf import settings
    
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=['HS256'])
        user = await sync_to_async(User.objects.get)(id=payload['user_id'])
        return user
    except Exception:
        return None

api = NinjaAPI(auth=AsyncAuthBearer())

@api.get("/async-protected")
async def async_protected(request):
    return {"user": request.auth.username}
```

## OpenAPI Documentation

### Swagger UI

```python
from ninja import NinjaAPI

api = NinjaAPI(
    title="My API",
    description="API documentation",
    version="1.0.0",
    docs_url="/docs/",  # Swagger UI at /api/docs/
    openapi_url="/openapi.json"  # OpenAPI schema at /api/openapi.json
)

# Access at: /api/docs/
# OpenAPI schema at: /api/openapi.json
```

### Customizing Documentation

```python
from ninja import Schema
from typing import Optional

class PostSchema(Schema):
    id: int
    title: str
    body: str
    
    class Config:
        # OpenAPI schema customization
        schema_extra = {
            "example": {
                "id": 1,
                "title": "My First Post",
                "body": "This is the content of my first post."
            }
        }

@api.get(
    "/posts/{post_id}",
    response=PostSchema,
    summary="Get a post by ID",
    description="Retrieves a specific post by its ID. Returns 404 if not found.",
    tags=["posts"],
    operation_id="get_post_by_id"
)
def get_post(request, post_id: int):
    """
    Retrieve a post by ID.
    
    Args:
        post_id: The unique identifier of the post
        
    Returns:
        PostSchema: The requested post
        
    Raises:
        HttpError: 404 if post not found
    """
    post = get_object_or_404(Post, id=post_id)
    return post

# Tags for grouping endpoints
api = NinjaAPI()

posts_tags = ["posts"]
users_tags = ["users"]

@api.get("/posts", tags=posts_tags)
def list_posts(request):
    pass

@api.get("/users", tags=users_tags)
def list_users(request):
    pass
```

### Response Examples

```python
from ninja import Schema

class PostSchema(Schema):
    id: int
    title: str
    body: str

@api.get(
    "/posts/{post_id}",
    response={
        200: PostSchema,
        404: ErrorSchema
    },
    examples={
        200: {"id": 1, "title": "Post Title", "body": "Post content"},
        404: {"error": "Post not found"}
    }
)
def get_post_with_examples(request, post_id: int):
    pass
```

## Django Integration

### Models

```python
# models.py
from django.db import models
from django.contrib.auth.models import User

class Post(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('published', 'Published'),
    ]
    
    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='posts')
    body = models.TextField()
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='draft')
    categories = models.ManyToManyField('Category', related_name='posts', blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return self.title

class Category(models.Model):
    name = models.CharField(max_length=100)
    slug = models.SlugField(unique=True)
    
    def __str__(self):
        return self.name
```

### Middleware Integration

```python
# middleware.py
from django.utils.deprecation import MiddlewareMixin

class APIMiddleware(MiddlewareMixin):
    """Custom middleware for API requests."""
    
    def process_request(self, request):
        # Add custom headers or modify request
        request.api_version = request.headers.get('X-API-Version', '1.0')
    
    def process_response(self, request, response):
        # Add headers to all API responses
        if request.path.startswith('/api/'):
            response['X-API-Version'] = getattr(request, 'api_version', '1.0')
        return response

# settings.py
MIDDLEWARE = [
    # ...
    'myapp.middleware.APIMiddleware',
]
```

### Signals

```python
# signals.py
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Post

@receiver(post_save, sender=Post)
def post_created_handler(sender, instance, created, **kwargs):
    """Handle post creation."""
    if created:
        # Send notification, update cache, etc.
        send_notification(instance)

# apps.py
from django.apps import AppConfig

class MyAppConfig(AppConfig):
    name = 'myapp'
    
    def ready(self):
        import myapp.signals
```

## Best Practices

### 1. Code Organization

```python
# api/__init__.py
from ninja import NinjaAPI

api = NinjaAPI(title="My API")

# Import routers
from .users import router as users_router
from .posts import router as posts_router

api.add_router("/users", users_router)
api.add_router("/posts", posts_router)

# api/users.py
from ninja import Router

router = Router()

@router.get("/")
def list_users(request):
    pass

# api/posts.py
from ninja import Router

router = Router()

@router.get("/")
def list_posts(request):
    pass
```

### 2. Schema Organization

```python
# schemas/__init__.py
from .users import UserIn, UserOut, UserUpdate
from .posts import PostIn, PostOut, PostUpdate

# schemas/users.py
from ninja import Schema, ModelSchema
from typing import Optional

class UserBase(Schema):
    username: str
    email: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None

class UserIn(UserBase):
    password: str

class UserOut(UserBase):
    id: int
    created_at: str

class UserUpdate(Schema):
    username: Optional[str] = None
    email: Optional[str] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
```

### 3. Error Handling

```python
# utils/errors.py
from ninja import HttpError

class NotFoundError(HttpError):
    def __init__(self, resource, identifier):
        super().__init__(404, f"{resource} with id {identifier} not found")

class PermissionDeniedError(HttpError):
    def __init__(self, message="Permission denied"):
        super().__init__(403, message)

class ValidationError(HttpError):
    def __init__(self, message):
        super().__init__(422, message)

# Usage
@api.get("/posts/{post_id}")
def get_post(request, post_id: int):
    post = Post.objects.filter(id=post_id).first()
    if not post:
        raise NotFoundError("Post", post_id)
    if post.author != request.user:
        raise PermissionDeniedError("You can only view your own posts")
    return post
```

### 4. Query Optimization

```python
# Always use select_related for ForeignKey
@api.get("/posts")
def list_posts(request):
    return Post.objects.select_related('author').all()

# Use prefetch_related for ManyToMany
@api.get("/posts")
def list_posts_with_categories(request):
    return Post.objects.select_related('author').prefetch_related('categories').all()

# Use only() for specific fields
@api.get("/posts")
def list_posts_minimal(request):
    return Post.objects.only('id', 'title', 'slug').all()

# Use defer() for excluding large fields
@api.get("/posts")
def list_posts_without_body(request):
    return Post.objects.defer('body').all()
```

### 5. Caching

```python
from django.core.cache import cache
from functools import wraps

def cache_response(timeout=300):
    """Decorator for caching API responses."""
    def decorator(func):
        @wraps(func)
        def wrapper(request, *args, **kwargs):
            cache_key = f"api:{request.path}:{request.GET.urlencode()}"
            cached = cache.get(cache_key)
            if cached:
                return cached
            
            result = func(request, *args, **kwargs)
            cache.set(cache_key, result, timeout)
            return result
        return wrapper
    return decorator

@api.get("/posts")
@cache_response(timeout=60)
def list_posts(request):
    return list(Post.objects.all())
```

## Common Issues

### Issue: Validation Errors Not Showing

**Problem**: Validation errors return generic 422 without details.

**Solution**:
```python
# Check error renderer configuration
api = NinjaAPI()

# Default error renderer shows details
# Custom error renderer for more control
def custom_error_renderer(errors):
    return {
        "success": False,
        "errors": [
            {"field": e["loc"][-1], "message": e["msg"]}
            for e in errors
        ]
    }

api = NinjaAPI(error_renderer=custom_error_renderer)
```

### Issue: Authentication Not Working

**Problem**: request.auth is None in protected endpoints.

**Solution**:
```python
# Check auth decorator placement
@api.get("/protected", auth=AuthBearer())  # Correct
def protected(request):
    return {"user": request.auth.username}

# vs

@api.get("/protected")  # Wrong - no auth
@auth_required  # This doesn't work
def protected(request):
    pass
```

### Issue: File Upload Size Limit

**Problem**: Large file uploads fail silently.

**Solution**:
```python
# settings.py
DATA_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024  # 10MB
FILE_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024  # 10MB

# In the endpoint
@api.post("/upload")
def upload_file(request, file: UploadedFile = File(...)):
    if file.size > 10 * 1024 * 1024:
        raise HttpError(413, "File too large")
```

### Issue: CORS Errors

**Problem**: Frontend can't access API due to CORS.

**Solution**:
```python
# Install django-cors-headers
pip install django-cors-headers

# settings.py
INSTALLED_APPS = [
    # ...
    'corsheaders',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # Add at the top
    # ...
]

CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "https://myapp.com",
]

# Or for development
CORS_ALLOW_ALL_ORIGINS = True  # Only in development!
```

### Issue: Nested Schema Serialization

**Problem**: Nested schemas not serializing correctly.

**Solution**:
```python
# Make sure nested schemas are properly defined
class AuthorSchema(ModelSchema):
    class Config:
        model = User
        model_fields = ['id', 'username']

class PostSchema(ModelSchema):
    author: AuthorSchema  # Must be defined before use
    
    class Config:
        model = Post
        model_fields = ['id', 'title', 'body']

# For many-to-many
class PostWithCategories(ModelSchema):
    categories: List[str]  # Or List[CategorySchema]
    
    class Config:
        model = Post
        model_fields = ['id', 'title']
    
    @staticmethod
    def resolve_categories(obj):
        return [c.name for c in obj.categories.all()]
```

## References

- **Official Documentation**: https://django-ninja.dev/
- **GitHub Repository**: https://github.com/vitalik/django-ninja
- **Pydantic Documentation**: https://docs.pydantic.dev/
- **OpenAPI Specification**: https://swagger.io/specification/
- **Django Documentation**: https://docs.djangoproject.com/
