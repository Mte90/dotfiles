# Network, Storage, Hot Reload, and Debugging Reference

This reference file is loaded on demand from ../SKILL.md when network, storage, or debugging details are needed.

## Network API

### Network Mode

```javascript
// Check network mode
if (network.mode === 'server') {
    console.log('Running as server');
} else if (network.mode === 'client') {
    console.log('Running as client');
} else {
    console.log('Single player');
}
```

### Player Management

```javascript
// Get all players
var players = network.players;
for (var i = 0; i < players.length; i++) {
    var player = players[i];
    console.log(player.name + ' (ID: ' + player.id + ')');
}

// Get specific player
var player = network.getPlayer(playerId);

// Player properties
console.log('Name: ' + player.name);
console.log('Group: ' + player.group);
console.log('Ping: ' + player.ping);

// Kick player
network.kickPlayer(playerId);

// Send message
network.sendMessage('Hello everyone!');
network.sendMessage('Private message', [playerId]);  // To specific player
```

### TCP Sockets

```javascript
// Create server (localhost only)
var server = network.createListener();
server.on('connection', function(conn) {
    console.log('Client connected');
    
    conn.on('data', function(data) {
        console.log('Received: ' + data);
        conn.write('Echo: ' + data);
    });
    
    conn.on('close', function() {
        console.log('Client disconnected');
    });
});

server.listen(8080, function() {
    console.log('Server listening on port 8080');
});

// Create client
var client = network.createSocket();
client.on('connect', function() {
    console.log('Connected to server');
    client.write('Hello from OpenRCT2');
});

client.on('data', function(data) {
    console.log('Server says: ' + data);
});

client.connect(8080, 'localhost');
```

## Data Persistence

### Shared Storage

```javascript
// Persistent across all parks (plugin.store.json)
var myData = context.sharedStorage.get('myplugin.data', { defaultValue: 0 });
context.sharedStorage.set('myplugin.data', myData + 1);

// Namespaced keys recommended
context.sharedStorage.set('MyPlugin.Settings.Enabled', true);
context.sharedStorage.set('MyPlugin.Settings.Volume', 0.8);
```

### Park Storage

```javascript
// Saved with the park file
var parkData = context.getParkStorage('myplugin');
var counter = parkData.get('counter', 0);
parkData.set('counter', counter + 1);
```

## Hot Reload

### Enable Hot Reload

Edit `config.ini`:
```ini
[plugin]
enable_hot_reloading = true
```

### Development Workflow

```javascript
// Plugin with auto-reload support
var window = null;

function main() {
    console.log('Plugin loaded/reloaded!');
    
    // Close old window on reload
    if (window) {
        window.close();
    }
    
    // Create new window
    openWindow();
}

function openWindow() {
    window = ui.openWindow({
        classification: 'myplugin.dev',
        title: 'Dev Window',
        width: 200,
        height: 100,
        widgets: [
            {
                type: 'label',
                x: 10, y: 10,
                width: 180, height: 80,
                text: 'Edit and save JS to reload!'
            }
        ]
    });
}
```

## Debugging

### Console Logging

```javascript
// Basic logging
console.log('Debug message');
console.log('Value: ' + value);

// Object inspection
console.log(JSON.stringify(obj));
```

### REPL Console

Run `openrct2.com` (Windows) or terminal version to access interactive console.

```javascript
// In console, test expressions
> park.cash
> map.rides.length
> context.sharedStorage.get('myplugin.data')
```