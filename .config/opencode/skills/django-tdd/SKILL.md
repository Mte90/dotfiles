---
name: django-tdd
description: Use when testing Django applications with pytest - TDD workflow, pytest-django setup, factory_boy and model-bakery fixtures, DRF API testing, mocking and patching, integration tests, or coverage
metadata:
  author: mte90
  version: 2.0.0
  tags:
    - python
    - django
    - testing
    - pytest
    - tdd
---

# Django Testing with TDD

Test-driven development for Django applications using pytest, factory_boy, and Django REST Framework.

## When to Activate

- Writing new Django applications
- Implementing Django REST Framework APIs
- Testing Django models, views, and serializers
- Setting up testing infrastructure for Django projects

## TDD Workflow for Django

### Red-Green-Refactor Cycle

```python
# Step 1: RED - Write failing test
def test_user_creation():
    user = User.objects.create_user(email='test@example.com', password='testpass123')
    assert user.email == 'test@example.com'
    assert user.check_password('testpass123')
    assert not user.is_staff

# Step 2: GREEN - Make test pass
# Create User model or factory

# Step 3: REFACTOR - Improve while keeping tests green
```

## Setup

### pytest Configuration

```ini
# pytest.ini
[pytest]
DJANGO_SETTINGS_MODULE = config.settings.test
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts =
    --reuse-db
    --nomigrations
    --cov=apps
    --cov-report=html
    --cov-report=term-missing
    --strict-markers
markers =
    slow: marks tests as slow
    integration: marks tests as integration tests
```

### Test Settings

```python
# config/settings/test.py
from .base import *

DEBUG = True
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': ':memory:',
    }
}

# Disable migrations for speed
class DisableMigrations:
    def __contains__(self, item):
        return True

    def __getitem__(self, item):
        return None

MIGRATION_MODULES = DisableMigrations()

# Faster password hashing
PASSWORD_HASHERS = [
    'django.contrib.auth.hashers.MD5PasswordHasher',
]

# Email backend
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'

# Celery always eager
CELERY_TASK_ALWAYS_EAGER = True
CELERY_TASK_EAGER_PROPAGATES = True
```

### conftest.py

```python
# tests/conftest.py
import pytest
from django.utils import timezone
from django.contrib.auth import get_user_model

User = get_user_model()

@pytest.fixture(autouse=True)
def timezone_settings(settings):
    """Ensure consistent timezone."""
    settings.TIME_ZONE = 'UTC'

@pytest.fixture
def user(db):
    """Create a test user."""
    return User.objects.create_user(
        email='test@example.com',
        password='testpass123',
        username='testuser'
    )

@pytest.fixture
def admin_user(db):
    """Create an admin user."""
    return User.objects.create_superuser(
        email='admin@example.com',
        password='adminpass123',
        username='admin'
    )

@pytest.fixture
def authenticated_client(client, user):
    """Return authenticated client."""
    client.force_login(user)
    return client

@pytest.fixture
def api_client():
    """Return DRF API client."""
    from rest_framework.test import APIClient
    return APIClient()

@pytest.fixture
def authenticated_api_client(api_client, user):
    """Return authenticated API client."""
    api_client.force_authenticate(user=user)
    return api_client
```

## Factory Boy Patterns

### Core Patterns with Failure Modes

**Lazy attributes** — computed values that depend on other fields:

```python
slug = factory.LazyAttribute(lambda obj: obj.name.lower().replace(' ', '-'))
```
*Failure:* `LazyAttribute` runs at object creation — if the model's `save()` overrides it, the factory value is silently lost.

**Sequence for unique values**:

```python
email = factory.Sequence(lambda n: f"user{n}@example.com")
```
*Failure:* Sequence state persists across test runs; parallel tests collide on unique constraints.

**SubFactory for relationships**:

```python
category = factory.SubFactory(CategoryFactory)
```
*Failure:* Nested SubFactory creates database hits; tests slow down exponentially with depth.

**django_get_or_create for M2M through models**:

```python
tags = factory.RelatedFactoryList(TagFactory, 'product_tags', _quantity=3)
```
*Failure:* `get_or_create` hides uniqueness violations — the test passes even when the real code would fail on duplicate keys.

**post_generation for M2M relationships**:

```python
@factory.post_generation
def tags(self, create, extracted, **kwargs):
    if not create:
        return
    if extracted:
        for tag in extracted:
            self.tags.add(tag)
```
*Failure:* If `post_generation` is missing or returns early, M2M rows are absent and the test passes for the wrong reason.

**Meta.freeze for immutable models**:

```python
class Meta:
    model = Invoice
    exclude = ('created_at',)

@classmethod
def _generate(cls, create_class, _build, *args, **kwargs):
    obj = super()._generate(create_class, _build, *args, **kwargs)
    obj.created_at = timezone.now()  # Set after save
    return obj
```
*Failure:* A non-frozen factory lets one test's mutation leak into another — `created_at` changes mid-test and assertions fail intermittently.

### Minimal Factory Example

```python
# tests/factories.py
import factory
from factory import fuzzy
from django.contrib.auth import get_user_model

User = get_user_model()

class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = User

    email = factory.Sequence(lambda n: f"user{n}@example.com")
    username = factory.Sequence(lambda n: f"user{n}")
    password = factory.PostGenerationMethodCall('set_password', 'testpass123')

class ProductFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Product

    name = factory.Faker('sentence', nb_words=3)
    price = fuzzy.FuzzyDecimal(10.00, 1000.00, 2)
    category = factory.SubFactory(CategoryFactory)

    @factory.post_generation
    def tags(self, create, extracted, **kwargs):
        if not create or not extracted:
            return
        for tag in extracted:
            self.tags.add(tag)
```

### Using Factories

```python
# tests/test_models.py
import pytest
from tests.factories import ProductFactory, UserFactory

def test_product_creation():
    product = ProductFactory(price=100.00, stock=50)
    assert product.price == 100.00
    assert product.stock == 50

def test_multiple_products():
    products = ProductFactory.create_batch(10)
    assert len(products) == 10
```

## Transaction and Isolation Testing

### pytest.mark.django_db vs transaction=True

`@pytest.mark.django_db` wraps each test in a transaction and rolls back at the end. Fast, but:

- **Failure mode:** `TransactionManagementError` when code explicitly commits or uses `transaction.atomic()` incorrectly
- **Failure mode:** Data persists across tests if the transaction doesn't roll back (e.g., unhandled exception before rollback)

`transaction=True` disables transaction wrapping and uses real transactions:

```python
@pytest.mark.django_db(transaction=True)
def test_real_transaction():
    # Actual commit/rollback behavior
    pass
```

- **Failure mode:** Missing data across tests — each test truncates tables, so fixtures from other tests are gone
- **Cost:** ~10x slower due to table truncation between tests

**When to use `transaction=True`:**
- Testing code that relies on `transaction.on_commit()` callbacks
- Testing concurrent database access (multiple threads/processes)
- Testing migration data that must survive a real commit

**When to stick with default:**
- Most unit tests — speed matters
- Tests that only read/write within a single test function

## Testing Pitfalls

### Mocking Pitfalls

**Patching `request.user` on the class instead of instance**

```python
# WRONG — patches the attribute on the class, leaks across tests
@patch('django.contrib.auth.models.User')
def test_view(mock_user):
    ...

# RIGHT — patch on the instance or use client.force_login
def test_view(client, user):
    client.force_login(user)
    ...
```
*Failure:* User state from one test appears in another; authentication checks pass for the wrong user.

**Patching a manager method vs the queryset**

```python
# Model.objects.filter returns a QuerySet that must be evaluated
# WRONG — patching the method but not evaluating
@patch('apps.models.Product.objects.filter')
def test_list_products(mock_filter):
    mock_filter.return_value = [ProductFactory()]  # Returns list, not evaluated QuerySet
    ...

# RIGHT — patch at the point of evaluation or use MagicMock
@patch('apps.models.Product.objects.filter')
def test_list_products(mock_filter):
    mock_filter.return_value = MagicMock(__iter__=Mock(return_value=iter([ProductFactory()])))
    ...
```
*Failure:* QuerySet evaluation returns empty; test passes with no data when real code would return results.

**Patching a decorated view**

```python
# WRONG — decorator wraps the function; patch target is wrapper's module attribute
@patch('apps.views.my_view')
def test_view(mock_view):
    ...

# RIGHT — patch the module-level attribute after decoration
@patch('apps.views.my_view')  # Target the decorated wrapper, not the undecorated name
def test_view(mock_view):
    ...
```
*Failure:* Patch doesn't apply; the real view runs and hits the database.

**Using `override_settings` instead of `mock.patch` for settings evaluated at import time**

```python
# WRONG — settings evaluated at import time, override_settings does nothing
from myapp import CONSTANT  # CONSTANT computed from settings at import

@override_settings(MY_SETTING='new_value')
def test_something():
    assert CONSTANT == 'expected'  # Still old value

# RIGHT — mock the module-level constant or restructure to lazy evaluation
@patch('myapp.CONSTANT', 'new_value')
def test_something(mock_constant):
    ...
```
*Failure:* Settings patch has no effect; test passes with wrong configuration.

**Mocking a third-party HTTP client with un-asserted mock**

```python
# WRONG — mock returns None or empty dict by default
@patch('requests.get')
def test_external_api(mock_get):
    response = make_api_call()  # Uses requests.get internally
    assert response.status == 200  # Fails if mock_get.return_value is None

# RIGHT — configure mock to return realistic response shape
mock_get.return_value = Mock(status_code=200, json=lambda: {'data': 'value'})
```
*Failure:* Mock hides the real response shape; test passes but integration fails with actual API.

### Common Anti-Patterns

**Assert on response status only**

```python
# WRONG — 200 with wrong content passes
response = client.get('/api/items/')
assert response.status_code == 200

# RIGHT — assert on content structure
assert response.status_code == 200
assert response.data['count'] == 10
assert 'results' in response.data
```
*Failure:* Endpoint returns 200 with empty or malformed data; test passes, production breaks.

**`assertTrue(form.is_valid())` without asserting `form.errors`**

```python
# WRONG — form fails for wrong reason, test still passes
assert form.is_valid()

# RIGHT — assert specific errors
assert not form.is_valid()
assert 'email' in form.errors
assert 'Invalid email format' in form.errors['email'][0]
```
*Failure:* Form validates when it shouldn't, or fails for unexpected reasons; test gives false confidence.

**`TestCase` wrapping a test that needs real transactions**

```python
# WRONG — TestCase wraps everything in transaction; real commit behavior hidden
class TestPayment(TestCase):
    def test_payment_commit(self):
        # Code uses transaction.on_commit() — never fires in TestCase
        ...

# RIGHT — use TransactionTestCase or pytest-django with transaction=True
@pytest.mark.django_db(transaction=True)
def test_payment_commit():
    ...
```
*Failure:* Test passes but `on_commit()` callbacks never execute in production; side effects (emails, webhooks) are lost.

**Mocking what you should build**

```python
# WRONG — mock your own models
@patch('apps.models.Order')
def test_checkout(mock_order):
    ...

# RIGHT — use factories for your own models
def test_checkout():
    order = OrderFactory()
    ...
```
*Failure:* Mock doesn't reflect model behavior (validations, managers, relationships); test diverges from reality.

### Django-Specific Gotchas

**Mocking `connections` imported at module scope**

If the code under test does `from django.db import connections` at the top, patch `module_under_test.connections`, not `django.db.connections`. The module bound its own reference at import time.

**`patch.object` cannot mock dunders on instances**

`patch.object(connections, "__getitem__", ...)` silently fails. Mock at class level (`patch.object(type(connections), "__getitem__", ...)`) or substitute a wrapper object.

**Always use timezone-aware datetimes**

Naive datetimes trigger `RuntimeWarning` and fail with `filterwarnings = ["error"]`. Use `django.utils.timezone.now()` or `timezone.make_aware()`.

**`auto_now_add` in tests**

`DateTimeField(auto_now_add=True)` ignores values passed to constructor. Set value after `save()`:

```python
invoice = Invoice(customer=c)
invoice.save()
invoice.issued_at = some_time
invoice.save()
```

## Quick Reference

| Pattern | Usage |
|---------|-------|
| `@pytest.mark.django_db` | Enable database access |
| `client` | Django test client |
| `api_client` | DRF API client |
| `factory.create_batch(n)` | Create multiple objects |
| `patch('module.function')` | Mock external dependencies |
| `override_settings` | Temporarily change settings |
| `force_authenticate()` | Bypass authentication in tests |
| `assertRedirects` | Check for redirects |
| `assertTemplateUsed` | Verify template usage |
| `mail.outbox` | Check sent emails |

## Deep Dives

Load these reference files for detailed coverage of specific testing areas:

- **Model & View Testing** — `references/model-view-testing.md` — Model tests, view tests, authentication checks
- **DRF API Testing** — `references/drf-api-testing.md` — Serializer tests, ViewSet tests, API endpoints
- **Mocking & Integration** — `references/mocking-integration.md` — External service mocking, email testing, full flow tests
- **Ecosystem & Coverage** — `references/ecosystem-coverage.md` — model-bakery, django-test-migrations, django-test-plus, coverage goals
