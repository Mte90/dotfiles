---
name: aiohttp
description: "Async HTTP server and client for Python with WebSocket support, middleware, streaming, and server-sent events"
metadata:
  author: mte90
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

### JSON Request Body Validation with Pydantic

```python
from aiohttp import web
from pydantic import BaseModel, Field, ValidationError
from typing import Optional
import json

# Define validation model
class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=50, description="Username")
    email: str = Field(..., pattern=r'^[\w\.-]+@[\w\.-]+\.\w+$', description="Valid email")
    age: Optional[int] = Field(None, ge=0, le=150, description="Age (0-150)")

# Pydantic v2 middleware for validation
@web.middleware
async def json_validation_middleware(request: web.Request, handler: web.Handler):
    """Validate JSON body against Pydantic model."""
    
    # Skip validation for non-POST/PUT requests
    if request.method not in ('POST', 'PUT'):
        return await handler(request)
    
    # Get content type
    if request.content_type != 'application/json':
        return await handler(request)
    
    try:
        # Parse and validate JSON
        body = await request.json()
        validated_data = UserCreate(**body)
        
        # Replace body with validated data
        request._body = json.dumps(validated_data.dict()).encode()
        request._parsed_json = validated_data
        
    except (json.JSONDecodeError, ValidationError) as e:
        return web.json_response(
            {"error": "Invalid JSON", "details": str(e)},
            status=400
        )
    
    return await handler(request)

# Add middleware to app
app = web.Application(middlewares=[json_validation_middleware])

# Handler receives validated data
async def create_user(request):
    # Access validated data
    user = request._parsed_json
    return web.json_response({
        "id": 1,
        "username": user.username,
        "email": user.email,
        "age": user.age
    }, status=201)
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
        await response.drain()
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

### Global Error Handlers

```python
from aiohttp import web
import logging
import traceback

logger = logging.getLogger(__name__)

@web.middleware
async def error_handling_middleware(request: web.Request, handler: web.Handler) -> web.Response:
    """Global error handler middleware."""
    try:
        response = await handler(request)
        response.headers['X-Request-Id'] = request.headers.get('X-Request-Id', '')
        return response
    except web.HTTPException as e:
        # Re-raise HTTP exceptions (4xx, 5xx)
        raise e
    except Exception as e:
        # Log unexpected errors
        logger.error(
            f"Unhandled exception: {e}",
            extra={
                'path': request.path,
                'method': request.method,
                'remote': request.remote,
            },
            exc_info=True
        )
        return web.json_response(
            {
                "error": "Internal Server Error",
                "message": str(e),
                "traceback": traceback.format_exc()
            },
            status=500
        )

# Custom exception handler for specific errors
async def not_found_handler(request):
    """404 Not Found handler."""
    return web.json_response(
        {"error": "Not Found", "path": request.path},
        status=404
    )

async def method_not_allowed_handler(request):
    """405 Method Not Allowed handler."""
    return web.json_response(
        {"error": "Method Not Allowed", "allowed": ['GET', 'POST']},
        status=405
    )

# Add error handlers
app = web.Application()
app.middlewares.append(error_handling_middleware)
app.on_exception.append(not_found_handler)
app.on_exception.append(method_not_allowed_handler)
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
    
    # Structured logging
    logger.info(
        "HTTP request completed",
        extra={
            "method": request.method,
            "path": request.path,
            "status": response.status,
            "duration": duration,
            "remote_ip": request.remote,
        }
    )
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

# Structured Logging Setup
import logging
from aiohttp import web

def setup_logging(app):
    """Configure structured logging for aiohttp."""
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    
    # File handler
    file_handler = logging.FileHandler('app.log')
    file_handler.setFormatter(formatter)
    
    # Console handler with JSON formatting
    console_handler = logging.StreamHandler()
    json_formatter = logging.Formatter('%(message)s')
    console_handler.setFormatter(json_formatter)
    
    logging.basicConfig(
        level=logging.INFO,
        handlers=[file_handler, console_handler]
    )
```

### Authentication/Authorization Patterns

```python
from aiohttp import web
import jwt
import time
from typing import Optional, Dict, Callable

# JWT Token Validation Middleware
@web.middleware
async def jwt_auth_middleware(request: web.Request, handler: web.Handler) -> web.Response:
    """JWT authentication middleware."""
    
    # Skip auth for public endpoints
    public_paths = ['/public/*', '/health']
    if any(request.path.startswith(p) for p in public_paths):
        return await handler(request)
    
    # Get token from Authorization header
    auth_header = request.headers.get('Authorization', '')
    
    if not auth_header.startswith('Bearer '):
        return web.json_response(
            {"error": "Missing Authorization header"},
            status=401
        )
    
    token = auth_header[7:]  # Remove 'Bearer ' prefix
    
    try:
        # Decode and verify JWT token
        payload = jwt.decode(
            token,
            options={"verify_exp": True},  # Verify expiration
            algorithms=["HS256"],  # Your algorithm
            audience="your-audience"
        )
        
        # Attach user data to request for handlers
        request['user'] = payload
        return await handler(request)
        
    except jwt.ExpiredSignatureError:
        return web.json_response(
            {"error": "Token expired"},
            status=401
        )
    except jwt.InvalidTokenError:
        return web.json_response(
            {"error": "Invalid token"},
            status=403
        )

# Basic Auth Middleware
@web.middleware
async def basic_auth_middleware(request: web.Request, handler: web.Handler) -> web.Response:
    """Basic authentication middleware."""
    
    # Skip auth for public paths
    if request.path.startswith('/public'):
        return await handler(request)
    
    # Get authorization header
    auth = request.headers.get('Authorization')
    if not auth:
        return web.Response(
            'Unauthorized',
            headers={'WWW-Authenticate': 'Basic realm="Login"'}
        )
    
    # Parse Basic auth
    try:
        username, password = auth.split(' ')[1].decode('base64').split(':')
    except:
        return web.Response(
            'Unauthorized',
            headers={'WWW-Authenticate': 'Basic realm="Login"'}
        )
    
    # Verify credentials
    if not verify_credentials(username, password):
        return web.Response(
            'Unauthorized',
            headers={'WWW-Authenticate': 'Basic realm="Login"'}
        )
    
    # Attach user to request
    request['user'] = {'username': username}
    return await handler(request)

# Helper functions
def verify_token(token: str) -> bool:
    """Verify JWT token (implementation depends on your setup)."""
    try:
        jwt.decode(token, options={"verify_exp": True}, algorithms=["HS256"])
        return True
    except:
        return False

def verify_credentials(username: str, password: str) -> bool:
    """Verify username/password (use database in production)."""
    # Replace with actual authentication logic
    return username == 'admin' and password == 'secret'
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

### pytest-aiohttp with Async Fixtures

```bash
pip install pytest pytest-aiohttp
```

```python
import pytest
from aiohttp import web

# Async server fixture
@pytest.fixture
async def aiohttp_server():
    """Create and return an aiohttp test server."""
    app = web.Application()
    
    # Add test routes
    @app.router.post('/users')
    async def create_user(request):
        data = await request.json()
        return web.json_response(
            {"id": 1, "username": data.get('username')},
            status=201
        )
    
    @app.router.get('/users/{user_id}')
    async def get_user(request, match_info):
        user_id = match_info['user_id']
        return web.json_response({"id": user_id, "name": f"User {user_id}"})
    
    server = await aiohttp_test_client(app)
    yield server
    await server.close()

# Route-specific fixture
@pytest.fixture
async def user_endpoint(aiohttp_client):
    """Test client for user endpoints."""
    app = web.Application()
    
    @app.router.post('/users')
    async def create_user(request):
        data = await request.json()
        return web.json_response(
            {"id": 1, "username": data.get('username')},
            status=201
        )
    
    app.router.add_get('/users/{user_id:int}', get_user_handler)
    
    async with aiohttp_client(app) as client:
        yield client

async def get_user_handler(request, match_info):
    user_id = match_info['user_id']
    return web.json_response({"id": user_id, "name": f"User {user_id}"})

# Test with fixtures
async def test_user_creation(aiohttp_server):
    """Test user creation endpoint."""
    response = await aiohttp_server.post('/users', json={'username': 'testuser'})
    assert response.status == 201
    data = await response.json()
    assert data['id'] == 1
    assert data['username'] == 'testuser'

async def test_user_retrieval(user_endpoint):
    """Test user retrieval by ID."""
    async with user_endpoint.get('/users/123') as response:
        assert response.status == 200
        data = await response.json()
        assert data['name'] == 'User 123'

# Test cleanup strategies
async def test_cleanup():
    """Test with proper cleanup."""
    session = None
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get('https://api.example.com') as response:
                data = await response.json()
                assert response.status == 200
    finally:
        # Cleanup will happen automatically with async with
        if session:
            await session.close()
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

## Troubleshooting

### Connection Refused

**Problem:** `aiohttp.connector.TCPConnector._resolve_host() raised for Connection refused`

**Solutions:**
1. Ensure the server is running on the expected port
2. Check firewall settings
3. Verify host address is correct

```python
# With retry logic
import aiohttp
from aiohttp import ClientConnectorError

async def fetch_with_retry(url, max_retries=3):
    for attempt in range(max_retries):
        try:
            async with aiohttp.ClientSession().get(url) as response:
                return await response.json()
        except ClientConnectorError as e:
            print(f"Connection attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                await asyncio.sleep(2 ** attempt)  # Exponential backoff
            else:
                raise
```

### Timeout Issues

**Problem:** Request hangs indefinitely

**Solutions:**
```python
# Always set timeouts
timeout = aiohttp.ClientTimeout(
    total=30,        # Max total time
    connect=5,       # Connection timeout
    sock_connect=5,  # Socket connection timeout
    sock_read=10     # Read timeout
)

async with aiohttp.ClientSession(timeout=timeout) as session:
    async with session.get('https://api.example.com') as response:
        data = await response.json()
```

### SSL Errors

**Problem:** SSL certificate verification failures

**Solutions:**
```python
# Solution 1: Update certificates (recommended)
# pip install --upgrade certifi

# Solution 2: Custom SSL context (verify only specific certs)
import ssl
ssl_context = ssl.create_default_context(
    purpose=ssl.Purpose.SERVER_AUTH,
    cafile='/path/to/ca-bundle.crt'
)
async with aiohttp.ClientSession(
    connector=aiohttp.TCPConnector(ssl=ssl_context)
) as session:
    pass

# Solution 3: Debug SSL issues
ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE  # Use only for development!
```

### Memory Leaks with Long-Running Sessions

**Problem:** Memory growth over time in long-running applications

**Solutions:**
```python
# 1. Always use async with for responses
# ❌ BAD
async def bad_handler(request):
    session = aiohttp.ClientSession()
    response = await session.get('https://example.com')
    data = await response.json()
    return web.Response(text=str(data))

# ✅ GOOD
async def good_handler(request):
    async with aiohttp.ClientSession() as session:
        async with session.get('https://example.com') as response:
            data = await response.json()
            return web.Response(text=str(data))

# 2. Clean up application resources
async def on_cleanup(app):
    """Clean up database connections, caches, etc."""
    if 'db_pool' in app:
        await app['db_pool'].close()
    if 'cache' in app:
        await app['cache'].close()

# 3. Monitor memory usage
import os, resource

async def memory_monitor(request):
    try:
        usage = resource.getrusage(resource.RUSAGE_SELF)
        mem_mb = usage.ru_maxrss / 1024  # Convert to MB (Linux)
        return web.Response(text=f"Memory: {mem_mb:.2f} MB")
    except:
        return web.Response(text="Memory monitoring not available")

# 4. Use garbage collection
import gc

def setup_gc(app):
    """Run garbage collection periodically."""
    @web.middleware
    async def gc_middleware(request, handler):
        response = await handler(request)
        # Run GC for long-running requests
        if request.path.startswith('/api/'):
            gc.collect()
        return response

app.middlewares.append(gc_middleware)

# 5. Close WebSocket connections properly
async def websocket_handler(request):
    ws = web.WebSocketResponse()
    await ws.prepare(request)
    
    try:
        async for msg in ws:
            await ws.send_str(f"Echo: {msg.data}")
    finally:
        # Ensure cleanup
        await ws.close()
    return ws
```

## Best Practices

### Session Management

```python
# ❌ BAD: Create session per request
async def bad_handler(request):
    session = aiohttp.ClientSession()
    async with session.get(url) as response:
        return response

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
# Optimize TCP connector
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
# Always handle exceptions
async def safe_request(url):
    try:
        async with session.get(url) as response:
            response.raise_for_status()  # Raise on 4xx/5xx
            return await response.json()
    except aiohttp.ClientError as e:
        logger.error(f"Request failed: {e}")
        return None
    finally:
        # Ensure response is closed
        pass  # async with handles this
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
- Implement request logging
- Use connection pooling

### Don't:

- Create ClientSession in handler
- Forget to close sessions on shutdown
- Use sync I/O in handlers
- Store large data in memory (use streaming)
- Rely on default timeouts
- Skip authentication middleware
- Use global variables for shared state

## Changelog

### 1.0.0 (2026-05-21)
- Initial skill publication
- Basic web server and client examples
- Routing and middleware patterns
- WebSocket and SSE support
- Testing with pytest-aiohttp
- Common troubleshooting guides
- Performance and best practices

## References

- **Official Documentation**: https://docs.aiohttp.org/
- **GitHub Repository**: https://github.com/aio-libs/aiohttp
- **aio-libs Discord**: https://discord.gg/aio-libs
- **Stack Overflow**: https://stackoverflow.com/questions/tagged/aiohttp
- **PEP 3333**: WSGI Reference (Python Web Server Gateway Interface)
- **PEP 552**: Minimum Version Requirement for JSON Requests
- **RFC 7231**: HTTP/1.1 Semantics and Content
- **RFC 7235**: HTTP Authentication: Basic and Digest Access Authentication
- **Pydantic Documentation**: https://docs.pydantic.dev/
- **pytest-aiohttp**: https://pytest-aiohttp.readthedocs.io/