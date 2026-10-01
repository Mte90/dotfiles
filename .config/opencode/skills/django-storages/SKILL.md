---
name: django-storages
description: Use when configuring django-storages for cloud file storage - STORAGES setting, Amazon S3, Google Cloud Storage and Azure backends, signed URLs, CDN and caching, multipart uploads, or storage testing
metadata:
  author: mte90
  version: 2.0.0
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

## Quick Start

```bash
pip install django-storages[boto3]  # AWS S3 example
```

```python
# settings.py
import os

STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "bucket_name": "my-app-media",
            "region_name": "us-east-1",
        },
    },
    "staticfiles": {
        "BACKEND": "django.contrib.staticfiles.storage.ManifestStaticFilesStorage",
    },
}

# Credentials from environment (never in settings)
AWS_ACCESS_KEY_ID = os.environ["AWS_ACCESS_KEY_ID"]
AWS_SECRET_ACCESS_KEY = os.environ["AWS_SECRET_ACCESS_KEY"]
```

---

## Critical Pitfall: Filename Encoding

**The single most common failure** with user-uploaded files is non-ASCII characters, spaces, and special characters in filenames.

### What Breaks

- Unicode filenames (`报告.pdf`, `vacation été.jpg`) may not survive URL encoding
- Spaces become `%20` or `+` inconsistently across backends
- Duplicate names overwrite existing files silently
- Some backends reject certain characters entirely

### Solution: Sanitize in `upload_to`

```python
import os
import unicodedata
import uuid
from django.utils.text import slugify

def sanitize_upload_path(instance, filename):
    """
    Sanitize filename and guarantee uniqueness.
    Never trust client-supplied filenames.
    """
    # Extract extension
    ext = os.path.splitext(filename)[1]
    
    # Normalize unicode (NFKD decomposes, then slugify strips diacritics)
    sanitized = unicodedata.normalize("NFKD", filename)
    sanitized = slugify(sanitized)
    
    # Fallback if slugify produces empty string
    if not sanitized:
        sanitized = "file"
    
    # Append random suffix to guarantee uniqueness
    unique_id = uuid.uuid4().hex[:8]
    new_filename = f"{sanitized}_{unique_id}{ext}"
    
    return f"uploads/{new_filename}"

class Document(models.Model):
    title = models.CharField(max_length=255)
    file = models.FileField(upload_to=sanitize_upload_path)
```

### Why Not Just Use `slugify`?

- Two users upload `report.pdf` → second overwrites first
- Filename contains only special characters → `slugify` produces empty string
- You need to reference the original name for download → store it separately

```python
class Document(models.Model):
    title = models.CharField(max_length=255)
    original_name = models.CharField(max_length=255)  # For download
    file = models.FileField(upload_to=sanitize_upload_path)
```

---

## Configuration (Django 6.0+)

### STORAGES Setting

The `STORAGES` dict replaces `DEFAULT_FILE_STORAGE` and `STATICFILES_STORAGE` (removed in Django 6.0).

```python
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "bucket_name": "my-app-media",
            "region_name": "us-east-1",
        },
    },
    "staticfiles": {
        "BACKEND": "django.contrib.staticfiles.storage.ManifestStaticFilesStorage",
    },
}
```

### Why Backend Selection Goes in Settings, Not Code

**Problem:** Hardcoding the backend in code forces environment-specific branching.

```python
# ❌ DON'T: Environment branching in code
if settings.DEBUG:
    from django.core.files.storage import FileSystemStorage
    storage = FileSystemStorage()
else:
    from storages.backends.s3 import S3Storage
    storage = S3Storage()
```

**Solution:** Swap backends via settings per environment.

```python
# settings/dev.py
STORAGES = {
    "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"},
}

# settings/prod.py
STORAGES = {
    "default": {"BACKEND": "storages.backends.s3.S3Storage"},
}

# Code stays the same:
from django.core.files.storage import default_storage
default_storage.save("file.txt", content)
```

### Credentials from Environment Variables

**Problem:** A leaked settings file = leaked cloud credentials.

```python
# ❌ DON'T: Hardcoded credentials
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "access_key": "AKIAIOSFODNN7EXAMPLE",  # Leaked = compromised
            "secret_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
        },
    },
}
```

**Solution:** Environment variables or IAM roles.

```python
# ✅ DO: Environment variables
import os
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "access_key": os.environ["AWS_ACCESS_KEY_ID"],
            "secret_key": os.environ["AWS_SECRET_ACCESS_KEY"],
        },
    },
}

# ✅ BETTER: IAM role (EC2/ECS) - no credentials needed
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "bucket_name": "my-app-media",
            # No access_key/secret_key → uses IAM role
        },
    },
}
```

---

## ACL and Authorization Decisions

### `default_acl`: When to Make Files Public

```python
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "default_acl": "public-read",  # or None for private
        },
    },
}
```

**Set `public-read` only for genuinely public assets:**

- Static website assets (images, CSS, JS)
- Publicly accessible user avatars
- Marketing materials

**Keep `None` (private) for:**

- User documents (PDFs, spreadsheets)
- Financial records
- Any data requiring authorization

**Why it matters:** Public buckets are a common security incident vector. Obscurity is not security.

### `querystring_auth`: Signed URLs

```python
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "querystring_auth": True,   # Require signatures (private)
            "querystring_expire": 3600, # 1 hour expiry
        },
    },
}
```

**When `querystring_auth = False`:**

- Bucket has a public ACL policy
- CDN frontends the bucket (CloudFront with OAI)
- Static assets that never expire

**Critical:** If `querystring_auth = False`, signed URLs **must carry their own expiry** via `url()` parameters:

```python
# Private bucket with querystring_auth=False (e.g., CDN-protected)
# You MUST pass expiry explicitly:
url = storage.url("file.pdf", expire=3600)  # Expires in 1 hour
```

**When you need signed URLs:**

```python
# Download as attachment (forces download with original filename)
url = storage.url(
    "documents/report.pdf",
    parameters={"ResponseContentDisposition": "attachment; filename=report.pdf"}
)

# Temporary access (e.g., password-protected page)
url = storage.url("private/secret.pdf", expire=1800)  # 30 minutes
```

---

## CDN Integration Pattern

### Private Bucket + CDN Origin

**Architecture:**
1. S3 bucket is private (`querystring_auth = True`)
2. CloudFront (or other CDN) fronts the bucket
3. Public users access via CDN URL
4. Signed URLs bypass CDN for direct S3 access (or use CloudFront signed URLs)

```python
# settings.py
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "bucket_name": "my-app-private",
            "region_name": "us-east-1",
            "querystring_auth": True,  # Private bucket
            "custom_domain": "d1234abcdef.cloudfront.net",  # CDN domain
        },
    },
}
```

### Cache-Control Headers

Differentiate cacheable public assets from private content:

```python
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "object_parameters": {
                # Public static assets: cache aggressively
                "CacheControl": "public, max-age=31536000, immutable",
            },
        },
    },
}

# Per-file cache control (overrides default)
from django.core.files.storage import default_storage

# Public image - cache for a year
default_storage.save("images/logo.png", content)
# S3 object params can be set via custom storage subclass or boto3 directly

# Temporary report - don't cache
default_storage.save("reports/daily.pdf", content)
```

### CDN Invalidation

**CloudFront:**

```python
import boto3

def invalidate_cloudfront(paths):
    """
    Invalidate CloudFront cache for given paths.
    Cost: $0.005 per path, 1000 paths/month free.
    """
    cloudfront = boto3.client("cloudfront")
    distribution_id = "E1234ABCDEF"
    
    cloudfront.create_invalidation(
        DistributionId=distribution_id,
        InvalidationBatch={
            "Id": f"invalidation-{uuid.uuid4().hex[:8]}",
            "Paths": {
                "Quantity": len(paths),
                "Items": paths,
            },
        },
    )

# Invalidate specific files
invalidate_cloudfront(["/images/logo.png", "/reports/daily.pdf"])

# Invalidate by prefix (expensive - use sparingly)
invalidate_cloudfront(["/reports/*"])  # Wildcards supported in CloudFront
```

**Azure CDN:**

```python
# Azure CDN Classic invalidation
from azure.cdn.management import CdnManagementClient

client = CdnManagementClient(credential, subscription_id)
client.profiles.begin_create_or_update(...)

# Invalidate by path prefix
client.endpoints.invalidate(
    resource_group_name="my-rg",
    profile_name="my-profile",
    endpoint_name="my-endpoint",
    content_paths=["/images/*", "/css/*"],
)
```

**Source:** [AWS CloudFront Invalidations](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Invalidation.html) | [Azure CDN Invalidation](https://learn.microsoft.com/en-us/azure/cdn/cdn-manage-cache)

---

## When Not to Use django-storages

### Local Development

**Use Django's `FileSystemStorage` instead:**

```python
# settings/dev.py
STORAGES = {
    "default": {
        "BACKEND": "django.core.files.storage.FileSystemStorage",
        "OPTIONS": {
            "location": "/tmp/media",  # or MEDIA_ROOT
        },
    },
}
```

**Why:** No network calls, no credentials, instant file access for debugging.

### Static Assets Pipeline

**Use a build pipeline instead of storage backend for assets that ship with code:**

- Webpack/Vite/Rollup output
- Compiled CSS/JS
- Optimized images from source control

**Why:** These are versioned at deploy time, not user-uploaded. Use `collectstatic` with `ManifestStaticFilesStorage`.

```python
STORAGES = {
    "staticfiles": {
        "BACKEND": "django.contrib.staticfiles.storage.ManifestStaticFilesStorage",
    },
}
```

### Single Bucket, No Django Integration Needed

**Use the SDK directly:**

```python
import boto3

s3 = boto3.client("s3")
s3.upload_file("local.txt", "my-bucket", "remote.txt")
```

**Why:** If you only use one bucket and never swap backends, django-storages adds indirection without benefit.

### Presigned URL Uploads from Browser

**Bypass Django entirely:**

```python
# View that returns upload credentials
def get_upload_url(request):
    s3 = boto3.client("s3")
    url = s3.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": "my-bucket",
            "Key": f"uploads/{uuid.uuid4()}.pdf",
            "ContentType": "application/pdf",
        },
        ExpiresIn=3600,
    )
    return JsonResponse({"url": url, "key": key})

# Browser uploads directly to S3
# POST { url, key } → client PUTs file to S3
```

**Why:** Large file uploads shouldn't proxy through Django. Use presigned URLs for direct browser-to-storage uploads.

---

## Configuration Settings (When You Need Them)

### S3-Specific Options

Most settings have sensible defaults. Use these only when you need specific behavior:

```python
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            # Only set if you need non-default storage class
            "object_parameters": {
                "StorageClass": "STANDARD_IA",  # Infrequent access (cheaper)
            },
            
            # Only set if you want to prevent overwrites
            "file_overwrite": False,  # Default: True (overwrites same name)
            
            # Only set if using KMS encryption
            "object_parameters": {
                "SSEKMSKeyId": "arn:aws:kms:...",
            },
            
            # Only set if bucket is in different region
            "region_name": "eu-west-1",  # Default: us-east-1
            
            # Only set if using custom domain/CDN
            "custom_domain": "cdn.example.com",
            
            # Only set if you need non-default ACL
            "default_acl": "public-read",  # Default: None (private)
            
            # Only set if you need URL prefix in bucket
            "location": "media/",  # All files stored under media/
        },
    },
}
```

**Source:** [django-storages S3 Backend Docs](https://django-storages.readthedocs.io/en/latest/backends/amazon-S3.html)

---

## Development and Testing

### Environment Switching

```python
# settings.py
from pathlib import Path

env = os.environ.get("DJANGO_ENV", "development")

if env == "development":
    STORAGES = {
        "default": {
            "BACKEND": "django.core.files.storage.FileSystemStorage",
        },
    }
else:
    STORAGES = {
        "default": {
            "BACKEND": "storages.backends.s3.S3Storage",
            "OPTIONS": {
                "bucket_name": os.environ["AWS_STORAGE_BUCKET_NAME"],
            },
        },
    }
```

### Testing with Mock

```python
from unittest.mock import patch
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase

class DocumentUploadTest(TestCase):
    @patch("django.core.files.storage.default_storage")
    def test_upload(self, mock_storage):
        mock_storage.save.return_value = "uploads/file.txt"
        
        file = SimpleUploadedFile("file.txt", b"content")
        path = default_storage.save("file.txt", file)
        
        self.assertEqual(path, "uploads/file.txt")
        mock_storage.save.assert_called_once()
```

---

## Deep Dives

Load these reference files for detailed backend-specific guidance:

- **Provider Configuration** — `references/providers.md` — Amazon S3, Google Cloud Storage, Azure Blob Storage detailed setup
- **Models and Code** — `references/models-code-urls.md` — FileField usage, direct backend access, uploads, signed URLs
- **Advanced Cloud Features** — `references/cloud-features.md` — Encryption, CDN, caching, multipart uploads (load when implementing provider-specific features)

---

## References

- **Documentation**: https://django-storages.readthedocs.io/
- **GitHub**: https://github.com/jschneier/django-storages
- **PyPI**: https://pypi.org/project/django-storages/
- **S3 Boto3 Docs**: https://boto3.readthedocs.io/
- **GCS Python Client**: https://google-cloud-python.readthedocs.io/
