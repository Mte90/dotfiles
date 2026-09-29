# Loaded on demand from ../SKILL.md — Mocking and Patching, CI/CD Integration, and Debugging.

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
        python-version: ['3.10', '3.11', '3.12', '3.13']
    
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