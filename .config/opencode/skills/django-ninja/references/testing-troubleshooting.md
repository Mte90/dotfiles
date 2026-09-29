# Testing & Common Issues

> This reference file is loaded on demand from the main django-ninja SKILL.md entry.

## Testing

### pytest with Django Ninja

```python
# tests/test_api.py
import pytest
from django.test import Client
from ninja.testing import TestClient
from myapp.api import api

@pytest.fixture
def api_client():
    return TestClient(api)

def test_list_posts(api_client):
    response = api_client.get("/posts")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_create_post(api_client):
    data = {
        "title": "Test Post",
        "slug": "test-post",
        "body": "Test content",
        "status": "draft"
    }
    response = api_client.post("/posts", json=data)
    assert response.status_code == 200
    result = response.json()
    assert result["title"] == "Test Post"
    assert result["id"] is not None

def test_get_post(api_client):
    # First create a post
    create_response = api_client.post("/posts", json={
        "title": "Test",
        "slug": "test",
        "body": "Content"
    })
    post_id = create_response.json()["id"]
    
    # Then retrieve it
    response = api_client.get(f"/posts/{post_id}")
    assert response.status_code == 200
    assert response.json()["title"] == "Test"

def test_update_post(api_client):
    # Create post
    create = api_client.post("/posts", json={
        "title": "Original",
        "slug": "original",
        "body": "Content"
    })
    post_id = create.json()["id"]
    
    # Update
    response = api_client.patch(f"/posts/{post_id}", json={
        "title": "Updated"
    })
    assert response.status_code == 200
    assert response.json()["title"] == "Updated"

def test_delete_post(api_client):
    # Create post
    create = api_client.post("/posts", json={
        "title": "To Delete",
        "slug": "to-delete",
        "body": "Content"
    })
    post_id = create.json()["id"]
    
    # Delete
    response = api_client.delete(f"/posts/{post_id}")
    assert response.status_code == 200
    
    # Verify deleted
    get_response = api_client.get(f"/posts/{post_id}")
    assert get_response.status_code == 404

def test_validation_error(api_client):
    response = api_client.post("/posts", json={
        "title": "Test"
        # Missing required fields
    })
    assert response.status_code == 422
```

### Testing Authentication

```python
from ninja.testing import TestClient
from myapp.api import api, AuthBearer

@pytest.fixture
def authenticated_client():
    client = TestClient(api)
    # Mock authentication
    user = User.objects.create_user(username="testuser", password="testpass")
    client.force_authenticate(user)
    return client

def test_authenticated_endpoint(authenticated_client):
    response = authenticated_client.get("/profile")
    assert response.status_code == 200
    assert response.json()["username"] == "testuser"

def test_unauthenticated():
    client = TestClient(api)
    response = client.get("/profile")
    assert response.status_code == 401

# Testing with JWT
def test_jwt_authentication():
    client = TestClient(api)
    
    # Login first
    login_response = client.post("/login", json={
        "username": "testuser",
        "password": "testpass"
    })
    token = login_response.json()["access"]
    
    # Use token
    response = client.get(
        "/profile",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
```

## Common Issues

### Issue: Validation Errors Not Showing

**Problem**: Validation errors return generic 422 without details.

**Solution**:
```python
# Check error renderer configuration
api = NinjaAPI()

# Default error renderer shows details
# Custom error renderer for more control
def custom_error_renderer(errors):
    return {
        "success": False,
        "errors": [
            {"field": e["loc"][-1], "message": e["msg"]}
            for e in errors
        ]
    }

api = NinjaAPI(error_renderer=custom_error_renderer)
```

### Issue: Authentication Not Working

**Problem**: request.auth is None in protected endpoints.

**Solution**:
```python
# Check auth decorator placement
@api.get("/protected", auth=AuthBearer())  # Correct
def protected(request):
    return {"user": request.auth.username}

# vs

@api.get("/protected")  # Wrong - no auth
@auth_required  # This doesn't work
def protected(request):
    pass
```

### Issue: File Upload Size Limit

**Problem**: Large file uploads fail silently.

**Solution**:
```python
# settings.py
DATA_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024  # 10MB
FILE_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024  # 10MB

# In the endpoint
@api.post("/upload")
def upload_file(request, file: UploadedFile = File(...)):
    if file.size > 10 * 1024 * 1024:
        raise HttpError(413, "File too large")
```

### Issue: CORS Errors

**Problem**: Frontend can't access API due to CORS.

**Solution**:
```python
# Install django-cors-headers
pip install django-cors-headers

# settings.py
INSTALLED_APPS = [
    # ...
    'corsheaders',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # Add at the top
    # ...
]

CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "https://myapp.com",
]

# Or for development
CORS_ALLOW_ALL_ORIGINS = True  # Only in development!
```

### Issue: Nested Schema Serialization

**Problem**: Nested schemas not serializing correctly.

**Solution**:
```python
# Make sure nested schemas are properly defined
class AuthorSchema(ModelSchema):
    class Config:
        model = User
        model_fields = ['id', 'username']

class PostSchema(ModelSchema):
    author: AuthorSchema  # Must be defined before use
    
    class Config:
        model = Post
        model_fields = ['id', 'title', 'body']

# For many-to-many
class PostWithCategories(ModelSchema):
    categories: List[str]  # Or List[CategorySchema]
    
    class Config:
        model = Post
        model_fields = ['id', 'title']
    
    @staticmethod
    def resolve_categories(obj):
        return [c.name for c in obj.categories.all()]
```