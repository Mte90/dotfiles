---
name: kate-plugin
description: "Develop C++ plugins for Kate text editor - KTextEditor interface, CMake, Qt widgets, action system"
metadata:
  author: "OSS AI Skills"
  version: "1.0.0"
  tags:
    - kate
    - kde
    - text-editor
    - plugin
    - c++
    - qt
    - kde-frameworks
---

# Kate Plugin Development

Develop C++ plugins for Kate text editor using KTextEditor interface.

## Overview

Kate (KDE Advanced Text Editor) is a powerful programmable editor. Plugins extend functionality through C++ using the KTextEditor framework.

**Note:** PyKDE6 does not exist. Kate plugins are developed in C++ using the native KTextEditor API.

### Plugin Types

- **KTextEditor Plugins** - C++ plugins using KTextEditor interface (primary method)
- **LSP Plugins** - Language Server Protocol clients
- **Python Scripts** - Limited scripting via console (not full plugins)

### Plugin Locations

```
# System plugins
/usr/share/kate/plugins/

# User plugins
~/.local/share/kate/plugins/
~/.kde/share/kate/plugins/
```

## KTextEditor API

### Document Interface

```python
from PyKDE6 import ktexteditor
from PyQt6.QtCore import QObject

class MyPlugin(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.doc = None
    
    def setDocument(self, doc: ktexteditor.Document):
        self.doc = doc
    
    # Document methods
    def insertText(self, text: str):
        self.doc.insertText(text)
    
    def getText(self) -> str:
        return self.doc.text()
    
    def getLine(self, line: int) -> str:
        return self.doc.line(line)
    
    def getCursor(self) -> ktextEditor.Cursor:
        return self.doc.cursorPosition()
```

### View Interface

```python
class MyPlugin(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.view = None
    
    def setView(self, view: ktexteditor.View):
        self.view = view
    
    # View methods
    def getSelection(self) -> str:
        return self.view.selectionText()
    
    def setSelection(self, start: Cursor, end: Cursor):
        self.view.setSelection(start, end)
    
    def gotoCursor(self, line: int, col: int):
        cursor = ktexteditor.Cursor(line, col)
        self.view.setCursorPosition(cursor)
    
    def getActiveLanguage(self) -> str:
        return self.view.activeLanguageMode()
```

### Cursor and Range

```python
from PyKDE6 import ktexteditor

# Create cursor (line, column)
cursor = ktexteditor.Cursor(10, 5)

# Create range
start = ktexteditor.Cursor(10, 0)
end = ktexteditor.Cursor(10, 20)
range_ = ktexteditor.Range(start, end)

# Cursor methods
line = cursor.line()
col = cursor.column()

# Range methods
start = range_.start()
end = range_.end()
text = range_.text(document)  # Get text in range
```

## Plugin Structure

### Python Plugin Layout

```
my-plugin/
├── plugin/
│   ├── __init__.py
│   └── myplugin.py
├── ui/
│   └── mydialog.ui
├── ../../../metadata.json
└── ../../../myplugin.desktop
```

### metadata.json

```json
{
    "KPlugin": {
        "Name": "My Plugin",
        "Comment": "Description of my plugin",
        "Icon": "kate",
        "Authors": [
            {
                "Name": "Your Name",
                "Email": "you@example.com"
            }
        ],
        "Version": "1.0.0",
        "License": "MIT",
        "ServiceTypes": [
            "Kate/Plugin"
        ],
        "Category": "Editor",
        "ApiVersion": "2.0"
    }
}
```

### Desktop File

```desktop
[Desktop Entry]
Name=My Plugin
Comment=A brief description
Icon=kate
Type=Service
X-KDE-Library=myplugin
X-KDE-PluginKeyword=myplugin
X-KDE-ParentApp=kate
X-KDE-InitFunction=load_myplugin
X-KDE-UnloadFunction=unload_myplugin
```

### Python Plugin Class

```python
from PyKDE6 import ktexteditor
from PyQt6.QtCore import QObject, pyqtSlot

class MyPlugin(ktexteditor.Plugin):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.widgets = []
    
    def addViewWidget(self, mainwindow):
        """Called when plugin is activated"""
        widget = MyPluginWidget(mainwindow)
        mainwindow.addToolView(widget)
        self.widgets.append(widget)
        return widget
    
    def removeViewWidget(self, widget):
        """Called when plugin is deactivated"""
        widget.mainWindow().removeToolView(widget)
        self.widgets.remove(widget)
    
    def readProperties(self, group, file):
        """Load settings"""
        self.enabled = group.readEntry("Enabled", True)
    
    def writeProperties(self, group, file):
        """Save settings"""
        group.writeEntry("Enabled", self.enabled)
```

## JavaScript Plugins

### Action Scripting

```javascript
// In Kate's console or .katescript files

// Basic editing
view.insertText("Hello, World!");
var selected = view.selectionText();
document.setText("New document content");

// Cursor navigation
view.setCursorPosition(10, 5);
var cursor = view.cursorPosition();

// Selection
view.select(cursor, new Cursor(10, 20));

// Search and replace
view.search("find", Cursor(0, 0));
view.replace("find", "replace");
```

### Key Shortcuts

```javascript
// Define keyboard shortcuts
// Edit > Shortcuts > Custom Shortcuts
```

## Examples

### Simple Insert Plugin

```python
from PyKDE6 import ktexteditor
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QPushButton

class SimpleInsertPlugin(ktexteditor.Plugin):
    def __init__(self, parent=None):
        super().__init__(parent)
    
    def addViewWidget(self, mainwindow):
        widget = QWidget()
        layout = QVBoxLayout()
        
        btn = QPushButton("Insert Timestamp")
        btn.clicked.connect(lambda: self.insertTimestamp(mainwindow))
        layout.addWidget(btn)
        
        widget.setLayout(layout)
        mainwindow.addToolView(widget)
        return widget
    
    def insertTimestamp(self, mainwindow):
        from datetime import datetime
        view = mainwindow.activeView()
        if view:
            view.insertText(datetime.now().isoformat())
```

### Find and Replace Plugin

```python
class FindReplacePlugin(ktexteditor.Plugin):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.range = None
    
    def findNext(self, view, text):
        doc = view.document()
        cursor = view.cursorPosition()
        
        # Search from cursor
        result = doc.searchText(text, cursor)
        
        if result.isValid():
            view.setSelection(result)
            view.setCursorPosition(result.end())
            return True
        return False
    
    def replace(self, view, find, replace):
        if view.hasSelection():
            selected = view.selectionText()
            if selected == find:
                view.removeSelectionText()
                view.insertText(replace)
                return True
        return False
```

## Configuration

### Settings Integration

```python
class MyPlugin(ktexteditor.Plugin):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.config = {}
    
    def createConfigPage(self, parent, alias):
        """Create configuration page"""
        from PyQt6.QtWidgets import QFormLayout, QLineEdit, QWidget
        
        page = QWidget(parent)
        layout = QFormLayout()
        
        self.pathInput = QLineEdit()
        self.pathInput.setText(self.config.get("path", ""))
        layout.addRow("Path:", self.pathInput)
        
        page.setLayout(layout)
        return page
    
    def applyConfig(self):
        """Apply configuration changes"""
        self.config["path"] = self.pathInput.text()
```

## Best Practices

### 1. Initialize Properly

```python
# Good: Check for valid document
def do_something(self, view):
    if view and view.document():
        doc = view.document()
        # Work with document
```

### 2. Handle Errors

```python
# Good: Error handling
try:
    view.insertText(text)
except Exception as e:
    print(f"Error inserting text: {e}")
```

### 3. Use Signals

```python
# Connect to document signals
doc.textChanged.connect(self.onTextChanged)
doc.cursorPositionChanged.connect(self.onCursorMoved)
```

## Advanced Topics

### KTextEditor Interface

```cpp
// Document interface - text manipulation
KTextEditor::Document* doc = view->document();

// Insert text at cursor
doc->insertText(cursor, "text");

// Replace range
doc->replaceText(start, end, "new text");

// Search and replace
doc->setSearchText("pattern", KTextEditor::Search::CaseInsensitive);
```

### View Interface

```cpp
// Cursor management
KTextEditor::Cursor cursor = view->cursorPosition();
view->setCursorPosition(cursor);

// Selection
view->selection();
view->setSelection(range);
view->clearSelection();

// Folding
view->toggleFolding(idx);
```

### Advanced Features

```cpp
// Variables (user-configurable settings)
KTextEditor::VariableInterface* varIface = qobject_cast<KTextEditor::VariableInterface*>(doc);
QVariant value = varIface->variable("my-var");

// Plugins can register:
# Document: new editing features
# View: visual enhancements  
# Tools: integrated utilities
# Tolls: additional functionality
```

### Best Practices

```cpp
// ✅ GOOD: Use proper interfaces
KTextEditor::Editor* editor = KTextEditor::Editor::self();

// ✅ GOOD: Check for null
if (view && view->document()) {
    // ...
}

// ✅ GOOD: Use signals for async
connect(doc, &KTextEditor::Document::textChanged, this, &MyPlugin::onTextChanged);

// ❌ BAD: Direct manipulation without interfaces
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Plugin not loading | Check JSON metadata, correct category |
| Crash on load | Initialize in init() not constructor |
| Feature not working | CheckKatePart version requirement |

---

## References

- **KDE Documentation**: https://docs.kde.org/
- **Kate API**: https://api.kde.org/
- **KTextEditor**: https://docs.kde.org/stable/en/kate/kate-part/
- **KDE Developer**: https://developer.kde.org/