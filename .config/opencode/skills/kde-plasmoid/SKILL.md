---
name: kde-plasmoid
description: Use when building KDE Plasma 6 widgets with a Python backend - plasmoid structure, metadata.json, QML UI, configuration system, plasmapkg2 packaging, KDE Store submission, or plasmoid testing and debugging
metadata:
  author: mte90
  version: 2.0.0
  tags:
    - kde
    - plasma
    - plasmoid
    - widget
    - qml
    - qt
    - desktop
---

# KDE Plasmoid Development with Python

Complete guide for developing Plasma widgets (Plasmoids) using Python backend with QML UI layer.

## Overview

**Important**: Native Python Plasmoids (PyKDE4/PyKDE5) are **deprecated** in Plasma 6. Modern Plasmoids must use:
- **UI Layer**: QML with Kirigami components
- **Backend Logic**: Python (PySide6 or PyQt6) via QObject subclasses

### Architecture

```
┌─────────────────────────────────────┐
│         QML UI Layer                │
│   (PlasmoidItem + Kirigami)         │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│       Python Backend Logic          │
│   (QObject-derived classes)         │
└─────────────────────────────────────┘
```

## Version Requirements

| Component | Version |
|-----------|---------|
| Plasma | 6.x |
| Qt | 6.x |
| Python | 3.8+ |
| PySide6/PyQt6 | 6.x |

## Dependencies

### System Packages

```bash
# Arch/Manjaro
sudo pacman -S python-pyqt6 pyside6 kirigami plasma-framework plasma-sdk

# Fedora
sudo dnf install python3-pyqt6 python3-pyside6 kf6-kirigami-devel plasma-framework plasma-sdk

# Debian/Ubuntu
sudo apt install python3-pyqt6 python3-pyside6 kirigami-devel plasma-framework plasma-sdk

# openSUSE
sudo zypper install python3-qt6 python3-pyside6 kf6-kirigami-devel plasma-framework
```

### Python Packages

```bash
pip install psutil requests pydbus
```

## Plasmoid Structure

```
my-plasmoid/
├── package/
│   ├── contents/
│   │   ├── config/
│   │   │   ├── config.qml
│   │   │   └── main.xml
│   │   ├── ui/
│   │   │   ├── main.qml
│   │   │   └── configGeneral.qml
│   │   └── main.xml
│   └── metadata.json
├── src/
│   ├── __init__.py
│   └── backend.py
├── README.md
└── LICENSE
```

## Python Backend

### Basic Backend Class

```python
#!/usr/bin/env python3
"""Python backend for Plasma widget"""

from PySide6.QtCore import QObject, Signal, Slot, Property
# OR PyQt6:
# from PyQt6.QtCore import QObject, pyqtSignal as Signal, pyqtSlot as Slot, pyqtProperty as Property

class WidgetBackend(QObject):
    """Backend logic exposed to QML"""
    
    # Signals
    dataUpdated = Signal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._data = "Initial Value"
        self._count = 0
    
    # Properties (exposed to QML)
    @Property(str, notify=dataUpdated)
    def data(self):
        return self._data
    
    @data.setter
    def data(self, value):
        if self._data != value:
            self._data = value
            self.dataUpdated.emit()
    
    @Property(int, notify=dataUpdated)
    def count(self):
        return self._count
    
    # Slots (callable from QML)
    @Slot(result=str)
    def getData(self):
        return self._data
    
    @Slot(str)
    def setData(self, value):
        self.data = value
    
    @Slot(str, result=str)
    def processData(self, inputText):
        """Process input and return result"""
        return f"Processed: {inputText}"
    
    @Slot()
    def refresh(self):
        """Refresh data"""
        self._count += 1
        self._data = f"Updated #{self._count}"
        self.dataUpdated.emit()
    
    @Slot(str, result=str)
    def getSystemInfo(self, category):
        """Get system information"""
        import psutil
        
        if category == "cpu":
            return f"{psutil.cpu_percent():.1f}%"
        elif category == "memory":
            mem = psutil.virtual_memory()
            return f"{mem.percent:.1f}%"
        elif category == "disk":
            disk = psutil.disk_usage('/')
            return f"{disk.percent:.1f}%"
        return "Unknown"
```

### PySide6 vs PyQt6

| Feature | PySide6 | PyQt6 |
|---------|---------|-------|
| Signal | `Signal` | `pyqtSignal` |
| Slot | `Slot` | `pyqtSlot` |
| Property | `Property` | `pyqtProperty` |
| License | LGPL | GPL |
| QML Registration | `@QmlElement` decorator | `qmlRegisterType()` |

**PySide6 Registration:**
```python
from PySide6.QtQml import QmlElement

QML_IMPORT_NAME = "com.example.widget"
QML_IMPORT_MAJOR_VERSION = 1

@QmlElement
class WidgetBackend(QObject):
    pass
```

**PyQt6 Registration:**
```python
from PyQt6.QtQml import qmlRegisterType

qmlRegisterType(WidgetBackend, "com.example.widget", 1, 0, "WidgetBackend")
```

## QML UI

### main.qml

```qml
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.0 as Kirigami
import com.example.widget 1.0

PlasmoidItem {
    id: root
    
    // Backend instance
    WidgetBackend {
        id: backend
    }
    
    // Full representation (expanded widget)
    Plasmoid.fullRepresentation: Kirigami.Card {
        implicitWidth: Kirigami.Units.gridUnit * 20
        implicitHeight: Kirigami.Units.gridUnit * 15
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing
            
            // Title
            PlasmaComponents3.Label {
                text: Plasmoid.configuration.customLabel || "My Widget"
                font.bold: true
                font.pointSize: Kirigami.Units.gridUnit * 1.2
                Layout.fillWidth: true
            }
            
            // Data display
            PlasmaComponents3.Label {
                text: backend.data
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            
            // System info
            RowLayout {
                Layout.fillWidth: true
                
                PlasmaComponents3.Label {
                    text: "CPU: " + backend.getSystemInfo("cpu")
                }
                
                PlasmaComponents3.Label {
                    text: "RAM: " + backend.getSystemInfo("memory")
                }
            }
            
            // Input field
            PlasmaComponents3.TextField {
                id: inputField
                placeholderText: "Enter text..."
                Layout.fillWidth: true
            }
            
            // Buttons
            RowLayout {
                Layout.fillWidth: true
                
                PlasmaComponents3.Button {
                    text: "Process"
                    onClicked: backend.processData(inputField.text)
                }
                
                PlasmaComponents3.Button {
                    text: "Refresh"
                    icon.name: "view-refresh"
                    onClicked: backend.refresh()
                }
            }
        }
    }
    
    // Compact representation (panel icon)
    Plasmoid.compactRepresentation: PlasmaCore.IconItem {
        source: Plasmoid.icon
        anchors.centerIn: parent
        
        implicitWidth: {
            if (Plasmoid.location === PlasmaCore.Types.HorizontalPanel ||
                Plasmoid.location === PlasmaCore.Types.VerticalPanel) {
                return Kirigami.Units.iconSizes.medium
            }
            return Kirigami.Units.iconSizes.large
        }
        implicitHeight: implicitWidth
        
        MouseArea {
            anchors.fill: parent
            onClicked: Plasmoid.expanded = !Plasmoid.expanded
        }
    }
    
    // Tooltip
    Plasmoid.toolTipMainText: "My Widget"
    Plasmoid.toolTipSubText: backend.data
    
    // Icon
    Plasmoid.icon: "utilities-system-monitor"
}
```

### Plasma 6 QML Imports

```qml
// Correct Plasma 6 imports (no version numbers for most)
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.0 as Kirigami
```

## Best Practices

### Python Backend

```python
# ✅ GOOD: Signal-based updates
class Backend(QObject):
    dataChanged = Signal()
    
    def updateData(self):
        self._data = compute()
        self.dataChanged.emit()

# ✅ GOOD: Lazy initialization
@Slot(result=str)
def expensiveData(self):
    if not hasattr(self, '_cached'):
        self._cached = self._computeExpensive()
    return self._cached

# ❌ BAD: Blocking main thread
@Slot(result=str)
def slowOperation(self):
    time.sleep(5)  # Blocks UI
```

### QML UI

```qml
// ✅ GOOD: Use Kirigami units for scaling
width: Kirigami.Units.gridUnit * 10
spacing: Kirigami.Units.smallSpacing

// ✅ GOOD: Handle configuration defaults
text: plasmoid.configuration.label || i18n("Default")

// ❌ BAD: Hardcoded values
width: 320  // Won't scale on HiDPI
```

### Performance

```python
# Use Timer for periodic updates
from PySide6.QtCore import QTimer

class Backend(QObject):
    def __init__(self):
        self._timer = QTimer()
        self._timer.timeout.connect(self.refresh)
        self._timer.start(60000)  # 60 seconds
```

## Deep Dives

Refer to these on-demand reference files for detailed topics:

- **Configuration System** — `references/configuration.md`: metadata.json schema, KCFG main.xml, config.qml, configGeneral.qml, property aliases with cfg_ prefix
- **Packaging & Publishing** — `references/packaging-publishing.md`: plasmapkg2 CLI, .plasmoid package creation, local/system deployment, KDE Store submission workflow
- **Testing & Debugging** — `references/testing-debugging.md`: plasmoidtest tool, exit codes, troubleshooting guide, unit/integration tests, debug logging

## References

- [Plasma Widget Tutorial](https://develop.kde.org/docs/plasma/widget/)
- [Porting to KF6](https://develop.kde.org/docs/plasma/widget/porting_kf6/)
- [Python + Kirigami](https://develop.kde.org/docs/getting-started/python/)
- [QML API Reference](https://develop.kde.org/docs/plasma/widget/plasma-qml-api/)
- [KDE Store](https://store.kde.org/)
- [Kirigami Documentation](https://develop.kde.org/docs/kirigami/)
- [plasmapkg2 Tool](https://apps.kde.org/plasmapkg2/)