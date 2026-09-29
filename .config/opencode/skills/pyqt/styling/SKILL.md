---
name: pyqt-styling
description: "Use when styling PyQt/PySide6 widgets with QSS - selectors and pseudo-states, stylesheet application, common style properties, widget-specific styling, or building a dark theme"
metadata:
  author: mte90
  version: 2.1.0
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

## Deep Dives

- **Dark Theme Example**: See [references/dark-theme.md](references/dark-theme.md) for a complete VS Code-inspired dark theme stylesheet.

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