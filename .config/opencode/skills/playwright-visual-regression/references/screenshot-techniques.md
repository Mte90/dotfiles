<!-- This file is loaded on demand from ../SKILL.md -->

# Screenshot Techniques

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