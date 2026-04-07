---
name: django-unfold
description: "Modern Django admin theme - Unfold - customization, settings, components, actions, filters, integrations"
metadata:
  author: OSS AI Skills
  version: 1.0.0
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

## Settings Reference

### Site Branding

```python
UNFOLD = {
    'SITE_HEADER': 'My Company Admin',
    'SITE_TITLE': 'My Admin',
    'INDEX_TITLE': 'Welcome to Dashboard',
    
    # Or with HTML support
    'SITE_HEADER': '<div class="flex items-center gap-2"><span>🚀</span> My Company</div>',
}
```

### Colors and Theme

```python
UNFOLD = {
    'COLORS': {
        'primary': {
            '50': '239 246 255',
            '100': '219 234 254',
            '200': '191 219 254',
            '300': '147 197 253',
            '400': '96 165 250',
            '500': '59 130 246',
            '600': '37 99 235',
            '700': '29 78 216',
            '800': '30 64 175',
            '900': '30 58 138',
            '950': '30 58 138',
        },
    },
    
    'DARK_MODE_COLORS': {
        'primary': {
            '50': '239 246 255',
            # ... dark mode colors
        },
    },
}
```

### Sidebar Navigation

```python
UNFOLD = {
    'SIDEBAR': {
        'show_search': True,
        'navigation': [
            {
                'title': 'Main',
                'items': [
                    {'title': 'Dashboard', 'icon': 'dashboard', 'link': '/admin/'},
                    {'title': 'Users', 'icon': 'people', 'link': '/admin/auth/user/'},
                ],
            },
            {
                'title': 'Content',
                'items': [
                    {'title': 'Articles', 'icon': 'article', 'link': '/admin/myapp/article/'},
                ],
            },
        ],
    },
}
```

### Dashboard Widgets

```python
UNFOLD = {
    'DASHBOARD_WIDGETS': [
        'unfold.widgets.DashboardStatistics',
        'unfold.widgets.DashboardActions',
        # Custom widgets
    ],
}
```

### Feature Flags

```python
UNFOLD = {
    # Show/hide features
    'SHOW_HISTORY': True,
    'SHOW_VIEW_ON_SITE': True,
    
    # Disable specific features
    'AUTH_PASSWORD_VALIDATION': True,
}
```

---

## Custom Admin Site

### Custom Site Class

```python
# admin.py
from unfold.admin import ModelAdmin, UnfoldAdminSite
from django.contrib.admin import AdminSite

class CustomAdminSite(UnfoldAdminSite):
    site_header = 'My Custom Admin'
    site_title = 'My Admin Panel'
    index_title = 'Welcome to Management'
    
    def each_context(self, request):
        context = super().each_context(request)
        # Add custom context
        context['custom_data'] = 'value'
        return context

admin_site = CustomAdminSite(name='myadmin')
```

```python
# settings.py
UNFOLD_ADMIN_SITE_CLASS = 'myapp.admin.CustomAdminSite'
```

### Custom ModelAdmin

```python
# admin.py
from django.contrib import admin
from unfold.admin import ModelAdmin
from .models import Article

@admin.register(Article, site=custom_admin_site)
class ArticleAdmin(ModelAdmin):
    list_display = ['title', 'status', 'created_at']
    search_fields = ['title', 'content']
    list_filter = ['status', 'created_at']
    
    # Unfold-specific
    sidebar_fieldsets = (
        (None, {'fields': ('title', 'slug')}),
        ('Content', {'fields': ('content', 'excerpt')}),
    )
```

---

## Components

### Buttons

```python
from unfold.decorators import action
from unfold.actions import Actions

class ArticleAdmin(ModelAdmin):
    @action(description='Publish selected')
    def make_published(self, request, queryset):
        queryset.update(status='published')
    
    @action(description='Export to CSV')
    def export_csv(self, request, queryset):
        # Export logic
        pass
```

### Cards

```python
# In change_view.html or custom template
{% load unfold %}

{% component "card" title="Statistics" %}
    <div class="p-4">
        <p class="text-2xl font-bold">1,234</p>
        <p class="text-gray-500">Total Users</p>
    </div>
{% endcomponent %}
```

### Charts

```python
# Using Unfold chart component
{% component "chart" type="line" data=chart_data %}
{% endcomponent %}
```

### Tables

```python
# In list_display
class UserAdmin(ModelAdmin):
    list_display = ['username', 'email', 'status_badge']
    
    @bind_to(admin_order_field='is_active')
    def status_badge(self, obj):
        from unfold.helpers import icon
        if obj.is_active:
            return icon('check_circle', classes='text-green-500')
        return icon('x_circle', classes='text-red-500')
```

---

## Fields and Widgets

### Autocomplete Fields

```python
from unfold import fields
from unfold.forms import ModelForm

class ArticleForm(ModelForm):
    class Meta:
        model = Article
        fields = '__all__'
    
    author = fields.AutocompleteField(
        queryset=User.objects.all(),
        search_fields=['username', 'email'],
        label='Author'
    )
```

### JSON Fields

```python
from unfold.fields import JSONField

class ConfigAdmin(ModelAdmin):
    fieldsets = (
        (None, {
            'fields': ('config_json',)
        }),
    )
    
    def get_form(self, request, obj=None, **kwargs):
        form = super().get_form(request, obj, **kwargs)
        form.base_fields['config_json'] = fields.JSONField(
            widget=forms.Textarea(attrs={
                'class': 'font-mono text-sm',
                'rows': 10
            })
        )
        return form
```

---

## Filters

### Custom Filters

```python
import unfold.filters as filters

class ArticleAdmin(ModelAdmin):
    list_filter = [
        ('status', filters.DropdownFilter),
        ('category', filters.DropdownFilter),
        ('created_at', filters.DateRangeFilter),
        ('author', filters.AutocompleteFilter),
    ]
```

### Filter Types

```python
# Dropdown filter
('status', filters.DropdownFilter)

# Date range filter
('created_at', filters.DateRangeFilter)

# Autocomplete filter (for FK/M2M with many items)
('author', filters.AutocompleteFilter)

# Checkbox/radio filter
('is_published', filters.CheckboxFilter)

# Numeric range filter
('views', filters.NumericFilter)

# Text search filter
('title', filters.TextFilter)
```

---

## Actions

### Custom Actions

```python
from django.http import HttpResponse
from django.shortcuts import render
import csv
import io

class ArticleAdmin(ModelAdmin):
    @action(description='Export selected to CSV')
    def export_csv(self, request, queryset):
        # Create CSV
        buffer = io.StringIO()
        writer = csv.writer(buffer)
        writer.writerow(['Title', 'Status', 'Created'])
        
        for obj in queryset:
            writer.writerow([obj.title, obj.status, obj.created])
        
        # Return response
        response = HttpResponse(buffer.getvalue(), content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="articles.csv"'
        return response
    
    @action(description='Send to publication')
    def publish(self, request, queryset):
        queryset.update(status='published', published_at=timezone.now())
    publish.short_description = 'Publish selected articles'
```

### Row Actions

```python
class ArticleAdmin(ModelAdmin):
    def get_row_actions(self, obj):
        actions = super().get_row_actions(obj)
        actions.append(
            actions.Link(
                'preview',
                icon='visibility',
                link=f'/admin/myapp/article/{obj.pk}/preview/'
            )
        )
        return actions
```

---

## Tabs

### Using Tabs

```python
class ArticleAdmin(ModelAdmin):
    tabs = [
        {'title': 'Content', 'id': 'content'},
        {'title': 'SEO', 'id': 'seo'},
        {'title': 'Metadata', 'id': 'metadata'},
    ]
    
    fieldsets = (
        (None, {
            'fields': ('title', 'content'),
            'tab_id': 'content',
        }),
        ('SEO Settings', {
            'fields': ('meta_title', 'meta_description'),
            'tab_id': 'seo',
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'tab_id': 'metadata',
        }),
    )
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

## Dark Mode

### Automatic Dark Mode

Unfold automatically supports dark mode based on system preference.

### Manual Control

```python
# Force dark mode
UNFOLD = {
    'THEME': 'dark',  # 'dark' or 'light' or None (auto)
}
```

### Custom Colors for Dark Mode

```python
UNFOLD = {
    'DARK_MODE_COLORS': {
        'primary': {
            '50': '224 242 254',
            '100': '214 238 253',
            # ... custom dark mode colors
        },
    },
}
```

---

## Custom Styling

### Custom CSS

```python
# settings.py
UNFOLD = {
    'STYLES': [
        'css/custom.css',
    ],
}

# templates/admin/base.html
{% extends "admin/base.html" %}
{% load static %}

{% block extrastyle %}
<link rel="stylesheet" href="{% static 'css/custom.css' %}">
{% endblock %}
```

### Custom JavaScript

```python
UNFOLD = {
    'SCRIPTS': [
        'js/custom.js',
    ],
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

## References

- **GitHub**: https://github.com/unfoldadmin/django-unfold
- **Documentation**: https://unfoldadmin.com/docs
- **Demo**: https://unfoldadmin.com/