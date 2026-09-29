# Troubleshooting Reference

> This file is loaded on demand from ../SKILL.md.

## Connection Refused

**Problem:** `aiohttp.connector.TCPConnector._resolve_host() raised for Connection refused`

**Solutions:**
1. Ensure the server is running on the expected port
2. Check firewall settings
3. Verify host address is correct

```python
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
                await asyncio.sleep(2 ** attempt)
            else:
                raise
```

## Timeout Issues

**Problem:** Request hangs indefinitely

**Solutions:**
```python
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

## SSL Errors

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
ssl_context.verify_mode = ssl.CERT_NONE
```

## Memory Leaks with Long-Running Sessions

**Problem:** Memory growth over time in long-running applications

**Solutions:**
```python
# 1. Always use async with for responses
# ✅ GOOD
async def good_handler(request):
    async with aiohttp.ClientSession() as session:
        async with session.get('https://example.com') as response:
            data = await response.json()
            return web.Response(text=str(data))

# 2. Clean up application resources
async def on_cleanup(app):
    if 'db_pool' in app:
        await app['db_pool'].close()
    if 'cache' in app:
        await app['cache'].close()

# 3. Monitor memory usage
import os, resource

async def memory_monitor(request):
    try:
        usage = resource.getrusage(resource.RUSAGE_SELF)
        mem_mb = usage.ru_maxrss / 1024
        return web.Response(text=f"Memory: {mem_mb:.2f} MB")
    except:
        return web.Response(text="Memory monitoring not available")

# 4. Use garbage collection
import gc

def setup_gc(app):
    @web.middleware
    async def gc_middleware(request, handler):
        response = await handler(request)
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
        await ws.close()
    return ws
```