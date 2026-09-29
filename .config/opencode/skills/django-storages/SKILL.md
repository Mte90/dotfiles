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

## Overview

Django-storages replaces Django's default file handling with cloud storage backends:

- **Amazon S3** — AWS Simple Storage Service
- **Azure Blob Storage** — Microsoft Azure
- **Google Cloud Storage** — Google Cloud Platform
- **Dropbox** — Dropbox cloud storage
- **FTP** — FTP servers
- **SFTP** — Secure FTP

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

## Configuration (Django 6.0+)

### STORAGES Setting (Required for Django 6.0+)

```python
# settings.py

STORAGES = {
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
    },
    "staticfiles": {
        "BACKEND": "django.contrib.staticfiles.storage.ManifestStaticFilesStorage",
    },
}
```

### Legacy Configuration (Django < 4.2)

```python
# settings.py (Django < 4.2)
DEFAULT_FILE_STORAGE = "storages.backends.s3.S3Storage"
STATICFILES_STORAGE = "storages.backends.s3.S3Storage"
```

> **Django 6.0**: `STATICFILES_STORAGE` and `DEFAULT_FILE_STORAGE` removed. Use `STORAGES` dict only.

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

---

## Deep Dives

Load these reference files for detailed backend-specific guidance:

- **Provider Configuration** — `references/providers.md` — Amazon S3, Google Cloud Storage, Azure Blob Storage details
- **Models and Code** — `references/models-code-urls.md` — FileField usage, direct backend access, uploads, signed URLs
- **Advanced Features** — `references/cloud-features.md` — Encryption, CDN, caching, multipart uploads

---

## References

- **Documentation**: https://django-storages.readthedocs.io/
- **GitHub**: https://github.com/jschneier/django-storages
- **PyPI**: https://pypi.org/project/django-storages/
- **S3 Boto3 Docs**: https://boto3.readthedocs.io/
- **GCS Python Client**: https://google-cloud-python.readthedocs.io/