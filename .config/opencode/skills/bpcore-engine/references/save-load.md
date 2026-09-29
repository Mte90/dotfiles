# Save/Load to SRAM

> This reference file is loaded on demand from ../SKILL.md

## SRAM Overview

GBA provides **32KB SRAM** that persists across restarts, unlike volatile IRAM (8KB).

```
SRAM: 32KB
├── Offset 0x00: Save data
├── Offset 0xFF: Save marker
└── Offset 0x00-0xFF: Checksum
```

## Basic Save/Load

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

## Structured Save Class

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