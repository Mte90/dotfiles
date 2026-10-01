# CSP Nonce Integration

**Loaded on demand from `django-htmx/SKILL.md` when you need Content-Security-Policy configuration.**

## The Problem

With a strict Content-Security-Policy, htmx's inline script (from `{% htmx_script %}`) is blocked:

```
Content-Security-Policy: script-src 'nonce-abc123'
```

Without a nonce, the browser refuses to execute the htmx bootstrap script. Symptom: htmx attributes (`hx-get`, `hx-trigger`) are ignored, elements don't respond to interactions.

## Solution: django-csp Package

Install and configure `django-csp`:

```bash
pip install django-csp
```

```python
# settings.py
INSTALLED_APPS = [
    ...
    "csp",
]

MIDDLEWARE = [
    "csp.middleware.CSPMiddleware",  # Place early
    ...
]

CSP_DEFAULT_SRC = ("'self'",)
CSP_SCRIPT_SRC = ("'self'", "'nonce-{random}'")  # Nonce required
```

## Template Integration

Django 6.0+ includes nonce support in the `htmx_script` template tag:

```django
{% load django_htmx %}
<!DOCTYPE html>
<html>
<head>
    {% htmx_script %}  {# Automatically adds nonce attribute #}
</head>
<body>
    ...
</body>
</html>
```

The tag reads `request.csp_nonce` (set by `CSPMiddleware`) and adds it to the `<script>` tag.

## Manual Nonce (Older Django)

If using Django < 6.0, pass the nonce manually:

```django
{% load django_htmx %}
<!DOCTYPE html>
<html>
<head>
    <script nonce="{{ request.csp_nonce }}">
        // htmx source inline or load from static
    </script>
</head>
...
```

Or use `django-csp`'s `{% csp_nonce %}` tag:

```django
{% load csp_tags %}
<script nonce="{% csp_nonce %}">
    // htmx code
</script>
```

## Debugging CSP Issues

**Symptom**: htmx doesn't work, no JavaScript errors visible.

**Check browser console**: CSP violations are logged there.

**Check response header**:

```python
def debug_csp(request):
    return HttpResponse(request.META.get("HTTP_CSP_REPORT_ONLY", "Not set"))
```

**Verify nonce is present**:

```python
response = self.client.get("/")
self.assertIn(b"nonce-", response.content)
```

## Alternative: Hash-Based Policy

Instead of nonces, you can use hashes (less flexible):

```python
CSP_SCRIPT_SRC = ("'self'", "'sha256-<base64-hash-of-htmx-script>'")
```

Calculate the hash of the exact htmx script content. This is brittle when htmx version changes.

## References

- **django-csp documentation**: https://github.com/mozilla/django-csp
- **CSP Level 3 spec**: https://www.w3.org/TR/CSP3/
