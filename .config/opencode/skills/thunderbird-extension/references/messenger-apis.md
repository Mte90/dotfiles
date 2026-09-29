# Messenger APIs Reference

> This reference file is loaded on demand from ../SKILL.md for detailed messenger.* API documentation.

## Complete API Namespace List

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

## Standard WebExtension APIs (also available)

- `browser.runtime` - Messaging, lifecycle
- `browser.storage` - Data persistence
- `browser.i18n` - Localization
- `browser.tabs` - Tab management
- `browser.windows` - Window management
- `browser.commands` - Keyboard shortcuts

## Accounts API

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

## Messages API

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

## Folders API

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

## Address Books & Contacts API (MV3)

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

## Compose API

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

## Message Display API

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

## Mail Tabs API

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