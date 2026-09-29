# Authentication, Pagination & Error Handling

> This reference file is loaded on demand from the main django-ninja SKILL.md entry.

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