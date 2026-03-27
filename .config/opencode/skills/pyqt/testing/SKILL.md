---
name: pyqt-testing
description: "PyQt/PySide6 testing with pytest-qt - qtbot fixture, waitSignal, mouse/keyboard simulation, dialog testing"
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - python
    - qt
    - pyqt
    - pyside
    - testing
    - pytest
    - tdd
---

# PyQt Testing - pytest-qt

Comprehensive guide to testing Qt applications with pytest-qt.

## Installation

```bash
pip install pytest-qt
```

## qtbot Fixture

The `qtbot` fixture provides methods for interacting with Qt widgets:

```python
import pytest
from PySide6.QtWidgets import QApplication, QPushButton, QLabel
from PySide6.QtCore import Qt

def test_button_click(qtbot):
    """Test button click updates label."""
    button = QPushButton("Click Me")
    label = QLabel("Before")
    
    # Register widgets for cleanup
    qtbot.addWidget(button)
    qtbot.addWidget(label)
    
    def on_click():
        label.setText("After")
    
    button.clicked.connect(on_click)
    
    # Simulate click
    qtbot.mouseClick(button, Qt.MouseButton.LeftButton)
    
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

## Mouse and Keyboard Simulation

```python
from PySide6.QtCore import Qt
from PySide6.QtWidgets import QPushButton, QLineEdit, QCheckBox

def test_mouse_buttons(qtbot):
    """Test different mouse buttons."""
    button = QPushButton("Test")
    qtbot.addWidget(button)
    
    clicks = []
    button.clicked.connect(lambda: clicks.append("left"))
    
    # Left click
    qtbot.mouseClick(button, Qt.MouseButton.LeftButton)
    
    # Right click
    qtbot.mouseClick(button, Qt.MouseButton.RightButton)
    
    # Double click
    qtbot.mouseDClick(button, Qt.MouseButton.LeftButton)
    
    assert clicks == ["left"]

def test_keyboard_modifiers(qtbot):
    """Test keyboard with modifiers."""
    line_edit = QLineEdit()
    qtbot.addWidget(line_edit)
    
    line_edit.setFocus()
    
    # Type with Ctrl held
    qtbot.keyClicks(line_edit, "a", Qt.KeyboardModifier.ControlModifier)
    
    # Press specific key
    qtbot.keyPress(line_edit, Qt.Key.Key_Return)
    qtbot.keyRelease(line_edit, Qt.Key.Key_Enter)

def test_checkbox_toggle(qtbot):
    """Test checkbox interaction."""
    checkbox = QCheckBox("Test")
    qtbot.addWidget(checkbox)
    
    # Click to check
    qtbot.mouseClick(checkbox, Qt.MouseButton.LeftButton)
    assert checkbox.isChecked()
    
    # Click to uncheck
    qtbot.mouseClick(checkbox, Qt.MouseButton.LeftButton)
    assert not checkbox.isChecked()
```

## waitSignal

Wait for signals to be emitted:

```python
from PySide6.QtCore import QThread, Signal, QTimer

def test_wait_signal(qtbot):
    """Test waiting for signal."""
    
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

def test_wait_multiple_signals(qtbot):
    """Wait for multiple signal emissions."""
    timer = QTimer()
    timer.setInterval(100)
    
    # Wait for 3 emissions
    with qtbot.waitSignal(timer.timeout, timeout=500, raising=3):
        timer.start()
    
    timer.stop()

def test_wait_signals_any(qtbot):
    """Wait for any of multiple signals."""
    timer1 = QTimer()
    timer2 = QTimer()
    
    timer1.setInterval(200)
    timer2.setInterval(100)
    
    # Returns when either signal fires
    with qtbot.waitSignals([timer1.timeout, timer2.timeout], timeout=1000):
        timer2.start()  # This one will fire first
        timer1.start()
    
    timer1.stop()
    timer2.stop()
```

## waitActive and waitExposed

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

## Testing Dialogs

```python
from PySide6.QtWidgets import QDialog, QDialogButtonBox, QVBoxLayout
from PySide6.QtCore import QTimer

def test_dialog_accept(qtbot):
    """Test dialog accepted."""
    
    class TestDialog(QDialog):
        def __init__(self):
            super().__init__()
            buttons = QDialogButtonBox(
                QDialogButtonBox.StandardButton.Ok |
                QDialogButtonBox.StandardButton.Cancel
            )
            buttons.accepted.connect(self.accept)
            buttons.rejected.connect(self.reject)
            
            layout = QVBoxLayout(self)
            layout.addWidget(buttons)
    
    dialog = TestDialog()
    
    # Find OK button
    button_box = dialog.findChild(QDialogButtonBox)
    ok_button = button_box.button(QDialogButtonBox.StandardButton.Ok)
    
    # Click OK after dialog opens
    QTimer.singleShot(100, lambda: qtbot.mouseClick(ok_button, Qt.MouseButton.LeftButton))
    
    result = dialog.exec()
    
    assert result == QDialog.DialogCode.Accepted

def test_custom_dialog_values(qtbot):
    """Test custom dialog returns values."""
    
    class InputDialog(QDialog):
        def __init__(self):
            super().__init__()
            
            from PySide6.QtWidgets import QLineEdit
            
            self.line_edit = QLineEdit()
            self.line_edit.setPlaceholderText("Enter name")
            
            buttons = QDialogButtonBox(
                QDialogButtonBox.StandardButton.Ok |
                QDialogButtonBox.StandardButton.Cancel
            )
            buttons.accepted.connect(self.accept)
            buttons.rejected.connect(self.reject)
            
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
    button_box = dialog.findChild(QDialogButtonBox)
    ok_button = button_box.button(QDialogButtonBox.StandardButton.Ok)
    QTimer.singleShot(100, lambda: qtbot.mouseClick(ok_button, Qt.MouseButton.LeftButton))
    
    result = dialog.exec()
    
    assert result == QDialog.DialogCode.Accepted
    assert dialog.get_value() == "Test Name"
```

## Testing Model/View

```python
from PySide6.QtCore import QAbstractListModel, Qt, QModelIndex

def test_list_model(qtbot):
    """Test QAbstractListModel."""
    
    class SimpleModel(QAbstractListModel):
        def __init__(self, data):
            super().__init__()
            self._data = data
        
        def rowCount(self, parent=QModelIndex()):
            return len(self._data)
        
        def data(self, index, role=Qt.ItemDataRole.DisplayRole):
            if 0 <= index.row() < len(self._data):
                return self._data[index.row()]
            return None
    
    model = SimpleModel(["Item 1", "Item 2", "Item 3"])
    
    assert model.rowCount() == 3
    index = model.index(1, 0)
    assert model.data(index, Qt.ItemDataRole.DisplayRole) == "Item 2"

def test_model_updates(qtbot):
    """Test model signals data changes."""
    
    class MutableModel(QAbstractListModel):
        def __init__(self):
            super().__init__()
            self._items = []
        
        def rowCount(self, parent=QModelIndex()):
            return len(self._items)
        
        def data(self, index, role=Qt.ItemDataRole.DisplayRole):
            if 0 <= index.row() < len(self._items):
                return self._items[index.row()]
            return None
        
        def add_item(self, item):
            self.beginInsertRows(QModelIndex(), len(self._items), len(self._items))
            self._items.append(item)
            self.endInsertRows()
    
    model = MutableModel()
    
    # Wait for rowsInserted signal
    with qtbot.waitSignal(model.rowsInserted, timeout=1000):
        model.add_item("New Item")
    
    assert model.rowCount() == 1
```

## Testing Threaded Code

```python
from PySide6.QtCore import QThread, Signal

def test_worker_thread(qtbot):
    """Test worker thread emits signals."""
    
    class TestWorker(QThread):
        progress = Signal(int)
        
        def run(self):
            for i in range(5):
                self.progress.emit(i * 20)
    
    worker = TestWorker()
    
    # Collect signals
    signals = []
    worker.progress.connect(signals.append)
    
    # Wait for thread to finish
    with qtbot.waitSignal(worker.finished, timeout=2000):
        worker.start()
    
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
    
    # Should have finished quickly due to cancellation
    assert not worker.isRunning()
```

## Fixtures

```python
# conftest.py - Shared fixtures
import pytest
from PySide6.QtWidgets import QApplication, QMainWindow

@pytest.fixture(scope="session")
def qapp():
    """Create QApplication once per session."""
    app = QApplication.instance()
    if app is None:
        app = QApplication([])
    yield app

@pytest.fixture
def main_window(qtbot):
    """Create main window for each test."""
    window = QMainWindow()
    qtbot.addWidget(window)
    window.show()
    return window

@pytest.fixture
def temp_settings(tmp_path):
    """Create temporary QSettings."""
    from PySide6.QtCore import QSettings
    import pathlib
    
    config_file = pathlib.Path(tmp_path) / "test.ini"
    settings = QSettings(str(config_file), QSettings.Format.IniFormat)
    yield settings
    settings.clear()
```

## Best Practices

1. **Always use qtbot.addWidget()** - Ensures proper cleanup
2. **Use waitSignal for async operations** - With appropriate timeouts
3. **Avoid real delays** - Use QTimer.singleShot for timing
4. **Test signals, not implementation** - Verify behavior
5. **Use fixtures for common setup** - DRY principle
6. **Keep tests isolated** - Each test should be independent

## References

- **pytest-qt**: https://pytest-qt.readthedocs.io/
- **Qt for Python Testing**: https://doc.qt.io/qtforpython-6/
- **pytest**: https://docs.pytest.org/
