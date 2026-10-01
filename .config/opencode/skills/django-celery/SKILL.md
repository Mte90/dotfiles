---
name: django-celery
description: Use when integrating Celery with Django - task definition and calling, django-celery-beat scheduling, worker deployment, Flower monitoring, testing tasks, batch processing, or choosing between cron and beat
metadata:
  author: mte90
  version: 2.0.0
  tags:
    - python
    - django
    - celery
    - task-queue
    - periodic-tasks
    - django-celery-beat
---

# Django Celery Integration

Celery distributed task queue integrated with Django, including django-celery-beat for database-backed periodic task scheduling.

## Overview

This skill covers:
- Celery setup within a Django project
- Task definition and execution
- Periodic scheduling with `django-celery-beat`
- Monitoring and best practices

---

## Installation

```bash
pip install celery django-celery-beat redis
```

- **celery**: Task queue library
- **django-celery-beat**: Stores periodic task schedules in the Django database
- **redis**: Broker (recommended for production)

---

## Project Setup

### Celery App Configuration

Create `proj/celery.py` in your Django project directory (same level as `settings.py`):

```python
import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'proj.settings')

app = Celery('proj')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()
```

Update `proj/__init__.py`:

```python
from .celery import app as celery_app

__all__ = ('celery_app',)
```

### Django Settings

In `settings.py`:

```python
INSTALLED_APPS = [
    'django_celery_beat',
    'myapp',
]

CELERY_BROKER_URL = 'redis://localhost:6379/0'
CELERY_RESULT_BACKEND = 'redis://localhost:6379/1'
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = 'Europe/Rome'
CELERY_ENABLE_UTC = True
CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'
CELERY_TASK_SOFT_TIME_LIMIT = 300
CELERY_TASK_TIME_LIMIT = 600
CELERY_TASK_DEFAULT_RETRY_DELAY = 60
CELERY_TASK_DEFAULT_MAX_RETRIES = 3
CELERY_TASK_ROUTES = {
    'myapp.tasks.send_email': {'queue': 'emails'},
    'myapp.tasks.process_video': {'queue': 'heavy'},
}
CELERY_WORKER_PREFETCH_MULTIPLIER = 1
CELERY_WORKER_MAX_TASKS_PER_CHILD = 1000
```

### Database Migration

```bash
python manage.py migrate django_celery_beat
```

---

## Anti-Patterns

### Database Pitfalls

**Passing QuerySets or model instances as task arguments** — The value is serialized at call time in the worker, which may evaluate against a different DB state. Always serialize IDs instead.

```python
# BAD: QuerySet evaluated in worker against stale state
@shared_task
def send_emails_to_users(users_qs):
    for user in users_qs:  # Evaluates in worker, may miss recent changes
        send_email(user)

# GOOD: serialize IDs, re-fetch in worker
@shared_task
def send_emails_to_user_ids(user_ids):
    for user in User.objects.filter(pk__in=user_ids):
        send_email(user)
```

**Calling `delay()`/`apply_async()` inside a transaction that later rolls back** — The task runs for a row that no longer exists. Use `transaction.on_commit` to defer task dispatch until the transaction commits.

```python
# BAD: task fires before transaction commits
@transaction.atomic
def create_order(request_data):
    order = Order.objects.create(**request_data)
    send_confirmation.delay(order.id)  # May run if outer transaction rolls back
    return order

# GOOD: defer until commit
@transaction.atomic
def create_order(request_data):
    order = Order.objects.create(**request_data)
    transaction.on_commit(lambda: send_confirmation.delay(order.id))
    return order
```

### Testing Pitfalls

**Assuming `CELERY_TASK_ALWAYS_EAGER` makes tests faithful** — Eager mode executes tasks synchronously in the test process. It does not exercise serialization, routing, retries, or worker behavior. It can produce false positives.

```python
# BAD: eager mode hides serialization bugs
@override_settings(CELERY_TASK_ALWAYS_EAGER=True)
def test_task_with_model(self):
    obj = MyModel.objects.create(name='test')
    my_task.delay(obj)  # Runs immediately, no serialization
    # Passes even if task can't serialize the object properly

# GOOD: test the function directly, mock apply_async
@mock.patch('myapp.tasks.my_task.apply_async')
def test_task_routing(self, mock_apply):
    my_task.delay(123)
    mock_apply.assert_called_once_with(args=[123], queue='default')
```

### Operational Pitfalls

**DB connections opened per task without cleanup** — Long-running workers accumulate stale connections. Use `close_old_connections()` at task start or configure `CELERY_WORKER_MAX_TASKS_PER_CHILD`.

```python
from django.db import close_old_connections

@shared_task
def long_running_task(data_id):
    close_old_connections()  # Drop stale DB connections
    # ... task work
```

**Timezone-aware datetimes not surviving naive serialization** — Naive serialization strips timezone info. Always use UTC and ensure serializers preserve timezone awareness.

```python
# BAD: naive datetime loses TZ
from datetime import datetime
send_report.delay(datetime.now())  # Loses timezone in JSON serializer

# GOOD: use UTC-aware datetime
from django.utils import timezone
send_report.delay(timezone.now())  # Preserves TZ through serialization
```

**Settings read at import time break `override_settings` in tests** — Access `django.conf.settings` at call time, not module load time.

```python
# BAD: settings read at import time
from django.conf import settings
BATCH_SIZE = settings.CELERY_BATCH_SIZE  # Fixed at import

@shared_task
def process_batch():
    for i in range(BATCH_SIZE):  # Can't be overridden in tests
        ...

# GOOD: read at call time
@shared_task
def process_batch():
    from django.conf import settings
    batch_size = settings.CELERY_BATCH_SIZE  # Read fresh each call
    for i in range(batch_size):
        ...
```

---

## Testing

### Testing Task Functions Directly

Call the underlying task function directly instead of using `delay()` or `apply_async()`. This tests the actual logic without Celery machinery.

```python
from django.test import TestCase
from myapp.tasks import send_welcome_email

class TaskFunctionTests(TestCase):
    def test_send_welcome_email_logic(self):
        user = User.objects.create_user(username='test', email='test@example.com')
        
        # Call the function directly, bypassing Celery
        send_welcome_email(user.id)
        
        # Assert on side effects
        self.assertEqual(len(mail.outbox), 1)
        self.assertEqual(mail.outbox[0].to, ['test@example.com'])
```

### Mocking `apply_async` to Assert Task Dispatch

Mock `apply_async` to verify that tasks are scheduled with correct arguments and routing.

```python
from unittest import mock
from django.test import TestCase
from myapp.tasks import process_upload

class TaskDispatchTests(TestCase):
    @mock.patch('myapp.tasks.process_upload.apply_async')
    def test_process_upload_scheduled_with_queue(self, mock_apply):
        process_upload.delay(123, queue='heavy')
        
        mock_apply.assert_called_once_with(args=[123], queue='heavy')
    
    @mock.patch('myapp.tasks.send_confirmation.apply_async')
    def test_task_scheduled_after_commit(self, mock_apply):
        with transaction.atomic():
            order = Order.objects.create(total=100)
            transaction.on_commit(lambda: send_confirmation.delay(order.id))
        
        # Verify on_commit callback scheduled the task
        mock_apply.assert_called_once()
```

### Testing Retries Deterministically

Test retry behavior by mocking the retry mechanism and asserting on the `Retry` exception.

```python
from unittest import mock
from celery.exceptions import Retry
from django.test import TestCase
from myapp.tasks import fetch_external_data

class TaskRetryTests(TestCase):
    @mock.patch('myapp.tasks.fetch_external_data.retry')
    def test_fetch_external_data_retries_on_connection_error(self, mock_retry):
        with mock.patch('myapp.tasks.fetch_external_data', side_effect=ConnectionError('timeout')):
            with self.assertRaises(Retry):
                fetch_external_data('http://example.com')
        
        mock_retry.assert_called_once()
    
    def test_fetch_external_data_succeeds_without_retry(self):
        with mock.patch('myapp.tasks.requests.get') as mock_get:
            mock_get.return_value.json.return_value = {'data': 'value'}
            result = fetch_external_data('http://example.com')
        
        self.assertEqual(result, {'data': 'value'})
```

### When Eager Mode Produces False Positives

Eager mode runs tasks synchronously in the test process. It does not test:
- Serialization/deserialization of task arguments
- Task routing and queue configuration
- Retry behavior with actual backoff
- Worker concurrency issues

```python
# FALSE POSITIVE: eager mode passes, but task fails in production
@override_settings(CELERY_TASK_ALWAYS_EAGER=True)
def test_model_instance_passed(self):
    obj = MyModel.objects.create(name='test')
    # This passes in eager mode but fails in production because
    # model instances can't be serialized by JSON serializer
    my_task.delay(obj)  # ERROR: Object of type MyModel is not JSON serializable

# CORRECT: test serialization explicitly
def test_task_argument_serialization(self):
    from celery.backends.base import BaseBackend
    
    obj = MyModel.objects.create(name='test')
    
    # Verify the argument can be serialized
    backend = BaseBackend(None)
    with self.assertRaises(TypeError):
        backend.encode({'obj': obj})  # Should fail for model instances
    
    # Verify ID serializes correctly
    result = backend.encode({'obj_id': obj.id})  # Should pass
    self.assertIn('obj_id', result[0])
```

---

## Deep Dives

Load these reference files on demand for detailed patterns:

- **Tasks & Calling** — `references/tasks.md` — Defining tasks, task options, signatures (chain/group/chord), result checking
- **Scheduling & Workers** — `references/scheduling-workers.md` — django-celery-beat, systemd deployment, cron vs beat decision guide
- **Monitoring & Batch** — `references/monitoring-batch.md` — Flower, health checks, batch processing with savepoints

---

## Ecosystem

### Monitoring

- **flower** (https://github.com/mher/flower) — Web-based Celery cluster admin and monitoring. Real-time task progress, worker stats, task history, broker metrics.
- **celery-exporter** (https://github.com/danihodovic/celery-exporter) — Prometheus metrics exporter for Celery. Exposes task durations, queue lengths, worker status for Grafana dashboards.

### Results & Backends

- **django-celery-results** (https://github.com/celery/django-celery-results) — Django ORM-based result backend. Store task results in Django database instead of Redis/RabbitMQ.

### Cache/Broker Companion

- **django-redis** (https://github.com/jazzband/django-redis) — Full-featured Redis cache backend for Django. Can be used as Celery broker companion for unified Redis infrastructure.

### Alternatives

| Library | Problem it solves | When to choose over Celery |
|---------|-------------------|----------------------------|
| **django-q2** (https://github.com/django-q2/django-q2) | Simple task queue with built-in scheduler, no external broker needed | You want periodic tasks without Redis/RabbitMQ; prefer Django-native scheduler |
| **django-dramatiq** (https://github.com/Bogdanp/django_dramatiq) | High-performance task queue with better retry semantics | You need message acknowledgment guarantees, better observability than Celery |
| **huey** (https://github.com/coleifer/huey) | Minimal task queue, works with SQLite/Redis | Tiny projects, no external broker infrastructure, simple scheduling needs |
| **django-tasks** (https://github.com/realOrangeOne/django-tasks) | Django DEP 14 reference implementation | Evaluating future Django standard task queue API; experimental |

**Selection criteria:** If you already use Celery for a task queue, stick with it. Choose an alternative only if: (1) you need zero external dependencies (huey, django-q2), (2) you require stronger message guarantees (dramatiq), or (3) you're prototyping against future Django standards (django-tasks).

---

## References

- **Celery Docs**: https://docs.celeryq.dev/en/stable/
- **django-celery-beat**: https://django-celery-beat.readthedocs.io/
- **Celery with Django**: https://docs.celeryq.dev/en/stable/django/first-steps-with-django.html
- **Flower**: https://github.com/mher/flower
