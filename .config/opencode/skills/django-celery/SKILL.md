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

## Best Practices

### Task Design

1. **Keep tasks small and idempotent** - Tasks may be retried
2. **Pass IDs, not model instances** - Serialize only primitives
3. **Use `bind=True` for retry** - Access `self.retry()`
4. **Set time limits** - Prevent stuck tasks
5. **Use `ignore_result=True`** when you don't need the return value

```python
# BAD: passing model instance
@shared_task
def process(user):
    pass

# GOOD: passing ID
@shared_task
def process(user_id):
    from myapp.models import User
    user = User.objects.get(pk=user_id)
    pass
```

### Error Handling

```python
from celery import shared_task
from celery.utils.log import get_task_logger

logger = get_task_logger(__name__)

@shared_task(bind=True, max_retries=3)
def reliable_task(self, data_id):
    try:
        result = do_work(data_id)
        return result
    except TemporaryError as exc:
        logger.warning(f"Temporary failure for {data_id}: {exc}")
        self.retry(exc=exc, countdown=60 * (self.request.retries + 1))
    except PermanentError as exc:
        logger.error(f"Permanent failure for {data_id}: {exc}")
        raise

@shared_task(bind=True)
def task_with_callback(self, data_id):
    try:
        result = do_work(data_id)
    except Exception as exc:
        self.update_state(state='FAILED', meta={'error': str(exc)})
        raise
```

### Testing

```python
from django.test import TestCase, override_settings
from myapp.tasks import send_welcome_email

@override_settings(CELERY_TASK_ALWAYS_EAGER=True, CELERY_TASK_EAGER_PROPAGATES=True)
class TaskTests(TestCase):
    def test_send_welcome_email(self):
        user = User.objects.create_user(username='test', email='test@example.com')
        send_welcome_email(user.id)
        self.assertEqual(len(mail.outbox), 1)
        self.assertEqual(mail.outbox[0].to, ['test@example.com'])
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

For lighter-weight task queues or different use cases:
- **django-q2** (https://github.com/django-q2/django-q2) — Simple Django task queue with own scheduler
- **django-dramatiq** (https://github.com/Bogdanp/django_dramatiq) — Dramatiq integration for Django (alternative Celery-style queue)
- **huey** (https://github.com/coleifer/huey) — Lightweight task queue with Django integration
- **django-tasks** (https://github.com/realOrangeOne/django-tasks) — Reference implementation for background workers (Django DEP 14)

---

## References

- **Celery Docs**: https://docs.celeryq.dev/en/stable/
- **django-celery-beat**: https://django-celery-beat.readthedocs.io/
- **Celery with Django**: https://docs.celeryq.dev/en/stable/django/first-steps-with-django.html
- **Flower**: https://github.com/mher/flower