---
name: pyqt
description: Comprehensive guide for developing desktop applications with PyQt5, PyQt6, and PySide6, including installation, widgets, signals/slots, layouts, styling, and packaging.
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - python
    - qt
    - pyqt
    - pyside
    - gui
    - desktop
    - pyqt6
    - pyqt5
---

# PyQt/PySide Development

Complete reference for building cross-platform desktop applications with Python and Qt.

## Overview

PyQt and PySide are Python bindings for the Qt application framework. They enable building professional desktop applications with native look and feel across Windows, macOS, and Linux.

**Key Characteristics:**
- Cross-platform (Windows, macOS, Linux)
- Rich widget library
- Signal-slot mechanism for event handling
- QSS styling (CSS-like)
- Support for OpenGL, multimedia, networking, databases

## PyQt vs PySide Comparison

| Feature | PyQt5 | PyQt6 | PySide6 |
|---------|-------|-------|---------|
| License | GPL | GPL | LGPL |
| Qt Version | Qt 5 | Qt 6 | Qt 6 |
| Maintained | Security only | Active | Active |
| Signal Syntax | `pyqtSignal` | `pyqtSignal` | `Signal` |
| Slot Syntax | `pyqtSlot` | `pyqtSlot` | `Slot` |
| Property Syntax | `pyqtProperty` | `pyqtProperty` | `Property` |
| Commercial Use | Requires license | Requires license | Free |
| QML Registration | `qmlRegisterType()` | `qmlRegisterType()` | `@QmlElement` |

### When to Use Each

- **PySide6**: Recommended for most projects (LGPL, official Qt Company support)
- **PyQt6**: If you need GPL compatibility or existing PyQt codebase
- **PyQt5**: Legacy projects only (security fixes only)

## Installation

### PySide6 (Recommended)

```bash
pip install PySide6
```

### PyQt6

```bash
pip install PyQt6
```

### PyQt5 (Legacy)

```bash
pip install PyQt5
```

### Additional Dependencies

```bash
# System packages (Ubuntu/Debian)
sudo apt install libgl1-mesa-glx libglib2.0-0

# System packages (Fedora)
sudo dnf install mesa-libGL glib2

# System packages (Arch)
sudo pacman -S mesa glib2
```

## Application Structure

### Basic Application

```python
#!/usr/bin/env python3
import sys
from PySide6.QtWidgets import QApplication, QMainWindow, QLabel

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("My Application")
        self.setGeometry(100, 100, 800, 600)
        
        label = QLabel("Hello, Qt!")
        label.setAlignment(Qt.AlignCenter)
        self.setCentralWidget(label)

def main():
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
```

### Recommended Project Structure

```
my_app/
├── src/
│   ├── __init__.py
│   ├── main.py
│   ├── main_window.py
│   ├── widgets/
│   │   ├── __init__.py
│   │   ├── custom_widget.py
│   │   └── dialog.py
│   ├── models/
│   │   ├── __init__.py
│   │   └── data_model.py
│   ├── resources/
│   │   ├── icons/
│   │   ├── styles/
│   │   │   └── style.qss
│   │   └── resources.qrc
│   └── utils/
│       ├── __init__.py
│       └── helpers.py
├── tests/
│   ├── __init__.py
│   └── test_main.py
├── requirements.txt
├── pyproject.toml
└── README.md
```

## Core Modules

### QtWidgets - UI Components

```python
from PySide6.QtWidgets import (
    QApplication, QMainWindow, QWidget,
    QLabel, QPushButton, QLineEdit, QTextEdit,
    QComboBox, QSpinBox, QCheckBox, QRadioButton,
    QSlider, QProgressBar, QGroupBox,
    QTabWidget, QStackedWidget, QSplitter,
    QListWidget, QTreeWidget, QTableWidget,
    QScrollArea, QToolBar, QStatusBar,
    QMenuBar, QMenu, QFileDialog, QMessageBox
)
```

### QtCore - Core Non-GUI

```python
from PySide6.QtCore import (
    Qt, QObject, QTimer, QThread,
    Signal, Slot, Property,
    QSize, QPoint, QRect,
    QSettings, QFile, QDir,
    QUrl, QMimeData,
    QDateTime, QDate, QTime,
    QAbstractItemModel, QModelIndex
)
```

### QtGui - Graphics

```python
from PySide6.QtGui import (
    QIcon, QPixmap, QImage,
    QPainter, QPen, QBrush, QColor,
    QFont, QCursor,
    QKeySequence, QShortcut,
    QDragEnterEvent, QDropEvent
)
```

## Signals and Slots

### Signal Declaration

```python
from PySide6.QtCore import QObject, Signal

class MyObject(QObject):
    # Define signals at class level
    valueChanged = Signal(int)
    nameChanged = Signal(str)
    dataReady = Signal(dict)
    errorOccurred = Signal(str)
    
    # Signal with multiple arguments
    positionChanged = Signal(int, int)
```

### Slot Declaration

```python
from PySide6.QtCore import Slot

class MyObject(QObject):
    @Slot()
    def doSomething(self):
        print("Action performed")
    
    @Slot(int)
    def setValue(self, value):
        self._value = value
    
    @Slot(str, int)
    def processData(self, name, count):
        pass
    
    @Slot(result=str)  # Return type annotation
    def getName(self) -> str:
        return self._name
```

### Connecting Signals to Slots

```python
# Connect signal to slot
button.clicked.connect(self.onButtonClick)
valueChanged.connect(self.updateValue)

# Connect with lambda
button.clicked.connect(lambda: print("Clicked!"))

# Connect with partial
from functools import partial
button.clicked.connect(partial(self.processItem, item_id))

# Disconnect
button.clicked.disconnect(self.onButtonClick)

# Emit signal
self.valueChanged.emit(42)
self.positionChanged.emit(x, y)

# Block signals temporarily
button.blockSignals(True)
button.setChecked(True)
button.blockSignals(False)
```

### PyQt6 Syntax (Different)

```python
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot

class MyObject(QObject):
    valueChanged = pyqtSignal(int)
    
    @pyqtSlot(int)
    def setValue(self, value):
        pass
```

## Layout Management

### Box Layouts

```python
from PySide6.QtWidgets import QVBoxLayout, QHBoxLayout, QGroupBox

# Vertical layout
layout = QVBoxLayout()
layout.addWidget(label)
layout.addWidget(button)
layout.addStretch()  # Add stretchable space
layout.addWidget(bottom_label)

# Horizontal layout
h_layout = QHBoxLayout()
h_layout.addWidget(left_button)
h_layout.addStretch()
h_layout.addWidget(right_button)

# Nest layouts
main_layout = QVBoxLayout()
main_layout.addLayout(h_layout)
```

### Grid Layout

```python
from PySide6.QtWidgets import QGridLayout

layout = QGridLayout()
layout.addWidget(label1, 0, 0)  # row 0, col 0
layout.addWidget(lineEdit, 0, 1)  # row 0, col 1
layout.addWidget(label2, 1, 0)  # row 1, col 0
layout.addWidget(comboBox, 1, 1)  # row 1, col 1

# Span multiple cells
layout.addWidget(bigWidget, 2, 0, 1, 2)  # row 2, col 0, span 1 row, 2 cols
```

### Form Layout

```python
from PySide6.QtWidgets import QFormLayout

layout = QFormLayout()
layout.addRow("Name:", nameLineEdit)
layout.addRow("Email:", emailLineEdit)
layout.addRow("Age:", ageSpinBox)
```

### Stack Layout

```python
from PySide6.QtWidgets import QStackedLayout

stack = QStackedLayout()
stack.addWidget(page1)
stack.addWidget(page2)
stack.addWidget(page3)
stack.setCurrentIndex(0)  # Show page1
```

### Layout Properties

```python
# Margins and spacing
layout.setContentsMargins(10, 10, 10, 10)  # left, top, right, bottom
layout.setSpacing(5)

# Widget alignment
layout.addWidget(label, alignment=Qt.AlignCenter)

# Stretch factors
layout.addWidget(widget1, stretch=1)
layout.addWidget(widget2, stretch=2)  # Gets twice the space
```

## Common Widgets

### Labels and Display

```python
# Label
label = QLabel("Text")
label.setText("New text")
label.setPixmap(QPixmap("image.png"))
label.setAlignment(Qt.AlignCenter)
label.setWordWrap(True)

# Progress bar
progress = QProgressBar()
progress.setValue(50)
progress.setRange(0, 100)
progress.setTextVisible(True)

# LCD Number
lcd = QLCDNumber()
lcd.display(123)
```

### Input Widgets

```python
# Line edit
lineEdit = QLineEdit()
lineEdit.setText("Default")
lineEdit.setPlaceholderText("Enter text...")
lineEdit.setEchoMode(QLineEdit.Password)
lineEdit.setMaxLength(100)
lineEdit.textChanged.connect(self.onTextChanged)

# Text edit
textEdit = QTextEdit()
textEdit.setPlainText("Plain text")
textEdit.setHtml("<b>HTML</b>")
textEdit.toPlainText()

# Spin box
spinBox = QSpinBox()
spinBox.setRange(0, 100)
spinBox.setValue(50)
spinBox.setSuffix(" px")
spinBox.valueChanged.connect(self.onValueChanged)

# Combo box
comboBox = QComboBox()
comboBox.addItems(["Option 1", "Option 2", "Option 3"])
comboBox.setCurrentIndex(0)
comboBox.currentTextChanged.connect(self.onSelectionChanged)

# Checkbox
checkBox = QCheckBox("Enable feature")
checkBox.setChecked(True)
checkBox.stateChanged.connect(self.onStateChanged)

# Radio button
radio1 = QRadioButton("Option A")
radio2 = QRadioButton("Option B")
radio1.setChecked(True)
radio1.toggled.connect(self.onToggled)

# Slider
slider = QSlider(Qt.Horizontal)
slider.setRange(0, 100)
slider.setValue(50)
slider.valueChanged.connect(self.onSliderChanged)
```

### Buttons

```python
# Push button
button = QPushButton("Click Me")
button.clicked.connect(self.onButtonClick)
button.setEnabled(False)
button.setDefault(True)

# Tool button
toolButton = QToolButton()
toolButton.setIcon(QIcon("icon.png"))
toolButton.setToolButtonStyle(Qt.ToolButtonTextUnderIcon)

# Checkable button
checkButton = QPushButton("Toggle")
checkButton.setCheckable(True)
checkButton.toggled.connect(self.onToggle)
```

### Container Widgets

```python
# Group box
groupBox = QGroupBox("Settings")
groupBox.setCheckable(True)
groupBox.setChecked(True)

# Tab widget
tabWidget = QTabWidget()
tabWidget.addTab(page1, "Tab 1")
tabWidget.addTab(page2, "Tab 2")
tabWidget.setCurrentIndex(0)

# Scroll area
scrollArea = QScrollArea()
scrollArea.setWidget(contentWidget)
scrollArea.setWidgetResizable(True)

# Splitter
splitter = QSplitter(Qt.Horizontal)
splitter.addWidget(leftWidget)
splitter.addWidget(rightWidget)
splitter.setSizes([200, 400])
```

### Item Views

```python
# List widget
listWidget = QListWidget()
listWidget.addItems(["Item 1", "Item 2", "Item 3"])
listWidget.currentItemChanged.connect(self.onItemChanged)

# Tree widget
treeWidget = QTreeWidget()
treeWidget.setHeaderLabels(["Name", "Value"])
item = QTreeWidgetItem(["Parent", "0"])
child = QTreeWidgetItem(["Child", "1"])
item.addChild(child)
treeWidget.addTopLevelItem(item)

# Table widget
table = QTableWidget()
table.setRowCount(3)
table.setColumnCount(2)
table.setHorizontalHeaderLabels(["Column 1", "Column 2"])
table.setItem(0, 0, QTableWidgetItem("Cell"))
```

## Event Handling

### Override Event Handlers

```python
class MyWidget(QWidget):
    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton:
            print("Left click at", event.pos())
        event.accept()
    
    def keyPressEvent(self, event):
        if event.key() == Qt.Key_Escape:
            self.close()
        elif event.key() == Qt.Key_Return:
            self.submit()
        event.accept()
    
    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setPen(QPen(Qt.blue, 2))
        painter.drawRect(10, 10, 100, 100)
    
    def resizeEvent(self, event):
        print("Resized to", self.size())
    
    def closeEvent(self, event):
        reply = QMessageBox.question(
            self, 'Exit',
            'Are you sure?',
            QMessageBox.Yes | QMessageBox.No
        )
        if reply == QMessageBox.Yes:
            event.accept()
        else:
            event.ignore()
```

### Event Filters

```python
class MyWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.textEdit.installEventFilter(self)
    
    def eventFilter(self, obj, event):
        if obj == self.textEdit and event.type() == QEvent.KeyPress:
            if event.key() == Qt.Key_Tab:
                # Handle tab key specially
                return True
        return super().eventFilter(obj, event)
```

### Shortcuts

```python
from PySide6.QtGui import QKeySequence, QShortcut

# Create shortcut
shortcut = QShortcut(QKeySequence("Ctrl+S"), self)
shortcut.activated.connect(self.save)

# Common sequences
QKeySequence.Save  # Ctrl+S
QKeySequence.Open  # Ctrl+O
QKeySequence.Copy  # Ctrl+C
QKeySequence.Paste # Ctrl+V
QKeySequence.Quit  # Ctrl+Q
```

## Styling with QSS

### Basic Syntax

```css
/* Type selector */
QLabel {
    color: #333;
    font-size: 14px;
}

/* Class selector */
QPushButton[primary="true"] {
    background-color: #0078d4;
    color: white;
}

/* ID selector */
#myButton {
    border: 2px solid blue;
}

/* Pseudo-states */
QPushButton:hover {
    background-color: #e0e0e0;
}

QPushButton:pressed {
    background-color: #c0c0c0;
}

QPushButton:disabled {
    color: #999;
}
```

### Applying Styles

```python
# Application-wide
app.setStyleSheet("""
    QLabel { color: #333; }
    QPushButton { padding: 5px 10px; }
""")

# Widget-specific
button.setStyleSheet("background-color: blue; color: white;")

# From file
with open("style.qss", "r") as f:
    app.setStyleSheet(f.read())
```

### Common Properties

```css
/* Colors */
color: #333333;                    /* Text color */
background-color: white;           /* Background */
selection-color: white;            /* Selected text */
selection-background-color: blue;  /* Selection background */

/* Fonts */
font-family: Arial, sans-serif;
font-size: 14px;
font-weight: bold;
font-style: italic;

/* Borders */
border: 1px solid #ccc;
border-radius: 4px;
border-top: none;

/* Spacing */
padding: 10px;
margin: 5px;
spacing: 5px;  /* Between widgets */

/* Size */
min-width: 100px;
max-height: 200px;
```

### Custom Properties

```python
# Set custom property for styling
button.setProperty("primary", True)
button.style().unpolish(button)  # Force style refresh
button.style().polish(button)
```

```css
/* Use in QSS */
QPushButton[primary="true"] {
    background-color: #0078d4;
    color: white;
}
```

## Dialogs

### Standard Dialogs

```python
# File dialog
filename, _ = QFileDialog.getOpenFileName(
    self,
    "Open File",
    "/home/user",
    "Images (*.png *.jpg);;All Files (*)"
)

# Save dialog
filename, _ = QFileDialog.getSaveFileName(
    self,
    "Save File",
    "/home/user/untitled.txt",
    "Text Files (*.txt)"
)

# Directory dialog
directory = QFileDialog.getExistingDirectory(
    self,
    "Select Directory",
    "/home/user"
)

# Message box
reply = QMessageBox.question(
    self,
    "Confirm",
    "Are you sure?",
    QMessageBox.Yes | QMessageBox.No,
    QMessageBox.No
)

if reply == QMessageBox.Yes:
    # User confirmed
    pass

# Information
QMessageBox.information(self, "Title", "Message")

# Warning
QMessageBox.warning(self, "Title", "Warning message")

# Error
QMessageBox.critical(self, "Title", "Error message")

# Input dialog
text, ok = QInputDialog.getText(
    self,
    "Input",
    "Enter name:",
    QLineEdit.Normal,
    "Default"
)

if ok and text:
    print(text)

# Color picker
color = QColorDialog.getColor()
if color.isValid():
    widget.setStyleSheet(f"background-color: {color.name()};")

# Font picker
font, ok = QFontDialog.getFont()
if ok:
    widget.setFont(font)
```

### Custom Dialog

```python
from PySide6.QtWidgets import QDialog, QDialogButtonBox

class CustomDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Custom Dialog")
        self.setMinimumWidth(400)
        
        layout = QVBoxLayout(self)
        
        # Content
        form = QFormLayout()
        self.nameEdit = QLineEdit()
        form.addRow("Name:", self.nameEdit)
        layout.addLayout(form)
        
        # Buttons
        buttons = QDialogButtonBox(
            QDialogButtonBox.Ok | QDialogButtonBox.Cancel
        )
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)
    
    def getValues(self):
        return {"name": self.nameEdit.text()}

# Usage
dialog = CustomDialog(self)
if dialog.exec() == QDialog.Accepted:
    values = dialog.getValues()
```

## Threading

### QThread with Worker

```python
from PySide6.QtCore import QThread, Signal

class Worker(QThread):
    finished = Signal(str)
    progress = Signal(int)
    
    def __init__(self, data):
        super().__init__()
        self.data = data
    
    def run(self):
        for i, item in enumerate(self.data):
            # Process item
            result = self.process_item(item)
            self.progress.emit(int((i + 1) / len(self.data) * 100))
        self.finished.emit("Done")
    
    def process_item(self, item):
        # Heavy work here
        return item

class MainWindow(QMainWindow):
    def startWork(self):
        self.worker = Worker(self.data)
        self.worker.progress.connect(self.updateProgress)
        self.worker.finished.connect(self.onFinished)
        self.worker.start()
    
    def updateProgress(self, percent):
        self.progressBar.setValue(percent)
    
    def onFinished(self, message):
        QMessageBox.information(self, "Done", message)
```

### QThreadPool with QRunnable

```python
from PySide6.QtCore import QThreadPool, QRunnable, Signal, QObject

class WorkerSignals(QObject):
    finished = Signal(object)
    error = Signal(str)

class Runnable(QRunnable):
    def __init__(self, func, *args, **kwargs):
        super().__init__()
        self.func = func
        self.args = args
        self.kwargs = kwargs
        self.signals = WorkerSignals()
    
    def run(self):
        try:
            result = self.func(*self.args, **self.kwargs)
            self.signals.finished.emit(result)
        except Exception as e:
            self.signals.error.emit(str(e))

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.thread_pool = QThreadPool()
    
    def runAsync(self):
        runnable = Runnable(self.heavyTask, "data")
        runnable.signals.finished.connect(self.onFinished)
        runnable.signals.error.connect(self.onError)
        self.thread_pool.start(runnable)
    
    def heavyTask(self, data):
        # Heavy computation
        return result
```

## Packaging & Distribution

### PyInstaller

```bash
# Install
pip install pyinstaller

# Build executable
pyinstaller --onefile --windowed --name "MyApp" main.py

# With icon
pyinstaller --onefile --windowed --icon=icon.ico --name "MyApp" main.py

# Include data files
pyinstaller --onefile --add-data "resources:resources" main.py

# Create spec file for customization
pyi-makespec --onefile --windowed main.py
# Edit main.spec
pyinstaller main.spec
```

### PyInstaller Spec File

```python
# main.spec
a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=[],
    datas=[('resources', 'resources')],
    hiddenimports=[],
    hookspath=[],
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=None,
)
pyz = PYZ(a.pure, a.zipped_data, cipher=pyz_crypto)
exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='MyApp',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    icon='icon.ico',
)
```

### cx_Freeze

```python
# setup.py
from cx_Freeze import setup, Executable

build_exe_options = {
    "packages": ["PySide6"],
    "includes": [],
    "excludes": [],
    "include_files": ["resources/"]
}

base = None
if sys.platform == "win32":
    base = "Win32GUI"

setup(
    name="MyApp",
    version="1.0",
    description="My Application",
    options={"build_exe": build_exe_options},
    executables=[Executable("main.py", base=base, icon="icon.ico")]
)
```

```bash
# Build
python setup.py build
```

### Nuitka

```bash
# Install
pip install nuitka

# Build
python -m nuitka --standalone --windows-console-mode=disable --output-dir=build main.py
```

## Testing

### pytest-qt

```bash
pip install pytest-qt
```

```python
# test_main.py
import pytest
from PySide6.QtWidgets import QApplication
from main_window import MainWindow

@pytest.fixture
def app(qtbot):
    window = MainWindow()
    qtbot.addWidget(window)
    return window

def test_window_title(app):
    assert app.windowTitle() == "My Application"

def test_button_click(qtbot, app):
    qtbot.mouseClick(app.button, Qt.LeftButton)
    assert app.label.text() == "Button clicked"

def test_signal_emission(qtbot, app):
    with qtbot.waitSignal(app.valueChanged, timeout=1000):
        app.setValue(42)
```

```bash
# Run tests
pytest tests/
```

### Manual Testing

```python
# Add debug output
import logging
logging.basicConfig(level=logging.DEBUG)

# Check memory
from PySide6.QtCore import QObject
print(f"QObject children: {len(self.children())}")

# Dump widget tree
def dump_widgets(widget, indent=0):
    print(" " * indent + widget.objectName() or widget.__class__.__name__)
    for child in widget.findChildren(QObject):
        dump_widgets(child, indent + 2)
```

## Best Practices

### Application Setup

```python
import sys
from PySide6.QtWidgets import QApplication
from PySide6.QtCore import Qt

def main():
    # High DPI support
    QApplication.setAttribute(Qt.AA_EnableHighDpiScaling, True)
    QApplication.setAttribute(Qt.AA_UseHighDpiPixmaps, True)
    
    app = QApplication(sys.argv)
    app.setApplicationName("MyApp")
    app.setOrganizationName("MyCompany")
    
    window = MainWindow()
    window.show()
    
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
```

### Settings Management

```python
from PySide6.QtCore import QSettings

class Settings:
    def __init__(self):
        self.settings = QSettings("MyCompany", "MyApp")
    
    @property
    def window_geometry(self):
        return self.settings.value("window/geometry")
    
    @window_geometry.setter
    def window_geometry(self, value):
        self.settings.setValue("window/geometry", value)
    
    def save_window_state(self, window):
        self.settings.setValue("window/geometry", window.saveGeometry())
        self.settings.setValue("window/state", window.saveState())
    
    def restore_window_state(self, window):
        geometry = self.settings.value("window/geometry")
        if geometry:
            window.restoreGeometry(geometry)
        state = self.settings.value("window/state")
        if state:
            window.restoreState(state)
```

### Error Handling

```python
import traceback
from PySide6.QtWidgets import QMessageBox

def excepthook(exc_type, exc_value, exc_tb):
    tb = "".join(traceback.format_exception(exc_type, exc_value, exc_tb))
    QMessageBox.critical(None, "Error", f"An error occurred:\n\n{tb}")

sys.excepthook = excepthook
```

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "module not found" | `pip install PySide6` |
| High DPI blur | Enable AA_UseHighDpiPixmaps |
| Signals not working | Check Signal/Slot signatures match |
| UI freezing | Use QThread for long operations |
| Memory leak | Delete widgets with `.deleteLater()` |
| Import error | Check venv is activated |

### Debug Commands

```bash
# Check Qt version
python -c "from PySide6 import QtCore; print(QtCore.__version__)"

# List available modules
python -c "from PySide6 import QtWidgets; print(dir(QtWidgets))"

# Test installation
python -c "from PySide6.QtWidgets import QApplication; app = QApplication([])"
```

## References

- [Qt Documentation](https://doc.qt.io/qt-6/)
- [PySide6 Documentation](https://doc.qt.io/qtforpython/)
- [PyQt6 Documentation](https://www.riverbankcomputing.com/static/Docs/PyQt6/)
- [Qt Examples](https://doc.qt.io/qt-6/qtexamplesandtutorials.html)
- [Python GUI Programming](https://realpython.com/python-pyqt-gui-calculator/)
