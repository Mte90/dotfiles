# JPEXS FFDec - Complete Reference

## Installation

### Download
- **GitHub Releases**: https://github.com/jindrapetrik/jpexs-decompiler/releases
- **Latest**: v26.0.0+ (check releases page for current version)
- **Requirements**: Java 8+ (Java 11+ recommended)

### Platform-Specific
```bash
# Linux (Flatpak)
flatpak install flathub com.jpexs.decompiler.flash

# Linux (direct)
wget https://github.com/jindrapetrik/jpexs-decompiler/releases/download/version/ffdec.zip
unzip ffdec.zip -d ~/ffdec/

# macOS / Windows
# Download from GitHub releases page
```

## Full Command Reference

### Opening Files
```bash
# GUI mode
java -jar ffdec.jar game.swf

# Open multiple files
java -jar ffdec.jar game1.swf game2.swf

# Open from directory (processes all SWFs)
java -jar ffdec.jar /path/to/swf_directory/
```

### Export Commands

```bash
# Syntax: java -jar ffdec.jar -export <itemtype> <outdir> <infile> [options]

# Export types:
java -jar ffdec.jar -export script       "out/" in.swf    # ActionScript source
java -jar ffdec.jar -export image       "out/" in.swf    # Images (PNG/JPEG)
java -jar ffdec.jar -export shape       "out/" in.swf    # Shapes (SVG)
java -jar ffdec.jar -export morphshape  "out/" in.swf    # MorphShapes (SVG)
java -jar ffdec.jar -export movie       "out/" in.swf    # Movies (FLV)
java -jar ffdec.jar -export font        "out/" in.swf    # Fonts (TTF)
java -jar ffdec.jar -export font4       "out/" in.swf    # CFF Fonts
java -jar ffdec.jar -export frame       "out/" in.swf    # Frames as PNG
java -jar ffdec.jar -export sprite      "out/" in.swf    # Sprites as PNG
java -jar ffdec.jar -export button      "out/" in.swf    # Buttons as PNG
java -jar ffdec.jar -export sound       "out/" in.swf    # Sounds (MP3/WAV)
java -jar ffdec.jar -export binaryData  "out/" in.swf    # Binary data (raw)
java -jar ffdec.jar -export symbolClass "out/" in.swf    # Symbol-Class mapping (CSV)
java -jar ffdec.jar -export text        "out/" in.swf    # Texts (plain)
java -jar ffdec.jar -export all         "out/" in.swf    # Everything (not FLA/XFL)
java -jar ffdec.jar -export fla         "out/" in.swf    # Full FLA project
java -jar ffdec.jar -export xfl         "out/" in.swf    # Full XFL project (uncompressed)

# Multiple types (comma-separated, NO spaces):
java -jar ffdec.jar -export "script,image,shape,sound,font" "out/" in.swf

# Format options:
java -jar ffdec.jar -export image "out/" in.swf -format png    # png, jpeg
java -jar ffdec.jar -export shape "out/" in.swf -format svg    # svg, png
java -jar ffdec.jar -export sound "out/" in.swf -format mp3    # mp3, wav
java -jar ffdec.jar -export font  "out/" in.swf -format ttf    # ttf, cff
```

### Dump/Inspect Commands
```bash
# Dump SWF tag structure
java -jar ffdec.jar -dumpSWF game.swf

# Dump AS3 script list (class names and paths)
java -jar ffdec.jar -dumpAS3 game.swf

# Dump AS1/AS2 script list with export names
java -jar ffdec.jar -dumpAS2 -exportNames game.swf

# Dump AS1/AS2 scripts without export names
java -jar ffdec.jar -dumpAS2 game.swf
```

### Replace/Edit Commands
```bash
# Replace a script
java -jar ffdec.jar -replace script "in.swf" "out.swf" "ScriptName.as" "path/to/new_script.as"

# Replace an image
java -jar ffdec.jar -replace image "in.swf" "out.swf" "imageId" "path/to/new_image.png"

# Replace a shape
java -jar ffdec.jar -replace shape "in.swf" "out.swf" "shapeId" "path/to/new_shape.svg"

# Compress/Decompress
java -jar ffdec.jar -compress "in.swf" "out.swf" zlib
java -jar ffdec.jar -compress "in.swf" "out.swf" lzma

# Decompress SWF
java -jar ffdec.jar -decompress "in.swf" "out.swf"
```

### Advanced Options
```bash
# Select specific characters by ID range
java -jar ffdec.jar -export image "out/" in.swf -selectRange 1-50

# Select by character ID list
java -jar ffdec.jar -export script "out/" in.swf -selectIds 5,10,15

# Export with specific naming pattern
java -jar ffdec.jar -export image "out/" in.swf -exportNamePattern "{tag}_{name}"

# Parallel processing (faster for large files)
java -jar ffdec.jar -export all "out/" in.swf -parallel

# Process all SWFs in a directory
java -jar ffdec.jar -export script "out/" /path/to/swf_folder/
```

## Supported File Formats

### Input Formats
- `.swf` - Standard Flash files (compressed Zlib, LZMA, or uncompressed)
- `.gfx` - ScaleForm GFx files (64-bit only)
- `.iggy` - Iggy font files (64-bit only)
- `.swc` - SWC library files
- `.abc` - ActionScript Byte Code files (standalone)
- Binary files (searches for embedded SWFs)

### Image Formats
- JPEG (with/without tables)
- PNG (lossless)
- GIF (static)
- DefineBitsLossless (lossless bitmap)

### Sound Formats
- MP3
- ADPCM (compressed PCM)
- PCM (raw, little/big endian)
- Nellymoser
- Speex
- FLV audio streams

### Font Formats
- TrueType (TTF)
- CFF (Compact Font Format)
- DefineFont4 (CFF-based)

## Output Formats

### XFL Export Structure
```
output/
├── DOMDocument.xml          # Main document
├── LIBRARY/
│   ├── bin/                 # Binary data (shapes compiled to SWF)
│   ├── Symbol_1.xml         # Each symbol definition
│   └── ...
├── bin/
│   ├── Symbol_1.swf
│   └── ...
├── META-INF/
│   └── manifest.xml
└── mimetype
```

### ActionScript Export Format
Scripts are exported as `.as` files with package structure preserved:
```
output/scripts/
├── PackageName/
│   ├── ClassName.as
│   └── AnotherClass.as
├── frame1_script.as
└── ...
```

## Tips for Game Migration

1. **Always export to XFL** first - it gives you the full editable project structure
2. **Export scripts separately** for code analysis and translation
3. **Export images as PNG** for lossless quality (re-encode later if needed)
4. **Export sounds as MP3** for web compatibility
5. **Export shapes as SVG** for vector quality preservation
6. **Check `-dumpAS3` output** to understand the full class hierarchy before starting translation
7. **Use `-parallel`** for large files to speed up extraction
