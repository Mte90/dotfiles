---
name: firefox-extension
description: Comprehensive guide for developing WebExtensions (browser extensions) for Mozilla Firefox, including Manifest V2/V3 configuration, all WebExtension APIs, security practices, web-ext CLI, and AMO submission.
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - firefox
    - webextension
    - browser-extension
    - mozilla
    - amo
    - manifest-v3
---

# Firefox WebExtension Development

Complete reference for building, testing, and publishing browser extensions for Mozilla Firefox.

## Overview

Firefox extensions use the WebExtensions API with the `browser.*` namespace (Promise-based natively). Firefox supports both Manifest V2 and V3, with MV2 NOT deprecated (unlike Chrome).

**Key Characteristics:**
- Global namespace: `browser` (Promise-based)
- Both MV2 and MV3 supported
- Firefox-specific APIs: `sidebarAction`, `userScripts`, `contextualIdentities`, `protocol_handlers`
- Submission via AMO (addons.mozilla.org)

## Manifest Structure

### Manifest V3 (Recommended, Firefox 109+)

```json
{
  "manifest_version": 3,
  "name": "Extension Name",
  "version": "1.0.0",
  "description": "Brief description",

  "browser_specific_settings": {
    "gecko": {
      "id": "extension@example.com",
      "strict_min_version": "109.0"
    },
    "gecko_android": {
      "strict_min_version": "109.0"
    }
  },

  "background": {
    "service_worker": "background.js",
    "type": "module"
  },

  "action": {
    "default_popup": "popup.html",
    "default_icon": {
      "16": "icons/icon-16.png",
      "48": "icons/icon-48.png",
      "96": "icons/icon-96.png"
    },
    "default_title": "Extension Title"
  },

  "content_scripts": [
    {
      "matches": ["https://*/*"],
      "js": ["content.js"],
      "css": ["styles.css"],
      "run_at": "document_idle"
    }
  ],

  "permissions": ["storage", "activeTab"],
  "host_permissions": ["https://api.example.com/*"],

  "content_security_policy": {
    "extension_pages": "script-src 'self'; object-src 'self';"
  }
}
```

### Manifest V2 (Still Supported)

```json
{
  "manifest_version": 2,
  "name": "Extension Name",
  "version": "1.0.0",

  "browser_specific_settings": {
    "gecko": {
      "id": "extension@example.com",
      "strict_min_version": "78.0"
    }
  },

  "background": {
    "scripts": ["background.js"],
    "persistent": false
  },

  "browser_action": {
    "default_popup": "popup.html",
    "default_icon": "icons/icon-48.png"
  },

  "permissions": ["storage", "activeTab", "https://*/*"]
}
```

### MV2 vs MV3 Key Differences

| Feature | MV2 | MV3 |
|---------|-----|-----|
| Toolbar button | `browser_action` | `action` |
| Background | `background.scripts` / `page` | `background.service_worker` |
| Host permissions | In `permissions` | Separate `host_permissions` |
| Default CSP | `script-src 'self'; object-src 'self';` | `script-src 'self'; upgrade-insecure-requests;` |
| Request blocking | `webRequest.onBeforeRequest` | `declarativeNetRequest` |

### All Manifest Keys Reference

**Metadata:**
- `name` (required) - Extension name
- `version` (required) - Version string (e.g., "1.0.0")
- `description` - Short description
- `author` - Author name
- `homepage_url` - Extension homepage
- `icons` - Extension icons object

**Firefox-Specific:**
- `browser_specific_settings.gecko.id` - **Required for AMO**
- `browser_specific_settings.gecko.strict_min_version` - Minimum Firefox version
- `browser_specific_settings.gecko.strict_max_version` - Maximum Firefox version
- `browser_specific_settings.gecko_android` - Android-specific settings

**Background & Scripts:**
- `background` - Service worker (MV3) or scripts/page (MV2)
- `content_scripts` - Scripts injected into pages
- `userScripts` - User script registration (Firefox-only)
- `declarative_net_request` - Rule-based request modification

**UI Components:**
- `action` (MV3) / `browser_action` (MV2) - Toolbar button
- `page_action` - Address bar button
- `sidebar_action` - Sidebar panel (Firefox-only)
- `options_ui` - Options page configuration
- `devtools_page` - DevTools extension page

**Permissions:**
- `permissions` - API permissions
- `host_permissions` (MV3) - Host access
- `optional_permissions` - Optional API permissions
- `optional_host_permissions` - Optional host access

**Other:**
- `commands` - Keyboard shortcuts
- `omnibox` - Address bar integration
- `web_accessible_resources` - Resources accessible from pages
- `protocol_handlers` - Custom protocol handlers
- `chrome_settings_overrides` - Override homepage/search
- `chrome_url_overrides` - Override new tab/bookmarks

## WebExtension APIs

### Complete API Namespace List (51 APIs)

| API | Permission | Description |
|-----|------------|-------------|
| `action` | - | Toolbar button (MV3) |
| `alarms` | `alarms` | Schedule code execution |
| `bookmarks` | `bookmarks` | Bookmark management |
| `browserAction` | - | Toolbar button (MV2) |
| `browserSettings` | - | Browser settings |
| `browsingData` | `browsingData` | Clear browsing data |
| `clipboard` | `clipboardWrite` | Clipboard access |
| `commands` | - | Keyboard shortcuts |
| `contentScripts` | - | Register content scripts |
| `contextualIdentities` | `contextualIdentities` | Container tabs (Firefox-only) |
| `cookies` | `cookies` | Cookie management |
| `declarativeNetRequest` | `declarativeNetRequest` | Rule-based request blocking |
| `devtools` | `devtools` | DevTools integration |
| `dns` | `dns` | DNS resolution |
| `downloads` | `downloads` | Download management |
| `events` | - | Common event types |
| `extension` | - | Extension utilities |
| `find` | `find` | Find text in pages |
| `history` | `history` | Browser history |
| `i18n` | - | Internationalization |
| `identity` | `identity` | OAuth2 authentication |
| `idle` | `idle` | Idle state detection |
| `management` | `management` | Installed add-ons info |
| `menus` | `menus` | Context menu items |
| `notifications` | `notifications` | System notifications |
| `omnibox` | - | Address bar suggestions |
| `pageAction` | - | Address bar button (MV2) |
| `permissions` | - | Runtime permissions |
| `pkcs11` | `pkcs11` | PKCS#11 modules |
| `privacy` | `privacy` | Privacy settings |
| `proxy` | `proxy` | Request proxying |
| `runtime` | - | Extension runtime |
| `scripting` | `scripting` | Inject scripts/CSS (MV3) |
| `search` | `search` | Search engines |
| `sessions` | `sessions` | Closed tabs/windows |
| `sidebarAction` | - | Sidebar (Firefox-only) |
| `storage` | `storage` | Local/managed storage |
| `tabGroups` | `tabGroups` | Tab groups |
| `tabs` | `tabs` | Tab management |
| `theme` | `theme` | Theme API |
| `topSites` | `topSites` | Frequently visited |
| `userScripts` | `userScripts` | User scripts (Firefox-only) |
| `webNavigation` | `webNavigation` | Navigation events |
| `webRequest` | `webRequest` | Request interception |
| `windows` | - | Window management |

### Core API Usage Patterns

**Tabs API:**
```javascript
// Query tabs
const tabs = await browser.tabs.query({ active: true, currentWindow: true });

// Create tab
const tab = await browser.tabs.create({ url: 'https://example.com' });

// Update tab
await browser.tabs.update(tabId, { active: true });

// Send message to tab
await browser.tabs.sendMessage(tabId, { action: 'update' });

// Execute script (MV3)
await browser.scripting.executeScript({
  target: { tabId },
  files: ['content.js']
});
```

**Storage API:**
```javascript
// Save data
await browser.storage.local.set({ key: 'value', settings: config });

// Get data
const { key, settings } = await browser.storage.local.get(['key', 'settings']);

// Remove data
await browser.storage.local.remove('key');

// Clear all
await browser.storage.local.clear();

// Listen for changes
browser.storage.onChanged.addListener((changes, area) => {
  if (changes.key) {
    console.log('Old:', changes.key.oldValue, 'New:', changes.key.newValue);
  }
});
```

**Runtime Messaging:**
```javascript
// Content script → Background
const response = await browser.runtime.sendMessage({ action: 'getData' });

// Background listener
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === 'getData') {
    return Promise.resolve({ data: 'response' });
  }
});

// Background → Content script
browser.tabs.sendMessage(tabId, { action: 'update' });

// External messaging (from web pages)
browser.runtime.onMessageExternal.addListener((message, sender) => {
  if (sender.id === 'allowed-extension-id') {
    // Handle message
  }
});
```

**Context Menus:**
```javascript
// Create context menu
browser.menus.create({
  id: 'my-menu',
  title: 'My Menu Item',
  contexts: ['selection']
});

// Handle click
browser.menus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === 'my-menu') {
    console.log('Selected:', info.selectionText);
  }
});
```

**Alarms:**
```javascript
// Create alarm
browser.alarms.create('my-alarm', { delayInMinutes: 1, periodInMinutes: 5 });

// Handle alarm
browser.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === 'my-alarm') {
    // Do work
  }
});
```

**Notifications:**
```javascript
// Show notification
browser.notifications.create({
  type: 'basic',
  iconUrl: 'icon.png',
  title: 'Title',
  message: 'Message'
});
```

### Firefox-Specific APIs

**Sidebar Action:**
```javascript
// Toggle sidebar
browser.sidebarAction.open();
browser.sidebarAction.close();

// Set panel
await browser.sidebarAction.setPanel({ panel: 'sidebar.html' });
```

**Container Tabs (Contextual Identities):**
```javascript
// List containers
const containers = await browser.contextualIdentities.query({});

// Create container
const container = await browser.contextualIdentities.create({
  name: 'Work',
  color: 'blue',
  icon: 'briefcase'
});

// Create tab in container
await browser.tabs.create({
  url: 'https://work.example.com',
  cookieStoreId: container.cookieStoreId
});
```

**User Scripts:**
```javascript
// Register user script
await browser.userScripts.register([{
  js: [{ file: 'script.js' }],
  matches: ['*://example.com/*'],
  runAt: 'document_start'
}]);
```

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

## web-ext CLI Reference

### Installation

```bash
npm install -g web-ext
```

### Commands

**Run extension (development):**
```bash
web-ext run                                    # Default Firefox
web-ext run --firefox-path /path/to/firefox    # Specific Firefox
web-ext run --target firefox-android           # Android
web-ext run --profile-create-new               # Clean profile
web-ext run --start-url https://example.com    # Start URL
web-ext run --verbose                          # Verbose output
web-ext run --no-reload                        # Disable auto-reload
```

**Lint extension:**
```bash
web-ext lint                   # Validate manifest and code
web-ext lint --warnings-as-errors
web-ext lint --self-hosted     # Skip AMO-specific checks
```

**Build extension:**
```bash
web-ext build                  # Create .zip in web-ext-artifacts/
web-ext build --source-dir ./src
web-ext build --artifacts-dir ./dist
```

**Sign extension:**
```bash
web-ext sign --api-key $KEY --api-secret $SECRET
web-ext sign --channel listed      # Public on AMO
web-ext sign --channel unlisted    # Direct download
```

**Other commands:**
```bash
web-ext docs       # Open documentation
web-ext dump-config  # Show configuration
```

### Configuration File (.web-ext-config.js)

```javascript
module.exports = {
  sourceDir: './src',
  artifactsDir: './dist',

  run: {
    firefox: '/Applications/Firefox.app/Contents/MacOS/firefox',
    startUrl: 'https://example.com',
    pref: ['extensions.webextensions.debug=true']
  },

  build: {
    overwriteDest: true
  },

  sign: {
    apiKey: process.env.AMO_API_KEY,
    apiSecret: process.env.AMO_API_SECRET,
    channel: 'listed'
  }
};
```

### Environment Variables

```bash
WEB_EXT_API_KEY=your_key
WEB_EXT_API_SECRET=your_secret
WEB_EXT_SOURCE_DIR=./src
WEB_EXT_ARTIFACTS_DIR=./dist
WEB_EXT_FIREFOX=/path/to/firefox
```

## AMO Submission Process

### Pre-Submission Checklist

- [ ] Extension ID in `browser_specific_settings.gecko.id`
- [ ] `web-ext lint` passes with no errors
- [ ] All permissions are necessary and documented
- [ ] Privacy policy included (if collecting data)
- [ ] No obfuscated code
- [ ] Source code available (if using build tools)
- [ ] Icons: 48x48 and 96x96 minimum
- [ ] Screenshots: minimum 464x200px
- [ ] Description is clear and accurate

### Submission Steps

1. **Build extension:**
   ```bash
   web-ext build
   ```

2. **Create developer account:**
   - Visit https://addons.mozilla.org/developers/
   - Sign up and complete profile

3. **Submit:**
   - Go to Developer Hub → "Submit a New Add-on"
   - Upload `.zip` from `web-ext build`
   - Choose distribution: Listed (public) or Unlisted (direct)

4. **Fill listing:**
   - Name, description, categories
   - Screenshots, icons
   - Privacy policy URL (if collecting data)
   - Support email/URL

5. **Review process:**
   - Automated validation: 5-15 minutes
   - Human review: 1-7 days for listed extensions
   - Respond to reviewer comments promptly

### Common Rejection Reasons

| Reason | Solution |
|--------|----------|
| Remote code execution | Package all scripts locally |
| Unnecessary permissions | Remove unused permissions |
| Obfuscated code | Provide source code |
| Missing privacy policy | Add policy if collecting data |
| Unclear functionality | Improve description |
| CSP violations | Fix CSP to not allow remote scripts |
| Hidden functionality | Disclose all features |

### Data Collection Requirements

If extension collects/transmits user data, privacy policy must disclose:
- What data is collected
- How it's transmitted
- Purpose of collection
- User consent mechanism
- Data retention policy

## Testing & Debugging

### Development Workflow

```bash
# Start development
web-ext run --verbose

# Auto-reloads on file changes
# Access via about:debugging
```

### Debugging Tools

**Access debugging:**
1. Open `about:debugging#/runtime/this-firefox`
2. Click "Inspect" next to extension

**Debug components:**
- **Background:** Console in debugging page
- **Popup:** Right-click popup → "Inspect"
- **Content scripts:** Regular page DevTools Console
- **Options page:** Right-click options → "Inspect"

### Debugging Commands

```javascript
// Check manifest
browser.runtime.getManifest();

// Check permissions
browser.permissions.contains({ permissions: ['tabs'] });

// Get extension URL
browser.runtime.getURL('/path/to/resource');

// Check last error
if (browser.runtime.lastError) {
  console.error(browser.runtime.lastError);
}

// Reload extension programmatically
browser.runtime.reload();
```

### Testing Strategies

**Unit Testing (Jest):**
```javascript
import { mockBrowser } from 'webextension-pockito';

describe('Extension', () => {
  beforeEach(() => mockBrowser.reset());

  test('storage', async () => {
    await browser.storage.local.set({ key: 'value' });
    const result = await browser.storage.local.get('key');
    expect(result.key).toBe('value');
  });
});
```

**Integration Testing (Selenium):**
```javascript
const { Builder } = require('selenium-webdriver');
const firefox = require('selenium-webdriver/firefox');

const driver = await new Builder()
  .forBrowser('firefox')
  .setFirefoxOptions(new firefox.Options()
    .setPreference('extensions.autoDisableScopes', 0))
  .build();
```

## Best Practices

### Background Service Worker (MV3)

```javascript
// Keep service worker alive briefly
let keepAlive;

browser.runtime.onMessage.addListener((msg) => {
  clearTimeout(keepAlive);
  keepAlive = setTimeout(() => {}, 25000);
  return handleMessage(msg);
});
```

### Error Handling

```javascript
async function safeAsync(fn) {
  try {
    return await fn();
  } catch (error) {
    console.error('Error:', error);
    return { error: error.message };
  }
}
```

### Cross-Browser Compatibility

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

### Performance

- Use `browser.tabs.query()` with specific filters
- Debounce frequent operations
- Cache storage API results
- Use `alarms` API instead of `setInterval` in background

## Troubleshooting

### Common Issues

| Error | Cause | Solution |
|-------|-------|----------|
| `browser is not defined` | Script not in extension context | Check manifest script paths |
| Permission denied | Missing permission | Add to manifest permissions |
| CSP violation | Remote script | Move script to extension package |
| Service worker terminated | Long operation | Use alarms API, avoid blocking |
| `webRequest` not blocking | MV3 limitation | Use `declarativeNetRequest` |
| ID mismatch | Different IDs | Set consistent ID in manifest |

### Debug Commands

```bash
# Validate manifest
web-ext lint --verbose

# Run with debug prefs
web-ext run --pref extensions.webextensions.debug=true

# Test in clean profile
web-ext run --profile-create-new

# Check specific Firefox
web-ext run --firefox /path/to/firefox-beta
```

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

## File Structure Template

```
my-extension/
├── manifest.json
├── background.js
├── content.js
├── popup.html
├── popup.js
├── options.html
├── options.js
├── browser-polyfill.js
├── styles/
│   ├── popup.css
│   └── content.css
├── icons/
│   ├── icon-16.png
│   ├── icon-32.png
│   ├── icon-48.png
│   └── icon-96.png
├── _locales/
│   ├── en/
│   │   └── messages.json
│   └── it/
│       └── messages.json
├── .web-ext-config.js
├── package.json
└── README.md
```

## References

- [MDN WebExtensions](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions)
- [Extension Workshop](https://extensionworkshop.com/)
- [Manifest V3 Migration](https://extensionworkshop.com/documentation/develop/manifest-v3-migration-guide/)
- [web-ext CLI Reference](https://extensionworkshop.com/documentation/develop/web-ext-command-reference/)
- [AMO Developer Hub](https://addons.mozilla.org/developers/)
- [webextension-polyfill](https://github.com/mozilla/webextension-polyfill)
- [Browser Compatibility](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Browser_support_for_JavaScript_APIs)
