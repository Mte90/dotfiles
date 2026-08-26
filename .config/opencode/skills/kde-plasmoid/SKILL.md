---
name: kde-plasmoid
description: "Build KDE Plasma 6 widgets with Python backend and QML UI, including metadata, deployment, and KDE Store distribution"
metadata:
  author: mte90
  version: "1.0.0"
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
        "Description": "A Python-powered Plasma widget with system monitoring capabilities",
        "Icon": "utilities-system-monitor",
        "Id": "com.example.my-plasmoid",
        "License": "LGPL-2.1-or-later",
        "Name": "My Plasmoid",
        "Version": "1.0.0",
        "Website": "https://github.com/youruser/my-plasmoid",
        "Keywords": [
            "system",
            "monitor",
            "cpu",
            "memory",
            "disk"
        ],
        "X-KDE-PluginInfo-Name": "com.example.my-plasmoid"
    },
    "X-Plasma-API-Minimum-Version": "6.0",
    "X-Plasma-API-Extensions-Required": [],
    "X-Plasma-Check-Compatibility": "true",
    "KPackageStructure": "Plasma/Applet"
}
```

**Critical Fields:**
- `KPlugin.Category`: Required widget category (see below)
- `KPlugin.License`: Must be valid SPDX identifier (e.g., "LGPL-2.1-or-later", "MIT", "GPL-2.0-or-later")
- `X-Plasma-API-Minimum-Version`: Must be `"6.0"` for Plasma 6
- `X-Plasma-Check-Compatibility`: Set to `"true"` to enable compatibility checking
- `KPackageStructure`: Must be `"Plasma/Applet"`
- `Id`: Unique identifier, must match folder name exactly

### Categories

| Category | Description |
|----------|-------------|
| `System Information` | System monitors, stats, sensors |
| `Utility` | General tools and helpers |
| `Date and Time` | Clocks, calendars, timers |
| `Environment and Weather` | Weather widgets, climate data |
| `Miscellaneous` | Other widgets not fitting other categories |
| `Application Launchers` | App menus, launchers, shortcuts |
| `Windows and Tasks` | Task managers, window controls |

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
plasmapkg2 -l com.example.my-plasmoid
plasmoidtest com.example.my-plasmoid

# Test directly from source
plasmoidtest /path/to/my-plasmoid/package

# Uninstall
plasmapkg2 -r com.example.my-plasmoid

# Upgrade existing installation
plasmapkg2 -u my-plasmoid.plasmoid

# List installed plasmoids
plasmapkg2 -t Plasma/Applet --list
```

### Reload Plasma Shell

```bash
# Plasma 6
kquitapp6 plasmashell && kstart6 plasmashell

# Plasma 5 (legacy)
kquitapp5 plasmashell && kstart5 plasmashell
```

### Testing with plasmoidtest

The `plasmoidtest` command is the recommended testing tool for Plasma 6. It provides:
- Interactive widget preview in a resizable window
- Real-time configuration testing
- Console output for debugging

```bash
# Test in window mode (interactive)
plasmoidtest com.example.my-plasmoid

# Test with debug output
plasmapkg2 -l com.example.my-plasmoid
plasmoidtest --debug com.example.my-plasmoid

# Test from file path
plasmoidtest /path/to/my-plasmoid/package
```

### Debugging

```bash
# View logs
journalctl -f | grep -i plasma

# Run with verbose output
plasmoidtest com.example.my-plasmoid 2>&1 | tee debug.log

# Enable debug logging
export QT_LOGGING_RULES="*.debug=true"
export QML_DEBUGGING_ENABLED=1

# Check QML errors
plasmoidtest com.example.my-plasmoid 2>&1 | grep -i "qml\|error"

# Force validation on load
plasmoidtest --validate com.example.my-plasmoid
```

## Packaging & Distribution

### Create Release Package

```bash
# Clean package
cd my-plasmoid
rm -f ../my-plasmoid.plasmoid
cd package && zip -r ../../my-plasmoid-1.0.0.plasmoid . && cd ..

# Verify package structure
unzip -l my-plasmoid-1.0.0.plasmoid
```

### Build .plasmoid with plasmapkg2

```bash
# Package creation
cd my-plasmoid/package
plasmapkg2 -c my-plasmoid.plasmoid

# List contents
plasmapkg2 -t Plasma/Applet --list

# Package with compression
plasmapkg2 -c -o my-plasmoid-compressed.plasmoid package/
```

### Install/Update/Remove

```bash
# Install from package
plasmapkg2 -i my-plasmoid.plasmoid

# Install from directory (auto-packages)
plasmapkg2 -i package/

# Upgrade existing
plasmapkg2 -u my-plasmoid.plasmoid

# Remove
plasmapkg2 -r com.example.my-plasmoid

# List all installed widgets
plasmapkg2 -t Plasma/Applet --list

# List with details
plasmapkg2 -t Plasma/Applet --list --verbose
```

### KDE Store Submission

1. **Prepare files:**
   - `my-plasmoid-1.0.0.plasmoid`
   - Screenshots (PNG, 1920x1080 recommended)
   - README.md with description
   - LICENSE file (compatible with specified license)

2. **KDE Store requirements:**
   - Minimum plasma version compatibility declared
   - Complete metadata in metadata.json
   - Valid SPDX license identifier
   - At least 3 screenshots showing widget in use

3. **Upload to KDE Store:**
   - Visit https://store.kde.org/
   - Create account
   - Submit to "Plasma Desktop Applets" category
   - Fill description, screenshots, changelog
   - Undergo review process (typically 1-2 weeks)

4. **KDE Store policy compliance:**
   - No promotional content
   - No aggressive marketing in description
   - Open-source license only (no proprietary components)
   - Privacy policy for widgets accessing user data

### GitHub Release

```bash
# Create release archive
tar -czf my-plasmoid-1.0.0.tar.gz my-plasmoid/

# Installation script
cat > install.sh << 'EOF'
#!/bin/bash
plasmapkg2 -i my-plasmoid-1.0.0.plasmoid
echo "Widget installed. Reload plasma shell: kquitapp6 plasmashell && kstart6 plasmashell"
EOF
chmod +x install.sh

# Verify installation
./install.sh
plasmapkg2 -t Plasma/Applet --list | grep my-plasmoid
```

## Deployment/Publishing

### Local Deployment

```bash
# Install to user Plasma (persistent across sessions)
plasmapkg2 -i my-plasmoid-1.0.0.plasmoid

# Verify installation location
find ~/.local/share/plasma-appletsrc -name "*my-plasmoid*" 2>/dev/null || \
find ~/.local/share/plasma-appletsrc -name "*com.example.my-plasmoid*" 2>/dev/null

# List all installed applets
plasmapkg2 -t Plasma/Applet --list

# Check widget configuration file location
cat ~/.local/share/plasma-appletsrc/com.example.kde.desktop-appletsrc
```

### System-Wide Deployment (requires root)

```bash
# Copy to system location
sudo cp my-plasmoid-1.0.0.plasmoid /usr/share/plasma/plasmoids/com.example.my-plasmoid/

# Or copy folder structure
sudo mkdir -p /usr/share/plasma/plasmoids/com.example.my-plasmoid
sudo cp -r my-plasmoid/package/* /usr/share/plasma/plasmoids/com.example.my-plasmoid/

# Reload plasma shell to apply
kquitapp6 plasmashell && kstart6 plasmashell

# Verify installation
sudo plasmapkg2 -l com.example.my-plasmoid
```

### KDE Store Distribution

**Step 1: Prepare package**

```bash
# Create release package
cd my-plasmoid
VERSION="1.0.0"
plasmapkg2 -c -o my-plasmoid-${VERSION}.plasmoid package/

# Verify package contents
unzip -l my-plasmoid-${VERSION}.plasmoid

# Check metadata
unzip -p my-plasmoid-${VERSION}.plasmoid metadata.json | jq .
```

**Step 2: Prepare screenshots**

Screenshots should:
- Be high-resolution (1920x1080 minimum)
- Show widget in actual Plasma session
- Include at least 3 variations:
  1. Widget in desktop mode
  2. Widget in panel (if applicable)
  3. Configuration dialog

```bash
# Create screenshots directory
mkdir -p screenshots

# Capture widget screenshots
plasmoidtest com.example.my-plasmoid
# (Take screenshots manually or use automation)
```

**Step 3: Submit to KDE Store**

1. **Account setup:**
   - Visit https://store.kde.org/
   - Register with KDE account (GitHub, KDE Accounts, or email)

2. **New submission:**
   - Click "Submit New Applet"
   - Fill metadata form:
     - Name, description, category
     - License (must match metadata.json)
     - Screenshots (upload PNG files)
     - GitHub repository URL (optional but recommended)

3. **Review process:**
   - KDE maintainers review (typically 1-2 weeks)
   - Common rejection reasons:
     - Missing required metadata fields
     - Non-compliant license
     - Promotional/proprietary content
     - Broken QML syntax
     - Missing plasma compatibility declaration

4. **Approved applet:**
   - Appears in Plasma Add-Widgets panel
   - Visible to all KDE users
   - Automated updates available

### Publishing Timeline

| Stage | Duration | Notes |
|-------|----------|-------|
| Development | Variable | Depends on feature complexity |
| Testing | 1-2 days | Manual testing, regression checks |
| Package creation | 30 minutes | Build .plasmoid package |
| KDE Store review | 1-2 weeks | Varies by workload |
| User availability | Immediate | Once approved |

## Troubleshooting

### plasmapkg2 Exit Codes

| Exit Code | Meaning | Solution |
|-----------|---------|----------|
| `0` | Success | Package created/installed correctly |
| `1` | Invalid source | Check folder structure, verify `contents/` exists |
| `2` | Missing metadata.json | Add `metadata.json` to package root |
| `3` | Invalid KPackageStructure | Set to `"Plasma/Applet"` in metadata.json |
| `4` | QML compilation error | Fix QML syntax errors in `main.qml` |
| `5` | Python backend error | Check `backend.py` for syntax/runtime errors |
| `6` | Permission denied | Run with sudo or check file permissions |
| `7` | Invalid KPluginMetaData | Verify all required fields in metadata.json |
| `8` | Config file error | Check `main.xml` and `config.qml` syntax |
| `9` | Package too large | Remove unused files, compress properly |

### plasmapkg2 Non-Zero Exit Codes

```bash
# Common installation failures

# Exit code 1: Invalid source directory
# Solution: Verify structure
ls my-plasmoid/package/contents/
# Expected: config/, ui/, main.xml

# Exit code 2: Missing metadata.json
# Solution: Check metadata.json exists in package root
ls my-plasmoid/package/metadata.json

# Exit code 4: QML compilation error
# Solution: Fix QML syntax errors
plasmapkg2 -c -v my-plasmoid.plasmoid 2>&1 | grep -i "qml\|error"

# Exit code 7: Invalid KPluginMetaData
# Solution: Add all required fields
jq '.KPlugin' metadata.json
# Required: Name, Id, Category, Description, License, Version
```

### Missing KPluginMetaData Errors

```
Error: Missing required KPluginMetaData field
```

**Solutions:**

1. **Missing Category:**
```json
{
    "KPlugin": {
        "Category": "System Information",  // ← Required
        "Name": "My Widget",
        "Id": "com.example.my-widget"
    }
}
```

2. **Missing License:**
```json
{
    "KPlugin": {
        "License": "LGPL-2.1-or-later",  // ← Required
        "Name": "My Widget",
        "Id": "com.example.my-widget"
    }
}
```

3. **Missing Version:**
```json
{
    "KPlugin": {
        "Version": "1.0.0",  // ← Required
        "Name": "My Widget",
        "Id": "com.example.my-widget"
    }
}
```

### QML Compilation Errors

```qml
// Error: "Object 'backend' not found"
// Solution: Ensure backend is instantiated before reference
WidgetBackend {
    id: backend
}
PlasmaComponents3.Label {
    text: backend.data  // ← Only valid after backend initialization
}
```

**Common QML Issues:**

1. **Import errors:**
```qml
// Error: "Import 'org.kde.plasma.plasmoid 2.0' is not allowed"
// Solution: Use Plasma 6 import (no version number)
import org.kde.plasma.plasmoid  // ← No version
```

2. **Property binding errors:**
```qml
// Error: "Cannot assign to const property"
// Solution: Use cfg_ prefix for config properties
property alias cfg_customLabel: label.text  // ← Correct
```

3. **Undefined signals:**
```qml
// Error: "Signal 'dataChanged' is not defined"
// Solution: Ensure backend has matching signal
class WidgetBackend(QObject):
    dataChanged = Signal()  // ← Must match QML
```

### KPackageStructure Errors

```
Error: KPackageStructure must be "Plasma/Applet"
```

**Fix in metadata.json:**
```json
{
    "KPackageStructure": "Plasma/Applet",  // ← Required value
    "X-Plasma-API-Minimum-Version": "6.0"
}
```

### Widget Not Appearing

| Issue | Solution |
|-------|----------|
| Missing `X-Plasma-API-Minimum-Version` | Add `"X-Plasma-API-Minimum-Version": "6.0"` to metadata.json |
| Wrong `KPackageStructure` | Set to `"Plasma/Applet"` |
| Missing main.qml | Ensure `contents/ui/main.qml` exists |
| Wrong Id format | Use reverse domain: `com.example.widget` |
| Permission denied | Check file permissions on widget directory |
| Category not found | Verify category matches predefined list |

### Python Backend Not Loading

```bash
# Check Python path
plasmapkg2 -l com.example.my-plasmoid 2>&1 | grep -i python

# Verify imports
python3 -c "from src.backend import WidgetBackend"

# Check Qt version
python3 -c "from PySide6 import QtCore; print(QtCore.__version__)"
```

**Common Backend Issues:**

1. **Import errors:**
```python
# Error: "No module named 'src.backend'"
# Solution: Update PySide6.QtQml imports
from PySide6.QtQml import qmlRegisterType
qmlRegisterType(WidgetBackend, "com.example.widget", 1, 0, "WidgetBackend")
```

2. **Signal/slot mismatch:**
```python
# Error: "Signal not emitted or not connected"
# Solution: Use correct Signal type
dataUpdated = Signal()  # ← Must match QML signal name
```

3. **Attribute errors:**
```python
# Error: "'WidgetBackend' object has no attribute '_data'"
# Solution: Initialize in __init__
def __init__(self, parent=None):
    super().__init__(parent)
    self._data = "Initial"  # ← Initialize before use
```

### Configuration Not Saving

1. Check `main.xml` uses correct types
2. Property aliases use `cfg_` prefix
3. Config file: `~/.config/plasma-org.kde.plasma.desktop-appletsrc`

**Debug config saving:**
```bash
# View config file
cat ~/.config/plasma-org.kde.plasma.desktop-appletsrc

# Reload shell after changes
kquitapp6 plasmashell && kstart6 plasmashell

# Verify config persisted
plasmapkg2 -l com.example.my-plasmoid
```

### Script Installation

**systemd service (optional, for testing):**
```ini
# /etc/systemd/system/plasmoid-test.service
[Unit]
Description=Plasmoid Test Service
After=plasma-org.kde.plasma.desktop-appletsrc.service

[Service]
Type=simple
ExecStart=/usr/bin/plasmoidtest com.example.my-plasmoid
Restart=always

[Install]
WantedBy=multi-user.target
```

### Advanced Debugging

```bash
# Full widget debug mode
export QT_LOGGING_RULES="*.debug=true"
export KWIN_DEBUG_LOGGING=1
plasmapkg2 -l com.example.my-plasmoid 2>&1 | tee widget-debug.log

# Capture widget runtime errors
journalctl -u plasma-org.kde.plasma.desktop-appletsrc -f | grep -i error

# Check widget manifest
unzip -p my-plasmoid.plasmoid metadata.json | jq .KPlugin

# Validate QML syntax
qmlcppcheck main.qml
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

## Testing/Debugging

### Unit Testing Backend

```python
#!/usr/bin/env python3
"""Unit tests for WidgetBackend"""

import unittest
from src.backend import WidgetBackend

class TestWidgetBackend(unittest.TestCase):
    
    def setUp(self):
        self.backend = WidgetBackend()
    
    def test_initial_data(self):
        self.assertEqual(self.backend.getData(), "Initial Value")
    
    def test_set_data(self):
        self.backend.setData("New Value")
        self.assertEqual(self.backend.getData(), "New Value")
    
    def test_process_data(self):
        result = self.backend.processData("test")
        self.assertEqual(result, "Processed: test")
    
    def test_refresh(self):
        self.backend.refresh()
        self.assertIn("Updated", self.backend.getData())

if __name__ == "__main__":
    unittest.main()
```

### Runtime Testing

```bash
# Test widget in isolation
plasmoidtest com.example.my-plasmoid

# Test with specific plasma location
krun "plasma-shell --test"

# Monitor widget events
journalctl -u plasma-org.kde.plasma.desktop-appletsrc -f
```

### Automated Testing

```python
#!/usr/bin/env python3
"""Integration tests for complete plasmoid"""

import subprocess
import sys
import tempfile
import os

def test_plasmoid_package():
    """Test plasmoid package creation"""
    with tempfile.TemporaryDirectory() as tmpdir:
        # Test packaging
        result = subprocess.run(
            ["plasmapkg2", "-c", "-o", "test.plasmoid", "package/"],
            capture_output=True,
            text=True
        )
        
        assert result.returncode == 0, f"Packages failed: {result.stderr}"
        
        # Verify package
        result = subprocess.run(
            ["unzip", "-l", "test.plasmoid"],
            capture_output=True,
            text=True
        )
        
        assert "metadata.json" in result.stdout, "Missing metadata.json"
        assert "main.qml" in result.stdout, "Missing main.qml"

if __name__ == "__main__":
    test_plasmoid_package()
    print("All tests passed!")
```

### Manual Testing Checklist

- [ ] Widget appears in Add Widgets panel
- [ ] Widget expands/collapses correctly
- [ ] Configuration dialog opens and saves
- [ ] Data updates reflect in UI
- [ ] System info displays correctly
- [ ] Buttons respond to clicks
- [ ] Compact representation shows in panel
- [ ] Tooltip displays properly
- [ ] No console errors when running

### Debug Tools

```bash
# Full widget debug mode
export QT_LOGGING_RULES="*.debug=true"
export KWIN_DEBUG_LOGGING=1
plasmapkg2 -l com.example.my-plasmoid 2>&1 | tee widget-debug.log

# Monitor widget events
journalctl -u plasma-org.kde.plasma.desktop-appletsrc -f | grep -i error

# Check widget manifest
unzip -p my-plasmoid.plasmoid metadata.json | jq .KPlugin

# Validate QML syntax
qmlcppcheck main.qml
```

## References

- [Plasma Widget Tutorial](https://develop.kde.org/docs/plasma/widget/)
- [Porting to KF6](https://develop.kde.org/docs/plasma/widget/porting_kf6/)
- [Python + Kirigami](https://develop.kde.org/docs/getting-started/python/)
- [QML API Reference](https://develop.kde.org/docs/plasma/widget/plasma-qml-api/)
- [KDE Store](https://store.kde.org/)
- [Kirigami Documentation](https://develop.kde.org/docs/kirigami/)
- [plasmapkg2 Tool](https://apps.kde.org/plasmapkg2/)
