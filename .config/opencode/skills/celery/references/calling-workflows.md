# Calling Workflows and Task States

> Loaded on demand from `../SKILL.md` for detailed task invocation patterns and state management.

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