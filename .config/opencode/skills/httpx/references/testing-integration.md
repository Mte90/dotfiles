# Testing & Integration

This file is loaded on demand from ../SKILL.md.

## Mocking with httpx-mock

```python
import httpx
import pytest
from httpx import MockTransport

def test_simple_mock():
    """Simple mock without external requests."""
    transport = MockTransport(lambda request: httpx.Response(200, json={"key": "value"}))
    
    with httpx.Client(transport=transport) as client:
        response = client.get("https://example.com/api")
        assert response.status_code == 200
        assert response.json() == {"key": "value"}

def test_mock_status():
    """Mock error responses."""
    transport = MockTransport(lambda request: httpx.Response(404))
    
    with httpx.Client(transport=transport) as client:
        response = client.get("https://example.com/not-found")
        assert response.status_code == 404

def test_mock_redirect():
    """Mock redirects."""
    transport = MockTransport(
        lambda request: (
            httpx.Response(301, headers={"location": "https://example.com/new"})
            if request.url.path == "/old"
            else httpx.Response(200)
        )
    )
    
    with httpx.Client(transport=transport, follow_redirects=True) as client:
        response = client.get("https://example.com/old")
        assert response.status_code == 200
```

## Using respx

```python
import httpx
import respx
import pytest

@respx.mock
def test_with_respx():
    """Mock with respx library."""
    route = respx.get("https://example.com/api").mock(
        return_value=httpx.Response(200, json={"data": "test"})
    )
    
    response = httpx.get("https://example.com/api")
    assert response.json() == {"data": "test"}
    
    # Check call info
    assert route.called
    assert route.call_count == 1

@respx.mock
def test_mock_side_effect():
    """Mock with side effects."""
    call_count = 0
    
    def side_effect(request):
        nonlocal call_count
        call_count += 1
        return httpx.Response(200, json={"count": call_count})
    
    route = respx.get("https://example.com/counter").mock(side_effect=side_effect)
    
    # First call
    r1 = httpx.get("https://example.com/counter")
    assert r1.json() == {"count": 1}
    
    # Second call
    r2 = httpx.get("https://example.com/counter")
    assert r2.json() == {"count": 2}
```

## Async Testing

```python
import pytest
import httpx
from unittest.mock import AsyncMock, patch

@pytest.mark.asyncio
async def test_async_mock():
    """Test async client with mock."""
    transport = AsyncMock()
    transport.handle_async_request = AsyncMock(
        return_value=httpx.Response(200, json={"async": True})
    )
    
    async with httpx.AsyncClient(transport=transport) as client:
        response = await client.get("https://example.com/api")
        assert response.json() == {"async": True}

@pytest.mark.asyncio
async def test_patch_async():
    """Test with patch."""
    with patch("httpx.AsyncClient") as mock_client:
        mock_response = httpx.Response(200, text="mocked")
        mock_client.return_value.__aenter__.return_value.get = AsyncMock(
            return_value=mock_response
        )
        
        async with httpx.AsyncClient() as client:
            response = await client.get("https://example.com")
            assert response.text == "mocked"
```

## FastAPI Integration

```python
import httpx
from fastapi import FastAPI, Depends

app = FastAPI()

# Dependency for HTTP client
def get_http_client():
    with httpx.Client() as client:
        yield client

@app.get("/users/{user_id}")
async def get_user(
    user_id: int,
    client: httpx.Client = Depends(get_http_client)
):
    response = client.get(f"https://api.example.com/users/{user_id}")
    return response.json()

# Async version
@app.get("/posts/{post_id}")
async def get_post(post_id: int):
    async with httpx.AsyncClient() as client:
        response = await client.get(f"https://api.example.com/posts/{post_id}")
        return response.json()
```

## Django Integration

```python
import httpx
from django.http import JsonResponse

def external_api_view(request):
    with httpx.Client() as client:
        response = client.get(
            "https://api.example.com/data",
            headers={"Authorization": f"Bearer {request.user.token}"}
        )
        return JsonResponse(response.json())

# With timeout
def api_with_timeout(request):
    with httpx.Client(timeout=30.0) as client:
        response = client.get("https://api.example.com/data")
        return JsonResponse(response.json())
```