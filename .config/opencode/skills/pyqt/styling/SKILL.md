---
name: pyqt-styling
description: "PyQt/PySide6 QSS styling - selectors, properties, pseudo-states, dark theme, widget-specific styles"
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - python
    - qt
    - pyqt
    - pyside
    - styling
    - qss
    - css
    - themes
---

# PyQt Styling - QSS (Qt Style Sheets)

Complete guide to styling Qt applications with QSS.

## Basic Syntax

### Type Selectors

```css
/* Match all widgets of a type */
QLabel {
    color: #333333;
    font-size: 14px;
}

QPushButton {
    background-color: #0078d4;
    color: white;
    border: none;
    padding: 8px 16px;
}

QLineEdit {
    border: 1px solid #cccccc;
    border-radius: 4px;
    padding: 4px;
}
```

### Class Selectors

```css
/* Match widgets with specific property */
QPushButton[primary="true"] {
    background-color: #0078d4;
    color: white;
}

QLabel[heading="true"] {
    font-size: 24px;
    font-weight: bold;
}
```

### ID Selectors

```css
/* Match specific widget by objectName */
#myButton {
    background-color: red;
}

#statusLabel {
    color: green;
}
```

### Pseudo-States

```css
/* Hover state */
QPushButton:hover {
    background-color: #106ebe;
}

/* Pressed state */
QPushButton:pressed {
    background-color: #005a9e;
}

/* Disabled state */
QPushButton:disabled {
    background-color: #cccccc;
    color: #666666;
}

/* Focus state */
QLineEdit:focus {
    border: 2px solid #0078d4;
}

/* Checked state (for checkable widgets) */
QCheckBox:checked {
    color: green;
}

/* Selected state */
QListWidget::item:selected {
    background-color: #0078d4;
    color: white;
}
```

## Applying Styles

### Application-Wide

```python
from PySide6.QtWidgets import QApplication

app = QApplication()

# Inline
app.setStyleSheet("""
    QLabel { color: #333; }
    QPushButton { padding: 5px 10px; }
""")

# From file
with open("style.qss", "r") as f:
    app.setStyleSheet(f.read())
```

### Widget-Specific

```python
button = QPushButton("Styled")
button.setStyleSheet("""
    QPushButton {
        background-color: blue;
        color: white;
        border-radius: 5px;
    }
    QPushButton:hover {
        background-color: darkblue;
    }
""")
```

### Custom Properties

```python
# Set custom property
button = QPushButton("Primary")
button.setProperty("primary", True)

# Force style refresh
button.style().unpolish(button)
button.style().polish(button)
```

```css
/* Use in QSS */
QPushButton[primary="true"] {
    background-color: #0078d4;
    color: white;
}

QPushButton[primary="true"]:hover {
    background-color: #106ebe;
}
```

## Common Properties

### Colors

```css
/* Text color */
color: #333333;

/* Background color */
background-color: white;

/* Selection colors */
selection-color: white;
selection-background-color: #0078d4;

/* Border color */
border: 1px solid #cccccc;

/* Alternate row color */
alternate-background-color: #f5f5f5;
```

### Fonts

```css
/* Font family */
font-family: "Segoe UI", Arial, sans-serif;

/* Font size */
font-size: 14px;

/* Font weight */
font-weight: bold;  /* normal, bold, 100-900 */

/* Font style */
font-style: italic;

/* Combined */
font: bold 14px "Segoe UI";
```

### Borders

```css
/* All sides */
border: 1px solid #cccccc;

/* Individual sides */
border-top: 1px solid #cccccc;
border-right: 2px dashed #999999;
border-bottom: 1px solid #cccccc;
border-left: none;

/* Border radius */
border-radius: 4px;

/* Individual corners */
border-top-left-radius: 8px;
border-top-right-radius: 8px;
border-bottom-left-radius: 0;
border-bottom-right-radius: 0;
```

### Spacing

```css
/* Padding (inside border) */
padding: 10px;
padding: 10px 20px;  /* vertical horizontal */
padding: 5px 10px 5px 10px;  /* top right bottom left */

/* Margin (outside border) */
margin: 5px;

/* Spacing between widgets */
spacing: 10px;
```

### Size

```css
/* Minimum size */
min-width: 100px;
min-height: 30px;

/* Maximum size */
max-width: 500px;
max-height: 200px;

/* Fixed size */
width: 200px;
height: 50px;
```

## Widget-Specific Styles

### QPushButton

```css
QPushButton {
    background-color: #0078d4;
    color: white;
    border: none;
    border-radius: 4px;
    padding: 8px 16px;
    font-weight: bold;
}

QPushButton:hover {
    background-color: #106ebe;
}

QPushButton:pressed {
    background-color: #005a9e;
}

QPushButton:disabled {
    background-color: #cccccc;
    color: #666666;
}

/* Flat button */
QPushButton[flat="true"] {
    background-color: transparent;
    color: #0078d4;
    border: 1px solid #0078d4;
}
```

### QLineEdit

```css
QLineEdit {
    background-color: white;
    border: 1px solid #cccccc;
    border-radius: 4px;
    padding: 4px 8px;
    selection-background-color: #0078d4;
}

QLineEdit:focus {
    border: 2px solid #0078d4;
}

QLineEdit:disabled {
    background-color: #f5f5f5;
    color: #999999;
}

/* Password field */
QLineEdit[echoMode="2"] {
    lineedit-password-character: 9679;  /* Unicode bullet */
}
```

### QComboBox

```css
QComboBox {
    background-color: white;
    border: 1px solid #cccccc;
    border-radius: 4px;
    padding: 4px 8px;
}

QComboBox:hover {
    border-color: #999999;
}

QComboBox::drop-down {
    border: none;
    width: 24px;
}

QComboBox::down-arrow {
    image: url(down_arrow.png);
    width: 12px;
    height: 12px;
}

/* Dropdown list */
QComboBox QAbstractItemView {
    background-color: white;
    border: 1px solid #cccccc;
    selection-background-color: #0078d4;
}
```

### QTabWidget

```css
QTabWidget::pane {
    border: 1px solid #cccccc;
    border-radius: 4px;
}

QTabBar::tab {
    background-color: #f5f5f5;
    border: 1px solid #cccccc;
    padding: 8px 16px;
    margin-right: 2px;
}

QTabBar::tab:selected {
    background-color: white;
    border-bottom-color: white;
}

QTabBar::tab:hover {
    background-color: #e5e5e5;
}
```

### QScrollBar

```css
/* Vertical scrollbar */
QScrollBar:vertical {
    background-color: #f5f5f5;
    width: 12px;
    margin: 0;
}

QScrollBar::handle:vertical {
    background-color: #cccccc;
    border-radius: 6px;
    min-height: 30px;
}

QScrollBar::handle:vertical:hover {
    background-color: #999999;
}

QScrollBar::add-line:vertical,
QScrollBar::sub-line:vertical {
    height: 0;
}
```

## Dark Theme Example

```python
DARK_THEME = """
/* Global */
* {
    font-family: "Segoe UI", Arial, sans-serif;
}

QWidget {
    background-color: #1e1e1e;
    color: #e0e0e0;
}

/* Main window */
QMainWindow {
    background-color: #1e1e1e;
}

/* Labels */
QLabel {
    color: #e0e0e0;
}

/* Buttons */
QPushButton {
    background-color: #0e639c;
    color: white;
    border: none;
    border-radius: 4px;
    padding: 6px 12px;
    font-weight: bold;
}

QPushButton:hover {
    background-color: #1177bb;
}

QPushButton:pressed {
    background-color: #0d5a8a;
}

QPushButton:disabled {
    background-color: #3c3c3c;
    color: #666666;
}

/* Input fields */
QLineEdit, QTextEdit, QPlainTextEdit {
    background-color: #2d2d2d;
    color: #e0e0e0;
    border: 1px solid #3c3c3c;
    border-radius: 4px;
    padding: 4px 8px;
    selection-background-color: #0e639c;
}

QLineEdit:focus, QTextEdit:focus, QPlainTextEdit:focus {
    border-color: #0e639c;
}

/* ComboBox */
QComboBox {
    background-color: #2d2d2d;
    color: #e0e0e0;
    border: 1px solid #3c3c3c;
    border-radius: 4px;
    padding: 4px 8px;
}

QComboBox:hover {
    border-color: #4a4a4a;
}

QComboBox::drop-down {
    border: none;
    width: 20px;
}

QComboBox QAbstractItemView {
    background-color: #2d2d2d;
    color: #e0e0e0;
    selection-background-color: #0e639c;
    border: 1px solid #3c3c3c;
}

/* SpinBox */
QSpinBox, QDoubleSpinBox {
    background-color: #2d2d2d;
    color: #e0e0e0;
    border: 1px solid #3c3c3c;
    border-radius: 4px;
    padding: 4px;
}

/* Checkbox */
QCheckBox {
    color: #e0e0e0;
    spacing: 8px;
}

QCheckBox::indicator {
    width: 16px;
    height: 16px;
    border: 1px solid #3c3c3c;
    border-radius: 3px;
}

QCheckBox::indicator:checked {
    background-color: #0e639c;
    border-color: #0e639c;
}

/* Radio button */
QRadioButton {
    color: #e0e0e0;
    spacing: 8px;
}

QRadioButton::indicator {
    width: 16px;
    height: 16px;
    border: 1px solid #3c3c3c;
    border-radius: 8px;
}

QRadioButton::indicator:checked {
    background-color: #0e639c;
    border-color: #0e639c;
}

/* Tab widget */
QTabWidget::pane {
    border: 1px solid #3c3c3c;
    background-color: #1e1e1e;
}

QTabBar::tab {
    background-color: #2d2d2d;
    color: #e0e0e0;
    border: 1px solid #3c3c3c;
    padding: 6px 12px;
    margin-right: 2px;
}

QTabBar::tab:selected {
    background-color: #1e1e1e;
    border-bottom-color: #1e1e1e;
}

QTabBar::tab:hover {
    background-color: #3c3c3c;
}

/* Scrollbar */
QScrollBar:vertical {
    background-color: #2d2d2d;
    width: 12px;
}

QScrollBar::handle:vertical {
    background-color: #4a4a4a;
    border-radius: 6px;
    min-height: 30px;
}

QScrollBar::handle:vertical:hover {
    background-color: #5a5a5a;
}

QScrollBar::add-line:vertical,
QScrollBar::sub-line:vertical {
    height: 0;
}

/* Scrollbar horizontal */
QScrollBar:horizontal {
    background-color: #2d2d2d;
    height: 12px;
}

QScrollBar::handle:horizontal {
    background-color: #4a4a4a;
    border-radius: 6px;
    min-width: 30px;
}

QScrollBar::handle:horizontal:hover {
    background-color: #5a5a5a;
}

/* Menu */
QMenuBar {
    background-color: #2d2d2d;
    color: #e0e0e0;
}

QMenuBar::item:selected {
    background-color: #0e639c;
}

QMenu {
    background-color: #2d2d2d;
    color: #e0e0e0;
    border: 1px solid #3c3c3c;
}

QMenu::item:selected {
    background-color: #0e639c;
}

/* Tooltip */
QToolTip {
    background-color: #2d2d2d;
    color: #e0e0e0;
    border: 1px solid #3c3c3c;
    padding: 4px;
}

/* Status bar */
QStatusBar {
    background-color: #007acc;
    color: white;
}

/* GroupBox */
QGroupBox {
    border: 1px solid #3c3c3c;
    border-radius: 4px;
    margin-top: 12px;
    padding-top: 12px;
    font-weight: bold;
}

QGroupBox::title {
    subcontrol-origin: margin;
    left: 8px;
    padding: 0 4px;
}
"""

# Apply
app.setStyleSheet(DARK_THEME)
```

## Best Practices

1. **Use semantic class names** - `primary`, `danger`, `warning`
2. **Organize styles by widget** - Keep related styles together
3. **Use variables** - Store colors in custom properties
4. **Test on all platforms** - Colors and fonts vary
5. **Use relative units** - `em` for fonts (limited support)
6. **Keep styles modular** - Separate files per theme

## References

- **Qt Style Sheets**: https://doc.qt.io/qtforpython-6/overviews/stylesheet.html
- **QSS Reference**: https://doc.qt.io/qtforpython-6/overviews/stylesheet-reference.html
- **Qt Examples**: https://doc.qt.io/qtforpython-6/overviews/stylesheet-examples.html
