---
name: gimp-plugin
description: "Develop GIMP 3.0+ plugins using Python 3 with GEGL operations, image manipulation, UI dialogs, and procedure registration"
metadata:
  author: "OSS AI Skills"
  version: "1.0.0"
  tags:
    - python
    - gimp
    - image-processing
    - graphics
    - plugin
    - gegl
---

# GIMP Plugin Development

Complete guide for developing GIMP 3.0+ plugins with Python 3.

## Overview

GIMP (GNU Image Manipulation Program) supports plugins written in Python 3. GIMP 3.0 introduced significant API changes, GEGL-based image processing, and modern Python integration.

**Key Features:**
- Python 3 scripting (no longer Python 2)
- GEGL (Generic Graphics Library) for image operations
- New procedure registration system
- GTK 3 dialog support
- Access to all GIMP internal procedures

### GIMP 3.0+ Requirements

```bash
# Check GIMP version
gimp --version  # GIMP 3.0.0 or higher

# Python 3 is bundled with GIMP
# Plugins use the Python interpreter included with GIMP
```

### Plugin Locations

```
# User plugins (preferred)
~/.config/GIMP/3.0/plug-ins/

# System plugins
/usr/lib/gimp/3.0/plug-ins/

# Windows
%APPDATA%\GIMP\3.0\plug-ins\

# macOS
~/Library/Application Support/GIMP/3.0/plug-ins/
```

### Plugin File Structure

```
my_plugin/
├── my_plugin.py           # Main plugin file (must be executable on Linux)
└── __pycache__/           # Python cache (auto-generated)
```

```bash
# Make plugin executable (Linux/macOS)
chmod +x ~/.config/GIMP/3.0/plug-ins/my_plugin.py
```

## Basic Plugin Structure

### Minimal Plugin

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import gi
gi.require_version('Gimp', '3.0')
from gi.repository import Gimp
from gi.repository import GObject
from gi.repository import GLib

def my_plugin(procedure, run_mode, image, n_drawables, drawables, args, data):
    """Main plugin function."""
    Gimp.message("Hello from my plugin!")
    return procedure.new_return_values(Gimp.PDBStatusType.SUCCESS, GLib.Error())

class MyPlugin(Gimp.PlugIn):
    ## Gimp.PlugIn virtual methods ##
    
    def do_query_procedures(self):
        """Return list of procedure names."""
        return ["plug-in-my-plugin"]
    
    def do_create_procedure(self, name):
        """Create procedure definition."""
        procedure = Gimp.ImageProcedure.new(
            self, name,
            Gimp.PDBProcType.PLUGIN,
            my_plugin, None
        )
        procedure.set_image_types("RGB*")
        procedure.set_documentation(
            "My Plugin Description",
            "Detailed help text",
            name
        )
        procedure.set_menu_label("My Plugin")
        procedure.add_menu_path("<Image>/Filters/Custom/")
        procedure.set_attribution("Author", "Author", "2024")
        
        return procedure

Gimp.main(MyPlugin.__gtype__, sys.argv)
```

### Plugin with Parameters

```python
#!/usr/bin/env python3

import gi
gi.require_version('Gimp', '3.0')
gi.require_version('Gegl', '0.4')
from gi.repository import Gimp, Gegl, GObject, GLib

def my_filter(procedure, run_mode, image, n_drawables, drawables, args, data):
    """Apply filter with user parameters."""
    # Get parameters
    blur_amount = args.index(0)
    opacity = args.index(1)
    
    # Get active drawable (layer)
    drawable = drawables[0]
    
    # Apply GEGL operation
    Gimp.drawable_filter_new(drawable, "gegl:gaussian-blur")
    
    # Update image
    Gimp.displays_flush()
    
    return procedure.new_return_values(Gimp.PDBStatusType.SUCCESS, GLib.Error())

class MyFilterPlugin(Gimp.PlugIn):
    def do_query_procedures(self):
        return ["plug-in-my-filter"]
    
    def do_create_procedure(self, name):
        procedure = Gimp.ImageProcedure.new(
            self, name,
            Gimp.PDBProcType.PLUGIN,
            my_filter, None
        )
        procedure.set_image_types("RGB*, GRAY*")
        procedure.set_documentation(
            "Apply custom blur filter",
            "Applies a configurable blur to the image",
            name
        )
        procedure.set_menu_label("My Blur Filter")
        procedure.add_menu_path("<Image>/Filters/Blur/")
        
        # Add parameters
        procedure.add_argument_from_property(
            GObject.Value(GObject.TYPE_DOUBLE),
            "blur-amount",
            "Blur Amount",
            "Radius of the blur",
            0.0, 100.0, 5.0
        )
        procedure.add_argument_from_property(
            GObject.Value(GObject.TYPE_DOUBLE),
            "opacity",
            "Opacity",
            "Filter opacity (0-100)",
            0.0, 100.0, 100.0
        )
        
        return procedure

Gimp.main(MyFilterPlugin.__gtype__, sys.argv)
```

## Procedure Registration

### Procedure Types

```python
# Image procedure (operates on image)
procedure = Gimp.ImageProcedure.new(
    self, name,
    Gimp.PDBProcType.PLUGIN,
    callback, data
)

# Load procedure (file import)
procedure = Gimp.LoadProcedure.new(
    self, name,
    Gimp.PDBProcType.PLUGIN,
    callback, data
)

# Save procedure (file export)
procedure = Gimp.SaveProcedure.new(
    self, name,
    Gimp.PDBProcType.PLUGIN,
    callback, data
)

# Brush procedure (create brushes)
procedure = Gimp.BrushProcedure.new(
    self, name,
    Gimp.PDBProcType.PLUGIN,
    callback, data
)
```

### Menu Registration

```python
procedure.add_menu_path("<Image>/Filters/MyFilters/")
procedure.add_menu_path("<Image>/Edit/")           # Edit menu
procedure.add_menu_path("<Image>/Select/")         # Select menu
procedure.add_menu_path("<Image>/View/")           # View menu
procedure.add_menu_path("<Image>/Image/")          # Image menu
procedure.add_menu_path("<Image>/Layer/")          # Layer menu
procedure.add_menu_path("<Image>/Colors/")         # Colors menu
procedure.add_menu_path("<Image>/Tools/")          # Tools menu
procedure.add_menu_path("<Filters>/")              # Filters menu
procedure.add_menu_path("<Toolbox>/Xtns/")         # Extensions
procedure.add_menu_path("<Image>/Filters/Custom/My Plugin")
```

### Image Types

```python
procedure.set_image_types("RGB*")       # RGB images (any alpha)
procedure.set_image_types("RGBA")       # RGB with alpha only
procedure.set_image_types("RGB,GRAY")   # RGB or grayscale
procedure.set_image_types("*")          # All image types
procedure.set_image_types("INDEXED*")   # Indexed images
```

### Parameters

```python
# Boolean
procedure.add_argument(
    GObject.param_spec_boolean(
        "preview",
        "Preview",
        "Show preview",
        True,  # default
        GObject.ParamFlags.READWRITE
    )
)

# Integer
procedure.add_argument(
    GObject.param_spec_int(
        "radius",
        "Radius",
        "Blur radius in pixels",
        1,    # min
        100,  # max
        5,    # default
        GObject.ParamFlags.READWRITE
    )
)

# Float/Double
procedure.add_argument(
    GObject.param_spec_double(
        "amount",
        "Amount",
        "Effect amount (0-100)",
        0.0,   # min
        100.0, # max
        50.0,  # default
        GObject.ParamFlags.READWRITE
    )
)

# String
procedure.add_argument(
    GObject.param_spec_string(
        "text",
        "Text",
        "Text to render",
        "",  # default
        GObject.ParamFlags.READWRITE
    )
)

# Enum
from gi.repository import Gimp
procedure.add_argument(
    Gimp.param_spec_enum(
        "blend-mode",
        "Blend Mode",
        "Layer blend mode",
        Gimp.LayerMode.__gtype__,
        Gimp.LayerMode.NORMAL,
        GObject.ParamFlags.READWRITE
    )
)

# Color
procedure.add_argument(
    Gimp.param_spec_rgb(
        "color",
        "Color",
        "Foreground color",
        True,  # has alpha
        Gimp.RGBA(1.0, 0.0, 0.0, 1.0),  # default red
        GObject.ParamFlags.READWRITE
    )
)
```

## Image Operations

### Accessing Image and Drawable

```python
def my_plugin(procedure, run_mode, image, n_drawables, drawables, args, data):
    # Get current image
    width = image.get_width()
    height = image.get_height()
    base_type = image.get_base_type()  # RGB, GRAY, INDEXED
    
    # Get active drawable (layer or mask)
    drawable = drawables[0]
    drawable_width = drawable.get_width()
    drawable_height = drawable.get_height()
    has_alpha = drawable.has_alpha()
    bpp = drawable.get_bpp()  # Bytes per pixel
    
    # Get selection bounds
    non_empty, x1, y1, x2, y2 = Gimp.selection_bounds(image, drawable)
    
    if non_empty:
        # Selection exists
        selection_width = x2 - x1
        selection_height = y2 - y1
    
    return procedure.new_return_values(Gimp.PDBStatusType.SUCCESS, GLib.Error())
```

### Layer Operations

```python
def layer_operations(image):
    # Get active layer
    layer = image.get_selected_layer()
    
    # Create new layer
    new_layer = Gimp.Layer.new(
        image,
        "New Layer",
        image.get_width(),
        image.get_height(),
        Gimp.ImageType.RGBA_IMAGE,
        100.0,  # opacity
        Gimp.LayerMode.NORMAL
    )
    
    # Add layer to image
    image.insert_layer(new_layer, None, 0)  # parent, position
    
    # Layer properties
    layer.set_opacity(50.0)
    layer.set_mode(Gimp.LayerMode.MULTIPLY)
    layer.set_visible(True)
    layer.set_name("Renamed Layer")
    
    # Duplicate layer
    duplicate = Gimp.Layer.copy(layer)
    image.insert_layer(duplicate, None, 0)
    
    # Delete layer
    image.remove_layer(layer)
    
    # Merge layers
    merged = image.merge_down(layer, Gimp.MergeType.EXPAND_AS_NECESSARY)
    
    # Flatten image
    image.flatten()
```

### Selection Operations

```python
def selection_operations(image, drawable):
    # Select all
    Gimp.selection_all(image)
    
    # Select none
    Gimp.selection_none(image)
    
    # Rectangle selection
    Gimp.image_select_rectangle(
        image,
        Gimp.ChannelOps.REPLACE,  # REPLACE, ADD, SUBTRACT, INTERSECT
        10, 10, 100, 100  # x, y, width, height
    )
    
    # Ellipse selection
    Gimp.image_select_ellipse(
        image,
        Gimp.ChannelOps.ADD,
        50, 50, 200, 150
    )
    
    # Color selection (fuzzy select)
    Gimp.image_select_color(
        image,
        Gimp.ChannelOps.REPLACE,
        drawable,
        100, 100,  # x, y
        15.0,      # threshold
        True,      # select-transparent
        False,     # sample-merged
        False,     # sample-criterion
        False,     # sample-threshold-int
    )
    
    # Invert selection
    Gimp.selection_invert(image)
    
    # Float selection
    floating = Gimp.selection_float(drawable, 0, 0)
    
    # Selection bounds
    non_empty, x1, y1, x2, y2 = Gimp.selection_bounds(image, drawable)
```

### Pixel Access

```python
def pixel_operations(drawable):
    # Get pixel at position
    pixel = drawable.get_pixel(100, 100)
    # pixel is a GeglBuffer or bytes
    
    # Set pixel (using GEGL buffer)
    buffer = drawable.get_buffer()
    
    # For more complex operations, use GEGL
    # or GIMP's drawable procedures
```

## GEGL Operations

### Using GEGL Filters

```python
import gi
gi.require_version('Gegl', '0.4')
from gi.repository import Gegl

def apply_gegl_blur(drawable, radius):
    """Apply GEGL gaussian blur."""
    # Create GEGL node
    graph = Gegl.Node()
    
    # Source node (from drawable)
    src = graph.create_child("gegl:buffer-source")
    src.set_property("buffer", drawable.get_buffer())
    
    # Blur node
    blur = graph.create_child("gegl:gaussian-blur")
    blur.set_property("std-dev-x", radius)
    blur.set_property("std-dev-y", radius)
    
    # Output node
    sink = graph.create_child("gegl:buffer-sink")
    
    # Connect nodes
    src.connect_to("output", blur, "input")
    blur.connect_to("output", sink, "input")
    
    # Process
    sink.process()

def apply_gegl_brightness_contrast(drawable, brightness, contrast):
    """Apply brightness-contrast adjustment."""
    graph = Gegl.Node()
    
    src = graph.create_child("gegl:buffer-source")
    src.set_property("buffer", drawable.get_buffer())
    
    bc = graph.create_child("gegl:brightness-contrast")
    bc.set_property("brightness", brightness)  # -1.0 to 1.0
    bc.set_property("contrast", contrast)       # -1.0 to 1.0
    
    sink = graph.create_child("gegl:write-buffer")
    sink.set_property("buffer", drawable.get_buffer())
    
    src.connect_to("output", bc, "input")
    bc.connect_to("output", sink, "input")
    
    sink.process()
```

### Common GEGL Operations

```python
# Available GEGL operations include:
GEGL_OPERATIONS = {
    # Blur
    "gegl:gaussian-blur": {"std-dev-x": 5.0, "std-dev-y": 5.0},
    "gegl:box-blur": {"radius": 5},
    "gegl:motion-blur": {"length": 10, "angle": 0},
    
    # Color Adjustments
    "gegl:brightness-contrast": {"brightness": 0.0, "contrast": 0.0},
    "gegl:levels": {"in-low": 0.0, "in-high": 1.0, "out-low": 0.0, "out-high": 1.0},
    "gegl:curves": {},
    "gegl:color-enhance": {},
    
    # Artistic
    "gegl:cartoon": {"mask-radius": 7.0, "pct-black": 0.2},
    "gegl:oilify": {"mask-radius": 4, "exponent": 8},
    "gegl:photocopy": {"mask-radius": 8.0, "sharpness": 0.5},
    "gegl:softglow": {"glow-radius": 10.0, "brightness": 0.4},
    
    # Edge Detection
    "gegl:edge": {"algorithm": "sobel"},
    "gegl:edge-sobel": {},
    "gegl:edge-laplace": {},
    
    # Distort
    "gegl:lens-distortion": {"main": 0.0, "edge": 0.0},
    "gegl:ripple": {"amplitude": 25.0, "period": 200.0},
    "gegl:waves": {"amplitude": 10.0, "wavelength": 50.0},
    "gegl:whirl-pinch": {"whirl": 90.0, "pinch": 0.0},
    
    # Noise
    "gegl:noise-hsv": {"holdness": 2, "hue-distance": 0.1},
    "gegl:noise-rgb": {"correlated": False},
    "gegl:noise-solid": {},
    
    # Sharpen
    "gegl:unsharp-mask": {"std-dev": 5.0, "scale": 0.5},
    "gegl:focus-blur": {"radius": 5.0},
    
    # Stylize
    "gegl:emboss": {"azimuth": 30.0, "elevation": 45.0, "depth": 20},
    "gegl:tile-glass": {"tile-width": 25, "tile-height": 25},
    "gegl:mosaic": {"tile-size": 15, "tile-height": 4},
    
    # Effects
    "gegl:dropshadow": {"x": 5.0, "y": 5.0, "radius": 10.0},
    "gegl:vignette": {"radius": 1.0, "softness": 0.5},
    "gegl:fractal-explorer": {},
}
```

## PDB (Procedural Database)

### Calling GIMP Procedures

```python
def call_pdb_procedures(image, drawable):
    # Get procedure
    pdb = Gimp.get_pdb()
    
    # List all procedures
    procedures = pdb.query_procedures("", "", "", "", "", "", "")
    
    # Call procedure by name
    # Using Gimp procedures
    Gimp.context_set_foreground(Gimp.RGBA(1.0, 0.0, 0.0, 1.0))
    Gimp.edit_fill(drawable, Gimp.FillType.FOREGROUND)
    
    # Using PDB directly
    config = Gimp.ProcedureConfig.new(pdb.lookup_procedure("plug-in-gauss"))
    config.set_property("run-mode", Gimp.RunMode.NONINTERACTIVE)
    config.set_property("image", image)
    config.set_property("drawable", drawable)
    config.set_property("horizontal", 5.0)
    config.set_property("vertical", 5.0)
    
    result = pdb.run_procedure("plug-in-gauss", config)
```

### Common PDB Procedures

```python
# Gaussian blur
Gimp drawable_filter operations for blur

# Color tools
Gimp.desaturate(image, drawable, Gimp.DesaturateMode.LIGHTNESS)
Gimp.invert(drawable)
Gimp.histogram(drawable, Gimp.HistogramChannel.VALUE, 0.0, 1.0)

# Transform
Gimp.item_transform_flip_simple(drawable, Gimp.OrientationType.HORIZONTAL, True, 0.0)
Gimp.item_transform_rotate_simple(drawable, Gimp.RotationType.ROTATE_90, True, 0, 0)
Gimp.item_transform_scale(drawable, 0, 0, 100, 100, False)

# Edit operations
Gimp.edit_copy(drawable)
Gimp.edit_paste(drawable, False)
Gimp.edit_clear(drawable)
```

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

## Complete Plugin Example

### Batch Resize Plugin

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Batch Resize Plugin for GIMP 3.0+
Resizes all open images to specified dimensions
"""

import gi
gi.require_version('Gimp', '3.0')
gi.require_version('Gegl', '0.4')
gi.require_version('Gtk', '3.0')
from gi.repository import Gimp, Gegl, GObject, GLib, Gtk
import sys

def batch_resize(procedure, run_mode, image, n_drawables, drawables, args, data):
    """Resize all open images."""
    # Get parameters
    width = args.index(0)
    height = args.index(1)
    maintain_aspect = args.index(2)
    
    # Get all open images
    images = Gimp.image_list()
    
    Gimp.progress_init("Batch resizing images...")
    
    for i, img in enumerate(images):
        Gimp.progress_set_text(f"Processing {img.get_name()}")
        
        if maintain_aspect:
            # Calculate aspect ratio
            orig_width = img.get_width()
            orig_height = img.get_height()
            aspect = orig_width / orig_height
            
            if width / height > aspect:
                new_width = int(height * aspect)
                new_height = height
            else:
                new_width = width
                new_height = int(width / aspect)
        else:
            new_width = width
            new_height = height
        
        # Scale image
        Gimp.image_scale(img, new_width, new_height, 
                        Gimp.InterpolationType.CUBIC)
        
        # Update progress
        Gimp.progress_update((i + 1) / len(images))
    
    Gimp.progress_end()
    Gimp.displays_flush()
    
    return procedure.new_return_values(Gimp.PDBStatusType.SUCCESS, GLib.Error())

class BatchResizePlugin(Gimp.PlugIn):
    ## Gimp.PlugIn virtual methods ##
    
    def do_query_procedures(self):
        return ["plug-in-batch-resize"]
    
    def do_create_procedure(self, name):
        procedure = Gimp.ImageProcedure.new(
            self, name,
            Gimp.PDBProcType.PLUGIN,
            batch_resize, None
        )
        
        procedure.set_image_types("*")
        procedure.set_documentation(
            "Batch resize all open images",
            "Resizes all open images to the specified dimensions",
            name
        )
        procedure.set_menu_label("Batch Resize")
        procedure.add_menu_path("<Image>/Image/Resize/")
        procedure.set_attribution("Author", "Author", "2024")
        
        # Parameters
        procedure.add_argument(
            GObject.param_spec_int(
                "width",
                "Width",
                "Target width in pixels",
                1, 10000, 800,
                GObject.ParamFlags.READWRITE
            )
        )
        procedure.add_argument(
            GObject.param_spec_int(
                "height",
                "Height", 
                "Target height in pixels",
                1, 10000, 600,
                GObject.ParamFlags.READWRITE
            )
        )
        procedure.add_argument(
            GObject.param_spec_boolean(
                "maintain-aspect",
                "Maintain Aspect Ratio",
                "Keep original aspect ratio",
                True,
                GObject.ParamFlags.READWRITE
            )
        )
        
        return procedure

Gimp.main(BatchResizePlugin.__gtype__, sys.argv)
```

### Artistic Filter Plugin

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Watercolor Effect Plugin for GIMP 3.0+
Creates a watercolor painting effect
"""

import gi
gi.require_version('Gimp', '3.0')
gi.require_version('Gegl', '0.4')
from gi.repository import Gimp, Gegl, GObject, GLib
import sys

def watercolor_effect(procedure, run_mode, image, n_drawables, drawables, args, data):
    """Apply watercolor effect."""
    drawable = drawables[0]
    
    # Get parameters
    brush_size = args.index(0)
    color_simplification = args.index(1)
    gradient_smoothing = args.index(2)
    
    Gimp.progress_init("Applying watercolor effect...")
    Gimp.progress_update(0.1)
    
    # Create working layer
    layer_copy = Gimp.Layer.copy(drawable)
    image.insert_layer(layer_copy, None, 0)
    
    Gimp.progress_update(0.2)
    
    # Step 1: Apply oilify effect
    graph = Gegl.Node()
    src = graph.create_child("gegl:buffer-source")
    src.set_property("buffer", layer_copy.get_buffer())
    
    oilify = graph.create_child("gegl:oilify")
    oilify.set_property("mask-radius", int(brush_size))
    oilify.set_property("exponent", int(color_simplification))
    
    sink = graph.create_child("gegl:write-buffer")
    sink.set_property("buffer", layer_copy.get_buffer())
    
    src.connect_to("output", oilify, "input")
    oilify.connect_to("output", sink, "input")
    sink.process()
    
    Gimp.progress_update(0.5)
    
    # Step 2: Apply slight blur
    blur = graph.create_child("gegl:gaussian-blur")
    blur.set_property("std-dev-x", gradient_smoothing)
    blur.set_property("std-dev-y", gradient_smoothing)
    
    src.set_property("buffer", layer_copy.get_buffer())
    src.connect_to("output", blur, "input")
    blur.connect_to("output", sink, "input")
    sink.process()
    
    Gimp.progress_update(0.8)
    
    # Step 3: Add paper texture (optional)
    # This could be done with a noise overlay
    
    Gimp.progress_update(1.0)
    Gimp.progress_end()
    
    Gimp.displays_flush()
    
    return procedure.new_return_values(Gimp.PDBStatusType.SUCCESS, GLib.Error())

class WatercolorPlugin(Gimp.PlugIn):
    def do_query_procedures(self):
        return ["plug-in-watercolor"]
    
    def do_create_procedure(self, name):
        procedure = Gimp.ImageProcedure.new(
            self, name,
            Gimp.PDBProcType.PLUGIN,
            watercolor_effect, None
        )
        
        procedure.set_image_types("RGB*")
        procedure.set_documentation(
            "Watercolor Effect",
            "Transform photo into watercolor painting",
            name
        )
        procedure.set_menu_label("Watercolor Effect")
        procedure.add_menu_path("<Image>/Filters/Artistic/")
        procedure.set_attribution("Author", "Author", "2024")
        
        procedure.add_argument(
            GObject.param_spec_int(
                "brush-size",
                "Brush Size",
                "Size of brush strokes",
                1, 50, 8,
                GObject.ParamFlags.READWRITE
            )
        )
        procedure.add_argument(
            GObject.param_spec_int(
                "color-simplification",
                "Color Simplification",
                "Reduce color complexity",
                1, 20, 10,
                GObject.ParamFlags.READWRITE
            )
        )
        procedure.add_argument(
            GObject.param_spec_double(
                "gradient-smoothing",
                "Gradient Smoothing",
                "Smooth color gradients",
                0.0, 10.0, 1.5,
                GObject.ParamFlags.READWRITE
            )
        )
        
        return procedure

Gimp.main(WatercolorPlugin.__gtype__, sys.argv)
```

## Debugging

### Logging and Messages

```python
# Show message in GIMP console
Gimp.message("Debug message")

# Log to terminal
print("Debug output", file=sys.stderr)

# Show in error console
Gimp.message("Error occurred!")

# Critical message (shows dialog)
Gimp.critical("Critical error in plugin")
```

### Testing Plugin

```bash
# Run GIMP from terminal to see debug output
gimp

# Run with verbose output
G_MESSAGES_DEBUG=all gimp

# Check Python console in GIMP
# Filters -> Python-Fu -> Console
```

## Best Practices

### 1. Always Use Non-Interactive Mode for Batch

```python
if run_mode == Gimp.RunMode.NONINTERACTIVE:
    # No dialogs, use default values
    pass
elif run_mode == Gimp.RunMode.INTERACTIVE:
    # Show dialog for user input
    pass
```

### 2. Clean Up Resources

```python
def my_plugin(procedure, run_mode, image, n_drawables, drawables, args, data):
    try:
        # Do work
        pass
    finally:
        Gimp.progress_end()
        Gimp.displays_flush()
```

### 3. Undo Groups

```python
def with_undo(image):
    # Start undo group
    Gimp.image_undo_group_start(image)
    
    try:
        # Do operations
        pass
    finally:
        # End undo group
        Gimp.image_undo_group_end(image)
```

### 4. Handle Exceptions

```python
def my_plugin(procedure, run_mode, image, n_drawables, drawables, args, data):
    try:
        # Plugin logic
        return procedure.new_return_values(
            Gimp.PDBStatusType.SUCCESS, 
            GLib.Error()
        )
    except Exception as e:
        Gimp.message(f"Error: {str(e)}")
        return procedure.new_return_values(
            Gimp.PDBStatusType.EXECUTION_ERROR,
            GLib.Error.new_literal(Gimp.PlugIn.error_quark(), str(e), 0)
        )
```

## References

- **GIMP Documentation**: https://docs.gimp.org/
- **GIMP Python Documentation**: https://www.gimp.org/docs/python/
- **GEGL Operations Reference**: https://gegl.org/operations/
- **GTK 3 Tutorial**: https://python-gtk-3-tutorial.readthedocs.io/
- **GIMP Developer Wiki**: https://wiki.gimp.org/
