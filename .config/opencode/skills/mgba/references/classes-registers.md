# Classes & Registers Reference

This file is loaded on demand from `../SKILL.md` when you need detailed information about MemoryDomain, TextBuffer classes, and CPU registers.

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