<!-- This file is loaded on demand from frameworks/django-bolt/SKILL.md -->

## WebSockets

Django-Bolt provides WebSocket support for real-time bidirectional communication.

### Basic WebSocket Endpoint

```python
from django_bolt import BoltAPI, WebSocket

api = BoltAPI()

@api.websocket("/ws/echo")
async def echo(websocket: WebSocket):
    await websocket.accept()
    async for message in websocket.iter_text():
        await websocket.send_text(f"Echo: {message}")
```

### Sending Messages

```python
# Text messages
await websocket.send_text("Hello, World!")

# Binary messages
await websocket.send_bytes(b"\x00\x01\x02\x03")

# JSON messages
await websocket.send_json({"type": "message", "data": "Hello"})
```

### Receiving Messages

```python
# Text messages
message = await websocket.receive_text()
async for message in websocket.iter_text():
    print(f"Received: {message}")

# Binary messages
data = await websocket.receive_bytes()

# JSON messages
data = await websocket.receive_json()
async for data in websocket.iter_json():
    print(f"Received: {data}")
```

### Path and Query Parameters

```python
# Path parameters
@api.websocket("/ws/room/{room_id}")
async def room(websocket: WebSocket, room_id: str):
    await websocket.accept()
    async for message in websocket.iter_text():
        await websocket.send_text(f"[{room_id}] {message}")

# Query parameters (for authentication)
@api.websocket("/ws/connect")
async def connect(websocket: WebSocket, token: str | None = None):
    if token != "secret":
        await websocket.close(code=4001, reason="Invalid token")
        return
    await websocket.accept()
```

### Closing Connections

```python
from django_bolt import WebSocketDisconnect

@api.websocket("/ws")
async def handler(websocket: WebSocket):
    await websocket.accept()
    try:
        async for message in websocket.iter_text():
            await websocket.send_text(message)
    except WebSocketDisconnect:
        print("Client disconnected")

# Close from server
await websocket.close(code=1000, reason="Normal closure")
```

### Authentication

```python
from django_bolt.auth import JWTAuthentication, IsAuthenticated

@api.websocket(
    "/ws/protected",
    auth=[JWTAuthentication()],
    guards=[IsAuthenticated()]
)
async def protected_ws(websocket: WebSocket):
    await websocket.accept()
    user = websocket.user
    async for message in websocket.iter_text():
        await websocket.send_json({"user": user.id, "message": message})
```

### Graceful Shutdown

On shutdown, connections close with code 1012 (Service Restart).

---

## File Uploads

Django-Bolt provides the `UploadFile` class for handling file uploads with Django integration.

### Basic File Upload

```python
from typing import Annotated
from django_bolt import UploadFile
from django_bolt.params import File

@api.post("/upload")
async def upload(file: Annotated[UploadFile, File()]):
    content = await file.read()
    return {
        "filename": file.filename,
        "size": file.size,
        "content_type": file.content_type,
    }
```

### UploadFile Properties

| Property | Type | Description |
|----------|------|-------------|
| `filename` | str | Original filename |
| `content_type` | str | MIME type |
| `size` | int | Size in bytes |
| `file` | Django File | Django File object for FileField |
| `headers` | dict | Multipart headers |

### File Validation

```python
from django_bolt import FileSize

@api.post("/upload")
async def upload(
    file: Annotated[UploadFile, File(
        max_size=FileSize.MB_10,
        min_size=1024,
        allowed_types=["image/*", "application/pdf"],
    )]
):
    return {"filename": file.filename}
```

### FileSize Enum

```python
from django_bolt import FileSize

File(max_size=FileSize.KB_1)    # 1 KB
File(max_size=FileSize.MB_1)    # 1 MB
File(max_size=FileSize.MB_5)    # 5 MB
File(max_size=FileSize.MB_10)   # 10 MB
File(max_size=FileSize.MB_50)   # 50 MB
```

### Multiple File Uploads

```python
@api.post("/upload-multiple")
async def upload_multiple(
    files: Annotated[list[UploadFile], File(
        max_files=5,
        max_size=FileSize.MB_5,
    )]
):
    return {
        "count": len(files),
        "filenames": [f.filename for f in files],
    }
```

### Saving to Django FileField/ImageField

```python
from myapp.models import Document, UserProfile

# FileField
@api.post("/documents")
async def create_document(
    title: Annotated[str, Form()],
    upload: Annotated[UploadFile, File(max_size=FileSize.MB_10)],
):
    doc = Document(title=title)
    doc.file = upload.file
    await doc.asave()
    return {"id": doc.id, "url": doc.file.url}

# ImageField
@api.post("/avatar")
async def upload_avatar(
    avatar: Annotated[UploadFile, File(
        max_size=FileSize.MB_5,
        allowed_types=["image/*"],
    )],
    request,
):
    profile = await UserProfile.objects.aget(user=request.user)
    profile.avatar = avatar.file
    await profile.asave()
    return {"avatar_url": profile.avatar.url}
```

### Global Upload Settings

```python
# settings.py
from django_bolt import FileSize

BOLT_MAX_UPLOAD_SIZE = FileSize.MB_10
BOLT_MEMORY_SPOOL_THRESHOLD = 5 * 1024 * 1024
```