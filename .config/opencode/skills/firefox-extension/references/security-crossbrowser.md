# Security & Cross-Browser Compatibility

> This reference file is loaded on demand from ../SKILL.md.

## Security & Content Security Policy

### Default CSP

**MV3:** `script-src 'self'; upgrade-insecure-requests;`
**MV2:** `script-src 'self'; object-src 'self';`

### CSP Restrictions

**Forbidden (causes AMO rejection):**
- Remote script sources
- `'unsafe-inline'`
- `'unsafe-eval'` (except `'wasm-unsafe-eval'` for WebAssembly)
- Data URLs for scripts
- `eval()`, `new Function()`, string-based code execution

**Allowed:**
- `'self'` - Scripts from extension package
- `'wasm-unsafe-eval'` - WebAssembly support
- `http://localhost:<port>` - Development only (remove before submission)

### Custom CSP Example

```json
{
  "content_security_policy": {
    "extension_pages": "script-src 'self' 'wasm-unsafe-eval'; object-src 'self';",
    "sandbox": "sandbox allow-scripts allow-forms allow-popups; script-src 'self';"
  }
}
```

### Security Best Practices

1. **Package all dependencies locally** - No CDN scripts
2. **Request minimal permissions** - Use `activeTab` instead of `<all_urls>` when possible
3. **Use optional_permissions** - Request permissions at runtime for non-critical features
4. **Validate user input** - Sanitize HTML before `innerHTML`, validate URLs
5. **Use HTTPS** - All external requests should use HTTPS
6. **No obfuscated code** - Must be reviewable for AMO

## Cross-Browser with webextension-polyfill

### Installation

```bash
npm install webextension-polyfill
```

### Usage

```javascript
// ES modules
import browser from 'webextension-polyfill';

// CommonJS
const browser = require('webextension-polyfill');

// Now browser.* works in Chrome with promises
const tabs = await browser.tabs.query({ active: true });
```

### Manifest Setup

```json
{
  "background": {
    "scripts": ["browser-polyfill.js", "background.js"]
  },
  "content_scripts": [{
    "matches": ["<all_urls>"],
    "js": ["browser-polyfill.js", "content.js"]
  }]
}
```

### TypeScript Support

```bash
npm install @types/webextension-polyfill
```

```typescript
import browser from 'webextension-polyfill';

async function getActiveTab(): Promise<browser.Tabs.Tab> {
  const [tab] = await browser.tabs.query({ active: true });
  return tab;
}
```

### Cross-Browser Compatibility Patterns

```javascript
import browser from 'webextension-polyfill';

// Feature detection
if (browser.sidebarAction) {
  // Firefox-specific
  browser.sidebarAction.open();
}

// Fallback pattern
const action = browser.action || browser.browserAction;
action.setPopup({ popup: 'popup.html' });
```