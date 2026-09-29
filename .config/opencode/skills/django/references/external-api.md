<!-- This file is loaded on demand from frameworks/django/SKILL.md -->

## Operational Dashboards

### dj-control-room
- **URL**: https://github.com/django-control-room/dj-control-room
- **PyPI**: `dj-control-room`
- **Version**: 1.7.1 (requires Python 3.9+, Django 4.2+)

A plugin framework for building Django admin tools ("panels") plus a centralized operations dashboard in the Django admin site. Bundled with official panels for Redis, Celery, cache, URLs, and Django signals. "Control room" means an operations/monitoring dashboard (an admin extension) — not orchestration: it aggregates operational insight into one staff-gated admin section at `/admin/dj-control-room/`.

**Key features:**
- Plugin framework: every panel (official or third-party) is a small independent Python package built on the public plugin API in `dj-control-room-base`; panels are auto-discovered via Python entry points and rendered in one centralized dashboard
- Shared design system: responsive UI with dark mode, theme adapters for popular admin skins, and admin sidebar integration
- Security: staff-gated access, permission scopes, and package verification
- Official panels: Redis (connections, keys, memory usage), Cache (entries, hit/miss ratios), URLs (browse patterns, test resolvers), Celery (workers, task queues), Signals (inspect signals and receivers)
- AI agent integration: a single MCP endpoint aggregates every installed panel's tools for AI agents
- Custom panels: scaffoldable via `cookiecutter-dj-control-room-plugin`

```bash
pip install dj-control-room
```
With extras: `pip install dj-control-room[redis,cache,urls]` or `pip install dj-control-room[all]`.

Add to `INSTALLED_APPS`:
```python
INSTALLED_APPS = [
    # ...
    "dj_control_room_base",
    "dj_control_room",  # core dashboard
    # official panels:
    "dj_control_room_redis",
    "dj_control_room_cache",
    "dj_control_room_urls",
    "dj_control_room_celery",
    "dj_control_room_signals",
]
```

Include URLs under `/admin/`:
```python
urlpatterns = [
    path("admin/", admin.site.urls),
    path("admin/dj-control-room/", include("dj_control_room.urls")),
]
```



---

## External API Integration Patterns

### Sync-State Machine PENDING/SYNCED/FAILED

Track external API sync state explicitly:

```python
from django.db import models

class ExternalResource(models.Model):
    SYNC_STATUS = {
        'PENDING': 'Pending sync',
        'SYNCED': 'Successfully synced',
        'FAILED': 'Sync failed',
    }
    
    external_id = models.CharField(max_length=100, unique=True)
    sync_status = models.CharField(
        max_length=20,
        choices=SYNC_STATUS,
        default='PENDING'
    )
    sync_error = models.TextField(blank=True, null=True)
    last_synced_at = models.DateTimeField(null=True, blank=True)
    
    def mark_synced(self):
        self.sync_status = 'SYNCED'
        self.sync_error = ''
        self.last_synced_at = timezone.now()
        self.save()
    
    def mark_failed(self, error: str):
        self.sync_status = 'FAILED'
        self.sync_error = error
        self.save()
```

### Persist sync_error, Never Swallow

Always log external API errors:

```python
import requests
from django.core.exceptions import ValidationError

def sync_external_resource(resource):
    """Sync with external API - never swallow errors."""
    
    try:
        response = requests.post(
            'https://api.example.com/sync',
            json={'id': resource.external_id},
            timeout=10  # ⚠️ Always set timeout
        )
        response.raise_for_status()
        
        resource.mark_synced()
        
    except requests.Timeout:
        resource.mark_failed('Request timeout after 10s')
        raise  # Re-raise for caller handling
        
    except requests.HTTPError as e:
        error_msg = f"HTTP {e.response.status_code}: {e.response.text}"
        resource.mark_failed(error_msg)
        raise ValidationError(error_msg)
        
    except requests.RequestException as e:
        error_msg = f"Network error: {str(e)}"
        resource.mark_failed(error_msg)
        raise ValidationError(error_msg)
```

**Key rules**:
- Never use bare `except:` - catch specific exceptions
- Persist `sync_error` for debugging
- Always set timeouts (prevent hanging)
- Re-raise after logging (don't hide failures)

### Webhooks for Sync State

- **django-webhook** (https://github.com/danihodovic/django-webhook) - Send outgoing webhooks on model changes (fits sync-state pattern with PENDING/SYNCED/FAILED)

### Boundary Decimal Validation

Validate Decimal at API boundary, not deep in logic:

```python
from decimal import Decimal, InvalidOperation
from django.core.exceptions import ValidationError

def parse_amount(value: str) -> Decimal:
    """Validate and parse Decimal at boundary."""
    
    if not value:
        raise ValidationError('Amount is required')
    
    try:
        amount = Decimal(value)
    except (InvalidOperation, ValueError):
        raise ValidationError(f'Invalid amount: {value}')
    
    if amount < 0:
        raise ValidationError('Amount must be positive')
    
    if amount > Decimal('999999999.99'):
        raise ValidationError('Amount exceeds maximum')
    
    return amount.quantize(Decimal('0.01'))  # Round to 2 decimals

# Usage in view
def create_order(request):
    amount = parse_amount(request.POST.get('amount'))  # ✅ Validated at boundary
    # Rest of code trusts amount is valid
    order = Order.objects.create(amount=amount)
```

### snapshot-vs-live (applied_reseller_percentage)

Beware of stale data when using computed fields:

```python
class Order(models.Model):
    subtotal = models.DecimalField(max_digits=10, decimal_places=2)
    reseller = models.ForeignKey(Reseller, on_delete=models.CASCADE)
    applied_reseller_percentage = models.DecimalField(
        max_digits=5, decimal_places=2,
        blank=True, null=True
    )
    
    def calculate_total(self):
        """Use LATEST reseller percentage, not snapshot."""
        # ❌ WRONG - uses stored snapshot
        # discount = self.applied_reseller_percentage
        
        # ✅ CORRECT - fetch live data
        discount = self.reseller.discount_percentage
        return self.subtotal * (1 - discount / 100)
    
    def save(self, *args, **kwargs):
        """Snapshot for audit, but calculate fresh."""
        # Store snapshot for historical records
        self.applied_reseller_percentage = self.reseller.discount_percentage
        super().save(*args, **kwargs)
```

**Pattern**:
- Store snapshot for audit/history
- Calculate from live data for accuracy
- Document which value is "source of truth"

---


