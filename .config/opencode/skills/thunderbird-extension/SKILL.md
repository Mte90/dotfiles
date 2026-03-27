---
name: thunderbird-extension
description: Comprehensive guide for developing MailExtensions for Mozilla Thunderbird, including Manifest V2/V3 configuration, all messenger.* APIs, UI actions, Experiment APIs, and ATN submission.
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - thunderbird
    - mailextension
    - email-extension
    - mozilla
    - atn
    - messenger-api
---

# Thunderbird MailExtension Development

Complete reference for building, testing, and publishing email extensions for Mozilla Thunderbird.

## Overview

Thunderbird extensions use the MailExtension API (based on WebExtensions) with the `messenger.*` namespace. Thunderbird supports both Manifest V2 and V3 since version 128.

**Key Characteristics:**
- Global namespace: `messenger` (Thunderbird-specific) + `browser` (standard WebExtensions)
- Both MV2 and MV3 supported (Thunderbird 128+)
- Thunderbird-specific APIs: `accounts`, `addressBooks`, `compose`, `folders`, `mailTabs`, `messages`, `messageDisplay`
- Submission via ATN (addons.thunderbird.net)

## Version Requirements

| Version | Status | Notes |
|---------|--------|-------|
| 128.x (ESR) | Current | Full MV2 + MV3 support |
| 115.x | Legacy | End of support |
| < 115 | Deprecated | Not recommended |

**Best Practice:** Set `strict_min_version` to "128.0"

## Manifest Structure

### Manifest V3 (Recommended, Thunderbird 128+)

```json
{
  "manifest_version": 3,
  "name": "My Thunderbird Extension",
  "version": "1.0.0",
  "description": "Extension description",
  "author": "Your Name",

  "browser_specific_settings": {
    "gecko": {
      "id": "extension@example.com",
      "strict_min_version": "128.0"
    }
  },

  "icons": {
    "16": "icons/icon-16.png",
    "32": "icons/icon-32.png",
    "64": "icons/icon-64.png"
  },

  "background": {
    "service_worker": "background.js",
    "type": "module"
  },

  "action": {
    "default_popup": "popup.html",
    "default_title": "My Extension",
    "default_icon": "icons/icon-32.png"
  },

  "permissions": [
    "storage",
    "messagesRead",
    "addressBooks"
  ]
}
```

### Manifest V2 (Still Supported)

```json
{
  "manifest_version": 2,
  "name": "My Thunderbird Extension",
  "version": "1.0.0",
  "author": "Your Name",

  "browser_specific_settings": {
    "gecko": {
      "id": "extension@example.com",
      "strict_min_version": "128.0"
    }
  },

  "background": {
    "scripts": ["background.js"],
    "type": "module"
  },

  "browser_action": {
    "default_popup": "popup.html",
    "default_title": "My Extension"
  },

  "permissions": [
    "storage",
    "messagesRead",
    "addressBooks"
  ]
}
```

### MV2 vs MV3 Key Differences

| Feature | MV2 | MV3 |
|---------|-----|-----|
| Toolbar button | `browser_action` | `action` |
| Background | `background.scripts` | `background.service_worker` |
| Execute script | `tabs.executeScript` | `messenger.scripting.messageDisplay.executeScript` |
| Compose scripts | `composeScripts` | `scripting.compose` |
| Contacts API | `messenger.contacts.*` | `messenger.addressBooks.contacts.*` (vCard only) |

### All Manifest Keys Reference

**Metadata:**
- `name` (required) - Extension name
- `version` (required) - Version string
- `description` - Short description
- `author` - Author name
- `icons` - Extension icons

**Thunderbird-Specific:**
- `browser_specific_settings.gecko.id` - **Required for ATN**
- `browser_specific_settings.gecko.strict_min_version` - Minimum version

**Background & Scripts:**
- `background` - Service worker (MV3) or scripts (MV2)
- `message_display_scripts` (MV2) - Scripts for displayed messages

**UI Components:**
- `action` (MV3) / `browser_action` (MV2) - Main toolbar button
- `compose_action` - Compose window toolbar button
- `message_display_action` - Message view toolbar button

**Permissions:**
- `permissions` - API permissions
- `experiment_apis` - Custom Experiment APIs

**Other:**
- `commands` - Keyboard shortcuts
- `options_ui` - Options page

## Messenger APIs

### Complete API Namespace List

| API | Permission | Description |
|-----|------------|-------------|
| `accounts` | `accountsRead` | Email accounts and identities |
| `addressBooks` | `addressBooks` | Address books management |
| `compose` | `compose` | Compose windows and events |
| `contacts` | `addressBooks` | Contact management (use addressBooks.contacts in MV3) |
| `folders` | `accountsFolders` | Mail folders management |
| `identities` | `accountsIdentities` | Account identities |
| `mailTabs` | - | Main Thunderbird window |
| `messages` | `messagesRead`, `messagesMove` | Message operations |
| `messageDisplay` | `messagesRead` | Displayed message events |
| `messageDisplayAction` | - | Message toolbar button |
| `tabs` | - | Tab management |
| `windows` | - | Window management |
| `runtime` | - | Extension runtime |
| `storage` | `storage` | Data storage |
| `i18n` | - | Internationalization |

### Standard WebExtension APIs (also available)

- `browser.runtime` - Messaging, lifecycle
- `browser.storage` - Data persistence
- `browser.i18n` - Localization
- `browser.tabs` - Tab management
- `browser.windows` - Window management
- `browser.commands` - Keyboard shortcuts

### Accounts API

```javascript
// List all accounts
const accounts = await messenger.accounts.list();

// Get specific account
const account = await messenger.accounts.get(accountId);

// Get account details
console.log(account.name, account.type, account.identities);

// List folders in account
const folders = await messenger.folders.getSubFolders(account);
```

### Messages API

```javascript
// List messages in folder
const messages = await messenger.messages.list(folderId);

// Get specific message
const message = await messenger.messages.get(messageId);

// Message properties
console.log(message.subject, message.from, message.to, message.date);

// Get full message with body
const fullMessage = await messenger.messages.getFull(messageId);
console.log(fullMessage.parts[0].body);

// Query messages
const results = await messenger.messages.query({
  from: "sender@example.com",
  unread: true,
  limit: 50
});

// Move messages
await messenger.messages.move([messageId], destinationFolderId);

// Copy messages
await messenger.messages.copy([messageId], destinationFolderId);

// Delete messages
await messenger.messages.delete([messageId], true); // true = skip trash

// Mark as read/unread
await messenger.messages.update(messageId, { read: true });

// Archive messages
await messenger.messages.archive([messageId]);

// Import message
const importedId = await messenger.messages.import(
  file,  // File object
  folderId,
  { read: true, flagged: false }
);
```

### Folders API

```javascript
// Get folder
const folder = await messenger.folders.get(folderId);

// List subfolders
const subfolders = await messenger.folders.getSubFolders(parentFolder);

// Create folder
const newFolder = await messenger.folders.create(parentAccountId, "New Folder");

// Rename folder
await messenger.folders.rename(folderId, "New Name");

// Delete folder
await messenger.folders.delete(folderId);

// Mark folder as read
await messenger.folders.markAsRead(folderId);

// Get folder properties
console.log(folder.name, folder.path, folder.unreadCount, folder.totalCount);
```

### Address Books & Contacts API (MV3)

```javascript
// List address books
const addressBooks = await messenger.addressBooks.list();

// Get address book
const book = await messenger.addressBooks.get(addressBookId);

// Create contact (vCard format)
const contactId = await messenger.addressBooks.contacts.create(addressBookId, {
  vCard: `BEGIN:VCARD
VERSION:4.0
FN:John Doe
EMAIL:john@example.com
TEL:+1-555-0100
END:VCARD`
});

// Get contact
const contact = await messenger.addressBooks.contacts.get(contactId);
console.log(contact.vCard);

// Update contact
await messenger.addressBooks.contacts.update(contactId, {
  vCard: updatedVCard
});

// Delete contact
await messenger.addressBooks.contacts.delete(contactId);

// Quick search contacts
const results = await messenger.addressBooks.contacts.quickSearch("john");

// Search in specific address book
const results = await messenger.addressBooks.contacts.query({
  addressBookId: addressBookId,
  searchText: "john"
});

// Create mailing list
const listId = await messenger.addressBooks.mailingLists.create(addressBookId, {
  name: "Team",
  nickName: "team",
  description: "Team members"
});

// Add contact to mailing list
await messenger.addressBooks.mailingLists.addMember(listId, contactId);
```

### Compose API

```javascript
// Open compose window
const tab = await messenger.compose.beginNew({
  to: ["recipient@example.com"],
  cc: ["cc@example.com"],
  subject: "Hello",
  body: "Message content",
  isPlainText: false
});

// Compose with attachments
await messenger.compose.beginNew({
  to: ["recipient@example.com"],
  attachments: [{
    file: new File(["content"], "file.txt", { type: "text/plain" })
  }]
});

// Reply to message
await messenger.compose.beginReply(messageId, "replyToAll");

// Forward message
await messenger.compose.beginForward(messageId, "forwardInline");

// Get compose details
const details = await messenger.compose.getComposeDetails(tabId);
console.log(details.to, details.subject, details.body);

// Set compose details
await messenger.compose.setComposeDetails(tabId, {
  subject: "Updated Subject"
});

// Listen for compose events
messenger.compose.onBeforeSend.addListener((tab, details) => {
  // Modify message before sending
  details.body += "\n\n-- Sent via MyExtension";
  return { details };
});

// Listen for compose window open
messenger.compose.onComposeCreated.addListener((tab) => {
  console.log("Compose window created:", tab.id);
});
```

### Message Display API

```javascript
// Listen for message displayed
messenger.messageDisplay.onMessageDisplayed.addListener((tab, message) => {
  console.log("Message displayed:", message.subject);
});

// Get displayed message
const message = await messenger.messageDisplay.getDisplayedMessage(tabId);

// Listen for messages displayed (batch)
messenger.messageDisplay.onMessagesDisplayed.addListener((tab, messages) => {
  console.log(`${messages.length} messages displayed`);
});
```

### Mail Tabs API

```javascript
// Get current mail tab
const mailTab = await messenger.mailTabs.getCurrent();

// Get displayed folder
const folder = await messenger.mailTabs.getDisplayedFolder(tabId);

// Set displayed folder
await messenger.mailTabs.update(tabId, {
  displayedFolderId: folderId
});

// Get selected messages
const selection = await messenger.mailTabs.getSelectedMessages(tabId);

// Listen for folder changes
messenger.mailTabs.onSelectedMessagesChanged.addListener((tab, selection) => {
  console.log("Selection changed:", selection.messages);
});
```

## UI Actions (Toolbar Buttons)

### Main Toolbar (action / browser_action)

```json
{
  "action": {
    "default_popup": "popup.html",
    "default_title": "My Extension",
    "default_icon": {
      "16": "icons/icon-16.png",
      "32": "icons/icon-32.png"
    }
  }
}
```

```javascript
// Listen for clicks (if no popup)
messenger.action.onClicked.addListener((tab) => {
  console.log("Action clicked");
});

// Update badge
await messenger.action.setBadgeText({ text: "5" });
await messenger.action.setBadgeBackgroundColor({ color: "#ff0000" });

// Update icon
await messenger.action.setIcon({ path: "icons/icon-active.png" });
```

### Compose Window (compose_action)

```json
{
  "compose_action": {
    "default_popup": "compose_popup.html",
    "default_title": "Compose Tool",
    "default_icon": "icons/compose-icon.png"
  }
}
```

```javascript
// Listen for clicks in compose window
messenger.composeAction.onClicked.addListener((tab) => {
  const details = await messenger.compose.getComposeDetails(tab.id);
  console.log("Compose action clicked:", details.subject);
});
```

### Message Display (message_display_action)

```json
{
  "message_display_action": {
    "default_popup": "message_popup.html",
    "default_title": "Message Tool",
    "default_icon": "icons/message-icon.png"
  }
}
```

```javascript
// Listen for clicks on message
messenger.messageDisplayAction.onClicked.addListener(async (tab) => {
  const message = await messenger.messageDisplay.getDisplayedMessage(tab.id);
  console.log("Message action clicked:", message.subject);
});
```

## Message Display Scripts

### MV2 Configuration

```json
{
  "message_display_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["message_content.js"],
      "css": ["message_styles.css"]
    }
  ]
}
```

### MV3 Configuration

```javascript
// In background.js
await messenger.scripting.messageDisplay.executeScript({
  tabId: tabId,
  files: ["message_content.js"]
});
```

### Available APIs in Display Scripts

Limited APIs available:
- `messenger.runtime.connect()`, `messenger.runtime.sendMessage()`
- `messenger.runtime.onConnect`, `messenger.runtime.onMessage`
- `messenger.i18n.getMessage()`, `messenger.i18n.getAcceptLanguages()`
- `messenger.storage.*`

```javascript
// message_content.js
// Send message to background
const response = await messenger.runtime.sendMessage({
  action: "processMessage",
  content: document.body.innerText
});

// Listen for messages from background
messenger.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === "highlight") {
    // Highlight text in message
    document.body.innerHTML = document.body.innerHTML.replace(
      message.text,
      `<mark>${message.text}</mark>`
    );
  }
});
```

## Experiment APIs

Experiments provide access to Thunderbird internals not exposed via WebExtension APIs.

### When to Use Experiments

- Need access to internal Thunderbird services
- API functionality not yet available in MailExtension API
- Complex integrations with core features

**⚠️ Warning:** Experiments grant full, unrestricted access. Users see:
> "Have full, unrestricted access to Thunderbird, and your computer"

### Experiment Structure

```json
{
  "experiment_apis": {
    "myapi": {
      "schema": "api/myapi/schema.json",
      "parent": {
        "scopes": ["addon_parent"],
        "paths": [["myapi"]],
        "script": "api/myapi/implementation.js",
        "events": ["startup"]
      }
    }
  }
}
```

### Schema Definition (schema.json)

```json
[
  {
    "namespace": "myapi",
    "functions": [
      {
        "name": "doSomething",
        "type": "function",
        "async": true,
        "parameters": [
          {
            "name": "param",
            "type": "string"
          }
        ]
      }
    ],
    "events": [
      {
        "name": "onSomething",
        "type": "function"
      }
    ]
  }
]
```

### Implementation (implementation.js)

```javascript
class MyAPI extends ExtensionAPI {
  getAPI(context) {
    return {
      myapi: {
        async doSomething(param) {
          // Access Thunderbird internals via Services
          const { Services } = ChromeUtils.import(
            "resource://gre/modules/Services.jsm"
          );
          
          // Do something with internal APIs
          return Services.someService.process(param);
        },

        onSomething: new ExtensionCommon.EventManager({
          context,
          name: "myapi.onSomething",
          register: (fire) => {
            const callback = (data) => fire.async(data);
            
            // Register with internal service
            someInternalService.addListener(callback);
            
            return () => {
              someInternalService.removeListener(callback);
            };
          }
        }).api()
      }
    };
  }

  onStartup() {
    console.log("Extension starting up");
  }

  onShutdown(reason) {
    console.log("Extension shutting down:", reason);
    // Cleanup required
    Services.obs.notifyObservers(null, "startupcache-invalidate", null);
  }
}
```

### Using Experiment API

```javascript
// In background.js
const result = await messenger.myapi.doSomething("param");

// Listen for experiment events
messenger.myapi.onSomething.addListener((data) => {
  console.log("Event received:", data);
});
```

### Available Community Experiments

| Experiment | Description | Repository |
|------------|-------------|------------|
| Calendar | Calendar API | [webext-experiments/calendar](https://github.com/thunderbird/webext-experiments/tree/main/calendar) |
| FileSystem | File system access | [webext-support/FileSystem](https://github.com/thunderbird/webext-support/tree/master/experiments/FileSystem) |
| LegacyPrefs | Preferences access | [webext-support/LegacyPrefs](https://github.com/thunderbird/webext-support/tree/master/experiments/LegacyPrefs) |
| NotificationBox | Notification bars | [webext-experiments/NotificationBox](https://github.com/thunderbird/webext-experiments/tree/main/NotificationBox) |
| WindowListener | Window events | [webext-support/WindowListener](https://github.com/thunderbird/webext-support/tree/master/experiments/WindowListener) |

## ATN Submission Process

### Pre-Submission Checklist

- [ ] Extension ID in `browser_specific_settings.gecko.id`
- [ ] Works with Thunderbird 128+
- [ ] All permissions are necessary
- [ ] Privacy policy included (if collecting data)
- [ ] No obfuscated code
- [ ] Source code available (if using build tools)
- [ ] Icons: 32x32 and 64x64 minimum
- [ ] Screenshots for listed extensions
- [ ] Clear description

### Submission Steps

1. **Build extension:**
   ```bash
   zip -r extension.zip manifest.json background.js icons/ popup.html
   ```

2. **Create developer account:**
   - Visit https://addons.thunderbird.net/developers/
   - Sign up and complete profile

3. **Submit:**
   - Go to Developer Hub → "Submit a New Add-on"
   - Upload `.zip` or `.xpi` file
   - Choose distribution: Listed (public) or Unlisted (direct)

4. **Fill listing:**
   - Name, description, categories
   - Screenshots, icons
   - Privacy policy (inline, not external link)
   - Support email/URL

5. **Review process:**
   - Automated validation: immediate
   - Manual review: 1-7 days for listed extensions
   - Respond to reviewer comments within 10 days

### Review Criteria

- Extension works with supported Thunderbird versions
- Uses only necessary permissions
- No remote code execution
- Uses HTTPS for sensitive data
- Clear privacy policy disclosure
- No Experiment API when built-in API exists
- No hidden functionality

### Privacy Policy Requirements

Must include (inline, not external):

```markdown
# Privacy Policy for [Add-on Name]

## Data Collection
[Specific description of what data is collected]

## Purpose
[Why data is collected]

## Storage
[How and where data is stored]

## Sharing
[Whether data is shared with third parties]

## User Control
[How users can delete their data]
```

### Common Rejection Reasons

| Reason | Solution |
|--------|----------|
| Doesn't work with supported versions | Test on Thunderbird 128+ |
| Uses Experiment when built-in API exists | Use MailExtension API |
| No response to reviewer comments | Check email, respond within 10 days |
| Unclear privacy policy | Be specific about data collection |
| Excessive permissions | Remove unused permissions |
| Missing source code | Provide if using minification |

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

## Best Practices

### Code Organization

```
my-extension/
├── manifest.json
├── background.js
├── popup.html
├── popup.js
├── compose_popup.html
├── compose_popup.js
├── api/
│   └── myapi/
│       ├── schema.json
│       └── implementation.js
├── icons/
│   ├── icon-16.png
│   ├── icon-32.png
│   └── icon-64.png
├── _locales/
│   ├── en/
│   │   └── messages.json
│   └── it/
│       └── messages.json
└── README.md
```

### Error Handling

```javascript
async function safeAsync(fn) {
  try {
    return await fn();
  } catch (error) {
    console.error("Error:", error);
    return { error: error.message };
  }
}

// Usage
const result = await safeAsync(() => messenger.messages.get(messageId));
if (result.error) {
  console.error("Failed to get message:", result.error);
}
```

### Performance

- Use pagination for large message lists
- Cache frequently accessed data
- Debounce rapid events
- Use `messages.query()` with filters instead of `list()` + filter manually

### Security

- Validate all user input
- Sanitize HTML before display
- Use minimal permissions
- Don't store sensitive data in `storage.local` unencrypted
- Validate message content before processing

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

## Differences from Firefox WebExtensions

| Feature | Firefox | Thunderbird |
|---------|---------|-------------|
| Namespace | `browser.*` | `messenger.*` (mail) + `browser.*` (common) |
| Context | Web browser | Email client |
| Content scripts | Work on web pages | Only in web tabs, not email content |
| Main action | `browser_action` / `action` | Same + `compose_action`, `message_display_action` |
| Mail APIs | None | `accounts`, `compose`, `messages`, etc. |
| Experiments | Limited | Common for email-specific features |
| Store | AMO | ATN |

## File Structure Template

```
my-thunderbird-extension/
├── manifest.json
├── background.js
├── popup.html
├── popup.js
├── compose_popup.html
├── compose_popup.js
├── message_popup.html
├── message_popup.js
├── message_content.js
├── styles/
│   └── popup.css
├── icons/
│   ├── icon-16.png
│   ├── icon-32.png
│   └── icon-64.png
├── api/
│   └── myapi/
│       ├── schema.json
│       └── implementation.js
├── _locales/
│   ├── en/
│   │   └── messages.json
│   └── it/
│       └── messages.json
└── README.md
```

## Quick Reference

### Essential Permissions

```json
{
  "permissions": [
    "storage",           // Data storage
    "messagesRead",      // Read messages
    "messagesMove",      // Move/copy/delete messages
    "addressBooks",      // Access contacts
    "compose",           // Compose windows
    "accountsRead",      // Read accounts
    "accountsFolders"    // Access folders
  ]
}
```

### Essential APIs

```javascript
// Messages
messenger.messages.list(folderId)
messenger.messages.get(messageId)
messenger.messages.query({ from, unread })
messenger.messages.update(messageId, { read: true })

// Folders
messenger.folders.get(folderId)
messenger.folders.getSubFolders(account)

// Compose
messenger.compose.beginNew({ to, subject, body })
messenger.compose.getComposeDetails(tabId)

// Address Books
messenger.addressBooks.list()
messenger.addressBooks.contacts.create(addressBookId, { vCard })

// Display
messenger.messageDisplay.getDisplayedMessage(tabId)
messenger.messageDisplayAction.onClicked
```

### Workflow Summary

1. **Develop:** Write code, load temporarily
2. **Debug:** Use Debug Add-ons → Inspect
3. **Test:** Test all functionality
4. **Build:** Create .zip with manifest and scripts
5. **Submit:** Upload to ATN
6. **Review:** Respond to reviewer feedback
7. **Publish:** Extension goes live

## References

- [Thunderbird Developer Hub](https://developer.thunderbird.net/add-ons/)
- [WebExtension API Reference](https://webextension-api.thunderbird.net/)
- [Supported APIs](https://developer.thunderbird.net/add-ons/mailextensions/supported-webextension-api)
- [Manifest V3 Guide](https://github.com/thunderbird/webext-docs/blob/beta-mv2/guides/manifestV3.rst)
- [Example Extensions](https://github.com/thunderbird/webext-examples)
- [Experiment Support](https://github.com/thunderbird/webext-support)
- [ATN Developer Hub](https://addons.thunderbird.net/developers/)
- [ATN Review Policy](https://thunderbird.github.io/atn-review-policy/)
