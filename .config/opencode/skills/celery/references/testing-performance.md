# Testing and Performance

> Loaded on demand from `../SKILL.md` for detailed testing strategies, performance optimization, and common issues.

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