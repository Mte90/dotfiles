# Testing, Debugging & Migration

> This reference file is loaded on demand from ../SKILL.md for testing, debugging, and migration documentation.

## Testing & Debugging

### Temporary Installation

1. Open Thunderbird
2. Go to **Tools → Add-ons and Themes**
3. Click gear icon → **Debug Add-ons**
4. Click **Load Temporary Add-on**
5. Select `manifest.json`

**Note:** Temporary add-ons are removed when Thunderbird closes.

### Debugging Tools

**Access Developer Tools:**
1. In Debug Add-ons page
2. Click "Inspect" next to extension
3. Console opens for background scripts

**Debug specific components:**
- **Background:** Console in debug page
- **Popup:** Right-click popup → "Inspect"
- **Content scripts:** Message window DevTools

### Debug Commands

```javascript
// Check manifest
messenger.runtime.getManifest();

// Check permissions
messenger.permissions.contains({ permissions: ['messagesRead'] });

// Get extension URL
messenger.runtime.getURL('/path/to/resource');

// Reload extension
messenger.runtime.reload();

// Check last error
if (messenger.runtime.lastError) {
  console.error(messenger.runtime.lastError);
}
```

### Testing Workflow

```bash
# 1. Create extension
# 2. Load temporarily in Thunderbird
# 3. Test functionality
# 4. Check console for errors
# 5. Fix issues
# 6. Reload extension (click Reload in debug page)
# 7. Repeat until working
# 8. Build and submit to ATN
```

### Logging

```javascript
// Use console for debugging
console.log("Extension loaded");
console.log("Message received:", message);

// Structured logging
console.table([
  { id: 1, name: "First" },
  { id: 2, name: "Second" }
]);

// Timing
console.time("operation");
// ... operation
console.timeEnd("operation");
```

## Migration from Legacy Extensions

### Key Changes in Thunderbird 128

| Change | Impact |
|--------|--------|
| `Services.jsm` removed | Use `ChromeUtils.importESModule()` |
| JSM → ES modules | Use `.sys.mjs` files |
| `mailWindowOverlay.js` removed | Use MailExtension APIs |
| Overlay extensions deprecated | Use MailExtensions only |

### Migration Checklist

- [ ] Convert to WebExtension/MailExtension format
- [ ] Replace XUL overlays with HTML/CSS
- [ ] Replace `Services.jsm` with ES modules
- [ ] Use `messenger.*` APIs instead of direct XPCOM
- [ ] Implement Experiment APIs for missing functionality
- [ ] Test thoroughly on Thunderbird 128+

### Common Migration Patterns

**Before (Legacy):**
```javascript
Components.utils.import("resource:///modules/mailServices.js");
MailServices.compose.OpenComposeWindow(...);
```

**After (MailExtension):**
```javascript
messenger.compose.beginNew({
  to: ["recipient@example.com"],
  subject: "Hello"
});
```

## Troubleshooting

### Common Issues

| Error | Cause | Solution |
|-------|-------|----------|
| `messenger is not defined` | Script not in extension context | Check manifest script paths |
| Permission denied | Missing permission | Add to manifest permissions |
| API not available | Wrong Thunderbird version | Check `strict_min_version` |
| Contacts API fails in MV3 | Using old API | Use `messenger.addressBooks.contacts.*` |
| Experiment not loading | Path error | Check schema and implementation paths |
| Message scripts not working | Limited API access | Only runtime/storage/i18n available |

### Debug Commands

```javascript
// Check Thunderbird version
const info = await messenger.runtime.getBrowserInfo();
console.log(info.version);

// Check platform info
const platform = await messenger.runtime.getPlatformInfo();
console.log(platform.os, platform.arch);

// List all listeners
// (Add logging to all addListener calls)

// Check storage
const all = await messenger.storage.local.get(null);
console.log("Stored data:", all);
```