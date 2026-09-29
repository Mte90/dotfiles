# Async Client

This file is loaded on demand from ../SKILL.md.

## AsyncClient Setup

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

## Concurrent Requests

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

## Streaming

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