<!-- This file is loaded on demand from ../SKILL.md -->

# Testing & Debugging Reference

Complete reference for testing, debugging, and troubleshooting KDE Plasmoids.

## Installation & Testing Commands

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

## Testing with plasmoidtest

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

## Unit Testing Backend

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

## Runtime Testing

```bash
# Test widget in isolation
plasmoidtest com.example.my-plasmoid

# Test with specific plasma location
krun "plasma-shell --test"

# Monitor widget events
journalctl -u plasma-org.kde.plasma.desktop-appletsrc -f
```

## Automated Testing

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

## Manual Testing Checklist

- [ ] Widget appears in Add Widgets panel
- [ ] Widget expands/collapses correctly
- [ ] Configuration dialog opens and saves
- [ ] Data updates reflect in UI
- [ ] System info displays correctly
- [ ] Buttons respond to clicks
- [ ] Compact representation shows in panel
- [ ] Tooltip displays properly
- [ ] No console errors when running

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

### Common Installation Failures

```bash
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
dataUpdated = Signal()  // ← Must match QML signal name
```

3. **Attribute errors:**
```python
# Error: "'WidgetBackend' object has no attribute '_data'"
# Solution: Initialize in __init__
def __init__(self, parent=None):
    super().__init__(parent)
    self._data = "Initial"  // ← Initialize before use
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

## Debug Tools

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