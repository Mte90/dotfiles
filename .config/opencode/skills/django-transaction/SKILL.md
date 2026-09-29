---
name: django-transaction
description: Use when handling Django transactions and concurrency - atomic, select_for_update, on_commit, upserts, M2M ordering
metadata:
  author: mte90
  version: 1.0.1
  tags:
    - python
    - django
    - transactions
    - concurrency
    - orm
---

# Django Transactions & Concurrency

Handle race conditions, locking, and transaction boundaries in Django.

## Overview

Django provides robust transaction management to ensure data consistency:
- **atomic** - Transaction boundaries with rollback on error
- **select_for_update** - Row-level locking for concurrent access
- **on_commit** - Deferred callbacks after transaction commits
- **update_or_create** - Upserts with race condition handling
- **M2M ordering** - ManyToMany relationships require PK first

---

## Transactions

### atomic

Transaction boundaries with automatic rollback on exception:

```python
from django.db import transaction

@transaction.atomic
def create_order_with_items(user, item_ids):
    """All-or-nothing order creation."""
    order = Order.objects.create(user=user, total=0)
    order.items.set(item_ids)  # Both succeed or both rollback
    return order
```

**Manual context manager:**
```python
with transaction.atomic():
    # All operations in this block are transactional
    account.deposit(100)
    account.withdraw(50)
    # If any exception here, both operations rollback
```

### savepoint

Nested transaction control within atomic block:

```python
with transaction.atomic():
    # Outer transaction
    savepoint = transaction.savepoint()
    
    try:
        risky_operation()
    except DangerousError:
        transaction.savepoint_rollback(savepoint)
        # Continue with outer transaction
        fallback_operation()
```

### Transaction Isolation Levels

Configure database transaction isolation:

```python
# settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        # PostgreSQL isolation levels:
        # - READ UNCOMMITTED (mapped to READ COMMITTED)
        # - READ COMMITTED (default)
        # - REPEATABLE READ
        # - SERIALIZABLE
        'OPTIONS': {
            'isolation_level': 'read_committed',
        },
    }
}
```

### Set Transaction Status

Control transaction state explicitly:

```python
from django.db import transaction

# Mark transaction as read-only
transaction.set_autocommit(False)
try:
    # Operations here are in a transaction
    data = Model.objects.filter(...)
    transaction.set_dirty()  # Mark as needing commit
finally:
    transaction.set_autocommit(True)  # Restore auto-commit
```

---

## Concurrency Control

### atomic + select_for_update for Unique Code Generation

Prevent race conditions when generating unique codes:

```python
from django.db import transaction, DatabaseError

def generate_unique_code():
    """Thread-safe unique code generation."""
    with transaction.atomic():
        # Lock the row to prevent concurrent access
        last_order = Order.objects.select_for_update().order_by('-id').first()
        
        if last_order:
            code = last_order.code + 1
        else:
            code = 1
        
        # Generate new order with unique code
        order = Order.objects.create(code=code)
        
        return order
```

**Key points**:
- `select_for_update()` locks rows until transaction commits
- Prevents two concurrent requests from getting the same code
- Works with PostgreSQL, MySQL, Oracle (not SQLite)

**Lock options:**
```python
# Wait for lock with timeout (PostgreSQL)
Order.objects.select_for_update(nowait=True).first()  # Raise error if locked
Order.objects.select_for_update(skip_locked=True).first()  # Skip locked rows
Order.objects.select_for_update(of=['order'], no_wait=True).first()  # Specific table
```

### on_commit for External Calls

Don't call external APIs inside transactions:

```python
from django.db import transaction
from django.db.transaction import on_commit

def create_order_with_webhook(request):
    """Create order, then call webhook after commit."""
    
    def send_webhook(order):
        # External API call - happens AFTER transaction commits
        requests.post('https://api.example.com/webhook', json={'order_id': order.id})
    
    with transaction.atomic():
        order = Order.objects.create(
            user=request.user,
            total=request.POST['total']
        )
        
        # Register callback - will fire after commit
        on_commit(lambda: send_webhook(order))
    
    return order
```

**Why**: If the webhook fails or the transaction rolls back, you don't want to send partial data.

**Multiple callbacks:**
```python
with transaction.atomic():
    order.save()
    on_commit(lambda: send_email(order.user))
    on_commit(lambda: send_analytics(order))
    on_commit(lambda: update_inventory(order))
# All callbacks fire in order after commit
```

**Exception handling in callbacks**:
```python
def safe_callback(order):
    try:
        send_webhook(order)
    except Exception:
        # Log error, don't rollback transaction
        logger.error('Webhook failed', exc_info=True)

with transaction.atomic():
    order.save()
    on_commit(lambda: safe_callback(order))
# Transaction commits even if webhook fails
```

---

## Upsert Race Conditions

### update_or_create Race Condition + unique_constraint + deterministic external_id + 409

Handle race conditions with upserts:

```python
from django.db import IntegrityError, transaction
from django.http import JsonResponse

def sync_external_resource(request, external_id):
    """Idempotent sync with conflict handling."""
    
    # Deterministic external_id validation
    if not external_id or not external_id.startswith('ext_'):
        return JsonResponse({'error': 'Invalid external_id'}, status=400)
    
    try:
        with transaction.atomic():
            obj, created = ExternalResource.objects.update_or_create(
                external_id=external_id,
                defaults={
                    'name': request.POST['name'],
                    'status': request.POST['status'],
                }
            )
            
            if created:
                return JsonResponse({'created': True, 'id': obj.id})
            else:
                return JsonResponse({'created': False, 'id': obj.id})
                
    except IntegrityError as e:
        # Duplicate external_id - concurrent request won the race
        if 'unique_external_id' in str(e):
            # Return 409 Conflict
            return JsonResponse(
                {'error': 'Resource being created by another request'},
                status=409
            )
        raise
```

**Pattern**:
1. `update_or_create()` with `external_id` as unique constraint
2. Catch `IntegrityError` for race conditions
3. Return `409 Conflict` instead of failing
4. Client can retry with same `external_id` (idempotent)

### Add Unique Constraints Before Relying on Upserts

Ensure upserts work correctly with unique constraints:

```python
from django.db import migrations, models

class Migration(migrations.Migration):
    
    dependencies = [
        ('myapp', '0001_initial'),
    ]
    
    operations = [
        # 1. Add unique constraint FIRST
        migrations.AddConstraint(
            model_name='externalresource',
            constraint=models.UniqueConstraint(
                fields=['external_id'],
                name='unique_external_id'
            ),
        ),
        
        # 2. Then data migration to dedupe
        migrations.RunPython(
            deduplicate_external_resources,
            reverse_code=migrations.RunPython.noop
        ),
        
        # 3. Now update_or_create will work reliably
        # (no code change needed - just ensure this migration runs first)
    ]

def deduplicate_external_resources(apps, schema_editor):
    ExternalResource = apps.get_model('myapp', 'ExternalResource')
    
    # Group by external_id
    from django.db.models import Count
    duplicates = ExternalResource.objects.values(
        'external_id'
    ).annotate(count=Count('id')).filter(count__gt=1)
    
    for dup in duplicates:
        # Keep oldest, delete rest
        ids = list(ExternalResource.objects.filter(
            external_id=dup['external_id']
        ).order_by('-created_at').values_list('id', flat=True)[1:])
        
        ExternalResource.objects.filter(id__in=ids).delete()
```

---

## Transaction Decorator

Use `@transaction.atomic` decorator for views:

```python
from django.db import transaction
from django.shortcuts import render, redirect

@transaction.atomic
def process_payment(request, order_id):
    """All payment operations in one transaction."""
    order = Order.objects.select_for_update().get(id=order_id)
    
    # Deduct from user balance
    user = request.user
    user.balance -= order.total
    user.save()
    
    # Mark order as paid
    order.status = 'paid'
    order.save()
    
    return redirect('order_detail', pk=order.id)
```

**Rollback on validation error**:
```python
@transaction.atomic
def bulk_create_products(request):
    products = []
    for data in request.POST.getlist('products'):
        product = Product(**data)
        product.full_clean()  # May raise ValidationError
        products.append(product)
    
    # All or nothing - ValidationError rolls back entire transaction
    Product.objects.bulk_create(products)
```

### Transaction State Management

Check transaction state programmatically:

```python
from django.db import connection, transaction

# Check if in transaction
if transaction.get_autocommit():
    print("Auto-commit mode")
else:
    print("In manual transaction")

# Check if transaction is dirty (has pending changes)
if connection.in_atomic_block:
    print("Inside atomic block")
```

---

## ManyToMany Relationships

### M2M Ordering After PK

ManyToMany relationships require the object to have a PK:

```python
from django.db import transaction

def create_order_with_items(order_data, item_ids):
    """M2M relationships must be set after save."""
    
    with transaction.atomic():
        # First: create the order (gets PK)
        order = Order.objects.create(
            user=order_data['user'],
            total=order_data['total']
        )
        
        # Second: set M2M (requires order.pk)
        order.items.set(item_ids)  # ✅ Works - order has PK
        
        # ❌ This fails: M2M on unsaved object
        # order = Order(items=item_ids)  # ERROR!
        
        return order
```

**Rule**: Always `save()` first, then set M2M relationships.

**Custom M2M through model**:
```python
# models.py
class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE)
    item = models.ForeignKey(Item, on_delete=models.CASCADE)
    quantity = models.IntegerField(default=1)
    
    class Meta:
        unique_together = ['order', 'item']  # Prevent duplicates

# Usage
with transaction.atomic():
    order = Order.objects.create(user=user)
    OrderItem.objects.create(order=order, item=item1, quantity=2)
    OrderItem.objects.create(order=order, item=item2, quantity=1)
```

**M2M with through_defaults**:
```python
# When using through models with defaults
order = Order.objects.create(user=user)
order.items.set(
    [item1, item2],
    through_defaults={'quantity': 1}  # Set default quantity for all
)
```

### Bulk Operations in Transactions

Batch operations with transaction safety:

```python
from django.db import transaction

@transaction.atomic
def bulk_update_inventory(items):
    """Update multiple items atomically."""
    # Use bulk_update for efficiency
    Item.objects.bulk_update(items, ['quantity', 'updated_at'])
    
    # All updates succeed or all rollback
```

**Atomic bulk create**:
```python
@transaction.atomic
def create_batch_orders(order_data_list):
    orders = [Order(**data) for data in order_data_list]
    Order.objects.bulk_create(orders)
    # All orders created or none
    return orders
```
        
        # ❌ This fails: M2M on unsaved object
        # order = Order(items=item_ids)  # ERROR!
        
        return order
```

**Rule**: Always `save()` first, then set M2M relationships.

**Custom M2M through model:**
```python
# models.py
class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE)
    item = models.ForeignKey(Item, on_delete=models.CASCADE)
    quantity = models.IntegerField(default=1)
    
    class Meta:
        unique_together = ['order', 'item']  # Prevent duplicates

# Usage
with transaction.atomic():
    order = Order.objects.create(user=user)
    OrderItem.objects.create(order=order, item=item1, quantity=2)
    OrderItem.objects.create(order=order, item=item2, quantity=1)
```

---

## Best Practices

1. **Keep transactions short** - Hold locks for minimal time
2. **Never call external APIs inside transactions** - Use `on_commit`
3. **Use `select_for_update` for sequential ID generation** - Prevent races
4. **Add unique constraints before upserts** - Ensure data integrity
5. **Handle `IntegrityError` for race conditions** - Return 409 for conflicts
6. **Save before M2M operations** - Object must have PK
7. **Use `nowait` or `skip_locked` for high concurrency** - Avoid waiting

---

## References

- [Django Transactions Documentation](https://docs.djangoproject.com/en/stable/topics/db/transactions/)
- [select_for_update Documentation](https://docs.djangoproject.com/en/stable/ref/models/querysets/#select-for-update)
- Source: frameworks/django/SKILL.md (v2.2.0)