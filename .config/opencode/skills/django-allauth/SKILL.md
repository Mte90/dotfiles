---
name: django-allauth
description: Use when implementing Django authentication - local accounts, OAuth, email verification, MFA, OIDC, django-organizations
metadata:
  author: mte90
  version: 2.0.0
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

## OIDC Provider (NEW in 65.x)

```python
INSTALLED_APPS = [
    # ... existing apps
    "allauth.idp.oidc",  # OIDC provider
]

# For Django Ninja:
from allauth.idp.oidc.contrib.ninja.security import TokenAuth

# For DRF:
from allauth.idp.oidc.contrib.rest_framework.authentication import TokenAuthentication
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

## Signals

Only a handful of signals matter operationally. Full list: https://docs.allauth.org/en/latest/_modules/allauth/core/signals.html

| Signal | When it fires | Use this when… |
|--------|---------------|----------------|
| `user_signed_up` | After user object created, before email sent | Send welcome emails, create profile rows, call external services |
| `user_logged_in` | After successful authentication | Log activity, refresh sessions, sync with external systems |
| `email_confirmed` | After email verification completes | Grant features, send confirmation receipts, update CRM |
| `password_changed` | After password update | Invalidate other sessions, notify user, audit trail |
| `social_account_added` | After OAuth account linked | Sync profile data, merge duplicate accounts |

```python
from allauth.account import signals
from django.dispatch import receiver

@receiver(signals.user_signed_up)
def on_user_signup(request, user, **kwargs):
    # Create profile, send welcome email
    pass
```
## Templates

All allauth templates are overridable by shadowing them in your project's `templates/` directory. See [template overriding docs](https://docs.allauth.org/en/latest/templates.html) for the full list.

Common overrides:
- `account/login.html`, `account/signup.html` — customize forms
- `account/email/email_confirmation_message.txt` — branded emails
- `socialaccount/login.html` — provider selection UI

## Anti-Patterns

| Failure | Cause | Fix |
|---------|-------|-----|
| `user.email` raises `DoesNotExist` | Accessing email before checking `EmailAddress` table | Use `EmailAddress.objects.get_primary(user)` or check `user.email_set.exists()` first |
| Stale sessions after password reset | Not invalidating other sessions | Set `ACCOUNT_SESSION_COOKIE_AGE` short; use `signals.password_changed` to revoke |
| Verification emails not sending | `EMAIL_BACKEND` set to console in production | Configure real SMTP; test with `EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'` in dev |
| Social login creates duplicates | Not checking existing emails in `pre_social_login` | In adapter: check `EmailAddress` for matching email, merge if found |
| MFA bypass in dev | `MFA_ENABLED = False` but prod uses MFA | Keep MFA on in all envs; disable per-user for testing |

## When Not to Use allauth

**API-only / headless projects** — If you're building a SPA or mobile backend with no server-rendered pages, allauth's template system is dead weight. Consider:
- Simple JWT signup/login with `djangorestframework-simplejwt`
- Custom views using Django's `User` model directly
- Only adopt allauth if you need social providers or complex email flows

**Existing user model conflicts** — If your project already has:
- A custom `AbstractUser` with fields allauth doesn't expect
- Existing auth logic that would need to be unwound
- Third-party packages that hook into auth in incompatible ways

Check before adopting:
1. `python manage.py shell` → `from django.contrib.auth import get_user_model; print(get_user_model()._meta.fields)` — does it match allauth's expectations?
2. Search for `AUTH_USER_MODEL` — is it already set to something custom?
3. Review existing login/signup views — can they be replaced, or would allauth fight them?

## Flow Decision Guide

### Email Verification

| Requirement | Setting | Common failure |
|-------------|---------|----------------|
| Must verify before login | `ACCOUNT_EMAIL_VERIFICATION = 'mandatory'` | Users complain they can't login; forgot to configure SMTP |
| Optional, but prefer verified | `ACCOUNT_EMAIL_VERIFICATION = 'optional'` + middleware check | Feature access not gated; check `EmailAddress.verified` in views |
| No verification needed | `ACCOUNT_EMAIL_VERIFICATION = 'none'` | Only for internal tools; emails still stored |

### Social + Password Combo

| Scenario | Configuration |
|----------|---------------|
| Social-only (no password) | Set `ACCOUNT_PASSWORD_REQUIRED = False`; remove password URLs from nav |
| Both allowed, separate flows | Default config; users choose at login |
| Password users can link social | Enable `SOCIALACCOUNT_AUTO_SIGNUP = False`; let users connect in settings |

### MFA Enablement

| Timing | Approach |
|--------|----------|
| Force at next login | Set `MFA_REQUIRED = True`; users redirected to `/mfa/` on auth |
| Optional, encourage | Show MFA status in profile; no enforcement |
| Per-role enforcement | Middleware: check `request.user.groups`, redirect high-priv users to `/mfa/` if not enrolled |

### Session / Redirect Separation

| Setting | Purpose |
|---------|--------|
| `LOGIN_REDIRECT_URL` | Where authenticated users go after login (allauth uses this) |
| `ACCOUNT_LOGIN_REDIRECT_URL` | Overrides `LOGIN_REDIRECT_URL` for allauth specifically |
| `ACCOUNT_LOGOUT_REDIRECT_URL` | Where users land after logout |
| Common failure | Set both `LOGIN_REDIRECT_URL` and `ACCOUNT_LOGIN_REDIRECT_URL` inconsistently; pick one and stick with it |

## Adapters

Adapters are the structural chokepoint for auth logic. Customize here instead of patching allauth internals.

### Custom Account Adapter

**Why you need this:** Add validation, enforce policies, integrate with external systems.

```python
# myapp/adapter.py
from allauth.account.adapter import DefaultAccountAdapter
from django.core.exceptions import ValidationError

class CustomAccountAdapter(DefaultAccountAdapter):
    def save_user(self, request, user, form, commit=True):
        """Add profile row when user signs up."""
        user = super().save_user(request, user, form, commit=False)
        if commit:
            from myapp.models import Profile
            Profile.objects.create(user=user)
        return user
    
    def clean_email(self, request, email):
        """Reject disposable email domains."""
        email = super().clean_email(request, email)
        disposable_domains = {'tempmail.com', 'throwaway.email'}
        domain = email.split('@')[-1].lower()
        if domain in disposable_domains:
            raise ValidationError('Disposable email domains not allowed')
        return email

# settings.py
ACCOUNT_ADAPTER = 'myapp.adapter.CustomAccountAdapter'
```

### Custom Social Account Adapter

**Why you need this:** Enforce allowlists, merge accounts, enforce org membership.

```python
# myapp/adapter.py
from allauth.socialaccount.adapter import DefaultSocialAccountAdapter
from allauth.socialaccount.models import SocialLogin
from django.core.exceptions import PermissionDenied

class CustomSocialAccountAdapter(DefaultSocialAccountAdapter):
    ALLOWED_DOMAINS = {'company.com', 'partner.org'}
    
    def pre_social_login(self, request, sociallogin):
        """Reject signups from unauthorized domains."""
        if sociallogin.state.get('action') != 'login':
            return  # New signup flow
        
        email = sociallogin.user.email
        if not email:
            return  # Let provider handle it
        
        domain = email.split('@')[-1].lower()
        if domain not in self.ALLOWED_DOMAINS:
            raise PermissionDenied(f'@{domain} not authorized for signup')
    
    def populate_user(self, request, sociallogin, data):
        """Sync profile fields from provider."""
        user = super().populate_user(request, sociallogin, data)
        # Sync first/last name from provider data
        user.first_name = data.get('first_name', '')
        user.last_name = data.get('last_name', '')
        return user

# settings.py
SOCIALACCOUNT_ADAPTER = 'myapp.adapter.CustomSocialAccountAdapter'
```

## Deep Dives

- [Examples](references/examples.md) — custom signup form, verified email middleware
