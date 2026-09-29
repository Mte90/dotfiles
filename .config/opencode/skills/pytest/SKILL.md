---
name: pytest
description: Use when writing Python tests with pytest - fixtures, parametrization, markers, conftest layout, pytest-asyncio, pytest-django, coverage with pytest-cov, mocking with pytest-mock, parallel runs with xdist, or CI integration
metadata:
  author: mte90
  version: 3.0.0
  tags:
    - python
    - testing
    - tdd
    - fixtures
    - unit-test
---

# pytest

Complete reference for Python testing with pytest.

## Overview

pytest is a mature, full-featured Python testing framework that makes it easy to write simple and scalable tests.

**Key Features:**
- Simple: Write tests with plain assert statements
- Powerful: Fixtures for setup/teardown
- Parametrized: Run same test with different inputs
- Plugins: Rich ecosystem of plugins
- Parallel: Run tests in parallel with pytest-xdist
- Detailed: Informative failure messages

### Installation

```bash
pip install pytest>=9.0
pip install pytest-cov>=5.0      # Coverage
pip install pytest-mock     # Mocking
pip install pytest-asyncio>=0.25 # Async tests
pip install pytest-django>=4.8   # Django testing
pip install pytest-xdist    # Parallel execution
```

### Python Version Requirements

pytest 9.0 requires **Python 3.10+**. Python 3.9 is no longer supported.

### Breaking Changes in pytest 9.0

**Errors from previously deprecated behavior:**
- `py.path.local` usage in hooks → Use `pathlib.Path` instead
- Mixing async + sync fixtures → Now raises errors
- `@pytest.mark.usefixtures` on fixture functions → Now errors
- `pytest.importorskip` with `__import__` → Removed

**CI Mode:** pytest enforces stricter configuration validation in CI environments.

## Test Discovery

### Naming Conventions

```python
# Files must match pattern
test_*.py
*_test.py

# Classes must start with Test
class TestClass:
    def test_method(self):
        pass

# Functions must start with test_
def test_function():
    pass
```

```ini
# pytest.ini - Custom discovery patterns
[pytest]
python_files = test_*.py check_*.py
python_classes = Test* Check*
python_functions = test_* check_*
```

## Fixtures

### Basic Fixtures

```python
# conftest.py or test file
import pytest

@pytest.fixture
def sample_data():
    """Provide sample data for tests."""
    return {"name": "test", "value": 42}

def test_with_fixture(sample_data):
    assert sample_data["name"] == "test"
    assert sample_data["value"] == 42
```

### Fixture Scopes

```python
@pytest.fixture(scope="function")
def function_fixture():
    """Created for each test (default)."""
    print("Setup: function scope")
    yield {"data": "function"}
    print("Teardown: function scope")

@pytest.fixture(scope="class")
def class_fixture():
    """Created once per test class."""
    print("Setup: class scope")
    yield {"data": "class"}
    print("Teardown: class scope")

@pytest.fixture(scope="module")
def module_fixture():
    """Created once per module."""
    print("Setup: module scope")
    yield {"data": "module"}
    print("Teardown: module scope")

@pytest.fixture(scope="package")
def package_fixture():
    """Created once per package."""
    print("Setup: package scope")
    yield {"data": "package"}
    print("Teardown: package scope")

@pytest.fixture(scope="session")
def session_fixture():
    """Created once per test session."""
    print("Setup: session scope")
    yield {"data": "session"}
    print("Teardown: session scope")
```

### Yield Fixtures (Setup/Teardown)

```python
@pytest.fixture
def database():
    """Setup and teardown database."""
    db = Database(':memory:')
    db.create_tables()
    yield db
    db.close()

@pytest.fixture
def temp_file():
    """Create temporary file for testing."""
    import tempfile
    import os
    
    fd, path = tempfile.mkstemp()
    os.close(fd)
    
    yield path
    
    # Cleanup
    if os.path.exists(path):
        os.unlink(path)

def test_database(database):
    database.insert({"name": "test"})
    assert database.count() == 1
```

### autouse Fixtures

```python
@pytest.fixture(autouse=True)
def setup_test_environment():
    """Automatically run for every test."""
    os.environ['TESTING'] = 'true'
    yield
    del os.environ['TESTING']
```

### Fixture Factories

```python
@pytest.fixture
def make_user():
    """Factory fixture for creating users."""
    created_users = []
    
    def _make_user(name, email, **kwargs):
        user = User.objects.create_user(
            username=name,
            email=email,
            **kwargs
        )
        created_users.append(user)
        return user
    
    yield _make_user
    
    # Cleanup all created users
    for user in created_users:
        user.delete()

def test_user_creation(make_user):
    user1 = make_user("user1", "user1@example.com")
    user2 = make_user("user2", "user2@example.com", is_staff=True)
    
    assert user1.username == "user1"
    assert user2.is_staff is True
```

### conftest.py

```python
# conftest.py - Shared fixtures for all tests in directory

import pytest
from myapp import create_app, db

@pytest.fixture(scope="session")
def app():
    """Create application for testing."""
    app = create_app(config="testing")
    yield app

@pytest.fixture(scope="function")
def client(app):
    """Create test client."""
    return app.test_client()

@pytest.fixture(scope="function")
def db_session(app):
    """Create database session."""
    with app.app_context():
        db.create_all()
        yield db
        db.session.remove()
        db.drop_all()
```

## Parametrization

### Basic Parametrization

```python
import pytest

@pytest.mark.parametrize("input,expected", [
    (1, 2),
    (2, 4),
    (3, 6),
    (10, 20),
])
def test_double(input, expected):
    assert input * 2 == expected

@pytest.mark.parametrize("value", [
    1,
    1.5,
    "string",
    [1, 2, 3],
    {"key": "value"},
])
def test_json_serializable(value):
    import json
    assert json.dumps(value) is not None
```

### Multiple Parameters

```python
@pytest.mark.parametrize("x,y,expected", [
    (1, 2, 3),
    (5, 5, 10),
    (0, 0, 0),
    (-1, 1, 0),
])
def test_add(x, y, expected):
    assert x + y == expected
```

### Parametrize with IDs

```python
@pytest.mark.parametrize("input,expected", [
    ("hello", "HELLO"),
    ("WORLD", "WORLD"),
    ("MixEd", "MIXED"),
], ids=["lowercase", "uppercase", "mixed"])
def test_uppercase(input, expected):
    assert input.upper() == expected

# Custom ID function
def idfn(val):
    if isinstance(val, str):
        return f"str_{val[:5]}"
    return str(val)

@pytest.mark.parametrize("value", ["hello", "world", "test"], ids=idfn)
def test_with_custom_ids(value):
    assert len(value) > 0
```

### Parametrize with Fixtures

```python
@pytest.fixture(params=[
    ("admin", True),
    ("user", False),
    ("guest", False),
])
def user_with_role(request):
    role, is_admin = request.param
    return {"role": role, "is_admin": is_admin}

def test_user_role(user_with_role):
    role = user_with_role["role"]
    is_admin = user_with_role["is_admin"]
    
    if role == "admin":
        assert is_admin is True
    else:
        assert is_admin is False
```

### Indirect Parametrization

```python
@pytest.fixture
def user(request):
    """Create user based on parameter."""
    role = request.param
    return User.objects.create_user(username=f"test_{role}", role=role)

@pytest.mark.parametrize("user", ["admin", "user", "guest"], indirect=True)
def test_user_access(user):
    """Test access based on user role."""
    if user.role == "admin":
        assert user.can_access_admin()
    else:
        assert not user.can_access_admin()
```

## Markers

### Built-in Markers

```python
import pytest

# Skip test
@pytest.mark.skip(reason="Not implemented yet")
def test_future_feature():
    pass

# Skip conditionally
@pytest.mark.skipif(sys.version_info < (3, 10), reason="Requires Python 3.10+")
def test_python_310_feature():
    pass

# Expected to fail
@pytest.mark.xfail(reason="Known bug #123")
def test_known_bug():
    assert 1 == 2

# Expected to fail conditionally
@pytest.mark.xfail(condition=sys.platform == "win32", reason="Windows issue")
def test_platform_specific():
    pass

# Expected failure but run anyway
@pytest.mark.xfail(strict=False)
def test_might_pass():
    pass
```

### Custom Markers

```python
# Register marker in pytest.ini
[pytest]
markers =
    slow: marks tests as slow (deselect with '-m "not slow"')
    integration: marks tests as integration tests
    unit: marks tests as unit tests
    requires_db: marks tests that need database

# Use custom markers
@pytest.mark.slow
def test_slow_operation():
    time.sleep(10)
    assert True

@pytest.mark.integration
def test_external_api():
    response = requests.get("https://api.example.com")
    assert response.status_code == 200

# Multiple markers
@pytest.mark.slow
@pytest.mark.integration
def test_slow_integration():
    pass

# Run tests with markers
# pytest -m slow          # Run only slow tests
# pytest -m "not slow"    # Skip slow tests
# pytest -m "slow and integration"
```

## Configuration

### pytest.ini

```ini
[pytest]
# Test discovery
python_files = test_*.py *_test.py
python_classes = Test*
python_functions = test_*

# Command line options
addopts = -v --tb=short --cov=myapp

# Markers
markers =
    slow: slow tests
    integration: integration tests
    unit: unit tests

# Minimum pytest version
minversion = 9.0

# Required plugins
required_plugins = pytest-cov>=5.0 pytest-mock pytest-asyncio>=0.25 pytest-django>=4.8

# Logging
log_cli = true
log_cli_level = INFO

# Timeout
timeout = 300
timeout_method = thread

# Coverage
testpaths = tests
```

### pyproject.toml

```toml
[tool.pytest.ini_options]
python_files = ["test_*.py", "*_test.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = "-v --tb=short"
testpaths = ["tests"]
markers = [
    "slow: marks tests as slow",
    "integration: marks tests as integration tests",
]
```

### conftest.py Structure

```python
# tests/conftest.py - Root conftest
import pytest

# Command line options
def pytest_addoption(parser):
    parser.addoption(
        "--run-slow",
        action="store_true",
        default=False,
        help="run slow tests"
    )

# Skip slow tests by default
def pytest_collection_modifyitems(config, items):
    if config.getoption("--run-slow"):
        return
    
    skip_slow = pytest.mark.skip(reason="need --run-slow option")
    for item in items:
        if "slow" in item.keywords:
            item.add_marker(skip_slow)

# Custom fixtures available to all tests
@pytest.fixture(scope="session")
def test_config():
    return {"debug": True}
```

## Deep Dives

For detailed coverage of these topics, load the corresponding reference files:

- **Async Testing & Django** — `references/plugins-async-django.md`: pytest-asyncio, pytest-django, async Django patterns, sync_to_async bridge, common pitfalls
- **Tooling Plugins** — `references/plugins-tooling.md`: pytest-cov (coverage), pytest-mock (mocking), pytest-xdist (parallel), pytest-timeout, pytest-env, pytest-randomly, pytest-sugar, pytest-clarity, pytest-benchmark
- **Mocking & CI** — `references/mocking-ci.md`: unittest.mock patterns, monkeypatch, GitHub Actions, GitLab CI, pdb debugging

## Best Practices

### 1. Test Organization

```
tests/
├── conftest.py           # Shared fixtures
├── unit/                 # Unit tests
│   ├── __init__.py
│   ├── test_models.py
│   └── test_utils.py
├── integration/          # Integration tests
│   ├── __init__.py
│   └── test_api.py
├── e2e/                  # End-to-end tests
│   ├── __init__.py
│   └── test_flows.py
└── fixtures/             # Test data
    └── data.json
```

### 2. Clear Test Names

```python
# Bad
def test_user():
    pass

# Good
def test_create_user_with_valid_data_succeeds():
    pass

def test_create_user_with_duplicate_email_raises_error():
    pass

def test_user_cannot_delete_own_account():
    pass
```

### 3. AAA Pattern

```python
def test_user_creation():
    # Arrange
    user_data = {
        "username": "testuser",
        "email": "test@example.com",
        "password": "password123"
    }
    
    # Act
    user = User.create(**user_data)
    
    # Assert
    assert user.username == "testuser"
    assert user.email == "test@example.com"
    assert user.check_password("password123")
```

### 4. One Assertion Per Test (When Possible)

```python
# Bad
def test_user():
    user = create_user()
    assert user.username == "test"
    assert user.email == "test@example.com"
    assert user.is_active is True

# Good
def test_user_has_correct_username():
    user = create_user()
    assert user.username == "test"

def test_user_has_correct_email():
    user = create_user()
    assert user.email == "test@example.com"

def test_user_is_active_by_default():
    user = create_user()
    assert user.is_active is True
```

## References

- **Official Documentation**: https://docs.pytest.org/
- **GitHub Repository**: https://github.com/pytest-dev/pytest
- **pytest Plugins**: https://docs.pytest.org/en/latest/reference/plugin_list.html
- **Book**: "Python Testing with pytest" by Brian Okken