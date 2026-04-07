---
name: django-security
description: "Django security - CSRF protection, authentication, sessions, login/logout, password handling, middleware, protected views"
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - python
    - django
    - security
    - csrf
    - authentication
    - sessions
    - authentication
---

# Django Security

Comprehensive guide to Django security features including CSRF protection, authentication, sessions, and security best practices.

## Overview

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

## References

- **Django CSRF Docs**: https://docs.djangoproject.com/en/stable/ref/csrf/
- **Django Authentication**: https://docs.djangoproject.com/en/stable/topics/auth/
- **Django Security**: https://docs.djangoproject.com/en/stable/topics/security/