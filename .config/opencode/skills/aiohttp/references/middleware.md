# Middleware Reference

> This file is loaded on demand from ../SKILL.md.

## Creating Middleware

```python
from aiohttp import web

@web.middleware
async def auth_middleware(request, handler):
    """Authentication middleware."""
    if request.path.startswith('/public'):
        return await handler(request)
    
    auth_header = request.headers.get('Authorization')
    if not auth_header:
        return web.HTTPUnauthorized(text="No auth header")
    
    if not await verify_token(auth_header):
        return web.HTTPForbidden(text="Invalid token")
    
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

## Global Error Handlers

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
        raise e
    except Exception as e:
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

## Common Middleware Patterns

```python
from aiohttp import web
import time

# Request logging middleware
@web.middleware
async def log_middleware(request, handler):
    start = time.time()
    response = await handler(request)
    duration = time.time() - start
    
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
    
    file_handler = logging.FileHandler('app.log')
    file_handler.setFormatter(formatter)
    
    console_handler = logging.StreamHandler()
    json_formatter = logging.Formatter('%(message)s')
    console_handler.setFormatter(json_formatter)
    
    logging.basicConfig(
        level=logging.INFO,
        handlers=[file_handler, console_handler]
    )
```

## Authentication/Authorization Patterns

```python
from aiohttp import web
import jwt
import time
from typing import Optional, Dict, Callable

# JWT Token Validation Middleware
@web.middleware
async def jwt_auth_middleware(request: web.Request, handler: web.Handler) -> web.Response:
    """JWT authentication middleware."""
    
    public_paths = ['/public/*', '/health']
    if any(request.path.startswith(p) for p in public_paths):
        return await handler(request)
    
    auth_header = request.headers.get('Authorization', '')
    
    if not auth_header.startswith('Bearer '):
        return web.json_response(
            {"error": "Missing Authorization header"},
            status=401
        )
    
    token = auth_header[7:]
    
    try:
        payload = jwt.decode(
            token,
            options={"verify_exp": True},
            algorithms=["HS256"],
            audience="your-audience"
        )
        
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
    
    if request.path.startswith('/public'):
        return await handler(request)
    
    auth = request.headers.get('Authorization')
    if not auth:
        return web.Response(
            'Unauthorized',
            headers={'WWW-Authenticate': 'Basic realm="Login"'}
        )
    
    try:
        username, password = auth.split(' ')[1].decode('base64').split(':')
    except:
        return web.Response(
            'Unauthorized',
            headers={'WWW-Authenticate': 'Basic realm="Login"'}
        )
    
    if not verify_credentials(username, password):
        return web.Response(
            'Unauthorized',
            headers={'WWW-Authenticate': 'Basic realm="Login"'}
        )
    
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
    return username == 'admin' and password == 'secret'
```