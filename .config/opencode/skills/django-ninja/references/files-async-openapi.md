# File Uploads, Async Support & OpenAPI Documentation

> This reference file is loaded on demand from the main django-ninja SKILL.md entry.

## File Uploads

### Single File Upload

```python
from ninja import File, NinjaAPI
from django.core.files.uploadedfile import UploadedFile

api = NinjaAPI()

@api.post("/upload")
def upload_file(request, file: UploadedFile = File(...)):
    """Upload a single file."""
    # Validate file
    if file.size > 10 * 1024 * 1024:  # 10MB
        raise HttpError(413, "File too large (max 10MB)")
    
    allowed_types = ['image/jpeg', 'image/png', 'application/pdf']
    if file.content_type not in allowed_types:
        raise HttpError(415, f"File type {file.content_type} not allowed")
    
    # Save file
    file_path = handle_uploaded_file(file)
    
    return {
        "filename": file.name,
        "size": file.size,
        "content_type": file.content_type,
        "path": file_path
    }

def handle_uploaded_file(f):
    import os
    from django.conf import settings
    
    upload_dir = os.path.join(settings.MEDIA_ROOT, 'uploads')
    os.makedirs(upload_dir, exist_ok=True)
    
    file_path = os.path.join(upload_dir, f.name)
    
    with open(file_path, 'wb+') as destination:
        for chunk in f.chunks():
            destination.write(chunk)
    
    return file_path
```

### Multiple File Uploads

```python
from typing import List

@api.post("/upload/multiple")
def upload_files(request, files: List[UploadedFile] = File(...)):
    """Upload multiple files."""
    results = []
    
    for file in files:
        if file.size > 10 * 1024 * 1024:
            continue  # Skip large files
        
        file_path = handle_uploaded_file(file)
        results.append({
            "filename": file.name,
            "size": file.size,
            "path": file_path
        })
    
    return {"uploaded": len(results), "files": results}
```

### File Upload with Schema

```python
from ninja import Schema, File, Form
from typing import Optional

class FileMetadata(Schema):
    title: str
    description: Optional[str] = None
    tags: List[str] = []

@api.post("/upload/with-metadata")
def upload_with_metadata(
    request,
    file: UploadedFile = File(...),
    metadata: FileMetadata = Form(...)
):
    """Upload file with metadata."""
    file_obj = UploadedFile.objects.create(
        file=file,
        title=metadata.title,
        description=metadata.description,
        tags=metadata.tags
    )
    return {"id": file_obj.id, "filename": file.name}
```

## Async Support

### Async Views

```python
from ninja import NinjaAPI
from asgiref.sync import sync_to_async

api = NinjaAPI()

@api.get("/async-posts")
async def async_list_posts(request):
    """Async endpoint for listing posts."""
    # Use async ORM
    posts = await sync_to_async(list)(Post.objects.all()[:10])
    return posts

@api.post("/async-posts")
async def async_create_post(request, payload: PostCreate):
    """Async endpoint for creating posts."""
    @sync_to_async
    def create_post_sync():
        return Post.objects.create(**payload.dict())
    
    post = await create_post_sync()
    return post

# Async with external API
import aiohttp

@api.get("/external-data")
async def fetch_external(request):
    """Fetch data from external API asynchronously."""
    async with aiohttp.ClientSession() as session:
        async with session.get('https://api.example.com/data') as response:
            data = await response.json()
            return data
```

### Async Authentication

```python
from ninja.security import HttpBearer

class AsyncAuthBearer(HttpBearer):
    async def authenticate(self, request, token):
        """Async token validation."""
        user = await validate_token_async(token)
        return user

async def validate_token_async(token):
    """Validate JWT token asynchronously."""
    import jwt
    from django.conf import settings
    
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=['HS256'])
        user = await sync_to_async(User.objects.get)(id=payload['user_id'])
        return user
    except Exception:
        return None

api = NinjaAPI(auth=AsyncAuthBearer())

@api.get("/async-protected")
async def async_protected(request):
    return {"user": request.auth.username}
```

## OpenAPI Documentation

### Swagger UI

```python
from ninja import NinjaAPI

api = NinjaAPI(
    title="My API",
    description="API documentation",
    version="1.0.0",
    docs_url="/docs/",  # Swagger UI at /api/docs/
    openapi_url="/openapi.json"  # OpenAPI schema at /api/openapi.json
)

# Access at: /api/docs/
# OpenAPI schema at: /api/openapi.json
```

### Customizing Documentation

```python
from ninja import Schema
from typing import Optional

class PostSchema(Schema):
    id: int
    title: str
    body: str
    
    class Config:
        # OpenAPI schema customization
        schema_extra = {
            "example": {
                "id": 1,
                "title": "My First Post",
                "body": "This is the content of my first post."
            }
        }

@api.get(
    "/posts/{post_id}",
    response=PostSchema,
    summary="Get a post by ID",
    description="Retrieves a specific post by its ID. Returns 404 if not found.",
    tags=["posts"],
    operation_id="get_post_by_id"
)
def get_post(request, post_id: int):
    """
    Retrieve a post by ID.
    
    Args:
        post_id: The unique identifier of the post
        
    Returns:
        PostSchema: The requested post
        
    Raises:
        HttpError: 404 if post not found
    """
    post = get_object_or_404(Post, id=post_id)
    return post

# Tags for grouping endpoints
api = NinjaAPI()

posts_tags = ["posts"]
users_tags = ["users"]

@api.get("/posts", tags=posts_tags)
def list_posts(request):
    pass

@api.get("/users", tags=users_tags)
def list_users(request):
    pass
```

### Response Examples

```python
from ninja import Schema

class PostSchema(Schema):
    id: int
    title: str
    body: str

@api.get(
    "/posts/{post_id}",
    response={
        200: PostSchema,
        404: ErrorSchema
    },
    examples={
        200: {"id": 1, "title": "Post Title", "body": "Post content"},
        404: {"error": "Post not found"}
    }
)
def get_post_with_examples(request, post_id: int):
    pass
```