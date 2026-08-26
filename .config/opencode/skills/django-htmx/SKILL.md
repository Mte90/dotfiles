---
name: django-htmx
description: "Build modern dynamic web applications with Django and htmx - partial rendering, HTMX-specific responses, and seamless frontend integration"
metadata:
  author: mte90
  version: 1.0.0
  tags:
    - django
    - htmx
    - python
    - web
    - frontend
    - partial-rendering
    - ajax
---

# Django HTMX

Django-htmx provides seamless integration between Django and htmx for building modern, dynamic web applications without writing complex JavaScript.

## Installation

```bash
pip install django-htmx
```

Add to `INSTALLED_APPS`:

```python
INSTALLED_APPS = [
    ...
    "django_htmx",
]
```

Add the middleware:

```python
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django_htmx.middleware.HtmxMiddleware",  # Add this
    ...
]
```

## Core Concepts

### Request Detection

The middleware adds `request.htmx` to detect htmx requests:

```python
from django.shortcuts import render

def my_view(request):
    if request.htmx:
        template_name = "partial.html"
    else:
        template_name = "full.html"
    return render(request, template_name)
```

### HtmxDetails Attributes

The `request.htmx` object provides these attributes:

- `request.htmx` - Boolean, True if request is from htmx
- `request.htmx.boosted` - True if request is from boosted element (hx-boost)
- `request.htmx.current_url` - Current URL in browser from HX-Current-URL header
- `request.htmx.current_url_abs_path` - Absolute path form of current_url
- `request.htmx.history_restore_request` - True if request is for history restoration
- `request.htmx.target` - Target element ID from HX-Target header
- `request.htmx.trigger` - Trigger element ID from HX-Trigger header
- `request.htmx.trigger_name` - Trigger element name from HX-Trigger-Name header
- `request.htmx.prompt` - User response to hx-prompt attribute
- `request.htmx.triggering_event` - Deserialized JSON from event-header extension

## Template Tags

Load and use in templates:

```django
{% load django_htmx %}
<!DOCTYPE html>
<html>
<head>
    {% htmx_script %}
</head>
<body hx-headers='{"x-csrftoken": "{{ csrf_token }}"}'>
    ...
</body>
</html>
```

### Django Templates

```django
{% load django_htmx %}
<!doctype html>
<html>
  <head>
    {% htmx_script %}
  </head>
  <body hx-headers='{"x-csrftoken": "{{ csrf_token }}"}'>
    ...
  </body>
</html>
```

Use `minified=False` for debugging:

```django
{% htmx_script minified=False %}
```

### Jinja2

```python
from jinja2 import Environment
from django_htmx.jinja import htmx_script

def environment(**options):
    env = Environment(**options)
    env.globals.update({"htmx_script": htmx_script})
    return env
```

```html
{{ htmx_script() }}
```

### Built-in Filters Useful with HTMX

`{% querystring %}` (Django 4.1+) rebuilds the current query string with one
key changed — ideal for htmx filter links that re-render a list partial:

```django
{% load django_htmx %}

<!-- keep all current filters, flip `outdoors` off -->
<a hx-get="{% querystring outdoors=None %}" hx-target="#list"
   hx-push-url="true">hide outdoors</a>

<!-- paginate by changing only `page` -->
<a hx-get="{% querystring page=page.next %}" hx-target="#list">next</a>
```

`json_script` safely embeds a Python dict as a `<script>` tag, useful for
seeding htmx-driven widgets with initial state:

```django
{{ row.config|json_script:"row-config" }}
<script>
  const cfg = JSON.parse(document.getElementById('row-config').textContent);
  htmx.trigger('#row', 'config-ready', cfg);
</script>
```

Other high-signal built-ins: `urlize`, `linebreaksbr`, `date:"M j"`.

## HTTP Response Classes

### HttpResponseClientRedirect

Triggers a client-side redirect (HX-Redirect header):

```python
from django_htmx.http import HttpResponseClientRedirect

def sensitive_view(request):
    if not sudo_mode.active(request):
        next_url = request.htmx.current_url_abs_path or ""
        return HttpResponseClientRedirect(f"/activate-sudo/?next={next_url}")
    ...
```

### HttpResponseClientRefresh

Triggers a page reload (HX-Refresh header):

```python
from django_htmx.http import HttpResponseClientRefresh

def partial_table_view(request):
    if page_outdated(request):
        return HttpResponseClientRefresh()
    ...
```

### HttpResponseLocation

Makes htmx do a client-side "boosted" request (HX-Location header):

```python
from django_htmx.http import HttpResponseLocation

def wait_for_completion(request, action_id):
    ...
    if action.completed:
        return HttpResponseLocation(f"/action/{action.id}/completed/")
    ...
```

### HttpResponseStopPolling

Stops polling when using hx-trigger="every":

```python
from django_htmx.http import HttpResponseStopPolling

def my_pollable_view(request):
    if event_finished():
        return HttpResponseStopPolling()
    ...
```

Or use the constant directly:

```python
from django_htmx.http import HTMX_STOP_POLLING
from django.shortcuts import render

def my_pollable_view(request):
    if event_finished():
        return render(request, "event-finished.html", status=HTMX_STOP_POLLING)
    ...
```

## Response Modifying Functions

### push_url

Push a new URL to the browser history:

```python
from django_htmx.http import push_url

def leaf(request, leaf_id):
    ...
    if leaf is None:
        response = branch(request, branch=leaf.branch)
        return push_url(response, f"/branch/{leaf.branch.id}")
    ...
```

### replace_url

Replace the current URL in browser history:

```python
from django_htmx.http import replace_url

def dashboard(request):
    ...
    response = render(request, "dashboard.html", ...)
    return replace_url(response, "/dashboard/")
```

### reswap

Override the swap method:

```python
from django.shortcuts import render
from django_htmx.http import reswap

def employee_table_row(request):
    ...
    response = render(...)
    if employee.is_boss:
        reswap(response, "afterbegin")
    return response
```

### retarget

Override the target element:

```python
from django.shortcuts import render
from django.views.decorators.http import require_POST
from django_htmx.http import retarget

@require_POST
def add_widget(request):
    ...
    if form.is_valid():
        response = render(request, "widget-table.html", ...)
        return retarget(response, "#widgets")
    return render(request, "widget-table-row.html", ...)
```

### reselect

Override the content selection:

```python
from django_htmx.http import reselect

def update_table(request):
    response = render(request, "table.html", ...)
    return reselect(response, "tbody")
```

### trigger_client_event

Trigger client-side events:

```python
from django.shortcuts import render
from django_htmx.http import trigger_client_event

def end_of_long_process(request):
    response = render(request, "end-of-long-process.html")
    return trigger_client_event(
        response,
        "showConfetti",
        {"colours": ["purple", "red", "pink"]},
        after="swap",  # "receive", "settle", or "swap"
    )
```

## Best Practices

### Partial Rendering

Use django-template-partials for efficient partial rendering:

```bash
pip install django-template-partials
```

```django
{% extends "_base.html" %}
{% load partials %}

{% block main %}
  {% partialdef country-table inline %}
    <table id="country-data">
      ...
    </table>
  {% endpartialdef %}
{% endblock main %}
```

In views:

```python
def country_listing(request):
    template_name = "countries.html"
    if request.htmx:
        template_name += "#country-table"

    countries = Country.objects.all()
    return render(request, template_name, {"countries": countries})
```

### Swapping Base Template

```python
def partial_rendering(request):
    if request.htmx:
        base_template = "_partial.html"
    else:
        base_template = "_base.html"

    return render(request, "page.html", {"base_template": base_template})
```

```django
{% extends base_template %}
{% block main %}
  ...
{% endblock %}
```

### CSRF Protection

Always include CSRF token in htmx requests:

```html
<body hx-headers='{"x-csrftoken": "{{ csrf_token }}"}'>
```

### Caching with HTMX

Keep the **cached template loader** on (`django.template.loaders.cached.Loader`).
It is on by default, but it is easy to disable by accident while tweaking
`TEMPLATES` — without it Django recompiles every template on every render, which
 dominates CPU for server-rendered htmx partials.

```python
# settings.py — the safe shape. Wrap app_dirs in cached.Loader.
TEMPLATES = [{
    "BACKEND": "django.template.backends.django.DjangoTemplates",
    "DIRS": [BASE_DIR / "templates"],
    "OPTIONS": {
        "loaders": [
            ("django.template.loaders.cached.Loader", [
                "django.template.loaders.app_directories.Loader",
                "django.template.loaders.filesystem.Loader",
            ]),
        ],
    },
}]
```

If a CPU profile (`py-spy record -o profile.svg --pid <django_pid>`) shows
`django.template.base.compile` near the top, the cached loader is off.

Add appropriate Vary headers for cacheable responses:

```python
from django.shortcuts import render
from django.views.decorators.cache import cache_control
from django.views.decorators.vary import vary_on_headers

@cache_control(max_age=300)
@vary_on_headers("HX-Request")
def my_view(request):
    if request.htmx:
        template_name = "partial.html"
    else:
        template_name = "complete.html"
    return render(request, template_name, ...)
```

### HTMX Extensions

Download extensions locally (avoid CDNs):

```bash
curl -L https://unpkg.com/htmx-ext-ws/dist/ws.min.js -o static/htmx-ext-ws.min.js
```

```django
{% load django_htmx static %}
<!doctype html>
<html>
  <head>
    {% htmx_script %}
    <script src="{% static 'htmx-ext-ws.min.js' %}" defer></script>
  </head>
  ...
</html>
```

## Type Checking

For type-checking, extend HttpRequest:

```python
from django.http import HttpRequest as HttpRequestBase
from django_htmx.middleware import HtmxDetails

class HttpRequest(HttpRequestBase):
    htmx: HtmxDetails
```

## References

- **Official Documentation**: https://django-htmx.readthedocs.io/
- **GitHub Repository**: https://github.com/adamchainz/django-htmx
- **htmx Reference**: https://htmx.org/reference/
- **jvns.ca – More nice Django things**: https://jvns.ca/blog/2026/07/21/more-nice-django-things/
- **HN discussion**: https://news.ycombinator.com/item?id=48997828