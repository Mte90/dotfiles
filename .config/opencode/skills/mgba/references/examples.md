# Examples Reference

This file is loaded on demand from `../SKILL.md` when you need complete working scripts and advanced examples.

## Basic Examples

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