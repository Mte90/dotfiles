---
name: turbodrf
description: Use when building Django REST APIs with TurboDRF - model Meta configuration, role-based and field-level permissions, multi-tenant predicates, router wiring, management commands, settings, or troubleshooting
metadata:
  author: mte90
  version: 2.0.0
  tags:
    - python
    - django
    - rest-api
    - openapi
    - serializers
    - caching
---

# turbodrf

**TurboDRF** - Dead simple Django REST API generator with role-based permissions

Turn your Django models into fully-featured REST APIs with a mixin and a configuration method. Zero boilerplate.

## Overview

TurboDRF is a Django REST Framework mixin-based library that automatically generates CRUD API endpoints for your models. Unlike traditional DRF setups requiring ViewSets and serializers, TurboDRF uses a simple mixin pattern where you declare your model inherits from `TurboDRFMixin` and define a `turbodrf()` configuration method.

**Key Features:**
- Automatic CRUD endpoints from model declaration
- Role-based access control (RBAC)
- Field-level permissions
- Built-in search, filtering, ordering, and pagination
- Nested field support for relationships
- Client-side field selection (`?fields=`)
- Auto-generated API documentation (Swagger UI, ReDoc)
- Performance optimizations with compiled read path
- Security: sensitive fields deny-list, FK injection defense, startup safety gates

## Installation

### PyPI

```bash
pip install turbodrf

# Optional: faster JSON rendering (7x faster than stdlib)
pip install turbodrf[fast]
```

### GitHub

```bash
pip install git+https://github.com/AlexanderCollins/TurboDRF.git
```

### Requirements

- Python >=3.10 (tested: 3.10, 3.11, 3.12, 3.13, 3.14)
- Django >=4.2 (tested: 4.2, 5.2, 6.0)
- Django REST Framework >=3.14.0
- drf-yasg >=1.21.0, django-filter >=23.0
- Optional extras: `turbodrf[fast]` (msgspec/orjson ~7x faster), `turbodrf[allauth]` (django-allauth >=0.57.0)

Verified against TurboDRF v0.5.1 (2026-07-12).

## Quick Start

### 1. Add to `INSTALLED_APPS`

```python
# settings.py
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'django_filters',
    'turbodrf',
    'myapp',
]
```

### 2. Add the mixin to your model

```python
# myapp/models.py
from django.db import models
from turbodrf.mixins import TurboDRFMixin

class Book(models.Model, TurboDRFMixin):
    title = models.CharField(max_length=200)
    author = models.CharField(max_length=100)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    published_date = models.DateField()
    searchable_fields = ['title', 'author']
    
    @classmethod
    def turbodrf(cls):
        return {
            'fields': ['title', 'author', 'price', 'published_date']
        }
```

### 3. Add the router

```python
# urls.py
from django.contrib import admin
from django.urls import path, include
from turbodrf.router import TurboDRFRouter

router = TurboDRFRouter()

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
]
```

### 4. Configure TurboDRF roles

```python
# settings.py
TURBODRF_ROLES = {
    'admin': [
        'myapp.book.read',
        'myapp.book.create',
        'myapp.book.update',
        'myapp.book.delete',
        'myapp.book.price.read',
        'myapp.book.price.write',
    ],
    'editor': [
        'myapp.book.read',
        'myapp.book.update',
        'myapp.book.price.read',
    ],
    'viewer': [
        'myapp.book.read',
    ]
}
```

### 5. Extend User Model with Roles

```python
# myapp/apps.py
from django.apps import AppConfig
from django.contrib.auth import get_user_model

class MyAppConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'myapp'
    
    def ready(self):
        User = get_user_model()
        
        def get_user_roles(self):
            return [group.name for group in self.groups.all()]
        
        if not hasattr(User, 'roles'):
            User.add_to_class('roles', property(get_user_roles))
```

**Done!** You now have a full REST API at `/api/`:

```
GET    /api/books/          # List all books
POST   /api/books/          # Create a new book
GET    /api/books/1/        # Get a specific book
PUT    /api/books/1/        # Update a book
DELETE /api/books/1/        # Delete a book
```

**Query parameters:**
```
GET /api/books/?search=django              # Search
GET /api/books/?author__name=Smith         # Filter
GET /api/books/?ordering=-price            # Order
GET /api/books/?page=2&page_size=10        # Paginate
GET /api/books/?fields=title,price         # Client field selection
```

## Model Configuration

### Basic Configuration

```python
@classmethod
def turbodrf(cls):
    return {
        'enabled': True,              # Enable/disable API (default: True)
        'endpoint': 'books',          # Custom endpoint name
        'fields': ['title', 'author'], # Fields to expose
        'public_access': False,       # Allow unauthenticated GET
        'lookup_field': 'pk',         # URL lookup field ('pk' or 'slug')
        'compiled': True,             # Use compiled read path
    }
```

### Fields Specification

**All database fields:**
```python
'fields': '__all__'
```

**Specific fields (same for list and detail):**
```python
'fields': ['title', 'author', 'price']
```

**Different fields for list vs detail:**
```python
'fields': {
    'list': ['title', 'author', 'price'],
    'detail': ['title', 'description', 'author__email', 'price']
}
```

### Nested Fields

Access related model fields with `__` notation:

```python
'fields': [
    'title',
    'author__name',              # ForeignKey (1 level)
    'author__publisher__name',   # Multi-level (2 levels)
    'tags__name',               # ManyToMany
]
```

FK fields are flattened (`author__name` → `author_name`). M2M fields are arrays:

```json
{
    "title": "Django for APIs",
    "author_name": "William Vincent",
    "tags": [{"name": "Python"}, {"name": "Django"}]
}
```

Maximum nesting depth is 3 by default. Change with `TURBODRF_MAX_NESTING_DEPTH`.

### Property Fields

Model `@property` methods work in the compiled path:

```python
class Book(models.Model, TurboDRFMixin):
    title = models.CharField(max_length=200)
    price = models.DecimalField(max_digits=10, decimal_places=2)

    @property
    def display_title(self):
        return self.title.upper()

    @classmethod
    def turbodrf(cls):
        return {
            'fields': ['title', 'price', 'display_title']
        }
```

Properties accessing related objects won't work in compiled path — use `author__name` instead.

### List/Detail Field Separation

```python
class Book(models.Model, TurboDRFMixin):
    title = models.CharField(max_length=200)
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    
    @classmethod
    def turbodrf(cls):
        return {
            'fields': {
                'list': ['title', 'price'],
                'detail': ['title', 'description', 'price']
            }
        }
```

## Documentation

Auto-generated Swagger UI and ReDoc:
- Swagger UI: `/api/swagger/`
- ReDoc: `/api/redoc/`

Disable in production:
```python
TURBODRF_ENABLE_DOCS = False
```

## Management Commands

```bash
# Validate configuration
python manage.py turbodrf_check

# Performance benchmark
python manage.py turbodrf_benchmark

# Explain query execution
python manage.py turbodrf_explain
```

## Integrations

TurboDRF ships optional, experimental integrations (all settings-gated):

- **Sentry** — security-event breadcrumbs
- **Keycloak** — role mapping (`STRICT_ROLES=True` default)
- **django-allauth** — group→role mapping (`pip install turbodrf[allauth]`)
- **drf-api-tracking** — request logging

Fast JSON: `pip install turbodrf[fast]` adds msgspec (~7x faster serialization).

## AI Agent Guidance

The TurboDRF repository ships an `AGENTS.md` with canonical guidance for AI coding agents — the "what never to do" list plus `invalidate_user_permissions()` cache API and testing patterns.

- **Repo AGENTS.md**: https://github.com/AlexanderCollins/TurboDRF/blob/main/AGENTS.md

> **Docs status:** The readthedocs and GitHub Pages sites are currently 404. The repo `docs/` folder is the only current documentation source.

## Best Practices

### 1. Use Meta Options

Define fields explicitly rather than `__all__` for better control.

### 2. Validate Input

Use Django's form validation or custom validators:

```python
def validate_title(value):
    if Book.objects.filter(title=value).exclude(pk=self.instance.pk).exists():
        raise serializers.ValidationError("Title already exists")
    return value
```

### 3. Use Permissions

Restrict access appropriately:

```python
TURBODRF_ROLES = {
    'public': ['myapp.book.read'],
    'staff': [
        'myapp.book.read',
        'myapp.book.create',
        'myapp.book.update',
        'myapp.book.delete',
    ],
}
```

### 4. Filter Usage

Users can only filter on fields they have read permission for.

### 5. Secure Sensitive Data

Always include sensitive fields in the deny-list:

```python
TURBODRF_SENSITIVE_FIELDS = [
    'password', 'token', 'api_key', 'secret_key',
]
```

## Deep Dives

The following reference documents are loaded on demand from `references/`:

- **references/permissions-tenancy.md** — Role-based permissions, field-level access, multi-tenant predicates, row-level scoping
- **references/security-settings.md** — Security gates, fail-closed design, settings reference, troubleshooting
- **references/examples.md** — Complete CRUD API examples with nested relationships

## References

- **GitHub Repository**: https://github.com/AlexanderCollins/TurboDRF
- **PyPI Package**: https://pypi.org/project/turbodrf/
- **Documentation**: https://github.com/AlexanderCollins/TurboDRF/tree/main/docs
  - [Configuration](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/configuration.md)
  - [Permissions](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/permissions.md)
  - [Tenancy & row-level access](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/tenancy.md)
  - [Performance](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/performance.md)
  - [Filtering & Search](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/filtering.md)
  - [Integrations](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/integrations.md)
  - [Security](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/security.md)
  - [Management Commands](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/commands.md)
  - [Settings Reference](https://github.com/AlexanderCollins/TurboDRF/blob/main/docs/settings_reference.md)
- **AI Agent Guide (AGENTS.md)**: https://github.com/AlexanderCollins/TurboDRF/blob/main/AGENTS.md