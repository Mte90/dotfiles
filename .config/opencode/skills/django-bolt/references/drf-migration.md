# Deep Dive: Loaded on demand from django-bolt/SKILL.md

## Comparison with DRF/Django Ninja

### When to Choose Django Bolt

| Feature | Django Bolt | Django REST Framework | Django Ninja |
|---------|-------------|----------------------|--------------|
| **Performance** | ~188k RPS | ~10-15k RPS | ~50-70k RPS |
| **Python GIL** | Bypassed via processes | Blocked | Blocked |
| **Django ORM** | Full async | Sync only | Full async |
| **Type Safety** | Full (msgspec) | Partial (serializers) | Full (Pydantic) |
| **Django Admin** | Compatible | Compatible | Compatible |
| **Django Packages** | Most work | All work | Most work |
| **Learning Curve** | Low | Low | Medium |
| **WebSocket** | Built-in | Via channels | Via channels |

### Choose Django Bolt When:

- You need maximum performance (300k+ RPS)
- You want to keep using Django ORM without async wrappers
- You're building new APIs and performance matters
- You want to bypass Python's GIL limitations
- You prefer msgspec over Pydantic for validation
- You want to incrementally migrate from DRF

### Choose Django REST Framework When:

- You have an existing DRF codebase
- You need extensive third-party packages
- You're new to async programming
- You need Django REST Framework's browserable API

### Choose Django Ninja When:

- You prefer Pydantic for validation
- You're building new APIs from scratch
- You need a more Pythonic async experience
- You want better IDE support via Pydantic

---

## Migration from DRF

Step-by-step guide to migrate Django REST Framework views to Django Bolt.

### Step 1: Install Django Bolt

```bash
pip install django-bolt
```

Add to `INSTALLED_APPS`:

```python
INSTALLED_APPS = [
    ...
    "django_bolt"
    ...
]
```

### Step 2: Convert Function-Based Views

**Before (DRF):**

```python
# views.py (DRF)
from rest_framework.decorators import api_view
from rest_framework.response import Response

@api_view(["GET", "POST"])
def user_list(request):
    if request.method == "GET":
        users = User.objects.all()
        serializer = UserSerializer(users, many=True)
        return Response(serializer.data)

    serializer = UserSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=201)
    return Response(serializer.errors, status=400)
```

**After (Django Bolt):**

```python
# api.py (Django Bolt)
from django_bolt import BoltAPI
import msgspec

api = BoltAPI()

class UserSchema(msgspec.Struct):
    id: int
    username: str
    email: str

@api.get("/users")
async def list_users():
    users = await User.objects.all()
    return [{"id": u.id, "username": u.username, "email": u.email} for u in users]

@api.post("/users")
async def create_user(data: UserSchema):
    user = await User.objects.acreate(
        username=data.username,
        email=data.email
    )
    return {"id": user.id, "username": user.username}, 201
```

### Step 3: Convert Class-Based Views

**Before (DRF):**

```python
# views.py (DRF)
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .serializers import UserSerializer

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]
```

**After (Django Bolt):**

```python
# api.py (Django Bolt)
from django_bolt import BoltAPI, ViewSet
from django_bolt.auth import JWTAuthentication, IsAuthenticated
from django.contrib.auth import get_user_model

User = get_user_model()
api = BoltAPI()

@api.viewset("/users", auth=[JWTAuthentication()], guards=[IsAuthenticated()])
class UserViewSet(ViewSet):
    async def list(self, request):
        users = await User.objects.all()
        return [{"id": u.id, "username": u.username} for u in users]

    async def retrieve(self, request, pk: int):
        user = await User.objects.aget(id=pk)
        return {"id": user.id, "username": user.username}

    async def create(self, request):
        data = await request.json()
        user = await User.objects.acreate(**data)
        return {"id": user.id}, 201

    async def destroy(self, request, pk: int):
        await User.objects.filter(id=pk).adelete()
        return {"deleted": True}
```

### Step 4: Convert Serializers

**Before (DRF):**

```python
# serializers.py (DRF)
from rest_framework import serializers
from .models import Article

class ArticleSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source="author.username", read_only=True)

    class Meta:
        model = Article
        fields = ["id", "title", "content", "author", "author_name", "created_at"]
```

**After (Django Bolt):**

```python
# schemas.py (Django Bolt)
import msgspec

class AuthorSchema(msgspec.Struct):
    id: int
    username: str

class ArticleSchema(msgspec.Struct):
    id: int
    title: str
    content: str
    author: AuthorSchema
    created_at: str
```

### Step 5: Convert URLs

**Before (DRF):**

```python
# urls.py (DRF)
from rest_framework.routers import DefaultRouter
from .views import UserViewSet

router = DefaultRouter()
router.register(r"users", UserViewSet)
urlpatterns = router.urls
```

**After (Django Bolt):**

```python
# myproject/urls.py
from django.urls import path
from myapp.api import api

urlpatterns = [
    path("api/", api.urls),
]
```

### Step 6: Running the Server

**Before (DRF):**

```bash
# Development
python manage.py runserver

# Production (with gunicorn)
gunicorn myproject.wsgi --workers 4
```

**After (Django Bolt):**

```bash
# Development
python manage.py runbolt --dev

# Production (standalone, no gunicorn needed)
python manage.py runbolt --processes 4
```

### Migration Checklist

- [ ] Install django-bolt and add to INSTALLED_APPS
- [ ] Convert function-based views to Django Bolt handlers
- [ ] Convert class-based views to ViewSets
- [ ] Replace DRF serializers with msgspec structs
- [ ] Update URL configuration
- [ ] Test authentication (JWT, API key)
- [ ] Test file uploads if applicable
- [ ] Run load tests to verify performance
- [ ] Remove DRF dependencies when ready

---