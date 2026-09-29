> This file is loaded on demand from the main SKILL.md "Deep Dives" section.

# Dark Theme Example

Complete VS Code-inspired dark theme stylesheet for PyQt/PySide6 applications.

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