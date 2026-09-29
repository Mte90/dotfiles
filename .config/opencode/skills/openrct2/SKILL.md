---
name: openrct2
description: Use when developing OpenRCT2 plugins in TypeScript - plugin registration and game actions, window and widget UI, event hooks, park, map, ride and entity access, network API, storage, or ES5 runtime constraints
metadata:
  author: mte90
  version: 2.0.0
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

Develop plugins (scripts) for OpenRCT2 using JavaScript/TypeScript to extend the game with custom windows, game actions, event hooks, and multiplayer features.

## Overview

OpenRCT2 plugins run in Duktape (ES5 runtime). Key capabilities:

- **JavaScript/TypeScript** - ES5 compatible, use transpilers for ES6+
- **Game Actions** - Multiplayer-synchronized state mutations
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
    args: { x: 32 * 10, y: 32 * 10, height: 10 }
}, callback);

// Build ride
context.executeAction({
    type: 'trackplace',
    args: { ride: 0, trackType: 1, x: 32 * 10, y: 32 * 10, z: 0, direction: 0 }
}, callback);
```

### Custom Game Actions

```javascript
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

## Best Practices

### 1. Check UI Availability

```javascript
function main() {
    if (typeof ui !== 'undefined') {
        ui.registerMenuItem('My Window', openWindow);
    }
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

Use namespaced keys to avoid conflicts. See `references/network-storage.md` for full storage API details.

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

context.subscribe('map.changed', function() {
    intervals.forEach(clearInterval);
    intervals = [];
});
```

## ES5 Limitations

OpenRCT2 uses Duktape (ES5). ES6+ features require transpilation.

### Not Supported

```javascript
// Arrow functions - NO
var func = () => {};

// Classes - NO
class MyClass {}

// let/const - NO
let x = 1;

// Template literals - NO
`Hello ${name}`

// Spread operator - NO
[...arr]

// Destructuring - NO
var { x } = obj;

// find/includes - NO
arr.find(x => x > 0);
arr.includes(5);
```

### ES5 Alternatives

```javascript
// Function expressions - YES
var func = function() {};

// Constructor functions - YES
function MyClass() {}

// var - YES
var x = 1;

// String concatenation - YES
'Hello ' + name

// Array methods - YES
arr.filter(function(x) { return x > 0; })[0];
arr.indexOf(5) !== -1;
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
});
```

## Deep Dives

Load these reference files on demand for detailed API information:

- **UI Development** - Window creation, widgets (ListView, GroupBox, tabs), events → `references/ui.md`
- **Hooks and Map Access** - Event subscriptions, park info, map tiles, rides, entities → `references/hooks-map.md`
- **Network, Storage, Hot Reload, Debugging** - TCP sockets, storage APIs, development workflow → `references/network-storage.md`

## References

- **OpenRCT2 Scripting Docs**: https://github.com/OpenRCT2/OpenRCT2/blob/develop/distribution/scripting.md
- **API Types**: https://github.com/OpenRCT2/OpenRCT2/blob/develop/distribution/openrct2.d.ts
- **Plugin Samples**: https://github.com/OpenRCT2/plugin-samples
- **Community Plugins**: https://openrct2plugins.org/
- **Duktape Engine**: https://duktape.org/