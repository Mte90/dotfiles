---
name: playwright-visual-regression
description: >
  Visual regression testing with Playwright — pixel-by-pixel screenshot comparison against baselines.
  Built on @playwright/test's toHaveScreenshot() — no third-party services.
  
  TRIGGER when: user mentions "visual regression", "screenshot diff", "snapshot mismatch",
  "toHaveScreenshot", "pixel-perfect", "UI looks broken after changes", "compare screenshots",
  "visual QA", "catch visual bugs", "baseline screenshots", or wants to verify code changes
  didn't break the UI visually.
  
  DO NOT TRIGGER when: user wants functional/behavioral testing (use Playwright skill),
  just wants a single screenshot (use screenshots skill), or asks about accessibility.
metadata:
  author: OSS AI Skills
  version: 1.0.0
  based_on: https://github.com/maxrihter/claude-skill-visual-regression
  tags:
    - playwright
    - visual-regression
    - screenshot
    - testing
    - e2e
    - snapshot
    - pixel-perfect
---

# Playwright Visual Regression Testing

Compare UI screenshots pixel-by-pixel against a baseline. Catch unintended visual changes. Built on `@playwright/test` — no third-party services.

```
Baseline capture → Code change → Re-run → HTML diff report
     ✅                 🛠️           ▶️          🔍
```

> **Working directory:** All commands run from the project root — the directory containing `package.json`. Do not `cd` between steps.
>
> **Package manager:** This skill uses npm. If your project uses yarn or pnpm, adapt install and CI commands accordingly.

## Step 1: Check State

Run all three commands, then use the table to choose your workflow.

```bash
ls playwright.config.ts 2>/dev/null && echo "CONFIG_EXISTS" || echo "CONFIG_MISSING"
find snapshots/ -name "*.png" 2>/dev/null | head -1 | grep -q . && echo "BASELINES_EXIST" || echo "BASELINES_MISSING"
curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:3000 2>/dev/null | grep -q "^2" && echo "SERVER_OK" || echo "NO_SERVER"
```

> If your dev server runs on a port other than 3000, adjust the URL in the curl command above.

| Config | Baselines | Server | → Do this |
|--------|-----------|--------|-----------|
| CONFIG_MISSING | any | any | **→ Workflow A** (Full Setup) |
| CONFIG_EXISTS | BASELINES_MISSING | SERVER_OK | **→ Workflow B** (Capture Baseline) |
| CONFIG_EXISTS | BASELINES_EXIST | SERVER_OK | Run `npx playwright test`. If all tests pass ✓, done. If tests fail → see **Step 2**. |
| CONFIG_EXISTS | BASELINES_EXIST | NO_SERVER | STOP. Tell the user: "Dev server is not running. Start it first, then re-check." |
| CONFIG_EXISTS | BASELINES_MISSING | NO_SERVER | STOP. Tell the user: "No baselines and no dev server. Start the server first." |

Do not guess the next step — use the table.

## Step 2: If Tests Fail

Only consult this section after running `npx playwright test` and seeing a failure.

```
What kind of failure?
│
├─ "screenshot doesn't match" / snapshot diff
│  │
│  │  STOP. Ask the user:
│  │  "Was this visual change intentional (design update) or unexpected (possible bug)?"
│  │  Wait for an explicit answer — do NOT infer from context.
│  │  If the answer is ambiguous, ask again: "Please answer 'intentional' or 'bug'."
│  │
│  ├─ "Intentional" → Workflow C: Update Baseline
│  └─ "Bug" / "Unexpected" → Workflow D: Debug Comparison
│
├─ Tests flaky (pass sometimes, fail sometimes)
│  └─ → Workflow E: Fix Flakiness with Fixture
│
└─ Config errors / tests won't run
   └─ Check Node.js version (v18+), re-run `npx playwright install chromium`
```

---

## Workflow A: Full Setup

**Precondition:** Step 1 returned `CONFIG_MISSING`.

**Exit condition:** `npx playwright test --list` prints test names without errors.

**Step 1.** Check for existing `package.json`:
```bash
ls package.json 2>/dev/null && echo "EXISTS" || echo "MISSING"
```
If MISSING: run `npm init -y` first. If EXISTS: skip — do not re-initialize.

**Step 2.** Install Playwright:
```bash
npm install -D @playwright/test
npx playwright install chromium
```
If this fails: check `node -v` — requires v18+.

**Step 3.** Ask the user: "What URL does your dev server run on? (e.g. http://localhost:3000)"
Wait for their answer. Save it — you will use it in Step 4 and in Workflow B.

**Step 4.** Write the config file:

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  snapshotDir: './snapshots',
  // {testFileDir}/{testFileName} keeps the path readable without .ts-as-directory quirk
  snapshotPathTemplate: '{snapshotDir}/{projectName}/{testFileDir}/{testFileName}/{arg}{ext}',

  // Run tests in parallel within each file
  fullyParallel: true,
  // GitHub Actions ubuntu-latest = 2 vCPUs. Higher values increase screenshot timing
  // variability and make diffs non-deterministic. Use 2 in CI, unlimited locally.
  workers: process.env.CI ? 2 : undefined,

  // ⚠️ Visual regression tests should NOT retry.
  // A retry overwrites diff artifacts, making it impossible to diagnose whether the
  // failure was a flake or a real regression. If you see flakiness, fix it with the
  // visual fixture (Workflow E) instead of masking it with retries.
  retries: 0,

  // Stop after 10 failures in CI — don't waste time if something is globally broken.
  // 0 means "no limit" (unintuitive API — 0 ≠ "stop immediately").
  maxFailures: process.env.CI ? 10 : 0,

  // CI:    'none' — missing baseline = test fails. Baselines must be committed to git.
  //        ⚠️ New tests added in a PR will fail in CI until baselines are generated
  //        via the update-snapshots workflow and committed. This is intentional.
  // Local: 'missing' — create new baselines automatically, never overwrite existing ones.
  //        Use `npx playwright test --update-snapshots` to overwrite changed ones.
  updateSnapshots: process.env.CI ? 'none' : 'missing',

  // Reporter: CI → dot + HTML report (open:'never' — no browser in CI)
  //           Local → list (verbose) + HTML report (opens on failure)
  reporter: process.env.CI
    ? [['dot'], ['html', { open: 'never', outputFolder: 'playwright-report' }]]
    : [['list'], ['html', { open: 'on-failure', outputFolder: 'playwright-report' }]],

  use: {
    // Set your actual dev server URL, or override via env variable:
    //   BASE_URL=https://staging.example.com npx playwright test
    baseURL: process.env.BASE_URL || 'http://localhost:3000',

    // ⚠️ reducedMotion: 'reduce' sets prefers-reduced-motion CSS media query.
    // Apps that respond to this query will render a DIFFERENT visual state
    // (e.g., no fade-in, instant transitions). You are testing the reduced-motion
    // layout, not the default one. If your app doesn't handle prefers-reduced-motion,
    // this has no effect. If it does — make sure your baselines match this state.
    // Remove this line if you want to test the default (animated) visual state.
    reducedMotion: 'reduce',
  },

  expect: {
    toHaveScreenshot: {
      // animations: 'disabled' freezes CSS transitions + Web Animations API at
      // screenshot time via DevTools protocol. This is already the default.
      animations: 'disabled',
      maxDiffPixelRatio: 0.01, // allow up to 1% of pixels to differ
      // threshold: per-pixel color sensitivity (0–1).
      // 0.05 = a pixel must differ by >5% of full color range to count as changed.
      // Increase to 0.1 or 0.2 only if font anti-aliasing causes false positives.
      threshold: 0.05,
    },
  },

  // Uncomment to auto-start your dev server before tests.
  // Without this, start the server manually before running `npx playwright test`.
  // webServer: {
  //   command: 'npm run dev',
  //   url: 'http://localhost:3000',
  //   reuseExistingServer: !process.env.CI,
  //   timeout: 30_000,
  // },

  projects: [
    {
      name: 'Desktop',
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1440, height: 900 },
      },
    },
    {
      name: 'Tablet',
      use: {
        // Spread device for correct user agent, touch emulation, deviceScaleFactor.
        // Override viewport to exact dimensions needed.
        ...devices['iPad (gen 7)'],
        viewport: { width: 768, height: 1024 },
      },
    },
    {
      name: 'Mobile',
      use: {
        // Spread device for correct mobile user agent and touch emulation.
        // Override viewport to exact dimensions needed.
        ...devices['iPhone 13'],
        viewport: { width: 375, height: 812 },
      },
    },
  ],
});
```

If the user's URL differs from `http://localhost:3000`, edit the `baseURL` line.

**Step 5.** Write the test file:

```typescript
// tests/visual.spec.ts
// Basic tests — standard @playwright/test
import { test, expect } from '@playwright/test';

// With the production fixture (fonts, JS animations, lazy images):
// import { test, expect, waitForPageReady } from '../fixtures/visual';

// ─────────────────────────────────────────────
// Basic: full page screenshot
// ─────────────────────────────────────────────
test('homepage', async ({ page }) => {
  await page.goto('/');

  // locator.waitFor() is the modern API — prefer over page.waitForSelector()
  await page.locator('h1').waitFor();

  // If using fixture: await waitForPageReady(page);

  await expect(page).toHaveScreenshot('homepage.png', {
    fullPage: true,
  });
});

// ─────────────────────────────────────────────
// Element-level screenshot
// ─────────────────────────────────────────────
test('heading', async ({ page }) => {
  await page.goto('/');
  await page.locator('h1').waitFor();

  await expect(page.locator('h1')).toHaveScreenshot('heading.png');
});

// ─────────────────────────────────────────────
// With dynamic content masked (adapt selectors to your app)
// ─────────────────────────────────────────────
// test('page with live data', async ({ page }) => {
//   await page.goto('/your-route');
//   await page.locator('[data-testid="loaded"]').waitFor();
//
//   await expect(page).toHaveScreenshot('page-live-data.png', {
//     fullPage: true,
//     mask: [
//       page.locator('[data-testid="live-price"]'),
//       page.locator('[data-testid="timestamp"]'),
//     ],
//   });
// });

// ─────────────────────────────────────────────
// With fixture: fonts + JS animations + lazy images
// ─────────────────────────────────────────────
// import { test, expect, waitForPageReady } from '../fixtures/visual';
//
// test('page with animations', async ({ page }) => {
//   await page.goto('/');
//   await page.locator('h1').waitFor();
//   await waitForPageReady(page);   // freeze fonts, images, GSAP
//   await expect(page).toHaveScreenshot('animated-page.png', { fullPage: true });
// });
```

**Step 6.** Verify setup is functional:
```bash
npx playwright test --list
```
If this errors or prints `0 tests`: show the output to the user and stop. Do not proceed to Workflow B.

**Optional:** If the project uses custom fonts, JS animations (GSAP, Framer Motion), or lazy-loaded images, also install the fixture now — see **Workflow E** Steps 1–2.

**Workflow A complete** → continue to **Workflow B**.

---

## Workflow B: Capture Baseline

**Precondition:** CONFIG_EXISTS + BASELINES_MISSING + SERVER_OK. (Or: just completed Workflow A.)

**Exit condition:** `find snapshots/ -name "*.png" | wc -l` prints a non-zero number and snapshots are committed to git.

**Step 1.** Verify the dev server responds. Use the `baseURL` from `playwright.config.ts` (default: `http://localhost:3000`). Replace the URL in the command if yours differs:
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000
```
Expected: `200`. If not 200: STOP. Tell the user the server is not responding and ask them to start it.

**Step 2.** Check if Docker is available:
```bash
docker --version 2>/dev/null && echo "DOCKER_OK" || echo "NO_DOCKER"
```

If DOCKER_OK — capture inside Docker (matches Linux CI, avoids font rendering diffs):
```bash
docker run --rm --ipc=host -v "$(pwd):/work" -w /work \
  mcr.microsoft.com/playwright:v1.50.1-noble \
  npx playwright test --update-snapshots
```

If NO_DOCKER — ask the user:
> "Docker is not available. Baselines captured locally on macOS can cause false CI failures due to font rendering differences. Do you want to proceed locally (acceptable if you won't use CI), or install Docker first?"
Wait for their answer before proceeding. If they confirm local: run `npx playwright test --update-snapshots`.

**Step 3.** Verify snapshots were created:
```bash
find snapshots/ -name "*.png" | wc -l
```
If output is `0` or command errors: STOP. Show the user the test output and ask to debug.

**Step 4.** Commit baselines:
```bash
if ! git rev-parse --is-inside-work-tree 2>/dev/null; then
  echo "Not a git repository — skipping commit."
elif git check-ignore -q snapshots/ 2>/dev/null; then
  echo "⚠️  snapshots/ is listed in .gitignore — remove it so baselines can be committed."
else
  git add snapshots/
  if git diff --staged --quiet; then
    echo "Snapshots already committed — nothing to add."
  else
    git commit -m "chore: add visual baselines"
    echo "Done. Push to remote: git push"
  fi
fi
```

**Workflow B complete.** Baselines are now the source of truth.

---

## Workflow C: Update Baseline

**Precondition:** Tests failing with 'screenshot doesn't match' and the user confirmed the change is **intentional**.

Use when a design change is intentional and the current baseline is outdated.

**Before Step 1.** Ask the user:
> "What is the reason for updating these baselines? (e.g., 'updated button design', 'new header font')"
Wait for their answer. Save it. You will use it in Step 2. Do not proceed until you have a clear answer.

**Step 1.** Check if Docker is available:
```bash
docker --version 2>/dev/null && echo "DOCKER_OK" || echo "NO_DOCKER"
```

If DOCKER_OK — update snapshots inside Docker:
```bash
docker run --rm --ipc=host -v "$(pwd):/work" -w /work \
  mcr.microsoft.com/playwright:v1.50.1-noble \
  npx playwright test --update-snapshots
```
This updates all existing baselines AND creates new ones.

If NO_DOCKER — existing baselines need updating, so local font rendering on macOS may differ from Linux CI:
1. Install Docker (recommended) and rerun this step.
2. Or run `npx playwright test --update-snapshots` locally and accept that CI may need a re-run after push (CI captures its own Linux baselines).

Ask the user which they prefer before proceeding.

**Step 2.** Commit with the reason the user gave you:
```bash
git add snapshots/ && git commit -m "chore: update visual baselines — USER_REASON"
```
Replace `USER_REASON` with the exact answer from the user. Do not invent a reason. If the user's reason contains backticks, `$(`, or newlines, ask for a simpler version — those characters cause shell injection in the commit command.

> ⚠️ Never auto-update snapshots in CI. Use a dedicated workflow for intentional updates — it requires a reason and commits with attribution.

---

## Workflow D: Debug Comparison

**Precondition:** Tests failing with 'screenshot doesn't match' and the user confirmed it is a **bug** (unexpected change).

**Step 1.** Run tests and capture output:
```bash
npx playwright test 2>&1 | tail -30
```

**Step 2.** Find diff images (CLI-friendly — no browser needed):
```bash
find playwright-report/ -name "*-diff.png" -o -name "*-actual.png" 2>/dev/null | head -20
find test-results/ -name "*.png" 2>/dev/null | head -20
```
Show the user the list of diff image paths. Ask them to open the files to see what changed.

**Step 3.** If the user has a browser available, they can run the HTML report themselves:
```
npx playwright show-report
```
Do NOT run `show-report` yourself — it starts a web server and blocks the terminal indefinitely.

---

## Workflow E: Fix Flakiness with Fixture

**Precondition:** Tests are flaky (pass sometimes, fail sometimes) — not a consistent snapshot mismatch.

For pages with custom fonts, JS animations (Framer Motion, GSAP), or lazy-loaded images.

**Step 1.** Create the fixture file:

```typescript
// tests/fixtures/visual.ts
import { test as base, expect, type Page } from '@playwright/test';

/**
 * Production-ready visual test fixture.
 *
 * Architecture: two-phase approach
 *   Phase 1 — addInitScript (runs BEFORE any page JS):
 *     - IntersectionObserver mock (lazy images load immediately)
 *     - window.__PLAYWRIGHT__ flag (for app-level animation disabling)
 *   Phase 2 — waitForPageReady() (call explicitly after page.goto()):
 *     - Double rAF — JS framework finishes initial render, layout stabilizes
 *     - Freeze GSAP timeline (if present) in final state
 *     - Wait for all images to decode
 *     - Wait for custom fonts (document.fonts.ready)
 *     - Final rAF — browser settles last paint after fonts and images
 *
 * Usage:
 *   import { test, expect, waitForPageReady } from '../fixtures/visual';
 *
 *   test('homepage', async ({ page }) => {
 *     await page.goto('/');
 *     await page.locator('h1').waitFor();   // wait for key element
 *     await waitForPageReady(page);         // stabilize before screenshot
 *     await expect(page).toHaveScreenshot('homepage.png', { fullPage: true });
 *   });
 *
 * Framer Motion (skipAnimations):
 *   The fixture sets window.__PLAYWRIGHT__ = true before page JS runs.
 *   In your app (e.g., layout.tsx or _app.tsx), add:
 *
 *   import { MotionGlobalConfig } from 'framer-motion'; // or 'motion/react'
 *   if (typeof window !== 'undefined' && (window as any).__PLAYWRIGHT__) {
 *     MotionGlobalConfig.skipAnimations = true;
 *   }
 */

/**
 * Stabilizes the page before taking a screenshot.
 * Call explicitly after page.goto() and after waiting for key content.
 * Works for both full-page navigations and SPA route changes.
 */
export async function waitForPageReady(page: Page): Promise<void> {
  // 1. Double rAF — let JS framework complete initial render and layout stabilize.
  await page.evaluate(
    () =>
      new Promise<void>((resolve) =>
        requestAnimationFrame(() => requestAnimationFrame(() => resolve()))
      )
  );

  // 2. Freeze GSAP timeline in final state (if GSAP is present on the page).
  await page.evaluate(() => {
    const g = (window as any).gsap;
    if (g?.globalTimeline) {
      if (g.ticker?.lagSmoothing) g.ticker.lagSmoothing(0);
      g.globalTimeline.progress(1, true);
      g.globalTimeline.pause();
    }
  });

  // 3. Wait for all images to fully load.
  await page.evaluate(() =>
    Promise.all(
      [...document.images].map((img) =>
        img.complete
          ? Promise.resolve()
          : img.decode().catch(() => {
              /* broken images (404, CORS) — don't block */
            })
      )
    )
  );

  // 4. Wait for all custom fonts to finish loading.
  await page.evaluate(() => document.fonts.ready.then(() => {}));

  // 5. Final rAF — let the browser settle one last paint frame after fonts and images.
  await page.evaluate(
    () => new Promise<void>((resolve) => requestAnimationFrame(() => resolve()))
  );
}

export const test = base.extend({
  page: async ({ page }, use) => {
    // Phase 1: addInitScript — runs BEFORE any page JavaScript
    await page.addInitScript(() => {
      // Set window.__PLAYWRIGHT__ flag for app-level animation disabling.
      (window as any).__PLAYWRIGHT__ = true;

      // Mock IntersectionObserver so lazy loaders fire immediately.
      window.IntersectionObserver = class MockIntersectionObserver
        implements IntersectionObserver
      {
        readonly root: Element | Document | null = null;
        readonly rootMargin: string = '0px';
        readonly thresholds: ReadonlyArray<number> = [0];

        private readonly _callback: IntersectionObserverCallback;

        constructor(callback: IntersectionObserverCallback) {
          this._callback = callback;
        }

        observe(target: Element): void {
          queueMicrotask(() => {
            const rect = target.getBoundingClientRect();
            this._callback(
              [
                {
                  isIntersecting: true,
                  intersectionRatio: 1,
                  target,
                  boundingClientRect: rect,
                  intersectionRect: rect,
                  rootBounds: {
                    x: 0,
                    y: 0,
                    top: 0,
                    left: 0,
                    width: window.innerWidth,
                    height: window.innerHeight,
                    bottom: window.innerHeight,
                    right: window.innerWidth,
                    toJSON() {
                      return {
                        x: 0,
                        y: 0,
                        top: 0,
                        left: 0,
                        width: window.innerWidth,
                        height: window.innerHeight,
                        bottom: window.innerHeight,
                        right: window.innerWidth,
                      };
                    },
                  } as DOMRectReadOnly,
                  time: performance.now(),
                } as IntersectionObserverEntry,
              ],
              this as unknown as IntersectionObserver
            );
          });
        }

        unobserve(_target: Element): void {}
        disconnect(): void {}
        takeRecords(): IntersectionObserverEntry[] {
          return [];
        }
      };
    });

    await use(page);
  },
});

export { expect };
```

**Step 2.** In your test file (e.g. `tests/visual.spec.ts`), find the import line:
```typescript
import { test, expect } from '@playwright/test';
```
Replace it with:
```typescript
import { test, expect, waitForPageReady } from './fixtures/visual';
```
(Adjust the relative path if your test file is in a different location.)

**Step 3.** In every test that calls `toHaveScreenshot()`, add these two lines immediately before the `toHaveScreenshot` call:
```typescript
await page.locator('TODO_REPLACE_WITH_KEY_SELECTOR').waitFor();  // key element confirming page is loaded
await waitForPageReady(page);              // fonts + images + GSAP freeze
```
Replace `TODO_REPLACE_WITH_KEY_SELECTOR` with the actual selector for the main content element on that page.

---

## Workflow F: GitHub Actions CI

**Precondition:** Workflow B is complete — baselines are committed and pushed to git.

**Exit condition:** Visual tests workflow exists at `.github/workflows/visual-tests.yml` and CI runs green on push.

**Step 1.** Create the workflow file:

```yaml
# .github/workflows/visual-tests.yml
name: Visual Tests

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  visual-tests:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Install Playwright browsers
      run: npx playwright install chromium --with-deps
    
    - name: Run visual tests
      env:
        BASE_URL: ${{ secrets.BASE_URL }}
      run: npx playwright test --project=Desktop
      # Note: Run all projects in CI with: npx playwright test
    
    - name: Upload test results
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: playwright-report
        path: playwright-report/
        retention-days: 30
    
    - name: Upload diff images
      if: failure()
      uses: actions/upload-artifact@v4
      with:
        name: visual-diffs
        path: |
          test-results/
          playwright-report/
        retention-days: 30
```

**Step 2.** Configure `BASE_URL` for CI. Ask the user:
> "What URL should CI run visual tests against? (e.g. https://staging.example.com)"

Then add it as a repository secret in GitHub (**Settings → Secrets and variables → Actions → New repository secret**, name: `BASE_URL`). The workflow reads `BASE_URL` from secrets.

If the user has no staging URL yet (tests run against localhost only), skip this step. CI will fail at the network step until a server is available.

**Key requirements:**
- Baselines must be committed to git before running in CI
- `CI=true` is set automatically by GitHub Actions
- Keep the Docker image version in sync with `@playwright/test` in `package.json`

---

## Key Options

| Option | Default | Use |
|--------|---------|-----|
| `maxDiffPixelRatio` | `0.01` | % pixels allowed to differ (`0.01` = 1%). Set to `0` for zero tolerance |
| `threshold` | `0.05` | Per-pixel color sensitivity (0–1). Raise to `0.1` only for font anti-aliasing false positives |
| `reducedMotion` | `'reduce'` | Sets `prefers-reduced-motion` CSS media query. Remove if you want to test the default (animated) visual state |
| `mask` | `[]` | Locators to black out (prices, timestamps, live data) |
| `fullPage` | `false` | Capture entire scrollable page |
| `animations` | `'disabled'` | Default — CSS + Web Animations API stopped at screenshot time |

## Quick Commands

```bash
npx playwright test                             # compare vs baseline
npx playwright test --project=Desktop           # specific viewport
npx playwright test tests/visual.spec.ts        # specific file
npx playwright test --update-snapshots          # update changed baselines
npx playwright test --update-snapshots=missing  # only add new baselines
npx playwright show-report                      # open HTML report (local only)
```

## Best Practices

1. **Never retry visual tests** — Retries overwrite diff artifacts, making debugging impossible
2. **Use Docker for baselines** — Matches Linux CI, avoids font rendering differences
3. **Commit baselines to git** — They're source of truth for your UI
4. **Mask dynamic content** — Prices, timestamps, live data cause false positives
5. **Use the fixture for flaky tests** — Handles fonts, animations, lazy images
6. **Set reducedMotion** — Tests stable visual state, not animations

## References

- **Based on**: [maxrihter/claude-skill-visual-regression](https://github.com/maxrihter/claude-skill-visual-regression)
- **Playwright Documentation**: https://playwright.dev/docs/test-snapshots
- **toHaveScreenshot API**: https://playwright.dev/docs/api/class-pageassertions#page-assertions-to-have-screenshot-1
- **Visual Comparisons**: https://playwright.dev/docs/test-snapshots#pixel-matching
