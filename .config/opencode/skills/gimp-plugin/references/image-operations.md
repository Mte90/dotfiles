# Image Operations, GEGL, and PDB Reference

This reference file is loaded on demand from ../SKILL.md when working with image manipulation, GEGL operations, or PDB procedures.

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