---
name: django-admin
description: Use when customizing Django Admin - save_formset, get_search_results, formsets, queryset optimization, db_index, custom URLs
metadata:
  author: mte90
  version: 1.1.1
  tags:
    - python
    - django
    - admin
    - orm
    - optimization
---

# Django Admin

Specialized guide for Django Admin customization - save hooks, formsets, queryset optimization, and security considerations.

## Overview

Django Admin provides a powerful interface for managing data, but customizing it requires understanding several critical patterns:

- **Save Hooks** - `save_model`, `save_formset` order and tuple shapes
- **Search Validation** - `get_search_results` field validation
- **Formset Restrictions** - `get_formset` per-role child filtering
- **Queryset Optimization** - `select_related`, `prefetch_related`, `annotate`
- **Indexing Strategy** - `db_index` on filter/search fields
- **Audit Logging** - Tracking changes via formset hooks

> **Security Note**: Admin customization touches authorization boundaries. For comprehensive security patterns (CSRF, authentication, permissions), see the main [Django skill](../django/SKILL.md).

### Common Admin Pitfalls

| Pitfall | Impact | Fix |
|---------|--------|-----|
| `.count()` in `list_display` | N+1 queries | Use `annotate()` |
| Wrong `save_formset` shape | Lost change tracking | Expect `[(obj, dict)]` |
| `save_model` after `save_formset` | FK violations | Order is fixed: parent first |
| Unvalidated search fields | SQL injection risk | Validate against `search_fields` |
| No `get_formset` filtering | Data leakage | Filter queryset by role |

---

## Save Hooks

### save_formset Tuple Shape

Django admin formsets return a specific tuple shape in `save_formset`:

```python
from django.contrib import admin
from myapp.models import Parent, Child

@admin.register(Parent)
class ParentAdmin(admin.ModelAdmin):
    inlines = [ChildInline]
    
    def save_formset(self, request, parent, formset, save_model_kwargs):
        """Handle inline child objects.
        
        formset.changed_objects = [(instance, {field: old_value}), ...]
        formset.new_objects = [(instance,), ...]  # Bare tuples
        formset.deleted_objects = [instance, ...]  # Bare objects
        """
        changed_objects = []
        
        for obj, changed_data in formset.changed_objects:
            # changed_data is a dict: {'name': 'old_value', 'status': 'old_status'}
            changed_objects.append((obj, changed_data))
            
            # Log the change
            self.log_change(request, obj, changed_data)
        
        # Process new objects (bare tuples, no changed_data)
        for new_obj in formset.new_objects:
            # new_obj is just (instance,) - no change tracking
            pass
        
        # Process deleted objects (bare instances)
        for deleted_obj in formset.deleted_objects:
            # deleted_obj is just the instance
            pass
```

**Critical distinction**:
- `changed_objects` → `[(obj, {field: old_value})]` - dict with old values
- `new_objects` → `[(obj,)]` - bare tuple, no tracking
- `deleted_objects` → `[obj, ...]` - bare instances

### Testing save_formset Shape

Always test with real tuple shape - mocks often get this wrong:

```python
from django.test import TestCase
from django.contrib import admin
from myapp.models import Parent, Child

class ParentAdminTest(TestCase):
    def setUp(self):
        self.parent = Parent.objects.create(name='Parent')
        self.child1 = Child.objects.create(parent=self.parent, name='Child 1')
    
    def test_save_formset_tuple_shape(self):
        """save_formset receives [(obj, changed_data)] not bare lists."""
        admin_instance = admin.site._registry[Parent]
        
        # Track what save_formset receives
        received_changes = []
        
        def mock_save_formset(parent, formset, **kwargs):
            # Shape: [(instance, {field: old_value}), ...]
            received_changes.extend(formset.changed_objects)
        
        # Patch and submit
        original_save = admin_instance.save_formset
        admin_instance.save_formset = mock_save_formset
        
        try:
            # Submit form with changed child
            data = {
                'child_set-0-id': self.child1.id,
                'child_set-0-name': 'Updated Child 1',
                'child_set-TOTAL_FORMS': 1,
                'child_set-INITIAL_FORMS': 1,
            }
            self.client.post(
                f'/admin/myapp/parent/{self.parent.id}/change/',
                data
            )
        finally:
            admin_instance.save_formset = original_save
        
        # Verify shape
        assert len(received_changes) == 1
        obj, changed_data = received_changes[0]
        assert obj.id == self.child1.id
        assert 'name' in changed_data
        assert changed_data['name'] == 'Updated Child 1'
```

### Inline Save Order

`save_model` is called BEFORE `save_formset` - sync state in formset:

```python
@admin.register(Parent)
class ParentAdmin(admin.ModelAdmin):
    inlines = [ChildInline]
    
    def save_model(self, request, obj, form, change):
        """Parent is saved first."""
        super().save_model(request, obj, form, change)
        # obj.pk is now available
    
    def save_formset(self, request, parent, formset, save_model_kwargs):
        """Children are saved after parent.
        
        Use parent.pk here - it's guaranteed to exist.
        """
        instances = formset.save(commit=False)
        
        for obj in instances:
            # parent.pk is available because save_model ran first
            if not obj.parent_id:
                obj.parent = parent
            # Sync any parent-dependent state
            obj.sync_with_parent(parent)
            obj.save()
        
        formset.save_m2m()  # Save M2M relationships
```

### save_model Immutability Guard

Prevent accidental overwrites in `save_model`:

```python
@admin.register(Document)
class DocumentAdmin(admin.ModelAdmin):
    def save_model(self, request, obj, form, change):
        """Guard against accidental overwrites."""
        if not change:
            # New object - safe to save
            super().save_model(request, obj, form, change)
            return
        
        # Existing object - check for stale data
        old_obj = self.model.objects.get(pk=obj.pk)
        
        # Check critical fields weren't changed by another user
        if old_obj.version != obj.version:
            messages.warning(
                request,
                f"Document was modified by another user. "
                f"Old version: {old_obj.version}, Your version: {obj.version}"
            )
            # Option 1: Reject save
            # raise ValidationError("Stale data detected")
            
            # Option 2: Force refresh and re-apply changes
            # obj.refresh_from_db()
            # obj.apply_changes(form.cleaned_data)
        
        super().save_model(request, obj, form, change)
```

---

## Search & Formset Security

### get_search_results Field Validation

Validate that `get_search_results` searches only valid fields:

```python
@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    search_fields = ['name', 'sku', 'category__name']
    
    def get_search_results(self, request, queryset, search_term):
        """Custom search with field validation.
        
        ⚠️ search_fields must be validated - arbitrary field access!
        """
        # Validate search fields exist
        allowed_fields = {'name', 'sku', 'category__name'}
        
        # Django's search_fields are already validated at admin init
        # But custom search logic needs validation
        
        queryset, use_distinct = super().get_search_results(
            request, queryset, search_term
        )
        
        return queryset, use_distinct
```

### get_formset Per-Role Child Restriction

Restrict inline children based on user role:

```python
@admin.register(Project)
class ProjectAdmin(admin.ModelAdmin):
    inlines = [TaskInline]
    
    def get_formset(self, request, obj=None, change=False, **kwargs):
        """Restrict visible tasks based on user role."""
        formset = super().get_formset(request, obj, change, **kwargs)
        
        original_queryset = formset.queryset
        
        def restricted_queryset(obj):
            qs = original_queryset(obj)
            
            if request.user.is_superuser:
                return qs
            
            if request.user.has_perm('myapp.view_all_tasks'):
                return qs
            
            # Regular users see only their tasks
            return qs.filter(assigned_to=request.user)
        
        formset.queryset = restricted_queryset
        return formset
```

---

## Indexing Strategy

**db_index on filter/search fields** - Critical for admin and API performance:

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

### When to Add db_index

| Field Type | Add Index When |
|------------|----------------|
| `ForeignKey` | Always (Django adds it, but verify) |
| `CharField` | Used in `list_filter`, `search_fields`, or API filters |
| `DateTimeField` | Used in date range queries or ordering |
| `IntegerField` | Used in status/type filters |

### Composite Index Guidelines

```python
class Meta:
    indexes = [
        # Leftmost prefix rule: (a, b) covers queries on (a) but not (b)
        models.Index(fields=['category', 'status']),  # Good for category+status filter
        
        # Single-field descending for common ordering
        models.Index(fields=['-created_at']),  # Good for "newest first"
        
        # Partial index (PostgreSQL) for filtered queries
        # models.Index(
        #     fields=['status'],
        #     condition=Q(status='active')
        # )
    ]
```

### Admin get_queryset Optimization

Prevent N+1 in list display:

```python
@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ['name', 'category', 'status', 'created_at', 'order_count']
    list_filter = ['status', 'category', 'created_at']  # These fields need db_index
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        # select_related for ForeignKey (1 query instead of N)
        # prefetch_related for ManyToMany/Reverse FK (2 queries instead of N+1)
        return qs.select_related('category').prefetch_related('tags')
    
    def order_count(self, obj):
        # NEVER use .count() here - it triggers a query per row!
        # Use prefetch_related with Prefetch object instead
        return obj.orders.count() if hasattr(obj, '_prefetched_objects_cache') else 'N/A'
    order_count.short_description = 'Orders'
```

---

## Per-Row .count() Antipattern

Avoid `.count()` in admin `list_display` methods - it triggers N+1 queries:

```python
# BAD - N+1 queries
@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ['name', 'post_count']
    
    def post_count(self, obj):
        return obj.posts.count()  # Query per row!
```

**Solution: Annotate once**

```python
from django.db.models import Count

class UserAdmin(admin.ModelAdmin):
    def get_queryset(self, request):
        return super().get_queryset(request).annotate(
            post_count=Count('posts')
        )
    
    list_display = ['name', 'post_count']
```

### Prefetch for Complex Aggregations

For more complex aggregations, use `Prefetch` with filtered querysets:

```python
from django.db.models import Prefetch, Count

@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ['customer', 'total_items', 'completed_items']
    
    def get_queryset(self, request):
        return super().get_queryset(request).prefetch_related(
            Prefetch(
                'orderitems',
                queryset=OrderItem.objects.annotate(
                    item_count=Count('id')
                )
            ),
            Prefetch(
                'orderitems',
                queryset=OrderItem.objects.filter(status='completed').annotate(
                    completed_count=Count('id')
                ),
                to_attr='completed_items'
            )
        )
    
    def total_items(self, obj):
        # Uses cached prefetch, no extra query
        return sum(item.quantity for item in obj.orderitems.all())
    
    def completed_items(self, obj):
        # Uses to_attr cache
        return sum(item.quantity for item in obj.completed_items)
```

### Benchmarking Admin Performance

Measure query count to catch N+1 issues:

```python
from django.test import TestCase
from django.contrib.admin import site

class AdminQueryCountTest(TestCase):
    def test_list_view_query_count(self):
        """Admin list view should not exceed N+2 queries."""
        # Create test data
        UserFactory.create_batch(10)
        
        with self.assertNumQueries(12):  # Adjust based on your admin config
            self.client.get('/admin/myapp/user/')
```

---

---

## Audit Logging with Formsets

Track changes via `save_formset` for audit trails:

```python
from django.contrib import admin
from django.utils import timezone
from myapp.models import AuditLog

@admin.register(Parent)
class ParentAdmin(admin.ModelAdmin):
    inlines = [ChildInline]
    
    def save_formset(self, request, parent, formset, save_model_kwargs):
        """Save formset and log all changes."""
        # Capture changes before saving
        changes_to_log = []
        
        for obj, changed_data in formset.changed_objects:
            changes_to_log.append({
                'object': obj,
                'field_changes': changed_data,
                'action': 'change'
            })
        
        for new_obj in formset.new_objects:
            changes_to_log.append({
                'object': new_obj[0],  # Tuple unpacking
                'field_changes': None,
                'action': 'create'
            })
        
        for deleted_obj in formset.deleted_objects:
            changes_to_log.append({
                'object': deleted_obj,
                'field_changes': None,
                'action': 'delete'
            })
        
        # Call parent save first
        super().save_formset(request, parent, formset, save_model_kwargs)
        
        # Log after successful save
        for change in changes_to_log:
            AuditLog.objects.create(
                user=request.user,
                content_type=ContentType.objects.get_for_model(change['object']),
                object_id=change['object'].id,
                action=change['action'],
                field_changes=change['field_changes'],
                timestamp=timezone.now()
            )
```

---
---

## Ecosystem Libraries

Complementary libraries that extend Django Admin functionality:

### django-admin-action-forms

**URL**: https://github.com/michalpokusa/django-admin-action-forms

Provides forms for admin actions with user input and validation. Allows creating admin actions that require intermediate input screens before execution.

**Usage pattern**:
```python
from admin_action_forms import ActionForm

class BulkUpdateForm(ActionForm):
    """Action form with intermediate input screen."""
    new_status = forms.ChoiceField(choices=STATUS_CHOICES)
    
    class Meta:
        model = MyModel
        fields = ['new_status']

# Integrates with django.contrib.admin actions
@admin.register(MyModel)
class MyModelAdmin(admin.ModelAdmin):
    actions = [bulk_update_action]
```

**Key features**:
- Action forms with Form classes for user input
- Intermediate page before action execution
- Full integration with `django.contrib.admin` actions system

### django-hijack

**URL**: https://github.com/django-hijack/django-hijack

Allows administrators to log in as other users without needing their credentials. Useful for debugging user-reported issues and understanding user experiences from their perspective.

### django-simple-history

**URL**: https://github.com/django-commons/django-simple-history

Tracks model history and allows reverting to previous versions directly from the admin. Pairs well with the manual audit logging patterns shown above, providing a drop-in solution for change tracking.

### django-easy-audit

**URL**: https://github.com/soynatan/django-easy-audit

Automatic user action tracking that monitors CRUD events, login/logout, and auth events. An alternative to manual audit logging implementation with minimal configuration required.

### django-admin-sortable2

**URL**: https://github.com/jrief/django-admin-sortable2

Adds drag-and-drop ordering support for model inlines and related objects in the admin interface. Useful for managing ordered relationships without custom JavaScript.

### django-admin-inline-paginator-plus

**URL**: https://github.com/DmytroLitvinov/django-admin-inline-paginator-plus

Adds pagination support for inline formsets in the admin. Particularly relevant when dealing with large numbers of inline objects, addressing challenges with the `save_formset` patterns discussed earlier.

## Custom Admin URLs Must Precede `super().get_urls()`

Django matches URL patterns in order. If `super().get_urls()` is called first, the default change-view pattern (`<path:object_id>/`) swallows custom paths.

```python
class CustomerAdmin(admin.ModelAdmin):
    def get_urls(self):
        urls = super().get_urls()
        my_urls = [
            path("import-csv/", self.admin_site.admin_view(self.import_csv), name="import_csv"),
        ]
        return my_urls + urls  # custom URLs FIRST
```

## Admin Action POST Payload

When invoking a custom action via POST (e.g., from JavaScript or `django-webtest`), the payload must include:

| Field | Value |
|-------|-------|
| `action` | the action method name (e.g., `"block_customers"`) |
| `_selected_action` | list of selected object IDs |
| `post` | `"yes"` (or `"on"`) to confirm |

Swapping `action` and `_selected_action` prevents the action from running and can break session persistence.

---

## References
- Main Django security patterns: [frameworks/django/SKILL.md](../django/SKILL.md)
- Django Admin documentation: https://docs.djangoproject.com/en/stable/ref/contrib/admin/
- Django ORM optimization: https://docs.djangoproject.com/en/stable/topics/db/optimization/