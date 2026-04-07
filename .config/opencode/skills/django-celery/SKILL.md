---
name: django-celery
description: "Django Celery integration - distributed tasks, periodic scheduling with django-celery-beat, monitoring, best practices"
metadata:
  author: OSS AI Skills
  version: 1.0.0
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

# Set default Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'proj.settings')

app = Celery('proj')

# Load config from Django settings with CELERY_ prefix
app.config_from_object('django.conf:settings', namespace='CELERY')

# Auto-discover tasks.py in each Django app
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
    # ...
    'django_celery_beat',
    'myapp',
]

# Broker
CELERY_BROKER_URL = 'redis://localhost:6379/0'

# Result backend (optional, for tracking task results)
CELERY_RESULT_BACKEND = 'redis://localhost:6379/1'

# Serialization
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'

# Timezone
CELERY_TIMEZONE = 'Europe/Rome'
CELERY_ENABLE_UTC = True

# django-celery-beat scheduler
CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'

# Task execution limits
CELERY_TASK_SOFT_TIME_LIMIT = 300  # 5 minutes soft limit
CELERY_TASK_TIME_LIMIT = 600       # 10 minutes hard limit

# Retry policy
CELERY_TASK_DEFAULT_RETRY_DELAY = 60
CELERY_TASK_DEFAULT_MAX_RETRIES = 3

# Task routing (optional)
CELERY_TASK_ROUTES = {
    'myapp.tasks.send_email': {'queue': 'emails'},
    'myapp.tasks.process_video': {'queue': 'heavy'},
}

# Worker settings
CELERY_WORKER_PREFETCH_MULTIPLIER = 1  # Fair scheduling for long tasks
CELERY_WORKER_MAX_TASKS_PER_CHILD = 1000  # Restart worker after N tasks (prevent memory leaks)
```

### Database Migration

```bash
python manage.py migrate django_celery_beat
```

---

## Defining Tasks

### In `myapp/tasks.py`

```python
from celery import shared_task
from django.core.mail import send_mail
from django.conf import settings
import logging

logger = logging.getLogger(__name__)


@shared_task
def send_welcome_email(user_id):
    """Send welcome email to a new user."""
    from myapp.models import User
    
    try:
        user = User.objects.get(pk=user_id)
        send_mail(
            subject='Welcome!',
            message=f'Hello {user.username}, welcome to our platform.',
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
            fail_silently=False,
        )
        logger.info(f"Welcome email sent to user {user_id}")
    except User.DoesNotExist:
        logger.error(f"User {user_id} not found")


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def process_upload(self, upload_id):
    """Process an uploaded file with retry on failure."""
    from myapp.models import Upload
    
    try:
        upload = Upload.objects.get(pk=upload_id)
        upload.process()
    except Upload.ProcessingError as exc:
        logger.warning(f"Upload {upload_id} failed, retrying: {exc}")
        self.retry(exc=exc)
    except Upload.DoesNotExist:
        logger.error(f"Upload {upload_id} not found")


@shared_task
def cleanup_expired_sessions():
    """Remove expired sessions (periodic task)."""
    from django.contrib.sessions.models import Session
    deleted, _ = Session.objects.filter(expire_date__lt=timezone.now()).delete()
    logger.info(f"Cleaned up {deleted} expired sessions")


@shared_task
def generate_report(report_type, date_from, date_to, recipient_email):
    """Generate and email a report."""
    from myapp.services import ReportGenerator
    
    report = ReportGenerator.generate(report_type, date_from, date_to)
    report.send_to(recipient_email)
    return {'report_id': report.id, 'rows': report.row_count}
```

### Task Options

```python
# Ignore result (don't store in backend)
@shared_task(ignore_result=True)
def log_event(event_data):
    pass

# Rate limiting (10 tasks per minute)
@shared_task(rate_limit='10/m')
def send_notification(user_id, message):
    pass

# Time limits
@shared_task(time_limit=120, soft_time_limit=90)
def quick_process(data):
    pass

# Retry with exponential backoff
@shared_task(bind=True, autoretry_for=(ConnectionError,), retry_backoff=True, retry_kwargs={'max_retries': 5})
def fetch_external_api(url):
    pass

# Custom queue
@shared_task(queue='heavy')
def process_large_file(file_id):
    pass
```

---

## Calling Tasks

### From Views

```python
from django.http import JsonResponse
from myapp.tasks import send_welcome_email, process_upload

def register_view(request):
    user = User.objects.create_user(...)
    
    # Fire and forget
    send_welcome_email.delay(user.id)
    
    return JsonResponse({'status': 'ok'})


def upload_view(request):
    upload = Upload.objects.create(file=request.FILES['file'])
    
    # With countdown (run in 30 seconds)
    process_upload.apply_async(args=[upload.id], countdown=30)
    
    return JsonResponse({'upload_id': upload.id})
```

### Task Signatures Patterns

```python
from celery import chain, group, chord

# Chain: tasks run sequentially, output feeds into next
workflow = chain(
    process_data.s(file_id),
    validate_data.s(),
    save_results.s(user_id)
)
workflow.apply_async()

# Group: tasks run in parallel
from myapp.tasks import send_email
job = group(
    send_email.s(user.id, "subject", "body") for user in users
)
result = job.apply_async()

# Chord: group + callback
chord(
    [process_chunk.s(chunk_id) for chunk_id in chunk_ids],
    finalize_report.s(report_id)
).apply_async()
```

### Checking Results

```python
from myapp.tasks import generate_report

# Get task ID
result = generate_report.delay('monthly', '2025-01-01', '2025-01-31', 'admin@example.com')
task_id = result.id

# Check status (requires result backend)
from celery.result import AsyncResult
task = AsyncResult(task_id)

task.status      # 'PENDING', 'STARTED', 'SUCCESS', 'FAILURE', 'RETRY'
task.result      # Return value on success, exception on failure
task.ready()     # True if completed
task.successful()  # True if completed successfully
```

---

## Periodic Tasks with django-celery-beat

### Django Admin Configuration

`django-celery-beat` stores schedules in the database. Configure via Django admin or programmatically.

### Programmatic Schedules

In `myapp/schedule.py` or a data migration:

```python
from django_celery_beat.models import PeriodicTask, CrontabSchedule, IntervalSchedule

# Every 5 minutes
interval = IntervalSchedule.objects.create(every=5, period=IntervalSchedule.MINUTES)
PeriodicTask.objects.create(
    interval=interval,
    name='cleanup-sessions',
    task='myapp.tasks.cleanup_expired_sessions',
)

# Crontab: every day at 2:00 AM
crontab = CrontabSchedule.objects.create(
    hour=2,
    minute=0,
    timezone='Europe/Rome',
)
PeriodicTask.objects.create(
    crontab=crontab,
    name='daily-report',
    task='myapp.tasks.generate_daily_report',
    args=json.dumps(['daily']),
)

# Crontab: every Monday at 9:00 AM
weekly = CrontabSchedule.objects.create(
    hour=9,
    minute=0,
    day_of_week=1,
)
PeriodicTask.objects.create(
    crontab=weekly,
    name='weekly-summary',
    task='myapp.tasks.generate_weekly_summary',
)

# Crontab: every 15 minutes during business hours
business = CrontabSchedule.objects.create(
    minute='*/15',
    hour='9-17',
    day_of_week='1-5',
)
PeriodicTask.objects.create(
    crontab=business,
    name='sync-inventory',
    task='myapp.tasks.sync_inventory',
)
```

### Dynamic Schedules from Models

```python
from django.db import models
from django_celery_beat.models import PeriodicTask, CrontabSchedule
import json


class ScheduledReport(models.Model):
    name = models.CharField(max_length=200)
    hour = models.IntegerField(default=8)
    minute = models.IntegerField(default=0)
    day_of_week = models.CharField(max_length=20, default='*')
    is_active = models.BooleanField(default=True)
    periodic_task = models.ForeignKey(
        PeriodicTask, null=True, blank=True, on_delete=models.SET_NULL
    )

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        self._update_schedule()

    def _update_schedule(self):
        if self.is_active:
            crontab, _ = CrontabSchedule.objects.get_or_create(
                hour=self.hour,
                minute=self.minute,
                day_of_week=self.day_of_week,
            )
            if self.periodic_task:
                self.periodic_task.crontab = crontab
                self.periodic_task.save()
            else:
                self.periodic_task = PeriodicTask.objects.create(
                    crontab=crontab,
                    name=f'report-{self.pk}',
                    task='myapp.tasks.generate_report',
                    args=json.dumps([self.pk]),
                )
                super().save(update_fields=['periodic_task'])
        elif self.periodic_task:
            self.periodic_task.delete()
            self.periodic_task = None
            super().save(update_fields=['periodic_task'])
```

---

## Running Workers

### Development

```bash
# Start worker
celery -A proj worker --loglevel=info

# Start beat scheduler (django-celery-beat)
celery -A proj beat -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler

# Or run both together (development only)
celery -A proj worker -B -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler
```

### Production (systemd)

`/etc/systemd/system/celery-worker.service`:

```ini
[Unit]
Description=Celery Worker
After=network.target redis.service

[Service]
Type=forking
User=www-data
Group=www-data
WorkingDirectory=/opt/myapp
ExecStart=/opt/myapp/venv/bin/celery -A proj multi start worker \
    --pidfile=/var/run/celery/%n.pid \
    --logfile=/var/log/celery/%n%I.log \
    --loglevel=INFO \
    --concurrency=4 \
    --max-tasks-per-child=1000
ExecStop=/opt/myapp/venv/bin/celery multi stopwait worker \
    --pidfile=/var/run/celery/%n.pid
ExecReload=/opt/myapp/venv/bin/celery -A proj multi restart worker \
    --pidfile=/var/run/celery/%n.pid \
    --logfile=/var/log/celery/%n%I.log \
    --loglevel=INFO
Restart=always

[Install]
WantedBy=multi-user.target
```

`/etc/systemd/system/celery-beat.service`:

```ini
[Unit]
Description=Celery Beat Scheduler
After=network.target redis.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/myapp
ExecStart=/opt/myapp/venv/bin/celery -A proj beat \
    --scheduler django_celery_beat.schedulers:DatabaseScheduler \
    --pidfile=/var/run/celery/beat.pid \
    --logfile=/var/log/celery/beat.log \
    --loglevel=INFO
Restart=always

[Install]
WantedBy=multi-user.target
```

---

## Monitoring

### Flower (Web UI)

```bash
pip install flower
celery -A proj flower --port=5555
```

Access at `http://localhost:5555`. Features:
- Real-time task progress and status
- Worker monitoring
- Task history and statistics
- Broker metrics

### Django Admin Integration

`django-celery-beat` models appear in Django admin:
- **Crontab schedules** - Cron-like schedules
- **Interval schedules** - Run every N seconds/minutes/hours
- **Periodic tasks** - Task + schedule binding
- **Solar schedules** - Sun-based events (sunrise, sunset)
- **Clocked schedules** - One-time tasks at specific time

### Health Checks

```python
from django.core.management.base import BaseCommand
from celery import current_app


class Command(BaseCommand):
    help = 'Check Celery worker health'

    def handle(self, *args, **options):
        inspect = current_app.control.inspect()
        
        # Active workers
        active = inspect.active()
        if not active:
            self.stderr.write("No active workers!")
            return
        
        for worker, tasks in active.items():
            self.stdout.write(f"{worker}: {len(tasks)} active tasks")
        
        # Registered tasks
        registered = inspect.registered()
        for worker, tasks in registered.items():
            self.stdout.write(f"{worker}: {len(tasks)} registered tasks")
        
        # Queue length
        reserved = inspect.reserved()
        for worker, tasks in reserved.items():
            self.stdout.write(f"{worker}: {len(tasks)} reserved tasks")
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
        raise  # No retry


@shared_task(bind=True)
def task_with_callback(self, data_id):
    try:
        result = do_work(data_id)
    except Exception as exc:
        # Send failure notification
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

## References

- **Celery Docs**: https://docs.celeryq.dev/en/stable/
- **django-celery-beat**: https://django-celery-beat.readthedocs.io/
- **Celery with Django**: https://docs.celeryq.dev/en/stable/django/first-steps-with-django.html
- **Flower**: https://github.com/mher/flower