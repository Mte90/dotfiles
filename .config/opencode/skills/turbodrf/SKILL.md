---
name: turbadrf
description: "TurboDRF - fast Django REST framework with automatic OpenAPI, serializers, views, routers, and caching"
metadata:
  author: "OSS AI Skills"
  version: "1.0.0"
  tags:
    - python
    - django
    - rest-api
    - openapi
    - fast
---

# TurboDRF

Fast Django REST framework.

## Overview

TurboDRF is a high-performance REST framework for Django that provides automatic OpenAPI documentation, powerful serializers, views, routers, and built-in caching.

**Key Features:**
- Automatic OpenAPI/Swagger documentation
- Powerful serializers with validation
- ViewSets and GenericViews
- Automatic router generation
- Built-in caching support
- JWT authentication
- Rate limiting

### Installation

```bash
pip install turbodrframework

# With caching support
pip install turbodrframework[cache]

# With async support
pip install turbodrframework[async]
```

## Quick Start

### Basic Setup

```python
# settings.py
INSTALLED_APPS = [
    'rest_framework',
    'turbodrframework',
    'myapp',
]

TURBODRF = {
    'OPENAPI_ENABLED': True,
    'CACHE_ENABLED': True,
}
```

### Minimal ViewSet

```python
from turbodrframework import ModelViewSet, Serializer

class UserSerializer(Serializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email']

class UserViewSet(ModelViewSet):
    serializer_class = UserSerializer
    queryset = User.objects.all()
    lookup_field = 'pk'
```

### URLs

```python
from turbodrframework import routers
from myapp.views import UserViewSet

router = routers.DefaultRouter()
router.register(r'users', UserViewSet)

urlpatterns = router.urls
```

## Serializers

### ModelSerializer

```python
from turbodrframework import Serializer, ModelSerializer
from django.contrib.auth.models import User

class UserSerializer(ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']
        read_only_fields = ['id']

class UserDetailSerializer(ModelSerializer):
    class Meta:
        model = User
        fields = '__all__'
```

### Field Validation

```python
class UserRegistrationSerializer(Serializer):
    username = serializers.CharField(min_length=3, max_length=50)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=8)
    confirm_password = serializers.CharField(write_only=True)

    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError("Passwords don't match")
        return data

    def create(self, validated_data):
        validated_data.pop('confirm_password')
        user = User.objects.create_user(**validated_data)
        return user
```

### Nested Serializers

```python
class CommentSerializer(Serializer):
    id = serializers.IntegerField()
    text = serializers.CharField()
    author = serializers.StringRelatedField()

class PostSerializer(Serializer):
    id = serializers.IntegerField()
    title = serializers.CharField()
    comments = CommentSerializer(many=True, read_only=True)
    author = UserSerializer(read_only=True)
```

## Views

### ModelViewSet

```python
from turbodrframework import ModelViewSet
from myapp.models import Article
from myapp.serializers import ArticleSerializer

class ArticleViewSet(ModelViewSet):
    serializer_class = ArticleSerializer
    queryset = Article.objects.all()
    lookup_field = 'slug'
    filterset_fields = ['category', 'status']
    search_fields = ['title', 'content']
    ordering_fields = ['created_at', 'updated_at']
    ordering = ['-created_at']
```

### Custom Actions

```python
class ArticleViewSet(ModelViewSet):
    serializer_class = ArticleSerializer
    queryset = Article.objects.all()

    @action(detail=True, methods=['post'])
    def publish(self, request, pk=None):
        article = self.get_object()
        article.status = 'published'
        article.save()
        return Response({'status': 'published'})

    @action(detail=False, methods=['get'])
    def published(self, request):
        articles = self.queryset.filter(status='published')
        serializer = self.get_serializer(articles, many=True)
        return Response(serializer.data)
```

### Generic Views

```python
from turbodrframework import (
    ListAPIView,
    CreateAPIView,
    RetrieveAPIView,
    UpdateAPIView,
    DestroyAPIView,
    ListCreateAPIView,
    RetrieveUpdateAPIView,
)

class UserListCreateView(ListCreateAPIView):
    serializer_class = UserSerializer
    queryset = User.objects.all()

class UserDetailView(RetrieveUpdateDestroyAPIView):
    serializer_class = UserSerializer
    queryset = User.objects.all()
    lookup_field = 'pk'
```

## Authentication

### JWT Authentication

```python
# settings.py
TURBODRF = {
    'AUTH_CLASS': 'turbodrframework.authentication.JWTAuthentication',
    'JWT_SECRET_KEY': 'your-secret-key',
    'JWT_ALGORITHM': 'HS256',
    'JWT_EXPIRATION': 3600,  # seconds
}

# views.py
from turbodrframework import ModelViewSet
from turbodrframework.permissions import IsAuthenticated

class SecureViewSet(ModelViewSet):
    permission_classes = [IsAuthenticated]
    queryset = SecureModel.objects.all()
```

### Token Authentication

```python
# settings.py
TURBODRF = {
    'AUTH_CLASS': 'turbodrframework.authentication.TokenAuthentication',
}

# urls.py
from turbodrframework.authentication import obtain_token

urlpatterns = [
    path('api/token/', obtain_token),
]
```

### Custom Authentication

```python
from turbodrframework.authentication import BaseAuthentication

class APIKeyAuthentication(BaseAuthentication):
    def authenticate(self, request):
        api_key = request.headers.get('X-API-Key')
        if not api_key:
            return None
        
        try:
            user = APIKey.objects.get(key=api_key).user
            return (user, None)
        except APIKey.DoesNotExist:
            return None
```

## Permissions

### Built-in Permissions

```python
from turbodrframework.permissions import (
    AllowAny,
    IsAuthenticated,
    IsAdminUser,
    IsAuthenticatedOrReadOnly,
)

class ArticleViewSet(ModelViewSet):
    permission_classes = [IsAuthenticatedOrReadOnly]
```

### Custom Permissions

```python
from rest_framework import permissions

class IsOwnerOrReadOnly(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.owner == request.user

class ArticleViewSet(ModelViewSet):
    permission_classes = [IsAuthenticatedOrReadOnly, IsOwnerOrReadOnly]
```

## Caching

### Cache Configuration

```python
# settings.py
TURBODRF = {
    'CACHE_ENABLED': True,
    'CACHE_CLASS': 'turbodrframework.cache.RedisCache',
    'CACHE_CONFIG': {
        'LOCATION': 'redis://127.0.0.1:6379/0',
    },
    'CACHE_TIMEOUT': 300,  # 5 minutes
}

# Or use default cache
TURBODRF = {
    'CACHE_ENABLED': True,
    'CACHE_CLASS': 'django.core.cache.backends.locmem.LocMemCache',
}
```

### View Caching

```python
class ArticleViewSet(ModelViewSet):
    serializer_class = ArticleSerializer
    queryset = Article.objects.all()
    
    @cache_response(timeout=60)
    def list(self, request):
        # This view will be cached for 60 seconds
        return super().list(request)
    
    @cache_response(timeout=300)
    def retrieve(self, request, pk=None):
        # Individual article cached for 5 minutes
        return super().retrieve(request, pk)
```

### Cache Invalidation

```python
from turbodrframework.cache import invalidate_cache

# Invalidate specific view cache
invalidate_cache('ArticleViewSet', 'list')

# Invalidate all caches
invalidate_cache('ArticleViewSet')

# Invalidate by key
invalidate_cache('ArticleViewSet:list', user_id=1)
```

## Filtering

### QuerySet Filtering

```python
class ArticleViewSet(ModelViewSet):
    serializer_class = ArticleSerializer
    queryset = Article.objects.all()
    filterset_fields = ['category', 'status', 'author']
    search_fields = ['title', 'content', 'tags']
```

### Custom Filtering

```python
from turbodrframework.filters import FilterSet

class ArticleFilter(FilterSet):
    category = filters.CharFilter(field_name='category__slug')
    published_after = filters.DateTimeFilter(field_name='created_at', lookup_expr='gte')
    author_username = filters.CharFilter(field_name='author__username')

    class Meta:
        model = Article
        fields = ['category', 'status', 'published_after']

class ArticleViewSet(ModelViewSet):
    serializer_class = ArticleSerializer
    queryset = Article.objects.all()
    filterset_class = ArticleFilter
```

## Pagination

### Default Pagination

```python
# settings.py
TURBODRF = {
    'PAGINATION_CLASS': 'turbodrframework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
}
```

### Custom Pagination

```python
class CustomPagination(pagination.PageNumberPagination):
    page_size = 50
    page_query_param = 'page'
    page_size_query_param = 'page_size'
    max_page_size = 100

class ArticleViewSet(ModelViewSet):
    serializer_class = ArticleSerializer
    queryset = Article.objects.all()
    pagination_class = CustomPagination
```

### Cursor Pagination

```python
class ArticleViewSet(ModelViewSet):
    serializer_class = ArticleSerializer
    queryset = Article.objects.all().order_by('id')
    pagination_class = pagination.CursorPagination
    page_size = 100
```

## OpenAPI Documentation

### Auto-Generated Docs

```python
# settings.py
TURBODRF = {
    'OPENAPI_ENABLED': True,
    'OPENAPI_TITLE': 'My API',
    'OPENAPI_VERSION': '1.0.0',
    'OPENAPI_DESCRIPTION': 'API documentation',
}

# URLs
from turbodrframework.docs import schema_view

urlpatterns = [
    path('docs/', schema_view),
]
```

### Custom Schema

```python
from turbodrframework.docs import AutoSchema

class CustomSchema(AutoSchema):
    def get_operation_id(self, path, method):
        # Custom operation ID
        return f"{method.lower()}_{path.replace('/', '_')}"

class ArticleViewSet(ModelViewSet):
    serializer_class = ArticleSerializer
    queryset = Article.objects.all()
    schema = CustomSchema()
```

### Request/Response Examples

```python
from turbodrframework.docs import extend_schema

class ArticleViewSet(ModelViewSet):
    serializer_class = ArticleSerializer
    queryset = Article.objects.all()

    @extend_schema(
        request=ArticleSerializer,
        responses={201: ArticleSerializer},
        examples=[
            {
                "title": "Example Article",
                "content": "Article content here",
            }
        ]
    )
    def create(self, request, *args, **kwargs):
        return super().create(request, *args, **kwargs)
```

## Rate Limiting

### Configuration

```python
# settings.py
TURBODRF = {
    'RATE_LIMIT_ENABLED': True,
    'RATE_LIMIT_CLASS': 'turbodrframework.throttling.SimpleRateThrottle',
    'DEFAULT_RATE': '100/minute',
}

# View-level
class ArticleViewSet(ModelViewSet):
    throttle_classes = [UserRateThrottle]
    throttle_scope = 'articles'
```

## Examples

### Complete CRUD API

```python
# serializers.py
from turbodrframework import ModelSerializer
from myapp.models import Article

class ArticleSerializer(ModelSerializer):
    class Meta:
        model = Article
        fields = ['id', 'title', 'content', 'author', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']

# views.py
from turbodrframework import ModelViewSet
from myapp.models import Article
from myapp.serializers import ArticleSerializer

class ArticleViewSet(ModelViewSet):
    serializer_class = ArticleSerializer
    queryset = Article.objects.all()
    filterset_fields = ['category']
    search_fields = ['title', 'content']
    ordering_fields = ['created_at', 'title']
    
    def perform_create(self, serializer):
        serializer.save(author=self.request.user)
    
    def get_queryset(self):
        return self.queryset.filter(author=self.request.user)

# urls.py
from turbodrframework import routers
from myapp.views import ArticleViewSet

router = routers.DefaultRouter()
router.register(r'articles', ArticleViewSet)

urlpatterns = router.urls
```

## Best Practices

### 1. Use Meta Options

```python
class UserSerializer(ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email']
        read_only_fields = ['id']
```

### 2. Validate Input

```python
def validate_username(self, value):
    if User.objects.filter(username=value).exists():
        raise serializers.ValidationError("Username already exists")
    return value
```

### 3. Use Permissions

```python
class ArticleViewSet(ModelViewSet):
    permission_classes = [IsAuthenticatedOrReadOnly]
```

## References

- **TurboDRF Documentation**: https://turbodrframework.readthedocs.io/
- **Django REST Framework**: https://www.django-rest-framework.org/