<!-- This file is loaded on demand from frameworks/django/SKILL.md -->

## Testing Optimization

### HTMX Error Branch Coverage

Test HTMX-specific error paths that regular tests miss:

```python
from django.test import Client

def test_htmx_form_validation_error(client):
    """HTMX requests need different error handling."""
    response = client.post(
        '/partial-form/',
        {'field': 'invalid'},
        HTTP_HX_REQUEST='true',  # HTMX header
    )
    # HTMX returns partial HTML, not redirect
    assert response.status_code == 200
    assert b'error-message' in response.content
    # No full page redirect for HTMX requests


def test_htmx_identity_fields_untrusted(client):
    """Never trust POSTed identity fields with HTMX."""
    # User logged in as user_id=5
    client.force_login(User.objects.get(id=5))
    
    # Malicious HTMX form tries to change user_id
    response = client.post(
        '/update-profile/',
        {'user_id': 999, 'name': 'Hacker'},  # user_id in POST!
        HTTP_HX_REQUEST='true',
    )
    # Should ignore user_id from POST, use request.user
    assert User.objects.get(id=5).name == 'Hacker'
    assert User.objects.get(id=999).name != 'Hacker'
```

### Formset Tests with Real Tuple Shape

Django admin formsets return specific tuple shapes - test with real data:

```python
from django.contrib import admin
from django.test import TestCase
from myapp.models import Parent, Child

class ParentAdminTest(TestCase):
    def setUp(self):
        self.parent = Parent.objects.create(name='Parent')
        self.child1 = Child.objects.create(parent=self.parent, name='Child 1')
        self.child2 = Child.objects.create(parent=self.parent, name='Child 2')
    
    def test_save_formset_tuple_shape(self):
        """save_formset receives [(obj, changed_data)] not bare lists."""
        admin_instance = admin.site._registry[Parent]
        
        # Mock POST with changed child
        data = {
            'child_set-0-id': self.child1.id,
            'child_set-0-name': 'Updated Child 1',  # Changed
            'child_set-1-id': self.child2.id,
            'child_set-1-name': 'Child 2',  # Unchanged
            'child_set-TOTAL_FORMS': 2,
            'child_set-INITIAL_FORMS': 2,
        }
        
        # Track what save_formset receives
        changed_objects = []
        
        def mock_save_formset(parent, formset, **kwargs):
            # Shape: [(instance, {field: old_value}), ...]
            changed_objects.extend(formset.changed_objects)
        
        # Patch and submit
        original_save = admin_instance.save_formset
        admin_instance.save_formset = mock_save_formset
        
        try:
            self.client.post('/admin/myapp/parent/{}/change/'.format(self.parent.id), data)
        finally:
            admin_instance.save_formset = original_save
        
        # Verify shape
        assert len(changed_objects) == 1
        obj, changed_data = changed_objects[0]
        assert obj.id == self.child1.id
        assert 'name' in changed_data
        assert changed_data['name'] == 'Updated Child 1'
```

### Coverage-Audit Cross-Reference

Verify test coverage matches actual code paths:

```bash
# Run coverage and check branches
pytest --cov=myapp --cov-report=html

# Check specific error branches
pytest -k "test_htmx" --cov=myapp.views --cov-report=term-missing

# Cross-reference with TODOs
grep -r "TODO\|FIXME" myapp/ | grep -v test
```

### Fast Password Hashing for Tests

```python
# settings.py
PASSWORD_HASHERS = [
    'django.contrib.auth.hashers.MD5PasswordHasher',  # 70% faster
]
```

### Parallel Testing

```bash
python manage.py test --parallel
```

### Capture on_commit Callbacks in Tests

```python
from django.test import TestCase

class ContactTests(TestCase):
    def test_post(self):
        with self.captureOnCommitCallbacks(execute=True) as callbacks:
            response = self.client.post("/contact/", {"message": "Test"})
        
        self.assertEqual(len(callbacks), 1)  # Verify callback was enqueued
```

### In-Memory SQLite for Tests

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': 'file::memory:',
    }
}
```

### Assert Query Count

```python
def test_something(self):
    with self.assertNumQueries(5):
        process_data()
```

---


---

## Migrations

### Post-Rename Dead-Reference Audit Checklist

After renaming fields, audit for dead references:

```bash
# 1. Search for old field name in code
grep -r "old_field_name" --include="*.py" . | grep -v migration | grep -v __pycache__

# 2. Search in templates
grep -r "old_field_name" --include="*.html" .

# 3. Search in admin configurations
grep -r "list_display.*old_field_name" --include="*.py" .

# 4. Search in forms
grep -r "fields.*=.*\['old_field_name'" --include="*.py" .

# 5. Search in serializers
grep -r "old_field_name" --include="*.py" serializers.py

# 6. Check for hardcoded field names in queries
grep -r "filter.*old_field_name" --include="*.py" .
```

**Checklist**:
- [ ] Models.py - field references
- [ ] Admin.py - list_display, list_filter, search_fields
- [ ] Forms.py - field definitions
- [ ] Serializers.py - field serialization
- [ ] Templates.py - template variable references
- [ ] Views.py - query filters, order_by
- [ ] Tests.py - test data assertions
- [ ] API documentation - Swagger/OpenAPI specs
- [ ] External integrations - webhooks, API consumers

### Add Unique Constraints Before Relying on Upserts

Ensure upserts work correctly with unique constraints:

```python
from django.db import migrations, models

class Migration(migrations.Migration):
    
    dependencies = [
        ('myapp', '0001_initial'),
    ]
    
    operations = [
        # 1. Add unique constraint FIRST
        migrations.AddConstraint(
            model_name='externalresource',
            constraint=models.UniqueConstraint(
                fields=['external_id'],
                name='unique_external_id'
            ),
        ),
        
        # 2. Then data migration to dedupe
        migrations.RunPython(
            deduplicate_external_resources,
            reverse_code=migrations.RunPython.noop
        ),
        
        # 3. Now update_or_create will work reliably
        # (no code change needed - just ensure this migration runs first)
    ]

def deduplicate_external_resources(apps, schema_editor):
    ExternalResource = apps.get_model('myapp', 'ExternalResource')
    
    # Group by external_id
    from django.db.models import Count
    duplicates = ExternalResource.objects.values(
        'external_id'
    ).annotate(count=Count('id')).filter(count__gt=1)
    
    for dup in duplicates:
        # Keep oldest, delete rest
        ids = list(ExternalResource.objects.filter(
            external_id=dup['external_id']
        ).order_by('-created_at').values_list('id', flat=True)[1:])
        
        ExternalResource.objects.filter(id__in=ids).delete()
```

### Squashing Migrations

```bash
# Squash migrations 0002 to 0006
python manage.py squashmigrations app 0002 0006
```

Then update dependencies in other migrations:
```python
class Migration(migrations.Migration):
    dependencies = [
        ('app', '0007_squashed_0006'),  # Update to squashed migration
    ]
```

### Standalone Django ORM (inspectdb)

Query existing databases without a full project:

```python
# settings.py
import os
from django.conf import settings

settings.configure(
    DATABASES={"default": {"ENGINE": "django.db.backends.sqlite3", "NAME": "db.sqlite"}},
    INSTALLED_APPS=["myapp"],
)

# Generate models
# python manage.py inspectdb > models.py
```

**Critical Model Attribute:**
```python
class Place(models.Model):
    url = models.URLField()
    title = models.CharField(null=True)
    
    class Meta:
        managed = False  # Don't try to create/migrate
        db_table = "moz_places"  # Existing table name
```

---

---


---

## Django Signals Best Practices

### Defining and Using Signals

```python
# Define custom signals
from django.dispatch import Signal
user_logged_in = Signal(providing_args=['user', 'request'])

# Connect receivers with decorator
from django.dispatch import receiver
from django.contrib.auth.signals import user_logged_in

@receiver(user_logged_in)
def log_user_login(sender, user, request, **kwargs):
    ActivityLog.objects.create(
        user=user,
        event_type=ActivityLog.LOGIN,
        context={'ip': request.META.get('REMOTE_ADDR')}
    )

# Register in AppConfig.ready() to avoid circular imports
class MyAppConfig(AppConfig):
    def ready(self):
        import myapp.signals
```

### Common Pitfalls to Avoid

- **Heavy computations** in signal handlers → Use Celery for async tasks
- **Circular imports** → Use string references: `sender="myapp.MyModel"`
- **Duplicate connections** → Use `dispatch_uid` parameter
- **Not registering signals** → Register in `AppConfig.ready()`

---


---

## StreamingHttpResponse

For large responses, stream instead of loading entirely:

```python
# Basic streaming response
def generate_csv():
    yield "Header1,Header2,Header3\n"
    yield "Value1,Value2,Value3\n"

def download_large_file(request):
    return StreamingHttpResponse(
        generate_csv(),
        content_type='text/csv'
    )

# For file downloads
from django.utils.filewrapper import FileWrapper

def download_file(request):
    file_like = open('large.csv', 'rb')
    return StreamingHttpResponse(
        FileWrapper(file_like),
        content_type='text/csv'
    )
```

**Benefits:**
- Lower memory usage (don't load entire file)
- Faster time-to-first-byte (TTFB)
- Better for large files (CSV, PDFs, exports)

---


