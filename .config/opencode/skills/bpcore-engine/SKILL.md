---
name: bpcore-engine
description: Use when building GBA games with the BPCore Lua engine - entity, sprite and tilemap functions, SRAM save and load, link cable multiplayer protocol, camera and scrolling, or optimization patterns
metadata:
  author: mte90
  version: 2.0.1
  tags:
    - lua
    - gba
    - game-engine
    - gameboy-advance
---

# BPCore Engine Skill

Comprehensive guide for building Gameboy Advance games using the BPCore Engine Lua framework.

## Overview

BPCore Engine (Blind jumP Core Engine) is a Lua game framework for GBA that combines C++ with embedded Lua, letting developers create games without C++ or compilers. Inspired by Pico-8 and Tic80, it's suited for small minigames given the GBA's limited resources: 240x160 screen, 16.78 MHz ARM7TDMI, and 256KB RAM for Lua/data.

The engine provides sprite rendering, tile-based graphics, entity management with collision, button input, UTF-8 text, audio, save/load via SRAM, and multiplayer through the link cable. The build system uses Lua to package resources into ROM.

## API Reference

### Entity Functions

| Function | Description |
|----------|-------------|
| `ent()` | Create entity, returns handle |
| `entpos(e, x, y)` | Set position, returns self |
| `entz(e, z)` | Set Z-order (0-255), returns self |
| `entspr(e, sprite, xflip, yflip)` | Set sprite and flips, returns self |
| `entspd(e, x, y)` | Set movement speed, returns self |
| `entslot(e, slot, value)` | Store in slot, returns self |
| `entslots(e, count)` | Allocate slots, returns self |
| `entanim(e, start, len, rate)` | Set animation |
| `entag(e, tag)` | Set collision tag, returns self |
| `enthb(e, ox, oy, w, h)` | Set hitbox, returns self |
| `del(e, [auto])` | Delete entity |
| `ents()` | Get all entities table |
| `enthb(e)` | Get hitbox (getter form) |

### Sprite & Tile Functions

| Function | Description |
|----------|-------------|
| `txtr(layer_id, filename)` | Load texture from file |
| `txtr(layer_id, ptr, len)` | Load from pointer/length |
| `file(filename)` | Get file pointer/length |
| `spr(sprite_id, x, y)` | Draw sprite |
| `spr(sprite_id, x, y, xflip, yflip)` | Draw with flips |
| `tile(layer_id, x, y, [num])` | Draw/read tile |
| `tilemap(f, layer, w, h, dx, dy, sx, sy)` | Load CSV tilemap |
| `clear()` | Clear sprites, VSync |
| `display()` | Send sprites to display |
| `fade(amount, [color], [tl], [bg])` | Fade layers |

### Camera & Scroll

| Function | Description |
|----------|-------------|
| `camera(x, y)` | Set camera center |
| `scroll(layer, x, y)` | Set layer scroll |
| `priority(s, bg, t0, t1)` | Set render priority |

### Collision

| Function | Description |
|----------|-------------|
| `ecolle(e1, e2)` | Check collision (bool) |
| `ecoll(e, tag)` | Find tag matches (array) |

### Input

| Function | Description |
|----------|-------------|
| `btn(num)` | Button held? (bool) |
| `btnp(num)` | Button pressed? (bool) |
| `btnnp(num)` | Button released? (bool) |

### Graphics

| Function | Description |
|----------|-------------|
| `print(text, x, y, [fg], [bg])` | Print to overlay |

### Audio

| Function | Description |
|----------|-------------|
| `music(f, [offset])` | Play background music |
| `sound(f, priority)` | Play sound effect |

### Memory

| Function | Description |
|----------|-------------|
| `poke(addr, value)` | Write byte |
| `poke4(addr, value)` | Write 32-bit word |
| `peek(addr)` | Read byte |
| `peek4(addr)` | Read 32-bit word |
| `memput(addr, data)` | Write to memory |
| `memget(addr, [len])` | Read from memory |

### System

| Function | Description |
|----------|-------------|
| `delta()` | Microseconds since last call |
| `sleep(frames)` | Sleep N frames |
| `startup_time()` | Get boot time |
| `fdog()` | Feed watchdog timer |
| `log(msg)` | Debug log |
| `rline()` | Get raster line |
| `flimit(fps)` | Set frame rate limit |
| `next_script(filename)` | Switch Lua script |

### Multiplayer

| Function | Description |
|----------|-------------|
| `connect(timeout)` | Connect (blocking) |
| `disconnect()` | Disconnect |
| `send(data)` | Send message (max 11 bytes) |
| `recv()` | Receive message |
| `send_iram(ptr)` | Send from IRAM |
| `recv_iram(ptr)` | Receive to IRAM |

### Layer IDs

| ID | Layer | Size | Description |
|----|-------|------|-------------|
| 0 | Overlay | 32x32 tiles | Front, persistent |
| 1 | Tile Layer 1 | 64x64 tiles | Behind sprites, in front of tile_0 |
| 2 | Tile Layer 0 | 64x64 tiles | Main background |
| 3 | Background | 32x32 tiles | Back layer |
| 4 | Sprites | Dynamic | On-top sprites |

## Installation & Project Structure

### Getting BPCoreEngine.gba

**Important**: BPCore Engine requires `BPCoreEngine.gba` base ROM with compiled C++ code and Lua interpreter. This is **not** a custom ROM you create.

1. **Official Repository**: clone from [GitHub](https://github.com/evanbowman/BPCore-Engine) — `git clone https://github.com/evanbowman/BPCore-Engine.git`
2. **Required Files**: `BPCoreEngine.gba` (engine base ROM, ~3.5 MB), `build.lua` (build script, Lua 5.3), `test/` example projects.
3. **Alternatives**: GitHub Releases may have pre-built GBA files; mGBA includes a BPCore version in some distributions.

### File Placement

```
your-project/
├── BPCoreEngine.gba          # Base ROM (required)
├── build.lua                  # Build script
├── manifest.lua               # Your manifest
├── overlay.bmp                # Text/UI tiles
├── tile0.bmp                  # Main background (64x64 tiles)
├── tile1.bmp                  # Foreground (64x64 tiles)
├── spritesheet.bmp           # Sprites
├── music.raw                  # Music (mono 16kHz PCM)
├── sfx.wav                    # Sound effects
├── main.lua                   # Entry point
└── data.txt                   # Resources
```

### Build Layout

```
./
├── src/            # main.lua, game.lua, menu.lua, level1.csv (tilemaps)
├── assets/
│   ├── graphics/   # spritesheet.bmp, tiles0.bmp, tiles1.bmp
│   ├── audio/      # music.raw, jump.wav, coin.wav
│   └── tilemaps/   # world.csv
├── build.lua
├── BPCoreEngine.gba
└── dist/yourgame.gba
```

### Building Your ROM

**Step 1** — `manifest.lua`:

```lua
local app = {
    name = "My Adventure",
    gamecode = "ABCD",
    makercode = "BC",
    tilesets = { "overlay.bmp", "tile0.bmp", "tile1.bmp" },
    spritesheets = { "spritesheet.bmp" },
    audio = { "music.raw", "jump.wav", "coin.wav" },
    scripts = { "main.lua", "game.lua", "menu.lua" },
    misc = { "level1.csv" }
}
return app
```

**Step 2** — build: `lua build.lua manifest.lua BPCoreEngine.gba output.gba`

**Step 3** — verify: build checks manifest files exist, formats valid, scripts readable, output ROM created (~3.5-4 MB).

**Step 4** — test in mGBA (see the mgba skill for scripting-driven verification of the built ROM).

### File Formats

- **BMP tilesets**: indexed color (256 colors), tiles 8x8 px. Overlay: 16x16 tiles, Tile_0/1: 32x32 tiles, Sprites: 8x8.
- **Audio**: mono 16kHz signed 8-bit PCM. Convert: `ffmpeg -i input.mp3 -ar 16000 -ac 1 -f s8 output.raw`
- **Tilemap CSV**: comma-separated tile indices, one tile row per line, indices start at 1 (0 = empty).

## Deep Dives

Complex topics live in reference files, loaded on demand:

- **Save/Load to SRAM** — persistent storage patterns, checksums, marker bytes → [references/save-load.md](references/save-load.md)
- **Multiplayer Link Cable Protocol** — packet formats, binary I/O, client-server sync → [references/multiplayer.md](references/multiplayer.md)
- **Optimization & Camera** — sprite batching, entity pools, parallax scrolling → [references/optimization.md](references/optimization.md)
- **Error Handling** — bounds checking, validation patterns → [references/error-handling.md](references/error-handling.md)

## Best Practices

- **Sprite/tilemap memory**: pre-allocate entity pools; batch stationary sprites; minimal tile updates per frame.
- **SRAM limits (32KB)**: compact save structure, checksums for corruption detection, validate before loading.
- **Fixed-point math**: GBA has no FPU — multiply by 256 for 8.8 format; avoid division.
- **Bounded entity loops**: process only active entities; spatial partitioning for collisions; cap at 128 entities.
- **Link cable**: packets under 11 bytes; drain `recv()` in a loop; handle disconnects gracefully.

## Troubleshooting

- **Emulator vs hardware**: mGBA is accurate but timing may differ; verify on real hardware before shipping.
- **Sprite flickering**: 128 sprite slots but only ~10 visible per scanline — distribute sprites vertically.
- **Audio channel conflicts**: 3 sound channels + 1 music; use the `priority` parameter.
- **Save corruption**: always write checksums; verify the marker byte (0x42) before loading; atomic writes (temp, then commit).

## References

- [BPCore Engine GitHub Repository](https://github.com/evanbowman/BPCore-Engine)
- [GBA Hardware Specifications](https://problemkaputt.de/gbatek.htm)
- [Tonc GBA Tutorial](https://www.coranac.com/tonc/text/)
- [GBA Programming Wiki](https://gbadev.net/)
- [mGBA Emulator](https://mgba.io/)
