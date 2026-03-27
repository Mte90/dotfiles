---
name: django-allauth
description: "Django authentication - local accounts, social OAuth, registration, email verification, MFA, session management"
metadata:
  author: "OSS AI Skills"
  version: "1.0.0"
  tags:
    - python
    - django
    - authentication
    - oauth
    - social-login
    - mfa
    - django-allauth
---

# django-allauth

Django authentication package.

## Overview

django-allauth is a reusable Django app for local and social authentication. It handles signup, login, logout, email verification, and integrates with many OAuth providers.

**Key Features:**
- Local account management (signup, login, password reset)
- OAuth providers (Google, GitHub, Facebook, etc.)
- Email verification
- Multi-factor authentication (TOTP, WebAuthn)
- Headless REST API support
- Session management
- Custom adapters

### Installation

```bash
pip install django-allauth

# With optional dependencies
pip install django-allauth[socialaccount]
pip install django-allauth[mfa]
```

## Quick Start

### settings.py

```python
INSTALLED_APPS = [
    # Required apps
    'django.contrib.auth',
    'django.contrib.messages',
    'django.contrib.sites',
    
    # allauth
    'allauth',
    'allauth.account',
    'allauth.socialaccount',
]

# Authentication backends
AUTHENTICATION_BACKENDS = [
    'allauth.account.auth_backends.AuthenticationBackend',
]

# Site ID
SITE_ID = 1

# allauth settings
ACCOUNT_AUTHENTICATION_METHOD = 'email'  # or 'username'
ACCOUNT_EMAIL_REQUIRED = True
ACCOUNT_USERNAME_REQUIRED = False
ACCOUNT_EMAIL_VERIFICATION = 'mandatory'  # or 'optional', 'none'

LOGIN_REDIRECT_URL = '/'
ACCOUNT_LOGOUT_REDIRECT_URL = '/'
```

### urls.py

```python
from django.urls import path, include

urlpatterns = [
    path('accounts/', include('allauth.urls')),
]
```

## Local Authentication

### Signup

```python
# views.py
from allauth.account.views import SignupView

# Uses built-in signup form
# POST /accounts/signup/
```

### Login

```python
# POST /accounts/login/
# Uses built-in login form

# With remember me
# POST /accounts/login/ with remember=true
```

### Logout

```python
# POST /accounts/logout/
# Clears session
```

### Password Management

```python
# Password change: POST /accounts/password/change/
# Password set: POST /accounts/password/set/
# Password reset: POST /accounts/password/reset/
# Password reset confirm: POST /accounts/password/reset/confirm/
```

## Email Configuration

### Settings

```python
# Email backend
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'

# allauth email settings
ACCOUNT_EMAIL_NOTIFICATIONS = True
EMAIL_CONFIRMATION_AUTHENTICATED_REDIRECT_URL = '/'
EMAIL_CONFIRMATION_ANONYMOUS_REDIRECT_URL = '/'
```

### Custom Email Templates

```
templates/account/email/
├── email_confirmation_subject.txt
├── email_confirmation_message.txt
├── email_confirmation_signup_message.txt
├── password_reset_key_message.txt
└── ...
```

### Sending Emails Manually

```python
from allauth.account.models import EmailAddress

# Get user's verified emails
emails = EmailAddress.objects.filter(
    user=user,
    verified=True
)

# Send via allauth adapter
from allauth.account.adapter import get_adapter
adapter = get_adapter()
adapter.send_mail(
    'account/email/custom_subject.txt',
    user,
    {'context': 'variables'},
    [user.email]
)
```

## OAuth Providers

### Google Setup

```python
# settings.py
INSTALLED_APPS += [
    'allauth.socialaccount.providers.google',
]

# Social app in admin:
# Add SocialApp with Google provider
# Client ID and Secret from Google Cloud Console
```

### GitHub Setup

```python
INSTALLED_APPS += [
    'allauth.socialaccount.providers.github',
]
```

### Custom Provider

```python
# myapp/providers.py
from allauth.socialaccount.providers.base import Provider
from allauth.socialaccount.providers.oauth2.provider import ProviderMixin

class MyCustomProvider(ProviderMixin, Provider):
    pass

# myapp/app_settings.py
from allauth.socialaccount import app_settings

provider_classes = [
    'myapp.providers.MyCustomProvider',
]

# settings.py
SOCIALACCOUNT_PROVIDERS = {
    'custom': {
        'APP': {
            'client_id': 'xxx',
            'secret': 'xxx',
            'key': ''
        }
    }
}
```

### Provider Settings

```python
SOCIALACCOUNT_PROVIDERS = {
    'google': {
        'APP': {
            'client_id': 'xxx',
            'secret': 'xxx',
        },
        'SCOPE': ['profile', 'email'],
        'AUTH_PARAMS': {'access_type': 'online'},
    },
    'github': {
        'APP': {
            'client_id': 'xxx',
            'secret': 'xxx',
        },
        'SCOPE': ['user:email'],
    },
}
```

## Multi-Factor Authentication

### Enable MFA

```python
INSTALLED_APPS += [
    'allauth.mfa',
]

# Settings
MFA_ENABLED = True
MFA_SUPPORTED_AUTHENTICATORS = [
    'allauth.mfa.authenticators.Totp',
    'allauth.mfa.authenticators.WebAuthn',
    'allauth.mfa.authenticators.RecoveryCodes',
]
```

### TOTP Setup

```python
# Users can set up TOTP via
# GET /mfa/totp/create/
# POST /mfa/totp/activate/
```

### WebAuthn

```python
# WebAuthn/fido2 setup
# GET /mfa/webauthn/create/
# POST /mfa/webauthn/activate/
```

### Recovery Codes

```python
# Generate recovery codes
# GET /mfa/recovery_codes/generate/
```

## REST API (Headless)

### Setup

```python
INSTALLED_APPS += [
    'allauth.headless',
]

# Settings
ALLAUTH_HEADLESS_ENABLED = True
ALLAUTH_HEADLESS_TOKEN_STRATEGY = 'allauth.headless.token.StrategyJWT'
ALLAUTH_HEADLESS_TOKEN_JWT_SECRET_KEY = 'your-secret'
ALLAUTH_HEADLESS_TOKEN_JWT_ALGORITHM = 'HS256'
```

### Endpoints

```bash
# Signup
POST /headless/signup/
{"email": "user@example.com", "password": "password"}

# Login
POST /headless/authentication/login/
{"email": "user@example.com", "password": "password"}

# Logout
POST /headless/authentication/logout/

# Get current user
GET /headless/users/me/

# Manage emails
GET/POST/DELETE /headless/emails/

# Manage passwords
POST /headless/password/set/
POST /headless/password/change/
POST /headless/password/reset/
```

### Token Strategies

```python
# JWT
ALLAUTH_HEADLESS_TOKEN_STRATEGY = 'allauth.headless.token.StrategyJWT'

# Session-based
ALLAUTH_HEADLESS_TOKEN_STRATEGY = 'allauth.headless.token.StrategySession'
```

## Adapters

### Custom Adapter

```python
# myapp/adapter.py
from allauth.account.adapter import DefaultAccountAdapter

class CustomAccountAdapter(DefaultAccountAdapter):
    def is_open_for_signup(self, request):
        return True  # Allow signup
    
    def send_mail(self, template_prefix, email_context, users):
        # Custom email sending
        pass
    
    def get_email_confirmation_redirect_url(self, request):
        return '/confirmed/'
    
    def authenticate(self, request, **credentials):
        # Custom authentication
        return super().authenticate(request, **credentials)

# settings.py
ACCOUNT_ADAPTER = 'myapp.adapter.CustomAccountAdapter'
```

### Social Account Adapter

```python
# myapp/adapter.py
from allauth.socialaccount.adapter import DefaultSocialAccountAdapter

class CustomSocialAccountAdapter(DefaultSocialAccountAdapter):
    def pre_social_login(self, request, sociallogin):
        # Called after login, before creating user
        pass
    
    def populate_user(self, request, sociallogin, data):
        # Populate user fields
        user = sociallogin.user
        user.first_name = data.get('first_name', '')
        user.last_name = data.get('last_name', '')
        return user

# settings.py
SOCIALACCOUNT_ADAPTER = 'myapp.adapter.CustomSocialAccountAdapter'
```

## Signals

### Account Signals

```python
from allauth.account import signals

# User signs up
signals.user_signed_up.connect(my_handler, sender=User)

# User logs in
signals.user_logged_in.connect(my_handler, sender=User)

# Email added
signals.email_added.connect(my_handler, sender=User)

# Email confirmed
signals.email_confirmed.connect(my_handler, sender=User)

# Password changed
signals.password_changed.connect(my_handler, sender=User)

# Password reset
signals.password_reset.connect(my_handler, sender=User)
```

### Social Account Signals

```python
from allauth.socialaccount import signals

# Social login successful
signals.social_login.connect(my_handler, sender=SocialLogin)

# Social account added
signals.social_account_added.connect(my_handler, sender=SocialAccount)

# Social account removed
signals.social_account_removed.connect(my_handler, sender=SocialAccount)

# Pre-update
signals.pre_update.connect(my_handler, sender=SocialAccount)
```

### MFA Signals

```python
from allauth.mfa import signals

# MFA enabled
signals.mfa_enabled.connect(my_handler, sender=User)

# MFA disabled
signals.mfa_disabled.connect(my_handler, sender=User)

# Authenticator created
signals.authenticator_created.connect(my_handler, sender=User)
```

## Templates

### Custom Templates

```
templates/
├── account/
│   ├── base.html
│   ├── login.html
│   ├── signup.html
│   ├── logout.html
│   ├── password_change.html
│   ├── password_reset.html
│   ├── password_set.html
│   ├── email/
│   │   ├── email_confirmation_subject.txt
│   │   └── email_confirmation_message.txt
│   └── snippets/
│       └── form.html
├── socialaccount/
│   ├── base.html
│   ├── login.html
│   ├── signup.html
│   ├── connections.html
│   └── snippets/
│       └── provider_list.html
└── mfa/
    ├── index.html
    ├── totp.html
    └── webauthn.html
```

### Template Tags

```django
{% load allauth_tags %}

{# Check if user is verified #}
{% user_verified request.user %}

{# Social account connections #}
{% socialaccount_providers %}

{# Login URL #}
{% provider_login_url "google" %}
```

## Best Practices

### 1. Use Adapter for Customization

```python
# Instead of modifying allauth, use adapter
ACCOUNT_ADAPTER = 'myapp.adapter.CustomAccountAdapter'
```

### 2. Enable HTTPS

```python
# In production
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
```

### 3. Rate Limiting

```python
# Allauth has rate limiting built-in
ACCOUNT_RATE_LIMITS = {
    'signup': '5/hour',
    'password_reset': '3/hour',
}
```

### 4. Email Verification

```python
# Require verification
ACCOUNT_EMAIL_VERIFICATION = 'mandatory'

# Or optional
ACCOUNT_EMAIL_VERIFICATION = 'optional'
```

## Examples

### Custom Signup Form

```python
# forms.py
from allauth.account.forms import SignupForm

class CustomSignupForm(SignupForm):
    first_name = forms.CharField(max_length=30)
    last_name = forms.CharField(max_length=30)
    
    def save(self, request):
        user = super().save(request)
        user.first_name = self.cleaned_data['first_name']
        user.last_name = self.cleaned_data['last_name']
        user.save()
        return user

# views.py
from allauth.account.views import SignupView
from .forms import CustomSignupForm

class CustomSignupView(SignupView):
    form_class = CustomSignupForm

# urls.py
path('accounts/signup/', CustomSignupView.as_view(), name='account_signup')
```

### Require Verified Email

```python
# myapp/middleware.py
from django.shortcuts import redirect
from allauth.account.models import EmailAddress

def verified_email_required(get_response):
    def middleware(request):
        if request.user.is_authenticated:
            email = EmailAddress.objects.filter(
                user=request.user,
                verified=True
            ).exists()
            if not email:
                return redirect('/accounts/verify-email/')
        return get_response(request)
    return middleware

# settings.py
MIDDLEWARE += ['myapp.middleware.verified_email_required']
```

## References

- **Official Documentation**: https://docs.allauth.org/
- **GitHub Repository**: https://github.com/pennersr/django-allauth
- **Stack Overflow**: https://stackoverflow.com/questions/tagged/django-allauth