<!-- This file is loaded on demand from ../SKILL.md -->

# Configuration Files Reference

Configuration files for KDE Plasmoids - metadata, KCFG schema, and QML config UI.

## metadata.json

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

## Configuration System (KCFG)

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

**Important**: Property aliases in config pages MUST use `cfg_` prefix to bind to KCFG entries.