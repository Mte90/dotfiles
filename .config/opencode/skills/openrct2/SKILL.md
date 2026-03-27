---
name: openrct2-plugin
description: "Develop plugins for OpenRCT2 - JavaScript/TypeScript scripting, game actions, UI windows, hooks, multiplayer sync"
metadata:
  author: "OSS AI Skills"
  version: "1.0.0"
  tags:
    - openrct2
    - plugin
    - javascript
    - typescript
    - game-modding
    - rollercoaster-tycoon
    - scripting
---

# OpenRCT2 Plugin Development

Comprehensive guide for developing plugins (scripts) for OpenRCT2, the open-source re-implementation of RollerCoaster Tycoon 2.

## Overview

OpenRCT2 allows custom scripts (plugins) written in JavaScript/TypeScript to extend the game with additional behavior - from extra windows to entire multiplayer game modes.

### Key Features

- **JavaScript/TypeScript** - ES5 compatible, transpilers for ES6+
- **Game Actions** - Safe multiplayer-synchronized state mutations
- **UI Windows** - Custom windows with widgets
- **Hooks** - Subscribe to game events
- **Network API** - TCP sockets for localhost communication
- **Hot Reload** - Real-time plugin development

### Plugin Directory

Place `.js` files in the `plugin` directory:

- **Windows**: `C:\Users\YourName\Documents\OpenRCT2\plugin\`
- **Mac**: `/Users/YourName/Library/Application Support/OpenRCT2/plugin/`
- **Linux**: `$XDG_CONFIG_HOME/OpenRCT2/plugin/` or `$HOME/.config/OpenRCT2/plugin/`

Access via game: **Red toolbox button → Open custom content folder**

## Plugin Template

### Basic Plugin Structure

```javascript
function main() {
    console.log("Your plugin has started!");
    
    // Your plugin code here
}

registerPlugin({
    name: 'Your Plugin',
    version: '1.0',
    authors: ['Your Name'],
    type: 'remote',
    licence: 'MIT',
    targetApiVersion: 34,
    minApiVersion: 10,
    main: main
});
```

### TypeScript Setup

```typescript
// Install TypeScript and types
// npm install typescript --save-dev
// Copy openrct2.d.ts to your project

/// <reference path="openrct2.d.ts" />

function main() {
    console.log("TypeScript plugin loaded!");
}

registerPlugin({
    name: 'My TypeScript Plugin',
    version: '1.0',
    authors: ['Developer'],
    type: 'local',
    licence: 'MIT',
    targetApiVersion: 34,
    main: main
});
```

### tsconfig.json

```json
{
    "compilerOptions": {
        "target": "ES5",
        "module": "none",
        "outFile": "./dist/plugin.js",
        "strict": true,
        "esModuleInterop": true,
        "skipLibCheck": true
    },
    "include": ["src/**/*"],
    "exclude": ["node_modules"]
}
```

## Plugin Types

### Local Plugins

Load on any client with plugin installed. Cannot alter game state directly.

```javascript
registerPlugin({
    name: 'Local Info Plugin',
    version: '1.0',
    type: 'local',  // Available to all players in multiplayer
    // ...
    main: function() {
        // Can only use game actions, not direct mutations
        // Good for: info windows, tools, dashboards
    }
});
```

### Remote Plugins

Load only on server, distributed to clients. Can mutate game state in execute context.

```javascript
registerPlugin({
    name: 'Remote Game Plugin',
    version: '1.0',
    type: 'remote',  // Server-side, synced to clients
    // ...
    main: function() {
        // Can mutate game state in custom game action execute()
    }
});
```

### Intransient Plugins

Stay loaded across park changes and in title screen.

```javascript
registerPlugin({
    name: 'Global Plugin',
    version: '1.0',
    type: 'intransient',  // Never unloaded
    // ...
    main: function() {
        // Active in title screen and across parks
        // Use context.sharedStorage for persistence
    }
});
```

## Game Actions

Game actions are the **recommended way** to mutate game state, ensuring multiplayer synchronization.

### Using Built-in Game Actions

```javascript
// Place scenery using game action
var action = {
    type: 'smallsceneryplace',
    args: {
        object: 0,           // Scenery object ID
        x: 32 * 10,          // X coordinate in map units
        y: 32 * 10,          // Y coordinate in map units
        z: 0,                // Z height
        direction: 0,        // Rotation (0-3)
        quadrant: 0,         // Quadrant for quarter tile scenery
        primaryColour: 0,    // Primary color
        secondaryColour: 0   // Secondary color
    }
};

context.executeAction(action, function(result) {
    if (result.error) {
        console.log("Failed to place scenery: " + result.error);
    } else {
        console.log("Scenery placed successfully");
    }
});
```

### Common Built-in Actions

```javascript
// Set park cash
context.executeAction({
    type: 'parksetcash',
    args: { cash: 100000 }
}, callback);

// Set guest count
context.executeAction({
    type: 'parksetguestgenerationrate',
    args: { generationRate: 100 }
}, callback);

// Change land height
context.executeAction({
    type: 'landsetheight',
    args: {
        x: 32 * 10,
        y: 32 * 10,
        height: 10
    }
}, callback);

// Build ride
context.executeAction({
    type: 'trackplace',
    args: {
        ride: 0,
        trackType: 1,
        x: 32 * 10,
        y: 32 * 10,
        z: 0,
        direction: 0
    }
}, callback);
```

### Custom Game Actions

```javascript
// Register custom action
context.registerAction({
    id: 'myplugin.award_cash',
    query: function(args) {
        // Validation - return error object if invalid
        if (args.amount < 0) {
            return { error: 'Amount must be positive' };
        }
        if (args.amount > 100000) {
            return { error: 'Amount too large' };
        }
        return {};  // Success
    },
    execute: function(args) {
        // Actual game state mutation - only runs on server
        park.cash += args.amount;
        return {};  // Success
    }
});

// Use custom action
context.executeAction({
    type: 'myplugin.award_cash',
    args: { amount: 5000 }
}, function(result) {
    console.log(result.error || "Cash awarded!");
});
```

### Permission Checks

```javascript
context.registerAction({
    id: 'myplugin.admin_action',
    query: function(args) {
        // Check player permissions
        if (network.mode !== 'none') {
            var player = network.getPlayer(args.playerId);
            if (!player || !player.hasPermission('modify_park')) {
                return { error: 'No permission' };
            }
        }
        return {};
    },
    execute: function(args) {
        // Perform action
    }
});
```

## UI Development

### Check UI Availability

```javascript
// Always check before using UI APIs (for headless servers)
if (typeof ui !== 'undefined') {
    // UI is available
    ui.registerMenuItem('My Window', openWindow);
}
```

### Menu Integration

```javascript
function main() {
    if (typeof ui === 'undefined') return;
    
    // Add menu item
    ui.registerMenuItem('My Plugin', function() {
        openMainWindow();
    });
    
    // Add to specific menu tab
    ui.registerMenuItem('Ride Stats', function() {
        openRideStatsWindow();
    }, 'ride');  // 'map', 'park', 'ride', 'guest', etc.
}
```

### Window Creation

```javascript
function openMainWindow() {
    var window = ui.openWindow({
        classification: 'myplugin.main',
        title: 'My Plugin Window',
        width: 300,
        height: 200,
        widgets: [
            // Label
            {
                type: 'label',
                x: 10,
                y: 10,
                width: 280,
                height: 20,
                text: 'Hello, OpenRCT2!'
            },
            // Button
            {
                type: 'button',
                x: 10,
                y: 40,
                width: 120,
                height: 30,
                text: 'Click Me',
                onClick: function() {
                    console.log('Button clicked!');
                }
            },
            // Checkbox
            {
                type: 'checkbox',
                x: 10,
                y: 80,
                width: 200,
                height: 20,
                text: 'Enable feature',
                isChecked: false,
                onChange: function(checked) {
                    console.log('Checkbox: ' + checked);
                }
            },
            // Dropdown
            {
                type: 'dropdown',
                x: 10,
                y: 110,
                width: 200,
                height: 20,
                items: ['Option 1', 'Option 2', 'Option 3'],
                selectedIndex: 0,
                onChange: function(index) {
                    console.log('Selected: ' + index);
                }
            },
            // Slider
            {
                type: 'slider',
                x: 10,
                y: 140,
                width: 200,
                height: 20,
                minValue: 0,
                maxValue: 100,
                value: 50,
                onChange: function(value) {
                    console.log('Slider: ' + value);
                }
            },
            // Spinner
            {
                type: 'spinner',
                x: 10,
                y: 170,
                width: 100,
                height: 20,
                text: '10',
                onDecrement: function() {
                    // Handle decrement
                },
                onIncrement: function() {
                    // Handle increment
                }
            }
        ]
    });
    
    return window;
}
```

### ListView Widget

```javascript
{
    type: 'listview',
    x: 10,
    y: 10,
    width: 280,
    height: 150,
    scrollbars: 'vertical',
    isStriped: true,
    showColumnHeaders: true,
    columns: [
        { header: 'Name', width: 150 },
        { header: 'Value', width: 80 },
        { header: 'Status', width: 50 }
    ],
    items: [
        ['Ride 1', '$5000', 'OK'],
        ['Ride 2', '$3000', 'OK'],
        ['Ride 3', '$2000', 'Low']
    ],
    onHighlight: function(item, column) {
        console.log('Highlighted: ' + item + ', ' + column);
    },
    onClick: function(item, column) {
        console.log('Clicked: ' + item + ', ' + column);
    }
}
```

### GroupBox Widget

```javascript
{
    type: 'groupbox',
    x: 10,
    y: 10,
    width: 280,
    height: 100,
    text: 'Settings',
    widgets: [
        {
            type: 'checkbox',
            x: 10,
            y: 20,
            width: 260,
            height: 20,
            text: 'Enable notifications'
        },
        {
            type: 'checkbox',
            x: 10,
            y: 45,
            width: 260,
            height: 20,
            text: 'Auto-save'
        }
    ]
}
```

### Tab Window

```javascript
function openTabWindow() {
    var window = ui.openWindow({
        classification: 'myplugin.tabs',
        title: 'Tabbed Window',
        width: 400,
        height: 300,
        tabs: [
            {
                image: 5221,  // Icon ID
                widgets: [
                    {
                        type: 'label',
                        x: 10, y: 10,
                        width: 380, height: 20,
                        text: 'Tab 1 Content'
                    }
                ]
            },
            {
                image: 5222,
                widgets: [
                    {
                        type: 'label',
                        x: 10, y: 10,
                        width: 380, height: 20,
                        text: 'Tab 2 Content'
                    }
                ]
            }
        ]
    });
}
```

### Window Events

```javascript
var window = ui.openWindow({ /* ... */ });

window.onClose = function() {
    console.log('Window closed');
    // Cleanup
};
```

## Hooks (Events)

### Interval Hooks

```javascript
// Every game tick (40ms)
context.subscribe('interval.tick', function() {
    // Runs 25 times per second
});

// Every game day
context.subscribe('interval.day', function() {
    console.log('New day! Cash: ' + park.cash);
    // Award daily bonus
    park.cash += 1000;
});

// Every in-game hour
context.subscribe('interval.hour', function() {
    // Hourly updates
});
```

### Ride Hooks

```javascript
// Ride created
context.subscribe('ride.ratings.calculate', function(e) {
    var ride = map.getRide(e.rideId);
    console.log('Ride ratings calculated: ' + ride.name);
});

// Ride crashed
context.subscribe('ride.crashed', function(e) {
    console.log('Ride ' + e.rideId + ' crashed!');
});
```

### Guest Hooks

```javascript
// Guest entered park
context.subscribe('guest.entered_park', function(e) {
    var guest = map.getEntity(e.entityId);
    console.log('Guest ' + guest.id + ' entered park');
});

// Guest left park
context.subscribe('guest.left_park', function(e) {
    console.log('Guest left: ' + e.entityId);
});

// Guest bought item
context.subscribe('guest.bought_item', function(e) {
    console.log('Guest bought item: ' + e.item);
});
```

### Network Hooks

```javascript
// Chat message received
context.subscribe('network.chat', function(e) {
    console.log(e.playerName + ': ' + e.message);
    
    // Anti-spam example
    if (e.message.length > 200) {
        network.kickPlayer(e.playerId);
    }
});

// Player joined
context.subscribe('network.join', function(e) {
    console.log('Player joined: ' + e.playerName);
    
    // Welcome message
    network.sendMessage('Welcome to the server, ' + e.playerName + '!');
});

// Player left
context.subscribe('network.leave', function(e) {
    console.log('Player left: ' + e.playerName);
});
```

### Action Hooks

```javascript
// Before action executes
context.subscribe('action.query', function(e) {
    if (e.action === 'ridesetstatus') {
        console.log('Ride status changing...');
    }
});

// After action executes
context.subscribe('action.execute', function(e) {
    if (e.action === 'ridesetstatus') {
        console.log('Ride status changed');
    }
});
```

## Park and Map Access

### Park Information

```javascript
// Park stats
console.log('Park name: ' + park.name);
console.log('Cash: $' + park.cash);
console.log('Rating: ' + park.rating);
console.log('Guests: ' + park.guests);
console.log('Value: $' + park.value);
console.log('Company value: $' + park.companyValue);

// Park flags
if (park.getFlag('noMoney')) {
    console.log('Park has no money');
}

// Modify park (remote plugin only)
park.cash = 100000;
park.name = "My Awesome Park";
```

### Map Access

```javascript
// Get map size
var mapSize = map.size;
console.log('Map size: ' + mapSize.x + 'x' + mapSize.y);

// Iterate all tiles
for (var x = 0; x < map.size.x; x++) {
    for (var y = 0; y < map.size.y; y++) {
        var tile = map.getTile(x, y);
        // Process tile
    }
}

// Get tile at coordinates
var tile = map.getTile(10, 10);

// Tile elements
for (var i = 0; i < tile.numElements; i++) {
    var element = tile.getElement(i);
    
    if (element.type === 'surface') {
        console.log('Surface at ' + element.baseHeight);
    } else if (element.type === 'track') {
        console.log('Track element');
    } else if (element.type === 'small_scenery') {
        console.log('Small scenery');
    }
}
```

### Rides

```javascript
// Get all rides
var rides = map.rides;
for (var i = 0; i < rides.length; i++) {
    var ride = rides[i];
    console.log(ride.name + ' - Excitement: ' + ride.excitement);
}

// Get specific ride
var ride = map.getRide(0);

// Ride properties
console.log('Type: ' + ride.type);
console.log('Status: ' + ride.status);
console.log('Excitement: ' + ride.excitement);
console.log('Intensity: ' + ride.intensity);
console.log('Nausea: ' + ride.nausea);
console.log('Price: $' + ride.price);
console.log('Customers: ' + ride.customers);

// Modify ride (remote only)
ride.price = 500;  // $5.00
ride.name = "Super Coaster";
```

### Entities (Guests and Staff)

```javascript
// Get all entities
var entities = map.entities;

// Iterate guests
for (var i = 0; i < entities.length; i++) {
    var entity = entities[i];
    
    if (entity.type === 'guest') {
        console.log('Guest ' + entity.id);
        console.log('  Cash: $' + entity.cash);
        console.log('  Happiness: ' + entity.happiness);
        console.log('  Energy: ' + entity.energy);
        console.log('  Hunger: ' + entity.hunger);
        console.log('  Thirst: ' + entity.thirst);
    } else if (entity.type === 'staff') {
        console.log('Staff ' + entity.id);
        console.log('  Type: ' + entity.staffType);
    }
}

// Get specific entity
var guest = map.getEntity(entityId);

// Modify guest (remote only)
guest.happiness = 200;
guest.energy = 150;
guest.cash = 500;
```

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

## Best Practices

### 1. Check UI Availability

```javascript
// Good: Check before UI operations
function main() {
    if (typeof ui !== 'undefined') {
        ui.registerMenuItem('My Window', openWindow);
    }
    
    // Non-UI code runs everywhere
    context.subscribe('interval.day', onDay);
}
```

### 2. Use Game Actions for Mutations

```javascript
// Good: Use game action
context.executeAction({
    type: 'parksetcash',
    args: { cash: 100000 }
}, callback);

// Bad: Direct mutation in local plugin
// park.cash = 100000;  // Will fail in multiplayer!
```

### 3. Namespace Your Data

```javascript
// Good: Use namespace prefix
context.sharedStorage.set('MyPlugin.Key', value);

// Bad: Generic key may conflict
context.sharedStorage.set('data', value);
```

### 4. Handle Errors

```javascript
context.executeAction(action, function(result) {
    if (result.error) {
        console.log('Action failed: ' + result.error);
        return;
    }
    // Success handling
});
```

### 5. Clean Up on Unload

```javascript
var intervals = [];

function main() {
    intervals.push(context.setInterval(update, 1000));
}

// For remote/intransient plugins
context.subscribe('map.changed', function() {
    // Clear intervals when map changes
    intervals.forEach(clearInterval);
    intervals = [];
});
```

## ES5 Limitations

OpenRCT2 uses Duktape (ES5). ES6+ features require transpilation:

### Not Supported

```javascript
// Arrow functions
var func = () => {};  // NO

// Classes
class MyClass {}  // NO

// let/const
let x = 1;  // NO

// Template literals
`Hello ${name}`  // NO

// Spread operator
[...arr]  // NO

// Destructuring
var { x } = obj;  // NO

// find/includes
arr.find(x => x > 0);  // NO
arr.includes(5);  // NO
```

### ES5 Alternatives

```javascript
// Function expressions
var func = function() {};  // YES

// Constructor functions
function MyClass() {}  // YES

// var
var x = 1;  // YES

// String concatenation
'Hello ' + name  // YES

// Array methods
arr.filter(function(x) { return x > 0; })[0];  // YES
arr.indexOf(5) !== -1;  // YES
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

## Distribution

### Publishing

1. **GitHub Releases** - Recommended, attach compiled `.js`
2. **openrct2plugins.org** - Community plugin repository

### Versioning

```javascript
registerPlugin({
    name: 'My Plugin',
    version: '1.2.3',  // Semantic versioning
    minApiVersion: 34,  // Minimum OpenRCT2 API version
    targetApiVersion: 34,  // Target API for behavior
    // ...
});
```

## References

- **OpenRCT2 Scripting Docs**: https://github.com/OpenRCT2/OpenRCT2/blob/develop/distribution/scripting.md
- **API Types**: https://github.com/OpenRCT2/OpenRCT2/blob/develop/distribution/openrct2.d.ts
- **Plugin Samples**: https://github.com/OpenRCT2/plugin-samples
- **Community Plugins**: https://openrct2plugins.org/
- **Duktape Engine**: https://duktape.org/
