---
name: django-filter
description: "django-filter - Django filtering library for querysets with Django REST Framework integration"
metadata:
  author: mte90
  version: 1.0.0
  tags:
    - django
    - django-filter
    - filtering
    - django-rest-framework
    - queryset
---

# django-filter

Django filtering library for dynamically filtering querysets, with full Django REST Framework integration.

## Overview

django-filter provides a declarative way to filter querysets based on URL query parameters.

- **Declarative** - Define filters as Python classes
- **DRF Integration** - Seamless Django REST Framework support
- **Flexible** - Custom filter backends and fields
- **Auto-generation** - FilterSet from Django models

---

## Installation

```bash
pip install django-filter

# With DRF support
pip install django-filter djangorestframework
```

Add to `INSTALLED_APPS`:

```python
INSTALLED_APPS = [
    # ...
    'django_filters',
]
```

---

## Basic Usage

### FilterSet Class

```python
# filters.py
import django_filters
from .models import Product

class ProductFilter(django_filters.FilterSet):
    # Exact match
    category = django_filters.NumberFilter(field_name='category_id')
    
    # Lookup expressions (icontains, exact, gt, gte, lt, lte, contains, in)
    name = django_filters.CharFilter(field_name='name', lookup_expr='icontains')
    price_min = django_filters.NumberFilter(field_name='price', lookup_expr='gte')
    price_max = django_filters.NumberFilter(field_name='price', lookup_expr='lte')
    
    # Boolean filter
    in_stock = django_filters.BooleanFilter(field_name='stock', lookup_expr='gt', method='filter_in_stock')
    
    # Date filters
    created_after = django_filters.DateFilter(field_name='created_at', lookup_expr='gte')
    created_before = django_filters.DateFilter(field_name='created_at', lookup_expr='lte')
    
    # Multiple selection (comma-separated)
    categories = django_filters.CharFilter(field_name='category_id', lookup_expr='in')
    
    # Ordering filter
    order_by = django_filters.OrderingFilter(
        fields=['price', 'created_at', 'name'],
        field_labels={'price': 'Price', 'created_at': 'Date'}
    )

    class Meta:
        model = Product
        fields = ['category', 'name', 'price', 'in_stock', 'is_active']

    def filter_in_stock(self, queryset, name, value):
        """Custom filter method for in_stock."""
        if value:
            return queryset.filter(stock__gt=0)
        return queryset.filter(stock=0)
```

### FilterSet with ModelForm

```python
# Auto-generate filters from model fields
class ProductFilter(django_filters.FilterSet):
    class Meta:
        model = Product
        fields = ['name', 'category', 'price', 'is_active', 'stock']
```

---

## Django REST Framework Integration

### ViewSet Integration

```python
# views.py
from rest_framework import viewsets
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters
from .models import Product
from .serializers import ProductSerializer
from .filters import ProductFilter

class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    
    # Filter backends
    filter_backends = [
        DjangoFilterBackend,
        filters.SearchFilter,
        filters.OrderingFilter
    ]
    
    # Filterset class
    filterset_class = ProductFilter
    
    # Or inline filterset_fields
    filter_fields = ['category', 'is_active']
    
    # Search configuration
    search_fields = ['name', 'description', 'category__name']
    
    # Ordering fields
    ordering_fields = ['price', 'created_at', 'name']
    ordering = ['-created_at']
```

### APIView Integration

```python
# views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters
from .models import Product
from .serializers import ProductSerializer
from .filters import ProductFilter

class ProductListView(APIView):
    def get(self, request):
        queryset = Product.objects.all()
        
        # Apply filters manually
        filter_backend = DjangoFilterBackend()
        queryset = filter_backend.filter_queryset(request, queryset, self)
        
        serializer = ProductSerializer(queryset, many=True)
        return Response(serializer.data)
```

---

## Filter Types Reference

### NumberFilter

```python
price = django_filters.NumberFilter()
price_gt = django_filters.NumberFilter(field_name='price', lookup_expr='gt')
price_range = django_filters.RangeFilter(field_name='price')
```

### CharFilter

```python
name = django_filters.CharFilter(lookup_expr='icontains')
description = django_filters.CharFilter(lookup_expr='contains')
```

### DateFilter / DateTimeFilter

```python
created = django_filters.DateFilter()
created_after = django_filters.DateTimeFilter(field_name='created_at', lookup_expr='gte')
```

### BooleanFilter

```python
is_active = django_filters.BooleanFilter()
is_featured = django_filters.BooleanFilter(field_name='is_featured', distinct=False)
```

### ModelChoiceFilter / ModelMultipleChoiceFilter

```python
category = django_filters.ModelChoiceFilter(
    queryset=Category.objects.all(),
    empty_label='All Categories'
)

tags = django_filters.ModelMultipleChoiceFilter(
    queryset=Tag.objects.all(),
    conjoined=True  # AND vs OR behavior
)
```

### ChoiceFilter

```python
status = django_filters.ChoiceFilter(
    choices=Product.STATUS_CHOICES,
    empty_label=None
)
```

### UUIDFilter

```python
id = django_filters.UUIDFilter(field_name='id')
```

### AllValuesFilter / AllValuesMultipleFilter

```python
# Dropdown with all possible values
category = django_filters.AllValuesFilter(field_name='category_id')
```

### DateFromToRangeFilter

```python
date_range = django_filters.DateFromToRangeFilter(field_name='created_at')
```

### TimeFromToRangeFilter

```python
time_range = django_filters.TimeFromToRangeFilter(field_name='created_at')
```

### DateTimeFromToRangeFilter

```python
datetime_range = django_filters.DateTimeFromToRangeFilter(field_name='created_at')
```

### NumberRangeFilter

```python
price_range = django_filters.NumberRangeFilter(field_name='price')
```

---

## Custom Filter Methods

### Method Filter with Request Context

```python
class ProductFilter(django_filters.FilterSet):
    # Access request in filter method
    category = django_filters.NumberFilter(method='filter_by_category')
    
    class Meta:
        model = Product
        fields = ['category']

    def filter_by_category(self, queryset, name, value):
        # Access request, user, etc. via self.request
        user = self.request.user
        
        if user.is_premium:
            return queryset.filter(category_id=value)
        return queryset.filter(category_id=value, category__is_premium=False)
```

### Filter with Multiple Fields

```python
class ProductFilter(django_filters.FilterSet):
    price_min = django_filters.NumberFilter(field_name='price', lookup_expr='gte')
    price_max = django_filters.NumberFilter(field_name='price', lookup_expr='lte')
    min_max_price = django_filters.NumberFilter(method='filter_price_range')

    def filter_price_range(self, queryset, name, value):
        # Handle custom filter logic
        return queryset.filter(price__gte=value)
```

---

## Composable QuerySet Methods (FilterSet Alternative)

When filtering is driven by code paths rather than user-supplied query params,
define a custom `QuerySet` with one method per `WHERE` clause. The view reads
like a sentence, and each method is independently testable.

```python
from django.db import models

class EventQuerySet(models.QuerySet):
    def approved(self):
        return self.filter(approved_at__isnull=False)

    def future(self):
        today = timezone.localdate()
        return self.filter(end__gt=self._midnight(today))

    def with_tags(self, tags):
        if not tags:
            return self
        return self.filter(tags__name__in=tags).distinct()

    def is_free(self, free):
        if free is None:
            return self
        return self.filter(price=0) if free else self

class Event(models.Model):
    objects = EventQuerySet.as_manager()
    # ...
```

Usage in a view — each method returns a queryset, so they chain naturally:

```python
def event_list(request, tab):
    qs = (
        Event.objects.approved()
        .for_tab(tab)
        .with_festivals(tab_params.festival_slugs)
        .is_free(tab_params.free)
    )
    return render(request, 'events/list.html', {'events': qs})
```

### When to choose QuerySet methods vs FilterSet

| Need | Pick |
|------|------|
| User-facing filters from query params, DRF integration, auto-generated form | `FilterSet` |
| Code-driven filtering, readable chains, no query-param binding | Custom `QuerySet` methods |
| Both | Combine: `FilterSet` for the API surface, `QuerySet` methods for internal reuse |

Guidelines for QuerySet methods:
- Return `self` (not `None`) when the filter is a no-op, so chains never break.
- Guard each method against its argument being empty/None — callers should not
  have to branch before calling.
- Keep methods single-purpose; compose in the view rather than adding flags.

## DRF Tips & Patterns

### FilterBackend per Action

```python
class ProductViewSet(viewsets.ModelViewSet):
    def get_filter_backends(self):
        if self.action == 'list':
            return [DjangoFilterBackend, filters.SearchFilter]
        return []

class OrderViewSet(viewsets.ModelViewSet):
    filter_backends = [DjangoFilterBackend]
    filterset_class = OrderFilter
    
    def get_queryset(self):
        # Exclude cancelled orders for non-admin users
        if not self.request.user.is_staff:
            return Order.objects.exclude(status='cancelled')
        return Order.objects.all()
```

### Conditional Filter Fields

```python
class ProductFilter(django_filters.FilterSet):
    class Meta:
        model = Product
        fields = []

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        
        # Add fields dynamically based on user
        if self.request.user.is_staff:
            self.filters['is_active'].field_class = django_filters.BooleanFilter()
```

### Select Related in Filtered Viewsets

```python
class ProductViewSet(viewsets.ModelViewSet):
    serializer_class = ProductSerializer
    
    def get_queryset(self):
        # Use select_related to avoid N+1
        return Product.objects.select_related('category').prefetch_related('tags')
```

---

## URL Patterns

### Basic

```bash
GET /api/products/
GET /api/products/?category=1
GET /api/products/?category=1&price_min=10&price_max=100
GET /api/products/?search=laptop
GET /api/products/?ordering=price
GET /api/products/?ordering=-price
GET /api/products/?categories=1,2,3
```

### With Filterset Class

```bash
GET /api/products/?name__icontains=laptop
GET /api/products/?price__gte=10
GET /api/products/?in_stock=true
GET /api/products/?created_after=2024-01-01
```

### Range Filters

```bash
GET /api/products/?price_range_min=10&price_range_max=100
GET /api/products/?date_range_after=2024-01-01&date_range_before=2024-12-31
```

---

## Best Practices

### Filter Naming Conventions

```python
# Use descriptive names that map to query params
price_min = django_filters.NumberFilter(field_name='price', lookup_expr='gte')
price_max = django_filters.NumberFilter(field_name='price', lookup_expr='lte')

# In URL: ?price_min=10&price_max=100
```

### Performance

```python
# Always use select_related/prefetch_related in get_queryset
class ProductViewSet(viewsets.ModelViewSet):
    def get_queryset(self):
        return Product.objects.select_related('category', 'vendor').prefetch_related('tags')
```

### Validation

```python
class ProductFilter(django_filters.FilterSet):
    price_min = django_filters.NumberFilter()
    price_max = django_filters.NumberFilter()
    
    class Meta:
        model = Product
        fields = ['price_min', 'price_max']
    
    def validate_price_range(self, cleaned_data):
        if cleaned_data.get('price_min') and cleaned_data.get('price_max'):
            if cleaned_data['price_min'] > cleaned_data['price_max']:
                raise serializers.ValidationError("price_min must be less than price_max")
        return cleaned_data
```

---

## Do

- Use `filterset_class` for complex filtering logic
- Use `select_related` and `prefetch_related` to avoid N+1 queries
- Use meaningful filter field names (`price_min`, `price_max` instead of `price` used twice)
- Add empty labels for optional filters with ModelChoiceFilter

## Don't

- Don't expose all model fields as filters - only expose what's needed
- Don't forget to add appropriate indexes on filtered fields
- Don't use filters that require expensive operations without pagination

---

## References

- **django-filter Docs**: https://django-filter.readthedocs.io/en/stable/guide/usage.html
- **DRF Integration**: https://django-filter.readthedocs.io/en/stable/guide/rest_framework.html
- **Tips**: https://django-filter.readthedocs.io/en/stable/guide/tips.html
- **GitHub**: https://github.com/carltongibson/django-filter
- **jvns.ca – More nice Django things (composable QuerySet methods)**: https://jvns.ca/blog/2026/07/21/more-nice-django-things/