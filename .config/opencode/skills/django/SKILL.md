---
name: django
description: "Comprehensive Django guide - security, ORM, PostgreSQL, GeoDjango, Django 6.0 features, admin extensions, middleware, authentication, sessions, and ecosystem tools"
metadata:
  author: mte90
  version: 2.1.0
  tags:
    - python
    - django
    - security
    - orm
    - postgresql
    - admin
    - authentication
    - sessions
---

# Django

Comprehensive guide to Django covering security, ORM, PostgreSQL, GeoDjango, Django 6.0 essentials, admin extensions, and ecosystem tools.

## Overview

Django provides a batteries-included web framework with robust features out of the box:
- **Security** - CSRF protection, authentication, sessions, password hashing, security middleware
- **ORM** - Powerful database abstraction with query optimization
- **PostgreSQL** - Full-text search, array fields, JSONB, range fields
- **GeoDjango** - Geographic database operations with GPS extraction
- **Django 6.0** - Middleware changes, built-in tasks framework, CSP, GeneratedField
- **Admin Extensions** - Operational dashboards and monitoring tools
Django provides robust security features out of the box:
- **CSRF Protection** - Prevents cross-site request forgery
- **Authentication** - User login/logout, password management
- **Sessions** - Secure session management
- **Security Middleware** - Various security headers
- **Password Hashing** - Secure password storage

---

## CSRF Protection

### How CSRF Works

CSRF (Cross-Site Request Forgery) prevents malicious sites from submitting forms on behalf of authenticated users.

```
User logs in → Django sets session cookie → User visits malicious site
                                                      ↓
                                    Malicious site submits form to your site
                                                      ↓
                                    CSRF token missing → Request rejected
```

### CsrfViewMiddleware

Django's `CsrfViewMiddleware` provides CSRF protection:

```python
# settings.py
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',  # Must be here
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
]
```

> **Important**: `CsrfViewMiddleware` must come AFTER `SessionMiddleware`.

### Using CSRF Token in Forms

```html+django
<!-- Required in every POST form -->
<form method="post">
    {% csrf_token %}
    <input type="text" name="username">
    <input type="password" name="password">
    <button type="submit">Login</button>
</form>
```

```html+django
<!-- AJAX requests -->
<script>
function submitForm() {
    fetch('/submit/', {
        method: 'POST',
        body: new FormData(document.getElementById('myForm')),
        headers: {
            'X-CSRFToken': '{{ csrf_token }}'
        }
    });
}
</script>
```

```javascript
// JavaScript helper
function getCookie(name) {
    let cookieValue = null;
    if (document.cookie && document.cookie !== '') {
        const cookies = document.cookie.split(';');
        for (let i = 0; i < cookies.length; i++) {
            const cookie = cookies[i].trim();
            if (cookie.substring(0, name.length + 1) === (name + '=')) {
                cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                break;
            }
        }
    }
    return cookieValue;
}

// Usage
fetch('/api/', {
    method: 'POST',
    body: JSON.stringify(data),
    headers: {
        'Content-Type': 'application/json',
        'X-CSRFToken': getCookie('csrftoken')
    }
});
```

### csrf_protect Decorator

Apply CSRF protection to specific views:

```python
from django.views.decorators.csrf import csrf_protect
from django.middleware.csrf import csrf_exempt

@csrf_protect
def protected_view(request):
    """This view requires CSRF protection."""
    pass

@csrf_exempt
def exempt_view(request):
    """This view is exempt from CSRF (use carefully!)."""
    pass
```

### AJAX with CSRF

```python
# Using Django's CSRF helper in JavaScript
import Cookies from 'js-cookie';

const csrftoken = Cookies.get('csrftoken');

// Fetch API
fetch('/api/', {
    method: 'POST',
    headers: {
        'X-CSRFToken': csrftoken
    },
    body: formData
});

// Axios
axios.defaults.headers.common['X-CSRFToken'] = csrftoken;

// jQuery
$.ajaxSetup({
    headers: {
        'X-CSRFToken': '{{ csrf_token }}'
    }
});
```

### CSRF Exemption (Use Carefully)

```python
# Only exempt when absolutely necessary
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from django.views import View

@method_decorator(csrf_exempt, name='dispatch')
class WebhookView(View):
    """Webhooks from trusted services."""
    def post(self, request):
        # Process webhook
        return JsonResponse({'status': 'ok'})
```

### Testing CSRF

```python
from django.test import Client, override_settings

@override_settings(CSRFmiddleware=None)  # Disable for testing
def test_view_without_csrf(client):
    """Test without CSRF (not recommended)."""
    response = client.post('/url/', {'data': 'value'})
    assert response.status_code == 200

# Better: Use CSRF client
def test_view_with_csrf(client):
    """Test with proper CSRF token."""
    # Get the form first to obtain CSRF token
    response = client.get('/form-url/')
    csrf_token = client.cookies.get('csrftoken').value
    
    # POST with token
    response = client.post('/form-url/', {
        'field': 'value',
        'csrfmiddlewaretoken': csrf_token
    })
    assert response.status_code == 200
```

---

## Authentication

### Built-in Authentication Views

```python
# urls.py
from django.contrib.auth import views as auth_views
from django.urls import path

urlpatterns = [
    path('login/', auth_views.LoginView.as_view(), name='login'),
    path('logout/', auth_views.LogoutView.as_view(), name='logout'),
    path('password_change/', auth_views.PasswordChangeView.as_view(), name='password_change'),
    path('password_change/done/', auth_views.PasswordChangeDoneView.as_view(), name='password_change_done'),
    path('password_reset/', auth_views.PasswordResetView.as_view(), name='password_reset'),
    path('password_reset/done/', auth_views.PasswordResetDoneView.as_view(), name='password_done'),
    path('reset/<uidb64>/<token>/', auth_views.PasswordResetConfirmView.as_view(), name='password_reset_confirm'),
    path('reset/done/', auth_views.PasswordResetCompleteView.as_view(), name='password_reset_complete'),
]
```

### LoginView Configuration

```python
# views.py
from django.contrib.auth.views import LoginView
from django.contrib.auth.forms import AuthenticationForm

class CustomLoginView(LoginView):
    template_name = 'registration/login.html'
    authentication_form = AuthenticationForm
    redirect_authenticated_user = True
    
    def get_success_url(self):
        return self.request.GET.get('next', '/dashboard/')
```

```python
# settings.py
LOGIN_URL = '/accounts/login/'
LOGIN_REDIRECT_URL = '/dashboard/'
LOGOUT_REDIRECT_URL = '/'
```

### Manual Authentication

```python
from django.contrib.auth import authenticate, login, logout

def login_view(request):
    username = request.POST.get('username')
    password = request.POST.get('password')
    
    # Authenticate user
    user = authenticate(request, username=username, password=password)
    
    if user is not None:
        if user.is_active:
            login(request, user)
            # Redirect to success page
            return redirect('dashboard')
        else:
            return render(request, 'login.html', {
                'error': 'Account disabled'
            })
    else:
        return render(request, 'login.html', {
            'error': 'Invalid credentials'
        })

def logout_view(request):
    logout(request)
    return redirect('home')
```

### Authentication Form

```python
from django.contrib.auth.forms import AuthenticationForm, UserCreationForm

# Login form
form = AuthenticationForm(request, data=request.POST)

if form.is_valid():
    user = form.get_user()
    login(request, user)

# Registration form
form = UserCreationForm(request.POST)
if form.is_valid():
    user = form.save()
    login(request, user)  # Auto-login after registration
```

### LoginRequiredMixin

```python
from django.contrib.auth.mixins import LoginRequiredMixin

class DashboardView(LoginRequiredMixin, View):
    login_url = '/accounts/login/'
    redirect_field_name = 'next'
    
    def get(self, request):
        return render(request, 'dashboard.html')

# Function-based view
from django.contrib.auth.decorators import login_required

@login_required(login_url='/accounts/login/')
def dashboard(request):
    return render(request, 'dashboard.html')
```

### Custom User Model Authentication

```python
# For custom User models with email instead of username
from django.contrib.auth.backends import BaseBackend
from django.contrib.auth import get_user_model

User = get_user_model()

class EmailBackend(BaseBackend):
    def authenticate(self, request, username=None, password=None, **kwargs):
        try:
            user = User.objects.get(email=username)
        except User.DoesNotExist:
            return None
        
        if user.check_password(password):
            return user
        return None
    
    def get_user(self, user_id):
        try:
            return User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return None
```

```python
# settings.py
AUTHENTICATION_BACKENDS = [
    'path.to.EmailBackend',
    'django.contrib.auth.backends.ModelBackend',
]
```

---

## Custom Permission Backends

### Why Custom Backends

Django's built-in `ModelBackend` only handles model-level permissions (`add`, `change`, `delete`, `view`). Custom backends add:
- **Per-object permissions** (row-level authorization)
- **External auth systems** (LDAP, OAuth providers)
- **Permission composition** (multiple backends chained)

### Custom Backend Implementation

```python
# myapp/backends.py
from django.contrib.auth.backends import BaseBackend
from django.contrib.auth.models import User

class ObjectPermissionBackend(BaseBackend):
    """Backend for per-object permissions."""
    
    def has_perm(self, user_obj, perm, obj=None):
        if obj is None:
            # Fall back to model-level check
            return None
        
        app_label, codename = perm.split('.')
        
        # Check object-level permission
        return self._check_object_perm(user_obj, obj, codename)
    
    def _check_object_perm(self, user_obj, obj, action):
        """Check if user can perform action on specific object."""
        if action == 'view':
            return self._can_view(user_obj, obj)
        if action == 'change':
            return self._can_change(user_obj, obj)
        if action == 'delete':
            return self._can_delete(user_obj, obj)
        return False
    
    def _can_view(self, user, obj):
        if hasattr(obj, 'owner'):
            return obj.owner_id == user.id or user.is_staff
        return True
    
    def _can_change(self, user, obj):
        if hasattr(obj, 'owner'):
            return obj.owner_id == user.id
        return user.is_staff
```

### Configuration

Chaining multiple backends:

```python
# settings.py
AUTHENTICATION_BACKENDS = [
    'django.contrib.auth.backends.ModelBackend',  # Default model-level
    'myapp.backends.ObjectPermissionBackend',      # Custom object-level
]
```

Django tries each backend in order; first `True` or `False` wins. `None` means "I don't know, ask the next backend".

### Per-Object Permissions

The row-level authorization pattern:

```python
from django.contrib.auth.decorators import permission_required
from django.shortcuts import get_object_or_404

@permission_required('myapp.change_document')
def edit_document(request, pk):
    document = get_object_or_404(Document, pk=pk)
    
    # Check object-level permission
    if not request.user.has_perm('myapp.change_document', document):
        from django.core.exceptions import PermissionDenied
        raise PermissionDenied
    
    # Proceed with edit...
```

### Permission Flow Design

The request → check → grant/deny pattern:

```python
# myapp/permissions.py
class PermissionFlow:
    """Centralized permission checking with audit logging."""
    
    def __init__(self, user):
        self.user = user
    
    def can_access(self, resource, action, obj=None):
        """Check permission and log the decision."""
        allowed = self.user.has_perm(
            f'{resource}.{action}', 
            obj=obj
        )
        
        if not allowed:
            # Log denied access for audit trail
            import logging
            logger = logging.getLogger('permissions')
            logger.warning(
                f"Permission denied: user={self.user.id}, "
                f"resource={resource}, action={action}, obj={obj}"
            )
        
        return allowed
```

### Class-Based View Mixin

Reusable permission checks in CBVs:

```python
from django.core.exceptions import PermissionDenied

class ObjectPermissionMixin:
    """Mixin for per-object permission checks in CBVs."""
    permission_required = None  # e.g., 'myapp.change_document'
    
    def get_object(self, queryset=None):
        obj = super().get_object(queryset)
        if self.permission_required:
            if not self.request.user.has_perm(
                self.permission_required, obj
            ):
                raise PermissionDenied
        return obj
```

### Testing Permissions

How to test custom backends:

```python
from django.test import TestCase
from django.contrib.auth.models import User, Permission
from myapp.models import Document

class ObjectPermissionTest(TestCase):
    def setUp(self):
        self.owner = User.objects.create_user('owner', 'o@e.com', 'pass')
        self.other = User.objects.create_user('other', 'x@e.com', 'pass')
        self.doc = Document.objects.create(title='Test', owner=self.owner)
    
    def test_owner_can_change(self):
        self.assertTrue(
            self.owner.has_perm('myapp.change_document', self.doc)
        )
    
    def test_other_cannot_change(self):
        self.assertFalse(
            self.other.has_perm('myapp.change_document', self.doc)
        )
```

### Common Pitfalls

| Issue | Cause | Solution |
|-------|-------|----------|
| `has_perm` returns True for all | Backend returns `True` instead of `None` for unknown perms | Return `None` when backend doesn't handle the permission |
| Object perm not checked | Called `has_perm(perm)` without `obj` arg | Always pass `obj=obj` for object checks |
| Backend not called | Not in `AUTHENTICATION_BACKENDS` | Add backend to settings list |
| Permissions cached incorrectly | Django caches per-user perms | Call `user_obj._perm_cache.clear()` if needed |

---

## Sessions

### Session Configuration

```python
# settings.py
SESSION_ENGINE = 'django.contrib.sessions.backends.db'  # Default
# Or:
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'  # Faster
SESSION_ENGINE = 'django.contrib.sessions.backends.signed_cookies'  # No server storage

SESSION_COOKIE_NAME = 'sessionid'
SESSION_COOKIE_AGE = 60 * 60 * 24 * 7  # 1 week in seconds
SESSION_COOKIE_SECURE = True  # HTTPS only
SESSION_COOKIE_HTTPONLY = True  # No JavaScript access
SESSION_COOKIE_SAMESITE = 'Lax'  # CSRF protection
```

### Using Sessions

```python
# Set session data
request.session['user_id'] = user.id
request.session['preferences'] = {'theme': 'dark', 'lang': 'en'}

# Get session data
user_id = request.session.get('user_id')
preferences = request.session.get('preferences', {})

# Delete session data
del request.session['user_id']
request.session.flush()  # Clear all session data

# Check if key exists
if 'user_id' in request.session:
    pass
```

### Session Middleware

```python
# settings.py - Ensure these are in MIDDLEWARE
'django.contrib.sessions.middleware.SessionMiddleware',
'django.contrib.auth.middleware.AuthenticationMiddleware',
```

---

## Password Management

### Password Validation

```python
# settings.py
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
        'OPTIONS': {'min_length': 8},
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]
```

### Custom Password Validation

```python
# validators.py
from django.core.exceptions import ValidationError
import re

class CustomPasswordValidator:
    def __init__(self, min_length=8):
        self.min_length = min_length
    
    def validate(self, password, user=None):
        if len(password) < self.min_length:
            raise ValidationError(f'Password must be at least {self.min_length} characters.')
        
        if not re.search(r'[A-Z]', password):
            raise ValidationError('Password must contain at least one uppercase letter.')
        
        if not re.search(r'[!@#$%^&*]', password):
            raise ValidationError('Password must contain at least one special character.')
    
    def help_text(self):
        return f'Password must be at least {self.min_length} characters with uppercase and special characters.'
```

```python
# settings.py
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'myapp.validators.CustomPasswordValidator',
    },
]
```

### Changing Password

```python
from django.contrib.auth import update_session_auth_hash

def change_password(request):
    if request.method == 'POST':
        form = PasswordChangeForm(user=request.user, data=request.POST)
        if form.is_valid():
            user = form.save()
            # Keep user logged in
            update_session_auth_hash(request, user)
            return redirect('password_change_done')
    else:
        form = PasswordChangeForm(user=request.user)
    
    return render(request, 'password_change.html', {'form': form})
```

---

## Security Middleware

```python
# settings.py
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    # ... other middleware
]

# Security settings
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
SECURE_REFERRER_POLICY = 'strict-origin-when-cross-origin'

# HTTPS settings
SECURE_SSL_REDIRECT = True  # Redirect HTTP to HTTPS
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# HSTS (HTTP Strict Transport Security)
SECURE_HSTS_SECONDS = 31536000  # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
```

### SecurityMiddleware Options

```python
# settings.py
SECURE_CONTENT_TYPE_NOSNIFF = True  # Prevent MIME sniffing
X_FRAME_OPTIONS = 'DENY'  # Prevent clickjacking
SECURE_BROWSER_XSS_FILTER = True  # XSS filter
SECURE_REFERRER_POLICY = 'strict-origin-when-cross-origin'  # Referrer policy

# Custom headers
SECURE_CONTENT_SECURITY_POLICY = "default-src 'self'"
```

---

## Login Templates

```html+django
<!-- registration/login.html -->
{% extends 'base.html' %}

{% block content %}
<div class="login-container">
    <h2>Login</h2>
    
    {% if form.errors %}
    <div class="error">
        <p>Your username and password didn't match. Please try again.</p>
    </div>
    {% endif %}
    
    {% if next %}
        {% if user.is_authenticated %}
        <p>Your account doesn't have access to this page.</p>
        {% else %}
        <p>Please login to see this page.</p>
        {% endif %}
    {% endif %}
    
    <form method="post" action="{% url 'login' %}">
        {% csrf_token %}
        
        <div class="form-group">
            <label for="id_username">Username</label>
            <input type="text" name="username" id="id_username" required>
        </div>
        
        <div class="form-group">
            <label for="id_password">Password</label>
            <input type="password" name="password" id="id_password" required>
        </div>
        
        <button type="submit">Login</button>
        <input type="hidden" name="next" value="{{ next }}">
    </form>
    
    <p><a href="{% url 'password_reset' %}">Forgot password?</a></p>
</div>
{% endblock %}
```

---

## Best Practices

1. **Always use {% csrf_token %}** in POST forms
2. **Use HTTPS** in production (SECURE_SSL_REDIRECT = True)
3. **Enable HSTS** for secure connections
4. **Set secure cookies** (SESSION_COOKIE_SECURE = True)
5. **Use strong password validation**
6. **Use @login_required** for protected views
7. **Never expose sensitive data** in URLs or logs
8. **Validate file uploads** carefully
9. **Use prepared statements** (Django ORM does this automatically)

---

## ORM Optimization

### Avoiding Duplicate Objects with Exists Subquery

When filtering across relationships (one-to-many or many-to-many), JOINs produce duplicate parent objects:

```python
# Problem: duplicates returned
Author.objects.filter(books__title__startswith="Book")
# [<Author: Charlie>, <Author: Alice>, <Author: Alice>]  # Alice appears twice
```

**Solution: Use Exists Subquery** (fastest, no ordering issues):

```python
from django.db.models import Exists, OuterRef

Author.objects.filter(
    Exists(Book.objects.filter(
        author=OuterRef("id"),
        title__startswith="Book",
    ))
).order_by("name")
```

- Stops evaluation on first match
- No ordering restrictions
- Works with all databases

**PostgreSQL-only alternative:**

```python
Author.objects.filter(books__title__startswith="Book").distinct("id")
```

### N+1 Query Prevention

**Problem:**
```python
for user in User.objects.all()[:100]:
    user.groups.count()  # 100 extra queries!
```

**Solution: Use prefetch_related with Prefetch object:**

```python
from django.db.models import Prefetch

staff_groups = Group.objects.filter(name__in=["admin", "superuser"])
users = User.objects.prefetch_related(
    "groups",
    Prefetch("groups", to_attr="staff_groups", queryset=staff_groups),
).order_by("id")[:100]

for user in users:
    groups_total = user.groups.count()  # Uses cached data
    is_staff = len(user.staff_groups) > 0  # No new query!
```

**Avoid querying prefetched objects unnecessarily:**
```python
# BAD: Makes new query
first_group = user.groups.first()

# GOOD: Uses in-memory data
first_group = user.groups.all()[0]
```

### Time-Based Lookups Performance

**Problem:** `timestamp__date` lookup **bypasses indexes**:

```python
# SLOW (30s on 25M rows)
Event.objects.filter(timestamp__date=datetime.date(2026, 1, 5))
# SQL: WHERE timestamp::date='2026-01-05'  # Full table scan!
```

**Solution: Use range boundaries:**

```python
import datetime
start = datetime.datetime(2026, 1, 5, tzinfo=datetime.UTC)
end = start + datetime.timedelta(days=1)

Event.objects.filter(timestamp__gte=start, timestamp__lt=end)
# Uses index, drops to <1s
```

### Deferring Large Fields

```python
# Defer large fields you don't need
books = Book.objects.defer("content", "notes")

# Or explicitly load only needed fields
books = Book.objects.only("title", "pub_date")
```

### Statement Timeouts (PostgreSQL)

```python
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "mydb",
        "OPTIONS": {
            "options": "-c statement_timeout=30s",  # Terminate queries >30s
        },
    }
}
```

---

## Django Tasks Framework (Django 6.0+)

Django 6.0 introduced a built-in tasks framework - an abstraction without a production-ready worker.

### Define a Task

```python
from django.tasks import task

@task(priority=2, queue_name="emails", backend="default")
def send_welcome_email(user_id):
    user = User.objects.get(id=user_id)
    send_mail("Welcome!", "Thanks for signing up.", "noreply@example.com", [user.email])
```

**Parameters:**
- `priority` (int): -100 to 100, defaults to 0
- `queue_name` (str): defaults to "default"
- `backend` (str): backend alias
- `takes_context` (bool): whether function accepts TaskContext

### Enqueue the Task

```python
# Synchronous
send_welcome_email.enqueue(user_id=user.id)

# Asynchronous
await send_welcome_email.aenqueue(user_id=user.id)
```

### Built-in Backends (Development Only)

| Backend | Behavior | Use Case |
| ------- |----------|----------|
| `ImmediateBackend` (default) | Runs synchronously | Development |
| `DummyBackend` | Stores without executing | Testing |

### Production: django-tasks-local

```python
# settings.py
INSTALLED_APPS = ["django_tasks_local"]

TASKS = {
    "default": {
        "BACKEND": "django_tasks_local.ThreadPoolBackend",
        "OPTIONS": {"MAX_WORKERS": 10}
    }
}
```

**When to use Django Tasks vs Celery:**

- **Django Tasks**: Fire-and-forget, no infrastructure (emails, webhooks, MVPs)
- **Celery**: Scheduled tasks, retries, persistence, distributed processing

---

## Django Permissions

### Custom Permissions in Model Meta

```python
class Experiment(models.Model):
    name = models.CharField(max_length=100)
    
    class Meta:
        permissions = [
            ("change_experiment_status", "Can change status"),
            ("view_experiment_details", "Can view details"),
        ]
```

### Groups for Role-Based Access

```python
from django.contrib.auth.models import Group

# Create groups
read_only = Group.objects.create(name="Read only")
maintainer = Group.objects.create(name="Maintainer")

# Assign permission to group
maintainer.permissions.add(permission)

# Assign user to group
maintainer.user_set.add(user)
```

### Function-Based View Protection

```python
from django.contrib.auth.decorators import login_required, permission_required

@login_required
def my_view(request):
    ...

@permission_required("blog.view_post")
def restricted_view(request):
    ...
```

### Class-Based View Protection

```python
from django.contrib.auth.mixins import LoginRequiredMixin, PermissionRequiredMixin
from django.views.generic import TemplateView

class RestrictedView(LoginRequiredMixin, TemplateView):
    template_name = 'restricted.html'
    raise_exception = True

class PermissionView(PermissionRequiredMixin, TemplateView):
    permission_required = ('posts.can_edit', 'posts.can_view')
    template_name = 'permission_required.html'
```

### Object-Level Permissions with Django Guardian

```python
from guardian.shortcuts import assign_perm, remove_perm

# Assign object-level permission
assign_perm("change_post", user, post)
assign_perm("view_post", group, post)

# Check permission
user.has_perm("change_post", post)
```

### Signal-Based Auto Permission Assignment

```python
from django.db.models.signals import post_save
from django.dispatch import receiver
from guardian.shortcuts import assign_perm

@receiver(post_save, sender=Post)
def set_permission(sender, instance, **kwargs):
    assign_perm("change_post", instance.author, instance)
    assign_perm("view_post", instance.author, instance)
```

---

## Caching

### View Caching

```python
from django.views.decorators.cache import cache_page

@cache_page(60 * 15)  # Cache for 15 minutes
def my_view(request):
    ...
```

### Template Fragment Caching

```{% load cache %}
{% cache 300 my_cache_key %}
    <!-- Expensive content -->
{% endcache %}
```

### Low-Level Cache API

```python
from django.core.cache import cache

cache.set('my_key', 'my_value', timeout=3600)
value = cache.get('my_key')
cache.delete('my_key')

# Multiple keys
cache.set_many({'a': 1, 'b': 2}, timeout=300)
cache.get_many(['a', 'b'])
```

### Redis Cache Backend

```python
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/0',
    }
}
```

---

## Testing Optimization

### Fast Password Hashing for Tests

```python
# settings.py
PASSWORD_HASHERS = [
    'django.contrib.auth.hashers.MD5PasswordHasher',  # 70% faster
]
```

### Parallel Testing

```bash
python manage.py test --parallel
```

### Capture on_commit Callbacks in Tests

```python
from django.test import TestCase

class ContactTests(TestCase):
    def test_post(self):
        with self.captureOnCommitCallbacks(execute=True) as callbacks:
            response = self.client.post("/contact/", {"message": "Test"})
        
        self.assertEqual(len(callbacks), 1)  # Verify callback was enqueued
```

### In-Memory SQLite for Tests

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': 'file::memory:',
    }
}
```

### Assert Query Count

```python
def test_something(self):
    with self.assertNumQueries(5):
        process_data()
```

---

## Migrations

### Squashing Migrations

```bash
# Squash migrations 0002 to 0006
python manage.py squashmigrations app 0002 0006
```

Then update dependencies in other migrations:
```python
class Migration(migrations.Migration):
    dependencies = [
        ('app', '0007_squashed_0006'),  # Update to squashed migration
    ]
```

### Standalone Django ORM (inspectdb)

Query existing databases without a full project:

```python
# settings.py
import os
from django.conf import settings

settings.configure(
    DATABASES={"default": {"ENGINE": "django.db.backends.sqlite3", "NAME": "db.sqlite"}},
    INSTALLED_APPS=["myapp"],
)

# Generate models
# python manage.py inspectdb > models.py
```

**Critical Model Attribute:**
```python
class Place(models.Model):
    url = models.URLField()
    title = models.CharField(null=True)
    
    class Meta:
        managed = False  # Don't try to create/migrate
        db_table = "moz_places"  # Existing table name
```

---

---

## Django Signals Best Practices

### Defining and Using Signals

```python
# Define custom signals
from django.dispatch import Signal
user_logged_in = Signal(providing_args=['user', 'request'])

# Connect receivers with decorator
from django.dispatch import receiver
from django.contrib.auth.signals import user_logged_in

@receiver(user_logged_in)
def log_user_login(sender, user, request, **kwargs):
    ActivityLog.objects.create(
        user=user,
        event_type=ActivityLog.LOGIN,
        context={'ip': request.META.get('REMOTE_ADDR')}
    )

# Register in AppConfig.ready() to avoid circular imports
class MyAppConfig(AppConfig):
    def ready(self):
        import myapp.signals
```

### Common Pitfalls to Avoid

- **Heavy computations** in signal handlers → Use Celery for async tasks
- **Circular imports** → Use string references: `sender="myapp.MyModel"`
- **Duplicate connections** → Use `dispatch_uid` parameter
- **Not registering signals** → Register in `AppConfig.ready()`

---

## Field-Level Encryption

```python
# Using django-secured-fields or django-fernet-encrypted-fields
from django_secured_fields.fields import EncryptedCharField

class UserProfile(models.Model):
    # Data encrypted at rest in database
    ssn = EncryptedCharField(max_length=11)
    credit_card = EncryptedCharField(max_length=16)
    
    # Transparent encryption/decryption via Django ORM
    # No manual encrypt/decrypt calls needed
```

**Benefits:**
- Field-level encryption (not blanket)
- Transparent integration with Django ORM
- Automatic key management
- Minimal performance impact

---

## StreamingHttpResponse

For large responses, stream instead of loading entirely:

```python
# Basic streaming response
def generate_csv():
    yield "Header1,Header2,Header3\n"
    yield "Value1,Value2,Value3\n"

def download_large_file(request):
    return StreamingHttpResponse(
        generate_csv(),
        content_type='text/csv'
    )

# For file downloads
from django.utils.filewrapper import FileWrapper

def download_file(request):
    file_like = open('large.csv', 'rb')
    return StreamingHttpResponse(
        FileWrapper(file_like),
        content_type='text/csv'
    )
```

**Benefits:**
- Lower memory usage (don't load entire file)
- Faster time-to-first-byte (TTFB)
- Better for large files (CSV, PDFs, exports)

---

## Response Time Optimization

### Use .only() to Limit Fields

```python
# Before: Fetching 130+ fields
qs = Article.objects.all()

# After: Fetch only needed fields
qs = Article.objects.only(
    "headline", "slug", "summary",
    "publication_start_date", "image",
    "primary_category"
)
```

### Denormalize Computed Fields

```python
class Article(models.Model):
    def set_publication_order_date(self):
        if self.updated_at:
            self.publication_order_date = self.updated_at
        elif self.publication_start_date:
            self.publication_order_date = self.publication_start_date
    
    def save(self, *args, **kwargs):
        self.set_publication_order_date()
        super().save(*args, **kwargs)
```

### Optimize Paginator Count

```python
# Reduce count() query cost
qs.count = qs.only("id").count
```

---

## Materialized Views with PostgreSQL

```python
# Using django-materialized-view library
from django_materialized_view import MaterializedViewModel

class YearlyRuntimeModel(MaterializedViewModel):
    create_pkey_index = True
    year = models.IntegerField(primary_key=True)
    average_runtime = models.IntegerField()
    
    class Meta:
        managed = False  # Important!
    
    @staticmethod
    def get_query_from_queryset():
        return Movie.objects.values('year').annotate(
            average_runtime=Avg('runtime_minutes')
        )

# Create the view
python manage.py migrate_with_views

# Refresh when data changes
YearlyRuntimeModel.refresh()
```

**Benefits:**
- Speed up complex aggregations
- Cache expensive queries
- Refresh on schedule or triggers

---

---

## pgvector Semantic Search

Vector similarity search with PostgreSQL and Django.

### Setup

```bash
pip install pgvector sentence-transformers psycopg[binary]
```

```python
# Migration to enable extension
from pgvector.django import VectorExtension

class Migration(migrations.Migration):
    operations = [VectorExtension()]
```

### Model with Embeddings

```python
from django.db import models
from pgvector.django import VectorField, CosineDistance
from sentence_transformers import SentenceTransformer

T = SentenceTransformer("distiluse-base-multilingual-cased-v1")

class Item(models.Model):
    content = models.TextField()
    embedding = VectorField(dimensions=512, editable=False)
    
    def save(self, *args, **kwargs):
        self.embedding = T.encode(self.content)
        super().save(*args, **kwargs)
    
    @classmethod
    def search(cls, q, dmax=0.5):
        distance = CosineDistance("embedding", T.encode(q))
        return (
            cls.objects.alias(distance=distance)
            .filter(distance__lt=dmax)
            .order_by(distance)
        )

# Usage
results = Item.search("python tutorial")
```

### SQL Generated

```sql
SELECT * FROM items_item 
WHERE (embedding <=> '[vector]') < 0.5 
ORDER BY (embedding <=> '[vector]') ASC;
```

---

## GeneratedField (Django 5.0+)

Database-generated columns that are computed by the DB when source fields change.

### SQLite Examples

```python
# Mathematical calculation
class Rectangle(models.Model):
    base = models.FloatField()
    height = models.FloatField()
    area = models.GeneratedField(
        expression=F("base") * F("height"),
        output_field=models.FloatField(),
        db_persist=True,
    )

# Conditional status
class Order(models.Model):
    creation = models.DateTimeField()
    payment = models.DateTimeField(null=True)
    status = models.GeneratedField(
        expression=Case(
            When(payment__isnull=False, then=Value("paid")),
            default=Value("created"),
        ),
        output_field=models.TextField(),
    )

# Date truncation
class Event(models.Model):
    start = models.DateTimeField()
    start_date = models.GeneratedField(
        expression=TruncDate("start"),
        output_field=models.DateField(),
    )
```

### PostgreSQL Examples

```python
# JSON key extraction
class Package(models.Model):
    slug = models.CharField()
    data = models.JSONField()
    version = models.GeneratedField(
        expression=F("data__info__version"),
        output_field=models.CharField(),
    )

# Full-text search vector
from django.contrib.postgres.search import SearchVector, SearchVectorField

class Quote(models.Model):
    author = models.CharField()
    text = models.TextField()
    search = models.GeneratedField(
        expression=SearchVector("text", config="english"),
        output_field=SearchVectorField(),
    )

# Array length
from django.contrib.postgres.fields import ArrayField, ArrayLenTransform

class Landmark(models.Model):
    name = models.CharField()
    reviews = ArrayField(models.SmallIntegerField())
    count = models.GeneratedField(
        expression=ArrayLenTransform("reviews"),
        output_field=models.IntegerField(),
    )
```

**⚠️ Note**: PostgreSQL requires IMMUTABLE functions only. Use `||` operator instead of `Concat`.

---

## GeoDjango with Pillow and GPS

Build maps with automatic GPS extraction from photo EXIF data.

### Setup

```python
# settings.py
INSTALLED_APPS = ["django.contrib.gis", "markers"]

DATABASES = {
    "default": {
        "ENGINE": "django.contrib.gis.db.backends.spatialite",
        "NAME": BASE_DIR / "db.sqlite3",
    }
}
```

### GPS Extraction from Images

```python
from PIL import Image
from PIL.ExifTags import GPS, IFD
from django.contrib.gis.geos import Point

def dms_to_dd(degrees, minutes, seconds, ref):
    REFS = {"N": 1, "S": -1, "E": 1, "W": -1}
    return (float(degrees) + float(minutes)/60 + float(seconds)/3600) * REFS.get(ref, 0)

def get_point(image):
    gpsinfo = Image.open(image).getexif().get_ifd(IFD.GPSInfo)
    longitude = dms_to_dd(*gpsinfo.get(GPS.GPSLongitude, (0,0,0)), gpsinfo.get(GPS.GPSLongitudeRef, "E"))
    latitude = dms_to_dd(*gpsinfo.get(GPS.GPSLatitude, (0,0,0)), gpsinfo.get(GPS.GPSLatitudeRef, "N"))
    return Point(longitude, latitude)
```

### Model with Auto-GPS

```python
class Marker(models.Model):
    name = models.CharField()
    location = models.PointField(blank=True)
    image = models.ImageField(upload_to="images/markers/")

    def save(self, *args, **kwargs):
        self.location = get_point(self.image)
        super().save(*args, **kwargs)
```

### Admin and GeoJSON

```python
from django.contrib.gis import admin

@admin.register(Marker)
class MarkerAdmin(admin.GISModelAdmin):
    list_display = ("name", "location", "image")

# Serialize to GeoJSON
from django.core.serializers import serialize
import json

geojson = json.loads(serialize("geojson", Marker.objects.all()))
```

---

## PostgreSQL Superpowers

### Full-Text Search

```python
from django.contrib.postgres.search import SearchQuery, SearchVector

# Simple search
results = Article.objects.annotate(
    search=SearchVector("title", "body")
).filter(search="django")

# With ranking
from django.contrib.postgres.search import SearchRank

results = Article.objects.annotate(
    rank=SearchRank(SearchVector("body"), SearchQuery("django"))
).order_by("-rank")
```

### Array Fields

```python
from django.contrib.postgres.fields import ArrayField

class Recipe(models.Model):
    name = models.CharField()
    tags = ArrayField(models.CharField(max_length=50))

# Query
Recipe.objects.filter(tags__contains=["vegan", "quick"])
Recipe.objects.filter(tags__overlap=["breakfast", "lunch"])
```

### Range Fields

```python
from django.contrib.postgres.fields import IntegerRangeField, DateRangeField

class Booking(models.Model):
    room = models.CharField()
    stay = DateRangeField()

# Overlap query
Booking.objects.filter(stay__overlap=[start_date, end_date])
```

### JSONB Operations

```python
class Product(models.Model):
    data = models.JSONField()

# Key existence
Product.objects.filter(data__has_key="specs")

# Path query
Product.objects.filter(data__specs__memory__gte=16)
```

---

## Django 6.0 Essentials

### Middleware Changes

- **CommonMiddleware deprecated** → Use `StaticFileMiddleware` for static file serving
- **CSP nonce improvements** - Built-in nonce support via `{% csp_nonce %}` template tag

### Test Client

- **`django.test.Client` class removed** → Use `LiveServerTestCase` for integration tests

### Static Files

- **`STATICFILES_STORAGE` removed** → Use `STORAGES` dict:
```python
STORAGES = {
    "staticfiles": {
        "BACKEND": "django.contrib.staticfiles.storage.ManifestStaticFilesStorage"
    }
}
```

### Tasks Framework (NEW - replacing Celery for simple needs)

```python
from django.tasks import task

@task
def send_email_task(user_id):
    # Background work
    pass

# Enqueue
send_email_task.enqueue(user.id)

# settings.py
TASKS = {
    "default": {"BACKEND": "django_tasks.backends.database.DatabaseBackend"},
}
```

### CSP (Content Security Policy) - Built-in

```python
MIDDLEWARE = ["django.middleware.csp.ContentSecurityPolicyMiddleware"]

SECURE_CSP_REPORT_ONLY = {
    "script-src": ["'self'", "'nonce-{{ csp_nonce }}'"],
    "object-src": ["'none'"],
}
```

### Dynamic Field Refresh on Save() - NO more refresh_from_db()

```python
# Now works automatically with GeneratedField and expressions
video = Video.objects.get(id=1)
video.title = "New"
video.save()
print(video.full_title)  # Already updated! No refresh_from_db() needed
```

Uses `RETURNING` clause (SQLite, PostgreSQL, Oracle).

---

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
## Ecosystem Libraries

### iommi
- **URL**: https://github.com/iommirocks/iommi (docs: https://docs.iommi.rocks/)
- **PyPI**: `iommi`
- **Version**: 7.31.0 (Python >=3.12; Django >=5.2, tested on Django 5.2 and 6.0)

A high-level framework built on Django for building web apps (CRUD apps) faster, without writing HTML or JavaScript. Composes forms, tables, menus, and fragments into full pages declaratively in Python.

**Key features**:
- Forms that feel like Django forms but scale to complex cases (auto-config from models)
- Powerful tables (list, filter, sort, paginate) plus edit tables for full CRUD
- Page composition system: combine forms, tables, menus, fragments into pages with access control
- Dev tools: live edit, jump-to-code, profiler, SQL trace, feedback for missing select/prefetch
- Actionable error messages when configuration is wrong

```bash
pip install iommi
```

### django-boilerplate (SaaS Pegasus)
- **URL**: https://github.com/saaspegasus/django-boilerplate
- **PyPI**: N/A (the `django-boilerplate` PyPI name belongs to an unrelated abandoned package — use by forking/cloning this repo)
- **Version**: No tagged releases (README targets Django 6 on Python 3.14)

The open-source edition of the SaaS Pegasus boilerplate: a free, production-grade starting point for a new Django app with a modern front-end stack and built-in essentials, optimized for the AI-agent era.

**Key features**:
- Django 6 on Python 3.14 with clean project structure
- Authentication via django-allauth (sign-up, login, password reset, email verification)
- HTMX + Alpine.js interactivity; Tailwind CSS v4 + DaisyUI wired through Vite and django-vite
- REST API on Django REST Framework with an auto-generated, OpenAPI-typed API client
- Celery + Redis background tasks, Postgres, Docker Compose, uv, Ruff, pre-commit, pytest, GitHub Actions CI, and agent-ready `CLAUDE.md`/`AGENTS.md` files

```bash
git clone https://github.com/saaspegasus/django-boilerplate.git
cd django-boilerplate
make init   # builds Postgres/Redis, runs migrations, installs frontend deps (Docker required)
make dev    # run app at localhost:8000
```

### double-turbo
- **URL**: https://github.com/Mte90/double-turbo
- **PyPI**: N/A (not on PyPI; repo-only boilerplate)
- **Version**: 0.1.0 (Python >=3.13, Django >=5.1)

A pure-API Django boilerplate aimed at SaaS development, built on Turbo (the Unfold admin boilerplate) plus TurboDRF, shipping a complete API project with admin panel and production deployment pieces.

**Key features**:
- Automatic REST API generation from models via TurboDRF, with an Unfold-admin-based admin panel and Swagger docs
- Stripe subscriptions via a fork of drf-stripe-subscription (multi-user membership)
- Auth stack: django-allauth + dj-rest-auth (JWT), dj-hijack (work on behalf of users), inactive users by default
- Ops tooling: django-prometheus metrics, drf-api-tracking, django-auditlog, Loguru logging (django-easy-logging), django-split-settings + python-dotenv
- Production deployment: Dockerfile, Nginx config, Celery/Celery Beat systemd services (RabbitMQ), GitLab CI example with `deploy-prod.sh`

```bash
git clone https://github.com/Mte90/double-turbo.git
cd double-turbo
uv sync
python setup.py   # initialize the database
uv run -- python manage.py runserver 0.0.0.0:8000
```

### nanodjango
- **URL**: https://github.com/radiac/nanodjango
- **PyPI**: `nanodjango`
- **Version**: 0.16.3 (Python >=3.8 declared; Django >=5.2 dependency, so effectively modern Python 3.10+)

Write a complete Django site — models, views, admin, and API — in a single `.py` file, run it locally or in production, and share it as a standalone script.

**Key features**:
- Single-file apps: `@app.route`, standard Django models auto-registered with the admin, class-based or function views
- Built-in Django Ninja API support (`@app.api.get`) and async view support
- CLI: `nanodjango run` (dev server + auto migrations), `nanodjango manage` (any manage.py command), `nanodjango serve` (gunicorn/uvicorn with production defaults)
- `nanodjango convert` upgrades the single file into a full Django project when it outgrows one file
- Shareable apps via PEP 723 inline script metadata: run with `uv run script.py` / `pipx run script.py`, no install needed; online playground at nanodjango.dev/play

```bash
pip install nanodjango
```

### neapolitan
- **URL**: https://github.com/carltongibson/neapolitan
- **PyPI**: `neapolitan`
- **Version**: 26.1 (CalVer: year.release; supports all current Django and Python versions, dropped at EOL)

Provides quick CRUD views for Django: one `CRUDView` subclass gives you the standard list, detail, create, edit, and delete views for a model, with hooks to customize any part.

**Key features**:
- `CRUDView.get_urls()` generates standard CRUD URLs for a model with minimal configuration
- Customization hooks on every part of the flow (fields, filters, actions, templates)
- Filtering via `filterset_fields` (uses django-filter)
- Base templates and reusable template tags for getting model data on the page
- Docs at https://noumenal.es/neapolitan/

```bash
pip install neapolitan
# then add "neapolitan" to INSTALLED_APPS and create a base.html with a {% block content %}
```

### django-migration-zero
- **URL**: https://github.com/ambient-innovation/django-migration-zero
- **PyPI**: `django-migration-zero`
- **Version**: 2.4.1 (Python >=3.11; Django >=4.2)

A holistic implementation of the "migration zero" pattern for Django: cleans up local migrations and handles updating the migration history of already-deployed environments (test/production), as an alternative to Django's squashing.

**Key features**:
- Removes all existing local migration files and recreates them as a fresh initial migration set
- Configuration singleton in the Django admin to prepare the clean-up deployment
- Management command for CI/CD pipelines that rewrites Django's migration history table to match the recreated migrations
- Alternative to migration squashing that avoids circular-dependency problems (for apps where you control all environments)
- 100% test coverage; fully automated, Sigstore-signed releases via PyPI Trusted Publishing

```bash
pip install django-migration-zero
# then add 'django_migration_zero' to INSTALLED_APPS
```

### django-maintenance-mode
- **URL**: https://github.com/fabiocaccamo/django-maintenance-mode
- **PyPI**: `django-maintenance-mode`
- **Version**: 0.23.0 (Django >=4.2)

Middleware that shows a 503 error page while maintenance mode is on. Works at application level (the Django instance must be up) and does not use the database, so it's safe during deployments and DB migrations.

**Key features**:
- Multiple state backends: local file (default), Django default storage, static storage, and cache — no database required
- Fine-grained ignore rules: admin site, staff, superusers, authenticated/anonymous users, IP addresses, and URL patterns
- Scheduled maintenance windows with `start`/`end` datetimes — auto on/off without cron
- Toggle from anywhere: Python API (`set_maintenance_mode`), `manage.py maintenance_mode on|off`, superuser URLs, view decorators, and context managers
- Configurable 503 template, HTML or JSON response type, custom status code, and Retry-After header

```bash
pip install django-maintenance-mode
# add maintenance_mode to INSTALLED_APPS, MaintenanceModeMiddleware to MIDDLEWARE, and a templates/503.html
```

### django-recurrence
- **URL**: https://github.com/jazzband/django-recurrence
- **PyPI**: `django-recurrence`
- **Version**: 1.14 (Python >=3.9; Django >=4.0)

Django utility for working with recurring dates, wrapping `dateutil.rrule` in an RFC 2445-compatible subset so you can store and render recurrence rules in Django models and forms.

**Key features**:
- `Recurrence`/`Rule` objects for specifying recurring dates/times (wraps `dateutil.rrule`)
- `RecurrenceField` model field that serializes recurrence information for database storage
- JavaScript widget included for form rendering
- Template tags/filters for expanding recurrence rules in templates
- Jazzband-maintained with active CI across supported Python/Django versions; docs at django-recurrence.readthedocs.io

```bash
pip install django-recurrence
```

### dj-database-url
- **URL**: https://github.com/jazzband/dj-database-url
- **PyPI**: `dj-database-url`
- **Version**: 3.1.2 (Python >=3.10; Django >=4.2)

A simple utility that lets you configure your Django `DATABASES` setting from a 12-factor `DATABASE_URL` environment variable.

**Key features**:
- `dj_database_url.config()` reads the `DATABASE_URL` env var, with a `default=` fallback
- `dj_database_url.parse()` to configure Django from any arbitrary database URL string
- `conn_max_age` (CONN_MAX_AGE) and `conn_health_checks` (CONN_HEALTH_CHECKS) options for connection pooling
- Supports PostgreSQL/PostGIS, MySQL/MySQL GIS, Oracle/Oracle GIS, MSSQL, Redshift, CockroachDB, Timescale/Timescale GIS, SQLite/SpatiaLite
- `register()` to add custom backends, including post-processing hooks for backend-specific config; `test_options` for test DB settings

```bash
pip install dj-database-url
```

### awesome-django
- **URL**: https://github.com/wsvincent/awesome-django
- **PyPI**: N/A

A curated list of awesome Django packages, tools, and resources. Useful for discovering Django ecosystem packages. Maintained by Will Vincent and Jeff Triplett (~11.2k stars), organized into third-party packages (admin, APIs, caching, task queues, testing, etc.), Python packages, resources (tutorials, books, conferences, podcasts), hosting, and DRF/Wagtail sections.

```bash
# Not a library — browse at https://github.com/wsvincent/awesome-django
```

## References

- **Django CSRF Docs**: https://docs.djangoproject.com/en/stable/ref/csrf/
- **Django Authentication**: https://docs.djangoproject.com/en/stable/topics/auth/
- **Django Security**: https://docs.djangoproject.com/en/stable/topics/security/
- **ORM Performance**: https://johnnymetz.com/posts/avoiding-duplicate-objects-in-django-querysets/
- **Time-based Lookups**: https://johnnymetz.com/posts/django-time-based-lookups-performance/
- **Django Tasks**: https://www.loopwerk.io/articles/2026/django-tasks-review/
- **Django Permissions**: https://dandavies99.github.io/posts/2021/11/django-permissions/
- **ORM Database Support**: https://www.paulox.net/2025/10/06/django-orm-comparison/
- **GeneratedField PostgreSQL**: https://www.paulox.net/2023/11/24/database-generated-columns-part-2-django-and-postgresql/
- **GeneratedField SQLite**: https://www.paulox.net/2023/11/07/database-generated-columns-part-1-django-and-sqlite/
- **GeoDjango Maps**: https://www.paulox.net/2025/04/11/maps-with-django-part-3-geodjango-pillow-and-gps/