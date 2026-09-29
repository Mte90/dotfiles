---
name: httpx
description: Use when making HTTP requests in Python with httpx - sync and async clients, streaming, HTTP/2, connection pooling, retries, proxies, SSL verification, respx testing, or FastAPI and Django integration
metadata:
  author: mte90
  version: 2.0.0
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

## Deep Dives

The following reference files are loaded on demand from `../SKILL.md`:

- **Async Client** — `references/async.md` — AsyncClient setup, concurrent requests, streaming uploads/downloads
- **Advanced Features** — `references/advanced.md` — HTTP/2, connection pooling, retries, proxies, event hooks
- **Testing & Integration** — `references/testing-integration.md` — httpx-mock, respx, async testing, FastAPI/Django integration