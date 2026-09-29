# Networking Reference

This file is loaded on demand from `../SKILL.md` when you need detailed information about sockets and constants.

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