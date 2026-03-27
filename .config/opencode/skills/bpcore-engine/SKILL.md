---
name: bpcore-engine
description: "BPCore Engine - Lua game framework for Gameboy Advance with sprites, tilemaps, entities, collision, audio, multiplayer"
metadata:
  author: "OSS AI Skills"
  version: "1.0.0"
  tags:
    - lua
    - gba
    - game-engine
    - gameboy-advance
    - retro-gaming
---

# BPCore Engine Skill

Comprehensive guide for building Gameboy Advance games using the BPCore Engine Lua framework.

## Overview

BPCore Engine (Blind jumP Core Engine) is a Lua game framework specifically designed for the Gameboy Advance (GBA) handheld console. The framework combines a C++ engine with an embedded Lua interpreter, allowing developers to create GBA games using Lua without needing to write C++ code or use a compiler. The API design takes inspiration from fantasy consoles like Pico-8 and Tic80, making it familiar to developers who have experience with those platforms.

The Gameboy Advance presents unique challenges for game development due to its limited hardware resources. The GBA features a 240x160 pixel screen, a 16.78 MHz ARM7TDMI processor, and only 256KB of RAM available for Lua code and data. Because Lua is resource-intensive, the engine is best suited for creating relatively small minigames rather than complex, resource-intensive applications. If you need to build more ambitious projects, consider learning C++ and using the Butano engine instead.

The engine provides a comprehensive API that covers sprite rendering, tile-based graphics, entity management with collision detection, button input handling, text rendering with UTF-8 support, audio playback, save/load functionality via SRAM, and multiplayer networking through the GBA's link cable. The build system uses a simple Lua script to package resources into a ROM file, making the development workflow accessible and straightforward.

## Setup and Installation

### Prerequisites

To start developing with BPCore Engine, you need three essential components. First, you need a copy of the `build.lua` script from the BPCore Engine repository, which handles the ROM building process. Second, you need the `BPCoreEngine.gba` base ROM file that contains the engine's compiled code. Third, you need Lua 5.3 installed on your development machine, as the build script is written in Lua.

The build process works by taking the base ROM file and appending a resource bundle containing all your game assets and scripts. When the GBA boots, the engine locates this resource bundle, loads your main.lua script, and begins executing your game code. This approach allows you to create complete games using only Lua scripts and resource files, without needing to recompile the C++ engine.

### Creating a Manifest

The manifest.lua file tells the build system which resources to include in your ROM. This file defines your game's metadata, specifies asset files, and identifies the main script entry point. Here is a comprehensive example demonstrating all available manifest options:

```lua
local app = {
    -- Game identification in the ROM header
    name = "MyGame",
    gamecode = "ABCD",  -- Four-character game code (optional)
    makercode = "BC",  -- Two-character maker code (optional)
    
    -- Graphics resources
    tilesets = {
        "overlay.bmp",      -- Text and UI tiles
        "tile0.bmp",        -- Main background tiles
        "tile1.bmp",        -- Additional tile set
    },
    
    spritesheets = {
        "spritesheet.bmp",  -- Sprite graphics
    },
    
    -- Audio resources
    audio = {
        "music.raw",         -- Background music
        "jump.wav",         -- Sound effect
        "coin.wav",         -- Sound effect
    },
    
    -- Lua scripts (main.lua is the entry point)
    scripts = {
        "main.lua",
        "menu.lua",
        "game.lua",
        "utils.lua",
    },
    
    -- Miscellaneous files
    misc = {
        "level1.csv",        -- Tilemap data
        "spritedata.txt",   -- Configuration
    }
}

return app
```

The manifest structure separates different resource types into their respective categories. Tilesets are 8x8 tile graphics used for background layers, while spritesheets contain 16x16 sprite graphics. Audio files must be in a specific format: mono 16kHz signed 8-bit PCM. Scripts are your Lua game code, and miscellaneous files can include any additional data your game needs.

### Building Your ROM

Once you have created your manifest.lua and placed all your resource files in the appropriate directory, building the ROM is straightforward. Run the build.lua script with Lua 5.3, specifying your manifest file and the base ROM:

```bash
lua53 build.lua manifest.lua BPCoreEngine.gba output.gba
```

The build script will parse your manifest, verify that all referenced files exist, and create a new ROM file with your game bundled inside. If there are any errors in your manifest or missing files, the build will fail with informative error messages that help you identify and fix the issue.

After building, you can test your ROM using an emulator such as mGBA, which provides excellent debugging tools including a logging window for the engine's log() function, memory viewers for inspecting IRAM and SRAM, and a disassembler for troubleshooting.

## Graphics System

### Understanding Layers and Memory

The GBA uses a tile-based display system where all graphics are composed of small tiles. Sprites are always 16x16 pixels, while background tiles are 8x8 pixels. The engine provides four tile-based layers plus a sprite layer, each with different characteristics and use cases.

The overlay layer (layer ID 0) is a 32x32 tile layer that displays in front of all other content. This layer is primarily used for text rendering via the print() function, but you can also draw tiles directly on it. The overlay is persistent like all tile layers, meaning tiles remain on screen until you explicitly change them.

Tile layer 1, also known as tile_1, is a larger 64x64 tile layer that displays behind sprites but in front of tile_0 and the background. This makes it suitable for foreground parallax elements or game elements that should appear behind sprites but above the main background.

Tile layer 0 (layer ID 2, also called tile_0) is another 64x64 tile layer that displays behind sprites, tile_1, and the overlay, but in front of the background layer. Use this for your main game background where you want layered depth effects.

The background layer (layer ID 3) is a 32x32 tile layer that displays behind everything else. It shares texture memory with tile_0, so you need to balance your graphical resources between these two layers carefully.

Sprites (loaded via layer ID 4) are dynamic objects that the engine renders on top of tile layers. Unlike tiles, sprites must be redrawn every frame using the clear() and display() cycle.

### Loading Textures

The txtr() function loads image data from resource bundle files into VRAM for use by specific layers. You can load by filename for initial loading, or preload with the file() function for faster texture swapping during gameplay:

```lua
-- Load a tileset into tile layer 1
txtr(1, "forest_tiles.bmp")

-- Load the spritesheet
txtr(4, "player_sprites.bmp")

-- Preload multiple textures for fast swapping
local forest_ptr, forest_len = file("forest_tiles.bmp")
local cave_ptr, cave_len = file("cave_tiles.bmp")

-- Later in your game, switch textures instantly
txtr(1, forest_ptr, forest_len)  -- Switch to forest
txtr(1, cave_ptr, cave_len)      -- Switch to cave
```

The texture loading system supports BMP files with specific constraints. The engine expects indexed color images where the palette defines available colors. For tilesets, the image dimensions should match the layer size (32x32 or 64x64 tiles, each tile being 8x8 pixels). Spritesheets can contain multiple 16x16 sprite frames arranged in a grid.

### Drawing Sprites

The spr() function draws sprites from the loaded spritesheet at specified screen coordinates. Sprites are not persistent—you must redraw them every frame within your game loop:

```lua
function draw()
    -- Draw sprite index 0 at position (100, 80)
    spr(0, 100, 80)
    
    -- Draw sprite with horizontal flip
    spr(5, 50, 60, true, false)
    
    -- Draw sprite with vertical flip
    spr(5, 150, 60, false, true)
    
    -- Draw sprite with both flips (rotated 180 degrees)
    spr(5, 200, 80, true, true)
end
```

Sprite indices correspond to positions in your spritesheet. If your spritesheet is organized as a grid, calculate indices by counting from left to right, top to bottom. The GBA hardware supports a maximum of 128 sprites on screen simultaneously, so be mindful of this limit in busy scenes.

Important: The engine draws sprites with increasing depth, meaning later spr() calls appear behind earlier ones. This may seem counterintuitive, but it ensures that when you exceed the 128 sprite limit, background sprites are hidden rather than foreground sprites.

### Drawing Tiles

The tile() function draws individual tiles on tile layers. Unlike sprites, tiles are persistent—they remain on screen without needing to be redrawn. This makes tiles efficient for backgrounds but requires careful management when you want to change them:

```lua
-- Draw tile index 1 at position (10, 10) on layer 1
tile(1, 10, 10, 1)

-- Draw the same tile across an area
for x = 0, 63 do
    for y = 0, 63 do
        tile(2, x, y, 1)  -- Fill layer 0 with tile 1
    end
end

-- Read the current tile at a position (getter mode)
local current = tile(2, 5, 5)  -- Returns tile index at that position
```

The tile() function operates differently depending on whether you provide a tile_num argument. With a tile number, it sets the tile at that position. Without it, the function returns the current tile index at the specified position, useful for collision detection or terrain checking.

### Loading Tilemaps

For large background areas, loading tiles one by one is impractical. The tilemap() function allows you to load pre-made tilemaps from CSV files, which you can export from map editors like Tiled:

```lua
-- Load a full tilemap from a CSV file
-- tilemap(filename, layer, width, height, dest_x, dest_y, src_x, src_y)
tilemap("level1.csv", 2, 64, 64, 0, 0, 0, 0)

-- Load only a portion of a larger tilemap
-- Load a 20x15 section starting from column 10, row 5
tilemap("world.csv", 1, 20, 15, 0, 0, 10, 5)
```

The CSV format uses comma-separated integer values representing tile indices. Each row in the CSV corresponds to a row of tiles in the layer. The function will fail if the file doesn't exist or if your parameters would cause an out-of-bounds access.

### Camera and Scrolling

The camera() function sets the center point of the view, affecting all subsequent sprite rendering. The scroll() function provides additional control for individual layers:

```lua
-- Set camera center to (x, y)
camera(120, 80)  -- Center on middle of screen

-- Additional scrolling for tile layers (relative to camera)
scroll(2, 0, 0)    -- No extra scroll on tile_0
scroll(1, 10, 5)   -- Offset tile_1 by 10 pixels horizontal, 5 vertical

-- Overlay scroll is absolute (not affected by camera)
scroll(0, 16, 0)   -- Scroll overlay 16 pixels right
```

Camera scrolling automatically affects sprites and the two map layers (tile_0 and tile_1). The overlay and background layers do not scroll with the camera, giving you flexibility in creating layered parallax effects. The scroll amounts for tile layers are relative to the camera position, while the overlay scroll is absolute.

### Layer Priority

The priority() function lets you reorder the rendering layers to control which elements appear in front of others:

```lua
-- priority(sprite, background, tile_0, tile_1)
-- Values 0-3: 0 = nearest to screen, 3 = furthest

-- Default priority
priority(1, 3, 3, 2)

-- Put background behind everything
priority(1, 3, 2, 1)

-- Bring sprites to front, tile_1 to back
priority(0, 3, 2, 3)
```

The overlay always has priority 0 and cannot be changed. When layers share the same priority value, the engine uses a fixed precedence order: sprites > tile_0 > background > overlay > tile_1. Understanding this order helps you achieve the desired visual layering.

### Screen Effects

The fade() function creates fade effects for transitions between scenes or states:

```lua
-- Simple fade to black
fade(1.0)           -- Fully faded (black)
fade(0.0)           -- No fade (fully visible)
fade(0.5)           -- Half faded

-- Fade to custom color (hex colors)
fade(0.8, 0xFFFF)   -- Fade to white

-- Control which layers are affected
fade(0.5, nil, false, true)  -- Only fade the overlay
```

The fade amount ranges from 0.0 (fully visible) to 1.0 (fully faded). By default, fade affects all layers except text with custom colors. The custom color option allows creating transitions to specific colors rather than black.

### Display Cycle

Every frame follows a specific sequence: update game logic, clear sprites, draw new sprites, then display. The clear() function clears all sprites and performs a VSync to synchronize with the display refresh:

```lua
function main_loop()
    while true do
        -- Update game state (button input, physics, etc.)
        update(delta())
        
        -- Clear previous frame's sprites
        clear()
        
        -- Draw all sprites for this frame
        draw()
        
        -- Send sprites to display
        display()
    end
end
```

The clear() function erases all sprites from the screen but does not affect tiles. Tiles persist across frames, so you only need to set up your background tiles once during loading. The display() function sends all pending sprite draw calls to the GBA hardware, making them visible.

### Frame Rate Control

The flimit() function restricts the frame rate to help manage CPU usage:

```lua
-- Limit to 30 FPS for slower games
flimit(30)

-- Full 60 FPS (default)
flimit(60)
```

Lower frame rates can help if your game logic is complex and needs more time per frame. The GBA has limited CPU resources, so finding the right balance between frame rate and game complexity is important.

### Monitoring Performance

The rline() function returns the current raster line number, which helps diagnose performance issues:

```lua
-- Check if you're taking too long per frame
local line = rline()
if line > 160 then
    -- Game is lagging: taking too long to update
    print("LAG!", 1, 1)
end
```

The GBA screen has 160 visible raster lines. If your game logic causes the raster to advance past line 160, you have exceeded your frame budget and the game will exhibit visual lag or tearing.

## Entity System

### Entity Overview

Entities are enhanced sprite objects with automatic rendering, hitbox support, and collision detection. Unlike regular sprites that you must redraw every frame, entities are automatically managed by the engine—they are redrawn each frame without explicit calls, and the engine handles sorting them by Z-order for proper depth rendering.

The entity system supports a maximum of 128 entities simultaneously. All entity functions that modify properties return the entity as a result, enabling method chaining. When called without modification arguments, these functions act as getters, returning the current property values.

### Creating and Managing Entities

```lua
-- Create a new entity
local player = ent()

-- Set entity properties with chaining
entspr(entpos(entz(player, 10), 100, 80), 0)
entspd(player, 0, 0)  -- No automatic movement

-- Or use the chained form directly
local enemy = entpos(entspr(ent(), 5), 120, 100)

-- Delete an entity when done
del(player)
del(enemy)

-- Delete entity when animation finishes
del(some_effect_entity, 1)  -- Parameter 1 means delete on animation end
```

The del() function is essential for resource management. The Lua garbage collector does not automatically clean up entities—the engine owns them. Always delete entities when they are no longer needed to free their slot for new entities.

### Entity Properties

Each entity has several properties that control its appearance and behavior:

```lua
local e = ent()

-- Set sprite (sprite_id, xflip, yflip)
entspr(e, 10, false, false)

-- Get sprite info
local sprite_id, xflip, yflip = entspr(e)

-- Set position
entpos(e, 50, 60)

-- Get position
local x, y = entpos(e)

-- Set Z-order (0-255, higher renders in front)
entz(e, 100)

-- Get Z-order
local z = entz(e)

-- Tag the entity for collision filtering
entag(e, 100)  -- Tag as enemy type

-- Get tag
local tag = entag(e)
```

Entity properties persist across frames without needing to be set again. The engine automatically handles repositioning and rendering based on these stored values.

### Hitboxes and Collision

Entities include configurable hitboxes for collision detection. By default, entities have a 16x16 hitbox centered on their position, matching the sprite size:

```lua
-- Set custom hitbox
-- enthb(entity, x_origin, y_origin, width, height)
enthb(e, 4, 4, 8, 8)  -- Smaller hitbox centered in sprite

-- Check collision between two entities
if ecole(entity1, entity2) then
    -- Collision detected!
end

-- Check collision with entities of a specific tag
-- Returns array of up to 16 colliding entities
local collisions = ecoll(entity1, 100)  -- Find all entities tagged 100
for i = 1, #collisions do
    local other = collisions[i]
    -- Handle collision with each entity
end
```

Hitboxes are anchored relative to the entity center. The x_origin and y_origin values are subtracted from the entity's center to position the hitbox. This allows creating hitboxes that don't exactly match the visual sprite—for example, making a character with a sword have a larger attack hitbox than their body hitbox.

### Entity Movement and Slots

The entspd() function sets automatic movement that the engine applies each frame:

```lua
-- Set entity speed (pixels per frame)
entspd(e, 2, 1)  -- Move 2 pixels right, 1 pixel down per frame

-- Entity slots store arbitrary data
entslots(e, 5)   -- Allocate 5 slots for this entity

-- Store and retrieve values
entslot(e, 1, 100)    -- Store 100 in slot 1
entslot(e, 2, "data") -- Store string in slot 2

local value1 = entslot(e, 1)   -- Retrieve slot 1 value
local value2 = entslot(e, 2)   -- Retrieve slot 2 value
```

Entity slots use 1-based indexing, matching Lua table conventions. The slot system provides a way to store game-specific data associated with each entity, such as health points, animation frames, or custom flags. Accessing invalid slots (0 or beyond allocated count) raises a fatal error.

### Entity Animation

The entanim() function creates sprite animations that cycle through keyframes:

```lua
-- Animate entity
-- entanim(entity, start_keyframe, length, rate)
entanim(e, 0, 4, 2)  -- Animate frames 0-3, advancing every 2 display() calls

-- Create and automatically delete a one-shot effect
local effect = entpos(entspr(ent(), 20), 100, 100)
entanim(effect, 0, 6, 1)  -- Animate frames 0-5
del(effect, 1)  -- Delete when animation completes
```

The rate parameter controls animation speed—higher values mean slower animation. Each display() call advances the animation counter, so the effective animation speed depends on your frame rate.

### Getting All Entities

For advanced use cases, you can retrieve a table of all active entities:

```lua
-- Get table of all entities
local all_entities = ents()

-- Iterate through entities
for i = 1, #all_entities do
    local e = all_entities[i]
    -- Process each entity
end
```

Use this function sparingly—it allocates a new table each call, which impacts performance. Only call it when necessary, such as when switching scripts and needing to clean up or preserve entity state.

## Input System

### Button State Functions

The input system provides three functions for different button states:

```lua
-- btn(num) - Returns true if button is currently held down
if btn(0) then  -- A button
    -- Player is holding A
end

-- btnp(num) - Returns true on frame button was pressed (just pressed)
if btnp(6) then  -- Up button
    -- Player just pressed Up (transition from unpressed to pressed)
end

-- btnnp(num) - Returns true on frame button was released (just not pressed)
if btnnp(1) then  -- B button
    -- Player just released B
end
```

Button IDs: 0=A, 1=B, 2=Start, 3=Select, 4=Left, 5=Right, 6=Up, 7=Down, 8=L bumper, 9=R bumper.

Use btn() for continuous actions like movement, btnp() for single-trigger actions like jumping or menu selection, and btnnp() for detecting button releases.

### Input Example

```lua
function update_movement(dt)
    local dx = 0
    local dy = 0
    
    -- Continuous movement with directional buttons
    if btn(4) then dx = dx - 1 end  -- Left
    if btn(5) then dx = dx + 1 end  -- Right
    if btn(6) then dy = dy - 1 end  -- Up
    if btn(7) then dy = dy + 1 end  -- Down
    
    -- Normalize diagonal movement
    if dx ~= 0 and dy ~= 0 then
        dx = dx * 0.707
        dy = dy * 0.707
    end
    
    -- Apply movement
    x = x + dx * speed * dt
    y = y + dy * speed * dt
    
    -- Single actions
    if btnp(0) then
        -- Jump on A press
        velocity_y = -10
    end
    
    if btnp(2) then
        -- Pause menu on Start
        game_state = "paused"
    end
end
```

## Text Rendering

### Basic Printing

The print() function renders text to the overlay layer using the built-in system font:

```lua
-- Basic usage
print("Hello, World!", 1, 1)

-- Custom colors (foreground, background)
print("Colored text", 5, 5, 0xFFFF, 0x0000)

-- Using custom color IDs (palette indices)
print("Custom palette", 1, 10, 4, 5)
```

The x and y coordinates are in tile units (not pixels), representing positions in the 32x32 overlay grid. Each tile is 8x8 pixels, so coordinate (30, 19) places text at the bottom-right corner of the screen.

### Character Limitations

Text rendering requires copying glyphs into VRAM. The engine uses the first 80 tile slots in the overlay layer for glyph mapping, which means you cannot display more than 80 unique text characters onscreen simultaneously. This limitation matters most in games with many different characters visible at once, such as RPGs with dialogue boxes.

```lua
-- This works fine (fewer than 80 unique characters)
print("Score: 100", 1, 1)
print("Lives: 3", 1, 3)

-- This may cause issues with many unique characters
print("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", 1, 1)
-- Many repeated characters are fine, but each unique character uses a slot
```

If you exceed the limit, some characters may not render correctly. Strategies to work around this include limiting visible text, using fewer unique characters, or breaking long text across multiple frames.

### UTF-8 Support

BPCore supports UTF-8 encoded text, including characters beyond basic ASCII:

```lua
-- English text
print("Score: " .. score, 1, 1)

-- Accented characters (Spanish, French)
print("¡Hola! ¿Cómo estás?", 1, 5)

-- Japanese Katakana
print("ゲーム", 1, 10)

-- Russian alphabet
print("Привет", 1, 12)

-- Chinese characters (2500 most common included)
print("你好世界", 1, 15)
```

The engine includes English alphanumeric characters, accented characters for Spanish and French, a selection of Japanese Katakana, the Russian alphabet, some Scandinavian glyphs, and approximately 2500 of the most common Chinese characters. Not all Unicode characters are supported—only those included in the built-in font.

### System Font Colors

The overlay layer shares graphics memory with the system font. Text uses color indices 2 and 3 from the overlay layer's palette by default for foreground and background. To customize these colors, include an 8x8 pixel calibration tile at index 0 of your overlay tileset: the top band sets the text background, the middle band sets the foreground, and the bottom band should be black.

```lua
-- Text with default colors uses palette indices 2 (fg) and 3 (bg)
print("Default colors", 1, 1)

-- Custom color IDs reference palette entries directly
print("Custom", 1, 5, 4, 6)  -- Use palette index 4 for foreground, 6 for background
```

## Audio System

### Music Playback

The music() function plays background music from audio files:

```lua
-- Start playing music from the beginning
music("music.raw", 0)

-- Start playing from a specific offset (in microseconds)
music("battle_music.raw", 0)
music("victory_music.raw", 0)  -- Jump to victory theme

-- Music loops automatically
```

Audio files must be mono 16kHz signed 8-bit PCM format. The .raw extension is conventional—your audio files can have any extension as long as the format is correct. Many audio editors or FFmpeg can convert audio to this format:

```bash
# Convert MP3 to GBA-compatible format using FFmpeg
ffmpeg -i input.mp3 -ar 16000 -ac 1 -f sv8 input.raw
```

The offset parameter lets you start playback from a specific position in the file, useful for looping music at different points or creating seamless transitions.

### Sound Effects

The sound() function plays one-shot sound effects:

```lua
-- Play sound effect (file, priority)
sound("jump.wav", 5)
sound("coin.wav", 10)
sound("explosion.wav", 8)

-- Higher priority sounds can evict lower priority ones
-- The engine has 3 sound channels plus 1 music channel
```

The engine supports four audio channels total: three for sound effects and one for music. When you play a sound and all three effect channels are busy, the engine evicts the sound with the lowest priority to play your new sound. Set higher priority values for more important sounds like player jumping or taking damage, and lower priorities for ambient or frequently playing sounds.

```lua
-- Example: Prioritize player sounds over environmental sounds
sound("player_jump.wav", 100)    -- Very important
sound("player_land.wav", 90)     -- Important
sound("footstep.wav", 10)        -- Less important
sound("wind.wav", 5)             -- Can be interrupted
```

## Memory System

### Memory Regions

The GBA provides several memory regions accessible through the engine's peek/poke functions. Two regions are writable: _IRAM (Internal RAM, 8000 bytes of fast on-chip memory) and _SRAM (Save RAM, 32KB of persistent storage). Other memory regions can be read but not written directly.

```lua
-- Access IRAM (fast, volatile)
poke(_IRAM, 65)              -- Write byte 65 to IRAM
poke4(_IRAM + 4, 12345)     -- Write 32-bit word

local val = peek(_IRAM)      -- Read byte
local val4 = peek4(_IRAM + 4)  -- Read 32-bit word

-- Access SRAM (slower, persistent across restarts)
poke(_SRAM, 100)
poke4(_SRAM + 100, 999)
```

_IRAM is fast but volatile—data is lost when the game restarts. Use it for temporary data that doesn't need to persist between sessions, such as caching or inter-script communication. _SRAM is slower but persistent—data survives game restarts and can be used for save games.

### String Operations

For larger data transfers, use memput and memget:

```lua
-- Write string to memory
memput(_IRAM, "Hello")

-- Read string from memory
local data = memget(_IRAM, 5)  -- Read 5 bytes
print(data, 1, 1)  -- Prints "Hello"

-- Write multiple values
poke4(_IRAM, 1000)       -- Player score
poke4(_IRAM + 4, 50)     -- Player health
poke4(_IRAM + 8, 3)      -- Player lives
poke(_IRAM + 12, 1)      -- Current level

-- Read saved game data
local score = peek4(_SRAM)
local health = peek4(_SRAM + 4)
local level = peek(_SRAM + 8)
```

### Reading Resource Files

The file() function provides access to bundled resource files:

```lua
-- Get pointer and length to a file
local ptr, len = file("level1.csv")

-- Read first 10 bytes of the file
local data = memget(ptr, 10)

-- Read individual bytes
local byte1 = peek(ptr)
local byte2 = peek(ptr + 1)

-- Read file into a string
for i = 1, len do
    local byte = peek(ptr + i - 1)
    -- Process byte
end
```

Files are read-only (they reside in ROM), so you cannot write to them directly. Use file() to read game data, level definitions, or any other static data bundled with your game.

### Save/Load Implementation Example

```lua
-- Save game state to SRAM
function save_game()
    local offset = 0
    
    -- Write player position
    poke4(_SRAM + offset, player_x); offset = offset + 4
    poke4(_SRAM + offset, player_y); offset = offset + 4
    
    -- Write player stats
    poke4(_SRAM + offset, player_health); offset = offset + 4
    poke4(_SRAM + offset, player_score); offset = offset + 4
    
    -- Write level info
    poke(_SRAM + offset, current_level); offset = offset + 1
    
    -- Write flag to indicate save exists
    poke(_SRAM + 255, 0x42)  -- Save marker
    
    print("Game Saved!", 10, 10, 0xFFFF)
end

-- Load game state from SRAM
function load_game()
    -- Check if save exists
    if peek(_SRAM + 255) ~= 0x42 then
        return false  -- No save found
    end
    
    local offset = 0
    
    -- Read player position
    player_x = peek4(_SRAM + offset); offset = offset + 4
    player_y = peek4(_SRAM + offset); offset = offset + 4
    
    -- Read player stats
    player_health = peek4(_SRAM + offset); offset = offset + 4
    player_score = peek4(_SRAM + offset); offset = offset + 4
    
    -- Read level info
    current_level = peek(_SRAM + offset)
    
    return true
end
```

## Multiplayer System

### Link Cable Overview

BPCore supports multiplayer gaming through the GBA's link cable, allowing two (and potentially more in future versions) GBA devices to communicate. The implementation uses asynchronous I/O with queues for sending and receiving packets.

Important characteristics: messages are not guaranteed to arrive in order or at all. Each device maintains a 64-packet receive queue and a 32-packet send queue. Overflowing either queue causes packet loss. In practice, limiting send() calls to a few packets per frame prevents any noticeable packet loss.

### Connection Management

```lua
-- Attempt to connect to another GBA
-- Returns true on success, false on timeout
local connected = connect(10)  -- 10 second timeout

if connected then
    print("Connected!", 10, 10)
else
    print("Connection failed", 10, 10)
end

-- During connect(), all other game logic blocks
-- Only connect() is a blocking call

-- When done playing, disconnect
disconnect()
```

The connect() function is the only blocking call in the multiplayer API. It will wait up to the specified timeout for a connection to be established. If you call connect() while already connected, it automatically calls disconnect() first.

### Sending and Receiving Messages

```lua
-- Send a message (max 11 bytes)
send("hello")          -- Send string
send("P1:MOVE:10,20")  -- Send structured data
send(string.char(1, 2, 3, 4))  -- Send binary data

-- Receive messages
local packet = recv()
while packet do
    -- packet is prefixed with sender ID: "1hello" or "2hello"
    local sender = string.sub(packet, 1, 1)
    local message = string.sub(packet, 2)
    
    if sender == "1" then
        -- Message from player 1
    elseif sender == "2" then
        -- Message from player 2
    end
    
    packet = recv()  -- Get next message
end
```

Messages have a maximum size of 11 bytes of data, plus 1 byte for the sender ID prefix. The first character of received messages indicates which device sent it: "1" for the first connected device, "2" for the second. Even with only two players, messages include this prefix for future compatibility with four-player support.

### Basic Multiplayer Example

```lua
-- Simple two-player position sync

-- Player state
local my_x = 120
local my_y = 80

function update_network()
    -- Send my position
    local msg = string.char(my_x) .. string.char(my_y)
    send(msg)
    
    -- Receive opponent position
    local pkt = recv()
    while pkt do
        opp_x = string.byte(pkt, 2)
        opp_y = string.byte(pkt, 3)
        pkt = recv()
    end
end

function draw_network()
    -- Draw opponent
    spr(1, opp_x, opp_y)
    
    -- Draw myself
    spr(0, my_x, my_y)
end
```

### Advanced Binary I/O

For performance-critical code, use send_iram() and recv_iram() to avoid string operations:

```lua
-- Using IRAM for faster packet handling
function sync_position()
    -- Pack position into IRAM
    poke(_IRAM, my_x)
    poke(_IRAM + 1, my_y)
    
    -- Send raw packet
    send_iram(_IRAM)
    
    -- Receive into IRAM
    if recv_iram(_IRAM) then
        local sender = peek(_IRAM)
        local their_x = peek(_IRAM + 1)
        local their_y = peek(_IRAM + 2)
        -- Process position
    end
end
```

This approach avoids string allocation in tight loops, which matters when sending frequent updates. The first byte in received IRAM packets is the sender ID, followed by up to 11 bytes of data.

## Program Structure

### Main Loop Pattern

The typical BPCore game follows an update-draw cycle:

```lua
-- Game variables
local x = 100
local y = 80
local speed = 2

function update(dt)
    -- Handle input
    if btn(4) then x = x - speed end  -- Left
    if btn(5) then x = x + speed end  -- Right
    if btn(6) then y = y - speed end  -- Up
    if btn(7) then y = y + speed end  -- Down
    
    -- Clamp to screen bounds
    if x < 0 then x = 0 end
    if x > 224 then x = 224 end
    if y < 0 then y = 0 end
    if y > 144 then y = 144 end
end

function draw()
    clear()
    spr(0, x, y)
    display()
end

-- Main loop
function main_loop()
    while true do
        update(delta())
        clear()
        draw()
    end
end

main_loop()
```

The game loop continuously calls update() with the time delta, clears the screen, draws all visible sprites, and displays them. Place all game logic in update() and all drawing in draw() for clean organization.

### Script Management

For games larger than available RAM, split your code into multiple scripts:

```lua
-- main.lua
local player_x = 100
local player_y = 100
local score = 0

-- Save state to IRAM for next script
poke4(_IRAM, player_x)
poke4(_IRAM + 4, player_y)
poke4(_IRAM + 8, score)

-- Store entities that need cleanup
local all_ents = ents()
poke4(_IRAM + 12, #all_ents)

-- Load next script
next_script("game.lua")
```

When calling next_script(), the current script finishes execution and the engine loads and runs the specified script. Scripts start with a clean slate—they have no access to the previous script's Lua variables. Use IRAM to pass data between scripts.

```lua
-- game.lua (continuing from main.lua)

-- Restore state from IRAM
local player_x = peek4(_IRAM)
local player_y = peek4(_IRAM + 4)
local score = peek4(_IRAM + 8)

-- Continue game...
```

Any entities created in the previous script persist in the engine, but your Lua variables do not. Use ents() to get the list of existing entities if you need to manage them across scripts.

### Including Shared Code

The dofile() function loads additional Lua files:

```lua
-- utils.lua
function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

function distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx*dx + dy*dy)
end
```

```lua
-- main.lua
dofile("utils.lua")

-- Now use functions from utils.lua
local x = clamp(player_x, 0, 224)
local dist = distance(player_x, player_y, enemy_x, enemy_y)
```

Unlike standard Lua dofile, the BPCore version does not return values. Place all your code in the loaded file at the top level (not inside functions) for it to execute. The dofile approach can reduce memory usage compared to having duplicate code in multiple scripts.

## System Functions

### Time and Timing

```lua
-- Get time since last call (in microseconds)
local dt = delta()

-- Sleep for N frames
sleep(60)  -- Sleep for 60 frames (about 1 second at 60fps)

-- Get startup time (if RTC hardware present)
local boot_time = startup_time()
-- Returns table: {year, month, day, hour, minute, second}
print("Booted: " .. boot_time.hour .. ":" .. boot_time.minute, 1, 1)
```

Use delta() to implement frame-rate independent movement. Multiply speeds by dt to ensure consistent movement regardless of actual frame rate. Note that delta() returns microseconds (1/1,000,000 second), so divide by a scaling factor:

```lua
local dt = delta() / 1000  -- Convert to milliseconds
local dt_seconds = delta() / 1000000  -- Convert to seconds

-- Frame-rate independent movement
x = x + velocity_x * (delta() / 10000)
```

### Watchdog

```lua
-- Feed the watchdog timer
fdog()

-- Not needed if calling clear() every frame
-- Manually feed when doing long operations without display
while loading do
    -- Long loading process
    fdog()  -- Prevent watchdog timeout
end
```

The watchdog timer reloads the ROM if the engine doesn't receive clear() and display() calls for more than 10 seconds. Most games don't need to manually call fdog() since they call clear() every frame anyway. However, during level loading or other operations that don't update the display, call fdog() periodically to prevent automatic reload.

### Debug Logging

```lua
-- Write to mGBA emulator's debug log
log("Player position: " .. x .. ", " .. y)
log("Score: " .. score)

-- Check engine version
print("BPCore version: " .. _BP_VERSION, 1, 1)
```

The log() function outputs to the mGBA emulator's logging window at debug severity. This is invaluable for debugging, especially for issues that are difficult to reproduce with visual debugging alone.

## Complete Example

Here is a complete, runnable game demonstrating many BPCore features:

```lua
-- Complete Example Game
-- A simple sprite that moves and collects items

-- Load graphics
txtr(4, "sprites.bmp")
txtr(2, "tiles.bmp")

-- Fill background with tile 1
for x = 0, 63 do
    for y = 0, 63 do
        tile(2, x, y, 1)
    end
end

-- Game state
local player = entpos(entspr(ent(), 0), 112, 72)
local score = 0
local items = {}

-- Create some collectible items
for i = 1, 5 do
    local item = entpos(entspr(ent(), 1), 
        math.random(20, 220), 
        math.random(20, 140))
    entag(item, 100)  -- Tag as collectible
    items[i] = item
end

-- Player speed
local speed = 2

function update(dt)
    -- Get current position
    local x, y = entpos(player)
    
    -- Movement
    if btn(4) then x = x - speed end
    if btn(5) then x = x + speed end
    if btn(6) then y = y - speed end
    if btn(7) then y = y + speed end
    
    -- Clamp to screen
    x = math.max(0, math.min(224, x))
    y = math.max(0, math.min(144, y))
    
    -- Update position
    entpos(player, x, y)
    
    -- Check collisions with items
    local collisions = ecoll(player, 100)
    for i = 1, #collisions do
        local item = collisions[i]
        
        -- Remove collected item
        for j = 1, #items do
            if items[j] == item then
                table.remove(items, j)
                break
            end
        end
        del(item)
        
        -- Increase score and play sound
        score = score + 10
        sound("coin.wav", 5)
    end
    
    -- Exit on Start
    if btnp(2) then
        -- Could call next_script here
    end
end

function draw()
    clear()
    
    -- Draw UI
    print("Score: " .. score, 1, 1, 0xFFFF, 0x0000)
    
    -- Items are automatically drawn (entities)
    -- Player is automatically drawn
    
    display()
end

-- Main loop
function main_loop()
    while true do
        update(delta())
        clear()
        draw()
    end
end

main_loop()
```

This example demonstrates entity creation, sprite assignment, movement, collision detection, scoring, and the game loop structure. Study it as a template for your own games.

## Best Practices

When developing with BPCore Engine, keep these guidelines in mind:

Resource Management is critical on the GBA. Always delete entities when no longer needed with del(). Avoid creating objects every frame—pool reusable entities instead. Monitor your memory usage with collectgarbage("count") and watch for leaks.

Performance Optimization matters significantly. The GBA has limited CPU power, so minimize calculations per frame. Use entities for persistent objects, sprites for transient effects. Call clear() and display() each frame but set up tiles only once during loading. Consider reducing frame rate with flimit(30) if needed.

Layer Management requires planning. Use the right layer IDs: 0=overlay, 1=tile_1, 2=tile_0, 3=background, 4=sprites. Remember tile layers are persistent while sprites must be redrawn each frame. Plan your graphics memory usage carefully.

Input Handling should use the right function for each purpose. Use btn() for continuous actions like movement, btnp() for triggered actions like jumping, and btnnp() for detecting releases.

Save Data should use appropriate memory. Use _IRAM for temporary data between scripts. Use _SRAM for persistent save games. Always check for valid save data before loading.

Multiplayer requires handling asynchronous communication. Don't assume messages arrive. Limit send() calls to avoid queue overflow. Implement reconciliation for important state.

The GBA is a constrained platform, and BPCore makes tradeoffs to enable Lua development. Keep your games focused and small. Complex games may exceed the platform's capabilities even with optimized Lua code.

## Additional Resources

For more information and example projects, see the official BPCore Engine repository at https://github.com/evanbowman/BPCore-Engine. The repository includes additional demo projects such as Meteorain (a puzzle game), HyperWing (a shoot-em-up boss rush), and various demonstration programs showing specific engine features.

When creating assets for your games, remember these technical requirements. Sprites must be 16x16 pixels, tiles must be 8x8 pixels. Audio must be mono 16kHz signed 8-bit PCM. Images should use indexed color with appropriate palettes. Tilemaps should be CSV format with comma delimiters.

This skill covers the complete BPCore Engine API. Refer to it when building your GBA games, and consult the official documentation for any recently added features or updates to existing functions.