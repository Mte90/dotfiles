# Cloud Features Deep Dive

This reference file is loaded on demand from ../SKILL.md for advanced cloud provider features.

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