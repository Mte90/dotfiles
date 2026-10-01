---
name: django-filter
description: Use when filtering Django querysets - FilterSet, custom filters, Django REST Framework integration, explicit fields
metadata:
  author: mte90
  version: 1.0.1
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

# With DRF integration
pip install django-filter djangorestframework
```

Add to `INSTALLED_APPS`:

```python
INSTALLED_APPS = [
    'django_filters',
]
```

---

## Basic FilterSet Pattern

```python
# filters.py
import django_filters
from .models import Product

class ProductFilter(django_filters.FilterSet):
    # Range filters (min/max naming convention)
    price_min = django_filters.NumberFilter(field_name='price', lookup_expr='gte')
    price_max = django_filters.NumberFilter(field_name='price', lookup_expr='lte')
    
    # Text search
    name = django_filters.CharFilter(field_name='name', lookup_expr='icontains')
    
    # Boolean filter
    in_stock = django_filters.BooleanFilter(method='filter_in_stock')
    
    # Multiple selection (comma-separated values)
    categories = django_filters.CharFilter(field_name='category__slug', lookup_expr='in')
    
    # Date range
    created_after = django_filters.DateFilter(field_name='created_at', lookup_expr='gte')
    
    # Ordering
    order_by = django_filters.OrderingFilter(
        fields=[('price', 'price'), ('created_at', 'created_at'), ('name', 'name')]
    )

    class Meta:
        model = Product
        fields = '__all__'  # Django 6.0+: must be string '__all__' or explicit list

    def filter_in_stock(self, queryset, name, value):
        if value:
            return queryset.filter(stock__gt=0)
        return queryset

    class Meta:
        model = Product
        fields = ['category', 'name', 'price', 'stock']
```

### Django 6.0 Breaking Change

The `fields` attribute requires explicit `__all__`:

```python
class UserFilter(FilterSet):
    class Meta:
        model = User
        fields = '__all__'  # String, not list
```

Using `fields = []` without `__all__` raises an error in Django 6.0+.

---

## Filter Type Selection

Choose filter types based on query shape, not field type. See [django-filter field documentation](https://django-filter.readthedocs.io/en/stable/guide/fields.html) for the full API.

| Query shape | Filter type | Example |
|-------------|-------------|---------|
| Exact match | `CharFilter` / `NumberFilter` | `category = CharFilter()` |
| Multiple values | `CharFilter` with `lookup_expr='in'` | `ids = CharFilter(lookup_expr='in')` |
| Range (min/max) | Two separate filters | `price_min`, `price_max` |
| Date range | `DateFromToRangeFilter` | `date_range = DateFromToRangeFilter()` |
| Relational (FK/M2M) | Filter on related field | `author__name = CharFilter()` |
| Custom logic | `Filter` with `method=` | `status = Filter(method='filter_status')` |

**Avoid enumerating all 12+ filter types** — focus on the lookup expressions you actually need: `exact`, `icontains`, `gt`, `gte`, `lt`, `lte`, `in`, `isnull`.

---

## Composable QuerySet Methods

When filtering is driven by code paths rather than user-supplied query params,
define a custom `QuerySet` with one method per `WHERE` clause. The view reads
like a sentence, and each method is independently testable.

```python
from django.db import models
from django.utils import timezone

class EventQuerySet(models.QuerySet):
    def approved(self):
        return self.filter(approved_at__isnull=False)

    def future(self):
        today = timezone.localdate()
        return self.filter(end__gt=self._midnight(today))

    def _midnight(self, date):
        return timezone.datetime(date.year, date.month, date.day, tzinfo=timezone.utc)

    def with_tags(self, tags):
        if not tags:
            return self
        return self.filter(tags__name__in=tags).distinct()

    def is_free(self, free):
        if free is None:
            return self
        return self.filter(price=0) if free else self

    def for_tab(self, tab):
        if tab == 'featured':
            return self.filter(featured=True)
        if tab == 'popular':
            return self.filter(views__gte=100)
        return self

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
        .with_tags(request.GET.getlist('tags'))
        .is_free(request.GET.get('free') == 'true')
    )
    return render(request, 'events/list.html', {'events': qs})
```

### Guidelines for QuerySet methods

- Return `self` (not `None`) when the filter is a no-op, so chains never break.
- Guard each method against its argument being empty/None — callers should not
  have to branch before calling.
- Keep methods single-purpose; compose in the view rather than adding flags.

---

## FilterSet Composition

### Combining FilterSets with `&`

Combine multiple `FilterSet` classes to create composite filters:

```python
class BaseProductFilter(django_filters.FilterSet):
    """Common filters used across multiple views."""
    search = django_filters.CharFilter(method='filter_search')
    category = django_filters.ModelChoiceFilter(
        field_name='category',
        queryset=Category.objects.active()
    )

    class Meta:
        model = Product
        fields = []

    def filter_search(self, queryset, name, value):
        if not value:
            return queryset
        return queryset.filter(
            models.Q(name__icontains=value) |
            models.Q(description__icontains=value)
        )

class PriceFilter(django_filters.FilterSet):
    price_min = django_filters.NumberFilter(field_name='price', lookup_expr='gte')
    price_max = django_filters.NumberFilter(field_name='price', lookup_expr='lte')
    on_sale = django_filters.BooleanFilter(method='filter_on_sale')

    class Meta:
        model = Product
        fields = []

    def filter_on_sale(self, queryset, name, value):
        if value:
            return queryset.filter(discount__gt=0)
        return queryset

# Combine filters
ProductFilter = BaseProductFilter & PriceFilter
```

**Failure mode**: Without composition, you either duplicate filter definitions or create bloated monolithic `FilterSet` classes. The `&` operator merges filters cleanly.

### Subclassing for shared base filters

```python
class BaseFilter(django_filters.FilterSet):
    """Base class with filters shared across multiple FilterSets."""
    created_after = django_filters.DateFilter(field_name='created_at', lookup_expr='gte')
    created_before = django_filters.DateFilter(field_name='created_at', lookup_expr='lte')
    ordering = django_filters.OrderingFilter(
        fields=['created_at', 'updated_at', 'name']
    )

    class Meta:
        model = None  # Subclasses must define Meta.model
        fields = []

class ProductFilter(BaseFilter):
    class Meta:
        model = Product
        fields = ['category', 'is_active']

class OrderFilter(BaseFilter):
    class Meta:
        model = Order
        fields = ['status', 'customer']
```

**Failure mode**: Duplicating date range and ordering filters across multiple `FilterSet` classes leads to drift when you add a new field to one but forget another.

### Using `@property` for computed filters

```python
class ProductFilter(django_filters.FilterSet):
    price_min = django_filters.NumberFilter()
    price_max = django_filters.NumberFilter()

    class Meta:
        model = Product
        fields = []

    @property
    def is_price_range_valid(self):
        """Check if both min and max are provided and valid."""
        price_min = self.data.get('price_min')
        price_max = self.data.get('price_max')
        if price_min and price_max:
            return float(price_min) <= float(price_max)
        return True

    @property
    def qs(self):
        qs = super().qs
        # Access computed property to trigger validation
        if not self.is_price_range_valid:
            # Return empty queryset or raise error
            return qs.none()
        return qs
```

**Failure mode**: Trying to validate cross-field constraints in `__init__` fails because filters haven't been instantiated yet. Use `@property` on `qs` to validate after filter application.

### Overriding `get_queryset()` for cross-field logic

```python
class ProductFilter(django_filters.FilterSet):
    min_price = django_filters.NumberFilter(field_name='price', lookup_expr='gte')
    max_price = django_filters.NumberFilter(field_name='price', lookup_expr='lte')
    category = django_filters.CharFilter()

    class Meta:
        model = Product
        fields = []

    def get_queryset(self):
        """Access other filter values for cross-field logic."""
        qs = super().get_queryset()
        
        # Example: filter based on relationship between fields
        min_price = self.data.get('min_price')
        max_price = self.data.get('max_price')
        
        if min_price and max_price:
            # Custom logic: ensure price is within 10% of midpoint
            midpoint = (float(min_price) + float(max_price)) / 2
            tolerance = midpoint * 0.1
            qs = qs.filter(price__gte=midpoint - tolerance, price__lte=midpoint + tolerance)
        
        return qs
```

**Failure mode**: `FilterSet` re-runs `get_queryset()` per request — there's no caching of the base queryset. If your `get_queryset()` performs expensive operations, cache the result or move logic to the view.

### `distinct()` for ManyToMany traversals

```python
class ProductFilter(django_filters.FilterSet):
    tags = django_filters.CharFilter(field_name='tags__name', lookup_expr='in')
    categories = django_filters.CharFilter(field_name='category__slug', lookup_expr='in')

    class Meta:
        model = Product
        fields = ['tags', 'categories']
        # Enable distinct to avoid duplicate rows from M2M joins
        # Note: django-filter doesn't auto-add distinct; you must handle it
```

In the view:

```python
def product_list(request):
    filter = ProductFilter(request.GET, queryset=Product.objects.all())
    qs = filter.qs.distinct()  # Required for M2M filters
    return render(request, 'products.html', {'products': qs})
```

**Failure mode**: Without `distinct()`, filtering on multiple M2M relationships produces duplicate rows (Cartesian product of joins).

---

## Decision: django-filter vs plain query params vs manual filtering

### Use django-filter when

- You need **DRF integration** (automatic filter schema, OpenAPI docs)
- Filters are **user-facing and dynamic** (users can combine any filter)
- You have **10+ filter parameters** or complex cross-field logic
- Multiple views share **the same filter set**
- You want **validation** of filter values (type coercion, range checks)

### Use plain `request.GET` when

- You have **2-3 stable parameters** (e.g., `page`, `limit`, `sort`)
- The API is **internal** with controlled consumers
- You need **full control** over query construction
- The threshold: hand-written `request.GET` handling is simpler for ≤3 params

```python
def product_list(request):
    page = int(request.GET.get('page', 1))
    limit = min(int(request.GET.get('limit', 20)), 100)  # Cap at 100
    sort = request.GET.get('sort', 'created_at')
    
    if sort not in ['created_at', 'price', 'name']:
        sort = 'created_at'  # Whitelist validation
    
    qs = Product.objects.all().order_by(sort)[(page-1)*limit:page*limit]
    return render(request, 'products.html', {'products': qs})
```

### When django-filter is overkill

- **Public API with a handful of stable params** — manual handling is clearer
- **Filters that depend on session/auth state** — put logic in `get_queryset()`
- **Complex business logic** — use QuerySet methods instead of filters

---

## Correctness & Performance

### `distinct()` on ManyToMany traversals

When filtering on M2M relationships, JOINs produce duplicate rows:

```python
# Without distinct: products with 3 tags appear 3 times
qs = Product.objects.filter(tags__name__in=['sale', 'new'])

# With distinct: each product appears once
qs = Product.objects.filter(tags__name__in=['sale', 'new']).distinct()
```

**Warning**: `distinct()` without arguments uses all fields. If you need to order by a filtered field, use `distinct('field_name')` (PostgreSQL only) or restructure the query.

### Indexing filtered columns

A filter on an unindexed column is a table scan:

```python
class Product(models.Model):
    name = models.CharField(max_length=255, db_index=True)  # Index on filter field
    price = models.DecimalField(max_digits=10, 2, db_index=True)
    category = models.ForeignKey(Category, on_delete=models.CASCADE)
    
    class Meta:
        indexes = [
            models.Index(fields=['-created_at']),  # For ordering
            models.Index(fields=['category', '-created_at']),  # Composite
        ]
```

Use `EXPLAIN` to verify index usage on slow filters.

### Bounding `__in` with user-supplied lists

```python
# Dangerous: unbounded list from user input
ids = request.GET.getlist('ids')
Product.objects.filter(id__in=ids)  # Could be millions of rows

# Safe: cap the list length
MAX_IDS = 100
ids = request.GET.getlist('ids')[:MAX_IDS]
Product.objects.filter(id__in=ids)
```

**Failure mode**: `id__in` with 10,000 values creates a massive SQL IN clause, causing query timeouts.

### `FilterSet` re-runs `get_queryset()` per request

```python
class ProductViewSet(viewsets.ModelViewSet):
    filterset_class = ProductFilter
    
    def get_queryset(self):
        # This runs EVERY request, not just once
        return Product.objects.select_related('category')
```

**Failure mode**: Assuming `get_queryset()` is cached and putting expensive operations there (e.g., calling an external API). Cache explicitly if needed:

```python
from django.core.cache import cache

def get_queryset(self):
    cache_key = 'product_base_qs'
    qs = cache.get(cache_key)
    if qs is None:
        qs = Product.objects.select_related('category')
        cache.set(cache_key, qs, timeout=300)
    return qs
```

---

## Django REST Framework Integration

### Basic ViewSet setup

```python
from rest_framework import viewsets
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters
from .models import Product
from .filters import ProductFilter

class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_class = ProductFilter
    ordering_fields = ['price', 'created_at']
    ordering = ['-created_at']
```

### Ordering pitfall: `OrderingFilter` vs FilterSet ordering

`OrderingFilter` (from DRF) and `FilterSet` ordering are separate:

```python
class ProductFilter(django_filters.FilterSet):
    # This creates an 'order_by' filter param
    order_by = django_filters.OrderingFilter(
        fields=['price', 'created_at']
    )

    class Meta:
        model = Product
        fields = []

class ProductViewSet(viewsets.ModelViewSet):
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_class = ProductFilter
    # ordering_fields applies to DRF's OrderingFilter, NOT FilterSet
    ordering_fields = ['price', 'created_at']
```

**Failure mode**: Using both `OrderingFilter` in `filter_backends` AND an `OrderingFilter` field in your `FilterSet` creates conflicting ordering behavior. Pick one:
- Use `FilterSet.ordering` for filter-param-based ordering (user types `?order_by=-price`)
- Use `OrderingFilter` in `filter_backends` for header-based ordering (user sends `Order: -price`)

---

## URL Patterns

```bash
# Basic filtering
GET /api/products/?category=1
GET /api/products/?price_min=10&price_max=100

# Text search
GET /api/products/?name__icontains=laptop

# Multiple values (comma-separated)
GET /api/products/?categories=electronics,books

# Date range
GET /api/products/?created_after=2024-01-01

# Ordering
GET /api/products/?order_by=-price
GET /api/products/?ordering=-price  # DRF OrderingFilter
```

---

## Common Pitfalls

### S silently ignoring unknown query parameters

django-filter ignores parameters not defined in your `FilterSet`:

```python
class ProductFilter(django_filters.FilterSet):
    price_min = django_filters.NumberFilter()
    
    class Meta:
        model = Product
        fields = []

# GET /api/products/?unknown_param=123 → silently ignored
```

**Fix**: Validate with `strict=True` (django-filter 4.0+):

```python
class ProductFilter(django_filters.FilterSet):
    class Meta:
        model = Product
        fields = []
        strict = True  # Raise error on unknown params
```

### Not exposing all model fields accidentally

```python
class Meta:
    model = Product
    fields = '__all__'  # Exposes EVERY field — often unintended
```

**Fix**: Be explicit:

```python
class Meta:
    model = Product
    fields = ['category', 'price', 'name', 'is_active']
```

---

## References

- **django-filter Docs**: https://django-filter.readthedocs.io/en/stable/guide/usage.html
- **DRF Integration**: https://django-filter.readthedocs.io/en/stable/guide/rest_framework.html
- **Tips**: https://django-filter.readthedocs.io/en/stable/guide/tips.html
- **GitHub**: https://github.com/carltongibson/django-filter
- **jvns.ca – More nice Django things (composable QuerySet methods)**: https://jvns.ca/blog/2026/07/21/more-nice-django-things/
