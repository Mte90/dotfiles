---
name: django
description: Comprehensive guide for building web applications with Django, including models, views, templates, forms, authentication, middleware, ORM, REST API, caching, async views, and deployment.
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - django
    - python
    - web-framework
    - web-development
    - rest-api
    - orm
    - async
---

# Django Development

Complete guide for building web applications with Django framework.

## Overview

Django is a high-level Python web framework for rapid development and clean design.

**Key Characteristics:**
- Batteries included (admin, ORM, auth)
- MTV (Model-Template-View) architecture
- Built-in security features
- Excellent documentation
- Large ecosystem

## Installation

### Setup

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/macOS
# or
venv\Scripts\activate  # Windows

# Install Django
pip install django

# Create project
django-admin startproject myproject
cd myproject

# Create app
python manage.py startapp myapp

# Run development server
python manage.py runserver
```

### Project Structure

```
myproject/
├── manage.py
├── myproject/
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   ├── asgi.py
│   └── wsgi.py
├── myapp/
│   ├── __init__.py
│   ├── admin.py
│   ├── apps.py
│   ├── models.py
│   ├── tests.py
│   ├── views.py
│   └── migrations/
└── templates/
    └── base.html
```

### settings.py

```python
# myproject/settings.py

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'myapp',  # Your app
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'mydb',
        'USER': 'myuser',
        'PASSWORD': 'mypassword',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'
```

## Models and ORM

### Model Definition

```python
# myapp/models.py
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone

class Category(models.Model):
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True)
    description = models.TextField(blank=True)

    class Meta:
        verbose_name_plural = 'categories'
        ordering = ['name']

    def __str__(self):
        return self.name

    def get_absolute_url(self):
        return f'/category/{self.slug}/'

class Post(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('published', 'Published'),
    ]

    title = models.CharField(max_length=200)
    slug = models.SlugField(max_length=200, unique_for_date='publish')
    author = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='posts'
    )
    body = models.TextField()
    publish = models.DateTimeField(default=timezone.now)
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)
    status = models.CharField(
        max_length=10,
        choices=STATUS_CHOICES,
        default='draft'
    )
    categories = models.ManyToManyField(
        Category,
        related_name='posts',
        blank=True
    )

    class Meta:
        ordering = ['-publish']
        indexes = [
            models.Index(fields=['-publish']),
            models.Index(fields=['status']),
        ]

    def __str__(self):
        return self.title

    def get_absolute_url(self):
        return f'/posts/{self.slug}/'
```

### Migrations

```bash
# Create migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Show migrations
python manage.py showmigrations

# Create empty migration
python manage.py makemigrations --empty myapp
```

### QuerySet Operations

```python
from myapp.models import Post, Category

# Create
post = Post.objects.create(
    title='My Post',
    slug='my-post',
    author=user,
    body='Content...',
    status='published'
)

# Get single object
post = Post.objects.get(id=1)
post = Post.objects.get(slug='my-post')

# Filter
published_posts = Post.objects.filter(status='published')
recent_posts = Post.objects.filter(
    publish__year=2024,
    status='published'
)

# Exclude
drafts = Post.objects.exclude(status='published')

# Order
posts = Post.objects.order_by('-publish')
posts = Post.objects.order_by('title', '-publish')

# Limit
posts = Post.objects.all()[:10]  # First 10
posts = Post.objects.all()[10:20]  # Offset 10, limit 10

# Count
count = Post.objects.count()
count = Post.objects.filter(status='published').count()

# Exists
exists = Post.objects.filter(slug='my-post').exists()

# Update
Post.objects.filter(status='draft').update(status='published')

# Delete
Post.objects.filter(status='draft').delete()
```

### Advanced ORM

#### select_related vs prefetch_related

```python
# ❌ BAD: N+1 queries
posts = Post.objects.all()
for post in posts:
    print(post.author.username)  # N+1 queries!

# ✅ GOOD: select_related (ForeignKey/OneToOne)
posts = Post.objects.select_related('author').all()
for post in posts:
    print(post.author.username)  # 1 query!

# ✅ GOOD: prefetch_related (ManyToMany/reverse ForeignKey)
posts = Post.objects.prefetch_related('categories').all()
for post in posts:
    for category in post.categories.all():
        print(category.name)  # 2 queries total!

# ✅ GOOD: Combine both
posts = Post.objects.select_related('author').prefetch_related('categories')

# ✅ GOOD: Nested prefetch
from django.db.models import Prefetch

posts = Post.objects.prefetch_related(
    Prefetch(
        'categories',
        queryset=Category.objects.filter(name__startswith='D')
    )
)
```

#### Aggregation and Annotation

```python
from django.db.models import Count, Sum, Avg, Max, Min, F, Q

# Count posts per author
authors = User.objects.annotate(
    post_count=Count('posts')
)

# Complex aggregation
authors = User.objects.annotate(
    total_posts=Count('posts'),
    published_posts=Count('posts', filter=Q(posts__status='published')),
    avg_views=Avg('posts__views'),
    max_views=Max('posts__views')
)

# Filter by annotation
popular_authors = User.objects.annotate(
    post_count=Count('posts')
).filter(post_count__gt=5)

# F() expressions
from django.db.models import F

# Update using field reference
Post.objects.update(views=F('views') + 1)

# Compare fields
Post.objects.filter(rating__gt=F('views') / 100)

# Annotate with F()
Post.objects.annotate(
    engagement=F('views') + F('comments') * 10
)
```

#### Q() Objects

```python
from django.db.models import Q

# OR condition
posts = Post.objects.filter(
    Q(status='published') | Q(status='featured')
)

# AND with NOT
posts = Post.objects.filter(
    Q(status='published') & ~Q(author=user)
)

# Complex conditions
posts = Post.objects.filter(
    Q(status='published') & (
        Q(title__icontains='django') |
        Q(body__icontains='django')
    )
)

# Dynamic queries
queries = []
if search_term:
    queries.append(Q(title__icontains=search_term))
if category:
    queries.append(Q(categories__slug=category))

posts = Post.objects.filter(*queries)
```

#### Bulk Operations

```python
# Bulk create
posts = [
    Post(title=f'Post {i}', slug=f'post-{i}', author=user)
    for i in range(100)
]
Post.objects.bulk_create(posts)

# Bulk update
posts = Post.objects.filter(status='draft')
for post in posts:
    post.status = 'published'
Post.objects.bulk_update(posts, ['status'])

# Bulk update with F()
from django.db.models import F
Post.objects.update(views=F('views') + 1)
```

## Views

### Function-Based Views

```python
# myapp/views.py
from django.shortcuts import render, get_object_or_404, redirect
from django.http import HttpResponse, JsonResponse
from django.contrib.auth.decorators import login_required
from django.views.decorators.http import require_http_methods

def post_list(request):
    posts = Post.objects.filter(status='published')
    return render(request, 'myapp/post_list.html', {'posts': posts})

def post_detail(request, slug):
    post = get_object_or_404(Post, slug=slug, status='published')
    return render(request, 'myapp/post_detail.html', {'post': post})

@login_required
def post_create(request):
    if request.method == 'POST':
        form = PostForm(request.POST)
        if form.is_valid():
            post = form.save(commit=False)
            post.author = request.user
            post.save()
            return redirect('post_detail', slug=post.slug)
    else:
        form = PostForm()
    return render(request, 'myapp/post_form.html', {'form': form})

@require_http_methods(["GET", "POST"])
def post_update(request, slug):
    post = get_object_or_404(Post, slug=slug)
    if request.method == 'POST':
        form = PostForm(request.POST, instance=post)
        if form.is_valid():
            form.save()
            return redirect('post_detail', slug=post.slug)
    else:
        form = PostForm(instance=post)
    return render(request, 'myapp/post_form.html', {'form': form})

def api_posts(request):
    posts = Post.objects.filter(status='published').values('title', 'slug')
    return JsonResponse({'posts': list(posts)})
```

### Class-Based Views

```python
from django.views.generic import (
    ListView, DetailView, CreateView, UpdateView, DeleteView
)
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin
from django.urls import reverse_lazy

class PostListView(ListView):
    model = Post
    template_name = 'myapp/post_list.html'
    context_object_name = 'posts'
    paginate_by = 10

    def get_queryset(self):
        return Post.objects.filter(status='published').select_related('author')

class PostDetailView(DetailView):
    model = Post
    template_name = 'myapp/post_detail.html'
    context_object_name = 'post'

    def get_queryset(self):
        return Post.objects.filter(status='published')

class PostCreateView(LoginRequiredMixin, CreateView):
    model = Post
    template_name = 'myapp/post_form.html'
    fields = ['title', 'body', 'status', 'categories']

    def form_valid(self, form):
        form.instance.author = self.request.user
        return super().form_valid(form)

class PostUpdateView(LoginRequiredMixin, UserPassesTestMixin, UpdateView):
    model = Post
    template_name = 'myapp/post_form.html'
    fields = ['title', 'body', 'status', 'categories']

    def test_func(self):
        post = self.get_object()
        return self.request.user == post.author

class PostDeleteView(LoginRequiredMixin, UserPassesTestMixin, DeleteView):
    model = Post
    template_name = 'myapp/post_confirm_delete.html'
    success_url = reverse_lazy('post_list')

    def test_func(self):
        post = self.get_object()
        return self.request.user == post.author
```

## Middleware

### Custom Middleware

```python
# myapp/middleware.py
import time
from django.http import HttpResponse

class RequestTimingMiddleware:
    """Measure request processing time."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Before view
        start_time = time.time()

        response = self.get_response(request)

        # After view
        duration = time.time() - start_time
        response['X-Request-Duration'] = f'{duration:.3f}s'

        return response


class BlockIPMiddleware:
    """Block requests from certain IPs."""

    BLOCKED_IPS = ['192.168.1.100']

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        ip = request.META.get('REMOTE_ADDR')
        if ip in self.BLOCKED_IPS:
            return HttpResponse('Blocked', status=403)
        return self.get_response(request)


class LegacyMiddleware:
    """Legacy middleware with all process_* methods."""

    def process_request(self, request):
        """Called before view. Return HttpResponse to short-circuit."""
        # Log request
        return None

    def process_view(self, request, view_func, view_args, view_kwargs):
        """Called just before view. Return HttpResponse to short-circuit."""
        # Check permissions
        return None

    def process_response(self, request, response):
        """Called after view. Must return HttpResponse."""
        response['X-Custom-Header'] = 'Value'
        return response

    def process_exception(self, request, exception):
        """Called when view raises exception. Return HttpResponse to handle."""
        if isinstance(exception, ValueError):
            return HttpResponse('Bad request', status=400)
        return None
```

### Middleware Ordering

```python
# settings.py - Middleware order matters!
MIDDLEWARE = [
    # Security middleware should be first
    'django.middleware.security.SecurityMiddleware',

    # Session middleware must come before cache
    'django.contrib.sessions.middleware.SessionMiddleware',

    # Common middleware
    'django.middleware.common.CommonMiddleware',

    # CSRF must come after session
    'django.middleware.csrf.CsrfViewMiddleware',

    # Authentication
    'django.contrib.auth.middleware.AuthenticationMiddleware',

    # Messages
    'django.contrib.messages.middleware.MessageMiddleware',

    # Clickjacking protection
    'django.middleware.clickjacking.XFrameOptionsMiddleware',

    # Custom middleware
    'myapp.middleware.RequestTimingMiddleware',
]
```

## Django REST Framework

### Installation and Setup

```bash
pip install djangorestframework
pip install django-filter  # For filtering
```

```python
# settings.py
INSTALLED_APPS = [
    ...
    'rest_framework',
    'django_filters',
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.SessionAuthentication',
        'rest_framework.authentication.TokenAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticatedOrReadOnly',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ],
}
```

### Serializers

```python
# myapp/serializers.py
from rest_framework import serializers
from .models import Post, Category

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'slug', 'description']

class PostSerializer(serializers.ModelSerializer):
    author = serializers.StringRelatedField(read_only=True)
    author_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(),
        source='author',
        write_only=True
    )
    categories = CategorySerializer(many=True, read_only=True)
    category_ids = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(),
        source='categories',
        many=True,
        write_only=True,
        required=False
    )

    class Meta:
        model = Post
        fields = [
            'id', 'title', 'slug', 'author', 'author_id',
            'body', 'publish', 'status', 'categories', 'category_ids'
        ]
        read_only_fields = ['id', 'publish']

    def validate_title(self, value):
        if len(value) < 5:
            raise serializers.ValidationError('Title must be at least 5 characters.')
        return value

    def validate(self, attrs):
        if attrs.get('status') == 'published' and not attrs.get('body'):
            raise serializers.ValidationError({
                'body': 'Published posts must have content.'
            })
        return attrs


class PostListSerializer(serializers.ModelSerializer):
    """Lighter serializer for list views."""
    author_name = serializers.CharField(source='author.username', read_only=True)
    category_count = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = ['id', 'title', 'slug', 'author_name', 'publish', 'category_count']

    def get_category_count(self, obj):
        return obj.categories.count()
```

### ViewSets and Routers

```python
# myapp/api.py
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from .models import Post, Category
from .serializers import PostSerializer, PostListSerializer, CategorySerializer

class PostViewSet(viewsets.ModelViewSet):
    queryset = Post.objects.select_related('author').prefetch_related('categories')
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['status', 'author', 'categories']
    search_fields = ['title', 'body']
    ordering_fields = ['publish', 'title']

    def get_serializer_class(self):
        if self.action == 'list':
            return PostListSerializer
        return PostSerializer

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

    @action(detail=True, methods=['post'])
    def publish(self, request, pk=None):
        """Custom action to publish a post."""
        post = self.get_object()
        if post.author != request.user:
            return Response(
                {'error': 'You can only publish your own posts.'},
                status=status.HTTP_403_FORBIDDEN
            )
        post.status = 'published'
        post.save()
        return Response({'status': 'published'})

    @action(detail=False, methods=['get'])
    def my_posts(self, request):
        """Get current user's posts."""
        posts = self.queryset.filter(author=request.user)
        serializer = self.get_serializer(posts, many=True)
        return Response(serializer.data)


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    lookup_field = 'slug'

    @action(detail=True, methods=['get'])
    def posts(self, request, slug=None):
        """Get posts in this category."""
        category = self.get_object()
        posts = Post.objects.filter(categories=category, status='published')
        serializer = PostListSerializer(posts, many=True)
        return Response(serializer.data)
```

### URLs

```python
# myapp/api_urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .api import PostViewSet, CategoryViewSet

router = DefaultRouter()
router.register(r'posts', PostViewSet)
router.register(r'categories', CategoryViewSet)

urlpatterns = [
    path('', include(router.urls)),
]

# myproject/urls.py
from django.urls import path, include

urlpatterns = [
    path('api/', include('myapp.api_urls')),
]
```

### Permissions

```python
# myapp/permissions.py
from rest_framework import permissions

class IsAuthorOrReadOnly(permissions.BasePermission):
    """Custom permission to only allow authors to edit their objects."""

    def has_object_permission(self, request, view, obj):
        # Read permissions for any request
        if request.method in permissions.SAFE_METHODS:
            return True

        # Write permissions only for author
        return obj.author == request.user


class IsAdminOrReadOnly(permissions.BasePermission):
    """Allow admin users full access, others read-only."""

    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return request.user and request.user.is_staff


# Usage in viewsets
class PostViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsAuthorOrReadOnly]
```

## Caching

### Cache Configuration

```python
# settings.py

# Redis (recommended for production)
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        },
        'KEY_PREFIX': 'myapp',
        'TIMEOUT': 300,
    }
}

# Memcached
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.PyMemcacheCache',
        'LOCATION': '127.0.0.1:11211',
    }
}

# File-based (development)
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.filebased.FileBasedCache',
        'LOCATION': '/var/tmp/django_cache',
    }
}
```

### Per-View Cache

```python
from django.views.decorators.cache import cache_page
from django.views.decorators.vary import vary_on_cookie, vary_on_headers

# Function-based view
@cache_page(60 * 15)  # 15 minutes
def post_list(request):
    posts = Post.objects.filter(status='published')
    return render(request, 'myapp/post_list.html', {'posts': posts})

# With vary headers
@cache_page(60 * 15)
@vary_on_cookie
def user_posts(request):
    posts = Post.objects.filter(author=request.user)
    return render(request, 'myapp/user_posts.html', {'posts': posts})

# Class-based view
from django.utils.decorators import method_decorator

@method_decorator(cache_page(60 * 15), name='dispatch')
class PostListView(ListView):
    model = Post
    template_name = 'myapp/post_list.html'
```

### Template Fragment Cache

```html
{% load cache %}

<!-- Basic fragment cache -->
{% cache 500 sidebar %}
    <div class="sidebar">
        {% for widget in sidebar_widgets %}
            {{ widget }}
        {% endfor %}
    </div>
{% endcache %}

<!-- Cache per user -->
{% cache 500 sidebar request.user.id %}
    <div class="sidebar">
        Welcome, {{ request.user.username }}!
    </div>
{% endcache %}

<!-- Multiple variations -->
{% cache 500 sidebar request.user.id request.LANGUAGE_CODE %}
    <div class="sidebar">
        {% trans "Welcome" %}, {{ request.user.username }}!
    </div>
{% endcache %}
```

### Low-Level Cache API

```python
from django.core.cache import cache

# Basic operations
cache.set('my_key', 'value', 300)  # 5 minutes
value = cache.get('my_key')
value = cache.get('my_key', 'default_value')

# Check existence
if cache.has_key('my_key'):
    pass

# Delete
cache.delete('my_key')
cache.delete_many(['key1', 'key2'])
cache.clear()  # Clear all!

# Add (only if doesn't exist)
cache.add('my_key', 'value', 300)

# Increment/Decrement
cache.set('counter', 1)
cache.incr('counter')  # 2
cache.decr('counter')  # 1

# Set many / Get many
cache.set_many({'key1': 1, 'key2': 2}, 300)
values = cache.get_many(['key1', 'key2'])  # {'key1': 1, 'key2': 2}

# Cache decorator
from django.views.decorators.cache import cache_page

@cache_page(60 * 15)
def expensive_view(request):
    result = expensive_computation()
    return JsonResponse(result)
```

## Async Views

### Async Views (Django 4.1+)

```python
import asyncio
from django.http import HttpResponse, JsonResponse
from asgiref.sync import sync_to_async

# Async function-based view
async def async_post_list(request):
    # Async database query
    posts = await Post.objects.filter(status='published').alist()

    data = [{'title': p.title, 'slug': p.slug} for p in posts]
    return JsonResponse({'posts': data})

# Async with external API
import aiohttp

async def fetch_external_data(request):
    async with aiohttp.ClientSession() as session:
        async with session.get('https://api.example.com/data') as response:
            data = await response.json()

    return JsonResponse(data)

# Mixing sync and async
async def hybrid_view(request):
    # Async database query
    posts = await Post.objects.all().alist()

    # Wrap sync code
    result = await sync_to_async(sync_function)(posts)

    return JsonResponse(result)

def sync_function(posts):
    # Synchronous processing
    return [p.title for p in posts]
```

### Async Middleware

```python
# Async middleware
class AsyncTimingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    async def __call__(self, request):
        import time
        start = time.time()

        response = await self.get_response(request)

        duration = time.time() - start
        response['X-Duration'] = f'{duration:.3f}s'

        return response

# Hybrid middleware (sync + async)
from inspect import iscoroutinefunction

class HybridMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

        if iscoroutinefunction(get_response):
            self._call = self._async_call
        else:
            self._call = self._sync_call

    def __call__(self, request):
        return self._call(request)

    async def _async_call(self, request):
        response = await self.get_response(request)
        response['X-Async'] = 'true'
        return response

    def _sync_call(self, request):
        response = self.get_response(request)
        response['X-Sync'] = 'true'
        return response
```

## Authentication

### Custom Authentication Backend

```python
# authentication/backends.py
from django.contrib.auth.backends import BaseBackend
from django.contrib.auth import get_user_model
import jwt
from django.conf import settings

User = get_user_model()

class JWTAuthenticationBackend(BaseBackend):
    """JWT token authentication."""

    def authenticate(self, request, token=None, **kwargs):
        if token is None:
            return None

        try:
            payload = jwt.decode(
                token,
                settings.SECRET_KEY,
                algorithms=['HS256']
            )
            user_id = payload.get('user_id')

            if user_id is None:
                return None

            user = User.objects.get(pk=user_id)

            if not user.is_active:
                return None

            return user

        except jwt.ExpiredSignatureError:
            return None
        except jwt.InvalidTokenError:
            return None
        except User.DoesNotExist:
            return None

    def get_user(self, user_id):
        try:
            return User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return None

# settings.py
AUTHENTICATION_BACKENDS = [
    'django.contrib.auth.backends.ModelBackend',
    'authentication.backends.JWTAuthenticationBackend',
]
```

### JWT with DRF

```bash
pip install djangorestframework-simplejwt
```

```python
# settings.py
from datetime import timedelta

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
}

# urls.py
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

urlpatterns = [
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]
```

## Signals

### Built-in Signals

```python
# myapp/signals.py
from django.db.models.signals import (
    pre_save, post_save, pre_delete, post_delete, m2m_changed
)
from django.dispatch import receiver
from django.contrib.auth.models import User
from django.core.mail import send_mail
from .models import Post

@receiver(post_save, sender=User)
def user_created(sender, instance, created, **kwargs):
    """Create profile when user is created."""
    if created:
        from .models import Profile
        Profile.objects.create(user=instance)
        send_mail(
            'Welcome!',
            'Thank you for registering.',
            'noreply@example.com',
            [instance.email],
        )

@receiver(post_save, sender=Post)
def post_saved(sender, instance, created, **kwargs):
    """Handle post save."""
    if created:
        # New post created
        instance.log_creation()
    else:
        # Post updated
        instance.log_update()

@receiver(pre_delete, sender=Post)
def post_pre_delete(sender, instance, **kwargs):
    """Clean up before post deletion."""
    if instance.cover_image:
        instance.cover_image.delete(save=False)

@receiver(m2m_changed, sender=Post.categories.through)
def categories_changed(sender, instance, action, **kwargs):
    """Handle category changes."""
    if action in ['post_add', 'post_remove', 'post_clear']:
        instance.update_category_cache()
```

### Custom Signals

```python
# myapp/signals.py
import django.dispatch

# Define custom signal
order_placed = django.dispatch.Signal()

# Connect receiver
@receiver(order_placed)
def send_order_confirmation(sender, order, **kwargs):
    send_mail(
        f'Order {order.id} Placed',
        f'Thank you for your order #{order.id}',
        'noreply@example.com',
        [order.customer.email],
    )

@receiver(order_placed)
def update_inventory(sender, order, **kwargs):
    for item in order.items.all():
        item.product.stock -= item.quantity
        item.product.save()

# Dispatch signal
def place_order(order):
    order.status = 'placed'
    order.save()
    order_placed.send(sender=order.__class__, order=order)
```

## Management Commands

### Custom Commands

```python
# myapp/management/commands/cleanup_posts.py
from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from myapp.models import Post

class Command(BaseCommand):
    help = 'Clean up old draft posts'

    def add_arguments(self, parser):
        parser.add_argument(
            '--days',
            type=int,
            default=30,
            help='Delete drafts older than this many days'
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be deleted without actually deleting'
        )

    def handle(self, *args, **options):
        days = options['days']
        dry_run = options['dry_run']

        cutoff = timezone.now() - timedelta(days=days)
        posts = Post.objects.filter(
            status='draft',
            updated__lt=cutoff
        )

        count = posts.count()

        if dry_run:
            self.stdout.write(
                self.style.WARNING(f'Would delete {count} draft posts')
            )
            for post in posts[:10]:
                self.stdout.write(f'  - {post.title}')
            return

        deleted, _ = posts.delete()
        self.stdout.write(
            self.style.SUCCESS(f'Deleted {deleted} draft posts')
        )
```

### Running Commands

```bash
# Run custom command
python manage.py cleanup_posts

# With options
python manage.py cleanup_posts --days=60 --dry-run

# Schedule with cron
# crontab -e
# 0 2 * * * cd /path/to/project && python manage.py cleanup_posts
```

## Deployment

### WSGI Configuration

```python
# myproject/wsgi.py
import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myproject.settings')
application = get_wsgi_application()
```

### Gunicorn

```bash
# Install
pip install gunicorn

# Run
gunicorn myproject.wsgi:application \
    --workers 4 \
    --bind 0.0.0.0:8000 \
    --timeout 120 \
    --access-logfile - \
    --error-logfile -
```

### Nginx Configuration

```nginx
# /etc/nginx/sites-available/myproject
upstream django {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name example.com;

    client_max_body_size 20M;

    location /static/ {
        alias /path/to/project/staticfiles/;
    }

    location /media/ {
        alias /path/to/project/media/;
    }

    location / {
        proxy_pass http://django;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Production Settings

```python
# settings/production.py
import os
from .base import *

DEBUG = False
ALLOWED_HOSTS = ['example.com', 'www.example.com']

# Security
SECURE_SSL_REDIRECT = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'

# Static files
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'ERROR',
            'class': 'logging.FileHandler',
            'filename': '/var/log/django/error.log',
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['file'],
            'level': 'ERROR',
            'propagate': True,
        },
    },
}
```

## Common Issues

### N+1 Queries

```python
# ❌ BAD: N+1 queries
posts = Post.objects.all()
for post in posts:
    print(post.author.username)  # N queries!

# ✅ GOOD: Use select_related
posts = Post.objects.select_related('author')
for post in posts:
    print(post.author.username)  # 1 query
```

### Migration Conflicts

```bash
# Show migration dependencies
python manage.py showmigrations

# Fake migration
python manage.py migrate --fake myapp 0001_initial

# Reset migrations (development only)
python manage.py migrate myapp zero
python manage.py makemigrations myapp
python manage.py migrate myapp
```

### Memory Issues

```python
# ❌ BAD: Load all into memory
posts = Post.objects.all()  # All posts in memory!

# ✅ GOOD: Use iterator
for post in Post.objects.iterator():
    process(post)

# ✅ GOOD: Use values() for simple data
posts = Post.objects.values('title', 'slug')
```

## Best Practices

1. **Use virtual environments** for every project
2. **Follow Django naming conventions**
3. **Use select_related/prefetch_related** to avoid N+1 queries
4. **Always use migrations** for database changes
5. **Write tests** for all views and models
6. **Use environment variables** for sensitive settings
7. **Enable caching** in production
8. **Set DEBUG=False** in production
9. **Use proper logging** instead of print()
10. **Keep views thin**, move logic to models or services

## Resources

- **Documentation:** https://docs.djangoproject.com/
- **Django REST Framework:** https://www.django-rest-framework.org/
- **Django Packages:** https://djangopackages.org/
- **Awesome Django:** https://github.com/wsvincent/awesome-django
- **Two Scoops of Django** (Book)

## Quick Reference

### Common Commands

```bash
python manage.py makemigrations    # Create migrations
python manage.py migrate           # Apply migrations
python manage.py createsuperuser   # Create admin user
python manage.py collectstatic     # Collect static files
python manage.py test              # Run tests
python manage.py shell             # Django shell
python manage.py dbshell           # Database shell
```

### Common Imports

```python
from django.shortcuts import render, redirect, get_object_or_404
from django.http import HttpResponse, JsonResponse
from django.contrib.auth.decorators import login_required
from django.views.generic import ListView, DetailView, CreateView
from django.db.models import Q, F, Count, Sum, Avg
from django.core.cache import cache
from django.utils import timezone
```
