# Models, Code, and URLs Deep Dive

This reference file is loaded on demand from ../SKILL.md for storage usage patterns.

## Using Storage in Models

### FileField

```python
from django.db import models

class Document(models.Model):
    title = models.CharField(max_length=255)
    file = models.FileField(upload_to="documents/%Y/%m/%d/")
    uploaded_at = models.DateTimeField(auto_now_add=True)

# File is automatically stored in S3 (or configured backend)
doc = Document.objects.create(
    title="Report",
    file="reports/2024/01/report.pdf"
)
```

### ImageField

```python
class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    avatar = models.ImageField(upload_to="avatars/")
    bio = models.TextField(blank=True)
```

### Custom Storage per Field

```python
from django.db import models
from storages.backends.s3boto3 import S3Boto3Storage

# Custom storage instance
public_storage = S3Boto3Storage(bucket_name="public-files")
private_storage = S3Boto3Storage(bucket_name="private-files")

class File(models.Model):
    name = models.CharField(max_length=255)
    public_file = models.FileField(storage=public_storage)
    private_file = models.FileField(storage=private_storage)
```

---

## Using Storage in Code

### Default Storage

```python
from django.core.files.storage import default_storage

# Save file
default_storage.save("uploads/file.txt", content)

# Open file
file = default_storage.open("uploads/file.txt", "r")

# Check if exists
exists = default_storage.exists("uploads/file.txt")

# Delete file
default_storage.delete("uploads/file.txt")

# Get URL
url = default_storage.url("uploads/file.txt")
```

### Direct Backend Access

```python
from storages.backends.s3 import S3Storage

storage = S3Storage(
    access_key="key",
    secret_key="secret",
    bucket_name="my-bucket"
)

# List files
files = storage.listdir("uploads/")
for f in files[1]:
    print(f)

# Get file info
size = storage.size("uploads/file.txt")
modified = storage.modified_time("uploads/file.txt")
```

---

## Uploading Files

### Simple Upload

```python
from django.core.files.storage import default_storage

# From uploaded file (request.FILES)
file = request.FILES["file"]
path = default_storage.save(f"uploads/{file.name}", file)

# From local file
path = default_storage.save("uploads/filename.txt", open("/local/file.txt", "rb"))
```

### Upload to Specific Path

```python
from django.core.files.storage import default_storage
import uuid

def upload_file(file):
    # Generate unique filename
    ext = file.name.split(".")[-1]
    filename = f"{uuid.uuid4()}.{ext}"
    
    # Save with custom path
    path = default_storage.save(f"uploads/{filename}", file)
    return path
```

---

## Generating URLs

### Signed URLs (S3)

```python
from django.core.files.storage import default_storage

# Generate signed URL (expires in 3600 seconds)
url = default_storage.url(
    "uploads/file.pdf",
    parameters={"ResponseContentDisposition": "attachment"}
)

# Or with custom expiration
url = default_storage.url(
    "uploads/file.pdf",
    expire=7200  # 2 hours
)
```

### Pre-signed URLs (boto3)

```python
import boto3

s3_client = boto3.client("s3")

# Generate pre-signed URL
url = s3_client.generate_presigned_url(
    "get_object",
    Params={
        "Bucket": "your-bucket",
        "Key": "uploads/file.pdf"
    },
    ExpiresIn=3600
)
```