---
name: bpcore-engine
description: Use when building GBA games with the BPCore Lua engine - entity, sprite and tilemap functions, SRAM save and load, link cable multiplayer protocol, camera and scrolling, or optimization patterns
metadata:
  author: mte90
  version: 2.0.0
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

| Function | Signature | Description |
|----------|-----------|-------------|
| `ent()` | `ent()` | Create entity, returns handle |
| `entpos(e, x, y)` | `entpos(e, x, y)` | Set position, returns self |
| `entz(e, z)` | `entz(e, z)` | Set Z-order (0-255), returns self |
| `entspr(e, sprite, xflip, yflip)` | `entspr(e, sprite, xflip, yflip)` | Set sprite and flips, returns self |
| `entspd(e, x, y)` | `entspd(e, x, y)` | Set movement speed, returns self |
| `entslot(e, slot, value)` | `entslot(e, slot, value)` | Store in slot, returns self |
| `entslots(e, count)` | `entslots(e, count)` | Allocate slots, returns self |
| `entanim(e, start, len, rate)` | `entanim(e, start, len, rate)` | Set animation |
| `entag(e, tag)` | `entag(e, tag)` | Set collision tag, returns self |
| `enthb(e, ox, oy, w, h)` | `enthb(e, ox, oy, w, h)` | Set hitbox, returns self |
| `del(e, auto?)` | `del(e, [auto])` | Delete entity |
| `ents()` | `ents()` | Get all entities table |

### Sprite & Tile Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `txtr(layer_id, filename)` | `txtr(layer_id, filename)` | Load texture from file |
| `txtr(layer_id, ptr, len)` | `txtr(layer_id, ptr, len)` | Load from pointer/length |
| `file(filename)` | `file(filename)` | Get file pointer/length |
| `spr(sprite_id, x, y)` | `spr(sprite_id, x, y)` | Draw sprite |
| `spr(sprite_id, x, y, xflip, yflip)` | `spr(sprite_id, x, y, xflip, yflip)` | Draw with flips |
| `tile(layer_id, x, y, num?)` | `tile(layer_id, x, y, [num])` | Draw/read tile |
| `tilemap(f, layer, w, h, dx, dy, sx, sy)` | `tilemap(f, layer, w, h, dx, dy, sx, sy)` | Load CSV tilemap |
| `clear()` | `clear()` | Clear sprites, VSync |
| `display()` | `display()` | Send sprites to display |
| `fade(amount, color?, tl?, bg?)` | `fade(amount, [color], [tl], [bg])` | Fade layers |

### Camera & Scroll

| Function | Signature | Description |
|----------|-----------|-------------|
| `camera(x, y)` | `camera(x, y)` | Set camera center |
| `scroll(layer, x, y)` | `scroll(layer, x, y)` | Set layer scroll |
| `priority(s, bg, t0, t1)` | `priority(s, bg, t0, t1)` | Set render priority |

### Collision

| Function | Signature | Description |
|----------|-----------|-------------|
| `ecolle(e1, e2)` | `ecolle(e1, e2)` | Check collision (bool) |
| `ecoll(e, tag)` | `ecoll(e, tag)` | Find tag matches (array) |
| `enthb(e)` | `enthb(e)` | Get hitbox (getter) |

### Input

| Function | Signature | Description |
|----------|-----------|-------------|
| `btn(num)` | `btn(num)` | Button held? (bool) |
| `btnp(num)` | `btnp(num)` | Button pressed? (bool) |
| `btnnp(num)` | `btnnp(num)` | Button released? (bool) |

### Graphics

| Function | Signature | Description |
|----------|-----------|-------------|
| `print(text, x, y, fg?, bg?)` | `print(text, x, y, [fg], [bg])` | Print to overlay |

### Audio

| Function | Signature | Description |
|----------|-----------|-------------|
| `music(f, offset?)` | `music(f, [offset])` | Play background music |
| `sound(f, priority)` | `sound(f, priority)` | Play sound effect |

### Memory

| Function | Signature | Description |
|----------|-----------|-------------|
| `poke(addr, value)` | `poke(addr, value)` | Write byte |
| `poke4(addr, value)` | `poke4(addr, value)` | Write 32-bit word |
| `peek(addr)` | `peek(addr)` | Read byte |
| `peek4(addr)` | `peek4(addr)` | Read 32-bit word |
| `memput(addr, data)` | `memput(addr, data)` | Write to memory |
| `memget(addr, len?)` | `memget(addr, [len])` | Read from memory |

### System

| Function | Signature | Description |
|----------|-----------|-------------|
| `delta()` | `delta()` | Microseconds since last call |
| `sleep(frames)` | `sleep(frames)` | Sleep N frames |
| `startup_time()` | `startup_time()` | Get boot time |
| `fdog()` | `fdog()` | Feed watchdog timer |
| `log(msg)` | `log(msg)` | Debug log |
| `rline()` | `rline()` | Get raster line |
| `flimit(fps)` | `flimit(fps)` | Set frame rate limit |
| `next_script(filename)` | `next_script(filename)` | Switch Lua script |

### Multiplayer

| Function | Signature | Description |
|----------|-----------|-------------|
| `connect(timeout)` | `connect(timeout)` | Connect (blocking) |
| `disconnect()` | `disconnect()` | Disconnect |
| `send(data)` | `send(data)` | Send message (max 11 bytes) |
| `recv()` | `recv()` | Receive message |
| `send_iram(ptr)` | `send_iram(ptr)` | Send from IRAM |
| `recv_iram(ptr)` | `recv_iram(ptr)` | Receive to IRAM |

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

#### Where to Obtain

1. **Official Repository**: Clone from [GitHub](https://github.com/evanbowman/BPCore-Engine)
   ```bash
   git clone https://github.com/evanbowman/BPCore-Engine.git
   cd BPCore-Engine
   ```

2. **Required Files**: Repository contains:
   - `BPCoreEngine.gba` - Engine base ROM (~3.5 MB)
   - `build.lua` - Build script (Lua 5.3)
   - `test/` - Example projects

3. **Alternatives**:
   - GitHub Releases may have pre-built GBA files
   - mGBA emulator includes BPCore version in some distributions

#### File Placement

```
your-project/
├── BPCoreEngine.gba          # Base ROM (required)
├── build.lua                  # Build script
├── manifest.lua               # Your manifest
├── overlay.bmp                # Text/UI tiles
├── tile0.bmp                  # Main background (64x64 tiles)
├── tile1.bmp                  # Foreground (64x64 tiles)
├── spritesheet.bmp           # Sprites (16x16)
├── music.raw                  # Music (mono 16kHz PCM)
├── sfx.wav                    # Sound effects
├── main.lua                   # Entry point
└── data.txt                   # Resources
```

### Build Layout

```
./
├── src/
│   ├── main.lua              # Main loop
│   ├── game.lua              # Game logic
│   ├── menu.lua              # Menu
│   └── level1.csv            # Tilemap
├── assets/
│   ├── graphics/
│   │   ├── spritesheet.bmp
│   │   ├── tiles0.bmp
│   │   └── tiles1.bmp
│   ├── audio/
│   │   ├── music.raw
│   │   ├── jump.wav
│   │   └── coin.wav
│   └── tilemaps/
│       └── world.csv
├── build.lua                 # Build script
├── BPCoreEngine.gba          # Engine ROM
└── dist/
    └── yourgame.gba          # Output
```

### Building Your ROM

**Step 1**: Create `manifest.lua`

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

**Step 2**: Run build script

```bash
lua build.lua manifest.lua BPCoreEngine.gba output.gba
```

**Step 3**: Verify

Build checks manifest files exist, formats are valid, scripts readable, output ROM created (~3.5-4 MB).

**Step 4**: Test with mGBA

```bash
mGBA output.gba --log --memview
```

`--log` shows engine log() output, `--memview` opens memory viewer for debugging.

### File Formats

**BMP Tilesets**: Indexed color (256 colors), tiles are 8x8 pixels. Overlay: 16x16 tiles, Tile_0/1: 32x32 tiles, Sprites: 8x8 sprites.

**Audio**: Mono 16kHz signed 8-bit PCM. Convert with FFmpeg:
```bash
ffmpeg -i input.mp3 -ar 16000 -ac 1 -f s8 output.raw
```

**Tilemap CSV**: Comma-separated tile indices, each row is one tile row. Tile indices start at 1 (0 = empty).

## Deep Dives

Complex topics are split into reference files loaded on demand from `../SKILL.md`:

- **Save/Load to SRAM** — Persistent storage patterns, checksums, marker bytes → [`references/save-load.md`](references/save-load.md)
- **Multiplayer Link Cable Protocol** — Packet formats, binary I/O, client-server sync → [`references/multiplayer.md`](references/multiplayer.md)
- **Optimization & Camera** — Sprite batching, entity pools, parallax scrolling → [`references/optimization.md`](references/optimization.md)
- **Error Handling** — Bounds checking, validation patterns → [`references/error-handling.md`](references/error-handling.md)

## Best Practices

- **Memory management for sprites/tilemaps**: Pre-allocate entity pools to avoid runtime allocation; batch stationary sprites to reduce redraw calls; keep tile updates minimal per frame.
- **Managing SRAM save limits**: SRAM is only 32KB—structure save data compactly; use checksums for corruption detection; validate save data before loading.
- **Fixed-point math for GBA hardware**: GBA lacks FPU—use fixed-point arithmetic (e.g., multiply by 256 for 8.8 format); avoid division where possible.
- **Keeping entity update loops bounded**: Process only active entities; use spatial partitioning for collision checks; cap entity count at 128.
- **Using the link cable protocol carefully**: Keep packets under 11 bytes; process recv() in a loop to clear queue; handle disconnects gracefully.

## Troubleshooting

- **Emulator vs hardware differences**: mGBA is accurate but timing may differ; test on real hardware for final verification.
- **Sprite flickering (too many sprites per scanline)**: GBA has 128 sprite slots but only ~10 visible per scanline; distribute sprites vertically.
- **Audio channel conflicts**: Only 3 sound channels + 1 music; prioritize important sounds using the priority parameter.
- **Save data corruption**: Always write checksums; verify marker byte (0x42) before loading; use atomic writes (write to temp, then commit).

## References

- [BPCore Engine GitHub Repository](https://github.com/evanbowman/BPCore-Engine)
- [GBA Hardware Specifications](https://problemkaputt.de/gbatek.htm)
- [Tonc GBA Tutorial](https://www.coranac.com/tonc/text/)
- [GBA Programming Wiki](https://gbadev.net/)
- [mGBA Emulator](https://mgba.io/)

---

## Summary

This skill covers BPCore Engine development for GBA:

- **API Reference**: 60+ functions with signatures
- **Installation & Project Structure**: BPCoreEngine.gba sources, build process
- **Save/Load to SRAM**: Persistent storage patterns
- **Multiplayer Link Cable Protocol**: Packet formats, binary I/O
- **Optimization Patterns**: Sprite batching, entity pools, audio mixing, state machines
- **Camera & Scrolling**: Parallax, bounds
- **Error Handling**: Validation, safe operations

Refer to [official repository](https://github.com/evanbowman/BPCore-Engine) for updates.