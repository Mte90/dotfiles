# Django Integration & Best Practices

> This reference file is loaded on demand from the main django-ninja SKILL.md entry.

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