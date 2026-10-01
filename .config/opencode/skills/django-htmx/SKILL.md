---
name: django-htmx
description: Use when building dynamic Django web apps with htmx - partial rendering, HTMX responses, querystring tag, CSP
metadata:
  author: mte90
  version: 1.0.1
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

**Versions**: django-htmx 1.16.0 + Django 6.0 fully compatible. Python 3.10 → 3.14 supported.

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

Add the middleware (order matters - after SessionMiddleware, before AuthenticationMiddleware):

```python
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django_htmx.middleware.HtmxMiddleware",  # Required for request.htmx
    "django.contrib.messages.middleware.MessageMiddleware",
    ...
]
```

## Setup

### Base Template

Load the template tag and include the htmx script once in your base template:

```django
{% load django_htmx %}
<!DOCTYPE html>
<html>
<head>
    {% htmx_script %}
</head>
<body hx-headers='{"x-csrftoken": "{{ csrf_token }}"}'>
    {% block content %}{% endblock %}
</body>
</html>
```

The `hx-headers` attribute on `<body>` ensures all htmx requests carry the CSRF token. Without this, POST/PUT/DELETE requests fail with 403.

For debugging, use the unminified version:

```django
{% htmx_script minified=False %}
```

### Jinja2 Configuration

If using Jinja2 templates, configure the global:

```python
# settings.py or jinja2 config
from django_htmx.jinja import htmx_script

def environment(**options):
    from jinja2 import Environment
    env = Environment(**options)
    env.globals.update({"htmx_script": htmx_script})
    return env
```

Then in templates: `{{ htmx_script() }}`

**See**: `references/csp-nonce.md` for Content-Security-Policy integration.

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

The `request.htmx` object provides:

- `request.htmx` - Boolean, True if request is from htmx
- `request.htmx.boosted` - True if from boosted element (hx-boost)
- `request.htmx.current_url` - Current URL from HX-Current-URL header
- `request.htmx.current_url_abs_path` - Absolute path form of current_url
- `request.htmx.history_restore_request` - True for history restoration
- `request.htmx.target` - Target element ID from HX-Target header
- `request.htmx.trigger` - Trigger element ID from HX-Trigger header
- `request.htmx.trigger_name` - Trigger element name from HX-Trigger-Name header
- `request.htmx.prompt` - User response to hx-prompt attribute
- `request.htmx.triggering_event` - Deserialized JSON from event-header extension

## HTTP Response Classes (Decision Guide)

Choose the right response type based on what should happen on the client:

| Response Type | When to Use | What Breaks If Wrong |
|---------------|-------------|---------------------|
| `HttpResponse` (normal) | Full page reload needed, or swapping entire document | Using htmx-specific responses here causes no-op or unexpected behavior |
| `HttpResponseClientRedirect` | Navigate to different URL without full reload | Using plain `HttpResponseRedirect` leaves stale DOM; user sees old content |
| `HttpResponseClientRefresh` | Force full page reload (stale session, permission change) | Using redirect instead loses form data; using `HttpResponse` doesn't refresh |
| `HttpResponseLocation` | "Boosted" navigation to new URL | Using redirect causes full reload; using `HttpResponse` shows wrong URL |
| `HttpResponseStopPolling` | End polling loop (event finished, error unrecoverable) | Omitting this keeps polling, wasting resources |
| Plain `HttpResponse` + `HX-Trigger` | Update fragment and trigger client event | Without trigger, client doesn't know to update related UI (e.g., badge count) |
| Plain `HttpResponse` + `HX-Redirect` header | Client-side redirect from server logic | Using `HttpResponseClientRedirect` directly is cleaner; manual header is for custom logic |

### HttpResponseClientRedirect

Use for navigation that should update browser history without full reload:

```python
from django_htmx.http import HttpResponseClientRedirect

def sensitive_view(request):
    if not sudo_mode.active(request):
        return HttpResponseClientRedirect("/activate-sudo/")
    ...
```

**What breaks**: A plain `HttpResponseRedirect` causes htmx to follow the redirect as a normal request, which may swap the wrong fragment or leave the original DOM intact.

### HttpResponseClientRefresh

Force a full page reload:

```python
from django_htmx.http import HttpResponseClientRefresh

def partial_table_view(request):
    if page_outdated(request):
        return HttpResponseClientRefresh()
    ...
```

**What breaks**: Without this, the client keeps showing stale data. Use when session expired, permissions changed, or cache invalidation occurred.

### HttpResponseLocation

Trigger client-side "boosted" navigation (hx-boost behavior):

```python
from django_htmx.http import HttpResponseLocation

def wait_for_completion(request, action_id):
    ...
    if action.completed:
        return HttpResponseLocation(f"/action/{action.id}/completed/")
    ...
```

**What breaks**: Using a redirect causes a full page reload, losing the htmx benefits.

### HttpResponseStopPolling

End a polling loop:

```python
from django_htmx.http import HttpResponseStopPolling

def my_pollable_view(request):
    if event_finished():
        return HttpResponseStopPolling()
    return render(request, "status.html", {"status": "running"})
```

Or use the constant with `render()`:

```python
from django_htmx.http import HTMX_STOP_POLLING

def my_pollable_view(request):
    if event_finished():
        return render(request, "event-finished.html", status=HTMX_STOP_POLLING)
```

## Response Modifying Functions

These wrap an `HttpResponse` to add htmx-specific headers:

### push_url / replace_url

Update browser history without navigation:

```python
from django_htmx.http import push_url

def leaf_select(request, leaf_id):
    ...
    response = render(request, "leaf-detail.html", {"leaf": leaf})
    return push_url(response, f"/leaf/{leaf.id}")
```

Use `replace_url()` to replace current history entry instead of pushing.

### reswap / retarget / reselect

Override htmx behavior server-side:

```python
from django_htmx.http import reswap, retarget, reselect

def conditional_swap(request):
    response = render(request, "row.html", {"row": row})
    if row.is_special:
        reswap(response, "afterbegin")  # Override hx-swap
        retarget(response, "#special-container")  # Override hx-target
    return reselect(response, ".data-row")  # Override CSS selector
```

### trigger_client_event

Trigger custom JavaScript events after swap:

```python
from django_htmx.http import trigger_client_event

def end_of_process(request):
    response = render(request, "done.html")
    return trigger_client_event(
        response,
        "showConfetti",
        {"colours": ["purple", "red", "pink"]},
        after="swap",  # "receive", "settle", or "swap"
    )
```

The event name (`showConfetti`) must match a handler registered via `htmx.on()`.

## Template Tags

### querystring Filter (Django 4.1+)

Rebuild query strings for filter/pagination links:

```django
{% load django_htmx %}

<!-- Keep all filters, flip `outdoors` off -->
<a hx-get="{% querystring outdoors=None %}" hx-target="#list"
   hx-push-url="true">hide outdoors</a>

<!-- Paginate -->
<a hx-get="{% querystring page=page.next %}" hx-target="#list">next</a>
```

### json_script

Embed Python data for client-side use:

```django
{{ row.config|json_script:"row-config" }}
<script>
  const cfg = JSON.parse(document.getElementById('row-config').textContent);
  htmx.trigger('#row', 'config-ready', cfg);
</script>
```

## Best Practices

### Partial Rendering with Template Partials

Use `django-template-partials` for efficient fragment rendering:

```bash
pip install django-template-partials
```

```django
{% extends "_base.html" %}
{% load partials %}

{% block main %}
  {% partialdef country-table inline %}
    <table id="country-data">
      {% for country in countries %}
        <tr><td>{{ country.name }}</td></tr>
      {% endfor %}
    </table>
  {% endpartialdef %}
{% endblock main %}
```

```python
def country_listing(request):
    template = "countries.html"
    if request.htmx:
        template += "#country-table"  # Render partial only
    return render(request, template, {"countries": Country.objects.all()})
```

### Caching

Keep the cached template loader enabled (it's default, but easy to break):

```python
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

Without it, Django recompiles templates on every request, dominating CPU for htmx partials.

**Diagnosis**: If `py-spy` shows `django.template.base.compile` at the top, the cache is off.

### Vary Headers

Tell caches that content differs by htmx request:

```python
from django.views.decorators.cache import cache_control
from django.views.decorators.vary import vary_on_headers

@cache_control(max_age=300)
@vary_on_headers("HX-Request")
def my_view(request):
    ...
```

## Anti-Patterns

### 1. Business Logic in Template Fragments

**Wrong**: A partial that needs data the parent page didn't load.

```django
<!-- BAD: template tries to access data not in context -->
{% partialdef user-stats %}
  {{ user.profile.score }}  {# user not passed to partial #}
{% endpartialdef %}
```

**Fix**: Ensure the view serving the fragment has all required context.

### 2. Returning JSON to hx-get

**Wrong**: htmx expects HTML by default.

```python
# BAD: htmx silently ignores JSON responses
def data_view(request):
    return JsonResponse({"data": items})
```

**Symptom**: No error, but nothing updates in the DOM.

**Fix**: Return HTML fragments, or use `hx-trigger` with JavaScript to handle JSON.

### 3. Missing hx-swap-oob for Out-of-Band Updates

**Wrong**: Updating a badge without telling htmx where to put it.

```python
# BAD: client doesn't know to update badge
return render(request, "order-status.html", {"status": "shipped"})
```

**Fix**: Use `hx-swap-oob` to update multiple fragments:

```django
<!-- In the fragment response -->
<span id="badge" hx-swap-oob="true">{{ new_count }}</span>
```

### 4. Expensive Polling with every="1s"

**Wrong**: Self-inflicted load generator.

```django
<div hx-get="/status" hx-trigger="every 1s">...</div>
```

**Fix**: Use longer intervals, or WebSockets for real-time:

```django
<div hx-get="/status" hx-trigger="every 5s">...</div>
```

Or load the `ws` extension for push-based updates.

### 5. Missing CSRF Token

**Wrong**: POST requests fail with 403.

```django
<!-- BAD: no CSRF token -->
<body>
  <form hx-post="/submit">...</form>
</body>
```

**Symptom**: 403 errors that look like template bugs.

**Fix**: Include token in `hx-headers` on `<body>` (see Setup section) or per-form:

```django
<form hx-post="/submit" hx-headers='{"x-csrftoken": "{{ csrf_token }}"}'>
```

### 6. Forgetting HX-Redirect for Client-Side Redirects

**Wrong**: Using Django's `HttpResponseRedirect` in htmx context.

```python
# BAD: causes full page reload
return HttpResponseRedirect("/done/")
```

**Fix**: Use `HttpResponseClientRedirect` for htmx-aware redirects.

## Testing

### What You Can Test Server-Side

**Fragment content**:

```python
from django.test import TestCase

class HtmxTests(TestCase):
    def test_fragment_content(self):
        response = self.client.get(
            "/partial/",
            HTTP_HX_REQUEST="true",  # Sets HX-Request header
        )
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Expected fragment content")
```

**HX-Response headers**:

```python
def test_redirect_header(self):
    response = self.client.post("/sensitive-action/")
    self.assertEqual(response["HX-Redirect"], "/activate-sudo/")
```

**Out-of-band swaps**:

```python
def test_oob_swap(self):
    response = self.client.post("/update-badge/")
    # Check the response contains hx-swap-oob attribute
    self.assertIn(b'hx-swap-oob="true"', response.content)
```

**CSRF handling**:

```python
def test_csrf_required(self):
    response = self.client.post("/action/", HTTP_HX_REQUEST="true")
    self.assertEqual(response.status_code, 403)  # No CSRF token

    response = self.client.post(
        "/action/",
        HTTP_HX_REQUEST="true",
        HTTP_X_CSRFTOKEN=self.client.cookies["csrftoken"].value,
    )
    self.assertEqual(response.status_code, 200)
```

### What You Cannot Test Server-Side

- **Actual DOM swaps**: Django tests don't render HTML in the browser
- **hx-trigger timing**: Polling intervals, debouncing
- **Client-side event handlers**: `htmx.on()` handlers triggered by `HX-Trigger`
- **hx-swap behavior**: How content is actually inserted (use Playwright/Cypress for this)

**For client-side behavior**: Use end-to-end tests with Playwright or Cypress.

## Type Checking

Extend `HttpRequest` for type hints:

```python
from django.http import HttpRequest as HttpRequestBase
from django_htmx.middleware import HtmxDetails

class HttpRequest(HttpRequestBase):
    htmx: HtmxDetails
```

## Deep Dives

Load these reference files for detailed guidance:

- `references/csp-nonce.md` - Content-Security-Policy nonce integration (when strict CSP breaks htmx)
- `references/testing-patterns.md` - Extended testing strategies and e2e setup

## References

- **Official Documentation**: https://django-htmx.readthedocs.io/
- **GitHub Repository**: https://github.com/adamchainz/django-htmx
- **htmx Reference**: https://htmx.org/reference/
- **jvns.ca – More nice Django things**: https://jvns.ca/blog/2026/07/21/more-nice-django-things/
