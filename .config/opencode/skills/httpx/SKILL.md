---
name: httpx
description: "Modern async HTTP client for Python with sync/async API, HTTP/2 support, connection pooling, retries, and timeouts"
metadata:
  author: "OSS AI Skills"
  version: "1.0.0"
  tags:
    - python
    - http
    - async
    - client
    - network
---

# httpx

Modern HTTP client for Python.

## Overview

httpx is a modern, full-featured HTTP client for Python that provides a simple but comprehensive API for making HTTP requests. It supports both synchronous and asynchronous programming, making it suitable for a wide variety of use cases.

**Key Features:**
- Sync and async APIs
- HTTP/2 support
- Connection pooling
- Timeouts and retries
- Cookie persistence
- Request/response streaming
- Proxies support
- Authentication
- Modern Python type hints

### Installation

```bash
# Basic installation
pip install httpx

# With HTTP/2 support
pip install httpx[http2]

# With SOCKS proxy support
pip install httpx[socks]

# With all optional dependencies
pip install httpx[http2,socks,trio,curio]
```

## Basic Usage

### Synchronous Requests

```python
import httpx

# GET request
response = httpx.get("https://example.com")
print(response.status_code)
print(response.text)
print(response.json())

# POST request with JSON
response = httpx.post(
    "https://api.example.com/users",
    json={"name": "John", "email": "john@example.com"}
)
print(response.status_code)

# PUT request
response = httpx.put(
    "https://api.example.com/users/1",
    data={"name": "Jane"}
)

# DELETE request
response = httpx.delete("https://api.example.com/users/1")

# HEAD request
response = httpx.head("https://example.com")
print(response.headers)

# OPTIONS request
response = httpx.options("https://api.example.com")
print(response.headers["allow"])
```

### Async Requests

```python
import asyncio
import httpx

async def main():
    async with httpx.AsyncClient() as client:
        response = await client.get("https://example.com")
        print(response.status_code)
        print(response.text)

asyncio.run(main())
```

## Response Handling

### Status Codes

```python
import httpx

response = httpx.get("https://example.com")

# Check status code
print(response.status_code)  # 200

# Status code categories
print(response.is_success)      # True for 2xx
print(response.is_redirect)     # True for 3xx
print(response.is_client_error)  # True for 4xx
print(response.is_server_error)  # True for 5xx

# Raise for error status codes
response = httpx.get("https://example.com/not-found")
try:
    response.raise_for_status()
except httpx.HTTPStatusError as e:
    print(f"Error: {e.response.status_code}")
```

### Response Content

```python
import httpx

response = httpx.get("https://example.com")

# Text content
print(response.text)  # Returns string

# Binary content
print(response.content)  # Returns bytes

# JSON content (auto-parsed)
data = response.json()
print(data["key"])

# Streaming response
async with httpx.AsyncClient() as client:
    async with client.stream("GET", "https://example.com/large-file") as response:
        # Process chunks
        async for chunk in response.aiter_bytes():
            print(chunk)

        # Or iter text
        async for line in response.aiter_text():
            print(line)
```

### Headers

```python
import httpx

response = httpx.get("https://example.com")

# Response headers
print(response.headers)
print(response.headers["content-type"])
print(response.headers.get("content-length"))

# Request headers
response = httpx.get(
    "https://api.example.com",
    headers={
        "Authorization": "Bearer token",
        "Accept": "application/json",
        "User-Agent": "MyApp/1.0"
    }
)
```

### Cookies

```python
import httpx

# Get cookies from response
response = httpx.get("https://example.com")
print(response.cookies)
print(response.cookies["session_id"])

# Send cookies
response = httpx.get(
    "https://example.com",
    cookies={"session_id": "abc123"}
)

# Cookie jar
import httpx
cookies = httpx.Cookies()
cookies.set("session", "value", domain="example.com")
response = httpx.get("https://example.com", cookies=cookies)
```

## Request Configuration

### Query Parameters

```python
import httpx

# Simple params
response = httpx.get(
    "https://api.example.com/search",
    params={"query": "python", "page": 1}
)

# List params
response = httpx.get(
    "https://api.example.com/users",
    params={"id": [1, 2, 3]}  # ?id=1&id=2&id=3
)
```

### Request Body

```python
import httpx

# JSON body (auto-serialized)
response = httpx.post(
    "https://api.example.com/users",
    json={"name": "John", "age": 30}
)

# Form data
response = httpx.post(
    "https://api.example.com/login",
    data={"username": "john", "password": "secret"}
)

# Multipart file upload
response = httpx.post(
    "https://api.example.com/upload",
    files={"document": open("file.pdf", "rb")}
)

# Multipart with data
response = httpx.post(
    "https://api.example.com/upload",
    data={"title": "My Document"},
    files={"document": ("doc.pdf", open("file.pdf", "rb"), "application/pdf")}
)

# Raw body
response = httpx.post(
    "https://api.example.com/data",
    content=b"raw bytes"
)
```

### Authentication

```python
import httpx
from httpx import Auth

# Basic auth
response = httpx.get(
    "https://api.example.com/protected",
    auth=("username", "password")
)

# Custom auth class
class CustomAuth(Auth):
    def __init__(self, token):
        self.token = token
    
    def auth_flow(self, request):
        request.headers["Authorization"] = f"Bearer {self.token}"
        yield request

response = httpx.get(
    "https://api.example.com",
    auth=CustomAuth("my-token")
)

# Digest auth
from httpx import DigestAuth
response = httpx.get(
    "https://api.example.com",
    auth=DigestAuth("username", "password")
)
```

### Timeouts

```python
import httpx
from httpx import Timeout

# Default timeout (5 seconds)
response = httpx.get("https://example.com")

# Custom timeout
response = httpx.get(
    "https://example.com",
    timeout=10.0
)

# Configure timeout components
timeout = Timeout(
    connect=5.0,    # Connection timeout
    read=30.0,      # Read timeout
    write=10.0,     # Write timeout
    pool=5.0        # Pool timeout
)
response = httpx.get("https://example.com", timeout=timeout)

# No timeout
response = httpx.get(
    "https://example.com",
    timeout=None
)
```

### SSL Verification

```python
import httpx

# Default (verify=True)
response = httpx.get("https://example.com")

# Disable verification (not recommended)
response = httpx.get(
    "https://example.com",
    verify=False
)

# Custom CA bundle
response = httpx.get(
    "https://example.com",
    verify="/path/to/ca-bundle.crt"
)

# Client certificates
response = httpx.get(
    "https://example.com",
    cert=("/path/to/client.crt", "/path/to/client.key")
)
```

## Async Client

### AsyncClient Setup

```python
import asyncio
import httpx

# Basic async client
async def fetch():
    async with httpx.AsyncClient() as client:
        response = await client.get("https://example.com")
        return response.text

asyncio.run(fetch())

# With default configuration
client = httpx.AsyncClient(
    base_url="https://api.example.com",
    headers={"Authorization": "Bearer token"},
    timeout=30.0
)

async def main():
    # Relative URL will be joined with base_url
    response = await client.get("/users/1")
    print(response.json())

asyncio.run(main())
```

### Concurrent Requests

```python
import asyncio
import httpx

async def fetch_all():
    urls = [
        "https://api.example.com/users/1",
        "https://api.example.com/users/2",
        "https://api.example.com/users/3",
    ]
    
    async with httpx.AsyncClient() as client:
        # Gather responses
        responses = await asyncio.gather(
            *[client.get(url) for url in urls]
        )
        
        for response in responses:
            print(response.json())

asyncio.run(fetch_all())

# With limits
async def fetch_with_limits():
    limits = httpx.Limits(
        max_keepalive_connections=20,
        max_connections=100,
        keepalive_expiry=30
    )
    
    async with httpx.AsyncClient(limits=limits) as client:
        # Concurrent requests with connection limiting
        tasks = [client.get(url) for url in urls]
        responses = await asyncio.gather(*tasks)

asyncio.run(fetch_with_limits())
```

### Streaming

```python
import asyncio
import httpx

async def stream_download():
    async with httpx.AsyncClient() as client:
        async with client.stream(
            "GET",
            "https://example.com/large-file"
        ) as response:
            # Response is not loaded into memory
            async for chunk in response.aiter_bytes(chunk_size=8192):
                # Process chunk
                print(f"Received {len(chunk)} bytes")

asyncio.run(stream_download())

# Upload streaming
async def stream_upload():
    async with httpx.AsyncClient() as client:
        # Generate data
        async def generate():
            for i in range(10):
                yield f"chunk {i}\n".encode()
        
        await client.post(
            "https://api.example.com/upload",
            content=generate()
        )

asyncio.run(stream_upload())
```

## Advanced Features

### HTTP/2 Support

```python
import httpx

# HTTP/2 with h2 library
client = httpx.Client(
    http2=True
)

# Auto-negotiation (default in async)
async with httpx.AsyncClient(http2=True) as client:
    # HTTP/2 connections are multiplexing
    # Multiple requests over single connection
    responses = await asyncio.gather(
        client.get("https://example.com/page1"),
        client.get("https://example.com/page2"),
        client.get("https://example.com/page3"),
    )
```

### Connection Pooling

```python
import httpx

# Custom limits
limits = httpx.Limits(
    max_keepalive_connections=20,  # Max idle connections
    max_connections=100,           # Max total connections
    keepalive_expiry=30            # Keepalive timeout in seconds
)

client = httpx.Client(limits=limits)

# Or async
async_client = httpx.AsyncClient(limits=limits)

# Context manager handles cleanup
with httpx.Client(limits=limits) as client:
    response = client.get("https://example.com")
```

### Retries

```python
import httpx
from httpx import Retry

# Configure retry strategy
retry = Retry(
    total=3,                    # Max total retries
    backoff_factor=0.5,          # Exponential backoff
    status_forcelist=[500, 502, 503, 504],
    allow_redirects=False,
)

client = httpx.Client(mounts={
    "http://": httpx.HTTPTransport(retries=retry),
    "https://": httpx.HTTPTransport(retries=retry),
})

# Or use httpx-retry library
# pip install httpx-retry
import httpx_retry

client = httpx_retry.RetryClient(
    total=3,
    backoff_factor=0.5,
    retry_on_status=[500, 502, 503, 504]
)
```

### Proxies

```python
import httpx

# HTTP proxy
response = httpx.get(
    "https://example.com",
    proxies={"http://": "http://proxy:8080"}
)

# HTTPS proxy
response = httpx.get(
    "https://example.com",
    proxies={"https://": "http://proxy:8080"}
)

# SOCKS proxy
response = httpx.get(
    "https://example.com",
    proxies={"http://": "socks5://user:pass@proxy:1080"}
)

# Per-host routing
response = httpx.get(
    "https://api.example.com",
    proxies={
        "http://api.example.com": "http://api-proxy:8080",
        "http://": "http://default-proxy:8080"
    }
)
```

### Event Hooks

```python
import httpx

def log_request(request):
    print(f"Request: {request.method} {request.url}")

def log_response(response):
    print(f"Response: {response.status_code}")

# Install hooks
client = httpx.Client(
    event_hooks={
        "request": [log_request],
        "response": [log_response],
    }
)

response = client.get("https://example.com")

# Async client
async def async_log_request(request):
    print(f"Request: {request.method}")

async with httpx.AsyncClient(
    event_hooks={
        "request": [async_log_request],
    }
) as client:
    response = await client.get("https://example.com")
```

## Testing

### Mocking with httpx-mock

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

### Using respx

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

### Async Testing

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

## Best Practices

### 1. Use Context Managers

```python
# Good: Context manager ensures cleanup
with httpx.Client() as client:
    response = client.get("https://api.example.com/users")
    users = response.json()

# Bad: Manual cleanup needed
client = httpx.Client()
try:
    response = client.get("https://api.example.com/users")
finally:
    client.close()
```

### 2. Reuse Client for Performance

```python
# Good: Reuse client for multiple requests
client = httpx.Client()
try:
    for user_id in range(1, 100):
        response = client.get(f"https://api.example.com/users/{user_id}")
        process(response.json())
finally:
    client.close()

# Bad: New client for each request
for user_id in range(1, 100):
    with httpx.Client() as client:  # Inefficient!
        response = client.get(f"https://api.example.com/users/{user_id}")
```

### 3. Always Set Timeouts

```python
# Good: Explicit timeouts
timeout = httpx.Timeout(10.0, connect=5.0)
response = client.get("https://api.example.com", timeout=timeout)

# Default timeout is 5 seconds
response = client.get("https://api.example.com")  # OK but explicit is better
```

### 4. Handle Exceptions

```python
import httpx
from httpx import ConnectTimeout, ReadTimeout, HTTPError

try:
    response = client.get("https://api.example.com")
except ConnectTimeout:
    print("Connection timed out")
except ReadTimeout:
    print("Read timed out")
except httpx.HTTPError as e:
    print(f"HTTP error: {e}")
except Exception as e:
    print(f"Unexpected error: {e}")
```

### 5. Use Async for I/O-bound Tasks

```python
# Good: Use async for multiple concurrent requests
async def fetch_all(urls):
    async with httpx.AsyncClient() as client:
        return await asyncio.gather(
            *[client.get(url) for url in urls]
        )

# Sequential sync requests
def fetch_all_sync(urls):
    with httpx.Client() as client:
        return [client.get(url).json() for url in urls]
```

## Integration Examples

### FastAPI

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

### Django

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

## Common Issues

### SSL Certificate Errors

```python
# Issue: SSL certificate verification failed
# Solution 1: Update certifi
# pip install --upgrade certifi

# Solution 2: Verify=False (not recommended for production)
response = client.get("https://example.com", verify=False)

# Solution 3: Custom CA
response = client.get(
    "https://example.com",
    verify="/path/to/ca-bundle.crt"
)
```

### Connection Pool Exhaustion

```python
# Issue: Too many open connections
# Solution: Use connection limits
limits = httpx.Limits(
    max_connections=50,
    max_keepalive_connections=20
)
client = httpx.Client(limits=limits)
```

### Timeout Issues

```python
# Issue: Requests hanging forever
# Solution: Always set timeouts
timeout = httpx.Timeout(10.0, connect=5.0)
response = client.get("https://api.example.com", timeout=timeout)

# Or disable only for specific operations
response = client.get(
    "https://api.example.com/long-operation",
    timeout=None  # No timeout
)
```

## References

- **Official Documentation**: https://www.python-httpx.org/
- **GitHub Repository**: https://github.com/encode/httpx
- **HTTPX Discord**: https://discord.gg/q5B4fAT
- **Stack Overflow**: https://stackoverflow.com/questions/tagged/httpx