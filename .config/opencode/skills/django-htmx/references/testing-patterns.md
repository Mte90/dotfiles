# Testing Patterns for Django + htmx

**Loaded on demand from `django-htmx/SKILL.md` when you need extended testing strategies.**

## Server-Side Testing (Django Test Client)

### Basic Fragment Testing

Assert that htmx fragments render correctly:

```python
from django.test import TestCase, Client

class HtmxFragmentTests(TestCase):
    def setUp(self):
        self.client = Client()
        self.user = User.objects.create_user("test", "test@example.com", "pass")
        self.client.login(username="test", password="pass")

    def test_table_row_fragment(self):
        response = self.client.get(
            "/users/123/row/",
            HTTP_HX_REQUEST="true",  # Simulates htmx request
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response["Content-Type"], "text/html; charset=utf-8")
        self.assertContains(response, '<tr id="user-123"')
        self.assertContains(response, "test@example.com")
```

### Testing HX-Response Headers

Verify htmx-specific headers:

```python
def test_redirect_header(self):
    response = self.client.post(
        "/sensitive-action/",
        HTTP_HX_REQUEST="true",
    )
    self.assertEqual(response["HX-Redirect"], "/activate-sudo/")

def test_stop_polling(self):
    response = self.client.get(
        "/polling/event/42/",
        HTTP_HX_REQUEST="true",
    )
    self.assertEqual(response.status_code, 286)  # HTMX_STOP_POLLING status
```

### Testing Out-of-Band Swaps

```python
def test_oob_badge_update(self):
    response = self.client.post(
        "/orders/123/ship/",
        HTTP_HX_REQUEST="true",
    )
    # Check OOB swap element exists in response
    self.assertIn(b'id="order-count" hx-swap-oob="true"', response.content)
    self.assertContains(response, "5")  # New count
```

### Testing CSRF Protection

```python
def test_csrf_token_required(self):
    # Without CSRF token - should fail
    response = self.client.post(
        "/action/",
        HTTP_HX_REQUEST="true",
    )
    self.assertEqual(response.status_code, 403)

    # With CSRF token - should succeed
    csrf_token = self.client.cookies["csrftoken"].value
    response = self.client.post(
        "/action/",
        HTTP_HX_REQUEST="true",
        HTTP_X_CSRFTOKEN=csrf_token,
    )
    self.assertEqual(response.status_code, 200)
```

### Testing Conditional Rendering

```python
def test_full_vs_partial_template(self):
    # Full page request
    response = self.client.get("/users/")
    self.assertContains(response, "<!DOCTYPE html>")
    self.assertContains(response, '<html>')

    # htmx fragment request
    response = self.client.get("/users/", HTTP_HX_REQUEST="true")
    self.assertNotContains(response, "<!DOCTYPE html>")
    self.assertNotContains(response, '<html>')
    self.assertContains(response, '<table id="user-table"')
```

## End-to-End Testing (Playwright/Cypress)

Server-side tests cannot verify actual DOM manipulation. Use e2e tests for:

### Basic htmx Interaction

```python
# Playwright example
def test_htmx_fragment_swap(page):
    page.goto("/users/")
    # Click a button that triggers htmx request
    page.click("#load-more")
    # Wait for fragment to be inserted
    page.wait_for_selector("#user-table tr:nth-child(11)")
    # Verify content
    assert "New User" in page.inner_text("#user-table")
```

### Testing Polling

```python
def test_polling_updates(page):
    page.goto("/status/42/")
    # Wait for polling to update the DOM
    page.wait_for_selector("#status:has-text("Complete")")
    # Verify polling stopped (no more network requests)
    page.wait_for_timeout(3000)
    # Should still see "Complete"
    assert "Complete" in page.inner_text("#status")
```

### Testing OOB Swaps

```python
def test_oob_badge_update(page):
    page.goto("/orders/")
    initial_count = page.inner_text("#order-count")
    page.click("#create-order")
    # Badge should update out-of-band
    page.wait_for_selector("#order-count:has-text(" + str(int(initial_count) + 1) + ")")
```

### Testing Client-Side Redirects

```python
def test_htmx_redirect(page):
    page.goto("/sensitive-action/")
    page.click("#execute-action")
    # Should redirect without full page reload
    page.wait_for_url("/activate-sudo/")
    # Check that history was updated (not a full reload)
    assert page.evaluate("window.performance.navigation.type") == 0
```

## Test Utilities

### Helper for htmx requests

```python
# tests/utils.py
from django.test import Client

class HtmxClient(Client):
    """Client that sends HX-Request header by default."""
    def __init__(self, **defaults):
        super().__init__(**defaults)
        self.defaults["HTTP_HX_REQUEST"] = "true"

# Usage
class MyTests(TestCase):
    def setUp(self):
        self.client = HtmxClient()
```

### Fixture for htmx-boosted navigation

```python
# tests/fixtures.py
HTMX_BOOSTED_FIXTURE = {
    "HTTP_HX_REQUEST": "true",
    "HTTP_HX_BOOSTED": "true",
    "HTTP_HX_CURRENT_URL": "/page/",
}
```

## Common Test Pitfalls

### 1. Forgetting HX-Request Header

Without `HTTP_HX_REQUEST="true"`, you're testing the full page, not the fragment.

### 2. Testing JSON Instead of HTML

If your view returns `JsonResponse` for htmx requests, the test passes but htmx won't work. Assert on HTML content.

### 3. Not Testing Both Paths

Always test both htmx and non-httmx paths:

```python
def test_both_rendering_modes(self):
    # Full page
    response = self.client.get("/users/")
    self.assertTemplateUsed(response, "users/full.html")

    # Fragment
    response = self.client.get("/users/", HTTP_HX_REQUEST="true")
    self.assertTemplateUsed(response, "users/partial.html")
```

### 4. Ignoring Error States

Test what happens when htmx requests fail:

```python
def test_error_fragment(self):
    response = self.client.post(
        "/invalid-action/",
        HTTP_HX_REQUEST="true",
    )
    self.assertEqual(response.status_code, 400)
    # Error message should still be HTML fragment
    self.assertContains(response, "Validation error")
```

## References

- **Playwright Django examples**: https://playwright.dev/python/docs/auth
- **Cypress Django testing**: https://docs.cypress.io/guides/getting-started/testing-your-app
