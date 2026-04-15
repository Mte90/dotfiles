---
name: playwright-visual-regression
description: "Visual regression testing using Playwright with toHaveScreenshot(), masking, thresholds, cross-browser testing, and VUDA integration for AI-powered visual analysis"
metadata:
  author: "OSS AI Skills"
  version: "1.0.0"
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

Playwright supports Python alongside TypeScript/JavaScript:

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

### Simple Screenshot Test

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
      // Maximum time to wait for screenshot
      timeout: 5000,
      // Animated elements
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

## Masking Dynamic Content

Real applications have dynamic elements (timestamps, avatars, ads). Mask them to avoid false positives.

### Basic Masking

```typescript
await expect(page).toHaveScreenshot('dashboard.png', {
  mask: [
    page.locator('[data-testid="user-avatar"]'),
    page.locator('[data-testid="timestamp"]'),
    page.locator('.live-feed'),
    page.locator('.ad-banner'),
  ],
  maskColor: '#000000',  // Custom mask color
});
```

### Reusable Mask Helper

```typescript
// helpers/visual.ts
import { Page } from '@playwright/test';

export async function maskDynamicContent(page: Page, selectors: string[]) {
  return selectors.map(selector => page.locator(selector));
}

// Usage
test('dashboard with masking', async ({ page }) => {
  await page.goto('/dashboard');
  
  const dynamicElements = await maskDynamicContent(page, [
    '.timestamp',
    '.user-avatar',
    '.notification-badge',
  ]);
  
  await expect(page).toHaveScreenshot('dashboard.png', {
    mask: dynamicElements,
  });
});
```

## Handling Animations

Animations cause flaky tests. Disable them before capturing.

### CSS-Based Animation Disable

```typescript
async function disableAnimations(page: Page) {
  await page.addStyleTag({
    content: `
      *, *::before, *::after {
        animation-duration: 0s !important;
        animation-delay: 0s !important;
        transition-duration: 0s !important;
        transition-delay: 0s !important;
        scroll-behavior: auto !important;
      }
    `,
  });
}

test('checkout without animations', async ({ page }) => {
  await page.goto('/checkout');
  await disableAnimations(page);
  await expect(page).toHaveScreenshot('checkout.png');
});
```

### Built-in Animation Option

```typescript
await expect(page).toHaveScreenshot('page.png', {
  animations: 'disabled',  // Playwright handles this automatically
});
```

## Full-Page Screenshots

### Full-Page Capture

```typescript
test('full page screenshot', async ({ page }) => {
  await page.goto('/pricing');
  
  await expect(page).toHaveScreenshot('pricing-full.png', {
    fullPage: true,
  });
});
```

### Handling Lazy-Loaded Content

```typescript
test('blog with lazy loading', async ({ page }) => {
  await page.goto('/blog');
  
  // Scroll to trigger lazy loading
  await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
  await page.waitForTimeout(1000);  // Wait for images
  await page.evaluate(() => window.scrollTo(0, 0));  // Scroll back
  
  await expect(page).toHaveScreenshot('blog-full.png', {
    fullPage: true,
  });
});
```

## Element-Level Testing

Test specific components instead of full pages for more precise results.

```typescript
test('navigation component', async ({ page }) => {
  await page.goto('/');
  
  const navbar = page.locator('nav[data-testid="main-nav"]');
  await expect(navbar).toHaveScreenshot('navbar.png');
});

test('pricing card', async ({ page }) => {
  await page.goto('/pricing');
  
  const card = page.locator('[data-testid="pro-plan"]');
  await expect(card).toHaveScreenshot('pro-plan-card.png', {
    maxDiffPixelRatio: 0.005,  // Tighter threshold for components
  });
});
```

## Cross-Browser Considerations

Different browsers render differently. Each project gets its own baseline:

```
tests/
  homepage.spec.ts-snapshots/
    homepage-chromium-linux.png
    homepage-firefox-linux.png
    homepage-webkit-linux.png
```

**Important:** Generate baselines in the same environment as CI to avoid OS-level rendering differences.

```yaml
# CI using Playwright Docker image
- uses: docker://mcr.microsoft.com/playwright:v1.50.0-noble
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Visual Regression Tests
on: [pull_request]

jobs:
  visual-tests:
    runs-on: ubuntu-latest
    container: mcr.microsoft.com/playwright:v1.50.0-noble
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - name: Run visual tests
        run: npx playwright test --grep @visual
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: visual-diff-report
          path: playwright-report/
```

### Updating Baselines

```bash
# Update snapshots for specific test
npx playwright test --update-snapshots --grep "homepage"

# Update all snapshots
npx playwright test --update-snapshots
```

## Debugging Visual Failures

When tests fail, Playwright generates three images in `test-results/`:

1. **Expected** - the baseline image
2. **Actual** - current screenshot
3. **Diff** - highlighted differences (red pixels)

```bash
# View HTML report with visual diffs
npx playwright show-report
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Entire screenshot different | Different OS/browser version | Use consistent CI environment |
| Text differences | Font rendering variance | Use Playwright Docker image |
| Scattered pixels | Anti-aliasing | Increase `maxDiffPixels` |
| Specific component changed | Real regression | Investigate CSS change |

## VUDA Integration (Optional)

VUDA (Visual UI Debug Agent) is an optional MCP server that provides AI-powered visual testing capabilities. It's **not included** in this skill - you need to install and configure it separately.

VUDA goes beyond Playwright's built-in VRT by providing:
- AI-powered visual analysis without writing tests
- Automatic visual difference detection
- DOM inspection with styles
- User workflow validation
- Performance metrics
- Console error monitoring

### VUDA Installation

```bash
# Install globally
npm install -g visual-ui-debug-agent-mcp

# Or run with npx
npx visual-ui-debug-agent-mcp
```

### Configure VUDA MCP

Add to your Claude Desktop config (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "vuda": {
      "command": "npx",
      "args": ["-y", "visual-ui-debug-agent-mcp"]
    }
  }
}
```

VUDA provides these tools for visual testing:

### Available VUDA Tools

| Tool | Description | Use Case |
|------|-------------|----------|
| `screenshot_url` | Capture screenshots of any URL | Quick visual capture without writing tests |
| `enhanced_page_analyzer` | Comprehensive page analysis with screenshots | Full diagnostic with console + elements |
| `visual_comparison` | Compare two URLs/pages and highlight differences | Before/after visual regression |
| `dom_inspector` | Inspect DOM elements with computed styles | Debug styling issues |
| `ui_workflow_validator` | Test user journeys with validation | Automated E2E testing |
| `performance_analysis` | Measure Core Web Vitals | Performance regression testing |
| `console_monitor` | Capture console errors/warnings | JavaScript error detection |
| `navigation_flow_validator` | Test sequences of user actions | Complex user flows |
| `batch_screenshot_urls` | Capture multiple URLs in grid | Overview/comparison |
| `visual_comparison` | Pixel-diff between two URLs | Automated visual diff |

### 1. screenshot_url - Quick Screenshots

Capture a screenshot without writing any test code:

```
screenshot_url(
  url: "https://example.com",
  fullPage: false,
  selector: null,  // Optional: capture specific element
  waitTime: 5000
)
```

**Example workflow:**
1. Run `screenshot_url` to capture current state
2. Make changes to your app
3. Run `screenshot_url` again
4. Compare visually

### 2. enhanced_page_analyzer - Full Diagnostic

Comprehensive page analysis combining multiple data sources:

```
enhanced_page_analyzer(
  url: "https://example.com",
  includeConsole: true,     // Capture console logs
  mapElements: true,        // Map interactive elements
  fullPage: false,
  waitForSelector: null,
  device: null
)
```

**Returns:**
- Screenshot
- Console logs (errors, warnings, info)
- List of interactive elements
- Page metadata

**Use case:** Debug why a page looks broken - get screenshot + console + elements in one call.

### 3. visual_comparison - Automated Visual Diff

Compare two URLs and automatically highlight differences:

```
visual_comparison(
  url1: "https://example.com",
  url2: "https://staging.example.com",
  threshold: 0.1,    // Sensitivity (0.0-1.0)
  fullPage: false,
  selector: null
)
```

**Returns:**
- Side-by-side screenshot
- Highlighted diff image
- Percentage of difference

**Use case:** Compare production vs staging, before/after deployments.

### 4. dom_inspector - Style Debugging

Inspect specific DOM elements with computed styles:

```
dom_inspector(
  url: "https://example.com",
  selector: "#login-button",
  includeChildren: false,
  includeStyles: true
)
```

**Returns:**
- Element HTML
- Computed CSS styles
- Computed values (colors, sizes, positions)

**Use case:** Debug why a button looks different - get exact CSS values.

### 5. ui_workflow_validator - Automated E2E

Test complete user journeys with validation:

```
ui_workflow_validator(
  startUrl: "https://example.com",
  taskDescription: "User login flow",
  steps: [
    {
      action: "fill",
      selector: "#email",
      value: "test@example.com"
    },
    {
      action: "fill", 
      selector: "#password",
      value: "password123"
    },
    {
      action: "click",
      selector: "[data-testid='login-btn']"
    },
    {
      action: "verifyUrl",
      url: "/dashboard"
    },
    {
      action: "verifyText",
      selector: "h1",
      value: "Dashboard"
    }
  ],
  captureScreenshots: "all"
)
```

**Returns:**
- Screenshots per step
- Pass/fail status per step
- Error details if failed

**Use case:** Automate complex flows without writing Playwright code.

### 6. performance_analysis - Core Web Vitals

Measure page performance metrics:

```
performance_analysis(
  url: "https://example.com",
  iterations: 3,
  waitForNetworkIdle: true,
  device: null
)
```

**Returns:**
- LCP (Largest Contentful Paint)
- FID (First Input Delay)
- CLS (Cumulative Layout Shift)
- FCP (First Contentful Paint)
- TTFB (Time to First Byte)

**Use case:** Catch performance regressions before deployment.

### 7. console_monitor - JavaScript Error Detection

Monitor console output for a page:

```
console_monitor(
  url: "https://example.com",
  filterTypes: ["error", "warning"],
  duration: 5000,
  interactionSelector: null
)
```

**Returns:**
- All console messages
- Error stack traces
- Warning details

**Use case:** Detect JavaScript errors during page load.

### 8. navigation_flow_validator - Multi-Page Flows

Test sequences across multiple pages:

```
navigation_flow_validator(
  startUrl: "https://example.com",
  steps: [
    { action: "navigate", url: "/products" },
    { action: "click", selector: ".product:first-child" },
    { action: "click", selector: "[data-testid='add-to-cart']" },
    { action: "navigate", url: "/cart" },
    { action: "screenshot", selector: null }
  ],
  captureScreenshots: true
)
```

### Complete VUDA Workflow Example

**Scenario:** You deployed a new version and want to verify the homepage looks correct.

```python
# Step 1: Capture baseline screenshot
vuda.screenshot_url(
    url="https://production.example.com",
    fullPage=True
)

# Step 2: Analyze with console to check for JS errors  
vuda.enhanced_page_analyzer(
    url="https://production.example.com",
    includeConsole=True,
    mapElements=True
)

# Step 3: Compare with staging
vuda.visual_comparison(
    url1="https://production.example.com",
    url2="https://staging.example.com",
    threshold=0.05
)

# Step 4: If issues found, inspect specific element
vuda.dom_inspector(
    url="https://staging.example.com",
    selector=".hero-title",
    includeStyles=True
)
```

### VUDA + Playwright Combined

Use VUDA for quick analysis, Playwright for CI/CD:

```python
# Quick debug with VUDA
vuda.enhanced_page_analyzer(
    url="http://localhost:3000",
    includeConsole=True
)

# Automated regression with Playwright
def test_homepage_visual_regression(page):
    page.goto("http://localhost:3000")
    expect(page).to_have_screenshot("homepage.png")
```

### Best Practices with VUDA

1. **Use for debugging** - Quick visual checks without writing tests
2. **Use for exploration** - Discover issues on unknown pages
3. **Use for comparison** - Before/after, staging/prod
4. **Use Playwright for CI** - Automated, reproducible tests

### Troubleshooting VUDA

| Issue | Solution |
|-------|----------|
| No screenshots | Check browser can launch, no headless restrictions |
| Timeout errors | Increase `waitTime` for slow pages |
| Missing elements | Page may use client-side rendering, wait longer |
| Console not captured | Some errors only appear on interaction |

### VUDA vs Playwright Built-in

| Feature | VUDA | Playwright toHaveScreenshot |
|---------|------|---------------------------|
| Setup required | Yes (MCP) | No (built-in) |
| Test automation | No (manual) | Yes (CI/CD) |
| AI analysis | Yes | No |
| Visual diff | Manual comparison | Automatic |
| Console capture | Yes | No |
| Performance metrics | Yes | No |
| Best for | Debugging, exploration | Automated regression |

## Vision Model Integration (look_at)

Use `look_at` tool with vision-capable models to analyze screenshots after capturing them.

**Important:** `look_at` requires a **direct file path** to the screenshot file (e.g., `/tmp/dashboard.png`). It does not work with virtual files or URLs - you must save the screenshot to disk first.

### Analyzing Screenshots with AI

```typescript
import { test, expect } from '@playwright/test';
import { readFileSync } from 'fs';

test('analyze screenshot with vision model', async ({ page }) => {
  await page.goto('/dashboard');
  
  // IMPORTANT: Save screenshot to a real file path
  // look_at needs a real filesystem path, not virtual/URL
  await page.screenshot({ 
    path: '/tmp/dashboard.png',  // Direct file path required!
    fullPage: true 
  });
  
  // Use look_at tool with the file path:
  // look_at(
  //   file_path: '/tmp/dashboard.png',
  //   goal: 'Analyze this dashboard screenshot for layout issues, missing elements, color problems'
  // )
  
  // The vision model will identify:
  // - Layout issues
  // - Color consistency problems
  // - Missing elements
  // - Visual anomalies
});
```

### look_at Requirements

```typescript
// ❌ WRONG - look_at does NOT work with:
// - URLs
// - Virtual files
// - Base64 strings
// - File descriptors

// ✅ CORRECT - look_at needs:
look_at(
  file_path: '/absolute/path/to/screenshot.png',  // Must be real file on disk
  goal: 'What to analyze in the screenshot'
)

// Recommended: Save to /tmp for temporary screenshots
await page.screenshot({ path: '/tmp/my-screenshot.png' });
look_at(file_path: '/tmp/my-screenshot.png', goal: 'Find any visual bugs');
```

### Complete Workflow Example

```typescript
test('capture and analyze screenshot', async ({ page }) => {
  await page.goto('/checkout');
  
  // Step 1: Capture screenshot to real file path
  const screenshotPath = '/tmp/checkout-page.png';
  await page.screenshot({ 
    path: screenshotPath,
    fullPage: true 
  });
  
  // Step 2: Use look_at for AI analysis
  // In your prompt, call look_at with:
  // {
  //   file_path: '/tmp/checkout-page.png',
  //   goal: 'Identify any visual issues: layout shifts, color mismatches, missing text, overlapping elements'
  // }
  
  // The model analyzes the image and returns:
  // - List of detected visual issues
  // - Screenshots of problematic areas
  // - Specific recommendations
});
```

### Best Practices for look_at

1. **Always use absolute paths** - `/tmp/screenshot.png` not `screenshot.png`
2. **Save to /tmp** - For temporary test screenshots
3. **Use descriptive goals** - "Find UI bugs" is better than "Analyze this"
4. **Check file exists** - Ensure screenshot was saved before calling look_at

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
// Prefer component screenshots
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

## Advanced Patterns

### Data-Driven Visual Testing

```typescript
import { test, expect } from '@playwright/test';
import testData from './visual-scenarios.json';

testData.forEach(({ name, url, maskSelectors, threshold }) => {
  test(`visual: ${name}`, async ({ page }) => {
    await page.goto(url);
    
    const mask = maskSelectors?.map(sel => page.locator(sel));
    
    await expect(page).toHaveScreenshot(`${name}.png`, {
      mask,
      maxDiffPixelRatio: threshold || 0.01,
    });
  });
});
```

### Page Object Model

```typescript
// page-objects/VisualPage.ts
import { type Page, expect } from '@playwright/test';

export class VisualPage {
  constructor(private page: Page) {}

  async assertMatches(name: string, options = {}) {
    await expect(this.page).toHaveScreenshot(name, options);
  }

  async assertElementMatches(selector: string, name: string, options = {}) {
    const element = this.page.locator(selector);
    await expect(element).toHaveScreenshot(name, options);
  }
}

// Usage
test('dashboard visual', async ({ page }) => {
  const visualPage = new VisualPage(page);
  await page.goto('/dashboard');
  await visualPage.assertMatches('dashboard.png', { mask: [...] });
});
```

## Troubleshooting

### Flaky Tests

**Causes:**
1. Animations not disabled
2. Dynamic content not masked
3. Network not idle before capture
4. Viewport inconsistencies

**Solutions:**

```typescript
test('stable screenshot', async ({ page }) => {
  await page.goto('/');
  
  // Disable animations
  await page.addStyleTag({ content: '*, *::before, *::after { animation: none !important; }' });
  
  // Wait for network idle
  await page.waitForLoadState('networkidle');
  
  // Disable animations in screenshot options
  await expect(page).toHaveScreenshot('stable.png', {
    animations: 'disabled',
    mask: [page.locator('.dynamic')],
  });
});
```

### Baseline Mismatch

1. **Different OS** - Use Playwright Docker image in CI
2. **Different browser version** - Pin Playwright version
3. **Font rendering** - Bundle fonts or use web fonts

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
| Vision model analysis | `look_at` tool with screenshots |
| Cross-browser at scale | Run against multiple browsers in CI |
| Component testing | Element-level screenshots |