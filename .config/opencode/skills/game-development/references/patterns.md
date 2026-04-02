# Game Development

## Patterns


---
  #### **Name**
Delta Time Movement
  #### **Description**
All movement and physics multiplied by time since last frame
  #### **When**
Implementing any movement, physics, or time-based logic
  #### **Example**
    // WRONG: Frame-dependent movement
    function update() {
      player.x += 5  // Runs twice as fast at 60 FPS vs 30 FPS
    }
    
    // RIGHT: Frame-independent movement
    function update(delta) {
      const speed = 300  // Pixels per second
      player.x += speed * delta  // Same speed at any frame rate
    }
    
    // Phaser example
    update(time, delta) {
      // delta is in milliseconds, convert to seconds
      const dt = delta / 1000
      this.player.x += this.velocity.x * dt
      this.player.y += this.velocity.y * dt
    }
    
    // Fixed timestep for physics (advanced)
    const FIXED_STEP = 1 / 60
    let accumulator = 0
    
    function update(delta) {
      accumulator += delta
      while (accumulator >= FIXED_STEP) {
        physicsStep(FIXED_STEP)
        accumulator -= FIXED_STEP
      }
      render(accumulator / FIXED_STEP)  // Interpolate
    }
    

---
  #### **Name**
State Machine
  #### **Description**
Explicit states with defined transitions instead of scattered booleans
  #### **When**
Managing entity states like player actions, game phases, or AI
  #### **Example**
    // WRONG: Boolean soup
    if (isJumping && !isDead && hasWeapon && !isMenuOpen) { ... }
    
    // RIGHT: State machine
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
            if (input.horizontal) this.transition(PlayerState.RUNNING)
            break
          case PlayerState.JUMPING:
            this.velocity.y += GRAVITY * delta
            if (this.velocity.y > 0) this.transition(PlayerState.FALLING)
            break
          // ... other states
        }
      }
    
      transition(newState) {
        this.onExit(this.state)
        this.state = newState
        this.onEnter(newState)
      }
    }
    

---
  #### **Name**
Object Pooling
  #### **Description**
Reuse objects instead of creating/destroying frequently
  #### **When**
Spawning bullets, particles, enemies, or any frequently created objects
  #### **Example**
    class BulletPool {
      constructor(size) {
        this.pool = []
        this.active = []
    
        for (let i = 0; i < size; i++) {
          this.pool.push(new Bullet())
        }
      }
    
      spawn(x, y, direction) {
        // Get from pool or create new
        const bullet = this.pool.pop() || new Bullet()
        bullet.init(x, y, direction)
        this.active.push(bullet)
        return bullet
      }
    
      release(bullet) {
        bullet.reset()
        const index = this.active.indexOf(bullet)
        if (index !== -1) {
          this.active.splice(index, 1)
          this.pool.push(bullet)
        }
      }
    
      update(delta) {
        for (let i = this.active.length - 1; i >= 0; i--) {
          const bullet = this.active[i]
          bullet.update(delta)
          if (bullet.isDead) {
            this.release(bullet)
          }
        }
      }
    }
    

---
  #### **Name**
Spatial Partitioning
  #### **Description**
Divide space into regions for efficient collision detection
  #### **When**
Many objects need collision checks, performance is critical
  #### **Example**
    // Simple grid-based spatial hash
    class SpatialGrid {
      constructor(cellSize) {
        this.cellSize = cellSize
        this.cells = new Map()
      }
    
      getKey(x, y) {
        const cellX = Math.floor(x / this.cellSize)
        const cellY = Math.floor(y / this.cellSize)
        return `${cellX},${cellY}`
      }
    
      insert(entity) {
        const key = this.getKey(entity.x, entity.y)
        if (!this.cells.has(key)) {
          this.cells.set(key, [])
        }
        this.cells.get(key).push(entity)
      }
    
      getNearby(entity) {
        const nearby = []
        const key = this.getKey(entity.x, entity.y)
        // Check adjacent cells
        for (let dx = -1; dx <= 1; dx++) {
          for (let dy = -1; dy <= 1; dy++) {
            const checkKey = this.getKey(
              entity.x + dx * this.cellSize,
              entity.y + dy * this.cellSize
            )
            if (this.cells.has(checkKey)) {
              nearby.push(...this.cells.get(checkKey))
            }
          }
        }
        return nearby
      }
    }
    

---
  #### **Name**
Input Abstraction
  #### **Description**
Separate input reading from game actions
  #### **When**
Handling player input across different devices or allowing rebinding
  #### **Example**
    // Input manager abstracts devices
    class InputManager {
      actions = new Map()
    
      constructor() {
        this.bindings = {
          jump: ['Space', 'KeyW', 'GamepadA'],
          left: ['KeyA', 'ArrowLeft', 'GamepadLeftStickLeft'],
          right: ['KeyD', 'ArrowRight', 'GamepadLeftStickRight'],
          attack: ['KeyJ', 'GamepadX']
        }
    
        window.addEventListener('keydown', e => this.onKeyDown(e))
        window.addEventListener('keyup', e => this.onKeyUp(e))
      }
    
      onKeyDown(e) {
        for (const [action, keys] of Object.entries(this.bindings)) {
          if (keys.includes(e.code)) {
            this.actions.set(action, true)
          }
        }
      }
    
      isPressed(action) {
        return this.actions.get(action) ?? false
      }
    
      // Input buffering for responsive controls
      buffer = []
      bufferAction(action, duration = 100) {
        this.buffer.push({ action, expires: Date.now() + duration })
      }
    
      consumeBuffered(action) {
        const now = Date.now()
        const index = this.buffer.findIndex(
          b => b.action === action && b.expires > now
        )
        if (index !== -1) {
          this.buffer.splice(index, 1)
          return true
        }
        return false
      }
    }
    

---
  #### **Name**
Component Entity System
  #### **Description**
Composition over inheritance for game entities
  #### **When**
Building complex games with many entity types and behaviors
  #### **Example**
    // Components are pure data
    class Position { constructor(x, y) { this.x = x; this.y = y } }
    class Velocity { constructor(x, y) { this.x = x; this.y = y } }
    class Sprite { constructor(texture) { this.texture = texture } }
    class Health { constructor(max) { this.current = max; this.max = max } }
    
    // Entities are just IDs with components
    class Entity {
      static nextId = 0
      id = Entity.nextId++
      components = new Map()
    
      add(component) {
        this.components.set(component.constructor, component)
        return this
      }
    
      get(type) {
        return this.components.get(type)
      }
    
      has(type) {
        return this.components.has(type)
      }
    }
    
    // Systems process entities with specific components
    class MovementSystem {
      update(entities, delta) {
        for (const entity of entities) {
          if (entity.has(Position) && entity.has(Velocity)) {
            const pos = entity.get(Position)
            const vel = entity.get(Velocity)
            pos.x += vel.x * delta
            pos.y += vel.y * delta
          }
        }
      }
    }
    
    // Create player
    const player = new Entity()
      .add(new Position(100, 100))
      .add(new Velocity(0, 0))
      .add(new Sprite('player.png'))
      .add(new Health(100))
    

## Anti-Patterns


---
  #### **Name**
Frame-Dependent Logic
  #### **Description**
Using frame count instead of delta time for game logic
  #### **Why**
Game runs at different speeds on different devices. 60 FPS moves twice as fast as 30 FPS.
  #### **Instead**
Always multiply movement by delta time. Test at different frame rates.

---
  #### **Name**
Update Loop Bloat
  #### **Description**
Expensive operations in the main update loop
  #### **Why**
Frame rate tanks. Only runs on developer machines. Mobile devices throttle.
  #### **Instead**
Profile early. Spatial partitioning. Object pooling. Spread work across frames.

---
  #### **Name**
Boolean State Soup
  #### **Description**
Managing state with scattered booleans and nested conditionals
  #### **Why**
Impossible to reason about. Bugs hide in edge cases. Features break each other.
  #### **Instead**
Implement proper state machines. One source of truth. Explicit transitions.

---
  #### **Name**
Create/Destroy Spam
  #### **Description**
Creating new objects every frame instead of pooling
  #### **Why**
GC pauses cause stuttering. Memory grows. Performance degrades over time.
  #### **Instead**
Object pooling for frequently created objects. Reuse instead of recreate.

---
  #### **Name**
Synchronous Asset Loading
  #### **Description**
Loading all assets at startup, blocking the main thread
  #### **Why**
Long freeze on startup. Browser may kill tab. Players leave.
  #### **Instead**
Async loading with progress feedback. Lazy load non-critical assets.

---
  #### **Name**
Tight Coupling
  #### **Description**
Systems directly accessing each other's internals
  #### **Why**
Can't test in isolation. Changes cascade. Unmaintainable codebase.
  #### **Instead**
Event-driven communication. Dependency injection. ECS for complex games.