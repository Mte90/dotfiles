# User Interface and File Operations Reference

This reference file is loaded on demand from ../SKILL.md when working with dialogs, file operations, or progress bars.

## User Interface

### Simple Input Dialog

```python
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

def show_dialog(procedure, config, image, drawable):
    """Show a simple dialog for plugin settings."""
    dialog = Gtk.Dialog(
        title="My Plugin Settings",
        parent=None,
        flags=Gtk.DialogFlags.MODAL,
        buttons=(
            Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
            Gtk.STOCK_OK, Gtk.ResponseType.OK
        )
    )
    
    dialog.set_default_size(300, 200)
    
    # Content area
    box = dialog.get_content_area()
    
    # Grid layout
    grid = Gtk.Grid()
    grid.set_column_spacing(10)
    grid.set_row_spacing(10)
    grid.set_margin_top(10)
    grid.set_margin_bottom(10)
    grid.set_margin_start(10)
    grid.set_margin_end(10)
    
    # Radius spin button
    label = Gtk.Label(label="Blur Radius:")
    grid.attach(label, 0, 0, 1, 1)
    
    spin = Gtk.SpinButton()
    spin.set_range(1, 100)
    spin.set_value(5)
    grid.attach(spin, 1, 0, 1, 1)
    
    # Preview checkbox
    preview = Gtk.CheckButton(label="Preview")
    preview.set_active(True)
    grid.attach(preview, 0, 1, 2, 1)
    
    box.pack_start(grid, True, True, 0)
    
    dialog.show_all()
    response = dialog.run()
    
    radius = spin.get_value()
    do_preview = preview.get_active()
    
    dialog.destroy()
    
    if response == Gtk.ResponseType.OK:
        return True, radius, do_preview
    return False, None, None
```

### Color Picker

```python
def color_picker_dialog():
    """Show color selection dialog."""
    dialog = Gtk.ColorChooserDialog(
        title="Select Color",
        parent=None
    )
    
    response = dialog.run()
    
    if response == Gtk.ResponseType.OK:
        color = dialog.get_rgba()
        dialog.destroy()
        return Gimp.RGBA(color.red, color.green, color.blue, color.alpha)
    
    dialog.destroy()
    return None
```

### File Dialog

```python
def file_open_dialog():
    """Show file open dialog."""
    dialog = Gtk.FileChooserDialog(
        title="Open Image",
        parent=None,
        action=Gtk.FileChooserAction.OPEN,
        buttons=(
            Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
            Gtk.STOCK_OPEN, Gtk.ResponseType.OK
        )
    )
    
    # Add file filter
    filter_image = Gtk.FileFilter()
    filter_image.set_name("Image files")
    filter_image.add_pattern("*.png")
    filter_image.add_pattern("*.jpg")
    filter_image.add_pattern("*.jpeg")
    filter_image.add_pattern("*.tif")
    dialog.add_filter(filter_image)
    
    response = dialog.run()
    filename = dialog.get_filename() if response == Gtk.ResponseType.OK else None
    dialog.destroy()
    
    return filename
```

### Progress Bar

```python
def long_operation_with_progress(image, drawable):
    """Show progress during long operation."""
    Gimp.progress_init("Processing image...")
    
    total = 100
    for i in range(total):
        # Do work...
        
        # Update progress
        Gimp.progress_update(i / total)
        
        # Check for user cancellation
        if Gimp.user_interrupt():
            Gimp.message("Operation cancelled by user")
            return
    
    Gimp.progress_update(1.0)
    Gimp.progress_end()
```

## File Operations

### Opening Files

```python
def open_image(filepath):
    """Open an image file."""
    # Using GIMP's file load
    image = Gimp.file_load(
        Gimp.RunMode.NONINTERACTIVE,
        None,  # file
        filepath
    )
    return image
```

### Saving Files

```python
def save_image(image, drawable, filepath, file_type="png"):
    """Save image to file."""
    if file_type == "png":
        procedure = Gimp.get_pdb().lookup_procedure("file-png-save")
    elif file_type == "jpeg":
        procedure = Gimp.get_pdb().lookup_procedure("file-jpeg-save")
    elif file_type == "tiff":
        procedure = Gimp.get_pdb().lookup_procedure("file-tiff-save")
    
    config = Gimp.ProcedureConfig.new(procedure)
    
    # PNG specific options
    if file_type == "png":
        config.set_property("compression", 9)
        config.set_property("interlaced", False)
    
    Gimp.file_save(
        Gimp.RunMode.NONINTERACTIVE,
        image,
        drawable,
        None,  # file
        filepath
    )
```

### Export with Options

```python
def export_as_jpeg(image, drawable, filepath, quality=0.85):
    """Export image as JPEG with quality setting."""
    procedure = Gimp.get_pdb().lookup_procedure("file-jpeg-save")
    config = Gimp.ProcedureConfig.new(procedure)
    
    config.set_property("quality", quality)
    config.set_property("smoothing", 0.0)
    config.set_property("optimize", True)
    config.set_property("progressive", False)
    config.set_property("baseline", True)
    config.set_property("sub-sampling", 2)  # 0=4:4:4, 1=4:2:2, 2=4:2:0
    config.set_property("restart", 0)
    config.set_property("dct", 1)  # 0=int, 1=float, 2=fast-int
    
    result = procedure.run(config)
```