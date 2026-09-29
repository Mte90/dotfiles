# Item Views and Layout Management - Deep Dive

This file is loaded on demand from frameworks/pyqt/widgets/SKILL.md for detailed reference on item views and layouts.

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