---
name: firefox-extension
description: Use when developing Firefox WebExtensions - Manifest V2/V3 configuration, WebExtension APIs, content security policy, web-ext CLI, cross-browser support with the polyfill, AMO submission, or debugging extensions
metadata:
  author: mte90
  version: 2.0.0
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

> See `references/security-crossbrowser.md` for full CSP reference.

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

### Performance

- Use `browser.tabs.query()` with specific filters
- Debounce frequent operations
- Cache storage API results
- Use `alarms` API instead of `setInterval` in background

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

## Deep Dives

Load these reference files on demand for detailed information:

- **WebExtension APIs** (51 namespaces, core patterns, Firefox-specific): `references/apis.md`
- **Security & Cross-Browser** (CSP, webextension-polyfill): `references/security-crossbrowser.md`
- **Testing & AMO** (debugging, troubleshooting, submission): `references/testing-amo.md`

## References

- [MDN WebExtensions](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions)
- [Extension Workshop](https://extensionworkshop.com/)
- [Manifest V3 Migration](https://extensionworkshop.com/documentation/develop/manifest-v3-migration-guide/)
- [web-ext CLI Reference](https://extensionworkshop.com/documentation/develop/web-ext-command-reference/)
- [AMO Developer Hub](https://addons.mozilla.org/developers/)
- [webextension-polyfill](https://github.com/mozilla/webextension-polyfill)
- [Browser Compatibility](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Browser_support_for_JavaScript_APIs)