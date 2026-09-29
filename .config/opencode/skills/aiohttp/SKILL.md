---
name: aiohttp
description: Use when building Python async HTTP services or clients with aiohttp - web server routing, middleware, WebSocket, SSE, streaming, client sessions, pytest-aiohttp testing, or troubleshooting SSL and timeout issues
metadata:
  author: mte90
  version: 2.0.0
  tags:
    - python
    - http
    - async
    - server
    - websocket
    - sse
---

# aiohttp

Asynchronous HTTP client/server framework for Python.

## Overview

aiohttp is a powerful asynchronous HTTP client and server framework built on asyncio. It provides both a web server for building web applications and a client for making HTTP requests.

**Key Features:**
- Async web server and client
- WebSocket support (client and server)
- Server-Sent Events (SSE)
- Middleware system
- Request/response streaming
- Cookie handling
- File uploads
- Web server routing
- Connection keepalive
- Support for HTTP/1.1 and HTTP/2

### Installation

```bash
# Basic installation
pip install aiohttp

# With development dependencies
pip install aiohttp[dev]

# With speedups (aiodns, Brotli)
pip install aiohttp[speedups]

# With all extras
pip install aiohttp[cryptography, speedups]
```

## See Also

- **fastapi** — Modern Python web framework with automatic OpenAPI and Pydantic integration
- **httpx** — Modern async HTTP client with sync/async API and HTTP/2 support
- **pydantic** — Data validation using Python type hints with automatic JSON validation
- **uvicorn** — ASGI server for running aiohttp and other async frameworks

## Web Server

### Basic Server

```python
from aiohttp import web

async def handle_request(request):
    """Simple request handler."""
    return web.Response(text="Hello, World!")

app = web.Application()
app.router.add_get('/', handle_handler)

if __name__ == '__main__':
    web.run_app(app, host='127.0.0.1', port=8080)
```

### Running Server

```python
from aiohttp import web

# Basic run
app = web.Application()
web.run_app(app)

# With configuration
web.run_app(
    app,
    host='0.0.0.0',
    port=8080,
    access_log=logger,
    shutdown_timeout=60,
    ssl_context=ssl_context,
    print=lambda x: print(x.strip())
)
```

### Application Factory

```python
from aiohttp import web

def create_app():
    """Application factory pattern."""
    app = web.Application()
    app.middlewares.append(security_middleware)
    app.router.add_get('/api', api_handler)
    app['db'] = create_database_pool()
    return app

app = create_app()
web.run_app(app)
```

## Routing

### Basic Routes

```python
from aiohttp import web

app = web.Application()

# Different HTTP methods
async def get_handler(request):
    return web.Response(text="GET request")

async def post_handler(request):
    data = await request.post()
    return web.json_response({"received": dict(data)})

app.router.add_get('/resource', get_handler)
app.router.add_post('/resource', post_handler)

# Or use @view decorator
@web.view('/items')
class ItemView(web.View):
    async def get(self):
        return web.json_response({"items": []})
    
    async def post(self):
        data = await self.request.json()
        return web.json_response({"created": data}, status=201)
```

### Variable Routes

```python
from aiohttp import web

app = web.Application()

# Path parameters
app.router.add_get('/users/{user_id}', get_user)
app.router.add_post('/users/{user_id}/posts', create_post)

async def get_user(request):
    user_id = request.match_info['user_id']
    return web.json_response({"id": user_id, "name": "John"})

# With type conversion
app.router.add_get('/users/{user_id:int}', get_user_by_id)
app.router.add_get('/files/{filename:[a-zA-Z0-9_\\.]+}', get_file)
```

### Resource Routes

```python
from aiohttp import web

app = web.Application()

# Using resource
resource = app.router.add_resource('/api', name='api')
resource.add_get(get_handler)
resource.add_post(post_handler)

# Reverse URL generation
url = app.router['api'].url_for()
print(str(url))  # /api

# With path parameters
resource = app.router.add_resource('/users/{user_id}', name='user_detail')
url = app.router['user_detail'].url_for(user_id=42)
print(str(url))  # /users/42
```

## Request Handling

### Reading Request Data

```python
from aiohttp import web

async def handle_request(request):
    # Query parameters
    query = request.query  # ImmutableMultiDict
    page = request.query.get('page', '1')
    tags = request.query.getall('tag')
    
    # POST form data
    data = await request.post()
    username = data.get('username')
    
    # JSON body
    json_data = await request.json()
    
    # Raw body
    body = await request.read()
    
    # Headers
    auth_header = request.headers.get('Authorization')
    content_type = request.content_type
    
    # Remote info
    remote = request.remote
    host = request.host
    
    # Match info (path parameters)
    user_id = request.match_info.get('user_id')
    
    return web.json_response({
        "query": dict(query),
        "data": json_data
    })
```

### JSON Request Body Validation with Pydantic

```python
from aiohttp import web
from pydantic import BaseModel, Field, ValidationError
from typing import Optional
import json

class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: str = Field(..., pattern=r'^[\w\.-]+@[\w\.-]+\.\w+$')
    age: Optional[int] = Field(None, ge=0, le=150)

@web.middleware
async def json_validation_middleware(request: web.Request, handler: web.Handler):
    if request.method not in ('POST', 'PUT'):
        return await handler(request)
    
    if request.content_type != 'application/json':
        return await handler(request)
    
    try:
        body = await request.json()
        validated_data = UserCreate(**body)
        request._body = json.dumps(validated_data.dict()).encode()
        request._parsed_json = validated_data
    except (json.JSONDecodeError, ValidationError) as e:
        return web.json_response(
            {"error": "Invalid JSON", "details": str(e)},
            status=400
        )
    
    return await handler(request)

app = web.Application(middlewares=[json_validation_middleware])
```

## Response

### Basic Responses

```python
from aiohttp import web

async def handler(request):
    # Text response
    return web.Response(text="Hello")
    
    # With status code
    return web.Response(text="Created", status=201)
    
    # JSON response
    return web.json_response({"key": "value"})
    
    # With headers
    return web.json_response(
        {"data": "test"},
        headers={"X-Custom": "value"}
    )
    
    # Redirect
    return web.HTTPFound('/new-location')
    
    # Error responses
    return web.HTTPUnauthorized(
        headers={'WWW-Authenticate': 'Basic realm="Login"'}
    )
```

### Response Types

```python
from aiohttp import web

async def text_response(request):
    return web.Response(text="Plain text", content_type="text/plain")

async def json_response(request):
    return web.json_response({"message": "JSON data"})

async def bytes_response(request):
    return web.Response(body=b"Binary data", content_type="application/octet-stream")

async def stream_response(request):
    """Streaming response for large files."""
    response = web.StreamResponse()
    response.headers['Content-Type'] = 'text/plain'
    await response.prepare(request)
    
    for i in range(10):
        await response.write(f"Line {i}\n".encode())
        await response.drain()
    
    await response.write_eof()
    return response

async def file_response(request):
    """Serve a file."""
    response = web.FileResponse('path/to/file.txt')
    response.headers['Content-Disposition'] = 'attachment; filename="file.txt"'
    return response
```

### WebSocket Response

```python
from aiohttp import web, WSMsgType

async def websocket_handler(request):
    ws = web.WebSocketResponse()
    await ws.prepare(request)
    
    try:
        async for msg in ws:
            if msg.type == WSMsgType.TEXT:
                await ws.send_str(f"Echo: {msg.data}")
            elif msg.type == WSMsgType.BINARY:
                await ws.send_bytes(msg.data)
            elif msg.type == WSMsgType.ERROR:
                print(f"WebSocket error: {ws.exception()}")
    finally:
        await ws.close()
    
    return ws

app.router.add_get('/ws', websocket_handler)
```

### Server-Sent Events

```python
from aiohttp import web
import asyncio

async def sse_handler(request):
    response = web.StreamResponse()
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Connection'] = 'keep-alive'
    
    await response.prepare(request)
    
    try:
        for i in range(10):
            data = json.dumps({"count": i})
            response.write(f"data: {data}\n\n".encode())
            await response.drain()
            await asyncio.sleep(1)
    finally:
        await response.write_eof()
    
    return response
```

## Static Files

```python
from aiohttp import web

app = web.Application()

# Simple static files
app.router.add_static('/static/', 'path/to/static')

# With options
app.router.add_static(
    '/static/',
    'path/to/static',
    show_index=True,
    follow_symlinks=True,
    append_version=True
)

# For single file
app.router.add_get('/favicon.ico', lambda r: web.FileResponse('favicon.ico'))
```

## Templates

### Jinja2 Integration

```bash
pip install aiohttp-jinja2 jinja2
```

```python
from aiohttp import web
import aiohttp_jinja2
import jinja2

# Setup
loader = jinja2.FileSystemLoader('templates')
env = aiohttp_jinja2.Environment(
    loader=loader,
    autoescape=True,
    enable_async=True
)
aiohttp_jinja2.setup(app, environment=env)

# Use in handler
@aiohttp_jinja2.template('index.html')
async def index(request):
    return {
        'title': 'My Page',
        'users': ['Alice', 'Bob', 'Charlie']
    }
```

### Template Filters

```python
from aiohttp import web
import aiohttp_jinja2
import jinja2

env = aiohttp_jinja2.Environment(
    loader=jinja2.FileSystemLoader('templates')
)

# Custom filter
@env.template_filter('uppercase')
def uppercase(s):
    return s.upper()

# Use in template: {{ name|uppercase }}
aiohttp_jinja2.setup(app, environment=env)
```

## Best Practices

### Session Management

```python
# ✅ GOOD: Reuse single session
async def setup(app):
    app['session'] = aiohttp.ClientSession()

async def cleanup(app):
    await app['session'].close()

app.on_startup.append(setup)
app.on_cleanup.append(cleanup)

async def good_handler(request):
    session = request.app['session']
    async with session.get(url) as response:
        return response
```

### Connection Settings

```python
connector = aiohttp.TCPConnector(
    limit=100,              # Total connection limit
    limit_per_host=30,      # Per-host limit
    ttl_dns_cache=300,      # DNS cache TTL
    ssl=True,
    keepalive_timeout=30,   # Keep connections alive
)
session = aiohttp.ClientSession(connector=connector)
```

### Error Handling

```python
async def safe_request(url):
    try:
        async with session.get(url) as response:
            response.raise_for_status()
            return await response.json()
    except aiohttp.ClientError as e:
        logger.error(f"Request failed: {e}")
        return None
```

### Do:

- Reuse ClientSession (not create per request)
- Always use `async with` for responses
- Set timeouts on all requests
- Use `raise_for_status()` for HTTP errors
- Implement proper error handling
- Use structured logging
- Validate request data with Pydantic
- Add authentication middleware
- Use connection pooling

### Don't:

- Create ClientSession in handler
- Forget to close sessions on shutdown
- Use sync I/O in handlers
- Store large data in memory (use streaming)
- Rely on default timeouts
- Skip authentication middleware

## Deep Dives

For detailed coverage of advanced topics, load these reference files on demand:

- **Middleware & Auth** — `references/middleware.md`: Global error handlers, logging, CORS, rate limiting, JWT/basic auth patterns
- **Client & Performance** — `references/client.md`: ClientSession usage, configuration, WebSocket client, keepalive, streaming, compression
- **Testing & Lifespan** — `references/testing.md`: Application signals, lifespan context, test client, pytest-aiohttp fixtures
- **Troubleshooting** — `references/troubleshooting.md`: Connection refused, timeouts, SSL errors, memory leaks

**Official Documentation**: https://docs.aiohttp.org/
**GitHub Repository**: https://github.com/aio-libs/aiohttp
**pytest-aiohttp**: https://pytest-aiohttp.readthedocs.io/