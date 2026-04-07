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

## References

- **django-redis**: https://github.com/jazzband/django-redis
- **Documentation**: https://django-redis.readthedocs.io/