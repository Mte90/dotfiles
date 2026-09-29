---
name: celery
description: Use when running background tasks with Celery - worker and broker configuration (Redis, RabbitMQ, SQS), task definitions, chains and chords, Celery Beat periodic tasks, routing, retries, Flower monitoring, or testing tasks with pytest
metadata:
  author: mte90
  version: 2.0.0
  tags:
    - python
    - task-queue
    - async
    - distributed
    - celery
---

# Celery

Complete reference for distributed task processing with Celery.

## Django 6.0 Alternative

For complex Django projects, consider **Django 6.0's built-in task queue** as a simpler alternative to Celery. It provides:

- Native Django integration (no separate broker needed)
- Database-backed task storage
- Simpler deployment (single Django process)
- Standardized interface: `from django.task import task`

**When to choose Django Tasks over Celery:**
- Existing Django project on version 6.0+
- Simpler use cases (single server, moderate load)
- Preference for minimal dependencies
- Database as task storage is acceptable

**When to keep Celery:**
- Multi-server distributed deployment
- High-throughput requirements (1000s of tasks/sec)
- Multiple broker options (Redis, RabbitMQ, etc.)
- Advanced features (task prioritization, complex routing)
- Multi-language support

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

## Deep Dives

For detailed reference on specific topics, load these on-demand:

- **Calling Workflows** (`references/calling-workflows.md`) — Task invocation patterns: `apply_async`, signatures, chains, groups, chords, chunks, and task states
- **Periodic Tasks & Routing** (`references/beat-routing.md`) — Celery Beat scheduling, crontab syntax, django-celery-beat, queue routing
- **Error Handling & Monitoring** (`references/errors-monitoring.md`) — Retries, error callbacks, DLQ, Flower, CLI monitoring, Prometheus
- **Testing & Performance** (`references/testing-performance.md`) — pytest testing, worker configuration, task optimization, memory management, common issues

## References

- **Official Documentation**: https://docs.celeryq.dev/
- **GitHub Repository**: https://github.com/celery/celery
- **Flower Monitoring**: https://github.com/mher/flower
- **Django Celery**: https://github.com/celery/django-celery