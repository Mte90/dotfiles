# WebExtension APIs

> This reference file is loaded on demand from ../SKILL.md.

## Complete API Namespace List (51 APIs)

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

## Core API Usage Patterns

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

## Firefox-Specific APIs

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