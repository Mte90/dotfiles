---
name: mgba-scripting
description: "Lua scripting for mGBA emulator - game automation, memory hacking, cheats, callbacks, and ROM manipulation"
metadata:
  author: "OSS AI Skills"
  version: "1.0.0"
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

## Registers

### GBA ARM Registers

```lua
-- Read register
value = emu.readRegister("r0")
emu.readRegister("pc")
emu.readRegister("sp")
emu.readRegister("lr")

-- Write register
emu.writeRegister("r0", 0x12345678)
emu.writeRegister("pc", 0x08000000)
```

### Register Names (GBA)

```lua
-- General purpose: r0-r12
-- Special: sp (r13), lr (r14), pc (r15), cpsr
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

## Socket Networking

### TCP Socket Basics

```lua
-- Create socket
sock = socket.tcp()

-- Connect (blocking!)
err = sock:connect("192.168.1.100", 1234)
if err then
    print("Error: " .. socket.ERRORS[err])
end

-- Bind for server
server = socket.tcp()
server:bind(nil, 8080)
server:listen(1)
client = server:accept()

-- Send data
sock:send("Hello, world!")

-- Receive data
data = sock:receive(1024)

-- Check if data available
if sock:hasdata() then
    data = sock:receive(256)
end

-- Close
sock:close()
```

### Socket Events

```lua
-- Add event callback
id = sock:add("received", function(data)
    print("Received: " .. data)
end)

id = sock:add("error", function(err)
    print("Error: " .. err)
end)

-- Poll manually
sock:poll()

-- Remove callback
sock:remove(id)
```

## Constants

### Platform

```lua
C.PLATFORM.NONE  = -1
C.PLATFORM.GBA   = 0
C.PLATFORM.GB    = 1
```

### Save State Flags

```lua
C.SAVESTATE.SCREENSHOT = 1
C.SAVESTATE.SAVEDATA   = 2
C.SAVESTATE.CHEATS     = 4
C.SAVESTATE.RTC        = 8
C.SAVESTATE.METADATA   = 16
C.SAVESTATE.ALL       = 31
```

### Socket Errors

```lua
C.SOCKERR.OK        = 0
C.SOCKERR.AGAIN     = 1
C.SOCKERR.ADDR_IN_USE = 2
C.SOCKERR.CONN_REFUSED = 3
C.SOCKERR.DENIED    = 4
C.SOCKERR.FAILED    = 5
C.SOCKERR.NETWORK_UNREACHABLE = 6
C.SOCKERR.NOT_FOUND = 7
C.SOCKERR.NO_DATA   = 8
C.SOCKERR.OUT_OF_MEMORY = 9
C.SOCKERR.TIMEOUT   = 10
C.SOCKERR.UNSUPPORTED = 11
```

## Examples

### Simple Memory Cheat

```lua
-- Infinite health (example address)
local healthAddr = 0x02001234

callbacks.add("frame", function()
    -- Always write max health
    emu.write16(healthAddr, 999)
end)
```

### Auto-Farmer

```lua
-- Press A every 60 frames
callbacks.add("frame", function()
    local frame = emu.currentFrame()
    
    if frame % 60 == 0 then
        emu.addKeys(C.GBA_KEY.A)
    else
        emu.clearKeys(C.GBA_KEY.A)
    end
end)
```

### RAM Watch

```lua
-- Watch specific RAM addresses
callbacks.add("frame", function()
    local hp = emu.read16(0x02001234)
    local mp = emu.read16(0x02001236)
    
    console.log(string.format("HP: %d, MP: %d", hp, mp))
end)
```

### Save State Timer

```lua
-- Auto-save every 5 seconds (300 frames at 60fps)
local frameCount = 0
local saveSlot = 0

callbacks.add("frame", function()
    frameCount = frameCount + 1
    
    if frameCount >= 300 then
        emu.saveStateSlot(saveSlot)
        console.log("Auto-saved to slot " .. saveSlot)
        frameCount = 0
    end
end)
```

### Button Masher

```lua
-- Mash A button as fast as possible
callbacks.add("frame", function()
    emu.addKeys(C.GBA_KEY.A)
    emu.clearKeys(C.GBA_KEY.A)
end)
```

### RNG Manipulation

```lua
-- Advance RNG for shiny hunting
-- Example: GBA games often use LCG at specific address
local rngAddr = 0x02001234  -- Replace with actual address

callbacks.add("frame", function()
    local rng = emu.read32(rngAddr)
    -- Simple LCG: new = (old * 0x41C64E6D + 0x6073) & 0xFFFFFFFF
    local newRng = (rng * 0x41C64E6D + 0x6073) & 0xFFFFFFFF
    emu.write32(rngAddr, newRng)
end)
```

### Screenshot Capture

```lua
-- Capture screenshot every 1000 frames
callbacks.add("frame", function()
    if emu.currentFrame() % 1000 == 0 then
        local filename = string.format("screenshot_%04d.png", emu.currentFrame())
        emu.screenshot(filename)
    end
end)
```

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

## MemoryDomain Class

Memory domains provide direct access to specific memory regions (ROM, RAM, etc.).

### Methods

```lua
-- Get domain info
local rom = emu.memory["cart0"]
local baseAddr = rom:base()      -- Base address
local boundAddr = rom:bound()    -- End address (exclusive)
local size = rom:size()          -- Size in bytes
local name = rom:name()          -- Human-readable name

-- Read from domain
value8 = rom:read8(offset)
value16 = rom:read16(offset)
value32 = rom:read32(offset)
data = rom:readRange(offset, length)

-- Write to domain (RAM only, not ROM)
local wram = emu.memory["wram"]
wram:write8(offset, 0xFF)
wram:write16(offset, 0xFFFF)
wram:write32(offset, 0xFFFFFFFF)
```

### Example: ROM Analysis

```lua
-- Read ROM header
local rom = emu.memory["cart0"]

-- Nintendo logo starts at 0x04
local logo = rom:readRange(0x04, 156)

-- Game title at 0xA0 (12 bytes)
local title = rom:readRange(0xA0, 12)
console.log("Game: " .. title)

-- Game code at 0xAC (4 bytes)
local code = rom:readRange(0xAC, 4)
console.log("Code: " .. code)

-- Maker code at 0xB0 (2 bytes)
local maker = rom:readRange(0xB0, 2)
console.log("Maker: " .. maker)
```

## TextBuffer Class

Create custom text buffers for displaying information.

### Methods

```lua
-- Create buffer
local buf = console.createBuffer("My Buffer")

-- Set size
buf:setSize(80, 25)  -- 80 columns, 25 rows

-- Get dimensions
local cols = buf:cols()
local rows = buf:rows()

-- Print text
buf:print("Hello, World!")

-- Move cursor
buf:moveCursor(10, 5)  -- x=10, y=5

-- Get cursor position
local x = buf:getX()
local y = buf:getY()

-- Advance cursor
buf:advance(5)  -- Move 5 columns right

-- Clear buffer
buf:clear()

-- Set visible name
buf:setName("Stats Display")
```

### Example: Stats Display

```lua
local statsBuf = console.createBuffer("Game Stats")
statsBuf:setSize(40, 10)
statsBuf:setName("Live Stats")

callbacks.add("frame", function()
    statsBuf:clear()
    
    local hp = emu.read16(0x02001234)
    local mp = emu.read16(0x02001236)
    local gold = emu.read32(0x02001238)
    
    statsBuf:moveCursor(0, 0)
    statsBuf:print("=== GAME STATS ===\n")
    statsBuf:print(string.format("HP:   %5d\n", hp))
    statsBuf:print(string.format("MP:   %5d\n", mp))
    statsBuf:print(string.format("Gold: %5d\n", gold))
    statsBuf:print("==================")
end)
```

## Game Boy Registers

For Game Boy (DMG/CGB) emulation.

### Register Names

```lua
-- 8-bit registers
emu.readRegister("a")   -- Accumulator
emu.readRegister("f")   -- Flags
emu.readRegister("b")
emu.readRegister("c")
emu.readRegister("d")
emu.readRegister("e")
emu.readRegister("h")
emu.readRegister("l")

-- 16-bit register pairs
emu.readRegister("bc")
emu.readRegister("de")
emu.readRegister("hl")
emu.readRegister("af")
emu.readRegister("pc")  -- Program counter
emu.readRegister("sp")  -- Stack pointer
```

### Example: GB Register Watch

```lua
callbacks.add("frame", function()
    -- Watch GB registers
    local a = emu.readRegister("a")
    local hl = emu.readRegister("hl")
    local pc = emu.readRegister("pc")
    
    console.log(string.format("A=%02X HL=%04X PC=%04X", a, hl, pc))
end)
```

## Advanced Examples

### Memory Search

```lua
-- Find all occurrences of a value in RAM
function searchMemory(value, size)
    local wram = emu.memory["wram"]
    local results = {}
    
    for i = 0, wram:size() - size, size do
        local v
        if size == 1 then
            v = wram:read8(i)
        elseif size == 2 then
            v = wram:read16(i)
        else
            v = wram:read32(i)
        end
        
        if v == value then
            table.insert(results, i)
        end
    end
    
    return results
end

-- Usage
local addresses = searchMemory(100, 2)  -- Find 100 as 16-bit
for _, addr in ipairs(addresses) do
    console.log(string.format("Found at 0x%08X", addr))
end
```

### Cheat Engine

```lua
-- Simple cheat engine with multiple cheats
local cheats = {
    { name = "Infinite HP", addr = 0x02001234, value = 999, size = 2, enabled = true },
    { name = "Max Gold", addr = 0x02001238, value = 999999, size = 4, enabled = true },
    { name = "All Items", addr = 0x02002000, value = 0xFF, size = 1, enabled = false },
}

callbacks.add("frame", function()
    for _, cheat in ipairs(cheats) do
        if cheat.enabled then
            if cheat.size == 1 then
                emu.write8(cheat.addr, cheat.value)
            elseif cheat.size == 2 then
                emu.write16(cheat.addr, cheat.value)
            else
                emu.write32(cheat.addr, cheat.value)
            end
        end
    end
end)

-- Toggle cheat
function toggleCheat(name)
    for _, cheat in ipairs(cheats) do
        if cheat.name == name then
            cheat.enabled = not cheat.enabled
            console.log(name .. ": " .. (cheat.enabled and "ON" or "OFF"))
        end
    end
end
```

### Speedrunner Tools

```lua
-- Frame counter and IGT (In-Game Time) tracker
local startFrame = nil
local lastSplit = nil
local splits = {}

callbacks.add("start", function()
    startFrame = emu.currentFrame()
    splits = {}
end)

function split(name)
    local currentFrame = emu.currentFrame()
    local frameTime = currentFrame - (lastSplit or startFrame)
    lastSplit = currentFrame
    
    table.insert(splits, {
        name = name,
        frame = frameTime,
        total = currentFrame - startFrame
    })
    
    local seconds = frameTime / 60
    local totalSeconds = (currentFrame - startFrame) / 60
    console.log(string.format("%s: %.2fs (Total: %.2fs)", name, seconds, totalSeconds))
end

function printSplits()
    console.log("=== SPLITS ===")
    for _, s in ipairs(splits) do
        console.log(string.format("%s: %.2fs", s.name, s.frame / 60))
    end
    console.log("==============")
end
```

### TAS Helper

```lua
-- Record and playback inputs
local recording = {}
local isRecording = false
local isPlaying = false
local playbackFrame = 0

function startRecording()
    recording = {}
    isRecording = true
    console.log("Recording started...")
end

function stopRecording()
    isRecording = false
    console.log("Recording stopped. " .. #recording .. " frames recorded.")
end

function startPlayback()
    isPlaying = true
    playbackFrame = 0
    console.log("Playback started...")
end

function stopPlayback()
    isPlaying = false
    console.log("Playback stopped.")
end

callbacks.add("frame", function()
    if isRecording then
        table.insert(recording, emu.getKeys())
    elseif isPlaying then
        playbackFrame = playbackFrame + 1
        if playbackFrame <= #recording then
            emu.setKeys(recording[playbackFrame])
        else
            isPlaying = false
            console.log("Playback complete.")
        end
    end
end)
```

### Networked Multi-Script

```lua
-- Sync game state over network
local server = nil
local clients = {}

function startSyncServer(port)
    server = socket.tcp()
    server:bind(nil, port or 8080)
    server:listen(5)
    
    server:add("received", function()
        local client = server:accept()
        table.insert(clients, client)
        console.log("Client connected!")
    end)
    
    console.log("Sync server started on port " .. (port or 8080))
end

function broadcastState()
    if not server then return end
    
    local state = {
        frame = emu.currentFrame(),
        keys = emu.getKeys(),
        -- Add more state as needed
    }
    
    local data = string.format("%d,%d\n", state.frame, state.keys)
    
    for i, client in ipairs(clients) do
        local err = client:send(data)
        if err then
            table.remove(clients, i)
        end
    end
end

callbacks.add("frame", broadcastState)
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