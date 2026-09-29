# Loaded on demand from ../SKILL.md — pytest-cov, pytest-mock, pytest-xdist, pytest-timeout, and other essential plugins.

## pytest-cov (Coverage)

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

## pytest-mock (Mocking)

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

## pytest-xdist (Parallel Execution)

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

## pytest-timeout

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

## Other Essential Plugins

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