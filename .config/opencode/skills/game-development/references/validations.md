# Game Development - Validations

## Frame-Dependent Movement

### **Id**
game-frame-dependent
### **Severity**
warning
### **Type**
regex
### **Pattern**
\.x\s*\+=\s*\d+(?!\s*\*)|\.y\s*\+=\s*\d+(?!\s*\*)|position\s*\+=\s*\d+(?!\s*\*)|velocity\s*=\s*\d+(?!\s*\*.*delta)
### **Message**
Movement not multiplied by delta time. Will run at different speeds on different devices.
### **Fix Action**
Multiply by delta: this.x += speed * delta
### **Applies To**
  - *.ts
  - *.js

## Object Creation in Update Loop

### **Id**
game-new-in-update
### **Severity**
warning
### **Type**
regex
### **Pattern**
update\s*\([^)]*\)\s*\{[^}]*new\s+[A-Z]|tick\s*\([^)]*\)\s*\{[^}]*new\s+[A-Z]
### **Message**
Creating objects in update loop causes GC pauses. Use object pooling.
### **Fix Action**
Pre-allocate objects and use an object pool
### **Applies To**
  - *.ts
  - *.js

## Audio Fire and Forget

### **Id**
game-audio-fire-forget
### **Severity**
warning
### **Type**
regex
### **Pattern**
new Audio\(|Audio\(\)\.play
### **Message**
Creating new Audio objects. Use audio pooling for sound effects.
### **Fix Action**
Use an audio manager with pooled sounds
### **Applies To**
  - *.ts
  - *.js

## Boolean State Soup

### **Id**
game-boolean-state
### **Severity**
warning
### **Type**
regex
### **Pattern**
is[A-Z]\w+\s*&&.*is[A-Z]\w+\s*&&.*is[A-Z]|if\s*\(\s*!?is\w+\s*&&\s*!?is\w+\s*&&
### **Message**
Complex boolean state logic. Consider using a state machine.
### **Fix Action**
Implement state machine with explicit states and transitions
### **Applies To**
  - *.ts
  - *.js

## Hardcoded Key Codes

### **Id**
game-hardcoded-keys
### **Severity**
warning
### **Type**
regex
### **Pattern**
keyCode\s*===\s*\d+|key\s*===\s*["'][A-Za-z]["']|keyboard\.isDown\s*\(["']
### **Message**
Hardcoded key bindings. Abstract input for rebinding support.
### **Fix Action**
Use input manager with action mapping
### **Applies To**
  - *.ts
  - *.js

## Synchronous Asset Loading

### **Id**
game-sync-load
### **Severity**
warning
### **Type**
regex
### **Pattern**
loadSync\(|\.load\s*\([^)]*\)\s*;\s*\w+\s*=
### **Message**
Synchronous asset loading blocks the main thread.
### **Fix Action**
Use async loading with progress callback
### **Applies To**
  - *.ts
  - *.js

## Global Game State Access

### **Id**
game-global-state
### **Severity**
warning
### **Type**
regex
### **Pattern**
window\.game\.|global\.game\.|game\.player\.|game\.enemies
### **Message**
Direct global state access couples systems. Use events or dependency injection.
### **Fix Action**
Use event bus or pass dependencies explicitly
### **Applies To**
  - *.ts
  - *.js

## Update Without Delta Parameter

### **Id**
game-no-delta
### **Severity**
warning
### **Type**
regex
### **Pattern**
update\s*\(\s*\)\s*\{|tick\s*\(\s*\)\s*\{
### **Message**
Update function has no delta time parameter.
### **Fix Action**
Add delta parameter: update(delta) { ... }
### **Applies To**
  - *.ts
  - *.js

## Mouse-Only Input

### **Id**
game-mouse-only
### **Severity**
warning
### **Type**
regex
### **Pattern**
addEventListener\s*\(\s*['"]click['"](?![\s\S]*touch)|addEventListener\s*\(\s*['"]mousedown['"](?![\s\S]*touch)
### **Message**
Mouse-only input. Consider touch support for mobile.
### **Fix Action**
Add touch event handlers or use Pointer Events API
### **Applies To**
  - *.ts
  - *.js

## Magic Numbers in Game Logic

### **Id**
game-magic-numbers
### **Severity**
warning
### **Type**
regex
### **Pattern**
speed\s*=\s*\d{2,}|gravity\s*=\s*\d+|jumpForce\s*=\s*-?\d+
### **Message**
Magic numbers in game logic. Use named constants or config.
### **Fix Action**
Define constants: const PLAYER_SPEED = 300
### **Applies To**
  - *.ts
  - *.js

## Nested Entity Loops

### **Id**
game-nested-loops
### **Severity**
warning
### **Type**
regex
### **Pattern**
entities\.forEach.*entities\.forEach|for.*entities.*for.*entities
### **Message**
O(n²) entity iteration. Use spatial partitioning for collision.
### **Fix Action**
Implement spatial grid or quadtree for efficient lookups
### **Applies To**
  - *.ts
  - *.js

## Missing Event Cleanup

### **Id**
game-missing-cleanup
### **Severity**
warning
### **Type**
regex
### **Pattern**
addEventListener\([^)]*\)(?![\s\S]{0,200}removeEventListener)|\.on\([^)]*\)(?![\s\S]{0,200}\.off\()
### **Message**
Event listener without cleanup. Can cause memory leaks.
### **Fix Action**
Add cleanup in destroy/dispose method
### **Applies To**
  - *.ts
  - *.js

## Direct requestAnimationFrame

### **Id**
game-requestanimationframe
### **Severity**
info
### **Type**
regex
### **Pattern**
  - requestAnimationFrame\s*\(
### **Message**
Consider using game engine's built-in loop for delta time handling.
### **Fix Action**
Use engine's update loop if available
### **Applies To**
  - *.ts
  - *.js