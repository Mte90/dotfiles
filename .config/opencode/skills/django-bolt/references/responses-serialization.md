<!-- This file is loaded on demand from frameworks/django-bolt/SKILL.md -->

## Responses

### JSON Response

```python
from django_bolt.response import Json

@api.get("/json")
async def json_handler(request):
    return Json({"key": "value"})

# Or shorthand (automatically JSON serialized)
@api.get("/auto-json")
async def auto_json_handler(request):
    return {"key": "value"}
```

### HTML Response

```python
from django_bolt.response import Html

@api.get("/html")
async def html_handler(request):
    return Html("<h1>Hello World</h1>")
```

### Streaming Response (SSE)

```python
from django_bolt.response import StreamingResponse

async def event_stream():
    for i in range(10):
        yield f"data: message {i}\n\n"

@api.get("/stream")
async def stream_handler(request):
    return StreamingResponse(event_stream())
```

### EventSourceResponse (v0.7.5+)

Server-Sent Events with automatic reconnection support:

```python
from django_bolt.response import EventSourceResponse

async def news_feed():
    while True:
        yield {"event": "update", "data": {"news": "breaking"}}
        await asyncio.sleep(5)

@api.get("/news")
async def news_handler(request):
    return EventSourceResponse(news_feed())
```

### Per-Chunk Compression (v0.8.1+)

Automatic compression per chunk (br/gzip/zstd):

```python
@api.get("/large-stream")
async def large_stream(request):
    async def generate():
        for i in range(1000):
            yield f"data: {i}\n\n"
    return StreamingResponse(generate(), compress=True)
```

### Union Return Types (v0.8.1+)

```python
@api.get("/conditional")
async def conditional() -> dict[str, str] | list[int]:
    if some_condition:
        return {"status": "ok"}
    return [1, 2, 3]
```

### HTTPException with Body (v0.11.0+)

```python
from django_bolt.exceptions import HTTPException

raise HTTPException(
    status_code=400,
    body={"error": "validation_failed", "fields": {"email": "Invalid"}}
)
```

### File Response

```python
from django_bolt.response import FileResponse

@api.get("/download")
async def download_handler(request):
    return FileResponse(
        path="/path/to/file.pdf",
        filename="document.pdf",
        content_type="application/pdf"
    )
```

### Redirect Response

```python
from django_bolt.response import Redirect

@api.get("/redirect")
async def redirect_handler(request):
    return Redirect(url="https://example.com", status=302)
```

---

## Serializers (msgspec)

msgspec provides **5-10x faster** serialization than Python's stdlib.

### Basic Struct

```python
import msgspec

class UserSchema(msgspec.Struct):
    id: int
    username: str
    email: str
    is_active: bool = True

@api.post("/users")
async def create_user(request, body: UserSchema):
    user = await User.objects.acreate(
        username=body.username,
        email=body.email,
        is_active=body.is_active
    )
    return {"id": user.id}
```

### Loading Plans (v0.10.2+)

Auto `select_related`/`prefetch_related`/`annotate` from Serializer fields:

```python
from django_bolt.serializers import ModelSerializer, loading_plan

class AuthorSerializer(ModelSerializer):
    class Meta:
        model = Author
        fields = ["id", "name"]

class ArticleSerializer(ModelSerializer):
    author: AuthorSchema  # Auto select_related("author")
    
    class Meta:
        model = Article
        fields = ["id", "title", "author"]
@api.get("/articles")
@loading_plan(ArticleSerializer)  # Auto-optimizes query
async def list_articles():
    return Article.objects.all()
```

### from_models() / afrom_models() (v0.10.2+)

```python
from django_bolt.serializers import from_models, afrom_models

class ArticleSchema(from_models(Article)):
    author_name: str  # Derived field

@api.get("/articles")
async def list_articles():
    articles = await Article.objects.all().alist()
    return [afrom_models(ArticleSchema, a) for a in articles]
```

### Nested() Removed in v0.11.0

Use plain type hints instead:

```python
# Before v0.11.0 (removed)
# author: Nested(AuthorSerializer)

# v0.11.0+ (plain type hint)
class ArticleSerializer(ModelSerializer):
    author: AuthorSerializer  # Direct type hint
```

### With Validation

```python
import msgspec

class UserCreateSchema(msgspec.Struct):
    username: str
    email: str
    password: str
    
    def __post_init__(self):
        if len(self.password) < 8:
            raise msgspec.ValidationError("Password must be at least 8 characters")
        if "@" not in self.email:
            raise msgspec.ValidationError("Invalid email format")
```

### Nested Structures

```python
class AddressSchema(msgspec.Struct):
    street: str
    city: str
    zip_code: str
    country: str

class UserSchema(msgspec.Struct):
    id: int
    username: str
    address: AddressSchema | None = None

@api.get("/users/{user_id}")
async def get_user_with_address(user_id: int):
    user = await User.objects.aget(id=user_id)
    return {
        "id": user.id,
        "username": user.username,
        "address": {
            "street": user.street,
            "city": user.city,
            "zip_code": user.zip_code,
            "country": user.country
        } if user.street else None
    }
```

---

## Pagination

Django-Bolt provides three pagination styles for handling large datasets efficiently.

### PageNumber Pagination

```python
from django_bolt import BoltAPI, PageNumberPagination, paginate

api = BoltAPI()

class ArticlePagination(PageNumberPagination):
    page_size = 20
    max_page_size = 100
    page_size_query_param = "page_size"

@api.get("/articles")
@paginate(ArticlePagination)
async def list_articles(request) -> list[ArticleSerializer]:
    return Article.objects.all()
```

Response:

```json
{
    "count": 150,
    "page": 1,
    "page_size": 20,
    "total_pages": 8,
    "has_next": true,
    "has_previous": false,
    "next_page": 2,
    "previous_page": null,
    "items": [...]
}
```

### LimitOffset Pagination

```python
from django_bolt import LimitOffsetPagination, paginate

@api.get("/articles")
@paginate(LimitOffsetPagination)
async def list_articles(request):
    return Article.objects.all()
```

Query: `/articles?limit=10&offset=20`

### Cursor Pagination

```python
from django_bolt import CursorPagination, paginate

class ArticlePagination(CursorPagination):
    page_size = 20
    ordering = "-created_at"

@api.get("/articles")
@paginate(ArticlePagination)
async def list_articles(request) -> list[ArticleSerializer]:
    return Article.objects.all()
```

Query: `/articles?cursor=eyJ2IjoxMDB9`

### Manual Pagination

```python
from django_bolt import Query

@api.get("/users")
async def list_users(
    request,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    offset = (page - 1) * page_size
    users = User.objects.all().order_by("id")
    
    total = await users.acount()
    items = await users[offset:offset + page_size].alist()
    
    return {
        "items": [{"id": u.id, "username": u.username} for u in items],
        "total": total,
        "page": page,
        "page_size": page_size,
        "pages": (total + page_size - 1) // page_size,
    }
```

### ViewSet with Pagination

```python
from django_bolt.views import ViewSet

@api.viewset("/articles")
class ArticleViewSet(ViewSet):
    queryset = Article.objects.all()

    @paginate(ArticlePagination)
    async def list(self, request) -> list[ArticleSerializer]:
        return await self.get_queryset()
```

---

## Request Object

Access the full request using the `request` parameter.

### Request Properties

```python
@api.get("/info")
async def request_info(request):
    return {
        "method": request.get("method"),
        "path": request.get("path"),
        "query": request.get("query"),
        "params": request.get("params"),
        "headers": request.get("headers"),
        "body": request.get("body", b""),
        "context": request.get("context"),
    }
```

### Type-Safe Request

```python
from django_bolt import Request
from django_bolt.auth import JWTAuthentication, IsAuthenticated

@api.get("/profile", auth=[JWTAuthentication()], guards=[IsAuthenticated()])
async def profile(request: Request):
    user = await request.auser()
    return {"user_id": request.user.id, "username": request.user.username}
```

### Headers

```python
from typing import Annotated
from django_bolt.param_functions import Header

@api.get("/auth")
async def check_auth(
    authorization: Annotated[str, Header(alias="Authorization")]
):
    return {"auth": authorization}

# Optional headers
@api.get("/optional-header")
async def optional_header(
    custom: Annotated[str | None, Header(alias="X-Custom")] = None
):
    return {"custom": custom}
```

### Cookies

```python
from typing import Annotated
from django_bolt.param_functions import Cookie

@api.get("/session")
async def get_session(
    session_id: Annotated[str, Cookie(alias="sessionid")]
):
    return {"session_id": session_id}
```

### Sessions

```python
from django_bolt import BoltAPI, Request
from django.contrib.auth import alogin, alogout
from datetime import datetime

api = BoltAPI(django_middleware=True)

@api.post("/login")
async def login(request: Request, username: str, password: str):
    user = await User.objects.filter(username=username).afirst()
    if user and user.check_password(password):
        await alogin(request, user)
        await request.session.aset("login_time", str(datetime.now()))
        return {"status": "ok"}
    return {"status": "error"}

@api.get("/profile")
async def profile(request: Request):
    user = await request.auser()
    if not user.is_authenticated:
        return {"error": "not logged in"}
    return {
        "username": user.username,
        "login_time": await request.session.aget("login_time"),
    }

@api.post("/logout")
async def logout(request: Request):
    await alogout(request)
    return {"status": "logged out"}
```

### Session Async Methods

| Method | Description |
|--------|-------------|
| `await session.aget(key, default)` | Get a session value |
| `await session.aset(key, value)` | Set a session value |
| `await session.apop(key, default)` | Remove and return a value |
| `await session.akeys()` | Get all session keys |
| `await session.aitems()` | Get all key-value pairs |
| `await session.aflush()` | Delete session and create new |

---

## Dependency Injection

Django-Bolt provides dependency injection using the `Depends` marker.

### Basic Usage

```python
from django_bolt import BoltAPI, Depends

api = BoltAPI()

async def get_pagination(page: int = 1, limit: int = 20):
    return {"page": page, "limit": limit, "offset": (page - 1) * limit}

@api.get("/items")
async def list_items(pagination=Depends(get_pagination)):
    return {"pagination": pagination}
```

### Request Access in Dependencies

```python
async def get_current_user(request):
    user_id = request.get("context", {}).get("user_id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return await User.objects.aget(id=user_id)

@api.get("/profile")
async def get_profile(user=Depends(get_current_user)):
    return {"id": user.id, "username": user.username}
```

### Authentication Dependency

```python
from django_bolt.auth import get_current_user

@api.get("/me")
async def me(user=Depends(get_current_user)):
    return {
        "id": user.id,
        "username": user.username,
        "email": user.email
    }
```

### Dependency Caching

```python
call_count = 0

async def expensive_operation(request):
    global call_count
    call_count += 1
    return {"count": call_count}

@api.get("/test")
async def test(
    dep1=Depends(expensive_operation),
    dep2=Depends(expensive_operation)
):
    # expensive_operation is called ONCE, result is reused
    return {"dep1": dep1, "dep2": dep2}

# Disable caching
@api.get("/fresh")
async def fresh(dep=Depends(some_dependency, use_cache=False)):
    return dep
```

### Nested Dependencies

```python
async def get_settings(request):
    return await Settings.objects.afirst()

async def get_feature_flags(settings=Depends(get_settings)):
    return {
        "new_ui": settings.enable_new_ui,
        "beta": settings.beta_features,
    }

@api.get("/features")
async def features(flags=Depends(get_feature_flags)):
    return flags
```

### Class-Based Dependencies

```python
class DatabaseSession:
    def __init__(self, request):
        self.request = request
        self.connection = None

    async def __aenter__(self):
        self.connection = await get_connection()
        return self.connection

    async def __aexit__(self, *args):
        if self.connection:
            await self.connection.close()

@api.get("/data")
async def get_data(db=Depends(DatabaseSession)):
    async with db:
        pass
```