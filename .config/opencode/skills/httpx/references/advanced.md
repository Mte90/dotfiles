# Advanced Features

This file is loaded on demand from ../SKILL.md.

## HTTP/2 Support (v0.28+)

```python
import httpx

# HTTP/2 with h2 library (requires httpx[http2])
client = httpx.Client(
    http2=True  # Enable HTTP/2
)

# HTTP/2 is stable in v0.28+
# Auto-negotiation works with http2=True
async with httpx.AsyncClient(http2=True) as client:
    # HTTP/2 connections are multiplexing
    # Multiple requests over single connection
    responses = await asyncio.gather(
        client.get("https://example.com/page1"),
        client.get("https://example.com/page2"),
        client.get("https://example.com/page3"),
    )
```

## Connection Pooling

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

## Retries

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

## Proxies

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

## Event Hooks

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