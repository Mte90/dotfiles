<!-- This file is loaded on demand from frameworks/django/SKILL.md -->

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
from secrets import compare_digest

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

### Constant-Time Token Comparison

**CRITICAL**: Use `secrets.compare_digest()` for token/API key comparison - prevents timing attacks:

```python
from secrets import compare_digest
from django.conf import settings

def verify_api_key(requested_key: str) -> bool:
    """Constant-time comparison prevents timing attacks."""
    # NEVER use: requested_key == settings.API_KEY
    # Timing attack: attacker measures response time to guess key char by char
    return compare_digest(requested_key, settings.API_KEY)

# Case-insensitive token comparison
def verify_token(requested_token: str, expected_token: str) -> bool:
    """Case-insensitive constant-time comparison."""
    return compare_digest(
        requested_token.lower().strip(),
        expected_token.lower().strip()
    )
```

### Never Trust POSTed Identity Fields (HTMX)

**CRITICAL**: With HTMX partial submissions, POST data can be manipulated. Always use `request.user`:

```python
# BAD - Trusting POSTed identity
def update_profile(request):
    user_id = request.POST.get('user_id')  # ⚠️ Attacker can change this!
    user = User.objects.get(id=user_id)
    user.name = request.POST.get('name')
    user.save()

# GOOD - Use request.user
@login_required
def update_profile(request):
    # Identity comes from authentication, not POST
    user = request.user  # ✅ Authenticated user
    user.name = request.POST.get('name')  # Only update allowed fields
    user.save()
```

**HTMX-specific vulnerability**: HTMX forms often submit partial data. If your form includes `user_id` or other identity fields in the POST, attackers can manipulate them. The authentication middleware already set `request.user` - use it.
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

### Additional Permission Libraries

Companions to django-guardian:
- **django-rules** (https://github.com/dfunckt/django-rules) - Object-level permissions without database (pre-save hooks)
- **django-role-permissions** (https://github.com/vintasoftware/django-role-permissions) - Role-based access control on top of Django permissions

---


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


