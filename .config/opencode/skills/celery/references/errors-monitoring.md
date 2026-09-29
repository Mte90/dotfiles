# Error Handling and Monitoring

> Loaded on demand from `../SKILL.md` for detailed error handling and monitoring patterns.

## Error Handling

### Retry Strategies

```python
@shared_task(
    bind=True,
    max_retries=5,
    autoretry_for=(ConnectionError, TimeoutError),
    retry_backoff=True,
    retry_backoff_max=600,
    retry_jitter=True,
)
def fetch_external_api(self, url):
    """Fetch from external API with retry."""
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.RequestException as exc:
        raise self.retry(exc=exc)

# Manual retry with custom logic
@shared_task(bind=True, max_retries=3)
def process_with_retry(self, data_id):
    try:
        data = Data.objects.get(id=data_id)
        return data.process()
    except Data.DoesNotExist:
        # Don't retry - data doesn't exist
        raise
    except DatabaseError as exc:
        # Retry with exponential backoff
        countdown = 2 ** self.request.retries
        raise self.retry(exc=exc, countdown=countdown)
```

### Error Callbacks

```python
@shared_task
def on_failure(request, exc, traceback):
    """Error callback task."""
    logger.error(f"Task {request.id} failed: {exc}")
    notify_admins(f"Task failed: {request.id}")

@shared_task
def process_data(data_id):
    data = Data.objects.get(id=data_id)
    return data.process()

# Link error callback
result = process_data.apply_async(
    args=[data_id],
    link_error=on_failure.s()
)
```

### Dead Letter Queue

```python
# Configure dead letter queue
CELERY_TASK_ANNOTATIONS = {
    '*': {
        'on_failure': handle_task_failure,
    }
}

@shared_task
def handle_task_failure(task_id, exception, args, kwargs, traceback, einfo):
    """Handle failed tasks."""
    FailedTask.objects.create(
        task_id=task_id,
        exception=str(exception),
        args=args,
        kwargs=kwargs,
        traceback=traceback,
    )
    notify_admins(f"Task {task_id} failed permanently")
```

## Monitoring

### Flower (Web UI)

```bash
# Install
pip install flower

# Start
celery -A myproject flower --port=5555

# With authentication
celery -A myproject flower --port=5555 --basic-auth=user:password
```

```python
# Configure in settings
CELERY_FLOWER_PORT = 5555
CELERY_FLOWER_BASIC_AUTH = ['user:password']
```

### Command Line Monitoring

```bash
# Inspect active tasks
celery -A myproject inspect active

# Inspect registered tasks
celery -A myproject inspect registered

# Inspect scheduled tasks
celery -A myproject inspect scheduled

# Inspect reserved tasks
celery -A myproject inspect reserved

# Stats
celery -A myproject inspect stats

# Ping workers
celery -A myproject inspect ping

# Control workers
celery -A myproject control enable_events
celery -A myproject control disable_events

# Revoke task
celery -A myproject revoke <task_id>

# Terminate task (SIGTERM)
celery -A myproject revoke <task_id> --terminate

# Purge all tasks
celery -A myproject purge
```

### Prometheus Metrics

```python
# Install: pip install celery-prometheus-exporter

# Start exporter
celery-prometheus-exporter --broker redis://localhost:6379/0

# Or integrate into Django
# urls.py
from django.urls import path
from celery_prometheus.views import metrics_view

urlpatterns = [
    path('metrics/', metrics_view),
]
```