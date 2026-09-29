<!-- Loaded on demand from ../SKILL.md -->

# Examples

## Complete CRUD API

**models.py:**
```python
from django.db import models
from turbodrf.mixins import TurboDRFMixin

class Author(models.Model, TurboDRFMixin):
    name = models.CharField(max_length=100)
    email = models.EmailField()
    
    @classmethod
    def turbodrf(cls):
        return {
            'fields': ['name', 'email']
        }

class Book(models.Model, TurboDRFMixin):
    title = models.CharField(max_length=200)
    author = models.ForeignKey(Author, on_delete=models.CASCADE)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    
    @classmethod
    def turbodrf(cls):
        return {
            'fields': {
                'list': ['title', 'author__name'],
                'detail': ['title', 'author__name', 'author__email', 'price']
            }
        }
```

**settings.py:**
```python
INSTALLED_APPS = [
    'rest_framework',
    'turbodrf',
    'myapp',
]

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

**urls.py:**
```python
from django.contrib import admin
from django.urls import path, include
from turbodrf.router import TurboDRFRouter

router = TurboDRFRouter()

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
]
```