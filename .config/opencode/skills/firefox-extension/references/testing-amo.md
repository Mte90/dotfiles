# Testing, Debugging & AMO Submission

> This reference file is loaded on demand from ../SKILL.md.

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