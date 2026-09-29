---
name: django-unfold
description: Use when theming the Django admin with django-unfold - settings and sidebar configuration, custom admin site, components and @display decorator, filters, actions, tabs, dark mode and styling, or Django 6.x compatibility
metadata:
  author: mte90
  version: 2.0.0
  based_on: https://github.com/unfoldadmin/django-unfold
  tags:
    - python
    - django
    - admin
    - unfold
    - theme
    - dashboard
---

# Django Unfold

Modern Django admin theme with beautiful design and advanced features.

## Overview

Unfold is a modern theme for Django admin that provides:

**Versions**: django-unfold 0.76.x + Django 6.0 fully compatible.
- **Beautiful design** - Modern UI with Tailwind CSS
- **Dark mode** - Built-in dark theme support
- **Custom components** - Charts, tables, cards, buttons
- **Easy customization** - Settings, branding, sidebar
- **Integrations** - Works with django-celery-beat, django-import-export, etc.

---

## Installation

```bash
pip install django-unfold

# Or with specific version
pip install django-unfold==0.9.0
```

```python
# settings.py
INSTALLED_APPS = [
    'unfold',  # Must come BEFORE django.contrib.admin
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    # ... other apps
]

# Unfold settings
UNFOLD = {
    # Configuration here
}
```

> **Important**: `unfold` must be first in `INSTALLED_APPS` to override Django templates.

---

## Quick Start

### Basic Configuration

```python
# settings.py
INSTALLED_APPS = [
    'unfold',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
]

# Optional: Add your custom admin site class
# UNFOLD_ADMIN_SITE_CLASS = 'path.to.CustomAdminSite'
```

### URL Configuration

Unfold doesn't require changes to your URL configuration:

```python
# urls.py - No changes needed!
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    # ... other urls
]
```

---

## Integrations

### django-guardian (Object Permissions)

```python
# Install
pip install django-guardian

# Add to INSTALLED_APPS
INSTALLED_APPS = [
    'guardian',
    'unfold',
    'django.contrib.admin',
    # ...
]

# Add to URLs
from django.contrib import admin
from unfold.contrib.guardian.admin import GuardedModelAdmin

class ArticleAdmin(GuardedModelAdmin):
    pass
```

### django-import-export

```python
pip install django-import-export

# Works automatically with Unfold
# Custom resource if needed
from import_export import resources
from unfold.admin import ImportExportMixin

class ArticleResource(resources.ModelResource):
    class Meta:
        model = Article
        fields = ('id', 'title', 'status', 'created_at')

class ArticleAdmin(ImportExportMixin, ModelAdmin):
    resource_classes = [ArticleResource]
```

### django-celery-beat

```python
# Install
pip install django-celery-beat

# Configuration is automatic with Unfold
# Shows schedule in admin dashboard
```

### django-constance

```python
pip install django-constance[database]

INSTALLED_APPS = [
    'constance',
    'unfold',
    # ...
]

# Configuration is automatic
# Shows in admin under "Constance" section
```

---

## Authentication Customization

### Custom Login Form

```python
# Custom form for Unfold login
from django import forms
from unfold.forms import LoginForm

class CustomLoginForm(LoginForm):
    def clean(self):
        # Add custom validation
        cleaned_data = super().clean()
        # Custom logic
        return cleaned_data
```

```python
# settings.py
UNFOLD = {
    'LOGIN': {
        'form': 'myapp.forms.CustomLoginForm',
    },
}
```

### Custom Views

```python
# Custom password reset
UNFOLD = {
    'PASSWORD_CHANGE_FORM': 'myapp.forms.CustomPasswordChangeForm',
    'PASSWORD_RESET_FORM': 'myapp.forms.CustomPasswordResetForm',
}
```

---

## Best Practices

1. **Keep unfold first** in INSTALLED_APPS
2. **Use Unfold ModelAdmin** for all models
3. **Leverage tabs** for organized forms
4. **Use filters** for better list navigation
5. **Customize actions** for bulk operations
6. **Enable dark mode** - users love it
7. **Use integrations** - they work out of the box

---

## Deep Dives

For detailed reference, load these on-demand:

- **Settings & Customization** — `references/settings-customization.md` - Settings reference, custom admin site, dark mode, custom styling
- **Components & Actions** — `references/components-actions.md` - Components, fields, filters, actions, tabs
- **Ecosystem & Compatibility** — `references/ecosystem-compat.md` - Ecosystem libraries, Django 6.x compatibility, ordering notes

---

## References

- **GitHub**: https://github.com/unfoldadmin/django-unfold
- **Documentation**: https://unfoldadmin.com/docs
- **Demo**: https://unfoldadmin.com/