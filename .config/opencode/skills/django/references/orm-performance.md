<!-- This file is loaded on demand from frameworks/django/SKILL.md -->

## ORM Optimization

### Indexing Strategy

**db_index on filter/search fields** - Critical for API performance:

```python
class Product(models.Model):
    # Add db_index to frequently filtered fields
    sku = models.CharField(max_length=50, db_index=True, unique=True)
    category = models.ForeignKey(Category, db_index=True)
    status = models.CharField(max_length=20, db_index=True)  # Filter by status
    created_at = models.DateTimeField(db_index=True)  # Date range queries
    
    # Composite index for common query patterns
    class Meta:
        indexes = [
            models.Index(fields=['category', 'status']),
            models.Index(fields=['-created_at']),
        ]
```

> **Admin-specific optimization**: For admin queryset optimization (select_related/prefetch_related patterns, N+1 prevention in list_display), see the [django-admin skill](frameworks/django-admin/SKILL.md).

### Avoiding Duplicate Objects with Exists Subquery

When filtering across relationships (one-to-many or many-to-many), JOINs produce duplicate parent objects:

```python
# Problem: duplicates returned
Author.objects.filter(books__title__startswith="Book")
# [<Author: Charlie>, <Author: Alice>, <Author: Alice>]  # Alice appears twice
```

**Solution: Use Exists Subquery** (fastest, no ordering issues):

```python
from django.db.models import Exists, OuterRef

Author.objects.filter(
    Exists(Book.objects.filter(
        author=OuterRef("id"),
        title__startswith="Book",
    ))
).order_by("name")
```

- Stops evaluation on first match
- No ordering restrictions
- Works with all databases

**PostgreSQL-only alternative:**

```python
Author.objects.filter(books__title__startswith="Book").distinct("id")
```

### N+1 Query Prevention

**Problem:**
```python
for user in User.objects.all()[:100]:
    user.groups.count()  # 100 extra queries!
```

**Solution: Use prefetch_related with Prefetch object:**

```python
from django.db.models import Prefetch

staff_groups = Group.objects.filter(name__in=["admin", "superuser"])
users = User.objects.prefetch_related(
    "groups",
    Prefetch("groups", to_attr="staff_groups", queryset=staff_groups),
).order_by("id")[:100]

for user in users:
    groups_total = user.groups.count()  # Uses cached data
    is_staff = len(user.staff_groups) > 0  # No new query!
```

**Avoid querying prefetched objects unnecessarily:**
```python
# BAD: Makes new query
first_group = user.groups.first()
first_group = user.groups.all()[0]

---

### N+1 Detection Tools

For automated N+1 detection in development:
- **django-debug-toolbar** (https://github.com/django-commons/django-debug-toolbar) - SQL panel shows query count/origin
- **django-zeal** (https://github.com/taobojlen/django-zeal) - N+1 detector with warnings/errors
- **django-silk** (https://github.com/jazzband/django-silk) - Profiling with SQL inspection
- **django-auto-prefetch** (https://github.com/adamchainz/django-auto-prefetch) - Auto prefetch FKs on serializer-like access

### Time-Based Lookups Performance

**Problem:** `timestamp__date` lookup **bypasses indexes**:

```python
# SLOW (30s on 25M rows)
Event.objects.filter(timestamp__date=datetime.date(2026, 1, 5))
# SQL: WHERE timestamp::date='2026-01-05'  # Full table scan!
```

**Solution: Use range boundaries:**

```python
import datetime
start = datetime.datetime(2026, 1, 5, tzinfo=datetime.UTC)
end = start + datetime.timedelta(days=1)

Event.objects.filter(timestamp__gte=start, timestamp__lt=end)
# Uses index, drops to <1s
```

### Deferring Large Fields

```python
# Defer large fields you don't need
books = Book.objects.defer("content", "notes")

# Or explicitly load only needed fields
books = Book.objects.only("title", "pub_date")
```

### Statement Timeouts (PostgreSQL)

```python
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "mydb",
        "OPTIONS": {
            "options": "-c statement_timeout=30s",  # Terminate queries >30s
        },
    }
}
```

### Caching Libraries

- **django-cachalot** (https://github.com/noripyt/django-cachalot) - Auto-invalidating cache for ORM queries
- **django-cacheops** (https://github.com/Suor/django-cacheops) - Transaction-aware cache with auto-invalidation


---

## Caching

### View Caching

```python
from django.views.decorators.cache import cache_page

@cache_page(60 * 15)  # Cache for 15 minutes
def my_view(request):
    ...
```

### Template Fragment Caching

```{% load cache %}
{% cache 300 my_cache_key %}
    <!-- Expensive content -->
{% endcache %}
```

### Low-Level Cache API

```python
from django.core.cache import cache

cache.set('my_key', 'my_value', timeout=3600)
value = cache.get('my_key')
cache.delete('my_key')

# Multiple keys
cache.set_many({'a': 1, 'b': 2}, timeout=300)
cache.get_many(['a', 'b'])
```

### Redis Cache Backend

```python
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/0',
    }
}
```

---


---

## Response Time Optimization

### Use .only() to Limit Fields

```python
# Before: Fetching 130+ fields
qs = Article.objects.all()

# After: Fetch only needed fields
qs = Article.objects.only(
    "headline", "slug", "summary",
    "publication_start_date", "image",
    "primary_category"
)
```

### Denormalize Computed Fields

```python
class Article(models.Model):
    def set_publication_order_date(self):
        if self.updated_at:
            self.publication_order_date = self.updated_at
        elif self.publication_start_date:
            self.publication_order_date = self.publication_start_date
    
    def save(self, *args, **kwargs):
        self.set_publication_order_date()
        super().save(*args, **kwargs)
```

### Optimize Paginator Count

```python
# Reduce count() query cost
qs.count = qs.only("id").count
```

---


---

## Materialized Views with PostgreSQL

```python
# Using django-materialized-view library
from django_materialized_view import MaterializedViewModel

class YearlyRuntimeModel(MaterializedViewModel):
    create_pkey_index = True
    year = models.IntegerField(primary_key=True)
    average_runtime = models.IntegerField()
    
    class Meta:
        managed = False  # Important!
    
    @staticmethod
    def get_query_from_queryset():
        return Movie.objects.values('year').annotate(
            average_runtime=Avg('runtime_minutes')
        )

# Create the view
python manage.py migrate_with_views

# Refresh when data changes
YearlyRuntimeModel.refresh()
```

**Benefits:**
- Speed up complex aggregations
- Cache expensive queries
- Refresh on schedule or triggers

---

---


