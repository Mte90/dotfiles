---
name: as3-fla-migration
metadata:
  author: Z.AI
  version: "1.0"
description: >
  Analyze, extract, and migrate Flash/ActionScript game projects (.fla, .swf, .as files)
  to modern web technologies (JavaScript, TypeScript, HTML5 Canvas, Haxe/OpenFL).
  Use this skill whenever the user mentions Flash, ActionScript, AS2, AS3, FLA, SWF,
  decompiling Flash games, extracting assets from Flash files, converting Flash to HTML5,
  porting Flash games to modern browsers, migrating legacy Flash content, JPEXS, FFDec,
  Ruffle, CreateJS, OpenFL, Haxe, or any Flash-era game preservation task.
  Also applies when the user has old .fla or .swf files and wants to understand, extract,
  rebuild, or modernize their content.
  NOT for: general web game development without Flash involvement, PDF/document conversion,
  or video format conversion.
---

# Flash / ActionScript Game Migration Skill

A comprehensive skill for analyzing, extracting assets from, and migrating legacy Flash/ActionScript game projects to modern web technologies.

## Quick Reference: File Types

| Type | Format | What It Contains | How to Handle |
|------|--------|-----------------|---------------|
| `.fla` | ZIP archive (compressed) | Timeline, library, assets, embedded scripts | Rename to `.zip`, extract, or use JPEXS |
| `.xfl` | Uncompressed FLA | Same as FLA but as XML + folders | Direct XML parsing |
| `.swf` | Compiled binary | Compiled game (code + assets) | Decompile with JPEXS FFDec |
| `.as` / `.as3` | Text (ActionScript) | Source code (if available) | Read directly, convert to JS/TS/Haxe |
| `.swc` | ZIP archive | Library/component SWF + catalog.xml | Extract with JPEXS or unzip |
| `.gfx` | Modified SWF | ScaleForm UI (Unreal Engine) | JPEXS with GFX support |

---

## Workflow Overview

The migration process follows these phases. Read the detailed reference for each phase as needed:

1. **Phase 1: Inventory & Analysis** - Understand what you're working with
2. **Phase 2: Asset Extraction** - Pull out code, images, sounds, shapes
3. **Phase 3: Code Analysis & Translation** - Convert ActionScript to target language
4. **Phase 4: Rebuild** - Reconstruct the game on a modern framework
5. **Phase 5: Testing & Validation** - Compare output with original behavior

---

## Phase 1: Inventory & Analysis

Before anything else, determine what files you have and what version of Flash/ActionScript was used.

### Step 1: Identify Available Files

Ask the user (or scan the directory) for:
- Source files: `.fla`, `.xfl`, `.as`, `.as3`, `.swc`
- Compiled files: `.swf`
- Supporting files: XML configs, asset folders, external data

### Step 2: Determine ActionScript Version

The migration approach differs significantly between AS2 and AS3:

| Feature | ActionScript 2 (AS2) | ActionScript 3 (AS3) |
|---------|---------------------|---------------------|
| Typing | Dynamic/weak | Static/strong (optional) |
| Classes | Prototype-based | Full OOP (ECMAScript 4) |
| Display | `_root`, `_level` | `DisplayObjectContainer` hierarchy |
| Events | `onEnterFrame`, callbacks | Event dispatcher pattern |
| Package | Flat | Namespaced packages |
| Migration difficulty | High (paradigm shift) | Medium (closer to JS/TS) |

If you have the `.swf` but no source, use JPEXS to determine the version:
```bash
# Dump AS3 script list
java -jar ffdec.jar -dumpAS3 game.swf

# Dump AS1/AS2 script list
java -jar ffdec.jar -dumpAS2 game.swf
```

### Step 3: Assess Game Complexity

Classify the project to choose the right migration strategy:

| Complexity | Indicators | Recommended Approach |
|-----------|-----------|---------------------|
| **Simple** | Animations, basic interactivity, no game logic | Adobe Animate CC or direct CreateJS |
| **Medium** | Game loops, basic physics, score system | Code extraction + JS/TS rebuild |
| **Complex** | Multiple scenes, state machines, AI, networking | Haxe/OpenFL port or full JS/TS rewrite |
| **Very Complex** | Multiplayer, custom protocols, obfuscated code | Phased migration with incremental testing |

### Step 4: Generate Project Inventory

Create an inventory report listing all extractable resources. For SWF files:
```bash
# List all SWF tags (shapes, sprites, sounds, images, scripts)
java -jar ffdec.jar -dumpSWF game.swf
```

The inventory should capture:
- Total number of scripts/classes
- Number of embedded images (with formats)
- Number of sound effects and music tracks
- Number of shapes and vector graphics
- Number of fonts
- Number of frames on the main timeline
- Any external dependencies (loaded SWFs, XML, JSON)

---

## Phase 2: Asset Extraction

### Tool: JPEXS Free Flash Decompiler (FFDec)

JPEXS FFDec is the primary open-source tool for SWF analysis and extraction.
- **GitHub**: https://github.com/jindrapetrik/jpexs-decompiler
- **Latest versions**: v26.0.0+ (actively maintained)
- **License**: GPL v3 / LGPL (some parts MPL)
- **Platforms**: Windows, macOS, Linux (requires Java 8+)

#### Command-Line Export (Batch)

Export all resources from an SWF in one command:

```bash
# Export everything to a directory
java -jar ffdec.jar -export script "output/scripts" game.swf
java -jar ffdec.jar -export image "output/images" game.swf
java -jar ffdec.jar -export shape "output/shapes" game.swf
java -jar ffdec.jar -export sound "output/sounds" game.swf
java -jar ffdec.jar -export font "output/fonts" game.swf
java -jar ffdec.jar -export text "output/texts" game.swf
java -jar ffdec.jar -export frame "output/frames" game.swf
java -jar ffdec.jar -export sprite "output/sprites" game.swf
java -jar ffdec.jar -export button "output/buttons" game.swf
java -jar ffdec.jar -export binaryData "output/binary" game.swf

# Export multiple types at once (comma-separated, NO spaces)
java -jar ffdec.jar -export "script,image,shape,sound,font,text" "output/all" game.swf

# Export to XFL format (uncompressed FLA - XML based, editable)
java -jar ffdec.jar -export xfl "output/xfl" game.swf

# Export to FLA format (compressed, opens in Adobe Animate)
java -jar ffdec.jar -export fla "output/fla" game.swf
```

#### Export Format Options

Customize export formats with `-format`:

```bash
# Images as PNG (default), JPEG, or original format
java -jar ffdec.jar -export image "output/images" game.swf -format png

# Shapes as SVG (default) or PNG
java -jar ffdec.jar -export shape "output/shapes" game.swf -format svg

# Scripts as AS source (default)
java -jar ffdec.jar -export script "output/scripts" game.swf -format as

# Fonts as TTF (default) or CFF
java -jar ffdec.jar -export font "output/fonts" game.swf -format ttf

# Sounds as MP3, WAV, or FLV
java -jar ffdec.jar -export sound "output/sounds" game.swf -format mp3
```

#### Processing FLA Files Directly

FLA files (CS4+) are ZIP archives. To extract their contents:

```bash
# Method 1: Rename and unzip
cp game.fla game.zip
unzip game.zip -d fla_extracted/

# The extracted FLA contains:
# - DOMDocument.xml     (timeline, library, frames structure)
# - LIBRARY/            (library items as separate XML files)
# - bin/                (compiled assets)
# - Settings.xml        (publish settings)
```

The DOMDocument.xml is the most important file - it describes the entire timeline structure, frame scripts, layer ordering, and library symbol references.

### Handling Specific Asset Types

#### Images
- Extracted as PNG or JPEG from SWF
- Check both `DefineBitsJPEG2/3/4` and `DefineBitsLossless1/2` tags
- Some images may be inside sprites/movieclips - export sprites to get them

#### Sounds
- May be in MP3, WAV, ADPCM, or raw PCM format
- `DefineSound` tags for embedded sounds
- `SoundStreamBlock` tags for streaming audio (longer clips/music)
- Export as MP3 when possible for modern compatibility

#### Vector Shapes
- Export as SVG for best quality (scalable, editable)
- Complex shapes may need cleanup after extraction
- Shapes can be converted to Canvas paths or SVG for web use

#### Text
- Static text: exported as plain text
- Dynamic/input text: check for embedded font references
- Text may use device fonts (no extraction needed) or embedded fonts (export separately)

#### Fonts
- Export as TTF (TrueType) for modern web use
- Font names may be obfuscated in SWF - check JPEXS's font viewer
- Consider converting to WOFF2 for web embedding

---

## Phase 3: Code Analysis & Translation

This is the most critical phase. The approach depends on the target technology.

### Option A: ActionScript to JavaScript/TypeScript (Direct Translation)

Best for: AS3 projects, games that need full rewrite anyway, web-only targets.

#### Key Mapping: AS3 → JavaScript/TypeScript

| AS3 Concept | JS/TS Equivalent | Notes |
|------------|-----------------|-------|
| `MovieClip` | Canvas context / DOM element | Use EaselJS Stage or raw Canvas |
| `Sprite` | `createjs.Container` / custom class | DisplayObject equivalent |
| `Event.ENTER_FRAME` | `requestAnimationFrame` loop | Game loop pattern |
| `addEventListener` | Same in JS, or `on('event')` in EaselJS | Nearly identical API |
| `Timer` / `setInterval` | `setTimeout` / `setInterval` | Direct equivalent |
| `getTimer()` | `performance.now()` | Milliseconds since page load |
| `URLRequest` / `Loader` | `fetch()` / `Image()` | Async loading |
| `SharedObject` | `localStorage` | Local persistence |
| `SoundChannel` | Web Audio API / Howler.js | Audio playback |
| `BitmapData` | Canvas ImageData | Pixel manipulation |
| `Point` | `{x, y}` object or custom class | Simple value object |
| `Rectangle` | `{x, y, width, height}` | Simple value object |
| `Matrix` | `DOMMatrix` / Canvas transforms | 2D transformation |
| `TextField` | DOM element / Canvas text | Text rendering |
| `Graphics.lineTo()` | `ctx.lineTo()` | Canvas path API (very similar) |
| `Graphics.drawCircle()` | `ctx.arc()` | Slightly different API |
| `stage.stageWidth` | `canvas.width` | Canvas dimensions |
| `mouseX` / `mouseY` | Mouse event `offsetX/Y` | Relative coordinates |

#### Translation Strategy

1. **Extract all AS3 code** with JPEXS
2. **Identify the entry point** (document class or frame scripts)
3. **Map the class hierarchy** - document inheritance chains
4. **Translate incrementally**: utilities → data models → display → game logic
5. **Use CreateJS** (EaselJS + TweenJS + SoundJS + PreloadJS) to preserve Flash-like display list API

#### AS3 Code Analysis Checklist

For each extracted AS3 class, analyze:
- [ ] **Class purpose**: What does it manage? (player, enemy, UI, physics, etc.)
- [ ] **Dependencies**: What other classes does it reference?
- [ ] **Display objects**: What does it render? (shapes, bitmaps, text)
- [ ] **Events**: What events does it listen to and dispatch?
- [ ] **Timers/loops**: Does it use ENTER_FRAME, Timer, or intervals?
- [ ] **State**: What data does it maintain between frames?
- [ ] **External resources**: Does it load external data, sounds, or images?
- [ ] **AS3-specific features**: Does it use byte manipulation (ByteArray), sockets, or other features without direct JS equivalents?

### Option B: ActionScript to Haxe (via as3hx)

Best for: AS3 projects wanting cross-platform output, games with existing AS3 class libraries.

#### Using as3hx

as3hx is an automated converter from ActionScript 3 to Haxe 3, created by the HaxeFoundation.

```bash
# Install (requires Haxe 3+ and Neko)
git clone https://github.com/HaxeFoundation/as3hx.git
cd as3hx
haxe --no-traces as3hx.hxml

# Convert a directory of AS3 files
neko run.n source_as3_dir/ output_haxe_dir/

# Convert a single file
neko run.n MyClass.as output/MyClass.hx
```

**Expected conversion rate**: ~70-80% automatic conversion. Remaining 20-30% requires manual fixes:
- Type system differences (dynamic types in AS3 vs static in Haxe)
- Flash-specific API calls (stage, root, display list)
- Event handling patterns
- Certain reflection features
- `*` (untyped) usage

#### Haxe + OpenFL Workflow

After converting with as3hx:

1. **Set up OpenFL project**: Install Haxe + OpenFL
2. **Copy converted code** into the OpenFL source directory
3. **Fix compilation errors** (as3hx produces valid but incomplete Haxe)
4. **Replace Flash API** with OpenFL equivalents:
   - `flash.display.MovieClip` → `openfl.display.MovieClip`
   - `flash.events.Event` → `openfl.events.Event`
   - Most Flash APIs have direct OpenFL equivalents
5. **Handle assets**: Copy extracted images/sounds to `assets/` directory
6. **Build for HTML5**: `openfl test html5`

**Pros**: Fastest path for AS3 games, cross-platform (HTML5 + native), familiar API for Flash developers.
**Cons**: Requires Haxe knowledge, some Flash features not supported in OpenFL HTML5 target.

### Option C: AI-Assisted Translation

Use LLM to assist with code translation when dealing with complex ActionScript:

1. **Extract all AS3 code** into individual files
2. **Create a context document** describing the game architecture
3. **Translate class by class**, providing the LLM with:
   - The full AS3 source code
   - A description of what the class does
   - The target language/framework (e.g., "TypeScript + Phaser.js")
   - Any dependencies or related classes

Best practices for AI translation:
- Translate utility/helper classes first (they have fewer dependencies)
- Provide the LLM with class relationships and interfaces
- Review output carefully - AI may "hallucinate" Flash APIs in JavaScript
- Test incrementally - don't wait until everything is "translated"

---

## Phase 4: Rebuild on Modern Framework

### Framework Selection Guide

| Target Framework | Best For | Difficulty | Display List Model | Audio |
|-----------------|----------|-----------|-------------------|-------|
| **CreateJS** (EaselJS) | Simple/medium games, timeline animations | Low | Flash-like hierarchy | SoundJS |
| **PixiJS** | Performance-critical 2D games | Medium | Scene graph | Howler.js |
| **Phaser** | Full-featured 2D games | Medium | Scene-based | Built-in |
| **Pixi.js + Phaser** | Complex 2D games | Medium-High | Scene + render | Built-in |
| **Three.js** | 2.5D / simple 3D conversions | High | Scene graph | Custom |
| **OpenFL/Haxe** | AS3 code preservation, cross-platform | Medium | Flash API clone | OpenAL |
| **Raw Canvas** | Simple games, learning | Medium | Manual | Web Audio API |

### Recommended: CreateJS for Flash-like Projects

CreateJS is the closest JavaScript equivalent to the Flash display list API:

```javascript
// Flash AS3                          → CreateJS JavaScript
var mc:MovieClip = new MovieClip();  → var mc = new createjs.MovieClip();
mc.x = 100;                          → mc.x = 100;
mc.addEventListener("click", fn);     → mc.on("click", fn);
stage.addChild(mc);                   → stage.addChild(mc);
createjs.Tween.get(mc).to({x:200}, 1000); // Like TweenLite in AS3
```

**CreateJS modules:**
- **EaselJS**: Display list, hit detection, caching (like Flash display API)
- **TweenJS**: Animation/tweening (like GreenSock/TweenLite)
- **SoundJS**: Audio playback (like Flash Sound class)
- **PreloadJS**: Asset preloading (like Flash Loader/URLLoader)

### Game Loop Pattern (AS3 → JS)

```javascript
// AS3 pattern:
// addEventListener(Event.ENTER_FRAME, update);

// Modern JS equivalent:
function gameLoop(timestamp) {
    var deltaTime = timestamp - lastTime;
    lastTime = timestamp;

    update(deltaTime);
    render();

    requestAnimationFrame(gameLoop);
}
requestAnimationFrame(gameLoop);
```

### Asset Loading Pattern

```javascript
// CreateJS PreloadJS loading (replaces AS3 Loader/URLLoader)
var queue = new createjs.LoadQueue();
queue.on("complete", handleComplete);
queue.loadManifest([
    { id: "player", src: "assets/player.png" },
    { id: "bg", src: "assets/background.jpg" },
    { id: "sfx_jump", src: "assets/jump.mp3" }
]);
```

---

## Phase 5: Testing & Validation

### Comparison Checklist

After rebuilding, compare the new version against the original:

1. **Visual fidelity**: Do all assets appear correctly? (position, size, scale, rotation)
2. **Animation timing**: Do tweens and frame animations play at the same speed?
3. **Game mechanics**: Does collision detection, physics, and scoring work identically?
4. **Audio**: Do all sound effects and music play at the right times?
5. **User input**: Does keyboard, mouse, and touch input respond correctly?
6. **State management**: Do game states (menu, play, pause, game over) transition correctly?
7. **Edge cases**: What happens at window resize, rapid input, or long play sessions?

### Using Ruffle for Reference Testing

[Ruffle](https://ruffle.rs/) is an open-source Flash emulator written in Rust that runs SWF files in the browser via WebAssembly. Use it to:
- Test the original SWF alongside your HTML5 rebuild
- Verify expected behavior when you don't have access to the original Flash Player
- Play through the game to document all behaviors before migration

---

## FLA/XFL Internal Structure Reference

### FLA File (CS4+)
FLA files are ZIP archives. Extract to see:
```
game.fla (ZIP contents):
├── DOMDocument.xml          # Main document: timeline, library references, publish settings
├── LIBRARY/
│   ├── Symbol_1.xml         # Each library symbol as XML
│   ├── Symbol_2.xml
│   └── ...
├── bin/
│   ├── Symbol_1.swf         # Compiled symbol data
│   └── ...
├── Settings.xml             # Publish settings (FPS, size, AS version)
└── MobileSettings.xml       # Mobile-specific settings (if applicable)
```

### DOMDocument.xml Structure (Key Elements)

```xml
<DOMDocument>
  <timeline>
    <DOMTimeline>
      <layers>
        <DOMLayer name="Actions" color="#...">       <!-- Script layer -->
          <frames>
            <DOMFrame index="0">
              <Actionscript>                         <!-- Frame scripts -->
                stop();
                gotoAndPlay("game");
              </Actionscript>
            </DOMFrame>
          </frames>
        </DOMLayer>
        <DOMLayer name="Graphics" color="#...">      <!-- Visual layer -->
          <frames>
            <DOMFrame index="0">
              <elements>
                <DOMSymbolInstance libraryItemName="Player">  <!-- Symbol placement -->
                  <matrix>...</matrix>
                  <transformationPoint>...</transformationPoint>
                </DOMSymbolInstance>
              </elements>
            </DOMFrame>
          </frames>
        </DOMLayer>
      </layers>
    </DOMTimeline>
  </timeline>
  <media>                                               <!-- Embedded media -->
    <DOMBitmapItem href="Library/image1.png"/>
    <DOMSoundItem href="Library/sound1.mp3"/>
  </media>
  <symbols>
    <DOMSymbolItem name="Player" linkageClassName="Player">  <!-- AS class binding -->
      ...
    </DOMSymbolItem>
  </symbols>
</DOMDocument>
```

### Key Information to Extract from DOMDocument.xml

1. **Frame rate**: `<DOMDocument framerate="30">`
2. **Stage size**: `<DOMDocument width="800" height="600">`
3. **ActionScript version**: `<DOMDocument asVersion="3">`
4. **Document class**: `<DOMDocument linkageBaseClass="..." >`
5. **Frame scripts**: Found in `<Actionscript>` tags within `<DOMFrame>` elements
6. **Symbol-to-class bindings**: `linkageClassName` attribute on `<DOMSymbolItem>`
7. **Layer structure**: `<DOMLayer>` elements with names, visibility, and lock states
8. **Animation keyframes**: Multiple `<DOMFrame>` elements with tween info
9. **Instance placements**: `<DOMSymbolInstance>` with position, scale, rotation

---

## Common Migration Pitfalls

| Issue | Description | Solution |
|-------|-------------|----------|
| **Missing frame scripts** | Code spread across timeline frames | Use JPEXS to extract all scripts; consolidate into a main game controller |
| **Hard-coded coordinates** | Positions relative to Flash stage | Recalculate for new canvas/container size |
| **AS2 timeline code** | `_root`, `_parent`, `this` references | Map to proper scope in target framework |
| **Flash filters** | DropShadow, Glow, Blur | Use CSS filters (canvas) or WebGL shaders |
| **Blend modes** | Flash-specific blend modes | Map to CSS `mix-blend-mode` or canvas `globalCompositeOperation` |
| **Masking** | Flash mask layers | Use canvas clipping paths or SVG masks |
| **9-slice scaling** | Flash 9-slice for UI | Use CSS `border-image` or custom 9-slice rendering |
| **Text rendering** | Anti-aliased Flash text | Use web fonts with appropriate rendering |
| **SharedObject** | Flash local storage | Migrate to `localStorage` or `IndexedDB` |
| **ExternalInterface** | Flash-JS bridge | Eliminate; replace with direct JS calls |
| **ByteArray** | Binary data manipulation | Use `DataView`, `ArrayBuffer`, or `Uint8Array` |
| **Socket/XMLSocket** | Network connections | Use WebSockets (`WebSocket` API) |
| **Camera/Microphone** | `getCamera()`, `getMicrophone()` | Use `getUserMedia()` API |

---

## Quick-Start Commands Summary

```bash
# 1. Extract everything from an SWF
java -jar ffdec.jar -export script,image,shape,sound,font,text "output/" game.swf

# 2. Export to XFL (editable XML format)
java -jar ffdec.jar -export xfl "output/xfl/" game.swf

# 3. Convert AS3 to Haxe (for OpenFL migration)
neko run.n source_as3/ output_haxe/

# 4. Inspect SWF structure
java -jar ffdec.jar -dumpSWF game.swf
java -jar ffdec.jar -dumpAS3 game.swf
java -jar ffdec.jar -dumpAS2 game.swf

# 5. Extract FLA (rename to zip and extract)
cp game.fla game.zip && unzip game.zip -d fla_extracted/
```

---

## Output Format

When completing a migration analysis or extraction, provide results in this structure:

### Extraction Report
```
## Flash Project: [name]
- **File**: [filename]
- **ActionScript Version**: AS2/AS3
- **Stage Size**: [WxH]
- **Frame Rate**: [fps] FPS
- **Main Timeline Frames**: [N]
- **Total Scripts/Classes**: [N]
- **Embedded Images**: [N]
- **Embedded Sounds**: [N]
- **Vector Shapes**: [N]
- **Fonts**: [N]
- **Estimated Complexity**: Simple/Medium/Complex/Very Complex
- **Recommended Migration Path**: [specific recommendation with rationale]
```

### Migration Plan
```
## Migration Plan: [name]
### Phase 1: Extraction
- [ ] Extract all assets using JPEXS FFDec
- [ ] Document class hierarchy and dependencies
- [ ] Catalog all timeline frame scripts

### Phase 2: Code Translation
- [ ] Translate utility classes to [target language]
- [ ] Translate game entity classes
- [ ] Translate game logic/state management
- [ ] Translate UI/input handling

### Phase 3: Rebuild
- [ ] Set up [framework] project
- [ ] Import converted assets
- [ ] Implement game loop
- [ ] Rebuild display hierarchy

### Phase 4: Validation
- [ ] Visual comparison with Ruffle
- [ ] Gameplay mechanics testing
- [ ] Audio verification
- [ ] Edge case testing
```
