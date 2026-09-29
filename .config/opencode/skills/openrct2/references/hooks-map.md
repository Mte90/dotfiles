# Hooks and Map Access Reference

This reference file is loaded on demand from ../SKILL.md when hooks or map access details are needed.

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