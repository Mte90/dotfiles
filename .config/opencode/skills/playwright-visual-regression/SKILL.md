---
name: playwright-visual-regression
description: Use when setting up visual regression testing with Playwright - toHaveScreenshot baselines, masking dynamic content, handling animations, full-page and element screenshots, cross-browser runs, CI integration, VUDA MCP tooling, or debugging flaky visual diffs
metadata:
  author: mte90
  version: 2.0.0
  tags:
    - playwright
    - visual-testing
    - regression
    - screenshot
    - vrt
    - automation
    - testing
---

# Playwright Visual Regression Testing

Complete guide to visual regression testing using Playwright's built-in `toHaveScreenshot()` API, VUDA MCP integration, and AI-powered visual analysis with vision models.

## Overview

Playwright provides native visual regression testing through the `toHaveScreenshot()` assertion. It captures screenshots, compares them against baselines using pixelmatch, and fails tests when visual differences exceed configured thresholds.

**Key Features:**
- Built-in screenshot comparison (no external dependencies)
- Pixel-by-pixel comparison with configurable thresholds
- Dynamic content masking
- Animation handling
- Cross-browser testing (Chromium, Firefox, WebKit)
- Full-page and element-level screenshots
- Integration with VUDA MCP for AI-powered visual debugging
- Vision model integration for screenshot analysis

## Installation

### Python Installation

```bash
# Install Playwright for Python
pip install playwright

# Install browser drivers
playwright install chromium firefox webkit

# Or install all browsers
playwright install
```

### TypeScript/JavaScript Installation

```bash
# Install Playwright
npm install -D @playwright/test

# Install browsers
npx playwright install chromium firefox webkit
```

## Basic Usage

### Python Example

```python
from playwright.sync_api import sync_playwright, expect

def test_homepage_screenshot():
    """Visual regression test for homepage"""
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()
        
        page.goto("https://your-app.com")
        
        # Take screenshot for comparison
        expect(page).to_have_screenshot("homepage.png")
        
        browser.close()

def test_element_screenshot():
    """Test specific element instead of full page"""
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()
        
        page.goto("/pricing")
        
        # Screenshot of specific element
        pricing_card = page.locator('[data-testid="pro-plan"]')
        expect(pricing_card).to_have_screenshot("pro-plan-card.png")
        
        browser.close()

def test_with_masking():
    """Mask dynamic content before screenshot"""
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()
        
        page.goto("/dashboard")
        
        # Mask dynamic elements
        expect(page).to_have_screenshot("dashboard.png", mask=[
            page.locator(".timestamp"),
            page.locator(".user-avatar"),
        ])
        
        browser.close()
```

### Using pytest with Playwright

```python
# conftest.py
import pytest
from playwright.sync_api import sync_playwright, Browser, Page

@pytest.fixture(scope="session")
def browser():
    with sync_playwright() as p:
        yield p.chromium.launch()

@pytest.fixture
def page(browser: Browser):
    page = browser.new_page()
    yield page
    page.close()

# test_visual.py
def test_login_page(page: Page):
    page.goto("/login")
    expect(page).to_have_screenshot("login-page.png")

def test_login_with_errors(page: Page):
    page.goto("/login")
    page.fill("#email", "invalid")
    page.click('[data-testid="submit"]')
    expect(page).to_have_screenshot("login-error.png")
```

### Pytest Markers for Visual Tests

```python
import pytest

@pytest.mark.visual
def test_visual_regression(page):
    """Run only visual tests with: pytest -m visual"""
    page.goto("/")
    expect(page).to_have_screenshot("homepage.png")

@pytest.mark.visual
@pytest.mark.parametrize("viewport", [
    {"width": 1280, "height": 720},  # Desktop
    {"width": 375, "height": 667},   # Mobile
])
def test_responsive_visual(page, viewport):
    """Test different viewports"""
    page.set_viewport_size(viewport)
    page.goto("/")
    name = f"homepage-{viewport['width']}x{viewport['height']}.png"
    expect(page).to_have_screenshot(name)
```

### TypeScript/JavaScript Example

```typescript
import { test, expect } from '@playwright/test';

test('homepage matches baseline', async ({ page }) => {
  await page.goto('https://your-app.com');
  await expect(page).toHaveScreenshot();
});
```

### First Run Behavior

The first run creates baseline images. Run with `--update-snapshots` to generate baselines:

```bash
npx playwright test --update-snapshots
```

Baselines are stored in `__snapshots__` directories next to test files.

### Named Screenshots

```typescript
test('login form states', async ({ page }) => {
  await page.goto('/login');
  
  // Empty state
  await expect(page).toHaveScreenshot('login-empty.png');
  
  // Validation error
  await page.fill('#email', 'invalid');
  await page.click('[data-testid="submit"]');
  await expect(page).toHaveScreenshot('login-validation-error.png');
});
```

## Configuration

### Playwright Config

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  retries: 2,
  
  // Cross-browser projects
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    // Mobile viewports
    {
      name: 'mobile-chrome',
      use: { ...devices['Pixel 7'] },
    },
  ],
  
  // Visual regression settings
  expect: {
    toHaveScreenshot: {
      timeout: 5000,
      animations: 'disabled',
    },
  },
});
```

### Threshold Options

```typescript
// Allow minor pixel differences
await expect(page).toHaveScreenshot('page.png', {
  maxDiffPixels: 100,           // Maximum pixels that can differ
  maxDiffPixelRatio: 0.01,      // Maximum 1% pixel difference
  threshold: 0.3,               // Per-pixel color sensitivity (0-1)
});
```

## Deep Dives

For detailed guidance on specific topics, load these reference files on demand:

- **Screenshot Techniques** (`references/screenshot-techniques.md`) - Masking dynamic content, handling animations, full-page screenshots, element-level testing, cross-browser considerations
- **VUDA AI Tools** (`references/vuda-ai.md`) - VUDA MCP integration, vision model `look_at` usage
- **CI & Debugging** (`references/ci-debugging.md`) - CI/CD integration, debugging visual failures, advanced patterns, troubleshooting flaky tests

## Best Practices

### 1. Test Organization

```typescript
// Tag visual tests for selective execution
test('homepage visual @visual', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveScreenshot('homepage.png');
});

// Run only visual tests
npx playwright test --grep @visual
```

### 2. Component Over Full Page

```typescript
// ✅ Good: Targeted, fast, precise
await expect(page.locator('.product-card')).toHaveScreenshot('product-card.png');

// ⚠️ Full page: Slower, more noise, harder to diagnose failures
await expect(page).toHaveScreenshot('page.png');
```

### 3. Consistent Environments

```bash
# Always use Docker for consistent rendering
docker run --rm -v $(pwd):/app mcr.microsoft.com/playwright:v1.50.0-noble
```

### 4. Threshold Guidelines

| Type | Recommended Threshold |
|------|----------------------|
| Simple components | `maxDiffPixelRatio: 0.001` (0.1%) |
| Text-heavy pages | `maxDiffPixelRatio: 0.01` (1%) |
| Full-page with fonts | `maxDiffPixelRatio: 0.02` (2%) |

### 5. Handle Dynamic Content

```typescript
// Always mask:
test('feed with masking', async ({ page }) => {
  await page.goto('/feed');
  
  await expect(page).toHaveScreenshot('feed.png', {
    mask: [
      page.locator('.timestamp'),
      page.locator('.user-avatar'),
      page.locator('.ad-slot'),
      page.locator('[data-testid="like-count"]'),
    ],
  });
});
```

## Test Pyramid for Visual Testing

```
        /\
       /  \     E2E Visual Tests (5-10%)
      /----\    - Critical user flows
     /      \   - Full-page regression
    /--------\  Component Tests (20-30%)
   /          \ - Individual components
  /------------\- UI component variants
 /              \ Element Tests (60-70%)
/________________\ - Smallest UI units
                 - Buttons, inputs, cards
```

## Resources

- [Playwright Visual Regression Docs](https://playwright.dev/docs/test-snapshots)
- [VUDA MCP GitHub](https://github.com/samihalawa/visual-ui-debug-agent-mcp)
- [BrowserStack Visual Testing Guide](https://www.browserstack.com/guide/visual-regression-testing-using-playwright)
- [CSS-Tricks Visual Testing Guide](https://css-tricks.com/automated-visual-regression-testing-with-playwright/)

---

**When to Use What:**

| Need | Solution |
|------|----------|
| Basic VRT | `toHaveScreenshot()` - built into Playwright |
| AI-powered analysis | VUDA MCP tools |
| Vision model analysis | `look_at` tool with screenshots |
| Cross-browser at scale | Run against multiple browsers in CI |
| Component testing | Element-level screenshots |