# Ecosystem Libraries and Coverage

> Loaded on demand from ../SKILL.md — contains Ecosystem Libraries and Coverage sections.

## Ecosystem Libraries

### model-bakery

Lightweight object factory for Django, simpler alternative to factory_boy.

https://github.com/model-bakers/model_bakery

```python
from model_bakery import baker

# Create single instance
user = baker.make("auth.User", username="test")

# Create multiple instances
users = baker.make("auth.User", _quantity=5)

# With relationships
order = baker.make("store.Order", user=baker.make("auth.User"))
```

Smart recipe pattern for reusable test fixtures:

```python
from model_bakery import baker

# Pre-define recipe
user_recipe = baker.recipe("auth.User", is_staff=True)

# Use recipe
staff_user = baker.make(user_recipe)
```

### django-test-migrations

Test schema and data migrations including migration order verification.

https://github.com/wemake-services/django-test-migrations

```python
from django_test_migrations.contrib.unittest_checks import TestCaseWithMigrationsChecks

class TestMigrations(TestCaseWithMigrationsChecks):
    def test_migration_order(self):
        # Verify migrations run in correct order
        self.assertNoConflictingMigrations()
    
    def test_migration_data(self):
        # Test data migrations
        self.assertForwardPathThenBackwardPath()
```

### django-test-plus

Useful TestCase additions (assertLoginRequired, simplified request handling).

https://github.com/revsys/django-test-plus

```python
from test_plus.test import TestCase

class MyTest(TestCase):
    def test_login_required(self):
        self.assertLoginRequired("/protected/")
    
    def test_view(self):
        # Built-in request factory
        self.get("/view/")
        self.post("/view/", {"key": "value"})
```

## Coverage

### Coverage Configuration

```bash
# Run tests with coverage
pytest --cov=apps --cov-report=html --cov-report=term-missing

# Generate HTML report
open htmlcov/index.html
```

### Coverage Goals

| Component | Target Coverage |
|-----------|-----------------|
| Models | 90%+ |
| Serializers | 85%+ |
| Views | 80%+ |
| Services | 90%+ |
| Utilities | 80%+ |
| Overall | 80%+ |