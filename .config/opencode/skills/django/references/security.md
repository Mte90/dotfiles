<!-- This file is loaded on demand from frameworks/django/SKILL.md -->

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


