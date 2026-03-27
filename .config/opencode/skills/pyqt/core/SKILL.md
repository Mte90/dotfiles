---
name: pyqt-core
description: "PyQt/PySide6 QtCore fundamentals - signals, slots, properties, timers, settings, file I/O"
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - python
    - qt
    - pyqt
    - pyside
    - core
    - signals
    - slots
---

# PyQt Core - QtCore Module

QtCore provides core non-GUI functionality: signals/slots, timers, settings, and file I/O.

## Overview

QtCore is the foundation of Qt. It provides:
- **Signal/Slot mechanism** - Type-safe event handling
- **Properties** - Bindable object properties
- **Timers** - Periodic and single-shot timers
- **Settings** - Persistent application configuration
- **File I/O** - Cross-platform file operations

## Signals and Slots

### Signal Declaration (PySide6)

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
    
    # Signal with optional arguments
    progressChanged = Signal(int, arguments=['percent'])
```

### Signal Declaration (PyQt6)

```python
from PyQt6.QtCore import QObject, pyqtSignal

class MyObject(QObject):
    valueChanged = pyqtSignal(int)
    nameChanged = pyqtSignal(str)
    positionChanged = pyqtSignal(int, int)
```

### Slot Declaration (PySide6)

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

### Slot Declaration (PyQt6)

```python
from PyQt6.QtCore import pyqtSlot

class MyObject(QObject):
    @pyqtSlot()
    def doSomething(self):
        pass
    
    @pyqtSlot(int)
    def setValue(self, value):
        pass
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

# Check connection
is_connected = button.clicked.isConnected(self.onButtonClick)

# Emit signal
self.valueChanged.emit(42)
self.positionChanged.emit(x, y)

# Block signals temporarily
button.blockSignals(True)
button.setChecked(True)
button.blockSignals(False)

# Get signal emission count
count = button.receivers(button.clicked)
```

### Connection Types

```python
from PySide6.QtCore import Qt

# Auto (default) - Direct if same thread, Queued if different
button.clicked.connect(self.handleClick, Qt.AutoConnection)

# Direct - Slot called immediately in signal's thread
button.clicked.connect(self.handleClick, Qt.DirectConnection)

# Queued - Slot called when control returns to receiver's thread
worker.finished.connect(self.onFinished, Qt.QueuedConnection)

# BlockingQueued - Blocks until slot completes (use carefully!)
worker.result.connect(self.handleResult, Qt.BlockingQueuedConnection)
```

## Properties

### Property Declaration

```python
from PySide6.QtCore import Property, Signal

class Person(QObject):
    nameChanged = Signal()
    
    def __init__(self):
        super().__init__()
        self._name = ""
    
    @Property(str, notify=nameChanged)
    def name(self):
        return self._name
    
    @name.setter
    def name(self, value):
        if self._name != value:
            self._name = value
            self.nameChanged.emit()
```

### Using Properties

```python
person = Person()
person.name = "Alice"  # Setter called
print(person.name)     # Getter called

# Connect to property change
person.nameChanged.connect(lambda: print("Name changed!"))
```

## QTimer

### Single-Shot Timer

```python
from PySide6.QtCore import QTimer

# Call function after 1000ms
QTimer.singleShot(1000, self.onTimer)

# With lambda
QTimer.singleShot(500, lambda: print("Delayed!"))

# Cancel single-shot (store reference)
self.timer_id = QTimer.singleShot(1000, self.delayedAction)
# Note: Can't cancel singleShot, use regular timer instead
```

### Periodic Timer

```python
from PySide6.QtCore import QTimer

class MyWidget(QWidget):
    def __init__(self):
        super().__init__()
        
        # Create timer
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.onTimeout)
        
        # Start with 100ms interval
        self.timer.start(100)
        
        # Or: self.timer.setInterval(100); self.timer.start()
    
    def onTimeout(self):
        print("Timer fired!")
    
    def stopTimer(self):
        self.timer.stop()
    
    def isRunning(self):
        return self.timer.isActive()
    
    def remainingTime(self):
        return self.timer.remainingTime()  # ms until next timeout
```

### Timer Properties

```python
timer = QTimer()

# Interval (milliseconds)
timer.setInterval(1000)  # 1 second
interval = timer.interval()

# Single-shot mode
timer.setSingleShot(True)  # Fires once then stops

# Timer type
timer.setTimerType(Qt.PreciseTimer)    # ~1ms accuracy
timer.setTimerType(Qt.CoarseTimer)     # ~5% accuracy (default)
timer.setTimerType(Qt.VeryCoarseTimer) # ~500ms accuracy
```

## QSettings

### Basic Usage

```python
from PySide6.QtCore import QSettings

# Create settings (uses app name from QApplication)
settings = QSettings("MyCompany", "MyApp")

# Write values
settings.setValue("window/geometry", self.saveGeometry())
settings.setValue("window/state", self.saveState())
settings.setValue("editor/fontSize", 12)
settings.setValue("editor/fontFamily", "Monospace")

# Read values
geometry = settings.value("window/geometry")
font_size = settings.value("editor/fontSize", 10)  # Default 10
font_family = settings.value("editor/fontFamily", "Consolas")

# Check if key exists
if settings.contains("editor/theme"):
    theme = settings.value("editor/theme")

# Remove key
settings.remove("editor/temp")

# Clear all
settings.clear()
```

### Settings Groups

```python
settings = QSettings("MyCompany", "MyApp")

# Using beginGroup/endGroup
settings.beginGroup("editor")
settings.setValue("fontSize", 12)
settings.setValue("fontFamily", "Monospace")
settings.endGroup()

# Using array
settings.beginWriteArray("recentFiles")
for i, filepath in enumerate(recent_files):
    settings.setArrayIndex(i)
    settings.setValue("path", filepath)
settings.endArray()

# Read array
size = settings.beginReadArray("recentFiles")
for i in range(size):
    settings.setArrayIndex(i)
    path = settings.value("path")
settings.endArray()
```

### Settings Format

```python
from PySide6.QtCore import QSettings

# Native format (registry on Windows, plist on macOS, conf on Linux)
settings = QSettings("MyCompany", "MyApp")

# INI file format
settings = QSettings("config.ini", QSettings.IniFormat)

# Custom file location
settings = QSettings("/path/to/settings.conf", QSettings.IniFormat)

# Get file path
print(settings.fileName())
```

## File I/O

### QFile

```python
from PySide6.QtCore import QFile, QIODevice

# Read file
file = QFile("data.txt")
if file.open(QIODevice.ReadOnly | QIODevice.Text):
    data = file.readAll()
    file.close()
    print(data)

# Write file
file = QFile("output.txt")
if file.open(QIODevice.WriteOnly | QIODevice.Text):
    file.write(b"Hello, World!")
    file.close()

# Append
file = QFile("log.txt")
if file.open(QIODevice.Append | QIODevice.Text):
    file.write(b"New log entry\n")
    file.close()

# Check exists
if QFile.exists("data.txt"):
    print("File exists")

# Remove file
QFile.remove("temp.txt")

# Copy file
QFile.copy("source.txt", "dest.txt")

# Rename file
QFile.rename("old.txt", "new.txt")
```

### QTextStream

```python
from PySide6.QtCore import QFile, QTextStream, QIODevice

# Read text
file = QFile("data.txt")
if file.open(QIODevice.ReadOnly | QIODevice.Text):
    stream = QTextStream(file)
    stream.setEncoding(QTextStream.Utf8)
    
    # Read all
    content = stream.readAll()
    
    # Read line by line
    while not stream.atEnd():
        line = stream.readLine()
        print(line)
    
    file.close()

# Write text
file = QFile("output.txt")
if file.open(QIODevice.WriteOnly | QIODevice.Text):
    stream = QTextStream(file)
    stream.setEncoding(QTextStream.Utf8)
    stream << "Line 1\n"
    stream << "Line 2\n"
    stream.writeString("Unicode: 你好")
    file.close()
```

### QDir

```python
from PySide6.QtCore import QDir

# Current directory
current = QDir.currentPath()
home = QDir.homePath()
temp = QDir.tempPath()

# Create directory
dir = QDir()
dir.mkpath("/path/to/new/directory")  # Creates all parent dirs

# Check if exists
if QDir("/path/to/dir").exists():
    print("Directory exists")

# List directory contents
dir = QDir("/path/to/dir")
entries = dir.entryList()  # Files and dirs
files = dir.entryList(QDir.Files)  # Only files
dirs = dir.entryList(QDir.Dirs | QDir.NoDotAndDotDot)  # Only subdirs

# With filters
entries = dir.entryList(["*.txt"], QDir.Files | QDir.Readable)

# Remove directory
QDir("/path/to/dir").rmdir(".")  # Must be empty
```

## Best Practices

### 1. Use Type Hints

```python
from PySide6.QtCore import Signal, Slot

class MyObject(QObject):
    valueChanged = Signal(int)
    
    @Slot(int)
    def setValue(self, value: int) -> None:
        self._value = value
```

### 2. Clean Up Timers

```python
class MyWidget(QWidget):
    def __init__(self):
        super().__init__()
        self.timer = QTimer(self)  # Parent ensures cleanup
    
    def closeEvent(self, event):
        self.timer.stop()
        super().closeEvent(event)
```

### 3. Use Settings Defaults

```python
# Always provide sensible defaults
font_size = settings.value("fontSize", 12, type=int)
theme = settings.value("theme", "dark")
```

### 4. Close Files

```python
# Use context manager pattern
file = QFile("data.txt")
if file.open(QIODevice.ReadOnly):
    try:
        data = file.readAll()
    finally:
        file.close()
```

## References

- **Qt for Python QtCore**: https://doc.qt.io/qtforpython-6/PySide6/QtCore/
- **Signals and Slots**: https://doc.qt.io/qtforpython-6/signalslot.html
- **QTimer**: https://doc.qt.io/qtforpython-6/PySide6/QtCore/QTimer.html
- **QSettings**: https://doc.qt.io/qtforpython-6/PySide6/QtCore/QSettings.html
- **QFile**: https://doc.qt.io/qtforpython-6/PySide6/QtCore/QFile.html
