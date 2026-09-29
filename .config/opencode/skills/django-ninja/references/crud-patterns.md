# CRUD Operations

> This reference file is loaded on demand from the main django-ninja SKILL.md entry.

## CRUD Operations

### Complete CRUD Example

```python
from ninja import NinjaAPI, ModelSchema, Schema
from django.shortcuts import get_object_or_404
from typing import List, Optional

api = NinjaAPI()

# Schemas
class CategoryOut(ModelSchema):
    class Config:
        model = Category
        model_fields = ['id', 'name', 'slug']

class PostOut(ModelSchema):
    author: UserSchema
    categories: List[CategoryOut]
    
    class Config:
        model = Post
        model_fields = ['id', 'title', 'slug', 'body', 'status', 'publish']

class PostIn(Schema):
    title: str
    slug: str
    body: str
    status: str = 'draft'
    category_ids: List[int] = []

class PostUpdate(Schema):
    title: Optional[str] = None
    slug: Optional[str] = None
    body: Optional[str] = None
    status: Optional[str] = None
    category_ids: Optional[List[int]] = None

# List
@api.get("/posts", response=List[PostOut])
def list_posts(request):
    return Post.objects.select_related('author').prefetch_related('categories').all()

# Retrieve
@api.get("/posts/{post_id}", response=PostOut)
def get_post(request, post_id: int):
    post = get_object_or_404(
        Post.objects.select_related('author').prefetch_related('categories'),
        id=post_id
    )
    return post

# Create
@api.post("/posts", response=PostOut)
def create_post(request, payload: PostIn):
    post = Post(
        title=payload.title,
        slug=payload.slug,
        body=payload.body,
        status=payload.status,
        author=request.user
    )
    post.save()
    
    if payload.category_ids:
        post.categories.set(payload.category_ids)
    
    return post

# Full Update
@api.put("/posts/{post_id}", response=PostOut)
def update_post(request, post_id: int, payload: PostIn):
    post = get_object_or_404(Post, id=post_id)
    
    post.title = payload.title
    post.slug = payload.slug
    post.body = payload.body
    post.status = payload.status
    post.save()
    
    post.categories.set(payload.category_ids)
    
    return post

# Partial Update
@api.patch("/posts/{post_id}", response=PostOut)
def partial_update_post(request, post_id: int, payload: PostUpdate):
    post = get_object_or_404(Post, id=post_id)
    
    update_data = payload.dict(exclude_unset=True)
    
    if 'category_ids' in update_data:
        category_ids = update_data.pop('category_ids')
        post.categories.set(category_ids)
    
    for attr, value in update_data.items():
        setattr(post, attr, value)
    
    post.save()
    return post

# Delete
@api.delete("/posts/{post_id}")
def delete_post(request, post_id: int):
    post = get_object_or_404(Post, id=post_id)
    post.delete()
    return {"success": True, "id": post_id}
```

### Bulk Operations

```python
from ninja import Schema
from typing import List

class BulkPostCreate(Schema):
    posts: List[PostIn]

@api.post("/posts/bulk", response=List[PostOut])
def bulk_create_posts(request, payload: BulkPostCreate):
    """Create multiple posts at once."""
    created_posts = []
    
    for post_data in payload.posts:
        post = Post.objects.create(
            **post_data.dict(exclude={'category_ids'}),
            author=request.user
        )
        if post_data.category_ids:
            post.categories.set(post_data.category_ids)
        created_posts.append(post)
    
    return created_posts

@api.post("/posts/bulk-delete")
def bulk_delete_posts(request, ids: List[int]):
    """Delete multiple posts."""
    deleted, _ = Post.objects.filter(id__in=ids).delete()
    return {"deleted": deleted}
```