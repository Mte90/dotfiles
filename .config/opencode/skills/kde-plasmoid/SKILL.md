---
name: kde-plasmoid
description: Guide for developing KDE Plasma widgets (Plasmoids) with Python backend and QML UI, including metadata configuration, installation, and KDE Store distribution.
metadata:
  author: OSS AI Skills
  version: 1.0.0
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
│   │   └── ui/
│   │       ├── main.qml
│   │       └── configGeneral.qml
│   └── metadata.json
├── src/
│   ├── __init__.py
│   └── backend.py
├── README.md
└── LICENSE
```

## Configuration Files

### metadata.json

```json
{
    "KPlugin": {
        "Authors": [
            {
                "Email": "your.email@example.com",
                "Name": "Your Name"
            }
        ],
        "Category": "System Information",
        "Description": "A Python-powered Plasma widget",
        "Icon": "utilities-system-monitor",
        "Id": "com.example.my-plasmoid",
        "Name": "My Plasmoid",
        "Version": "1.0.0",
        "Website": "https://github.com/youruser/my-plasmoid"
    },
    "X-Plasma-API-Minimum-Version": "6.0",
    "KPackageStructure": "Plasma/Applet"
}
```

**Critical Fields:**
- `X-Plasma-API-Minimum-Version`: Must be `"6.0"` for Plasma 6
- `KPackageStructure`: Must be `"Plasma/Applet"`
- `Id`: Unique identifier, must match folder name

### Categories

| Category | Description |
|----------|-------------|
| `System Information` | System monitors, stats |
| `Utility` | General tools |
| `Date and Time` | Clocks, calendars |
| `Environment and Weather` | Weather widgets |
| `Miscellaneous` | Other widgets |
| `Application Launchers` | App menus, launchers |
| `Windows and Tasks` | Task managers |

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
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
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

## Configuration System

### contents/config/main.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.kde.org/standards/kcfg/1.0
      http://www.kde.org/standards/kcfg/1.0/kcfg.xsd">
    <kcfgfile name=""/>
    
    <group name="General">
        <entry name="enabled" type="Bool">
            <default>true</default>
            <label>Enable widget</label>
        </entry>
        <entry name="refreshInterval" type="Int">
            <default>60</default>
            <min>5</min>
            <max>3600</max>
            <label>Refresh interval in seconds</label>
        </entry>
        <entry name="customLabel" type="String">
            <default>My Widget</default>
            <label>Custom label</label>
        </entry>
        <entry name="showNotifications" type="Bool">
            <default>false</default>
            <label>Show notifications</label>
        </entry>
    </group>
</kcfg>
```

### contents/config/config.qml

```qml
import QtQuick 2.0
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "configGeneral.qml"
    }
}
```

### contents/ui/configGeneral.qml

```qml
import QtQuick 2.0
import QtQuick.Controls 2.5 as QQC2
import org.kde.kirigami 2.4 as Kirigami

Kirigami.FormLayout {
    id: page
    
    // Property aliases MUST use cfg_ prefix
    property alias cfg_enabled: enabledCheck.checked
    property alias cfg_refreshInterval: intervalSpin.value
    property alias cfg_customLabel: labelField.text
    property alias cfg_showNotifications: notifyCheck.checked
    
    QQC2.CheckBox {
        id: enabledCheck
        text: i18n("Enable widget")
        Kirigami.FormData.label: i18n("Status:")
    }
    
    QQC2.SpinBox {
        id: intervalSpin
        from: 5
        to: 3600
        editable: true
        Kirigami.FormData.label: i18n("Refresh interval (seconds):")
    }
    
    QQC2.TextField {
        id: labelField
        placeholderText: i18n("Enter custom label")
        Kirigami.FormData.label: i18n("Label:")
    }
    
    QQC2.CheckBox {
        id: notifyCheck
        text: i18n("Show notifications")
    }
}
```

### Accessing Configuration in QML

```qml
// Read configuration
text: plasmoid.configuration.customLabel || "Default"
checked: plasmoid.configuration.enabled

// Write configuration
plasmoid.configuration.customLabel = "New Label"
```

## Installation & Testing

### Development Commands

```bash
# Package the plasmoid
cd my-plasmoid/package
zip -r ../my-plasmoid.plasmoid .

# Install locally
plasmapkg2 -i my-plasmoid.plasmoid

# Test in window (recommended for development)
plasmoidviewer com.example.my-plasmoid

# Test directly from source
plasmoidviewer /path/to/my-plasmoid/package

# Uninstall
plasmapkg2 -r com.example.my-plasmoid

# Upgrade existing installation
plasmapkg2 -u my-plasmoid.plasmoid

# List installed plasmoids
plasmapkg2 -t Plasma/Applet --list
```

### Reload Plasma Shell

```bash
# Plasma 5
kquitapp5 plasmashell && kstart5 plasmashell

# Plasma 6
kquitapp6 plasmashell && kstart6 plasmashell
```

### Debugging

```bash
# View logs
journalctl -f | grep -i plasma

# Run with verbose output
plasmoidviewer com.example.my-plasmoid 2>&1 | tee debug.log

# Enable debug logging
export QT_LOGGING_RULES="*.debug=true"
export QML_DEBUGGING_ENABLED=1

# Check QML errors
plasmoidviewer com.example.my-plasmoid 2>&1 | grep -i "qml\|error"
```

## Packaging & Distribution

### Create Release Package

```bash
# Clean package
cd my-plasmoid
rm -f ../my-plasmoid.plasmoid
cd package && zip -r ../../my-plasmoid-1.0.0.plasmoid . && cd ..
```

### KDE Store Submission

1. **Prepare files:**
   - `my-plasmoid-1.0.0.plasmoid`
   - Screenshots (PNG, 1920x1080 recommended)
   - README.md with description
   - LICENSE file

2. **Upload to KDE Store:**
   - Visit https://store.kde.org/
   - Create account
   - Submit to "Plasma Desktop Applets" category
   - Fill description, screenshots, changelog

### GitHub Release

```bash
# Create release archive
tar -czf my-plasmoid-1.0.0.tar.gz my-plasmoid/

# Installation script
cat > install.sh << 'EOF'
#!/bin/bash
plasmapkg2 -i my-plasmoid-1.0.0.plasmoid
EOF
chmod +x install.sh
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

## Troubleshooting

### Widget Not Appearing

| Issue | Solution |
|-------|----------|
| Missing `X-Plasma-API-Minimum-Version` | Add `"X-Plasma-API-Minimum-Version": "6.0"` |
| Wrong `KPackageStructure` | Set to `"Plasma/Applet"` |
| Missing main.qml | Ensure `contents/ui/main.qml` exists |
| Wrong Id format | Use reverse domain: `com.example.widget` |

### Python Backend Not Loading

```bash
# Check Python path
plasmoidviewer widget 2>&1 | grep -i python

# Verify imports
python3 -c "from src.backend import WidgetBackend"

# Check Qt version
python3 -c "from PySide6 import QtCore; print(QtCore.__version__)"
```

### QML Import Errors

```qml
// ❌ Plasma 5 imports (deprecated)
import org.kde.plasma.plasmoid 2.0

// ✅ Plasma 6 imports
import org.kde.plasma.plasmoid
```

### Configuration Not Saving

1. Check `main.xml` uses correct types
2. Property aliases use `cfg_` prefix
3. Config file: `~/.config/plasma-org.kde.plasma.desktop-appletsrc`

## Advanced Patterns

### D-Bus Integration

```python
from PySide6.QtDBus import QDBusConnection, QDBusInterface

class SystemBackend(QObject):
    @Slot(result=float)
    def getBatteryPercent(self):
        iface = QDBusInterface(
            "org.freedesktop.UPower",
            "/org/freedesktop/UPower/devices/battery_BAT0",
            "org.freedesktop.UPower.Device",
            QDBusConnection.systemBus()
        )
        return iface.property("Percentage")
```

### Async Operations

```python
from PySide6.QtCore import QThreadPool, QRunnable, Signal

class Worker(QRunnable):
    finished = Signal(str)
    
    def __init__(self, task):
        super().__init__()
        self.task = task
    
    def run(self):
        result = self.task()
        self.finished.emit(result)

class Backend(QObject):
    @Slot(str)
    def startAsyncTask(self, param):
        worker = Worker(lambda: self.expensive_op(param))
        worker.signals.finished.connect(self.handle_result)
        QThreadPool.globalInstance().start(worker)
```

## File Templates

### metadata.json Template

```json
{
    "KPlugin": {
        "Authors": [{"Email": "", "Name": ""}],
        "Category": "Utility",
        "Description": "",
        "Icon": "applications-utilities",
        "Id": "com.example.widget",
        "Name": "",
        "Version": "1.0.0",
        "Website": ""
    },
    "X-Plasma-API-Minimum-Version": "6.0",
    "KPackageStructure": "Plasma/Applet"
}
```

### Minimal main.qml

```qml
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PlasmaComponents3

PlasmoidItem {
    Plasmoid.icon: "applications-utilities"
    
    Plasmoid.fullRepresentation: PlasmaComponents3.Label {
        text: "Hello World"
    }
    
    Plasmoid.compactRepresentation: PlasmaComponents3.Label {
        text: "HW"
    }
}
```

## References

- [Plasma Widget Tutorial](https://develop.kde.org/docs/plasma/widget/)
- [Porting to KF6](https://develop.kde.org/docs/plasma/widget/porting_kf6/)
- [Python + Kirigami](https://develop.kde.org/docs/getting-started/python/)
- [QML API Reference](https://develop.kde.org/docs/plasma/widget/plasma-qml-api/)
- [KDE Store](https://store.kde.org/)
- [Kirigami Documentation](https://develop.kde.org/docs/kirigami/)
