---
name: gimp-plugin
description: Use when developing GIMP 3.0+ plugins in Python 3 - procedure registration, image and layer operations, GEGL operations, PDB calls, dialogs and progress bars, file export, or batch processing plugins
metadata:
  author: mte90
  version: 2.0.0
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

## Deep Dives

For detailed reference material, load these files on demand:

- **Image Operations, GEGL, and PDB** — `references/image-operations.md`: Drawable access, layer operations, selections, pixel access, GEGL operation graphs, and PDB procedure calls
- **User Interface and Files** — `references/ui-and-files.md`: GTK dialogs, color pickers, file dialogs, progress bars, file load/save operations
- **Complete Examples** — `references/complete-examples.md`: Full plugin implementations (batch resize, artistic filter)

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