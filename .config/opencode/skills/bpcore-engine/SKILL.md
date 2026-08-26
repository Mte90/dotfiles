---
name: bpcore-engine
description: "Lua game framework for Gameboy Advance with sprites, tilemaps, entities, collision, audio, multiplayer"
metadata:
  author: mte90
  version: "1.0.0"
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

## Save/Load to SRAM

### SRAM Overview

GBA provides **32KB SRAM** that persists across restarts, unlike volatile IRAM (8KB).

```
SRAM: 32KB
├── Offset 0x00: Save data
├── Offset 0xFF: Save marker
└── Offset 0x00-0xFF: Checksum
```

### Basic Save/Load

```lua
function save_game()
    local offset = 0
    
    poke4(_SRAM + offset, player_x); offset = offset + 4
    poke4(_SRAM + offset, player_y); offset = offset + 4
    poke4(_SRAM + offset, player_health); offset = offset + 4
    poke4(_SRAM + offset, player_score); offset = offset + 4
    poke(_SRAM + offset, current_level); offset = offset + 1
    poke(_SRAM + 31999, 0x42)  -- Save marker
    
    print("Saved!", 1, 1, 0xFFFF)
end

function load_game()
    if peek(_SRAM + 31999) ~= 0x42 then
        return false
    end
    
    player_x = peek4(_SRAM); offset = offset + 4
    player_y = peek4(_SRAM); offset = offset + 4
    player_health = peek4(_SRAM); offset = offset + 4
    player_score = peek4(_SRAM); offset = offset + 4
    current_level = peek(_SRAM)
    
    print("Loaded!", 1, 1, 0xFFFF)
    return true
end
```

### Structured Save Class

```lua
SaveGame = {}
SaveGame.__index = SaveGame

function SaveGame:new()
    local self = setmetatable({}, SaveGame)
    self.created = false
    return self
end

function SaveGame:create()
    if peek(_SRAM + 31999) ~= 0x42 then
        poke4(_SRAM, 1)  -- version
        poke4(_SRAM + 4, 1)  -- created
        poke4(_SRAM + 8, 0)  -- packed
        
        self.player = {x = 120, y = 80, health = 100, score = 0, lives = 3}
        poke4(_SRAM + 12, self.player.x)
        poke4(_SRAM + 16, self.player.y)
        poke4(_SRAM + 20, self.player.health)
        poke4(_SRAM + 24, self.player.score)
        poke(_SRAM + 28, self.player.lives)
        
        poke(_SRAM + 31999, 0x42)
        self.created = true
    end
end

function SaveGame:save()
    poke(_SRAM, self.player.x)
    poke(_SRAM + 4, self.player.y)
    poke(_SRAM + 8, self.player.health)
    poke(_SRAM + 12, self.player.score)
    poke(_SRAM + 16, self.player.lives)
end

function SaveGame:load()
    if not self.created then return false end
    
    self.player.x = peek(_SRAM)
    self.player.y = peek(_SRAM + 4)
    self.player.health = peek(_SRAM + 8)
    self.player.score = peek(_SRAM + 12)
    self.player.lives = peek(_SRAM + 16)
    
    return true
end
```

## Multiplayer Link Cable Protocol

### Hardware

Two GBA systems connect via link cable on right side of cartridge.

### Communication

```
Device 1                      Device 2
┌─────────────┐             ┌─────────────┐
│  SEND QUEUE │ ←──→  │  SEND QUEUE      │
│    (32pk)   │    ←──→   │    (32pk)     │
└─────────────┘             └─────────────┘
│  REC QUEUE  │    ←──→   │  REC QUEUE    │
│    (64pk)   │             │    (64pk)   │
└─────────────┘             └─────────────┘
```

**Limits**: 64 receive packets, 32 send packets per device. Overflow causes loss.

### Packet Format

```
[Sender ID (1 byte)][Data (up to 10 bytes)]
[Total: 11 bytes max]

Examples:
  "1HELLO" = Player 1 sent
  "2WORLD" = Player 2 sent
```

### Connection Management

```lua
local connected = connect(10)  -- 10 second timeout

if connected then
    print("Connected!", 10, 10)
else
    print("Failed", 10, 10)
end

disconnect()  -- Clean up when done
```

`connect()` is blocking. Calling it while connected auto-disconnects first.

### Sending & Receiving

```lua
-- Send (max 11 bytes including sender ID)
send("hello")
send("P1:MOVE:10,20")
send(string.char(1, 2, 3, 4))

-- Receive
local packet = recv()
while packet do
    local sender = string.sub(packet, 1, 1)
    local data = string.sub(packet, 2)
    
    if sender == "1" then
        -- From player 1
    elseif sender == "2" then
        -- From player 2
    end
    
    packet = recv()
end
```

### Basic Example

```lua
local my_x, my_y = 120, 80
local opp_x, opp_y = 0, 0

function update_network()
    send(string.char(my_x) .. string.char(my_y))
    
    local pkt = recv()
    while pkt do
        opp_x = string.byte(pkt, 2)
        opp_y = string.byte(pkt, 3)
        pkt = recv()
    end
end

function draw_network()
    spr(1, opp_x, opp_y)
    spr(0, my_x, my_y)
end
```

### Binary I/O (Fast)

```lua
function sync_position_fast()
    poke(_IRAM, my_x)
    poke(_IRAM + 1, my_y)
    poke(_IRAM + 2, my_score)
    send_iram(_IRAM)
    
    if recv_iram(_IRAM) then
        opp_x = peek(_IRAM)
        opp_y = peek(_IRAM + 1)
        opp_score = peek(_IRAM + 2)
    end
end
```

### Synchronization

#### Client-Server Model

```lua
local last_sent_x, last_sent_y = 0, 0

function update_gameplay()
    if btn(4) then my_x = my_x - speed end
    if btn(5) then my_x = my_x + speed end
    
    if last_sent_x ~= my_x or last_sent_y ~= my_y then
        send(string.char(my_x) .. string.char(my_y))
        last_sent_x, last_sent_y = my_x, my_y
    end
end
```

#### Lerp/Interpolation

```lua
local target_x, target_y = 0, 0
local lerp_factor = 0.1

function update_gameplay()
    if current_time - last_network_update > 100 then
        local pkt = recv()
        if pkt then
            target_x = string.byte(pkt, 2)
            target_y = string.byte(pkt, 3)
            last_network_update = current_time
        end
    end
    
    my_x = my_x + (target_x - my_x) * lerp_factor
    my_y = my_y + (target_y - my_y) * lerp_factor
end
```

## Optimization Patterns

### Sprite Batching

**Problem**: Sprites redraw every frame - excessive calls waste CPU.

**Solution**: Batch stationary sprites.

```lua
local static_sprites = {}
local dynamic_sprites = {}

function init_static_sprites()
    static_sprites[1] = {1, 100, 80, false, false}
    static_sprites[2] = {2, 50, 80, false, false}
end

function draw()
    clear()
    
    for i = 1, #static_sprites do
        local s = static_sprites[i]
        spr(s[1], s[2], s[3], s[4], s[5])
    end
    
    for i = 1, #dynamic_sprites do
        local s = dynamic_sprites[i]
        spr(s[1], s[2], s[3], s[4], s[5])
    end
    
    display()
end
```

### Entity Pool Management

**Problem**: Engine supports 128 entities - creating new ones is wasteful.

**Solution**: Pre-allocate and reuse.

```lua
local entities = {}
local next_entity = 0
local active_entities = 0

function pool_init(count)
    for i = 1, count do
        local e = ent()
        entities[i] = e
        entspd(e, 0, 0)
    end
    next_entity = 1
    active_entities = count
end

function pool_create(props)
    if next_entity > #entities then
        error("Pool exhausted!")
    end
    
    local e = entities[next_entity]
    next_entity = next_entity + 1
    
    entpos(e, props.x, props.y)
    entspr(e, props.sprite, props.xflip, props.yflip)
    entag(e, props.tag)
    active_entities = active_entities + 1
    
    return e
end

function pool_recycle(entity)
    for i = 1, #entities do
        if entities[i] == entity then
            table.remove(entities, i)
            break
        end
    end
    del(entity)
    active_entities = active_entities - 1
end
```

### Audio Mixing Limits

**Constraint**: 3 sound channels + 1 music channel.

**Strategy**: Prioritize important sounds.

```lua
local AUDIO_PRIORITIES = {
    player_jump = 100,
    player_attack = 90,
    player_hurt = 95,
    collect_item = 50,
    background = 10
}

function play_sound(filename, importance)
    local priority = importance or AUDIO_PRIORITIES[filename] or 50
    sound(filename, priority)
end
```

### State Machine for Game Flow

```lua
local GameState = {
    main_menu = 0,
    playing = 1,
    paused = 2,
    game_over = 3
}

local current_state = GameState.main_menu

function state_transition(new_state)
    print("State: " .. new_state, 1, 1, 0xFFFF)
    current_state = new_state
end

function update_states()
    if current_state == GameState.main_menu then
        if btnp(0) then state_transition(GameState.playing) end
    elseif current_state == GameState.playing then
        update_gameplay()
        if btnp(2) then state_transition(GameState.paused) end
        if player_health <= 0 then state_transition(GameState.game_over) end
    elseif current_state == GameState.paused then
        if btnp(0) then state_transition(GameState.playing) end
    elseif current_state == GameState.game_over then
        if btnp(0) then
            player_health = 100
            player_x = 120
            player_y = 80
            state_transition(GameState.main_menu)
        end
    end
end
```

### Rendering Optimization

```lua
local last_tile_updates = {}

function update_tiles(x, y, tile_id)
    if last_tile_updates[x] ~= y then
        tile(2, x, y, tile_id)
        last_tile_updates[x] = y
    end
end

function draw_visible_entities()
    for i = 1, #entities do
        local e = entities[i]
        local ex, ey = entpos(e)
        
        if ex < 0 or ex > 224 or ey < 0 or ey > 144 then
            continue
        end
        spr(e)
    end
end
```

### Physics Optimizations

```lua
function check_collision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x1 + w1 > x2 and y1 < y2 + h2 and y1 + h1 > y2
end

function check_distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return dx * dx + dy * dy < 2500  -- 50px radius squared
end
```

## Camera & Scrolling System

### Fundamentals

```lua
-- Camera center (screen: 240x160)
camera(120, 80)  -- Middle of screen

-- Scroll layers independently
scroll(2, 100, 50)  -- Tile_0 scroll
scroll(1, 0, 0)     -- Tile_1 no scroll
scroll(0, 16, 0)    -- Overlay absolute scroll
```

### Parallax Scrolling

```lua
function update_camera()
    local x, y = player_x - 120, player_y - 80
    camera(x, y)
    
    -- Background: 0.5x speed
    scroll(3, (x - camera_x) * 0.5, (y - camera_y) * 0.5)
    
    -- Tile layer 0: 0.8x speed
    scroll(2, (x - camera_x) * 0.8, (y - camera_y) * 0.8)
    
    -- Tile layer 1: no scroll (foreground)
    scroll(1, 0, 0)
end
```

### World Bounds

```lua
local world_width = 512  -- 32 tiles × 16 pixels
local world_height = 256 -- 32 tiles × 8 pixels

function update_camera_bounds()
    local x, y = player_x - 120, player_y - 80
    
    if x < 0 then x = 0 end
    if x > world_width - 240 then x = world_width - 240 end
    if y < 0 then y = 0 end
    if y > world_height - 160 then y = world_height - 160 end
    
    camera(x, y)
end
```

## Error Handling

### Out-of-Bounds Detection

```lua
function safe_tile(layer, x, y, tile_num)
    if x < 0 or x > 127 or y < 0 or y > 127 then
        print("Tile out of bounds", 1, 1, 0xFFFF)
        return false
    end
    tile(layer, x, y, tile_num)
    return true
end

function safe_sprite(sprite, x, y, xflip, yflip)
    if x < 0 or x > 224 or y < 0 or y > 144 then
        print("Sprite out of bounds", 1, 1, 0xFFFF)
        return false
    end
    spr(sprite, x, y, xflip, yflip)
    return true
end
```

### Collision Safety

```lua
function safe_collision_check(e1, e2)
    if not e1 or not e2 then
        print("Invalid entity", 1, 1, 0xFFFF)
        return false
    end
    return eccole(e1, e2)
end
```

### Entity Pool Safety

```lua
function safe_create_entity(props)
    if next_entity > #entities then
        print("Pool exhausted", 1, 1, 0xFFFF)
        return nil
    end
    
    local e = ent()
    if not e then
        print("Failed to create entity", 1, 1, 0xFFFF)
        return nil
    end
    
    entpos(e, props.x, props.y)
    entspr(e, props.sprite, props.xflip, props.yflip)
    return e
end
```

### Multiplayer Safety

```lua
function safe_receive_packet()
    local pkt = recv()
    if not pkt then
        return nil, "No packet"
    end
    
    local len = string.len(pkt)
    if len > 11 then
        return nil, "Packet too long"
    end
    if len < 2 then
        return nil, "Packet too short"
    end
    
    local sender = string.byte(pkt, 1)
    if sender ~= 1 and sender ~= 2 then
        return nil, "Unknown sender"
    end
    
    return pkt, "OK"
end
```

### Memory Bounds

```lua
function safe_poke(addr, value)
    if addr < 0 or addr > 31999 then
        print("Invalid address", 1, 1, 0xFFFF)
        return false
    end
    poke(addr, value)
    return true
end

function safe_peek(addr)
    if addr < 0 or addr > 31999 then
        return 0
    end
    return peek(addr)
end
```

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

#BQ|---
