<!-- This file is loaded on demand from ../SKILL.md -->

# CI & Debugging

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