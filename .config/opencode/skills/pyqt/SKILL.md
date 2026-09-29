---
name: pyqt
description: Use when building cross-platform desktop apps with PyQt6 or PySide6 - hub for installation, project structure, signals and slots basics, and pointers to widgets, styling, dialogs, threading, and testing sub-skills
metadata:
  author: mte90
  version: 3.0.0
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
| **pyqt-multimedia** | Audio, video, camera, recording | [multimedia/SKILL.md](multimedia/SKILL.md) |

## Deep Dives

Load these sub-skills for specialized topics:

- **Signals/slots deep dive** → `pyqt/core` - Signal declaration, slot decorators, connections, typed signals
- **Widgets, layouts, item views, event handling** → `pyqt/widgets` - Display/input/container widgets, QVBoxLayout/QHBoxLayout/QGridLayout, event filters, shortcuts
- **QSS styling and dark theme** → `pyqt/styling` - QSS syntax, pseudo-states, widget-specific styles, property-based styling
- **Dialogs** → `pyqt/dialogs` - Standard dialogs (QFileDialog, QMessageBox, QInputDialog), custom QDialog patterns, modal/modeless
- **Threading patterns** → `pyqt/threading` - QThread worker-object pattern, QThreadPool/QRunnable, thread safety, cancellation
- **pytest-qt testing** → `pyqt/testing` - qtbot fixture, waitSignal, mouse/keyboard simulation, dialog testing, model/view testing

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
from PySide6.QtWidgets import QApplication, QMainWindow, QWidget, QLabel, QPushButton, QLineEdit, QTextEdit, QComboBox, QSpinBox, QCheckBox, QSlider, QProgressBar, QGroupBox, QTabWidget, QStackedWidget, QSplitter, QListWidget, QTreeWidget, QTableWidget, QScrollArea, QToolBar, QStatusBar
from PySide6.QtCore import Qt, QObject, QTimer, QThread, Signal, Slot, Property, QSize, QPoint, QRect, QSettings, QFile, QDir, QUrl, QMimeData, QDateTime
from PySide6.QtGui import QIcon, QPixmap, QImage, QPainter, QPen, QBrush, QColor, QFont, QCursor, QKeySequence, QShortcut
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

### Common Properties

```python
widget.setEnabled(True)  # Enable/disable
widget.setVisible(False)  # Visibility
widget.setToolTip("Help")  # Tooltip
widget.setObjectName("myButton")  # QSS selector
widget.setProperty("primary", True)  # Custom property
```

### Dialogs

```python
filename, _ = QFileDialog.getOpenFileName(self, "Open", "", "Files (*)")
filename, _ = QFileDialog.getSaveFileName(self, "Save", "", "Text (*.txt)")
directory = QFileDialog.getExistingDirectory(self, "Select")
reply = QMessageBox.question(self, "Confirm", "Continue?", QMessageBox.Yes | QMessageBox.No)
text, ok = QInputDialog.getText(self, "Input", "Name:")
color = QColorDialog.getColor()
font, ok = QFontDialog.getFont()
```

### Threading

```python
# Worker pattern
class Worker(QObject):
    finished = Signal(object)
    @Slot()
    def process(self): self.finished.emit(result)

thread = QThread()
worker = Worker()
worker.moveToThread(thread)
thread.started.connect(worker.process)
worker.finished.connect(thread.quit)
thread.start()

# Thread pool
pool = QThreadPool()
pool.start(QRunnable(task))
```

## Packaging & Distribution

### PyInstaller

```bash
# Install
pip install pyinstaller

# Single executable
pyinstaller --onefile --windowed app.py

# With icon and data files
pyinstaller --onefile --windowed --icon=app.ico --add-data "resources:resources" app.py
```

### PyInstaller Spec File

```python
# app.spec
a = Analysis(
    ['app.py'],
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
    noarchive=False,
)
pyz = PYZ(a.pure, a.zipped_data)
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
    icon='app.ico',
)
```

### cx_Freeze

```python
# setup.py
from cx_Freeze import setup, Executable

build_options = {
    'packages': ['PySide6'],
    'excludes': ['tkinter'],
    'include_files': [('resources', 'resources')]
}

setup(
    name='MyApp',
    version='1.0',
    description='My Qt Application',
    options={'build_exe': build_options},
    executables=[Executable('app.py', base='Win32GUI', icon='app.ico')]
)
```

### Build Commands

```bash
# PyInstaller
pyinstaller --clean app.spec

# cx_Freeze
python setup.py build

# Create distribution
pyinstaller --clean --distpath dist app.spec
```

### Distribution Checklist

- [ ] Test on clean VM (no Python installed)
- [ ] Verify all assets bundled (icons, QSS, translations)
- [ ] Check executable size (strip debug symbols if needed)
- [ ] Test on target OS versions
- [ ] Sign executable (Windows/macOS)
- [ ] Create installer (optional: NSIS, Inno Setup, dmgbuild)

## Best Practices

### Architecture

1. **Separate UI from business logic** - Use MVC or MVVM patterns
2. **Use dependency injection** - Pass dependencies to constructors
3. **Keep widgets stateless** - Store state in models, not widgets
4. **Use signals for decoupling** - Components communicate via signals
5. **Lazy load heavy resources** - Load images/data on demand

### Performance

1. **Avoid blocking the main thread** - Use workers for long operations
2. **Use view delegates for complex item rendering** - Don't subclass QItemDelegate unnecessarily
3. **Batch UI updates** - Block signals during bulk changes
4. **Reuse widgets** - Pool frequently created widgets
5. **Profile before optimizing** - Use `python -m cProfile`

### Memory Management

1. **Use parent-child relationships** - Qt auto-cleans children
2. **Call `deleteLater()` for dynamic widgets** - Don't use `del` directly
3. **Break signal/slot connections** - Disconnect before deleting
4. **Avoid circular references** - Use weak references where needed
5. **Monitor with `tracemalloc`** - Find memory leaks

### Code Organization

1. **One class per file** - Keep modules focused
2. **Group related widgets** - Custom widgets in separate modules
3. **Centralize constants** - Use enums for fixed values
4. **Use type hints** - Helps with IDE support and debugging
5. **Document public APIs** - Docstrings for methods and classes

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| UI freezes | Blocking operation in main thread | Move to worker thread |
| Crashes on widget access | Accessing UI from worker thread | Use signals instead |
| Memory leaks | Objects not cleaned up | Use parent-child relationships, `deleteLater()` |
| QSS not applying | Wrong selector or syntax | Check widget objectName, use `style().polish()` |
| Signals not firing | Wrong connection type | Verify signal declaration, check thread affinity |
| High CPU usage | Tight loop in main thread | Use timers or workers |
| Window not showing | Missing `show()` call | Call `window.show()` before `app.exec()` |
| Icons not loading | Wrong path or format | Use `QResource` for bundled assets |

### Debugging Tips

```python
# Enable Qt logging
import logging
logging.basicConfig(level=logging.DEBUG)

# Check for unhandled exceptions
import sys
sys.excepthook = lambda exc: print(f"Unhandled: {exc}")

# Print widget hierarchy
print(window.findChildren(QWidget))

# Check signal connections
print(button.receivers(button.clicked))

# Dump QSS errors
app.setStyleSheet("INVALID {")  # Will print parse errors
```

## References

- [Official Qt Documentation](https://doc.qt.io/)
- [PySide6 Documentation](https://doc.qt.io/qtforpython-6/)
- [PyQt6 Documentation](https://www.riverbankcomputing.com/static/Docs/PyQt6/)
- [Qt Examples](https://doc.qt.io/qt-6/examples-and-tutorials.html)
- [pytest-qt Documentation](https://pytest-qt.readthedocs.io/)