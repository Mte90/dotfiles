# Optimization Patterns & Camera System

> This reference file is loaded on demand from ../SKILL.md

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