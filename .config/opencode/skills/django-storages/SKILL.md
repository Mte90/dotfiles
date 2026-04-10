---
name: django-storages
description: "Django cloud storage - S3, Azure, Google Cloud, Boto3, cloud file storage backends"
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - python
    - django
    - storage
    - s3
    - azure
    - gcs
    - cloud
    - boto3
---

# Django Storages

Django package for cloud storage backends. Provides a unified API for storing files across different cloud providers.

## Overview

Django-storages replaces Django's default file handling with cloud storage backends:

- **Amazon S3** — AWS Simple Storage Service
- **Azure Blob Storage** — Microsoft Azure
- **Google Cloud Storage** — Google Cloud Platform
- **Dropbox** — Dropbox cloud storage
- **FTP** — FTP servers
- **SFTP** — Secure FTP
- **And more...**

## Installation

```bash
pip install django-storages
```

```bash
# For specific backends
pip install django-storages[boto3]    # AWS S3
pip install django-storages[azure]     # Azure Blob
pip install django-storages[gcloud]    # Google Cloud Storage
```

---

## Configuration (Django 4.2+)

### Using STORAGES Setting

```python
# settings.py

STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
    },
    "staticfiles": {
        "BACKEND": "storages.backends.s3.S3Storage",
    },
}
```

### Legacy Configuration (Django < 4.2)

```python
# settings.py (Django < 4.2)
DEFAULT_FILE_STORAGE = "storages.backends.s3.S3Storage"
STATICFILES_STORAGE = "storages.backends.s3.S3Storage"
```

---

## Amazon S3 Configuration

### Basic Setup

```python
# settings.py
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "access_key": "your-access-key",
            "secret_key": "your-secret-key",
            "bucket_name": "your-bucket-name",
            "region_name": "us-east-1",
        },
    },
    "staticfiles": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "bucket_name": "your-static-bucket",
        },
    },
}

# Or using environment variables
import os
AWS_ACCESS_KEY_ID = os.environ.get("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.environ.get("AWS_SECRET_ACCESS_KEY")
AWS_STORAGE_BUCKET_NAME = "your-bucket-name"
AWS_S3_REGION_NAME = "us-east-1"
```

### S3 Advanced Options

```python
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "access_key": "your-access-key",
            "secret_key": "your-secret-key",
            "bucket_name": "your-bucket-name",
            "region_name": "eu-west-1",
            
            # Object parameters (applied to all uploads)
            "object_parameters": {
                "CacheControl": "max-age=86400",
                "SSEKMSKeyId": "arn:aws:kms:...",
                "StorageClass": "STANDARD_IA",
            },
            
            # File handling
            "default_acl": "public-read",
            "file_overwrite": False,
            
            # Custom domain for URLs
            "custom_domain": "cdn.yourdomain.com",
            
            # URL expiration
            "querystring_auth": True,
            "querystring_expire": 3600,
            
            # Location prefix
            "location": "media",
            
            # Gzip compression
            "gzip": True,
            "gzip_content_types": [
                "text/css",
                "text/javascript",
                "application/javascript",
                "application/json",
                "image/svg+xml",
            ],
        },
    },
}
```

### S3 Environment Variables

```bash
# .env
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_STORAGE_BUCKET_NAME=your-bucket
AWS_S3_REGION_NAME=us-east-1
AWS_S3_CUSTOM_DOMAIN=cdn.yourdomain.com
```

### Using boto3 Session

```python
import boto3
from botocore.config import Config

session = boto3.Session(
    aws_access_key_id="your-key",
    aws_secret_access_key="your-secret",
    region_name="eu-west-1"
)

STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "bucket_name": "your-bucket",
            "session": session,
            "config": Config(signature_version="s3v4"),
        },
    },
}
```

---

## Google Cloud Storage Configuration

### Service Account Authentication

```python
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.gcloud.GoogleCloudStorage",
        "OPTIONS": {
            "bucket_name": "your-bucket-name",
            "project_id": "your-project-id",
            "credentials_path": "/path/to/service-account.json",
            # Or use default credentials
            # "credentials": None  # Uses GOOGLE_APPLICATION_CREDENTIALS
        },
    },
}
```

### With Custom Domain

```python
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.gcloud.GoogleCloudStorage",
        "OPTIONS": {
            "bucket_name": "your-bucket",
            "custom_domain": "storage.yourdomain.com",
        },
    },
}
```

### Environment Variables

```bash
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
GS_BUCKET_NAME=your-bucket
GS_PROJECT_ID=your-project
```

---

## Azure Blob Storage Configuration

```python
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.azure_storage.AzureStorage",
        "OPTIONS": {
            "account_name": "your-account-name",
            "account_key": "your-account-key",
            "container_name": "your-container",
            "cdn_host": "https://your-cdn.azureedge.net",
        },
    },
}
```

### Azure Environment Variables

```bash
AZURE_ACCOUNT_NAME=your-account
AZURE_ACCOUNT_KEY=your-key
AZURE_CONTAINER_NAME=your-container
```

---

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

---

## Cloud Provider Specific Features

### S3: Server-Side Encryption

```python
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "bucket_name": "your-bucket",
            "object_parameters": {
                "SSEKMSKeyId": "arn:aws:kms:region:account:key/key-id",
                "ServerSideEncryption": "aws:kms",
            },
        },
    },
}
```

### S3: CloudFront CDN

```python
# settings.py
CLOUDFRONT_DOMAIN = "your-cloudfront-distribution.cloudfront.net"

STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "bucket_name": "your-bucket",
            "custom_domain": CLOUDFRONT_DOMAIN,
            "querystring_auth": False,  # Not needed with CloudFront
        },
    },
}
```

### GCS: Signed URLs

```python
from google.cloud import storage

client = storage.Client()
bucket = client.bucket("your-bucket")
blob = bucket.blob("uploads/file.pdf")

# Generate signed URL
url = blob.generate_signed_url(
    version="v4",
    expiration=datetime.timedelta(hours=1),
    method="GET"
)
```

### Azure: Blob Properties

```python
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.azure_storage.AzureStorage",
        "OPTIONS": {
            "container_name": "your-container",
            "azure_blob": {
                "cache_control": "max-age=3600",
                "content_disposition": "inline",
                "content_language": "en-US",
            },
        },
    },
}
```

---

## Caching Static Files

### collectstatic with S3

```bash
python manage.py collectstatic --noinput
```

### Manifest StaticFiles Storage (with cache busting)

```python
STORAGES = {
    "staticfiles": {
        "BACKEND": "storages.backends.s3boto3.S3Boto3Storage",
        "OPTIONS": {
            "bucket_name": "static-bucket",
            "manifest_storage": "storages.backends.s3boto3.S3Boto3Storage",
        },
    },
}

# Or for Django 4.2+
from django.contrib.staticfiles.storage import ManifestStaticFilesStorage
from storages.backends.s3boto3 import S3Boto3Storage

class S3ManifestStaticFilesStorage(ManifestStaticFilesStorage):
    def __init__(self, *args, **kwargs):
        kwargs["storage"] = S3Boto3Storage(
            bucket_name="static-bucket"
        )
        super().__init__(*args, **kwargs)

STORAGES = {
    "staticfiles": {
        "BACKEND": "path.to.S3ManifestStaticFilesStorage",
    },
}
```

---

## Handling Large Files

### Multipart Upload (S3)

```python
from storages.backends.s3 import S3Storage

class LargeFileS3Storage(S3Storage):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.multipart_chunksize = 50 * 1024 * 1024  # 50MB chunks

# settings.py
STORAGES = {
    "default": {
        "BACKEND": "path.to.LargeFileS3Storage",
        "OPTIONS": {
            "bucket_name": "large-files-bucket",
        },
    },
}
```

---

## Development and Testing

### Local Development

```python
# settings.py (development)
STORAGES = {
    "default": {
        "BACKEND": "django.core.files.storage.FileSystemStorage",
    },
    "staticfiles": {
        "BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage",
    },
}
```

### Testing with Mock

```python
from unittest.mock import patch
from django.core.files.uploadedfile import SimpleUploadedFile

@patch("django.core.files.storage.default_storage")
def test_upload(mock_storage):
    mock_storage.save.return_value = "test.txt"
    
    file = SimpleUploadedFile("test.txt", b"content")
    path = default_storage.save("test.txt", file)
    
    assert path == "test.txt"
    mock_storage.save.assert_called_once()
```

---

## Common Issues

### CORS Configuration (S3)

Add to bucket CORS policy:

```json
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
        "AllowedOrigins": ["https://yourdomain.com"],
        "ExposeHeaders": []
    }
]
```

### Credential Loading Priority

1. `credentials` parameter in OPTIONS
2. Environment variables (AWS_ACCESS_KEY_ID, etc.)
3. AWS credentials file (~/.aws/credentials)
4. IAM role (EC2/ECS)

### File Name Encoding

```python
# Handle Unicode filenames
import unicodedata
from django.utils.text import slugify

def upload_path(instance, filename):
    # Normalize unicode
    name = unicodedata.normalize("NFKD", filename)
    name = slugify(name)
    return f"uploads/{name}"
```

---

## Best Practices

### Security

```python
# ✅ GOOD: Don't hardcode credentials
# settings.py - use environment variables
AWS_ACCESS_KEY_ID = os.environ['AWS_ACCESS_KEY_ID']
AWS_SECRET_ACCESS_KEY = os.environ['AWS_SECRET_ACCESS_KEY']

# ✅ GOOD: Use bucket policies
# Restrict public access, use VPC endpoints
```

### Performance

```python
# ✅ GOOD: Use appropriate storage class
STORAGE_BACKEND = 'storages.backends.s3boto3.S3Boto3Storage'
AWS_STORAGE_CLASS = 'STANDARD_IA'  # Infrequent access

# ✅ GOOD: Enable caching
AWS_S3_OBJECT_PARAMETERS = {
    'CacheControl': 'max-age=86400',
}
```

### File Handling

```python
# ✅ GOOD: Use FileField with storage
from django.db import models

class Document(models.Model):
    file = models.FileField(storage=s3_storage)
    uploaded_at = models.DateTimeField(auto_now_add=True)

# ✅ GOOD: Generate signed URLs
url = s3_storage.url(file.name, parameters={'ResponseContentDisposition': 'attachment'})
```

### Do:
- Use environment variables for credentials
- Set proper caching headers
- Use signed URLs for private files

### Don't:
- Store credentials in code
- Use public buckets for sensitive data

## References

- **Documentation**: https://django-storages.readthedocs.io/
- **GitHub**: https://github.com/jschneier/django-storages
- **PyPI**: https://pypi.org/project/django-storages/
- **S3 Boto3 Docs**: https://boto3.readthedocs.io/
- **GCS Python Client**: https://google-cloud-python.readthedocs.io/