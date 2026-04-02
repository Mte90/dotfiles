---
name: pytest
description: "Python testing framework with powerful fixtures, parametrization, extensive plugin ecosystem, and support for async, Django, Flask testing"
metadata:
  author: "OSS AI Skills"
  version: "1.0.0"
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
pip install pytest
pip install pytest-cov      # Coverage
pip install pytest-mock     # Mocking
pip install pytest-asyncio  # Async tests
pip install pytest-django   # Django testing
pip install pytest-xdist    # Parallel execution
```

### Basic Test

```python
# test_example.py
def test_addition():
    assert 1 + 1 == 2

def test_string_concat():
    assert "hello" + " " + "world" == "hello world"

def test_list_length():
    items = [1, 2, 3]
    assert len(items) == 3
```

```bash
# Run tests
pytest

# Verbose output
pytest -v

# Specific test file
pytest test_example.py

# Specific test function
pytest test_example.py::test_addition

# Run with pattern
pytest -k "addition"
```

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

### Custom Discovery

```python
# conftest.py
import pytest

def pytest_collect_file(parent, file_path):
    """Custom file collection."""
    if file_path.suffix == ".py" and file_path.name.startswith("check_"):
        return pytest.Module.from_parent(parent, path=file_path)

# Or use python_files in config
```

```ini
# pytest.ini
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
    # Setup
    db = Database(':memory:')
    db.create_tables()
    
    yield db  # Test runs here
    
    # Teardown
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
    import os
    os.environ['TESTING'] = 'true'
    
    yield
    
    del os.environ['TESTING']

def test_something():
    # setup_test_environment already ran
    assert os.environ.get('TESTING') == 'true'
```

### Fixture Composition

```python
@pytest.fixture
def config():
    return {"debug": True, "timeout": 30}

@pytest.fixture
def client(config):
    """Fixture using another fixture."""
    return Client(config=config)

@pytest.fixture
def authenticated_client(client):
    """Fixture using client fixture."""
    client.login("user", "password")
    return client

def test_authenticated(authenticated_client):
    response = authenticated_client.get("/profile")
    assert response.status_code == 200
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
def runner(app):
    """Create CLI runner."""
    return app.test_cli_runner()

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

## Plugins

pytest has a rich plugin ecosystem. Here are the most essential plugins.

### pytest-asyncio (Async Testing)

**Installation:**
```bash
pip install pytest-asyncio
```

**Configuration:**
```ini
# pytest.ini
[pytest]
asyncio_mode = auto  # Options: auto, strict, legacy
```

**Basic Async Tests:**
```python
import pytest

# Auto mode - no decorator needed with auto mode
async def test_async_operation():
    """Test async function."""
    result = await fetch_data()
    assert result == expected

# Strict mode - requires decorator
@pytest.mark.asyncio
async def test_with_decorator():
    """Test with explicit marker."""
    result = await async_function()
    assert result is not None
```

**Async Fixtures:**
```python
import pytest
import httpx

@pytest.fixture
async def async_client():
    """Async HTTP client fixture."""
    async with httpx.AsyncClient() as client:
        yield client

@pytest.fixture
async def db_session():
    """Async database session."""
    session = await create_session()
    yield session
    await session.close()

# Usage
@pytest.mark.asyncio
async def test_api_call(async_client):
    """Test API with async client."""
    response = await async_client.get("https://api.example.com/data")
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
```

**Testing Async Context Managers:**
```python
@pytest.mark.asyncio
async def test_async_context():
    """Test async context manager."""
    async with AsyncResource() as resource:
        result = await resource.process()
        assert result.success
```

**Testing Concurrent Operations:**
```python
import asyncio

@pytest.mark.asyncio
async def test_concurrent_tasks():
    """Test multiple concurrent operations."""
    tasks = [
        fetch_user(1),
        fetch_user(2),
        fetch_user(3),
    ]
    results = await asyncio.gather(*tasks)
    assert len(results) == 3
```

**Mocking Async Functions:**
```python
from unittest.mock import AsyncMock

@pytest.mark.asyncio
async def test_with_async_mock():
    """Mock async function."""
    fetch_data = AsyncMock(return_value={"status": "ok"})
    
    result = await fetch_data()
    assert result["status"] == "ok"
    fetch_data.assert_awaited_once()

# With pytest-mock
def test_async_mock_mocker(mocker):
    """Using pytest-mock for async."""
    mock_fetch = mocker.patch('mymodule.fetch_data', new_callable=AsyncMock)
    mock_fetch.return_value = {"data": "test"}
    
    # In your async code
    result = await fetch_data()
    assert result["data"] == "test"
```

### pytest-django (Django Testing)

**Installation:**
```bash
pip install pytest-django
```

**Configuration:**
```ini
# pytest.ini
[pytest]
DJANGO_SETTINGS_MODULE = myproject.settings
python_files = tests.py test_*.py *_tests.py
```

**Database Access:**
```python
import pytest
from django.contrib.auth.models import User
from myapp.models import Post

# Mark test for database access
@pytest.mark.django_db
def test_create_user():
    """Test requires database."""
    user = User.objects.create_user('testuser', 'test@example.com', 'password')
    assert user.username == 'testuser'

# Using db fixture (preferred)
def test_with_db_fixture(db):
    """db fixture enables database access."""
    User.objects.create_user('testuser')
    assert User.objects.count() == 1

# Transactional tests (rollback after test)
@pytest.mark.django_db(transaction=True)
def test_transactional():
    """Test with transaction rollback."""
    User.objects.create_user('temp')
    # Rolled back after test
```

**Django Fixtures:**
```python
@pytest.fixture
def client():
    """Django test client."""
    from django.test import Client
    return Client()

@pytest.fixture
def admin_user(db):
    """Create admin user."""
    return User.objects.create_superuser(
        'admin',
        'admin@example.com',
        'adminpass'
    )

@pytest.fixture
def admin_client(client, admin_user):
    """Authenticated admin client."""
    client.force_login(admin_user)
    return client

@pytest.fixture
def post(db):
    """Create test post."""
    user = User.objects.create_user('author')
    return Post.objects.create(
        title="Test Post",
        content="Test content",
        author=user
    )

# Usage
def test_admin_access(admin_client):
    """Test admin-only view."""
    response = admin_client.get('/admin/')
    assert response.status_code == 200

def test_post_creation(admin_client):
    """Test creating a post."""
    response = admin_client.post('/posts/', {
        'title': 'New Post',
        'content': 'Content here'
    })
    assert response.status_code == 302  # Redirect after create
```

**Testing Views:**
```python
def test_home_view(client):
    """Test home page."""
    response = client.get('/')
    assert response.status_code == 200
    assert 'Welcome' in response.content.decode()

def test_login_view(client):
    """Test login."""
    response = client.post('/login/', {
        'username': 'test',
        'password': 'pass'
    })
    assert response.status_code == 302  # Redirect after login

def test_api_json(client):
    """Test JSON API."""
    response = client.get('/api/data/')
    assert response.status_code == 200
    data = response.json()
    assert 'results' in data
```

**Testing Models:**
```python
@pytest.mark.django_db
class TestUserModel:
    """Test User model."""
    
    def test_create_user(self):
        user = User.objects.create_user('test')
        assert user.username == 'test'
        assert user.is_active is True
    
    def test_user_str(self):
        user = User(username='testuser')
        assert str(user) == 'testuser'
```

**Testing Forms:**
```python
def test_valid_form():
    """Test form validation."""
    from myapp.forms import PostForm
    form = PostForm(data={
        'title': 'Test',
        'content': 'Content'
    })
    assert form.is_valid() is True

def test_invalid_form():
    """Test invalid form."""
    from myapp.forms import PostForm
    form = PostForm(data={'title': ''})  # Missing content
    assert form.is_valid() is False
    assert 'content' in form.errors
```

### pytest-cov (Coverage)

**Installation:**
```bash
pip install pytest-cov
```

**Basic Usage:**
```bash
# Run with coverage
pytest --cov=myapp tests/

# Coverage with report
pytest --cov=myapp --cov-report=term-missing tests/

# HTML report
pytest --cov=myapp --cov-report=html tests/
# Open htmlcov/index.html in browser

# XML report (for CI)
pytest --cov=myapp --cov-report=xml tests/

# Multiple report formats
pytest --cov=myapp --cov-report=term --cov-report=html --cov-report=xml tests/
```

**Fail on Low Coverage:**
```bash
# Fail if coverage below 80%
pytest --cov=myapp --cov-fail-under=80 tests/
```

**Configuration:**
```ini
# pytest.ini
[pytest]
addopts = --cov=myapp --cov-report=term-missing --cov-fail-under=80

# .coveragerc
[run]
source = myapp
omit = 
    myapp/tests/*
    myapp/migrations/*

[report]
exclude_lines =
    pragma: no cover
    if __name__ == .__main__.:
    raise NotImplementedError
```

**Coverage Configuration in pyproject.toml:**
```toml
# pyproject.toml
[tool.coverage.run]
source = ["myapp"]
omit = ["myapp/tests/*"]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "if TYPE_CHECKING:",
    "raise NotImplementedError",
]
fail_under = 80
```

**Branch Coverage:**
```bash
# Enable branch coverage
pytest --cov=myapp --cov-branch tests/
```

**Coverage Contexts:**
```python
# Test with coverage contexts
pytest --cov-context=test tests/
```

### pytest-mock (Mocking)

**Installation:**
```bash
pip install pytest-mock
```

**Basic Mocking:**
```python
def test_mock_function(mocker):
    """Mock a function."""
    mock_get = mocker.patch('requests.get')
    mock_get.return_value.status_code = 200
    mock_get.return_value.json.return_value = {"data": "test"}
    
    import requests
    response = requests.get("https://api.example.com")
    
    assert response.status_code == 200
    assert response.json() == {"data": "test"}
    mock_get.assert_called_once_with("https://api.example.com")

def test_mock_method(mocker):
    """Mock class method."""
    user = User()
    mock_save = mocker.patch.object(user, 'save', return_value=True)
    
    result = user.save()
    
    assert result is True
    mock_save.assert_called_once()

def test_mock_class(mocker):
    """Mock entire class."""
    MockUser = mocker.patch('myapp.models.User')
    MockUser.objects.create.return_value = User(id=1, name="Test")
    
    user = create_user("Test")
    
    assert user.id == 1
    MockUser.objects.create.assert_called_once_with(name="Test")
```

**Mock Properties:**
```python
def test_mock_property(mocker):
    """Mock property."""
    mocker.patch.object(
        User, 
        'is_active',
        new_callable=mocker.PropertyMock,
        return_value=True
    )
    
    user = User()
    assert user.is_active is True
```

**Spy on Functions:**
```python
def test_spy(mocker):
    """Spy tracks calls but uses real implementation."""
    spy = mocker.spy(myapp, 'process_data')
    
    result = myapp.process_data([1, 2, 3])
    
    assert result == [2, 4, 6]  # Real implementation
    spy.assert_called_once_with([1, 2, 3])
```

**Mock Context Managers:**
```python
def test_mock_context_manager(mocker):
    """Mock context manager."""
    mock_open = mocker.patch('builtins.open', mocker.mock_open(read_data="test data"))
    
    with open('file.txt') as f:
        content = f.read()
    
    assert content == "test data"
    mock_open.assert_called_once_with('file.txt')
```

**Side Effects:**
```python
def test_side_effect(mocker):
    """Mock with side effects."""
    mock_func = mocker.patch('mymodule.api_call')
    mock_func.side_effect = [
        {"status": "pending"},
        {"status": "pending"},
        {"status": "complete"}
    ]
    
    # First call
    assert api_call()["status"] == "pending"
    # Second call
    assert api_call()["status"] == "pending"
    # Third call
    assert api_call()["status"] == "complete"

def test_side_effect_exception(mocker):
    """Mock to raise exception."""
    mock_func = mocker.patch('mymodule.risky_operation')
    mock_func.side_effect = ValueError("Invalid input")
    
    with pytest.raises(ValueError, match="Invalid input"):
        risky_operation()
```

**Mock Async Functions:**
```python
from unittest.mock import AsyncMock

@pytest.mark.asyncio
async def test_async_mock(mocker):
    """Mock async function."""
    mock_fetch = mocker.patch(
        'mymodule.fetch_data',
        new_callable=AsyncMock,
        return_value={"data": "test"}
    )
    
    result = await fetch_data()
    
    assert result == {"data": "test"}
    mock_fetch.assert_awaited_once()
```

**Reset Mocks:**
```python
def test_reset_mock(mocker):
    """Reset mock between tests."""
    mock_func = mocker.patch('mymodule.function')
    
    function()  # Called once
    mock_func.assert_called_once()
    
    mock_func.reset_mock()
    
    # Now call count is 0
    mock_func.assert_not_called()
```

### pytest-xdist (Parallel Execution)

**Installation:**
```bash
pip install pytest-xdist
```

**Basic Usage:**
```bash
# Auto-detect CPU count
pytest -n auto tests/

# Specific number of workers
pytest -n 4 tests/

# One worker per test file
pytest -n 0 tests/  # Run each file in separate process
```

**Distribution Modes:**
```bash
# Load balancing (default)
pytest -n auto --dist=load tests/

# Each worker gets one test file
pytest -n auto --dist=loadfile tests/

# Each worker gets one test class
pytest -n auto --dist=loadscope tests/

# No distribution (run in main process)
pytest -n 0 tests/
```

**Configuration:**
```ini
# pytest.ini
[pytest]
addopts = -n auto --dist=loadfile
```

**When to Use:**
- ✅ Slow tests (I/O bound, API calls, database)
- ✅ Large test suites (100+ tests)
- ✅ CPU-bound tests (can use multiple cores)
- ❌ Tests with shared state
- ❌ Tests that modify global state
- ❌ Tests with race conditions

**Synchronization Between Workers:**
```python
import pytest
from xdist.scheduler import LoadScopeScheduling

# Tests in same class run on same worker
class TestDatabase:
    """All tests in this class run on same worker."""
    
    def test_create(self):
        pass
    
    def test_update(self):
        pass
```

### pytest-timeout

**Installation:**
```bash
pip install pytest-timeout
```

**Usage:**
```python
import pytest

@pytest.mark.timeout(5)  # 5 seconds
def test_must_be_fast():
    """Fail if takes longer than 5 seconds."""
    result = fast_operation()
    assert result is not None

@pytest.mark.timeout(10, method='thread')
def test_with_thread_method():
    """Use thread-based timeout (default)."""
    pass

@pytest.mark.timeout(10, method='signal')
def test_with_signal_method():
    """Use signal-based timeout (Unix only)."""
    pass
```

**Global Configuration:**
```ini
# pytest.ini
[pytest]
timeout = 10
timeout_method = thread
```

**Command Line:**
```bash
# Global timeout for all tests
pytest --timeout=10 tests/

# Override marker timeout
pytest --timeout=5 --override-timeout tests/
```

### Other Essential Plugins

**pytest-env (Environment Variables):**
```ini
# pytest.ini
[pytest]
env =
    D:DATABASE_URL=sqlite:///:memory:
    D:DEBUG=True
    API_KEY=test_key
```

**pytest-randomly (Random Test Order):**
```bash
pip install pytest-randomly

# Randomizes test order to detect inter-test dependencies
pytest tests/

# Set seed for reproducibility
pytest --randomly-seed=1234 tests/
```

**pytest-sugar (Better Output):**
```bash
pip install pytest-sugar

# Automatically enhances pytest output with progress bar and icons
pytest tests/
```

**pytest-clarity (Better Diffs):**
```bash
pip install pytest-clarity

# Improves diff output for failed assertions
pytest tests/
```

**pytest-benchmark (Performance):**
```python
def test_performance(benchmark):
    """Benchmark function performance."""
    result = benchmark(sort_large_list, data)
    assert result == sorted(data)

# Run
pytest --benchmark-only tests/
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
minversion = 7.0

# Required plugins
required_plugins = pytest-cov pytest-mock

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

## Mocking and Patching

### unittest.mock

```python
from unittest.mock import Mock, patch, MagicMock

def test_with_mock():
    """Using unittest.mock directly."""
    mock = Mock()
    mock.method.return_value = 42
    
    result = mock.method()
    assert result == 42
    mock.method.assert_called_once()

@patch('module.function')
def test_with_patch(mock_function):
    """Patch a function."""
    mock_function.return_value = "mocked"
    
    result = module.function()
    assert result == "mocked"

@patch.object(MyClass, 'method')
def test_patch_method(mock_method):
    """Patch class method."""
    mock_method.return_value = "mocked"
    
    obj = MyClass()
    result = obj.method()
    assert result == "mocked"
```

### monkeypatch

```python
import pytest

def test_environment_variable(monkeypatch):
    """Set environment variable for test."""
    monkeypatch.setenv('API_KEY', 'test_key')
    
    import os
    assert os.environ['API_KEY'] == 'test_key'

def test_delete_env(monkeypatch):
    """Delete environment variable."""
    monkeypatch.delenv('HOME', raising=False)
    
    import os
    assert 'HOME' not in os.environ

def test_patch_dict(monkeypatch):
    """Patch dictionary."""
    data = {'key': 'value'}
    monkeypatch.setitem(data, 'key', 'new_value')
    
    assert data['key'] == 'new_value'

def test_patch_attribute(monkeypatch):
    """Patch object attribute."""
    class Config:
        DEBUG = False
    
    monkeypatch.setattr(Config, 'DEBUG', True)
    
    assert Config.DEBUG is True

def test_patch_function(monkeypatch):
    """Patch function."""
    def original():
        return "original"
    
    monkeypatch.setattr('module.original', lambda: "patched")
    
    assert module.original() == "patched"
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ['3.9', '3.10', '3.11', '3.12']
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}
    
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        pip install pytest pytest-cov pytest-xdist
    
    - name: Run tests
      run: |
        pytest --cov=myapp --cov-report=xml -n auto
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml
```

### GitLab CI

```yaml
# .gitlab-ci.yml
test:
  stage: test
  image: python:3.11
  script:
    - pip install -r requirements.txt
    - pip install pytest pytest-cov
    - pytest --cov=myapp --cov-report=xml --junitxml=report.xml
  artifacts:
    reports:
      junit: report.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
  coverage: '/TOTAL.*\s+(\d+%)/'
```

## Debugging

### pdb Debugging

```python
def test_with_debugger():
    """Use pdb for debugging."""
    result = some_function()
    import pdb; pdb.set_trace()  # Breakpoint
    assert result == expected
```

```bash
# Run with pdb on failure
pytest --pdb tests/

# Trace execution
pytest --trace tests/

# Enter pdb on error
pytest --pdbcls=IPython.terminal.debugger:TerminalPdb tests/
```

### pytest hooks for debugging

```python
# conftest.py
def pytest_runtest_makereport(item, call):
    """Log test results."""
    if call.when == "call":
        if call.excinfo is not None:
            print(f"\nTest {item.name} failed!")
            print(f"Exception: {call.excinfo.value}")

def pytest_exception_interact(node, call, report):
    """Called when exception occurs."""
    if report.failed:
        print(f"\nFailed test: {node.name}")
```

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
- **Pytest Plugins**: https://docs.pytest.org/en/latest/reference/plugin_list.html
- **Excellent Book**: "Python Testing with pytest" by Brian Okken
