---
name: pyqt-widgets
description: "PyQt/PySide6 widgets and layouts - buttons, inputs, containers, item views, layout management"
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - python
    - qt
    - pyqt
    - pyside
    - widgets
    - gui
    - layouts
---

# PyQt Widgets - QtWidgets Module

Comprehensive guide to Qt widgets and layout management.

## Display Widgets

### QLabel

```python
from PySide6.QtWidgets import QLabel
from PySide6.QtCore import Qt
from PySide6.QtGui import QPixmap

label = QLabel("Text Label")

# Text properties
label.setText("New text")
label.setAlignment(Qt.AlignmentFlag.AlignCenter)
label.setWordWrap(True)
label.setIndent(10)  # Pixels

# Image
label.setPixmap(QPixmap("image.png"))
label.setScaledContents(True)

# Rich text
label.setText("<b>Bold</b> and <i>italic</i>")
label.setTextFormat(Qt.TextFormat.RichText)

# Link
label.setText('<a href="https://example.com">Click here</a>')
label.setOpenExternalLinks(True)
label.linkActivated.connect(lambda url: print(f"Clicked: {url}"))
```

### QProgressBar

```python
from PySide6.QtWidgets import QProgressBar

progress = QProgressBar()

# Set range and value
progress.setRange(0, 100)
progress.setValue(50)

# Text visibility
progress.setTextVisible(True)
progress.setFormat("%p%")  # %p = percentage, %v = value

# Indeterminate mode
progress.setRange(0, 0)  # Shows busy indicator

# Orientation
progress.setOrientation(Qt.Orientation.Horizontal)
progress.setOrientation(Qt.Orientation.Vertical)
```

### QLCDNumber

```python
from PySide6.QtWidgets import QLCDNumber

lcd = QLCDNumber()
lcd.display(123)
lcd.setDigitCount(4)
lcd.setMode(QLCDNumber.Mode.Dec)  # Hex, Oct, Bin
lcd.setSegmentStyle(QLCDNumber.SegmentStyle.Flat)
```

## Input Widgets

### QLineEdit

```python
from PySide6.QtWidgets import QLineEdit

line = QLineEdit()

# Text
line.setText("Default")
line.setPlaceholderText("Enter text...")
line.clear()

# Echo mode
line.setEchoMode(QLineEdit.EchoMode.Normal)
line.setEchoMode(QLineEdit.EchoMode.Password)
line.setEchoMode(QLineEdit.EchoMode.NoEcho)

# Validation
line.setMaxLength(100)
line.setInputMask("999-9999")  # Phone number
line.setValidator(QIntValidator(0, 100))  # Numbers only

# Selection
line.selectAll()
line.setSelection(0, 5)

# Signals
line.textChanged.connect(self.onTextChange)
line.textEdited.connect(self.onTextEdit)
line.returnPressed.connect(self.onSubmit)
line.editingFinished.connect(self.onEditDone)
```

### QTextEdit

```python
from PySide6.QtWidgets import QTextEdit

text = QTextEdit()

# Plain text
text.setPlainText("Plain text content")
plain = text.toPlainText()

# HTML
text.setHtml("<b>Bold</b> and <i>italic</i>")
html = text.toHtml()

# Append
text.append("More text")
text.append("<b>HTML text</b>")

# Properties
text.setReadOnly(True)
text.setLineWrapMode(QTextEdit.LineWrapMode.WidgetWidth)

# Cursor
cursor = text.textCursor()
cursor.insertText("Inserted text")

# Undo/Redo
text.undo()
text.redo()
text.setUndoRedoEnabled(False)
```

### QSpinBox and QDoubleSpinBox

```python
from PySide6.QtWidgets import QSpinBox, QDoubleSpinBox

spin = QSpinBox()
spin.setRange(0, 100)
spin.setValue(50)
spin.setSingleStep(5)  # Step on arrow click
spin.setSuffix(" px")
spin.setPrefix("$ ")
spin.valueChanged.connect(lambda v: print(f"Value: {v}"))

# Double spin box
dspin = QDoubleSpinBox()
dspin.setRange(0.0, 1.0)
dspin.setValue(0.5)
dspin.setDecimals(2)
dspin.setSingleStep(0.1)
```

### QComboBox

```python
from PySide6.QtWidgets import QComboBox

combo = QComboBox()

# Add items
combo.addItem("Option 1")
combo.addItems(["Option 2", "Option 3", "Option 4"])

# Current selection
combo.setCurrentIndex(0)
combo.setCurrentText("Option 2")
index = combo.currentIndex()
text = combo.currentText()

# Editable
combo.setEditable(True)
combo.setCompleter(None)  # Disable autocomplete

# Insert
combo.insertItem(0, "First")
combo.insertItems(1, ["A", "B"])

# Remove
combo.removeItem(0)
combo.clear()

# Signals
combo.currentIndexChanged.connect(lambda i: print(f"Index: {i}"))
combo.currentTextChanged.connect(lambda t: print(f"Text: {t}"))
```

### QCheckBox

```python
from PySide6.QtWidgets import QCheckBox

check = QCheckBox("Enable feature")
check.setChecked(True)

# Tristate
check.setTristate(True)
check.setCheckState(Qt.CheckState.PartiallyChecked)

# State
is_checked = check.isChecked()
state = check.checkState()

# Signals
check.stateChanged.connect(lambda s: print(f"State: {s}"))
check.toggled.connect(lambda c: print(f"Checked: {c}"))
```

### QRadioButton

```python
from PySide6.QtWidgets import QRadioButton, QButtonGroup

radio1 = QRadioButton("Option A")
radio2 = QRadioButton("Option B")

# Group (exclusive)
group = QButtonGroup()
group.addButton(radio1)
group.addButton(radio2)

# Or use parent widget for auto-exclusive behavior

# Select
radio1.setChecked(True)

# Check
if radio1.isChecked():
    print("Option A selected")

# Signals
radio1.toggled.connect(lambda c: print(f"Toggled: {c}"))
group.buttonClicked.connect(lambda btn: print(f"Clicked: {btn.text()}"))
```

### QSlider

```python
from PySide6.QtWidgets import QSlider

slider = QSlider(Qt.Orientation.Horizontal)
slider.setRange(0, 100)
slider.setValue(50)
slider.setSingleStep(1)
slider.setPageStep(10)
slider.setTickPosition(QSlider.TickPosition.TicksBelow)
slider.setTickInterval(10)

value = slider.value()
slider.valueChanged.connect(lambda v: print(f"Value: {v}"))
```

## Buttons

### QPushButton

```python
from PySide6.QtWidgets import QPushButton
from PySide6.QtGui import QIcon

button = QPushButton("Click Me")

# Icon
button.setIcon(QIcon("icon.png"))
button.setIconSize(QSize(16, 16))

# Properties
button.setEnabled(False)
button.setDefault(True)  # Default button in dialog
button.setFlat(True)  # No border

# Checkable
button.setCheckable(True)
button.setChecked(True)
button.toggled.connect(lambda c: print(f"Toggled: {c}"))

# Menu
menu = QMenu(button)
menu.addAction("Option 1")
menu.addAction("Option 2")
button.setMenu(menu)

# Signals
button.clicked.connect(lambda: print("Clicked!"))
button.pressed.connect(lambda: print("Pressed"))
button.released.connect(lambda: print("Released"))
```

### QToolButton

```python
from PySide6.QtWidgets import QToolButton

tool = QToolButton()
tool.setIcon(QIcon("icon.png"))
tool.setToolTip("Tool tip")
tool.setToolButtonStyle(Qt.ToolButtonStyle.ToolButtonTextUnderIcon)
tool.setAutoRaise(True)  # Flat until hover
```

## Container Widgets

### QGroupBox

```python
from PySide6.QtWidgets import QGroupBox, QVBoxLayout

group = QGroupBox("Settings")
group.setCheckable(True)
group.setChecked(True)

layout = QVBoxLayout(group)
layout.addWidget(QCheckBox("Option 1"))
layout.addWidget(QCheckBox("Option 2"))
```

### QTabWidget

```python
from PySide6.QtWidgets import QTabWidget, QWidget

tabs = QTabWidget()

# Add tabs
page1 = QWidget()
page2 = QWidget()
tabs.addTab(page1, "Tab 1")
tabs.addTab(page2, "Tab 2")

# With icon
tabs.addTab(page3, QIcon("icon.png"), "Tab 3")

# Current tab
tabs.setCurrentIndex(0)
index = tabs.currentIndex()

# Properties
tabs.setTabsClosable(True)
tabs.setMovable(True)
tabs.setDocumentMode(True)  # Flat style

# Signals
tabs.currentChanged.connect(lambda i: print(f"Tab: {i}"))
tabs.tabCloseRequested.connect(lambda i: tabs.removeTab(i))
```

### QScrollArea

```python
from PySide6.QtWidgets import QScrollArea, QLabel

scroll = QScrollArea()

# Content widget
content = QLabel("Very long content...")
content.setWordWrap(True)

scroll.setWidget(content)
scroll.setWidgetResizable(True)
scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
scroll.setVerticalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAsNeeded)
```

### QSplitter

```python
from PySide6.QtWidgets import QSplitter

splitter = QSplitter(Qt.Orientation.Horizontal)
splitter.addWidget(left_widget)
splitter.addWidget(right_widget)

# Sizes
splitter.setSizes([200, 400])
sizes = splitter.sizes()

# Collapsible
splitter.setChildrenCollapsible(False)
```

### QStackedWidget

```python
from PySide6.QtWidgets import QStackedWidget

stack = QStackedWidget()
stack.addWidget(page1)  # Index 0
stack.addWidget(page2)  # Index 1
stack.addWidget(page3)  # Index 2

stack.setCurrentIndex(0)
stack.setCurrentWidget(page2)
current = stack.currentIndex()
```

## Item Views

### QListWidget

```python
from PySide6.QtWidgets import QListWidget, QListWidgetItem

list = QListWidget()
list.addItems(["Item 1", "Item 2", "Item 3"])

# Custom items
item = QListWidgetItem("Custom Item")
item.setIcon(QIcon("icon.png"))
item.setData(Qt.ItemDataRole.UserRole, {"id": 123})
list.addItem(item)

# Selection
list.setCurrentRow(0)
list.setSelectionMode(QAbstractItemView.SelectionMode.MultiSelection)

# Get selected
selected = list.selectedItems()
for item in selected:
    print(item.text())

# Signals
list.currentItemChanged.connect(lambda curr, prev: print(curr.text()))
list.itemClicked.connect(lambda item: print(item.text()))
list.itemDoubleClicked.connect(lambda item: print(f"Double: {item.text()}"))
```

### QTreeWidget

```python
from PySide6.QtWidgets import QTreeWidget, QTreeWidgetItem

tree = QTreeWidget()
tree.setHeaderLabels(["Name", "Value"])

# Root item
root = QTreeWidgetItem(["Parent", "0"])
tree.addTopLevelItem(root)

# Child items
child1 = QTreeWidgetItem(["Child 1", "1"])
child2 = QTreeWidgetItem(["Child 2", "2"])
root.addChild(child1)
root.addChild(child2)

# Nested
grandchild = QTreeWidgetItem(["Grandchild", "3"])
child1.addChild(grandchild)

# Expand
root.setExpanded(True)

# Signals
tree.itemClicked.connect(lambda item, col: print(f"{item.text(col)}"))
```

### QTableWidget

```python
from PySide6.QtWidgets import QTableWidget, QTableWidgetItem

table = QTableWidget()
table.setRowCount(3)
table.setColumnCount(2)
table.setHorizontalHeaderLabels(["Column 1", "Column 2"])

# Set item
item = QTableWidgetItem("Cell 0,0")
table.setItem(0, 0, item)

# Get item
item = table.item(0, 0)
text = item.text() if item else ""

# Selection
table.selectRow(0)
table.selectColumn(1)
table.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)

# Edit
table.setEditTriggers(QAbstractItemView.EditTrigger.DoubleClicked)

# Resize
table.horizontalHeader().setStretchLastSection(True)
table.resizeColumnsToContents()
```

## Layout Management

### QVBoxLayout and QHBoxLayout

```python
from PySide6.QtWidgets import QVBoxLayout, QHBoxLayout

# Vertical
vlayout = QVBoxLayout()
vlayout.addWidget(label)
vlayout.addWidget(button)
vlayout.addStretch()  # Add stretchable space
vlayout.addWidget(bottom_label)

# Horizontal
hlayout = QHBoxLayout()
hlayout.addWidget(left_button)
hlayout.addStretch()
hlayout.addWidget(right_button)

# Nest
main_layout = QVBoxLayout()
main_layout.addLayout(hlayout)
```

### QGridLayout

```python
from PySide6.QtWidgets import QGridLayout

grid = QGridLayout()
grid.addWidget(label1, 0, 0)   # row 0, col 0
grid.addWidget(lineEdit, 0, 1)  # row 0, col 1
grid.addWidget(label2, 1, 0)   # row 1, col 0
grid.addWidget(comboBox, 1, 1)  # row 1, col 1

# Span multiple cells
grid.addWidget(bigWidget, 2, 0, 1, 2)  # row 2, col 0, 1 row, 2 cols

# Column/row stretch
grid.setColumnStretch(1, 1)  # Column 1 stretches
grid.setRowStretch(0, 2)     # Row 0 gets 2x space
```

### QFormLayout

```python
from PySide6.QtWidgets import QFormLayout

form = QFormLayout()
form.addRow("Name:", nameLineEdit)
form.addRow("Email:", emailLineEdit)
form.addRow("Age:", ageSpinBox)
form.addRow(button)  # Full width row

# Alignment
form.setLabelAlignment(Qt.AlignmentFlag.AlignRight)
form.setFormAlignment(Qt.AlignmentFlag.AlignHCenter)
```

### QStackedLayout

```python
from PySide6.QtWidgets import QStackedLayout

stack = QStackedLayout()
stack.addWidget(page1)
stack.addWidget(page2)
stack.addWidget(page3)
stack.setCurrentIndex(0)
```

### Layout Properties

```python
# Margins (left, top, right, bottom)
layout.setContentsMargins(10, 10, 10, 10)

# Spacing between widgets
layout.setSpacing(5)

# Widget alignment
layout.addWidget(label, alignment=Qt.AlignmentFlag.AlignCenter)

# Stretch factors
layout.addWidget(widget1, stretch=1)
layout.addWidget(widget2, stretch=2)  # Gets twice the space

# Minimum/maximum sizes
widget.setMinimumSize(100, 50)
widget.setMaximumSize(500, 300)

# Size policy
from PySide6.QtWidgets import QSizePolicy
widget.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)
```

## References

- **Qt for Python Widgets**: https://doc.qt.io/qtforpython-6/PySide6/QtWidgets/
- **Widget Gallery**: https://doc.qt.io/qtforpython-6/widgetgallery.html
- **Layout Management**: https://doc.qt.io/qtforpython-6/layouts.html
