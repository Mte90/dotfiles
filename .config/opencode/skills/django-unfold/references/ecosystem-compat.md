# Ecosystem and Compatibility Deep Dive

This file is loaded on demand from ../SKILL.md for ecosystem libraries and Django version compatibility notes.

## Ecosystem Libraries

### django-unfold-modal
- **URL**: https://github.com/metaforx/django-unfold-modal
- **PyPI**: `django-unfold-modal`
- **Version**: 0.2.1 (requires Python 3.10+, Django 5.0+, django-unfold 0.52.0+)

Replaces Django admin's popup windows for related objects (ForeignKey, ManyToMany, etc.) with Unfold-styled modals, so related-object selection happens in-page instead of in separate browser windows.

**Key features:**
- Modal replacement for admin related-object popups (ForeignKey/ManyToMany/OneToOne selects, `raw_id_fields` lookup, `autocomplete_fields`/Select2, related fields inside inlines)
- Nested modals with replace/restore behavior
- Size presets (`default`/`large`/`full`) and optional manual resize handle
- Optional admin header suppression inside modal iframes
- Django CMS integration — admin modals can open in the CMS parent window when admin runs inside a CMS modal

```bash
pip install django-unfold-modal
```

### django-unfold-markdown
- **URL**: https://github.com/sergei-vasilev-dev/django-unfold-markdown
- **PyPI**: `django-unfold-markdown`
- **Version**: 0.1.2 (requires Python >=3.10, Django >=4.2, django-unfold >=0.70.0)

Markdown editor widget for the Django Unfold admin: a plain-text monospace editor with live preview that renders stored content as Markdown.

**Key features:**
- Plain text editor with monospace font (no rich-text WYSIWYG)
- Side-by-side live preview and fullscreen mode
- Dark/light theme integration with Unfold; Material Symbols icons matching Unfold design
- Toolbar: bold, italic, strikethrough, headings, lists, links, images, tables, horizontal rule
- No autosave — content saves on form submit
- Responsive layout; renders stored text with `markdown` or `mistune`

```bash
pip install django-unfold-markdown
```

### django-unfold-extra
- **URL**: https://github.com/metaforx/django-unfold-extra
- **PyPI**: `django-unfold-extra`
- **Version**: 0.4.0 (requires `django-unfold>=0.92`, `django-cms>=5.0,<5.1`, `django-parler~=2.3`)

Unofficial "extra" package that enhances the Django Unfold admin interface with Unfold-styled integrations for Django CMS 5.0, django-parler multilingual models, and django-versatileimagefield.

**Key features:**
- Django CMS 5.0 integration: Unfold-styled page tree with "New Page" button and language switcher, tabbed Page/PageContent change forms, `PageUser`/`PageUserGroup`/`GlobalPagePermission` admin with permission inlines, `djangocms-versioning` admin
- `UnfoldCMSPluginBase` with `UnfoldStackedInline`/`UnfoldTabularInline`; drop-in Unfold-styled `djangocms-link` Link plugin and `djangocms-alias` admin
- django-parler support: `UnfoldTranslatableAdminMixin`, `UnfoldTranslatableStackedAdminMixin`, `UnfoldTranslatableTabularAdminMixin`, translatable inlines
- django-versatileimagefield integration (preview + ppoi)
- Unfold auto-update of styles from the official package via npm; Theme-Sync to control themes from either the Unfold or CMS switcher

```bash
pip install django-unfold-extra
```

> **Note:** Used in production but the author notes to "expect additional implementation work"; recommended mainly when most CMS plugins are custom-built.

### django-admin-action-forms
- **URL**: https://github.com/michalpokusa/django-admin-action-forms
- **PyPI**: `django-admin-action-forms`
- **Version**: 3.0.0 (supports Django 3.2.x through 6.x.x; requires only `django>=3.2`)

Django admin extension that adds confirmation pages for admin actions: each action can have a custom form shown on an intermediate page before execution, with the form data passed to the action as an extra argument. Works with the stock Django admin (not Unfold-specific, but pairs well with Unfold's admin theming).

**Key features:**
- `@action_with_form` decorator + `ActionForm` base class; form data passed to the action as an additional argument
- Supports Django 3.2.x through 6.x.x; no additional dependencies
- Supports `fields`/`fieldsets`, `filter_horizontal`/`filter_vertical`, `autocomplete_fields`, custom widgets and validators
- Formset support via inlines (`StackedAdminActionInline`, `TabularAdminActionInline`)
- Easily testable with Django's built-in testing tools; compatible with `django-no-queryset-admin-actions`

```bash
pip install django-admin-action-forms
```
Add `'django_admin_action_forms'` to `INSTALLED_APPS`.

## Django 6.x `get_action_choices` Compatibility

`django-unfold` 0.105.0's `ModelAdmin.get_action_choices(self, request, default_choices=BLANK_CHOICE_DASH)` does not accept the `action_location` argument that Django 6.x requires, triggering a `DeprecationWarning` that fails the test suite when warnings are treated as errors.

Since this is an upstream bug, the fix is a monkey-patch in an `AppConfig.ready()` hook:

```python
# customers/apps.py
from django.apps import AppConfig

class CustomersConfig(AppConfig):
    name = "customers"

    def ready(self):
        from unfold.admin import ModelAdmin
        original = ModelAdmin.get_action_choices

        def patched(self, request, default_choices=None, action_location=None):
            return original(self, request, default_choices)

        ModelAdmin.get_action_choices = patched
```

This runs once at Django startup and silences the warning for the entire process. Remove the patch when `django-unfold` ships a version that accepts `action_location` natively.

## INSTALLED_APPS Ordering

`django-unfold` must appear in `INSTALLED_APPS` **before** `django.contrib.admin` so its templates and static files take precedence:

```python
INSTALLED_APPS = [
    # ...
    "unfold",            # before admin
    "django.contrib.admin",
    # ...
]
```

If the order is reversed, the admin renders with the default Django admin theme and Unfold's customizations are silently ignored.

## Admin URL Precedence and Action Payload

These patterns apply to Unfold and standard Django admin alike, but surface frequently when customizing Unfold views:

1. **Custom URLs before `super().get_urls()`** — A custom Unfold view like a voucher-creation wizard must be registered before the default changelist pattern, or `<path:object_id>/` swallows it.

2. **Action POST payload** — when triggering a custom action from an Unfold view via JavaScript, the payload must include `action` (the method name) and `_selected_action` (list of IDs). Swapping them silently no-ops the action.

3. **Redirects** — `UnfoldAdminSite` has no `urls_url` attribute. Use `django.urls.reverse()` to build redirect targets from custom Unfold views.

```python
from django.urls import reverse
return redirect(reverse("admin:customers_customer_changelist"))
```