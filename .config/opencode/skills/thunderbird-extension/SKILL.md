---
name: thunderbird-extension
description: Use when developing Thunderbird MailExtensions - Manifest V2/V3 configuration, messenger.* APIs for accounts, messages, folders and compose, UI actions, message display scripts, Experiment APIs, ATN submission, or migration from legacy extensions
metadata:
  author: mte90
  version: 2.0.0
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

## Deep Dives

For detailed reference on specific topics, load these reference files on demand:

- **Messenger APIs** - Complete `messenger.*` API reference (accounts, messages, folders, addressBooks, compose, mailTabs): `./references/messenger-apis.md`
- **Experiment APIs** - Custom Experiment API development guide: `./references/experiment-apis.md`
- **ATN Submission** - Publishing workflow and review criteria: `./references/atn-submission.md`
- **Testing & Migration** - Debugging, testing workflow, and legacy migration: `./references/testing-migration.md`

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