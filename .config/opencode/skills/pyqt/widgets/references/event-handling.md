# Event Handling - Deep Dive

This file is loaded on demand from frameworks/pyqt/widgets/SKILL.md for detailed event handling reference.

## Override Event Handlers

```python
from PySide6.QtWidgets import QWidget, QMessageBox
from PySide6.QtCore import Qt
from PySide6.QtGui import QPainter, QPen

class MyWidget(QWidget):
    def mousePressEvent(self, event):
        if event.button() == Qt.MouseButton.LeftButton:
            print("Left click at", event.pos())
        event.accept()
    
    def keyPressEvent(self, event):
        if event.key() == Qt.Key.Key_Escape:
            self.close()
        elif event.key() == Qt.Key.Key_Return:
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
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )
        if reply == QMessageBox.StandardButton.Yes:
            event.accept()
        else:
            event.ignore()
```

## Event Filters

```python
from PySide6.QtWidgets import QMainWindow
from PySide6.QtCore import QEvent, Qt

class MyWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.textEdit.installEventFilter(self)
    
    def eventFilter(self, obj, event):
        if obj == self.textEdit and event.type() == QEvent.Type.KeyPress:
            if event.key() == Qt.Key.Key_Tab:
                # Handle tab key specially
                return True
        return super().eventFilter(obj, event)
```

## Shortcuts

```python
from PySide6.QtGui import QKeySequence, QShortcut
from PySide6.QtWidgets import QApplication

# Create shortcut
shortcut = QShortcut(QKeySequence("Ctrl+S"), self)
shortcut.activated.connect(self.save)

# Common sequences
QKeySequence.Save  # Ctrl+S
QKeySequence.Open  # Ctrl+O
QKeySequence.Copy  # Ctrl+C
QKeySequence.Paste # Ctrl+V
QKeySequence.Quit  # Ctrl+Q

# Custom shortcut
shortcut = QShortcut(QKeySequence("Ctrl+Shift+R"), self)
shortcut.activated.connect(self.refresh)

# Context-sensitive shortcuts
self.addAction(QShortcut(QKeySequence("F1"), self, self.showHelp))
```