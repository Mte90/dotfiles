# Periodic Tasks (Beat) and Task Routing

> Loaded on demand from `../SKILL.md` for detailed scheduling and routing configuration.

## Periodic Tasks (Celery Beat)

### Configuration

```python
# celery.py
from celery.schedules import crontab

app.conf.beat_schedule = {
    # Every 30 seconds
    'add-every-30-seconds': {
        'task': 'myapp.tasks.add',
        'schedule': 30.0,
        'args': (16, 16)
    },
    
    # Crontab schedule
    'cleanup-every-night': {
        'task': 'myapp.tasks.cleanup',
        'schedule': crontab(hour=2, minute=0),
    },
    
    # Every Monday morning
    'weekly-report': {
        'task': 'myapp.tasks.weekly_report',
        'schedule': crontab(hour=7, minute=30, day_of_week=1),
    },
    
    # Every 5 minutes during business hours
    'business-check': {
        'task': 'myapp.tasks.check_status',
        'schedule': crontab(minute='*/5', hour='9-17'),
    },
}

app.conf.timezone = 'UTC'
```

### Crontab Syntax

```python
from celery.schedules import crontab

# Every minute
crontab()

# Every hour at minute 0
crontab(minute=0)

# Every day at midnight
crontab(hour=0, minute=0)

# Every Monday at 8:30 AM
crontab(hour=8, minute=30, day_of_week=1)

# Every 15 minutes
crontab(minute='*/15')

# First day of every month
crontab(hour=0, minute=0, day_of_month=1)

# Every weekday (Mon-Fri) at 6 PM
crontab(hour=18, minute=0, day_of_week='1-5')

# Specific months
crontab(hour=0, minute=0, day_of_month=1, month_of_year='1,4,7,10')
```

### django-celery-beat

```python
# Install: pip install django-celery-beat

# settings.py
INSTALLED_APPS = [
    # ...
    'django_celery_beat',
]

# Use database-backed schedule
CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'

# Now manage periodic tasks via Django admin
```

```python
# Create periodic task programmatically
from django_celery_beat.models import PeriodicTask, IntervalSchedule

# Create interval
schedule, _ = IntervalSchedule.objects.get_or_create(
    every=10,
    period=IntervalSchedule.SECONDS,
)

# Create task
PeriodicTask.objects.create(
    interval=schedule,
    name='my-periodic-task',
    task='myapp.tasks.my_task',
    args=json.dumps(['arg1', 'arg2']),
    kwargs=json.dumps({'key': 'value'}),
)

# Crontab schedule
from django_celery_beat.models import CrontabSchedule

schedule, _ = CrontabSchedule.objects.get_or_create(
    minute='0',
    hour='*',
    day_of_week='*',
    day_of_month='*',
    month_of_year='*',
)

PeriodicTask.objects.create(
    crontab=schedule,
    name='hourly-task',
    task='myapp.tasks.hourly',
)
```

## Task Routing

### Queue Routing

```python
# settings.py
CELERY_TASK_ROUTES = {
    'myapp.tasks.send_email': {
        'queue': 'email',
    },
    'myapp.tasks.process_video': {
        'queue': 'video',
        'routing_key': 'video.process',
    },
    'myapp.tasks.*': {
        'queue': 'default',
    },
}

# Or use task decorator
@shared_task(queue='email')
def send_email(to, subject, body):
    pass

# Or specify when calling
send_email.apply_async(args=[], queue='priority')
```

### Automatic Routing

```python
# celery.py
def route_task(name, args, kwargs, options, task=None, **kw):
    """Custom routing function."""
    if name.startswith('myapp.email.'):
        return {'queue': 'email'}
    if name.startswith('myapp.video.'):
        return {'queue': 'video', 'routing_key': 'video.high'}
    return {'queue': 'default'}

app.conf.task_routes = (route_task,)
```

### Worker Queues

```bash
# Start worker for specific queues
celery -A myproject worker -Q email,video -n worker1@%h

# Multiple workers for different queues
celery -A myproject worker -Q email -n email_worker@%h --concurrency=4
celery -A myproject worker -Q video -n video_worker@%h --concurrency=2
celery -A myproject worker -Q default -n default_worker@%h
```