# Components and Actions Deep Dive

This file is loaded on demand from ../SKILL.md for detailed component usage, fields, filters, actions, and tabs.

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

### @display Decorator (Django 6.0+)

```python
from unfold.decorators import display

class UserAdmin(ModelAdmin):
    @display(description="Status", boolean=True)
    def is_active(self, obj):
        return obj.is_active
    
    @display(description="Actions", order="username")
    def user_actions(self, obj):
        return f"{obj.first_name} {obj.last_name}"
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