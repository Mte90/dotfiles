# Provider Configuration Deep Dive

This reference file is loaded on demand from ../SKILL.md for detailed backend configuration.

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
            "region_name": "us-east-1",
            
            # Django 6.0+: AWS_S3_USE_THREADS removed → use AWS_S3_TRANSFER_CONFIG
            "transfer_config": {
                "use_threads": True,
                "multipart_threshold": 100 * 1024 * 1024,  # 100MB
            },
        },
    },
}
```

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