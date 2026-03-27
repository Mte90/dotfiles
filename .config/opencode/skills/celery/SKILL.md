---
name: celery
description: "Distributed task queue for Python supporting Redis, RabbitMQ, periodic scheduling, real-time processing, and Django integration"
metadata:
  author: "OSS AI Skills"
  version: "1.0.0"
  tags:
    - python
    - task-queue
    - async
    - distributed
    - celery
---

# Celery

Complete reference for distributed task processing with Celery.

## Overview

Celery is a distributed task queue system for Python that enables asynchronous task execution, scheduled tasks, and real-time processing.

**Key Features:**
- Distributed: Run workers across multiple machines
- Brokers: Redis, RabbitMQ, SQS, and more
- Scheduled tasks: Periodic execution with Celery Beat
- Real-time: Task monitoring and result tracking
- Scalable: Easy horizontal scaling

### Architecture

```
Producer → Broker → Worker → Result Backend
   ↓          ↓         ↓          ↓
 Task      Queue   Consumer    Storage
```

### When to Use Celery

- Email sending
- Image/video processing
- Report generation
- Web scraping
- Scheduled maintenance tasks
- Long-running computations
- Third-party API calls

## Installation

```bash
pip install celery

# With Redis broker (recommended)
pip install celery[redis]

# With RabbitMQ broker
pip install celery[amqp]

# With Django
pip install django-celery-beat django-celery-results
```

### Basic Configuration

```python
# celery_config.py or celery.py
from celery import Celery

# Create app
app = Celery('myapp')

# Configure from Django settings
app.config_from_object('django.conf:settings', namespace='CELERY')

# Or configure directly
app.conf.update(
    broker_url='redis://localhost:6379/0',
    result_backend='redis://localhost:6379/0',
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,
)
```

### Django Integration

```python
# myproject/celery.py
import os
from celery import Celery

# Set default Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myproject.settings')

app = Celery('myproject')

# Load config from Django settings with CELERY_ prefix
app.config_from_object('django.conf:settings', namespace='CELERY')

# Auto-discover tasks in installed apps
app.autodiscover_tasks()

# myproject/__init__.py
from .celery import app as celery_app

__all__ = ('celery_app',)

# settings.py
CELERY_BROKER_URL = 'redis://localhost:6379/0'
CELERY_RESULT_BACKEND = 'redis://localhost:6379/0'
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = 'UTC'
```

### Project Structure

```
myproject/
├── celery.py
├── __init__.py
├── settings.py
└── apps/
    └── myapp/
        ├── tasks.py
        └── __init__.py
```

## Brokers

### Redis

```python
# Basic Redis configuration
CELERY_BROKER_URL = 'redis://localhost:6379/0'
CELERY_RESULT_BACKEND = 'redis://localhost:6379/1'

# Redis with authentication
CELERY_BROKER_URL = 'redis://:password@localhost:6379/0'

# Redis Sentinel for HA
CELERY_BROKER_URL = 'sentinel://localhost:26379/0;sentinel://localhost:26380/0;sentinel://localhost:26381/0'
CELERY_BROKER_TRANSPORT_OPTIONS = {
    'master_name': 'mymaster',
}

# Redis with SSL
CELERY_BROKER_URL = 'rediss://localhost:6379/0'
CELERY_BROKER_TRANSPORT_OPTIONS = {
    'ssl_cert_reqs': 'required',
}
```

### RabbitMQ

```python
# Basic RabbitMQ configuration
CELERY_BROKER_URL = 'amqp://guest:guest@localhost:5672//'

# RabbitMQ with authentication
CELERY_BROKER_URL = 'amqp://user:password@localhost:5672/vhost'

# RabbitMQ with SSL
CELERY_BROKER_URL = 'amqps://user:password@localhost:5671/vhost'
CELERY_BROKER_TRANSPORT_OPTIONS = {
    'ssl_cert_reqs': 'required',
}
```

### Amazon SQS

```python
CELERY_BROKER_URL = 'sqs://aws_access_key:aws_secret_key@'

CELERY_BROKER_TRANSPORT_OPTIONS = {
    'region': 'us-east-1',
    'visibility_timeout': 3600,
    'polling_interval': 1,
}
```

## Result Backends

### Redis

```python
CELERY_RESULT_BACKEND = 'redis://localhost:6379/0'

# With expiration
CELERY_RESULT_EXPIRES = 3600  # 1 hour
```

### Database (Django)

```python
# Install: pip install django-celery-results
INSTALLED_APPS = [
    # ...
    'django_celery_results',
]

CELERY_RESULT_BACKEND = 'django-db'
CELERY_CACHE_BACKEND = 'django-cache'
```

### RPC

```python
# Results sent back as AMQP messages
CELERY_RESULT_BACKEND = 'rpc://'
```

## Task Definitions

### Basic Task

```python
from celery import shared_task

@shared_task
def add(x, y):
    """Simple addition task."""
    return x + y

@shared_task
def send_email(to, subject, body):
    """Send email task."""
    # Email sending logic
    send_mail(subject, body, 'from@example.com', [to])
    return f"Email sent to {to}"
```

### Task Options

```python
from celery import shared_task

@shared_task(
    name='myapp.process_data',      # Custom task name
    bind=True,                       # Access to task instance
    max_retries=3,                   # Max retry attempts
    default_retry_delay=60,          # Delay between retries (seconds)
    autoretry_for=(Exception,),      # Auto-retry on these exceptions
    retry_backoff=True,              # Exponential backoff
    retry_backoff_max=600,           # Max backoff delay
    retry_jitter=True,               # Add jitter to backoff
    time_limit=300,                  # Hard time limit (seconds)
    soft_time_limit=240,             # Soft time limit
    rate_limit='10/m',               # Rate limiting
    ignore_result=False,             # Store result
    store_errors_even_if_ignored=True,
)
def process_data(self, data_id):
    """Process data with full task options."""
    try:
        data = Data.objects.get(id=data_id)
        result = data.process()
        return result
    except Data.DoesNotExist:
        raise self.retry(countdown=60)
    except Exception as exc:
        raise self.retry(exc=exc, countdown=60)
```

### Bound Tasks

```python
@shared_task(bind=True)
def bound_task(self, x, y):
    """Task with access to task instance."""
    # Access task ID
    task_id = self.request.id
    
    # Access retries count
    retries = self.request.retries
    
    # Update task state
    self.update_state(
        state='PROGRESS',
        meta={'current': 50, 'total': 100}
    )
    
    # Retry manually
    try:
        return risky_operation(x, y)
    except Exception as exc:
        raise self.retry(exc=exc, countdown=5)
```

### Task Inheritance

```python
from celery import Task

class DatabaseTask(Task):
    """Custom task base class with database session."""
    _db = None
    
    @property
    def db(self):
        if self._db is None:
            self._db = DatabaseSession()
        return self._db
    
    def after_return(self, *args, **kwargs):
        if self._db is not None:
            self._db.close()
            self._db = None

@shared_task(base=DatabaseTask, bind=True)
def database_task(self, record_id):
    """Task using custom base class."""
    record = self.db.query(Record).get(record_id)
    return record.process()
```

### Task Signals

```python
from celery import signals

@signals.task_prerun.connect
def task_prerun_handler(sender=None, task_id=None, task=None, **kwargs):
    """Called before task execution."""
    print(f"Task {task.name}[{task_id}] starting...")

@signals.task_postrun.connect
def task_postrun_handler(sender=None, task_id=None, task=None, retval=None, **kwargs):
    """Called after task execution."""
    print(f"Task {task.name}[{task_id}] completed with result: {retval}")

@signals.task_failure.connect
def task_failure_handler(sender=None, task_id=None, exception=None, **kwargs):
    """Called on task failure."""
    print(f"Task {task_id} failed: {exception}")

@signals.task_retry.connect
def task_retry_handler(sender=None, reason=None, **kwargs):
    """Called on task retry."""
    print(f"Task retrying: {reason}")
```

## Calling Tasks

### Basic Calls

```python
# Apply async (recommended)
result = add.apply_async((2, 3))

# Using delay (shortcut for apply_async)
result = add.delay(2, 3)

# Get result
value = result.get()  # Blocks until ready
value = result.get(timeout=10)  # With timeout

# Check status
result.ready()  # True if completed
result.successful()  # True if successful
result.failed()  # True if failed
result.state  # PENDING, STARTED, SUCCESS, FAILURE, RETRY, REVOKED
```

### apply_async Options

```python
# Countdown (delay in seconds)
result = add.apply_async((2, 3), countdown=60)

# ETA (specific time)
from datetime import datetime, timedelta
eta = datetime.utcnow() + timedelta(hours=1)
result = add.apply_async((2, 3), eta=eta)

# Expires
result = add.apply_async((2, 3), expires=3600)  # 1 hour

# Specific queue
result = add.apply_async((2, 3), queue='high_priority')

# Specific worker
result = add.apply_async((2, 3), worker='worker1@hostname')

# Retry policy
result = add.apply_async(
    (2, 3),
    retry=True,
    retry_policy={
        'max_retries': 3,
        'interval_start': 0,
        'interval_step': 0.2,
        'interval_max': 0.5,
    }
)

# Priority (0-255, higher = more important)
result = add.apply_async((2, 3), priority=10)

# Custom task ID
result = add.apply_async((2, 3), task_id='custom-task-id')

# Compression
result = add.apply_async((large_data,), compression='gzip')
```

### Signatures

```python
from celery import signature

# Create signature
s = add.s(2, 3)
s.apply_async()

# Partial signature (immutable)
s = add.s(2)  # First argument fixed
s.apply_async(args=(3,))  # Will call add(2, 3)

# Signature with options
s = add.s(2, 3).set(countdown=10).set(queue='priority')
s.apply_async()

# Clone signature
s2 = s.clone(args=(4, 5))
```

### Chains

```python
from celery import chain

# Sequential execution
workflow = chain(add.s(2, 3), add.s(4), add.s(5))
result = workflow.apply_async()
# add(2, 3) → add(result, 4) → add(result, 5)

# Pipe notation
workflow = add.s(2, 3) | add.s(4) | add.s(5)
result = workflow.apply_async()

# With error handling
workflow = chain(
    validate_data.s(data_id),
    process_data.s(),
    save_result.s()
)
result = workflow.apply_async()
```

### Groups

```python
from celery import group

# Parallel execution
job = group(add.s(i, i) for i in range(10))
result = job.apply_async()

# Get all results
values = result.get()  # [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]

# Check completion
result.ready()  # True when all complete
result.completed_count()  # Number completed

# Group with callback
job = group(process_item.s(item_id) for item_id in items)
callback = summarize_results.s()
workflow = job | callback
result = workflow.apply_async()
```

### Chords

```python
from celery import chord

# Group with callback (parallel + callback)
callback = summarize.s()
header = [process_item.s(item_id) for item_id in items]
result = chord(header)(callback)

# All header tasks run in parallel, then callback receives results
@shared_task
def summarize(results):
    return sum(results)

# Example: Process order
workflow = chord(
    group(
        validate_inventory.s(item_id) 
        for item_id in order_items
    ),
    create_shipment.s(order_id)
)
result = workflow.apply_async()
```

### Chunks

```python
# Split large task into chunks
@shared_task
def process_chunk(items):
    return [process_item(item) for item in items]

# Process 100 items in chunks of 10
items = list(range(100))
result = process_chunk.chunks(items, 10).apply_async()
```

## Task States

### Built-in States

```python
from celery.result import AsyncResult

result = add.delay(2, 3)

# States
result.state
# PENDING    - Task waiting to execute
# STARTED    - Task started
# SUCCESS    - Task completed successfully
# FAILURE    - Task failed
# RETRY      - Task being retried
# REVOKED    - Task revoked

# Check state
if result.successful():
    print(f"Result: {result.result}")
elif result.failed():
    print(f"Error: {result.result}")
```

### Custom States

```python
@shared_task(bind=True)
def long_task(self, total):
    """Task with progress tracking."""
    for i in range(total):
        # Update progress
        self.update_state(
            state='PROGRESS',
            meta={
                'current': i + 1,
                'total': total,
                'status': 'Processing...'
            }
        )
        time.sleep(1)
    
    return {'result': 'completed'}

# Check custom state
result = long_task.delay(10)
if result.state == 'PROGRESS':
    progress = result.info
    print(f"{progress['current']}/{progress['total']}")
```

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

## Testing

### pytest Configuration

```python
# conftest.py
import pytest
from celery import Celery

@pytest.fixture(scope='session')
def celery_app():
    """Create test Celery app."""
    app = Celery('test_app')
    app.config_from_object({
        'broker_url': 'memory://',
        'result_backend': 'cache+memory://',
        'task_always_eager': True,  # Execute synchronously
        'task_eager_propagates': True,  # Propagate exceptions
    })
    return app

@pytest.fixture
def celery_worker(celery_app):
    """Create test worker."""
    from celery.contrib.testing import worker
    with worker.start_worker(celery_app):
        yield celery_app
```

### Unit Tests

```python
# tests/test_tasks.py
import pytest
from myapp.tasks import add, send_email

# Synchronous testing (eager mode)
@pytest.mark.celery(task_always_eager=True)
def test_add_task(celery_app):
    """Test add task executes synchronously."""
    result = add.delay(2, 3)
    assert result.get() == 5

# Mock task
def test_send_email_task(mocker):
    """Test send_email task with mocked send."""
    mock_send = mocker.patch('myapp.tasks.send_mail')
    
    send_email.delay('to@example.com', 'Subject', 'Body')
    
    mock_send.assert_called_once_with(
        'Subject', 'Body', 'from@example.com', ['to@example.com']
    )

# Test with fixtures
@pytest.fixture
def mock_email_backend():
    """Mock email backend."""
    with patch('myapp.tasks.send_mail') as mock:
        yield mock

def test_email_task_with_fixture(mock_email_backend):
    send_email.delay('test@example.com', 'Test', 'Body')
    assert mock_email_backend.called
```

### Integration Tests

```python
# tests/test_integration.py
import pytest
from celery.result import AsyncResult

@pytest.mark.integration
def test_task_execution(celery_worker):
    """Test real task execution with worker."""
    result = add.apply_async(args=(10, 20))
    
    # Wait for result
    value = result.get(timeout=10)
    
    assert value == 30
    assert result.successful()

@pytest.mark.integration
def test_task_retry(celery_worker):
    """Test task retry behavior."""
    from myapp.tasks import flaky_task
    
    result = flaky_task.apply_async()
    
    # Should eventually succeed after retries
    value = result.get(timeout=30)
    assert value is not None
```

## Performance

### Concurrency

```python
# Worker configuration
CELERY_WORKER_CONCURRENCY = 4  # Number of worker processes

# Prefetch limit
CELERY_WORKER_PREFETCH_MULTIPLIER = 4  # Tasks per worker

# For long tasks, reduce prefetch
CELERY_WORKER_PREFETCH_MULTIPLIER = 1
```

```bash
# Start with specific concurrency
celery -A myproject worker --concurrency=4

# Use eventlet for I/O-bound tasks
celery -A myproject worker --pool=eventlet --concurrency=100

# Use gevent
celery -A myproject worker --pool=gevent --concurrency=100
```

### Task Optimization

```python
# Avoid database queries in loops
@shared_task
def process_items_bad(item_ids):
    """Bad: N database queries."""
    results = []
    for item_id in item_ids:
        item = Item.objects.get(id=item_id)  # N queries!
        results.append(item.process())
    return results

@shared_task
def process_items_good(item_ids):
    """Good: 1 database query."""
    items = Item.objects.filter(id__in=item_ids)
    return [item.process() for item in items]

# Use bulk operations
@shared_task
def bulk_update_items(updates):
    """Use bulk_update for efficiency."""
    items = []
    for item_id, data in updates:
        item = Item(id=item_id, **data)
        items.append(item)
    
    Item.objects.bulk_update(
        items,
        ['field1', 'field2', 'field3']
    )
```

### Memory Management

```python
# Process large datasets in chunks
@shared_task
def process_large_dataset(dataset_id):
    """Process large dataset without loading all into memory."""
    dataset = Dataset.objects.get(id=dataset_id)
    
    # Use iterator to avoid loading all records
    for batch in dataset.records.iterator(chunk_size=1000):
        process_batch(batch)

# Configure max tasks per worker
CELERY_WORKER_MAX_TASKS_PER_CHILD = 1000  # Restart after 1000 tasks

# Memory limit
CELERY_WORKER_MAX_MEMORY_PER_CHILD = 400000  # 400MB
```

## Best Practices

### 1. Idempotent Tasks

```python
@shared_task(bind=True)
def process_payment(self, payment_id):
    """Idempotent payment processing."""
    payment = Payment.objects.select_for_update().get(id=payment_id)
    
    # Check if already processed
    if payment.status == 'completed':
        return {'status': 'already_processed'}
    
    # Process only once
    with transaction.atomic():
        result = payment.charge()
        payment.mark_completed()
    
    return result
```

### 2. Proper Error Handling

```python
@shared_task(bind=True, autoretry_for=(Exception,), max_retries=3)
def robust_task(self, data_id):
    """Task with proper error handling."""
    try:
        data = Data.objects.get(id=data_id)
    except Data.DoesNotExist:
        # Log and don't retry
        logger.error(f"Data {data_id} not found")
        return None
    
    try:
        return data.process()
    except ExternalAPIError as exc:
        # Retry with backoff
        raise self.retry(exc=exc, countdown=2 ** self.request.retries)
    except Exception as exc:
        # Unexpected error - log and retry
        logger.exception(f"Unexpected error processing {data_id}")
        raise
```

### 3. Task Granularity

```python
# Bad: One monolithic task
@shared_task
def process_order_bad(order_id):
    order = Order.objects.get(id=order_id)
    order.validate()
    order.charge()
    order.ship()
    order.send_confirmation()

# Good: Smaller, focused tasks
@shared_task
def validate_order(order_id):
    order = Order.objects.get(id=order_id)
    order.validate()
    charge_order.delay(order_id)

@shared_task
def charge_order(order_id):
    order = Order.objects.get(id=order_id)
    order.charge()
    ship_order.delay(order_id)

@shared_task
def ship_order(order_id):
    order = Order.objects.get(id=order_id)
    order.ship()
    send_confirmation.delay(order_id)
```

### 4. Use Task Queues Appropriately

```python
# Route different task types to different queues
@shared_task(queue='high_priority')
def send_password_reset(user_id):
    """Time-sensitive task."""
    pass

@shared_task(queue='low_priority')
def generate_report(user_id):
    """Background task."""
    pass

@shared_task(queue='compute')
def process_video(video_id):
    """CPU-intensive task."""
    pass
```

## Common Issues

### Issue: Tasks Stuck in PENDING

**Problem**: Tasks never execute.

**Solution**:
```bash
# Check worker is running
celery -A myproject inspect active

# Check worker is consuming from correct queue
celery -A myproject worker -Q myqueue

# Check broker connection
celery -A myproject inspect ping
```

### Issue: Memory Leaks

**Problem**: Worker memory grows over time.

**Solution**:
```python
# Limit tasks per worker
CELERY_WORKER_MAX_TASKS_PER_CHILD = 1000

# Or limit memory
CELERY_WORKER_MAX_MEMORY_PER_CHILD = 400000  # KB

# Avoid circular references in tasks
@shared_task
def task_with_cleanup():
    try:
        return process()
    finally:
        # Clean up resources
        cleanup()
```

### Issue: Duplicate Task Execution

**Problem**: Task executed multiple times.

**Solution**:
```python
# Use idempotent tasks
@shared_task(bind=True)
def idempotent_task(self, data_id):
    with transaction.atomic():
        # Lock record
        data = Data.objects.select_for_update().get(id=data_id)
        
        if data.processed:
            return {'status': 'already_processed'}
        
        result = data.process()
        data.processed = True
        data.save()
    
    return result

# Or use task deduplication
CELERY_TASK_ANNOTATIONS = {
    'myapp.tasks.*': {
        'acks_late': True,
        'reject_on_worker_lost': True,
    }
}
```

## References

- **Official Documentation**: https://docs.celeryq.dev/
- **GitHub Repository**: https://github.com/celery/celery
- **Flower Monitoring**: https://github.com/mher/flower
- **Django Celery**: https://github.com/celery/django-celery
