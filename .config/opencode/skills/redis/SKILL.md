---
name: redis
description: "Redis - in-memory database, caching, pub/sub, sessions, rate limiting, data structures"
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - redis
    - database
    - caching
    - pub-sub
    - sessions
    - rate-limiting
    - data-structures
    - nosql
---

# Redis

Redis - in-memory data structure store, used as database, cache, and message broker.

## Installation

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
        }
    }
}
```

---

## Caching

### Basic Configuration

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
            },
            'SOCKET_CONNECT_TIMEOUT': 5,
            'SOCKET_TIMEOUT': 5,
        },
        'KEY_PREFIX': 'myapp',
        'VERSION': 1,
    }
}
```

### Using Cache

```python
from django.core.cache import cache

# Set with expiration (seconds)
cache.set('key', 'value', timeout=300)
cache.set_many({'key1': 'value1', 'key2': 'value2'}, timeout=300)

# Get
value = cache.get('key')
value = cache.get('key', 'default_value')

# Delete
cache.delete('key')
cache.delete_pattern('user_*')
```

### View Caching

```python
from django.views.decorators.cache import cache_page

@cache_page(60 * 15)  # 15 minutes
def my_view(request):
    return render(request, 'template.html')
```

### Template Fragment Caching

```html+django
{% load cache %}
{% cache 500 sidebar request.user.id %}
    <div class="sidebar">
        <!-- Content to cache -->
    </div>
{% endcache %}
```

---

## Session Backend

```python
# settings.py
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'default'
```

Or with Redis directly:

```python
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/0',
    }
}
```

---

## Celery Broker

```python
# settings.py
CELERY_BROKER_URL = 'redis://127.0.0.1:6379/0'
CELERY_RESULT_BACKEND = 'redis://127.0.0.1:6379/1'
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
```

---

## Django Channels with Redis

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

---

## Connection Pool

```python
# settings.py with connection pool
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'CONNECTION_POOL_KWARGS': {
                'max_connections': 100,
            },
            'PASSWORD': 'your_password',
        }
    }
}
```

## Redis CLI Commands

```bash
# Connect
redis-cli

# Check keys
KEYS *

# Delete by pattern
FLUSHDB  # Clear current database
```

## Best Practices

### Connection Management

```python
# Reuse connection, don't create new each request
from django_redis import get_redis_connection

def get_redis():
    # Global singleton
    return get_redis_connection("default")
```

```python
# Connection pool settings
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/1',
        'OPTIONS': {
            'CONNECTION_POOL_KWARGS': {
                'max_connections': 100,
                'retry_on_timeout': True,
            },
            'SOCKET_CONNECT_TIMEOUT': 5,
            'SOCKET_TIMEOUT': 5,
        }
    }
}
```

### Key Design

```python
# Use namespaced keys
KEY_PREFIX = 'myapp'
VERSION = 1
# Keys become: myapp:v1:user:123

# Add TTL to all keys
cache.set('temp_token', token, timeout=300)  # 5 min

# Use consistent naming
cache.set('user:profile:123', data)
cache.set('user:session:123', data)
```

### Performance

```python
# Batch operations
cache.set_many({
    'key1': 'value1',
    'key2': 'value2',
    'key3': 'value3',
}, timeout=3600)

# Use pipeline for multiple ops
pipe = cache.client.get_client()
pipe.set('a', 1)
pipe.set('b', 2)
pipe.execute()  # Atomic, single round-trip
```

### Error Handling

```python
from django.core.cache import CacheKeyError

try:
    value = cache.get('key')
except ConnectionError:
    # Fallback to DB or default
    value = get_from_db()
```

### Do:

- Always set TTL (expire keys)
- Use key prefixes for namespacing
- Reuse connections (don't create per request)
- Use pipeline for batch operations

### Don't:

- Use KEYS * in production (blocks Redis)
- Store large values (>1MB consider compression)
- Use Redis as primary data store (it's a cache)
- Forget connection timeout settings

---

## References

- **django-redis**: https://github.com/jazzband/django-redis
- **Documentation**: https://django-redis.readthedocs.io/