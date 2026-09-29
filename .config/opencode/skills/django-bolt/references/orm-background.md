<!-- This file is loaded on demand from frameworks/django-bolt/SKILL.md -->

## Django ORM Patterns

### Async QuerySet Operations

```python
from django_bolt import BoltAPI

api = BoltAPI()

# Async iteration
@api.get("/posts")
async def list_posts(request):
    posts = []
    async for post in Post.objects.all().order_by("-created_at")[:20]:
        posts.append({"id": post.id, "title": post.title})
    return {"posts": posts}

# select_related / prefetch_related
@api.get("/articles/{article_id}")
async def get_article(article_id: int):
    article = await Article.objects.select_related("author", "category").aget(id=article_id)
    return {
        "id": article.id,
        "title": article.title,
        "author": article.author.name,
        "category": article.category.name,
    }

# Bulk operations
@api.post("/articles/bulk")
async def bulk_create_articles(request):
    articles = await Article.objects.abulk_create([
        Article(title=f"Article {i}", content="...")
        for i in range(100)
    ])
    return {"created": len(articles)}
```

### Basic Async ORM Methods

```python
from myapp.models import Article

# Get a single object
article = await Article.objects.aget(id=1)

# Create an object
article = await Article.objects.acreate(title="My Article", content="Content")

# Get or create
article, created = await Article.objects.aget_or_create(
    title="My Article",
    defaults={"content": "Default content"}
)

# Count
total = await Article.objects.acount()

# Check existence
exists = await Article.objects.filter(published=True).aexists()

# Delete
deleted_count, _ = await Article.objects.filter(draft=True).adelete()

# Update
updated_count = await Article.objects.filter(draft=True).aupdate(published=True)
```

### Avoiding N+1 Queries

```python
# select_related for ForeignKey/OneToOne
@api.get("/articles")
async def list_articles():
    articles = []
    async for article in Article.objects.select_related("author")[:20]:
        articles.append({
            "id": article.id,
            "author_name": article.author.username
        })
    return {"articles": articles}

# prefetch_related for ManyToMany
@api.get("/articles")
async def list_articles():
    queryset = Article.objects.select_related("author").prefetch_related("tags")
    async for article in queryset[:20]:
        tags = [tag.name for tag in article.tags.all()]
    return {"articles": [...]}
```

### Transactions

```python
from django.db import transaction

@api.post("/orders")
async def create_order(request):
    data = await request.json()
    
    async with transaction.atomic():
        order = await Order.objects.acreate(
            user_id=data["user_id"],
            total=data["total"],
        )
        for item in data["items"]:
            await OrderItem.objects.acreate(
                order=order,
                product_id=item["product_id"],
                quantity=item["quantity"],
            )
    
    return {"order_id": order.id}
```

### Aggregations

```python
from django.db.models import Count, Avg, Q

@api.get("/stats")
async def article_stats():
    stats = await Article.objects.aaggregate(
        total=Count("id"),
        published=Count("id", filter=Q(published=True)),
        avg_comments=Avg("comment_count")
    )
    return stats
```

### DJANGO_BOLT_ORM_THREADS (v0.11.0+)

Bounded thread pool for sync ORM operations:

```python
# settings.py
DJANGO_BOLT_ORM_THREADS = 20  # Bounded pool size
```

---

## Background Tasks

### Django 6.0 Tasks Framework

```python
from django.tasks import task

@task
def process_video(video_path: str):
    import subprocess
    subprocess.run(["ffmpeg", "-i", video_path, "-vcodec", "h264", f"{video_path}.mp4"])

@api.post("/videos")
async def upload_video(request):
    file = await request.file("video")
    from django.core.files.storage import default_storage
    path = default_storage.save(f"videos/{file.filename}", file)
    
    process_video.enqueue(path)
    
    return {"path": path, "status": "processing"}
```

### Celery Integration

```python
# tasks.py
from celery import shared_task

@shared_task
def process_data_async(data_id: int):
    import asyncio
    from myapp.models import DataRecord

    async def process():
        record = await DataRecord.objects.aget(id=data_id)
        record.status = "processed"
        await record.asave()

    asyncio.run(process())

@api.post("/process")
async def start_processing(data_id: int):
    process_data_async.delay(data_id)
    return {"status": "processing_started", "data_id": data_id}
```

### Django Q

```python
@api.post("/process")
async def start_processing(data_id: int):
    from django_q.tasks import async_task
    async_task("myapp.functions.process_data", data_id)
    return {"status": "queued", "data_id": data_id}
```