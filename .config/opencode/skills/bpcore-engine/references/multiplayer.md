# Multiplayer Link Cable Protocol

> This reference file is loaded on demand from ../SKILL.md

## Hardware

Two GBA systems connect via link cable on right side of cartridge.

## Communication

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

## Packet Format

```
[Sender ID (1 byte)][Data (up to 10 bytes)]
[Total: 11 bytes max]

Examples:
  "1HELLO" = Player 1 sent
  "2WORLD" = Player 2 sent
```

## Connection Management

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

## Sending & Receiving

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

## Basic Example

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

## Binary I/O (Fast)

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

## Synchronization

### Client-Server Model

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

### Lerp/Interpolation

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