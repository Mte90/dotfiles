---
name: pygame
description: Use when building 2D games in Python with pygame - game loop and delta time, sprites and groups, collision detection, drawing and surfaces, events and input, sound and fonts, camera, or performance optimization
metadata:
  author: mte90
  version: 2.0.0
  tags:
    - python
    - game-development
    - 2d-games
    - pygame
    - graphics
    - game-engine
---

# Pygame

Python game development library.

## Overview

Pygame is a set of Python modules designed for writing video games. It provides functionality for creating graphics, handling input, playing sounds, and more.

**Key Features:**
- 2D graphics and sprites
- Event handling
- Sound and music playback
- Font rendering
- Collision detection
- Game loops
- Hardware acceleration

### Installation

```bash
# Install pygame-ce (Community Edition) - recommended
pip install pygame-ce

# Legacy pygame (no longer maintained)
pip install pygame

# With additional features
pip install pygame-ce[fonts]
```

### pygame-ce (Community Edition)

pygame-ce is the maintained fork of pygame. Key differences:

- 20-30% faster performance in many benchmarks
- `IS_CE` flag to detect pygame-ce
- Better Python 3.10+ support
- Active development and bug fixes

```python
import pygame
print(pygame.ver)  # '2.x.x' for pygame-ce, '1.x.x' for legacy

# Check if using pygame-ce
if hasattr(pygame, 'IS_CE'):
    print("Using pygame-ce!")
```

## Getting Started

### Basic Window

```python
import pygame
import sys

# Initialize pygame
pygame.init()

# Create window
screen = pygame.display.set_mode((800, 600))
pygame.display.set_caption("My Game")

# Game loop
running = True
while running:
    # Event handling
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False
    
    # Drawing
    screen.fill((0, 0, 0))  # Black background
    pygame.draw.rect(screen, (255, 0, 0), (100, 100, 50, 50))
    
    # Update display
    pygame.display.flip()

# Quit pygame
pygame.quit()
sys.exit()
```

## Events

### Event Types

```python
for event in pygame.event.get():
    # Quit
    if event.type == pygame.QUIT:
        running = False
    
    # Key pressed
    if event.type == pygame.KEYDOWN:
        if event.key == pygame.K_SPACE:
            print("Space pressed")
        if event.key == pygame.K_ESCAPE:
            running = False
    
    # Key released
    if event.type == pygame.KEYUP:
        if event.key == pygame.K_SPACE:
            print("Space released")
    
    # Mouse clicked
    if event.type == pygame.MOUSEBUTTONDOWN:
        x, y = event.pos
        button = event.button
        if button == 1:  # Left click
            print(f"Left click at {x}, {y}")
    
    # Mouse motion
    if event.type == pygame.MOUSEMOTION:
        x, y = event.pos
        rel_x, rel_y = event.rel
    
    # Joystick events
    if event.type == pygame.JOYBUTTONDOWN:
        if event.button == 0:  # A button
            print("Joystick A pressed")
    
    # Window events
    if event.type == pygame.WINDOWFOCUSLOST:
        print("Window lost focus")
    if event.type == pygame.WINDOWRESIZED:
        print(f"Window resized to {event.x}x{event.y}")
```

### Input States

```python
# Keyboard state
keys = pygame.key.get_pressed()
if keys[pygame.K_SPACE]:
    print("Space is held down")

# Mouse state
mouse_pos = pygame.mouse.get_pos()
mouse_buttons = pygame.mouse.get_pressed()
if mouse_buttons[0]:  # Left button
    print("Left mouse button held")

# Joystick state
joystick = pygame.joystick.Joystick(0)
axes = joystick.get_numaxes()
for i in range(axes):
    value = joystick.get_axis(i)
```

## Collision Detection

```python
# Rectangle collision
if pygame.sprite.collide_rect(sprite1, sprite2):
    print("Collision!")

# Group collision
hits = pygame.sprite.spritecollide(player, enemies, True)  # Kill enemies
for enemy in hits:
    score += 10

# Group vs group
pygame.sprite.groupcollide(bullets, enemies, True, True)  # Kill both

# Circle collision (requires radius attribute)
pygame.sprite.collide_circle(sprite1, sprite2)

# Group circle collision
pygame.sprite.spritecollide(player, enemies, True, pygame.sprite.collide_circle)

# Mask collision (pixel-perfect)
mask1 = pygame.mask.from_surface(sprite1.image)
mask2 = pygame.mask.from_surface(sprite2.image)
if sprite1.rect.colliderect(sprite2.rect):  # First check bounding
    offset = (sprite2.rect.x - sprite1.rect.x, sprite2.rect.y - sprite1.rect.y)
    if mask1.overlap(mask2, offset):
        print("Pixel-perfect collision!")
```

## Sound

```python
# Initialize mixer
pygame.mixer.init()

# Load sound
shoot_sound = pygame.mixer.Sound("shoot.wav")
explosion_sound = pygame.mixer.Sound("explosion.wav")

# Set volume
shoot_sound.set_volume(0.5)
explosion_sound.set_volume(0.8)

# Play sound
shoot_sound.play()
shoot_sound.play(maxtime=500)  # Stop after 500ms

# Load music (streaming)
pygame.mixer.music.load("bgm.mp3")
pygame.mixer.music.play(-1)  # Loop forever
pygame.mixer.music.pause()
pygame.mixer.music.unpause()
pygame.mixer.music.stop()

# Music volume
pygame.mixer.music.set_volume(0.5)
```

## Fonts

```python
# Initialize font system
pygame.font.init()

# Get default font
font = pygame.font.Font(None, 36)  # Default system font, size 36

# Load custom font
font = pygame.font.Font("custom.ttf", 36)

# Render text
text_surface = font.render("Hello, World!", True, WHITE)  # Antialiased
text_surface = font.render("Hello", False, RED)  # Not antialiased

# Get text size
width, height = font.size("Hello")

# Draw text on screen
screen.blit(text_surface, (x, y))
```

## Time and Delta Time

```python
import pygame
import time

# Clock
clock = pygame.time.Clock()

# Set framerate
clock.tick(60)  # 60 FPS
fps = clock.get_fps()

# Delta time (for consistent movement)
last_time = time.time()
while True:
    dt = time.time() - last_time
    last_time = time.time()
    
    # Move at consistent speed regardless of framerate
    player.x += player.speed * dt
```

### Fixed Timestep Game Loop

The basic `clock.tick(fps)` approach varies the timestep when framerate drops, causing inconsistent physics. Fixed timestep updates physics at regular intervals while allowing interpolated rendering:

```python
class Game:
    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode((800, 600))
        self.clock = pygame.time.Clock()
        self.running = True
        
        # Fixed timestep configuration
        self.fixed_dt = 1/60  # 60 Hz physics
        self.accumulator = 0.0
        
    def run(self):
        while self.running:
            # Calculate delta time (in seconds)
            dt = self.clock.tick(60) / 1000.0
            
            # Handle events
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.running = False
            
            # Fixed timestep update loop
            self.accumulator += dt
            while self.accumulator >= self.fixed_dt:
                self.fixed_update(self.fixed_dt)
                self.accumulator -= self.fixed_dt
            
            # Render with interpolation (smooths visual updates)
            interpolation = self.accumulator / self.fixed_dt
            self.render(interpolation)
        
        pygame.quit()
    
    def fixed_update(self, dt):
        """Physics/update at fixed 60 Hz"""
        # All game logic here - movement, collision, AI
        player.update_physics(dt)
    
    def render(self, interp):
        """Render with interpolation factor (0.0 to 1.0)"""
        self.screen.fill((0, 0, 0))
        
        # Interpolate positions for smooth rendering
        for sprite in all_sprites:
            render_x = sprite.x + (sprite.vx * interp)
            render_y = sprite.y + (sprite.vy * interp)
            self.screen.blit(sprite.image, (render_x, render_y))
        
        pygame.display.flip()
```

**Why fixed timestep matters:**
- Consistent physics regardless of framerate
- Deterministic network games (same simulation everywhere)
- No "spiral of death" when frame time exceeds update time
- Interpolation makes rendering smooth even when physics runs at lower rate

## Deep Dives

For detailed implementations, load these reference files on demand:

- **Drawing & Surfaces**: `references/drawing-surfaces.md` — Colors, shapes, surface operations, transforms
- **Performance Optimization**: `references/performance.md` — Image conversion, RLEACCEL, batched blits, dirty rects, pre-rendered surfaces
- **Sprites, Camera & UI**: `references/sprites-camera-ui.md` — Sprite classes, groups, camera implementation, button UI elements

## Best Practices

### 1. Use Sprite Groups

```python
# Good: Use groups for efficient updates
all_sprites = pygame.sprite.Group()
all_sprites.update()  # Updates all sprites
all_sprites.draw(screen)  # Draws all sprites
```

### 2. Delta Time

```python
# Good: Frame-rate independent movement
player.x += speed * dt
```

### 3. Pre-load Resources

```python
# Good: Load images/sounds once at startup
def load_game():
    global player_image, enemy_image, shoot_sound
    player_image = pygame.image.load("player.png").convert_alpha()
    enemy_image = pygame.image.load("enemy.png").convert_alpha()
    shoot_sound = pygame.mixer.Sound("shoot.wav")
```

### 4. Clean Exit

```python
# Good: Proper cleanup
try:
    game_loop()
finally:
    pygame.quit()
    sys.exit()
```

## Game Loop Template

```python
import pygame
import sys

class Game:
    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode((800, 600))
        self.clock = pygame.time.Clock()
        self.running = True
    
    def handle_events(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False
    
    def update(self):
        pass
    
    def draw(self):
        self.screen.fill((0, 0, 0))
        pygame.display.flip()
    
    def run(self):
        while self.running:
            dt = self.clock.tick(60) / 1000.0  # Delta time in seconds
            self.handle_events()
            self.update()
            self.draw()
        pygame.quit()
        sys.exit()

if __name__ == "__main__":
    game = Game()
    game.run()
```

## References

- **Official Documentation**: https://www.pygame.org/docs/
- **Pygame Wiki**: https://www.pygame.org/wiki/
- **KidsCanCode Pygame Tutorials**: https://kidscancode.org/pygame_tutorials/