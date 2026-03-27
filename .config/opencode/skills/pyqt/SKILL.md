---
name: pyqt
description: "PyQt/PySide6 overview hub - installation, comparison, project structure. See sub-skills for detailed topics."
metadata:
  author: OSS AI Skills
  version: 2.0.0
  tags:
    - python
    - qt
    - pyqt
    - pyside
    - gui
    - desktop
    - hub
---

# PyQt/PySide Development

PyQt and PySide are Python bindings for the Qt application framework for building cross-platform desktop applications.

## Sub-Skills

For detailed information, see the specialized sub-skills:

| Skill | Description | Path |
|-------|-------------|------|
| **pyqt-core** | Signals, slots, timers, settings, file I/O | [core/SKILL.md](core/SKILL.md) |
| **pyqt-widgets** | All widgets and layouts | [widgets/SKILL.md](widgets/SKILL.md) |
| **pyqt-threading** | QThread, thread pools, concurrency | [threading/SKILL.md](threading/SKILL.md) |
| **pyqt-dialogs** | Standard and custom dialogs | [dialogs/SKILL.md](dialogs/SKILL.md) |
| **pyqt-testing** | pytest-qt testing patterns | [testing/SKILL.md](testing/SKILL.md) |
| **pyqt-styling** | QSS styling and themes | [styling/SKILL.md](styling/SKILL.md) |

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

## Basic Application

```python
#!/usr/bin/env python3
import sys
from PySide6.QtWidgets import QApplication, QMainWindow, QLabel
from PySide6.QtCore import Qt

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("My Application")
        self.setGeometry(100, 100, 800, 600)
        
        label = QLabel("Hello, Qt!")
        label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.setCentralWidget(label)

def main():
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
```

## Recommended Project Structure

```
my_app/
├── src/
│   ├── __init__.py
│   ├── main.py
│   ├── main_window.py
│   ├── widgets/
│   │   ├── __init__.py
│   │   └── custom_widget.py
│   ├── models/
│   │   └── data_model.py
│   ├── resources/
│   │   ├── icons/
│   │   └── styles/
│   │       └── style.qss
│   └── utils/
│       └── helpers.py
├── tests/
│   └── test_main.py
├── requirements.txt
└── pyproject.toml
```

## Quick Reference

### Core Imports

```python
# QtWidgets - UI Components
from PySide6.QtWidgets import (
    QApplication, QMainWindow, QWidget,
    QLabel, QPushButton, QLineEdit, QTextEdit,
    QComboBox, QSpinBox, QCheckBox, QRadioButton,
    QSlider, QProgressBar, QGroupBox,
    QTabWidget, QStackedWidget, QSplitter,
    QListWidget, QTreeWidget, QTableWidget,
    QScrollArea, QToolBar, QStatusBar,
    QMenuBar, QMenu
)

# QtCore - Core Non-GUI
from PySide6.QtCore import (
    Qt, QObject, QTimer, QThread,
    Signal, Slot, Property,
    QSize, QPoint, QRect,
    QSettings, QFile, QDir,
    QUrl, QMimeData,
    QDateTime, QDate, QTime
)

# QtGui - Graphics
from PySide6.QtGui import (
    QIcon, QPixmap, QImage,
    QPainter, QPen, QBrush, QColor,
    QFont, QCursor,
    QKeySequence, QShortcut
)
```

### Signal/Slot Basics

```python
from PySide6.QtCore import QObject, Signal, Slot

class MyObject(QObject):
    valueChanged = Signal(int)
    
    @Slot(int)
    def setValue(self, value):
        self._value = value
        self.valueChanged.emit(value)

# Connect
button.clicked.connect(self.onButtonClick)

# Emit
self.valueChanged.emit(42)
```

### Layout Basics

```python
from PySide6.QtWidgets import QVBoxLayout, QHBoxLayout, QGridLayout, QFormLayout

# Vertical
layout = QVBoxLayout()
layout.addWidget(label)
layout.addWidget(button)

# Horizontal
h_layout = QHBoxLayout()
h_layout.addWidget(left)
h_layout.addWidget(right)

# Grid
grid = QGridLayout()
grid.addWidget(label, 0, 0)
grid.addWidget(input, 0, 1)

# Form
form = QFormLayout()
form.addRow("Name:", nameEdit)
```

## References

- **Qt for Python Documentation**: https://doc.qt.io/qtforpython-6/
- **PySide6 GitHub**: https://github.com/pyside/pyside-setup
- **PyQt6 Documentation**: https://www.riverbankcomputing.com/static/Docs/PyQt6/
- **pytest-qt**: https://pytest-qt.readthedocs.io/

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

Threading is essential for PyQt applications to keep the UI responsive while performing long-running operations. PyQt provides several approaches to multithreading.

### Thread Safety Rules

**CRITICAL**: Qt/PyQt is NOT thread-safe for UI operations. You must follow these rules:

1. **Never access widgets from worker threads** - Only the main thread can modify UI
2. **Use signals for cross-thread communication** - Emit signals from worker, connect to slots in main thread
3. **Use Qt.QueuedConnection for thread-safe signal delivery** - Default AutoConnection handles this automatically
4. **Never block the main thread** - Long operations will freeze the UI

```python
# ❌ WRONG: Direct UI access from thread
class BadWorker(QThread):
    def run(self):
        # This will crash or cause undefined behavior!
        self.label.setText("Done")

# ✅ CORRECT: Use signals
class GoodWorker(QThread):
    finished = Signal(str)
    
    def run(self):
        result = self.process_data()
        self.finished.emit(result)  # Signal emitted, UI updated in main thread
```

### QThread with Worker Object (Recommended Pattern)

The most flexible pattern separates the worker logic from thread lifecycle:

```python
from PySide6.QtCore import QThread, Signal, QObject, Slot

class Worker(QObject):
    """Worker object that does the actual work."""
    finished = Signal(object)
    progress = Signal(int)
    error = Signal(str)
    
    def __init__(self, data):
        super().__init__()
        self.data = data
        self._is_cancelled = False
    
    @Slot()
    def process(self):
        """Main processing method called from thread."""
        try:
            for i, item in enumerate(self.data):
                if self._is_cancelled:
                    return
                
                # Simulate heavy work
                result = self.process_item(item)
                self.progress.emit(int((i + 1) / len(self.data) * 100))
            
            self.finished.emit({"status": "success", "count": len(self.data)})
        except Exception as e:
            self.error.emit(str(e))
    
    def cancel(self):
        self._is_cancelled = True
    
    def process_item(self, item):
        # Override in subclass
        import time
        time.sleep(0.1)  # Simulate work
        return item * 2

class ThreadController(QObject):
    """Manages worker thread lifecycle."""
    def __init__(self):
        super().__init__()
        self.thread = None
        self.worker = None
    
    def start_work(self, data):
        # Create thread and worker
        self.thread = QThread()
        self.worker = Worker(data)
        
        # Move worker to thread
        self.worker.moveToThread(self.thread)
        
        # Connect signals
        self.worker.finished.connect(self.on_finished)
        self.worker.progress.connect(self.on_progress)
        self.worker.error.connect(self.on_error)
        
        # Thread lifecycle
        self.thread.started.connect(self.worker.process)
        self.thread.finished.connect(self.thread.deleteLater)
        
        # Start thread
        self.thread.start()
    
    def cancel_work(self):
        if self.worker:
            self.worker.cancel()
        if self.thread:
            self.thread.quit()
            self.thread.wait()
    
    @Slot()
    def on_finished(self, result):
        print(f"Work completed: {result}")
        self.cleanup()
    
    @Slot()
    def on_progress(self, percent):
        print(f"Progress: {percent}%")
    
    @Slot()
    def on_error(self, error):
        print(f"Error: {error}")
        self.cleanup()
    
    def cleanup(self):
        self.thread = None
        self.worker = None

# Usage in MainWindow
class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.controller = ThreadController()
        self.setup_ui()
    
    def setup_ui(self):
        self.button = QPushButton("Start Work")
        self.progress_bar = QProgressBar()
        self.cancel_button = QPushButton("Cancel")
        
        self.button.clicked.connect(self.start_work)
        self.cancel_button.clicked.connect(self.controller.cancel_work)
        
        # Connect controller signals to UI
        self.controller.worker.progress.connect(self.progress_bar.setValue)
    
    def start_work(self):
        data = list(range(100))
        self.controller.start_work(data)
```

### QThread Subclass (Simpler Pattern)

For simpler cases, subclass QThread directly:

```python
from PySide6.QtCore import QThread, Signal

class DataProcessor(QThread):
    """Thread that processes data and emits progress."""
    # Define signals at class level
    progress = Signal(int)
    result_ready = Signal(list)
    error_occurred = Signal(str)
    finished = Signal()
    
    def __init__(self, input_data, parent=None):
        super().__init__(parent)
        self.input_data = input_data
        self._cancelled = False
    
    def run(self):
        """Thread entry point - called by start()."""
        try:
            results = []
            total = len(self.input_data)
            
            for i, item in enumerate(self.input_data):
                # Check for cancellation
                if self._cancelled:
                    self.error_occurred.emit("Cancelled")
                    return
                
                # Process item (heavy work here)
                processed = self.process_item(item)
                results.append(processed)
                
                # Emit progress
                progress_percent = int((i + 1) / total * 100)
                self.progress.emit(progress_percent)
            
            # Emit results
            self.result_ready.emit(results)
            
        except Exception as e:
            self.error_occurred.emit(str(e))
        finally:
            self.finished.emit()
    
    def process_item(self, item):
        """Override this method for custom processing."""
        import time
        time.sleep(0.05)  # Simulate work
        return item.upper()
    
    def cancel(self):
        """Request thread cancellation."""
        self._cancelled = True

# Usage
class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.processor = None
        
        # UI setup
        self.progress = QProgressBar()
        self.start_btn = QPushButton("Start")
        self.cancel_btn = QPushButton("Cancel")
        
        self.start_btn.clicked.connect(self.start_processing)
        self.cancel_btn.clicked.connect(self.cancel_processing)
    
    def start_processing(self):
        data = ["item1", "item2", "item3", "item4", "item5"]
        
        self.processor = DataProcessor(data)
        
        # Connect signals
        self.processor.progress.connect(self.progress.setValue)
        self.processor.result_ready.connect(self.on_results)
        self.processor.error_occurred.connect(self.on_error)
        self.processor.finished.connect(self.on_finished)
        
        # Start thread
        self.processor.start()
        self.start_btn.setEnabled(False)
    
    def cancel_processing(self):
        if self.processor:
            self.processor.cancel()
    
    def on_results(self, results):
        print(f"Got {len(results)} results")
    
    def on_error(self, error):
        QMessageBox.warning(self, "Error", error)
    
    def on_finished(self):
        self.start_btn.setEnabled(True)
        self.progress.setValue(0)
        self.processor = None
```

### QThreadPool with QRunnable

For parallel execution of independent tasks:

```python
from PySide6.QtCore import QThreadPool, QRunnable, Signal, QObject
import time

class TaskSignals(QObject):
    """Signals for QRunnable (QRunnable cannot have signals directly)."""
    finished = Signal(object)
    error = Signal(str)
    progress = Signal(int)

class ParallelTask(QRunnable):
    """Runnable task for thread pool."""
    
    def __init__(self, task_id, data):
        super().__init__()
        self.task_id = task_id
        self.data = data
        self.signals = TaskSignals()
        self._cancelled = False
    
    def run(self):
        """Executed by thread pool."""
        try:
            # Simulate work
            time.sleep(0.5)
            
            if self._cancelled:
                return
            
            result = {
                "id": self.task_id,
                "processed": self.data.upper(),
                "thread": int(QThread.currentThreadId())
            }
            
            self.signals.finished.emit(result)
            
        except Exception as e:
            self.signals.error.emit(str(e))
    
    def cancel(self):
        self._cancelled = True

class ThreadPoolManager(QObject):
    """Manages parallel task execution."""
    all_finished = Signal(int)
    task_progress = Signal(int, int)  # task_id, progress
    
    def __init__(self, max_threads=4):
        super().__init__()
        self.pool = QThreadPool()
        self.pool.setMaxThreadCount(max_threads)
        self.active_tasks = {}
        self.completed_count = 0
        self.total_tasks = 0
    
    def run_parallel(self, tasks):
        """Run multiple tasks in parallel."""
        self.completed_count = 0
        self.total_tasks = len(tasks)
        self.active_tasks.clear()
        
        for task_id, data in enumerate(tasks):
            task = ParallelTask(task_id, data)
            task.signals.finished.connect(
                lambda result, tid=task_id: self.on_task_finished(result)
            )
            task.signals.error.connect(self.on_task_error)
            self.active_tasks[task_id] = task
            self.pool.start(task)
    
    def on_task_finished(self, result):
        self.completed_count += 1
        task_id = result["id"]
        del self.active_tasks[task_id]
        
        if self.completed_count >= self.total_tasks:
            self.all_finished.emit(self.completed_count)
    
    def on_task_error(self, error):
        print(f"Task error: {error}")
    
    def cancel_all(self):
        for task in self.active_tasks.values():
            task.cancel()
        self.active_tasks.clear()

# Usage
class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.pool_manager = ThreadPoolManager(max_threads=4)
        
        # UI
        self.run_btn = QPushButton("Run Parallel Tasks")
        self.status_label = QLabel("Ready")
        
        self.run_btn.clicked.connect(self.run_tasks)
        self.pool_manager.all_finished.connect(self.on_all_done)
    
    def run_tasks(self):
        tasks = [f"data_{i}" for i in range(10)]
        self.status_label.setText(f"Running {len(tasks)} tasks...")
        self.pool_manager.run_parallel(tasks)
    
    def on_all_done(self, count):
        self.status_label.setText(f"Completed {count} tasks")
```

### QTimer for Periodic Updates

 For polling or periodic checks:

```python
from PySide6.QtCore import QTimer, Slot

class PollingWidget(QWidget):
    """Widget that polls for updates periodically."""
    
    def __init__(self):
        super().__init__()
        
        # Create timer
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.on_timeout)
        
        # UI
        self.status_label = QLabel("Last update: Never")
        self.poll_btn = QPushButton("Start Polling")
        self.poll_btn.setCheckable(True)
        
        layout = QVBoxLayout(self)
        layout.addWidget(self.status_label)
        layout.addWidget(self.poll_btn)
        
        self.poll_btn.toggled.connect(self.toggle_polling)
    
    @Slot()
    def toggle_polling(self, checked):
        if checked:
            self.timer.start(1000)  # Poll every second
            self.poll_btn.setText("Stop Polling")
        else:
            self.timer.stop()
            self.poll_btn.setText("Start Polling")
    
    @Slot()
    def on_timeout(self):
        """Called every timeout milliseconds."""
        # Fetch updates (in real app, this might trigger a worker thread)
        from datetime import datetime
        self.status_label.setText(f"Last update: {datetime.now().strftime('%H:%M:%S')}")
```

### Qt Concurrent (QtConcurrent)

For map/filter/reduce operations on collections:

```python
from PySide6.QtConcurrent import QtConcurrent
from PySide6.QtCore import QFutureWatcher, QFuture

class ConcurrentProcessor(QObject):
    """Process data using QtConcurrent."""
    finished = Signal(list)
    
    def process_items(self, items):
        """Process items concurrently."""
        # Map function
        def process_item(item):
            import time
            time.sleep(0.1)  # Simulate work
            return item.upper()
        
        # Run concurrent map
        future = QtConcurrent.mapped(items, process_item)
        
        # Watch for completion
        self.watcher = QFutureWatcher()
        self.watcher.futureReady.connect(lambda: self.on_future_ready(future))
        self.watcher.setFuture(future)
    
    def on_future_ready(self, future):
        results = future.result()
        self.finished.emit(list(results))
```

### Thread-Safe Data Sharing

For sharing data between threads safely:

```python
from PySide6.QtCore import QMutex, QMutexLocker, QReadWriteLock

class SharedData:
    """Thread-safe data container."""
    
    def __init__(self):
        self._data = {}
        self._mutex = QMutex()
    
    def set_value(self, key, value):
        """Thread-safe write."""
        locker = QMutexLocker(self._mutex)
        self._data[key] = value
    
    def get_value(self, key, default=None):
        """Thread-safe read."""
        locker = QMutexLocker(self._mutex)
        return self._data.get(key, default)
    
    def get_all(self):
        """Thread-safe copy of all data."""
        locker = QMutexLocker(self._mutex)
        return dict(self._data)

class ReadWriteData:
    """Read-write lock for read-heavy workloads."""
    
    def __init__(self):
        self._data = {}
        self._lock = QReadWriteLock()
    
    def read_value(self, key):
        """Multiple readers can hold the lock."""
        self._lock.lockForRead()
        try:
            return self._data.get(key)
        finally:
            self._lock.unlock()
    
    def write_value(self, key, value):
        """Only one writer at a time."""
        self._lock.lockForWrite()
        try:
            self._data[key] = value
        finally:
            self._lock.unlock()
```

### Best Practices

1. **Always use signals for cross-thread communication**
2. **Keep worker objects thread-affinity aware** - Don't assume they're in main thread
3. **Clean up threads properly** - Use deleteLater() and quit() + wait()
4. **Handle cancellation** - Check flags periodically in long operations
5. **Use QThreadPool for parallel independent tasks**
6. **Use QThread.moveToThread() for single long operations**
7. **Never use time.sleep() in main thread** - Use timers or workers instead

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| UI freezes | Blocking operation in main thread | Move to worker thread |
| Crashes on widget access | Accessing UI from worker thread | Use signals instead |
| Memory leaks | Thread not cleaned up | Use deleteLater() and proper lifecycle |
| Deadlocks | Multiple mutexes acquired in different order | Always acquire in same order, use timeout |
| Race conditions | Shared data without locks | Use QMutex or atomic operations |

### Testing Threaded Code

```python
# test_threading.py
import pytest
from pytest_qt import QtBot
from PySide6.QtCore import QThread, Signal, QTimer
from unittest.mock import Mock

def test_worker_thread_emits_progress(qtbot):
    """Test that worker thread emits progress signals."""
    
    class TestWorker(QThread):
        progress = Signal(int)
        
        def run(self):
            for i in range(5):
                self.progress.emit(i * 20)
    
    worker = TestWorker()
    
    # Wait for signal
    with qtbot.waitSignal(worker.progress, timeout=1000):
        worker.start()
    
    # Check multiple signals
    signals = []
    worker.progress.connect(signals.append)
    
    worker.start()
    worker.wait()
    
    assert len(signals) == 5
    assert signals == [0, 20, 40, 60, 80]

def test_thread_cancellation(qtbot):
    """Test thread can be cancelled."""
    
    class CancellableWorker(QThread):
        finished = Signal()
        
        def __init__(self):
            super().__init__()
            self._cancelled = False
        
        def run(self):
            for i in range(100):
                if self._cancelled:
                    return
                import time
                time.sleep(0.01)
            self.finished.emit()
        
        def cancel(self):
            self._cancelled = True
    
    worker = CancellableWorker()
    worker.start()
    worker.cancel()
    worker.wait(100)  # Wait with timeout
    
    # Should not have emitted finished
    assert not hasattr(worker, '_finished_emitted')
```

## Testing with pytest-qt

pytest-qt provides specialized fixtures and utilities for testing Qt applications.

### Installation

```bash
pip install pytest-qt
```

### qtbot Fixture

The `qtbot` fixture provides methods for interacting with Qt widgets:

```python
import pytest
from pytest_qt import QtBot
from PySide6.QtWidgets import QApplication, QPushButton, QLabel
from PySide6.QtCore import Qt

def test_button_click(qtbot):
    """Test button click updates label."""
    button = QPushButton("Click Me")
    label = QLabel("Before")
    
    qtbot.addWidget(button)
    qtbot.addWidget(label)
    
    def on_click():
        label.setText("After")
    
    button.clicked.connect(on_click)
    
    # Simulate click
    qtbot.mouseClick(button, Qt.LeftButton)
    
    assert label.text() == "After"

def test_key_press(qtbot):
    """Test keyboard input."""
    from PySide6.QtWidgets import QLineEdit
    
    line_edit = QLineEdit()
    qtbot.addWidget(line_edit)
    
    # Type text
    qtbot.keyClicks(line_edit, "Hello World")
    
    assert line_edit.text() == "Hello World"
```

### waitSignal Context Manager

Wait for signals to be emitted:

```python
def test_async_operation(qtbot):
    """Test async operation completes."""
    from PySide6.QtCore import QThread, Signal
    
    class Worker(QThread):
        finished = Signal(str)
        
        def run(self):
            import time
            time.sleep(0.1)
            self.finished.emit("Done")
    
    worker = Worker()
    
    # Wait for signal with timeout
    with qtbot.waitSignal(worker.finished, timeout=1000) as blocker:
        worker.start()
    
    # Check signal argument
    assert blocker.args == ["Done"]

def test_multiple_signals(qtbot):
    """Wait for multiple signal emissions."""
    from PySide6.QtCore import QTimer
    
    timer = QTimer()
    timer.setInterval(100)
    
    # Wait for 3 emissions
    with qtbot.waitSignal(timer.timeout, timeout=500, raising=3):
        timer.start()
    
    timer.stop()
```

### waitActive and waitExposed

Wait for window activation/exposure:

```python
def test_window_activation(qtbot, qapp):
    """Test window becomes active."""
    from PySide6.QtWidgets import QWidget
    
    widget = QWidget()
    qtbot.addWidget(widget)
    
    widget.show()
    
    # Wait for window to be active
    with qtbot.waitActive(widget, timeout=1000):
        qapp.setActiveWindow(widget)

def test_window_exposed(qtbot):
    """Test window is exposed (visible on screen)."""
    from PySide6.QtWidgets import QWidget
    
    widget = QWidget()
    qtbot.addWidget(widget)
    
    # Show and wait for exposure
    with qtbot.waitExposed(widget, timeout=1000):
        widget.show()
```

### Testing QDialogs

```python
def test_dialog_acceptance(qtbot):
    """Test dialog accepted."""
    from PySide6.QtWidgets import QDialog, QDialogButtonBox
    
    class TestDialog(QDialog):
        def __init__(self):
            super().__init__()
            buttons = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
 self.rejected.connect(self.reject)
            buttons.accepted.connect(self.accept)
            
            layout = QVBoxLayout(self)
            layout.addWidget(buttons)
    
    dialog = TestDialog()
    
    # Keep reference to buttons
    ok_button = dialog.findChild(QDialogButtonBox).button(QDialogButtonBox.Ok)
    
    # Click OK in next event loop
    QTimer.singleShot(100, lambda: qtbot.mouseClick(ok_button, Qt.LeftButton))
    
    result = dialog.exec()
    
    assert result == QDialog.Accepted

def test_custom_dialog_values(qtbot):
    """Test custom dialog returns values."""
    from PySide6.QtWidgets import QDialog, QLineEdit, QVBoxLayout, QDialogButtonBox
    
    class InputDialog(QDialog):
        def __init__(self):
            super().__init__()
            
            self.line_edit = QLineEdit()
            self.line_edit.setPlaceholder("Enter name")
            
            buttons = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
            self.rejected.connect(self.reject)
            buttons.accepted.connect(self.accept)
            
            layout = QVBoxLayout(self)
            layout.addWidget(self.line_edit)
            layout.addWidget(buttons)
        
        def get_value(self):
            return self.line_edit.text()
    
    dialog = InputDialog()
    qtbot.addWidget(dialog)
    
    # Enter text
    qtbot.keyClicks(dialog.line_edit, "Test Name")
    
    # Accept dialog
    ok_button = dialog.findChild(QDialogButtonBox).button(QDialogButtonBox.Ok)
    QTimer.singleShot(100, lambda: qtbot.mouseClick(ok_button, Qt.LeftButton))
    
    result = dialog.exec()
    
    assert result == QDialog.Accepted
    assert dialog.get_value() == "Test Name"
```

### Testing Model/View

```python
def test_list_model(qtbot):
    """Test QAbstractListModel."""
    from PySide6.QtCore import QAbstractListModel, Qt
    
    class SimpleModel(QAbstractListModel):
        def __init__(self, data):
            super().__init__()
            self._data = data
        
        def rowCount(self, parent=None):
            return len(self._data)
        
        def data(self, index, role=Qt.DisplayRole):
            if 0 <= index < len(self._data):
                return self._data[index]
            return None
    
    model = SimpleModel(["Item 1", "Item 2", "Item 3"])
    
    assert model.rowCount() == 3
    assert model.data(0, Qt.DisplayRole) == "Item 2"

def test_model_updates(qtbot):
    """Test model signals data changes."""
    from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt
    
    class MutableModel(QAbstractListModel):
        def __init__(self):
            super().__init__()
            self._items = []
        
        def rowCount(self, parent=None):
            return len(self._items)
        
        def data(self, index, role=Qt.DisplayRole):
            if 1 <= index < len(self._items):
                return self._items[index]
            return None
        
        def add_item(self, item):
            self.beginInsertRows(QModelIndex(), len(self._items), len(self._items))
            self._items.append(item)
            self.endInsertRows()
    
    model = MutableModel()
    
    # Track dataChanged signal
    with qtbot.waitSignal(model.dataChanged, timeout=1000):
        model.add_item("New Item")
```

### Best Practices for pytest-qt

1. **Always use qtbot.addWidget()** to ensure proper cleanup
2. **Use waitSignal for async operations** with appropriate timeouts
3. **Avoid real delays** - use QTimer.singleShot for timing in tests
4. **Test signals not implementation** - verify behavior, not internal state
5. **Use qapp fixture** when you need QApplication instance
6. **Clean up resources** - qtbot handles widget cleanup automatically

### Common Testing Patterns

```python
# conftest.py - Shared fixtures
import pytest
from pytest_qt import QtBot
from PySide6.QtWidgets import QApplication
from PySide6.QtCore import QDir, QSettings

@pytest.fixture
def app(qapp):
    """Create application instance."""
    return qapp

@pytest.fixture
def temp_dir(tmp_path):
    """Create temporary directory."""
    import pathlib
    d = pathlib.Path(tmp_path) / "test_data"
    d.mkdir(exist_ok=True)
    return d

@pytest.fixture
def main_window(app, qtbot, temp_dir):
    """Create main window with dependencies."""
    from myapp.main_window import MainWindow
    
    window = MainWindow()
    qtbot.addWidget(window)
    window.show()
    
    return window

def test_main_window_loads(main_window, qtbot):
    """Test main window initializes correctly."""
    assert main_window.windowTitle() == "My App"
    assert main_window.isVisible()

def test_settings_persistence(main_window, qtbot, temp_dir):
    """Test settings are persisted."""
    # Change setting
    main_window.settings.setValue("test_key", "test_value")
    
    # Verify saved
    settings = QSettings(main_window.settings.organization(), main_window.settings.application())
    assert settings.value("test_key") == "test_value"
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
