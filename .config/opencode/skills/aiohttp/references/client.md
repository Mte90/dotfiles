# Client & Performance Reference

> This file is loaded on demand from ../SKILL.md.

## Basic Client Usage

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

## Client Configuration

```python
import aiohttp

async def configured_client():
    # With base URL
    async with aiohttp.ClientSession(
        base_url='https://api.example.com',
        headers={'Authorization': 'Bearer token'}
    ) as session:
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

## Client Request Options

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

## Client Response

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

## Client WebSocket

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

## Keepalive

```python
from aiohttp import web

# Keep connections alive
app = web.Application(
    client_max_cache_size=1000
)

# Client keepalive
async with aiohttp.ClientSession() as session:
    for _ in range(100):
        async with session.get('https://api.example.com/data'):
            pass
```

## Streaming

```python
from aiohttp import web

async def upload_handler(request):
    """Handle streaming upload."""
    reader = request.content
    
    with open('uploaded.file', 'wb') as f:
        while True:
            chunk = await reader.read(1024 * 1024)
            if not chunk:
                break
            f.write(chunk)
    
    return web.Response(text="Uploaded")
```

## Compression

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