# Settings Customization Deep Dive

This file is loaded on demand from ../SKILL.md for detailed settings, admin site customization, dark mode, and styling configuration.

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