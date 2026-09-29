Loaded on demand from ../SKILL.md — Monitoring and Batch Processing patterns.

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

## Batch Processing in Tasks

A Celery task (or management command) that processes many items must wrap each item in a savepoint so one failure doesn't poison the batch. Without per-item `transaction.atomic`, the first `TransactionManagementError` rolls back everything and the task dies without processing remaining items.

```python
from celery import shared_task
from django.db import transaction
from django.utils import timezone

@shared_task(bind=True, max_retries=3)
def daily_processing(self):
    for customer in Customer.objects.filter(active=True):
        try:
            with transaction.atomic():
                process_customer(customer)
        except Exception as exc:
            JobLog.objects.create(
                customer=customer,
                status="failed",
                error=str(exc),
                started_at=timezone.now(),
            )
            # continue to next customer — do not re-raise inside the loop
```

Key rules:
- `transaction.atomic()` creates a savepoint; a failure rolls back only the current item.
- Log inside the `except`, don't re-raise, so the loop continues.
- `JobLog.started_at` has no default — always pass `timezone.now()`.
- For Celery tasks, use `bind=True` and `self.retry(exc=exc)` for transient failures (broker, DB connection), not for per-item business errors.