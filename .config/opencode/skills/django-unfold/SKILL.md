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

### Custom Login Form with Design System Integration

**When you need this**: Customize the admin login page to match your design system using unfold's template overrides.

```python
# settings.py - Override login template
def get_custom_login_template(request):
    return "admin/custom_login.html"

UNFOLD = {
    'TEMPLATES': {
        'login': get_custom_login_template,
    },
    'LOGIN': {
        'show_language_switcher': False,
        'extra_fields': [
            {'field': 'organization', 'type': 'select', 'required': True},
        ],
    },
}
```

```html
<!-- templates/admin/custom_login.html -->
{% extends "unfold/login.html" %}
{% load i18n %}

{% block branding %}
<div class="flex items-center gap-3 mb-6">
    <img src="/static/img/company-logo.svg" alt="Company" class="h-10">
    <span class="text-xl font-semibold">Admin Portal</span>
</div>
{% endblock %}
```

### Custom UserAdmin with Additional Fields

**When you need this**: Add custom fields to the user admin form for organization-specific user attributes.

```python
# admin.py
from django.contrib import admin
from unfold.admin import ModelAdmin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import User
from unfold.contrib.filters import AutocompleteFilter

class OrganizationFilter(AutocompleteFilter):
    title = "Organization"
    field_name = "organization"

@admin.register(User)
class UserAdmin(BaseUserAdmin):
    # Inherit Unfold styling while adding custom fields
    fieldsets = BaseUserAdmin.fieldsets + (
        ("Organization", {"fields": ("organization", "employee_id")}),
    )
    
    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        ("Organization", {"fields": ("organization",)}),
    )
    
    list_filter = BaseUserAdmin.list_filter + ("organization", OrganizationFilter)
```

### Custom Admin Site Authentication

**When you need this**: Override the entire authentication flow with custom admin site class.

```python
# admin.py
from unfold.admin import UnfoldAdminSite
from django.contrib.auth.forms import AuthenticationForm

class CustomAuthForm(AuthenticationForm):
    def confirm_login_allowed(self, user):
        # Custom authentication logic
        if not user.is_active:
            raise ValidationError("Account inactive")
        if user.organization.status != "active":
            raise ValidationError("Organization suspended")

class CustomAdminSite(UnfoldAdminSite):
    def login(self, request, extra_context=None):
        extra_context = extra_context or {}
        extra_context["custom_message"] = "Welcome to the admin"
        return super().login(request, extra_context)

admin_site = CustomAdminSite(name="custom")
```

```python
# settings.py
UNFOLD_ADMIN_SITE_CLASS = "myapp.admin.CustomAdminSite"
```

---

## Common Pitfalls

### INSTALLED_APPS Ordering

**Failure**: Unfold silently ignored, admin renders with default Django theme.

```python
# WRONG - unfold must come BEFORE django.contrib.admin
INSTALLED_APPS = [
    'django.contrib.admin',  # ❌ Too late, templates already loaded
    'unfold',
]

# CORRECT
INSTALLED_APPS = [
    'unfold',  # ✅ Template engine override works
    'django.contrib.admin',
]
```

---

### Template Extension Mistake

**Failure**: Custom template doesn't apply Unfold styling because it extends wrong base.

```python
# WRONG - extends stock Django admin, bypasses Unfold
{% extends "admin/base.html" %}  # ❌ Missing Unfold blocks

# CORRECT - extends Unfold's base template
{% extends "unfold/base.html" %}  # ✅ Gets Unfold's CSS, layout, sidebar
```

### UNFOLD Settings Case Sensitivity

**Failure**: Settings silently ignored due to lowercase keys.

```python
# WRONG - keys must be UPPER_CASE
UNFOLD = {
    'site_header': 'My Admin',  # ❌ Ignored
    'show_sidebar': True,       # ❌ Ignored
}

# CORRECT
UNFOLD = {
    'SITE_HEADER': 'My Admin',  # ✅
    'SHOW_SIDEBAR': True,       # ✅
}
```

### Styling Without Theme Pipeline

**Failure**: Custom CSS conflicts with Unfold's Tailwind classes, requires constant maintenance.

```python
# WRONG - raw CSS file overrides Unfold classes
UNFOLD = {
    'STYLES': ['css/custom.css'],  # ❌ Brittle, breaks on Unfold updates
}

/* custom.css */
.sidebar { background: blue !important; }  /* ❌ Fighting framework */
```

**Correct approach**: Use Unfold's theme customization or Tailwind config.

```python
# CORRECT - extend Unfold's color system
UNFOLD = {
    'COLORS': {
        'primary': {
            '50': '239 246 255',
            '500': '59 130 246',
            # ... full palette
        },
    },
}
```

---

## Integrations Decision Guide

### django-guardian (Object Permissions)

**Solves**: Per-object permissions beyond Django's model-level permissions.

- **Choose it when**: You need granular access control (e.g., users can only edit their own records)
- **Skip it when**: Model-level permissions (`add`, `change`, `delete`, `view`) are sufficient

**URL**: https://github.com/django-guardian/django-guardian

### django-import-export

**Solves**: Import/export data via CSV, Excel, YAML in admin.

- **Choose it when**: Non-technical users need to bulk-import or export data through admin
- **Skip it when**: Data migration is one-time or handled by API/ETL tools

**URL**: https://github.com/django-import-export/django-import-export

### django-celery-beat

**Solves**: Schedule periodic Celery tasks via admin interface.

- **Choose it when**: You need cron-like scheduling with admin UI for task management
- **Skip it when**: Tasks run on fixed intervals (use Celery beat config) or triggered by events

**URL**: https://github.com/celery/django-celery-beat

### django-constance

**Solves**: Runtime site-wide settings editable via admin.

- **Choose it when**: You need feature flags or configuration values changed without redeploy
- **Skip it when**: Settings are static or managed via environment variables

**URL**: https://github.com/jazzband/django-constance

### django-unfold-modal

**Solves**: Replace admin popup windows with in-page modals for related object selection.

- **Choose it when**: UX polish matters and you want seamless related-object creation
- **Skip it when**: Popups are acceptable or you're using autocomplete_fields exclusively

**URL**: https://github.com/metaforx/django-unfold-modal

### django-unfold-markdown

**Solves**: Markdown editor widget for admin text fields.

- **Choose it when**: Content editors need Markdown formatting without rich-text overhead
- **Skip it when**: You need WYSIWYG editing or plain text is sufficient

**URL**: https://github.com/sergei-vasilev-dev/django-unfold-markdown

---

## When Not to Use Unfold

Plain Django admin is sufficient when:

- **Small internal projects** - Admin used by <5 power users, no branding requirements
- **Heavy customization needed** - Unfold's template override layer becomes maintenance cost when you're rewriting 50% of templates
- **No Tailwind expertise** - Adding Tailwind build pipeline just for admin theming is overkill
- **Budget constraints** - Unfold is free, but Tailwind compilation and theme maintenance have hidden costs

**Check before adopting**:
1. Does your team have Tailwind CSS experience?
2. Will admin branding be reviewed by stakeholders?
3. Are you comfortable maintaining template overrides if Unfold breaks them?
4. Is the admin used frequently enough to justify the UX investment?

If answers are "no" to most, stick with stock Django admin or consider lighter themes.

---

## Django Version Compatibility

| Unfold Version | Django Version |
|----------------|----------------|
| 0.76.x +       | 6.0+           |
| 0.70.x - 0.75.x | 5.0+, 5.1+    |
| 0.60.x - 0.69.x | 4.2+, 5.0+    |
| 0.50.x - 0.59.x | 4.1+, 4.2+    |

**Full compatibility matrix**: https://unfoldadmin.com/docs/installation/#compatibility

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
