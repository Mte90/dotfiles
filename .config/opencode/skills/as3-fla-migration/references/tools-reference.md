# Alternative Tools & Approaches Reference

## Ruffle - Flash Emulator (Run SWF in Browser)

### Overview
Ruffle is an open-source Flash Player emulator written in Rust that compiles to WebAssembly. It can run SWF files directly in modern browsers without any plugins.

### When to Use Ruffle
- Quick testing of original SWF behavior during migration
- Preserving Flash games that can't be fully ported
- Verifying game mechanics and visual fidelity against the original
- Situations where a full code migration isn't cost-effective

### Compatibility
- AS1/AS2: Good support (~80%+)
- AS3: Partial support (~60-70%, actively improving)
- Vector graphics: Excellent
- Audio: Good (MP3, WAV, ADPCM)
- Video: Limited
- ActionScript features: Most core features supported; advanced features (sockets, ByteArray operations, some filters) may not work

### Usage
```html
<!-- Embed Ruffle in a webpage -->
<script src="ruffle/ruffle.js"></script>
<div>
    <embed src="game.swf" type="application/x-shockwave-flash">
</div>
```

Ruffle auto-detects Flash embeds and replaces them. Alternatively:
```javascript
// Load SWF dynamically
const ruffle = window.RufflePlayer.newest();
const player = ruffle.createPlayer();
container.appendChild(player);
player.load("game.swf");
```

### Links
- Website: https://ruffle.rs/
- GitHub: https://github.com/ruffle-rs/ruffle
- Compatibility tracker: https://ruffle.rs/wiki/Compatibility

---

## Adobe Animate CC - FLA to HTML5 Canvas

### Overview
Adobe Animate CC (formerly Flash Professional) can open FLA files and convert them to HTML5 Canvas format using CreateJS.

### Workflow
1. Open `.fla` file in Adobe Animate CC
2. **File → Convert To → HTML5 Canvas**
3. Review conversion warnings (some features may not convert)
4. **File → Publish Settings** → configure output
5. **File → Publish** → generates HTML + JS + assets

### What Converts Well
- Timeline animations (tweens, keyframes)
- Shape animations
- Simple button interactions
- Frame labels and navigation
- Audio sync with timeline

### What Doesn't Convert Well
- Complex ActionScript (AS3 code needs manual conversion)
- Custom components
- Advanced filters and blend modes
- 3D transforms
- Video playback
- External data loading

### Output
Generates a CreateJS-based HTML5 Canvas project with:
- `index.html` - Host page
- `*.js` - CreateJS animation code
- `images/` - Exported image assets
- `sounds/` - Exported audio assets

### Cost
- Adobe Creative Cloud subscription required
- Not suitable for batch processing or automation

---

## Haxe + OpenFL Migration Path

### Overview
Haxe is a programming language originally created as a successor to ActionScript 2. OpenFL is an open-source implementation of the Flash API for Haxe, enabling cross-platform deployment.

### When to Choose This Path
- You have AS3 source code that can be converted with as3hx
- You need cross-platform targets (HTML5 + native desktop/mobile)
- The game's architecture closely follows Flash patterns
- You want the fastest migration from AS3 to working code

### Setup
```bash
# Install Haxe (via installer or package manager)
# macOS: brew install haxe
# Ubuntu: apt install haxe
# Or download from https://haxe.org/download/

# Install OpenFL
haxelib install openfl
haxelib install lime
haxelib setup openfl

# Create a new OpenFL project
openfl create project MyGame
cd MyGame

# Test HTML5 build
openfl test html5
```

### AS3 → Haxe with as3hx

```bash
# Install as3hx
git clone https://github.com/HaxeFoundation/as3hx.git
cd as3hx
haxe --no-traces as3hx.hxml

# Convert entire AS3 source tree
neko run.n /path/to/as3/source/ /path/to/haxe/output/

# Convert single file
neko run.n Player.as output/Player.hx
```

### Conversion Rate & Common Issues
- **Automatic conversion**: ~70-80% of code
- **Manual fixes needed for**:
  - Flash-specific types (Point, Rectangle → use openfl.geom.*)
  - Dynamic typing (`*` type) → add explicit types
  - `getTimer()` → `openfl.Lib.getTimer()`
  - `flash.net.*` classes → check OpenFL equivalents
  - Some reflection features
  - Metadata attributes
  - `default xml namespace`

### Flash API → OpenFL API Mapping
| Flash (AS3) | OpenFL (Haxe) |
|------------|--------------|
| `flash.display.Sprite` | `openfl.display.Sprite` |
| `flash.display.MovieClip` | `openfl.display.MovieClip` |
| `flash.display.Bitmap` | `openfl.display.Bitmap` |
| `flash.display.BitmapData` | `openfl.display.BitmapData` |
| `flash.events.Event` | `openfl.events.Event` |
| `flash.geom.Point` | `openfl.geom.Point` |
| `flash.geom.Rectangle` | `openfl.geom.Rectangle` |
| `flash.geom.Matrix` | `openfl.geom.Matrix` |
| `flash.net.URLLoader` | `openfl.net.URLLoader` |
| `flash.net.SharedObject` | `openfl.net.SharedObject` |
| `flash.media.Sound` | `openfl.media.Sound` |
| `flash.utils.Timer` | `openfl.utils.Timer` |
| `flash.Lib.getTimer()` | `openfl.Lib.getTimer()` |
| `flash.Lib.current.stage` | `openfl.Lib.current.stage` |

### Pros
- Fastest migration path for AS3 codebases
- True cross-platform (HTML5, Windows, macOS, Linux, iOS, Android)
- Flash API familiarity for AS3 developers
- Strong type system catches many bugs

### Cons
- Haxe has a smaller community than JS/TS
- Some Flash features not available on HTML5 target
- Debugging HTML5 target can be challenging
- Learning curve if team doesn't know Haxe

---

## CreateJS - Flash-like JavaScript Library

### Overview
CreateJS is a suite of JavaScript libraries maintained by CreateJS (supported by Adobe, Microsoft, Mozilla). It provides the closest equivalent to Flash's display list and animation APIs.

### Modules

#### EaselJS - Display List
```javascript
// Stage (like Flash stage)
var stage = new createjs.Stage("canvasElement");

// Container (like Sprite)
var container = new createjs.Container();
stage.addChild(container);

// Shape (like flash.display.Shape)
var shape = new createjs.Shape();
shape.graphics.beginFill("#FF0000").drawCircle(0, 0, 50);
container.addChild(shape);

// Bitmap
var bmp = new createjs.Bitmap("image.png");
stage.addChild(bmp);

// Text
var txt = new createjs.Text("Score: 100", "bold 24px Arial", "#FFF");
txt.x = 10; txt.y = 10;
stage.addChild(txt);

// Sprite (animated)
var spriteSheet = new createjs.SpriteSheet({
    images: ["spritesheet.png"],
    frames: { width: 64, height: 64, count: 8 },
    animations: {
        walk: [0, 3, "walk", 0.1],
        jump: [4, 7, "walk", 0.1]
    }
});
var player = new createjs.Sprite(spriteSheet, "walk");
stage.addChild(player);

// Update stage (like ENTER_FRAME)
createjs.Ticker.framerate = 30;
createjs.Ticker.addEventListener("tick", stage);
```

#### TweenJS - Animation
```javascript
// Simple tween
createjs.Tween.get(target)
    .to({ x: 300, y: 200 }, 1000, createjs.Ease.quadOut)
    .call(onComplete);

// Chained tweens
createjs.Tween.get(player)
    .to({ x: 400 }, 500, createjs.Ease.linear)
    .to({ y: 300 }, 500, createjs.Ease.bounceOut)
    .wait(100)
    .to({ alpha: 0 }, 300);

// Easing functions (equivalent to Flash easing)
createjs.Ease.linear
createjs.Ease.quadIn / quadOut / quadInOut
createjs.Ease.cubicIn / cubicOut / cubicInOut
createjs.Ease.quartIn / quartOut / quartInOut
createjs.Ease.elasticIn / elasticOut / elasticInOut
createjs.Ease.bounceIn / bounceOut / bounceInOut
createjs.Ease.backIn / backOut / backInOut
```

#### SoundJS - Audio
```javascript
// Register sounds
createjs.Sound.alternateExtensions = { "mp3": ["ogg"] };
createjs.Sound.registerSound("sfx/jump.mp3", "jump");
createjs.Sound.registerSound("sfx/hit.mp3", "hit");
createjs.Sound.registerSound("music/bgm.mp3", "bgm");

// Play
var jumpSound = createjs.Sound.play("jump", { volume: 0.7 });
var bgm = createjs.Sound.play("bgm", { loop: -1, volume: 0.5 });

// Control
bgm.volume = 0.3;
bgm.stop();
```

#### PreloadJS - Asset Loading
```javascript
var queue = new createjs.LoadQueue();
queue.installPlugin(createjs.Sound);

queue.on("complete", handleComplete);
queue.loadManifest([
    { id: "player", src: "images/player.png" },
    { id: "enemy", src: "images/enemy.png" },
    { id: "bg", src: "images/background.jpg" },
    { id: "jump", src: "sfx/jump.mp3" },
    { id: "bgm", src: "music/bgm.mp3" }
]);

function handleComplete(event) {
    var playerImg = queue.getResult("player");
    var jumpSfx = queue.getResult("jump");
    // ... start game
}
```

### CDN Links
```html
<script src="https://code.createjs.com/1.0.0/createjs.min.js"></script>
```

---

## Other Tools (Historical Reference)

### Discontinued / Deprecated
| Tool | Status | Notes |
|------|--------|-------|
| **Google Swiffy** | Discontinued 2016 | Was a Flash→HTML5 converter |
| **Mozilla Shumway** | Discontinued 2015 | JS-based Flash runtime |
| **Adobe Wallaby** | Discontinued 2012 | Flash→HTML5 converter for animations |
| **Lightspark** | Abandoned | Native Flash player alternative |
| **Apache FlexJS** | Rebranded to Royale | AS3→JS transpiler (limited) |

### Commercial Tools
| Tool | Status | Notes |
|------|--------|-------|
| **Sothink SWF Decompiler** | Active | Commercial ($80+), SWF→FLA decompiler |
| **Eltima Flash Decompiler** | Active | Commercial ($80+), SWF→FLA converter |
| **JPEXS FFDec** | **Free/Open Source** | Recommended: best open-source option |

### AI-Assisted Migration
LLMs (like the one powering this skill) can assist with:
- Understanding complex ActionScript code
- Translating AS3 to JavaScript/TypeScript/Haxe
- Explaining Flash-specific patterns and their modern equivalents
- Generating boilerplate code for the target framework
- Debugging migration issues by comparing AS3 and translated code
