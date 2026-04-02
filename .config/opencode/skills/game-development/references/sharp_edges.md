# Game Development - Sharp Edges

## Frame Rate Ignorance

### **Id**
frame-rate-ignorance
### **Summary**
Building game logic without considering frame rate independence
### **Severity**
critical
### **Situation**
Using frame count instead of delta time for movement and physics
### **Why**
  Game runs at different speeds on different devices. 60 FPS players move twice as
  fast as 30 FPS players. Physics becomes unpredictable. Multiplayer becomes impossible.
  
### **Solution**
  # WRONG: Frame-dependent movement
  function update() {
    player.x += 5  // Runs twice as fast at 60 FPS vs 30 FPS
  }
  
  # RIGHT: Frame-independent movement
  function update(delta) {
    const speed = 300  // Pixels per second
    player.x += speed * delta
  }
  
  # Fixed timestep for physics
  const FIXED_STEP = 1 / 60
  let accumulator = 0
  
  function update(delta) {
    accumulator += delta
    while (accumulator >= FIXED_STEP) {
      physicsStep(FIXED_STEP)
      accumulator -= FIXED_STEP
    }
  }
  
  # Test at different frame rates
  # Throttle to 30 FPS and verify behavior
  
### **Symptoms**
  - Movement without delta multiplication
  - Fixed values for position changes
  - Different behavior on different machines
  - Physics glitches at variable FPS
### **Detection Pattern**
\\.x\s*\+=\s*\d+(?!\s*\*)|velocity\s*=\s*\d+(?!\s*\*)

## Update Loop Bloat

### **Id**
update-loop-bloat
### **Summary**
Putting expensive operations in the update/tick loop
### **Severity**
critical
### **Situation**
Collision checks against every object, pathfinding every frame, allocations in update
### **Why**
  Frame rate tanks. Game becomes unplayable at scale. Mobile devices heat up and throttle.
  You've built something that only runs on developer machines.
  
### **Solution**
  # WRONG: O(n²) collision every frame
  function update() {
    for (const a of entities) {
      for (const b of entities) {
        checkCollision(a, b)
      }
    }
  }
  
  # RIGHT: Spatial partitioning
  const grid = new SpatialGrid(64)  // 64px cells
  
  function update() {
    grid.clear()
    entities.forEach(e => grid.insert(e))
  
    for (const entity of entities) {
      const nearby = grid.getNearby(entity)
      for (const other of nearby) {
        checkCollision(entity, other)
      }
    }
  }
  
  # Profile early and often
  # Object pooling instead of allocation
  # Spread expensive work across frames
  # Only update what changed
  
### **Symptoms**
  - Nested loops over all entities
  - New objects created in update
  - Pathfinding called every frame
  - Frame rate drops with more entities
### **Detection Pattern**
new\s+\w+\s*\(.*\).*update|forEach.*forEach

## State Machine Spaghetti

### **Id**
state-machine-spaghetti
### **Summary**
Managing game state with scattered booleans and conditionals
### **Severity**
high
### **Situation**
Complex conditionals like if (isJumping && !isDead && hasWeapon && ...)
### **Why**
  Impossible to reason about state. Bugs hide in edge cases. Adding features breaks
  existing behavior. State transitions become unpredictable.
  
### **Solution**
  # WRONG: Boolean soup
  if (isJumping && !isDead && hasWeapon && !isMenuOpen) { ... }
  
  # RIGHT: State machine
  const PlayerState = {
    IDLE: 'idle',
    RUNNING: 'running',
    JUMPING: 'jumping',
    FALLING: 'falling',
    DEAD: 'dead'
  }
  
  class Player {
    state = PlayerState.IDLE
  
    update(delta) {
      switch (this.state) {
        case PlayerState.IDLE:
          if (input.jump) this.transition(PlayerState.JUMPING)
          break
        case PlayerState.JUMPING:
          if (this.velocity.y > 0) this.transition(PlayerState.FALLING)
          break
      }
    }
  
    transition(newState) {
      this.onExit(this.state)
      this.state = newState
      this.onEnter(newState)
    }
  }
  
### **Symptoms**
  - Multiple boolean flags for state
  - Complex nested conditionals
  - Bugs when states conflict
  - Hard to add new states
### **Detection Pattern**
is[A-Z]\\w+\\s*&&.*is[A-Z]\\w+\\s*&&

## Input Handling Chaos

### **Id**
input-handling-chaos
### **Summary**
Checking input scattered throughout the codebase
### **Severity**
high
### **Situation**
Different systems reading input independently, raw input for game actions
### **Why**
  Input conflicts between systems. Can't rebind controls. Can't handle different input
  devices. Menu and gameplay fight for input.
  
### **Solution**
  # WRONG: Scattered input checks
  // In player.js
  if (keyboard.isDown('Space')) jump()
  
  // In menu.js
  if (keyboard.isDown('Space')) select()
  
  // In weapon.js
  if (keyboard.isDown('Space')) fire()
  
  # RIGHT: Centralized input manager
  class InputManager {
    bindings = {
      jump: ['Space', 'KeyW', 'GamepadA'],
      attack: ['KeyJ', 'GamepadX']
    }
  
    isPressed(action) {
      return this.bindings[action].some(key => this.keys.has(key))
    }
  
    // Context-aware
    setContext(context) {
      this.context = context  // 'gameplay', 'menu', 'dialogue'
    }
  }
  
  // Single point of input handling
  if (input.isPressed('jump') && input.context === 'gameplay') {
    player.jump()
  }
  
### **Symptoms**
  - Keyboard checks in multiple files
  - No way to rebind controls
  - Input conflicts between systems
  - Hardcoded key codes everywhere
### **Detection Pattern**
keyboard\\.isDown|keyCode\\s*===|key\\s*===\\s*["']

## Physics Tunneling

### **Id**
physics-tunneling
### **Summary**
Fast-moving objects passing through thin colliders
### **Severity**
high
### **Situation**
Bullet goes through wall, player falls through floor when moving fast
### **Why**
  Discrete collision detection. Object moves too far between frames. Collision is
  never detected. Core mechanics break at edge cases.
  
### **Solution**
  # Problem: Object moves from A to B, passing through wall
  
  Frame 1: [Bullet].......[Wall]
  Frame 2: [Wall].......[Bullet]  // Passed through!
  
  # Solutions:
  
  # 1. Continuous collision detection
  this.matter.body.setContinuousCollision(bullet, true)
  
  # 2. Sweep testing
  function moveSweep(entity, dx, dy) {
    const steps = Math.ceil(Math.max(Math.abs(dx), Math.abs(dy)))
    const stepX = dx / steps
    const stepY = dy / steps
  
    for (let i = 0; i < steps; i++) {
      entity.x += stepX
      entity.y += stepY
      if (checkCollision(entity)) {
        entity.x -= stepX
        entity.y -= stepY
        return true  // Hit something
      }
    }
    return false
  }
  
  # 3. Cap maximum velocity
  const MAX_SPEED = 500  // Never move more than this per second
  velocity.x = Math.min(velocity.x, MAX_SPEED)
  
  # 4. Thicken colliders for thin surfaces
  
### **Symptoms**
  - Bullets pass through walls
  - Player falls through floor
  - Fast objects miss collisions
  - Edge case physics bugs
### **Detection Pattern**


## Memory Leak Accumulation

### **Id**
memory-leak-accumulation
### **Summary**
Not properly destroying/disposing game objects
### **Severity**
high
### **Situation**
Event listeners not removed, textures not unloaded, references held after destroy
### **Why**
  Memory grows over time. Game crashes after extended play. Mobile runs out of memory.
  Performance degrades as session continues.
  
### **Solution**
  # WRONG: Create without cleanup
  class Enemy {
    constructor() {
      this.sprite = new Sprite()
      eventBus.on('playerDied', this.celebrate)
    }
    // No cleanup!
  }
  
  # RIGHT: Object pooling with explicit cleanup
  class EnemyPool {
    spawn() {
      const enemy = this.pool.pop() || new Enemy()
      enemy.init()
      return enemy
    }
  
    release(enemy) {
      enemy.cleanup()  // Remove listeners, reset state
      this.pool.push(enemy)
    }
  }
  
  class Enemy {
    init() {
      this.listener = () => this.celebrate()
      eventBus.on('playerDied', this.listener)
    }
  
    cleanup() {
      eventBus.off('playerDied', this.listener)
      this.sprite.visible = false
    }
  }
  
  # Test long play sessions
  # Monitor memory in profiler
  # Watch for growing object counts
  
### **Symptoms**
  - Memory grows during gameplay
  - Game slows after long sessions
  - Events fire on destroyed objects
  - Crash after extended play
### **Detection Pattern**
addEventListener(?![\\\\s\\\\S]*removeEventListener)|on\\([\\\\s\\\\S]*(?!off\\()

## Asset Loading Freeze

### **Id**
asset-loading-freeze
### **Summary**
Loading all assets synchronously at startup
### **Severity**
high
### **Situation**
Blocking the main thread during load, no loading feedback
### **Why**
  Long blank screen on startup. Browser may kill the tab. Players leave before game
  loads. Adding assets makes it worse.
  
### **Solution**
  # WRONG: Synchronous blocking load
  const allAssets = loadAll()  // Freezes for 10 seconds
  startGame()
  
  # RIGHT: Async with progress
  class AssetLoader {
    async loadAll(manifest, onProgress) {
      const total = manifest.length
      let loaded = 0
  
      await Promise.all(manifest.map(async (asset) => {
        await this.loadAsset(asset)
        loaded++
        onProgress(loaded / total)
      }))
    }
  }
  
  // Show loading screen
  const loader = new AssetLoader()
  loader.loadAll(manifest, (progress) => {
    loadingBar.width = progress * 100 + '%'
    loadingText.text = `Loading... ${Math.floor(progress * 100)}%`
  })
  
  # Lazy load non-critical assets
  # Preload only what's needed for first scene
  # Background loading during gameplay
  
### **Symptoms**
  - Blank screen on startup
  - No loading indicator
  - All assets loaded upfront
  - Long initial load times
### **Detection Pattern**
loadSync|load\\(.*\\)\\s*;\\s*start

## Audio Disaster

### **Id**
audio-disaster
### **Summary**
Not managing audio properly - sounds pile up and distort
### **Severity**
medium
### **Situation**
Sounds pile up, music and effects fight for volume, audio continues when paused
### **Why**
  Horrible audio experience. Volume spikes hurt players. Unprofessional feel.
  Audio continues during pause/menus.
  
### **Solution**
  # WRONG: Fire and forget audio
  function shoot() {
    new Audio('shoot.wav').play()  // Creates new audio each time
  }
  // 100 shots = 100 audio objects = distortion
  
  # RIGHT: Audio management
  class AudioManager {
    pools = new Map()
    volumes = { master: 1, sfx: 0.8, music: 0.5 }
  
    constructor() {
      this.context = new AudioContext()
    }
  
    playSfx(name, options = {}) {
      const pool = this.getPool(name)
      const sound = pool.find(s => !s.playing) || pool[0]
  
      sound.volume = this.volumes.master * this.volumes.sfx
      sound.play()
    }
  
    pause() {
      this.context.suspend()
    }
  
    resume() {
      this.context.resume()
    }
  }
  
  # Instance limits prevent pile-up
  # Category volumes (music, sfx, UI)
  # Audio responds to game state
  
### **Symptoms**
  - Audio distortion with many sounds
  - Audio plays during pause
  - No volume categories
  - Creating new Audio objects frequently
### **Detection Pattern**
new Audio\\(|Audio\\(\\).*\\.play

## Save System Afterthought

### **Id**
save-system-afterthought
### **Summary**
Adding save/load after the game is built
### **Severity**
high
### **Situation**
Saving game state that's scattered across systems, breaking saves with updates
### **Why**
  Extremely difficult to retrofit. Can't save all necessary state. Saves break between
  versions. Players lose progress.
  
### **Solution**
  # Design for serialization from the start
  
  # Centralized game state
  class GameState {
    version = 1
    player = { x: 0, y: 0, health: 100, inventory: [] }
    world = { level: 1, enemies: [], items: [] }
    progress = { achievements: [], unlocks: [] }
  
    serialize() {
      return JSON.stringify({
        version: this.version,
        player: this.player,
        world: this.world,
        progress: this.progress
      })
    }
  
    deserialize(data) {
      const parsed = JSON.parse(data)
      this.migrate(parsed)  // Handle version differences
      Object.assign(this, parsed)
    }
  
    migrate(data) {
      if (data.version < 2) {
        // Migration from v1 to v2
        data.player.stamina = 100
      }
    }
  }
  
  # Version your save format
  # Test save/load throughout development
  # Handle migration between versions
  
### **Symptoms**
  - State scattered across systems
  - No save versioning
  - Saves break after updates
  - Can't serialize game state
### **Detection Pattern**


## Scope Explosion

### **Id**
scope-explosion
### **Summary**
Adding features without cutting others
### **Severity**
critical
### **Situation**
"Just one more mechanic" without time adjustment
### **Why**
  Game never ships. Everything is half-done. Quality suffers. Team burns out.
  Project dies in development.
  
### **Solution**
  # The reality of game development
  Every feature you add:
  - Needs implementation
  - Needs testing
  - Needs balancing
  - Needs polish
  - Interacts with other features
  - Creates bugs
  
  # Ruthless scope management
  
  1. Define MVP that's actually minimum
     - What's the core loop?
     - What's the smallest playable version?
  
  2. Cut features, not quality
     - Better to have 3 polished features than 10 broken ones
  
  3. Playable at every stage
     - Always have a working build
     - Add features incrementally
  
  4. The 80/20 rule
     - 20% of features provide 80% of fun
     - Find your 20% and polish it
  
  # Ship something smaller that's polished
  # rather than something ambitious that's broken
  
### **Symptoms**
  - Feature list growing
  - Nothing fully polished
  - Release date slipping
  - Team burnout
### **Detection Pattern**


## Platform Assumption

### **Id**
platform-assumption
### **Summary**
Building only for your development environment
### **Severity**
high
### **Situation**
Mouse-only controls for touch game, no fallbacks for missing features
### **Why**
  Game doesn't work on target platform. Controls are wrong. Performance is terrible.
  You've built for yourself, not your players.
  
### **Solution**
  # Test on target devices early
  
  # Abstract platform-specific code
  class InputAdapter {
    constructor() {
      if ('ontouchstart' in window) {
        this.setupTouch()
      } else {
        this.setupMouse()
      }
    }
  }
  
  # Design for lowest common denominator
  # Minimum spec should be defined upfront
  
  # Performance budgets
  const BUDGET = {
    mobile: { drawCalls: 100, triangles: 10000 },
    desktop: { drawCalls: 500, triangles: 100000 }
  }
  
  # Handle different input methods
  - Keyboard + mouse
  - Touch only
  - Gamepad
  - Hybrid
  
  # Test early, test often on real devices
  
### **Symptoms**
  - Only tested on development machine
  - Hardcoded input assumptions
  - No mobile testing
  - Performance not measured on target
### **Detection Pattern**
addEventListener\(["']click|addEventListener\(["']mouse

## Hardcoded Dependencies

### **Id**
hardcoded-dependencies
### **Summary**
Systems tightly coupled with direct references
### **Severity**
medium
### **Situation**
Player directly accesses enemy list, UI directly reads game state
### **Why**
  Can't test in isolation. Changing one system breaks others. Can't add features
  without touching everything. Codebase becomes unmaintainable.
  
### **Solution**
  # WRONG: Direct coupling
  class Player {
    update() {
      for (const enemy of game.enemies) {  // Direct access
        if (this.collidesWith(enemy)) {
          game.ui.showDamage()  // Direct UI access
        }
      }
    }
  }
  
  # RIGHT: Event-driven communication
  class Player {
    update() {
      // Player only knows about collisions through events
      this.on('collision', (other) => {
        if (other.type === 'enemy') {
          this.emit('damaged', { amount: other.damage })
        }
      })
    }
  }
  
  class UI {
    constructor(eventBus) {
      eventBus.on('player:damaged', () => this.showDamage())
    }
  }
  
  # Dependency injection
  # Service locator pattern
  # Entity-component-system for complex games
  
### **Symptoms**
  - Global game object access
  - Direct system-to-system calls
  - Can't test components alone
  - Changes cascade through codebase
### **Detection Pattern**
game\\.|global\\.|window\\.game