---
name: aiohttp
description: "Async HTTP server and client for Python with WebSocket support, middleware, streaming, and server-sent events"
metadata:
  author: "OSS AI Skills"
  version: "1.0.0"
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

aiohttp is a powerful asynchronous HTTP client and server framework built on top of asyncio. It provides both a web server for building web applications and a client for making HTTP requests.

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

## Web Server

### Basic Server

```python
from aiohttp import web

async def handle_request(request):
    """Simple request handler."""
    return web.Response(text="Hello, World!")

app = web.Application()
app.router.add_get('/', handle_request)

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

# From coroutine
async def init_app():
    app = web.Application()
    app.router.add_get('/', lambda request: web.Response(text="OK"))
    return app

web.run_app(init_app())
```

### Application Factory

```python
from aiohttp import web

def create_app():
    """Application factory pattern."""
    app = web.Application()
    
    # Add middleware
    app.middlewares.append(security_middleware)
    
    # Add routes
    app.router.add_get('/api', api_handler)
    
    # Store shared data
    app['db'] = create_database_pool()
    
    return app

# Create and run
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

async def put_handler(request):
    data = await request.json()
    return web.json_response({"updated": data})

async def delete_handler(request):
    return web.Response(text="Deleted")

# Add routes
app.router.add_get('/resource', get_handler)
app.router.add_post('/resource', post_handler)
app.router.add_put('/resource', put_handler)
app.router.add_delete('/resource', delete_handler)

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

async def create_post(request):
    user_id = request.match_info['user_id']
    data = await request.json()
    return web.json_response({
        "user_id": user_id,
        "post": data
    }, status=201)

# With type conversion
app.router.add_get('/users/{user_id:int}', get_user_by_id)
app.router.add_get('/files/{filename:[a-zA-Z0-9_\\.]+}', get_file)

async def get_user_by_id(request):
    user_id = request.match_info['user_id']  # Already int
    return web.json_response({"id": user_id})

# Default value
app.router.add_get('/users/{user_id:int=1}', get_default_user)
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

### Route Lifecycle

```python
from aiohttp import web

async def on_request_start(request):
    """Called when request starts."""
    print(f"Request started: {request.method} {request.path}")

async def on_request_match(request, mapping):
    """Called when route is matched."""
    print(f"Matched route: {mapping}")

app = web.Application()
app.on_request_start.append(on_request_start)
app.on_request_match.append(on_request_match)
```

## Request Handling

### Reading Request Data

```python
from aiohttp import web

async def handle_request(request):
    # Query parameters
    query = request.query  # ImmutableMultiDict
    page = request.query.get('page', '1')
    page = int(page)
    
    # Multiple values
    tags = request.query.getall('tag')
    
    # POST form data
    data = await request.post()
    username = data.get('username')
    password = data.get('password')
    
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

### Request Properties

```python
from aiohttp import web

async def handler(request):
    # Method
    print(request.method)  # GET, POST, etc.
    
    # URL
    print(request.url)       # yarl.URL object
    print(request.url.path)  # /path
    print(request.url.query) # query string
    
    # Version
    print(request.version)  # (1, 1)
    
    # Cookies
    print(request.cookies)  # SimpleCookie
    
    # Content type
    print(request.content_type)  # application/json
    
    # Can read body
    print(request.can_read_body)
    
    # Payload
    print(request.payload)  # StreamReader
    
    return web.Response(text="OK")
```

## Response

### Basic Responses

```python
from aiohttp import web

async def handlers(request):
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
    return web.Response(
        text="Plain text",
        content_type="text/plain"
    )

async def json_response(request):
    return web.json_response(
        {"message": "JSON data"},
        dumps=lambda x: json.dumps(x, indent=2)
    )

async def bytes_response(request):
    return web.Response(
        body=b"Binary data",
        content_type="application/octet-stream"
    )

async def stream_response(request):
    """Streaming response for large files."""
    response = web.StreamResponse()
    response.headers['Content-Type'] = 'text/plain'
    
    await response.prepare(request)
    
    for i in range(10):
        await response.write(f"Line {i}\n".encode())
        await asyncio.sleep(0.1)
    
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
    """WebSocket handler."""
    ws = web.WebSocketResponse()
    await ws.prepare(request)
    
    try:
        async for msg in ws:
            if msg.type == WSMsgType.TEXT:
                text = msg.data
                # Echo back
                await ws.send_str(f"Echo: {text}")
            elif msg.type == WSMsgType.BINARY:
                await ws.send_bytes(msg.data)
            elif msg.type == WSMsgType.ERROR:
                print(f"WebSocket error: {ws.exception()}")
    finally:
        await ws.close()
    
    return ws

# Add route
app.router.add_get('/ws', websocket_handler)
```

### Server-Sent Events

```python
from aiohttp import web
import asyncio

async def sse_handler(request):
    """Server-Sent Events handler."""
    response = web.StreamResponse()
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Connection'] = 'keep-alive'
    
    await response.prepare(request)
    
    try:
        for i in range(10):
            # Send event
            data = json.dumps({"count": i})
            response.write(f"data: {data}\n\n".encode())
            await response.drain()
            await asyncio.sleep(1)
    finally:
        await response.write_eof()
    
    return response
```

## Middleware

### Creating Middleware

```python
from aiohttp import web

@web.middleware
async def auth_middleware(request, handler):
    """Authentication middleware."""
    # Skip auth for certain paths
    if request.path.startswith('/public'):
        return await handler(request)
    
    # Check auth
    auth_header = request.headers.get('Authorization')
    if not auth_header:
        return web.HTTPUnauthorized(text="No auth header")
    
    # Verify token
    if not await verify_token(auth_header):
        return web.HTTPForbidden(text="Invalid token")
    
    # Continue to handler
    return await handler(request)

# Add to app
app = web.Application(middlewares=[auth_middleware])

# Multiple middleware (applied in order)
app = web.Application(
    middlewares=[
        logging_middleware,
        auth_middleware,
        error_middleware
    ]
)
```

### Common Middleware Patterns

```python
from aiohttp import web
import time

# Request logging middleware
@web.middleware
async def log_middleware(request, handler):
    start = time.time()
    response = await handler(request)
    duration = time.time() - start
    
    print(f"{request.method} {request.path} - {response.status} - {duration:.3f}s")
    return response

# CORS middleware
@web.middleware
async def cors_middleware(request, handler):
    response = await handler(request)
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
    return response

# Rate limiting middleware
@web.middleware
async def rate_limit_middleware(request, handler):
    ip = request.remote
    if await is_rate_limited(ip):
        return web.HTTPTooManyRequests(text="Rate limited")
    
    await increment_rate_limit(ip)
    return await handler(request)
```

## Static Files

```python
from aiohttp import web

app = web.Application()

# Simple static files
app.router.add_static('/static/', 'path/to/static')

# With cache max-age
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

# Template (index.html)
# <h1>{{ title }}</h1>
# <ul>
# {% for user in users %}
#   <li>{{ user }}</li>
# {% endfor %}
# </ul>
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

## Client

### Basic Client Usage

```python
import aiohttp
import asyncio

async def fetch():
    async with aiohttp.ClientSession() as session:
        # GET request
        async with session.get('https://api.example.com/data') as response:
            data = await response.json()
            print(data)
        
        # POST request
        async with session.post(
            'https://api.example.com/users',
            json={'name': 'John', 'email': 'john@example.com'}
        ) as response:
            result = await response.json()
        
        # PUT request
        async with session.put(
            'https://api.example.com/users/1',
            data={'name': 'Jane'}
        ) as response:
            pass
        
        # DELETE request
        async with session.delete('https://api.example.com/users/1') as response:
            pass

asyncio.run(fetch())
```

### Client Configuration

```python
import aiohttp

async def configured_client():
    # With base URL
    async with aiohttp.ClientSession(
        base_url='https://api.example.com',
        headers={'Authorization': 'Bearer token'}
    ) as session:
        # Relative URL will use base_url
        async with session.get('/users/1') as response:
            pass
    
    # With timeout
    timeout = aiohttp.ClientTimeout(
        total=30,
        connect=5,
        sock_read=10
    )
    async with aiohttp.ClientSession(timeout=timeout) as session:
        pass
    
    # With cookies
    async with aiohttp.ClientSession(
        cookies={'session': 'abc123'}
    ) as session:
        pass
    
    # With SSL context
    import ssl
    ssl_context = ssl.create_default_context()
    async with aiohttp.ClientSession(
        ssl=ssl_context
    ) as session:
        pass
```

### Client Request Options

```python
import aiohttp

async def client_options():
    async with aiohttp.ClientSession() as session:
        # Query parameters
        async with session.get(
            '/search',
            params={'q': 'python', 'page': 1}
        ) as response:
            pass
        
        # Headers
        async with session.get(
            '/api',
            headers={'Authorization': 'Bearer token'}
        ) as response:
            pass
        
        # JSON body
        async with session.post(
            '/users',
            json={'name': 'John'}
        ) as response:
            pass
        
        # Form data
        async with session.post(
            '/login',
            data={'username': 'john', 'password': 'secret'}
        ) as response:
            pass
        
        # Files
        async with session.post(
            '/upload',
            data={'file': open('file.txt', 'rb')}
        ) as response:
            pass
        
        # Custom content type
        async with session.post(
            '/data',
            data='raw string',
            content_type='text/plain'
        ) as response:
            pass
```

### Client Response

```python
import aiohttp

async def handle_response():
    async with aiohttp.ClientSession() as session:
        async with session.get('https://api.example.com') as response:
            # Status code
            print(response.status)
            
            # Headers
            print(response.headers)
            print(response.content_type)
            
            # Text
            text = await response.text()
            
            # JSON
            json_data = await response.json()
            
            # Bytes
            content = await response.read()
            
            # Cookies
            print(response.cookies)
            
            # History (for redirects)
            print(response.history)
```

### Client WebSocket

```python
import aiohttp

async def websocket_client():
    async with aiohttp.ClientSession() as session:
        async with session.ws_connect('wss://example.com/ws') as ws:
            # Send message
            await ws.send_str('Hello')
            await ws.send_json({'type': 'message', 'data': 'test'})
            
            # Receive message
            msg = await ws.receive()
            
            if msg.type == aiohttp.WSMsgType.TEXT:
                text = msg.data
            elif msg.type == aiohttp.WSMsgType.BINARY:
                data = msg.data
            elif msg.type == aiohttp.WSMsgType.ERROR:
                print(f"Error: {ws.exception()}")
            
            # Ping/Pong
            await ws.ping()
            
            # Close
            await ws.close()
```

## Advanced

### Application Signals

```python
from aiohttp import web

async def on_startup(app):
    """Called on startup."""
    print("Application starting")
    app['db'] = await create_db_pool()

async def on_cleanup(app):
    """Called on cleanup."""
    print("Application cleaning up")
    await app['db'].close()

async def on_shutdown(app):
    """Called on shutdown."""
    print("Application shutting down")

app = web.Application()
app.on_startup.append(on_startup)
app.on_cleanup.append(on_cleanup)
app.on_shutdown.append(on_shutdown)
```

### Lifespan Context

```python
from aiohttp import web

@web.lifespanContext
async def lifespan(app):
    """Context manager for application lifespan."""
    # Startup
    app['db'] = await create_db_pool()
    app['cache'] = await create_cache()
    
    yield
    
    # Shutdown
    await app['cache'].close()
    await app['db'].close()

app = web.Application(lifespan=lifespan)
```

### Signals

```python
from aiohttp import web
from aiohttp import signals as signals

# Pre-signal handlers
async def pre_signal_handler(app, services):
    print("Pre-signal handler")

app.signal(signals.pre_shutdown).append(pre_signal_handler)

# Post-signal handlers
async def post_signal_handler(app):
    print("Post-signal")

web.run_app(app, print=lambda x: None)
app.signal(web.Signals.POST_SIGNALS).append(post_signal_handler)
```

## Testing

### Test Client

```python
from aiohttp import web
import aiohttp
from aiohttp.test_utils import AioHTTPTestCase, unittest_run_loop

# Using TestClient
async def test_handler(request):
    return web.json_response({"test": True})

app = web.Application()
app.router.add_get('/test', test_handler)

async def run_tests():
    async with aiohttp.test_utils.TestClient(app) as client:
        async with client.get('/test') as response:
            assert response.status == 200
            data = await response.json()
            assert data == {"test": True}

asyncio.run(run_tests())

# Using AioHTTPTestCase
class MyTestCase(AioHTTPTestCase):
    async def get_application(self):
        app = web.Application()
        app.router.add_get('/', lambda r: web.Response(text='OK'))
        return app
    
    @unittest_run_loop
    async def test_index(self):
        async with self.client.get('/') as response:
            text = await response.text()
            assert text == 'OK'
```

### pytest-aiohttp

```bash
pip install pytest-aiohttp
```

```python
import pytest
from aiohttp import web

@pytest.fixture
def app():
    app = web.Application()
    app.router.add_get('/', lambda r: web.Response(text='OK'))
    return app

@pytest.mark.parametrize('path,expected', [
    ('/', 'OK'),
])
async def test_root(client, path, expected):
    async with client.get(path) as response:
        assert response.status == 200
        text = await response.text()
        assert text == expected
```

## Performance

### Keepalive

```python
from aiohttp import web

# Keep connections alive
app = web.Application(
    client_max_cache_size=1000  # Cache size for connections
)

# Client keepalive
async with aiohttp.ClientSession() as session:
    # Connections are reused automatically
    for _ in range(100):
        async with session.get('https://api.example.com/data'):
            pass
```

### Streaming

```python
from aiohttp import web

async def upload_handler(request):
    """Handle streaming upload."""
    reader = request.content
    
    with open('uploaded.file', 'wb') as f:
        while True:
            chunk = await reader.read(1024 * 1024)  # 1MB chunks
            if not chunk:
                break
            f.write(chunk)
    
    return web.Response(text="Uploaded")
```

### Compression

```python
from aiohttp import web

# Server handles compression automatically
# Client requests compressed content
async with aiohttp.ClientSession() as session:
    async with session.get(
        'https://api.example.com/data',
        headers={'Accept-Encoding': 'gzip, deflate'}
    ) as response:
        pass
```

## Security

### CORS

```python
from aiohttp import web

@web.middleware
async def cors_middleware(request, handler):
    if request.method == 'OPTIONS':
        # Preflight request
        response = web.Response()
    else:
        response = await handler(request)
    
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
    response.headers['Access-Control-Max-Age'] = '3600'
    
    return response

app = web.Application(middlewares=[cors_middleware])
```

### Rate Limiting

```python
from aiohttp import web
import time
from collections import defaultdict

class RateLimiter:
    def __init__(self, max_requests, window):
        self.max_requests = max_requests
        self.window = window
        self.requests = defaultdict(list)
    
    def is_allowed(self, ip):
        now = time.time()
        # Clean old requests
        self.requests[ip] = [
            t for t in self.requests[ip]
            if now - t < self.window
        ]
        
        if len(self.requests[ip]) >= self.max_requests:
            return False
        
        self.requests[ip].append(now)
        return True

@web.middleware
async def rate_limit_middleware(request, handler):
    ip = request.remote
    limiter = request.app['rate_limiter']
    
    if not limiter.is_allowed(ip):
        return web.HTTPTooManyRequests(text="Rate limited")
    
    return await handler(request)

app = web.Application()
app['rate_limiter'] = RateLimiter(max_requests=100, window=60)
app.middlewares.append(rate_limit_middleware)
```

## Common Issues

### Memory Leaks

```python
# Issue: Not closing response
async def bad_request():
    session = aiohttp.ClientSession()
    response = await session.get('https://example.com')
    data = await response.json()
    # Missing: await response.release()
    # Or use async with!

# Good: Always use context manager
async def good_request():
    async with aiohttp.ClientSession() as session:
        async with session.get('https://example.com') as response:
            data = await response.json()
```

### SSL Errors

```python
# Issue: SSL verification failed
# Solution 1: Update certifi
# pip install --upgrade certifi

# Solution 2: Disable verification (not recommended)
async with aiohttp.ClientSession(
    connector=aiohttp.TCPConnector(ssl=False)
) as session:
    pass

# Solution 3: Custom SSL context
import ssl
ssl_context = ssl.create_default_context()
async with aiohttp.ClientSession(
    connector=aiohttp.TCPConnector(ssl=ssl_context)
) as session:
    pass
```

### Timeouts

```python
# Issue: Request hangs
# Solution: Always set timeouts
timeout = aiohttp.ClientTimeout(total=30, connect=10)
async with aiohttp.ClientSession(timeout=timeout) as session:
    async with session.get('https://example.com') as response:
        pass
```

## References

- **Official Documentation**: https://docs.aiohttp.org/
- **GitHub Repository**: https://github.com/aio-libs/aiohttp
- **aio-libs Discord**: https://discord.gg/aio-libs
- **Stack Overflow**: https://stackoverflow.com/questions/tagged/aiohttp