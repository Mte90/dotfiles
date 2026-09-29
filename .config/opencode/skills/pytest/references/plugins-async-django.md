# Loaded on demand from ../SKILL.md — pytest-asyncio, pytest-django, and async Django testing patterns.

## pytest-asyncio (Async Testing)

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

## pytest-django (Django Testing)

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

## Async Django Testing (pytest-asyncio + pytest-django)

When combining pytest-asyncio with pytest-django, special configuration and patterns are required to handle the async event loop and Django's sync ORM.

### Configuration

Make pytest-asyncio and pytest-django coexist in `pyproject.toml`:

```toml
# pyproject.toml
[tool.pytest.ini_options]
DJANGO_SETTINGS_MODULE = "myproject.settings.test"
asyncio_mode = "auto"
```

The `asyncio_mode = "auto"` setting is critical — it prevents event loop conflicts and allows async tests to run without explicit `@pytest.mark.asyncio` on every test.

### Async Database Fixture

Async tests that write to the DB need `transaction=True` because the transaction is not shared between the async event loop and the sync DB connection:

```python
import pytest
from asgiref.sync import sync_to_async

@pytest.fixture
@pytest.mark.django_db(transaction=True)
async def async_db():
    """Async fixture that can write to the DB."""
    yield

@pytest.mark.asyncio
@pytest.mark.django_db(transaction=True)
async def test_async_create_user():
    """Test async Django ORM operation."""
    from myapp.models import User
    
    # Must use sync_to_async for Django ORM calls
    user = await sync_to_async(User.objects.create)(
        username="testuser",
        email="test@example.com"
    )
    assert user.pk is not None
```

### Async Django View Testing

Testing async views with the async test client:

```python
from django.test import AsyncClient
import pytest

@pytest.mark.asyncio
@pytest.mark.django_db
async def test_async_api_endpoint():
    client = AsyncClient()
    response = await client.get("/api/data/")
    assert response.status_code == 200
```

### sync_to_async / async_to_async Bridge

The key pattern for mixing sync Django ORM with async tests:

```python
from asgiref.sync import sync_to_async

@pytest.mark.asyncio
@pytest.mark.django_db
async def test_async_with_orm():
    # Sync ORM call wrapped for async context
    count = await sync_to_async(User.objects.count)()
    assert count == 0
    
    # Create must also be wrapped
    await sync_to_async(User.objects.create)(username="async_user")
    
    count = await sync_to_async(User.objects.count)()
    assert count == 1
```

### Common Pitfalls

| Issue | Cause | Solution |
|-------|-------|----------|
| `SynchronousOnlyOperation` | Calling Django ORM directly in async | Use `sync_to_async()` wrapper |
| `TransactionManagementError` | Transaction not shared between event loops | Use `@pytest.mark.django_db(transaction=True)` |
| Tests hang/freeze | Event loop conflict | Set `asyncio_mode = "auto"` in config |
| `RuntimeError: Event loop is closed` | Fixture scope mismatch | Use function-scoped async fixtures |
| DB state leaks between tests | Missing transaction=True | Always use `transaction=True` for async DB tests |

### Complete conftest.py Example

```python
# tests/conftest.py
import pytest
from asgiref.sync import sync_to_async

@pytest.fixture
def async_client():
    from django.test import AsyncClient
    return AsyncClient()

@pytest.fixture
async def async_user(db):
    """Create a user for async tests."""
    from django.contrib.auth.models import User
    return await sync_to_async(User.objects.create_user)(
        username="testuser",
        password="testpass123"
    )
```