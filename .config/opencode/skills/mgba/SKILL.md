---
name: mgba
description: Use when scripting mGBA emulator automation in Lua - console API, ROM and save state operations, frame callbacks, input handling, memory reading for cheats and RAM watches, sockets, or TAS and speedrunner tooling
metadata:
  author: mte90
  version: 2.0.0
  tags:
    - lua
    - emulator
    - gba
    - gameboy-advance
    - scripting
    - memory-hacking
---

# mGBA Scripting

Lua scripting for mGBA emulator.

## Overview

Starting with version 0.10, mGBA has built-in scripting capabilities. To use scripting, click "Scripting..." from the Tools menu. Currently, only Lua scripting is supported.

**Key Features:**
- Full memory access (ROM, RAM, MMIO)
- Input manipulation (button presses)
- Save state management
- Callbacks for frame/events
- TCP socket networking
- Console output
- Screenshot capture

### Opening Scripting Console

```
Tools → Scripting...
```

This opens a console where you can load and run Lua scripts.

## Top-Level Objects

### Available Objects

```lua
-- emu: CoreAdapter instance (available when game loaded)
-- C: Exported constants
-- callbacks: CallbackManager instance
-- console: Console instance
-- util: Basic utility library
-- socket: TCP socket library
```

### Console Output

```lua
console.log("Info message")
console.warn("Warning message")
console.error("Error message")

-- Create text buffer
buffer = console.createBuffer("My Buffer")
buffer:print("Text in buffer")
buffer:clear()
```

### Utility Functions

```lua
-- Expand bitmask to list
bits = util.expandBitmask(0xFF)  -- {0,1,2,3,4,5,6,7}

-- Make bitmask from list
mask = util.makeBitmask({0, 3, 5})  -- 0x29
```

## Core API

### ROM Operations

```lua
-- Load ROM file
success = emu.loadFile("path/to/rom.gba")

-- Get game info
title = emu.getGameTitle()  -- "POKEMON FIRE"
code = emu.getGameCode()   -- "AGB-P-FE"
size = emu.romSize()       -- ROM size in bytes
platform = emu.platform()  -- 0=GBA, 1=GB
checksum = emu.checksum()  -- CRC32
```

### Save States

```lua
-- Save to file
emu.saveStateFile("path/to/state.state")

-- Load from file
emu.loadStateFile("path/to/state.state")

-- Save to slot (0-9)
emu.saveStateSlot(0)
emu.loadStateSlot(0)

-- Save/load buffer
buffer = emu.saveStateBuffer()
emu.loadStateBuffer(buffer)

-- Flags: SCREENSHOT=1, SAVEDATA=2, CHEATS=4, RTC=8, METADATA=16
-- ALL = 31
emu.saveStateSlot(0, 31)  -- Save everything
```

### Frame Control

```lua
-- Run one frame
emu.runFrame()

-- Run one instruction
emu.step()

-- Get current frame number
frame = emu.currentFrame()

-- Get cycle info
cycles = emu.frameCycles()    -- Cycles per frame
freq = emu.frequency()         -- Cycles per second
```

### Input Handling

```lua
-- Set all keys at once
emu.setKeys(0x0000)  -- No keys

-- Add keys (OR with existing)
emu.addKeys(C.GBA_KEY.A + C.GBA_KEY.R)

-- Clear keys
emu.clearKeys(C.GBA_KEY.B)

-- Check key state
if emu.getKey(C.GBA_KEY.UP) == 1 then
    print("UP is pressed")
end

-- Get all pressed keys
keys = emu.getKeys()
```

### GBA Key Constants

```lua
C.GBA_KEY.A      = 0
C.GBA_KEY.B      = 1
C.GBA_KEY.SELECT = 2
C.GBA_KEY.START  = 3
C.GBA_KEY.RIGHT  = 4
C.GBA_KEY.LEFT   = 5
C.GBA_KEY.UP     = 6
C.GBA_KEY.DOWN   = 7
C.GBA_KEY.R      = 8
C.GBA_KEY.L      = 9
```

### Game Boy Key Constants

```lua
C.GB_KEY.A       = 0
C.GB_KEY.B       = 1
C.GB_KEY.SELECT  = 2
C.GB_KEY.START   = 3
C.GB_KEY.RIGHT   = 4
C.GB_KEY.LEFT    = 5
C.GB_KEY.UP      = 6
C.GB_KEY.DOWN    = 7
```

## Memory Access

### Reading Memory

```lua
-- Read 8/16/32 bit values
value8 = emu.read8(address)
value16 = emu.read16(address)
value32 = emu.read32(address)

-- Read range
data = emu.readRange(address, length)

-- Read from memory domain
rom = emu.memory["cart0"]
value = rom:read8(offset)
data = rom:readRange(offset, length)
```

### Writing Memory

```lua
-- Write 8/16/32 bit values
emu.write8(address, value)
emu.write16(address, value)
emu.write32(address, value)
```

### Memory Domains (GBA)

```lua
-- Available memory domains
emu.memory["bios"]    -- BIOS (0x00000000)
emu.memory["wram"]     -- EWRAM (0x02000000)
emu.memory["iwram"]    -- IWRAM (0x03000000)
emu.memory["io"]       -- MMIO (0x04000000)
emu.memory["palette"]  -- Palette (0x05000000)
emu.memory["vram"]     -- VRAM (0x06000000)
emu.memory["oam"]      -- OAM (0x07000000)
emu.memory["cart0"]    -- ROM (0x08000000)
emu.memory["cart1"]    -- ROM WS1 (0x0a000000)
emu.memory["cart2"]    -- ROM WS2 (0x0c000000)
```

### Memory Domains (GB)

```lua
emu.memory["cart0"]  -- ROM Bank ($0000)
emu.memory["vram"]   -- VRAM ($8000)
emu.memory["sram"]   -- SRAM ($a000)
emu.memory["wram"]   -- WRAM ($c000)
emu.memory["oam"]    -- OAM ($fe00)
emu.memory["io"]     -- MMIO ($ff00)
emu.memory["hram"]   -- HRAM ($ff80)
```

## Callbacks

### Adding Callbacks

```lua
-- Add callback (returns callback ID)
id = callbacks.add("frame", function()
    -- Called every frame
end)

id = callbacks.add("start", function()
    -- Called when emulation starts
end)

id = callbacks.add("reset", function()
    -- Called when emulation resets
end)

id = callbacks.add("shutdown", function()
    -- Called when emulation stops
end)

-- Remove callback
callbacks.remove(id)
```

### Available Callbacks

```lua
-- alarm     - In-game alarm went off
-- crashed   - Emulation crashed
-- frame     - Frame finished
-- keysRead  - About to read key input
-- reset     - Emulation reset
-- savedataUpdated - Save data modified
-- sleep     - Entered low-power mode
-- shutdown  - Powered off
-- start     - Started
-- stop      - Voluntarily shut down
```

### Frame Callback Example

```lua
-- Auto-press A every 10 frames
local counter = 0
callbacks.add("frame", function()
    counter = counter + 1
    if counter >= 10 then
        emu.addKeys(C.GBA_KEY.A)
        counter = 0
    else
        emu.clearKeys(C.GBA_KEY.A)
    end
end)
```

## Deep Dives

Detailed reference material is available in the `references/` directory. Load these on demand for specific topics:

- **Classes & Registers** — MemoryDomain class, TextBuffer class, GBA/GB register details
  - `references/classes-registers.md`
- **Networking** — Socket API details and constants
  - `references/networking.md`
- **Examples** — Complete working scripts (cheats, TAS tools, networked scripts)
  - `references/examples.md`

## Best Practices

### 1. Always Clear Keys

```lua
-- Bad: Keys stay pressed
callbacks.add("frame", function()
    emu.addKeys(C.GBA_KEY.A)
end)

-- Good: Clear after use
callbacks.add("frame", function()
    emu.addKeys(C.GBA_KEY.A)
    emu.clearKeys(C.GBA_KEY.A)
end)
```

### 2. Use Frame Callback for Input

```lua
-- Input should be handled in frame callback
callbacks.add("frame", function()
    if btnp(6) then  -- UP pressed this frame
        -- Handle input
    end
end)
```

### 3. Watch for Crashes

```lua
callbacks.add("crashed", function()
    console.error("Emulation crashed!")
    -- Save state before exit
    emu.saveStateFile("crash.state")
end)
```

### 4. Reset State on Script Load

```lua
-- Clear any previous state when loading
emu.clearKeys(0xFFFF)
callbacks.remove(cbid)  -- Remove old callbacks
```

## Common Issues

### Address Not Found

```lua
-- Some games use different RAM locations
-- Use mGBA's cheat search or memory viewer to find correct addresses
```

### Keys Not Working

```lua
-- Some games poll keys differently
-- Try using addKeys instead of setKeys
emu.addKeys(C.GBA_KEY.A)  -- OR with existing
```

### Socket Connection Timeout

```lua
-- Socket connect is blocking!
-- Use connect with timeout or run in separate thread
-- For async, use callbacks and poll()
```

## Complete API Reference

### Core Methods Summary

| Method | Description |
|--------|-------------|
| `loadFile(path)` | Load ROM file |
| `getGameTitle()` | Get ROM title |
| `getGameCode()` | Get ROM code |
| `romSize()` | Get ROM size |
| `platform()` | Get platform (GBA=0, GB=1) |
| `checksum(type)` | Get ROM checksum |
| `reset()` | Reset emulation |
| `runFrame()` | Run one frame |
| `step()` | Run one instruction |
| `currentFrame()` | Get frame number |
| `frameCycles()` | Cycles per frame |
| `frequency()` | Cycles per second |
| `screenshot(filename)` | Save screenshot |

### Memory Methods Summary

| Method | Description |
|--------|-------------|
| `read8(addr)` | Read 8-bit value |
| `read16(addr)` | Read 16-bit value |
| `read32(addr)` | Read 32-bit value |
| `readRange(addr, len)` | Read byte range |
| `write8(addr, val)` | Write 8-bit value |
| `write16(addr, val)` | Write 16-bit value |
| `write32(addr, val)` | Write 32-bit value |
| `readRegister(name)` | Read CPU register |
| `writeRegister(name, val)` | Write CPU register |

### Input Methods Summary

| Method | Description |
|--------|-------------|
| `setKeys(mask)` | Set key bitmask |
| `addKeys(mask)` | Add keys to current |
| `clearKeys(mask)` | Remove keys from current |
| `addKey(key)` | Add single key |
| `clearKey(key)` | Clear single key |
| `getKey(key)` | Get key state |
| `getKeys()` | Get all keys as mask |

### Save State Methods Summary

| Method | Description |
|--------|-------------|
| `saveStateFile(path, flags)` | Save to file |
| `loadStateFile(path, flags)` | Load from file |
| `saveStateSlot(slot, flags)` | Save to slot |
| `loadStateSlot(slot, flags)` | Load from slot |
| `saveStateBuffer(flags)` | Save to buffer |
| `loadStateBuffer(buf, flags)` | Load from buffer |
| `autoloadSave()` | Load associated save |

## References

- **Official Documentation**: https://mgba.io/docs/scripting.html
- **mGBA GitHub**: https://github.com/mgba-emu/mgba
- **Forums**: https://forums.mgba.io/
- **Discord**: https://discord.gg/em2M2sG
- **Scripting API Reference**: https://mgba.io/docs/scripting.html