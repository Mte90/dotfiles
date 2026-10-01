# Django Integration with Redis

> This file is loaded on demand from the main redis skill when working with Django projects.

## django-redis Cache Backend

```bash
pip install django-redis
```

```python
# settings.py
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'CONNECTION_POOL_KWARGS': {
                'max_connections': 50,
                'retry_on_timeout': True,
                'protocol': 3,  # RESP3
            },
            'SOCKET_CONNECT_TIMEOUT': 5,
            'SOCKET_TIMEOUT': 5,
        },
        'KEY_PREFIX': 'myapp',
        'VERSION': 1,
    }
}
```

```python
from django.core.cache import cache

# Set with expiration
cache.set('key', 'value', timeout=300)

# Get
value = cache.get('key', 'default_value')

# Delete
cache.delete('key')
cache.delete_pattern('user_*')
```

## Cache Invalidation on Model Save

```python
from django.core.cache import cache
from django.db.models.signals import post_save
from django.dispatch import receiver

@receiver(post_save, sender=User)
def invalidate_user_cache(sender, instance, **kwargs):
    """Clear cached user data after model save."""
    cache.delete(f'user:profile:{instance.id}')
    cache.delete(f'user:session:{instance.id}')
```

## Per-User Rate Limiting

```python
from django.core.cache import cache
from django.core.exceptions import PermissionDenied

def rate_limit_user(user_id, max_requests=100, window_seconds=3600):
    """
    Simple per-user rate limiting using Redis.
    Returns True if request is allowed, raises PermissionDenied if exceeded.
    """
    key = f'ratelimit:user:{user_id}'
    current = cache.get(key, 0)
    
    if current >= max_requests:
        raise PermissionDenied("Rate limit exceeded")
    
    # Increment counter (atomic in Redis)
    new_count = cache.incr(key)
    if new_count == 1:
        # First request, set TTL
        cache.expire(key, window_seconds)
    
    return True
```

## Celery Broker

```python
# settings.py
CELERY_BROKER_URL = 'redis://127.0.0.1:6379/0'
CELERY_RESULT_BACKEND = 'redis://127.0.0.1:6379/1'
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
```

## Django Channels

```python
# settings.py
CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            'hosts': [('127.0.0.1', 6379)],
        },
    }
}
```
