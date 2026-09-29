<!-- This file is loaded on demand from ../SKILL.md -->

# VUDA AI Tools

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