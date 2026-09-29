# Testing & Lifespan Reference

> This file is loaded on demand from ../SKILL.md.

## Application Signals

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

## Lifespan Context

```python
from aiohttp import web

@web.lifespanContext
async def lifespan(app):
    """Context manager for application lifespan."""
    app['db'] = await create_db_pool()
    app['cache'] = await create_cache()
    
    yield
    
    await app['cache'].close()
    await app['db'].close()

app = web.Application(lifespan=lifespan)
```

## Signals

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

## Test Client

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

## pytest-aiohttp with Async Fixtures

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
        if session:
            await session.close()
```