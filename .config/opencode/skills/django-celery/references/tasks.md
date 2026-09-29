Loaded on demand from ../SKILL.md — Defining Tasks and Calling Tasks patterns.

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