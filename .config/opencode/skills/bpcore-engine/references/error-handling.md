# Error Handling

> This reference file is loaded on demand from ../SKILL.md

## Out-of-Bounds Detection

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

## Collision Safety

```lua
function safe_collision_check(e1, e2)
    if not e1 or not e2 then
        print("Invalid entity", 1, 1, 0xFFFF)
        return false
    end
    return eccole(e1, e2)
end
```

## Entity Pool Safety

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

## Multiplayer Safety

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

## Memory Bounds

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