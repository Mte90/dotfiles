---
name: pyqt-dialogs
description: "PyQt/PySide6 dialogs - QFileDialog, QMessageBox, QInputDialog, QColorDialog, custom QDialog patterns"
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - python
    - qt
    - pyqt
    - pyside
    - dialogs
    - ui
---

# PyQt Dialogs

Standard and custom dialog patterns for PyQt/PySide6 applications.

## Standard Dialogs

### QFileDialog

```python
from PySide6.QtWidgets import QFileDialog

# Open single file
filename, _ = QFileDialog.getOpenFileName(
    self,
    "Open File",
    "/home/user",  # Starting directory
    "Images (*.png *.jpg);;Text Files (*.txt);;All Files (*)"
)

if filename:
    print(f"Selected: {filename}")

# Save file
filename, _ = QFileDialog.getSaveFileName(
    self,
    "Save File",
    "/home/user/untitled.txt",
    "Text Files (*.txt);;All Files (*)"
)

# Select directory
directory = QFileDialog.getExistingDirectory(
    self,
    "Select Directory",
    "/home/user",
    QFileDialog.Option.ShowDirsOnly
)

# Open multiple files
files, _ = QFileDialog.getOpenFileNames(
    self,
    "Open Files",
    "/home/user",
    "Images (*.png *.jpg)"
)

for f in files:
    print(f)

# Options
options = QFileDialog.Option.DontUseNativeDialog  # Use Qt dialog instead of OS dialog
filename, _ = QFileDialog.getOpenFileName(self, "Open", "", "", options=options)
```

### QMessageBox

```python
from PySide6.QtWidgets import QMessageBox

# Question dialog
reply = QMessageBox.question(
    self,
    "Confirm",
    "Are you sure?",
    QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
    QMessageBox.StandardButton.No
)

if reply == QMessageBox.StandardButton.Yes:
    print("User confirmed")

# Information
QMessageBox.information(self, "Info", "Operation completed successfully")

# Warning
QMessageBox.warning(self, "Warning", "This action cannot be undone")

# Critical error
QMessageBox.critical(self, "Error", "Failed to connect to server")

# About
QMessageBox.about(self, "About", "My App v1.0\n\nCopyright 2024")

# About Qt
QMessageBox.aboutQt(self)

# Custom buttons
msg = QMessageBox(self)
msg.setWindowTitle("Custom Dialog")
msg.setText("Continue?")
msg.setIcon(QMessageBox.Icon.Question)
msg.addButton("Yes", QMessageBox.ButtonRole.YesRole)
msg.addButton("No", QMessageBox.ButtonRole.NoRole)
msg.addButton("Cancel", QMessageBox.ButtonRole.RejectRole)

result = msg.exec()
print(f"Button role: {msg.buttonRole(msg.clickedButton())}")
```

### QInputDialog

```python
from PySide6.QtWidgets import QInputDialog, QLineEdit

# Get text
text, ok = QInputDialog.getText(
    self,
    "Input",
    "Enter name:",
    QLineEdit.EchoMode.Normal,
    "Default value"
)

if ok and text:
    print(f"Name: {text}")

# Get integer
value, ok = QInputDialog.getInt(
    self,
    "Input",
    "Enter age:",
    25,  # Default
    0,   # Min
    120, # Max
    1    # Step
)

if ok:
    print(f"Age: {value}")

# Get double
price, ok = QInputDialog.getDouble(
    self,
    "Input",
    "Enter price:",
    0.0,
    0.0,
    1000.0,
    2  # Decimals
)

if ok:
    print(f"Price: ${price:.2f}")

# Get item from list
items = ["Option 1", "Option 2", "Option 3"]
item, ok = QInputDialog.getItem(
    self,
    "Select",
    "Choose an option:",
    items,
    0,    # Current index
    False # Editable
)

if ok:
    print(f"Selected: {item}")

# Get multiline text
text, ok = QInputDialog.getMultiLineText(
    self,
    "Input",
    "Enter description:",
    "Default\ntext"
)
```

### QColorDialog

```python
from PySide6.QtWidgets import QColorDialog
from PySide6.QtGui import QColor

# Get color
color = QColorDialog.getColor(
    QColor(255, 0, 0),  # Default color
    self,
    "Select Color"
)

if color.isValid():
    print(f"Color: {color.name()}")  # "#ff0000"
    widget.setStyleSheet(f"background-color: {color.name()};")

# With alpha
color = QColorDialog.getColor(
    QColor(255, 0, 0, 128),
    self,
    "Select Color with Alpha",
    QColorDialog.ColorDialogOption.ShowAlphaChannel
)

# Get color with options
options = (
    QColorDialog.ColorDialogOption.ShowAlphaChannel |
    QColorDialog.ColorDialogOption.NoButtons
)
color = QColorDialog.getColor(Qt.white, self, "Color", options)
```

### QFontDialog

```python
from PySide6.QtWidgets import QFontDialog
from PySide6.QtGui import QFont

# Get font
font, ok = QFontDialog.getFont(
    QFont("Arial", 12),  # Default font
    self,
    "Select Font"
)

if ok:
    print(f"Font: {font.family()}, Size: {font.pointSize()}")
    widget.setFont(font)

# With options
font, ok = QFontDialog.getFont(
    QFont(),
    self,
    "Select Font",
    QFontDialog.FontDialogOption.MonospacedFonts
)
```

## Custom Dialogs

### Basic Custom Dialog

```python
from PySide6.QtWidgets import (
    QDialog, QVBoxLayout, QHBoxLayout, QLabel,
    QLineEdit, QDialogButtonBox, QFormLayout
)

class InputDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Input Dialog")
        self.setMinimumWidth(400)
        
        layout = QVBoxLayout(self)
        
        # Form
        form = QFormLayout()
        self.name_edit = QLineEdit()
        self.email_edit = QLineEdit()
        form.addRow("Name:", self.name_edit)
        form.addRow("Email:", self.email_edit)
        layout.addLayout(form)
        
        # Buttons
        buttons = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Ok |
            QDialogButtonBox.StandardButton.Cancel
        )
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)
    
    def get_values(self):
        return {
            "name": self.name_edit.text(),
            "email": self.email_edit.text()
        }
    
    def set_values(self, name="", email=""):
        self.name_edit.setText(name)
        self.email_edit.setText(email)

# Usage
dialog = InputDialog(self)
dialog.set_values("John", "john@example.com")

if dialog.exec() == QDialog.DialogCode.Accepted:
    values = dialog.get_values()
    print(f"Name: {values['name']}, Email: {values['email']}")
```

### Dialog with Validation

```python
class ValidatedDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Validated Input")
        
        layout = QVBoxLayout(self)
        
        # Input
        form = QFormLayout()
        self.age_spin = QSpinBox()
        self.age_spin.setRange(0, 120)
        self.email_edit = QLineEdit()
        form.addRow("Age:", self.age_spin)
        form.addRow("Email:", self.email_edit)
        layout.addLayout(form)
        
        # Error label
        self.error_label = QLabel()
        self.error_label.setStyleSheet("color: red;")
        layout.addWidget(self.error_label)
        
        # Buttons
        self.buttons = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Ok |
            QDialogButtonBox.StandardButton.Cancel
        )
        self.buttons.accepted.connect(self.try_accept)
        self.buttons.rejected.connect(self.reject)
        layout.addWidget(self.buttons)
    
    def try_accept(self):
        if not self.validate():
            return
        self.accept()
    
    def validate(self):
        import re
        
        # Validate email
        email = self.email_edit.text()
        if not email:
            self.error_label.setText("Email is required")
            return False
        
        if not re.match(r"[^@]+@[^@]+\.[^@]+", email):
            self.error_label.setText("Invalid email format")
            return False
        
        self.error_label.clear()
        return True
    
    def get_values(self):
        return {
            "age": self.age_spin.value(),
            "email": self.email_edit.text()
        }
```

### Modeless Dialog

```python
class SearchDialog(QDialog):
    """Non-modal (modeless) dialog that stays open."""
    searchRequested = Signal(str)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Search")
        self.setWindowFlags(
            Qt.WindowType.Dialog |
            Qt.WindowType.WindowCloseButtonHint
        )
        
        layout = QVBoxLayout(self)
        
        self.search_edit = QLineEdit()
        self.search_edit.setPlaceholderText("Enter search term...")
        self.search_edit.returnPressed.connect(self.search)
        
        self.search_btn = QPushButton("Search")
        self.search_btn.clicked.connect(self.search)
        
        layout.addWidget(self.search_edit)
        layout.addWidget(self.search_btn)
    
    def search(self):
        term = self.search_edit.text()
        if term:
            self.searchRequested.emit(term)

# Usage
search_dialog = SearchDialog(self)
search_dialog.searchRequested.connect(self.perform_search)
search_dialog.show()  # Use show() instead of exec() for modeless
```

## Best Practices

1. **Use standard dialogs when possible** - They're familiar and consistent
2. **Provide sensible defaults** - Pre-fill common values
3. **Validate input before accepting** - Show clear error messages
4. **Use QDialogButtonBox** - Ensures correct button ordering per platform
5. **Set minimum size** - Prevent dialogs from being too small
6. **Consider modeless dialogs** - For search, find/replace, etc.

## References

- **QDialog**: https://doc.qt.io/qtforpython-6/PySide6/QtWidgets/QDialog.html
- **QFileDialog**: https://doc.qt.io/qtforpython-6/PySide6/QtWidgets/QFileDialog.html
- **QMessageBox**: https://doc.qt.io/qtforpython-6/PySide6/QtWidgets/QMessageBox.html
- **Dialogs**: https://doc.qt.io/qtforpython-6/dialogs.html
