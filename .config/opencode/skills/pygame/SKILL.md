---
name: pygame
description: "Python 2D game development - sprites, surfaces, events, sound, fonts, game loops, collision detection, and input handling"
metadata:
  author: "OSS AI Skills"
  version: "1.0.0"
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

## Drawing

### Colors

```python
# RGB colors
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
RED = (255, 0, 0)
GREEN = (0, 255, 0)
BLUE = (0, 0, 255)
YELLOW = (255, 255, 0)
CYAN = (0, 255, 255)
MAGENTA = (255, 0, 255)

# With alpha (RGBA)
TRANSPARENT = (0, 0, 0, 0)
SEMI_RED = (255, 0, 0, 128)
```

### Shapes

```python
# Rectangle
pygame.draw.rect(screen, RED, (x, y, width, height))
pygame.draw.rect(screen, RED, (x, y, width, height), 2)  # Outline

# Circle
pygame.draw.circle(screen, GREEN, (center_x, center_y), radius)
pygame.draw.circle(screen, GREEN, (cx, cy, radius), 2)  # Outline

# Line
pygame.draw.line(screen, BLUE, (x1, y1), (x2, y2), width)
pygame.draw.aaline(screen, BLUE, (x1, y1), (x2, y2))  # Antialiased

# Polygon
points = [(x1, y1), (x2, y2), (x3, y3)]
pygame.draw.polygon(screen, YELLOW, points)
pygame.draw.polygon(screen, YELLOW, points, 2)  # Outline

# Ellipse
pygame.draw.ellipse(screen, MAGENTA, (x, y, width, height))

# Arc
pygame.draw.arc(screen, CYAN, (x, y, width, height), start_angle, end_angle)

# Lines (multiple)
points = [(0, 0), (100, 100), (200, 0)]
pygame.draw.lines(screen, WHITE, False, points, 2)
```

### Surfaces

```python
# Create surface
surface = pygame.Surface((width, height))
surface = pygame.Surface((width, height), pygame.SRCALPHA)  # With alpha

# Fill
surface.fill(RED)
surface.fill((0, 0, 0, 128), pygame.Rect(0, 0, 100, 100))  # Partially

# Blit (copy one surface to another)
screen.blit(surface, (x, y))

# Transform
scaled = pygame.transform.scale(surface, (new_width, new_height))
rotated = pygame.transform.rotate(surface, angle)
flipped = pygame.transform.flip(surface, flip_x, flip_y)
```

## Performance Optimization

### Image Conversion

Always convert images after loading to match the display format:

```python
# Bad: Each blit converts format (slow)
screen.blit(pygame.image.load("sprite.png"), (0, 0))

# Good: Convert once at load time
sprite = pygame.image.load("sprite.png").convert()
sprite_alpha = pygame.image.load("player.png").convert_alpha()

# When to use convert() vs convert_alpha():
# - convert(): Opaque images, no transparency needed (20-30% faster)
# - convert_alpha(): Images with transparency, alpha channels, or colorkeys
```

### RLEACCEL for Static Surfaces

For surfaces that rarely change, RLEACCEL speeds up repeated blitting:

```python
# Create surface with RLEACCEL flag (can be combined with SRCALPHA)
static_bg = pygame.Surface((800, 600))
static_bg.fill((50, 50, 50))
static_bg = static_bg.convert()
static_bg.set_colorkey((0, 0, 0), pygame.RLEACCEL)  # RLE encode colorkey
static_bg.set_alpha(128, pygame.RLEACCEL)  # RLE encode alpha

# RLEACCEL speeds up repeated blits of the same surface
# Best for: backgrounds, UI elements, static game elements
```

### Batched Blits with blits()

Use `blits()` instead of multiple `blit()` calls for better performance:

```python
# Bad: Multiple individual blits
screen.blit(sprite1, (x1, y1))
screen.blit(sprite2, (x2, y2))
screen.blit(sprite3, (x3, y3))

# Good: Batched blits (single call)
screen.blits([(sprite1, (x1, y1)), (sprite2, (x2, y2)), (sprite3, (x3, y3))])

# With destination areas (for clipping)
screen.blits([(sprite, dest_rect1), (sprite, dest_rect2)], doreturn=0)
```

### Dirty Rect Optimization

For games with many sprites where only some move, use dirty rect tracking:

```python
class OptimizedSprite(pygame.sprite.DirtySprite):
    def __init__(self, x, y):
        super().__init__()
        self.image = pygame.Surface((32, 32))
        self.image.fill(GREEN)
        self.rect = self.image.get_rect()
        self.rect.topleft = (x, y)
        self.dirty = 1  # Force initial draw
    
    def update(self):
        # Movement logic...
        if moved:
            self.dirty = 1  # Mark as needing redraw

# Only redraw changed regions
def render_dirty_rects(screen, sprite_group, background):
    # Clear only dirty rects
    for sprite in sprite_group:
        if sprite.dirty:
            if sprite.visible:
                # Restore background at old position
                screen.blit(background, sprite.rect, sprite.rect)
            
            # Draw at new position
            if sprite.visible:
                screen.blit(sprite.image, sprite.rect)
            sprite.dirty = 0
```

### Pre-rendered Surfaces

Cache expensive operations:

```python
# Bad: Rotate every frame
while running:
    rotated = pygame.transform.rotate(original_image, angle)
    screen.blit(rotated, pos)

# Good: Pre-render all rotations
rotations = {angle: pygame.transform.rotate(original, angle) 
             for angle in range(0, 360, 5)}
while running:
    screen.blit(rotations[int(angle) % 360], pos)

# Bad: Scale every frame
screen.blit(pygame.transform.scale(small_image, (100, 100)), pos)

# Good: Cache scaled versions
sizes = {size: pygame.transform.scale(image, (size, size)) for size in [32, 64, 128]}
```

## Sprites

### Sprite Class

```python
class Player(pygame.sprite.Sprite):
    def __init__(self, x, y):
        super().__init__()
        self.image = pygame.Surface((32, 32))
        self.image.fill(GREEN)
        self.rect = self.image.get_rect()
        self.rect.topleft = (x, y)
        self.speed = 5
    
    def update(self):
        keys = pygame.key.get_pressed()
        if keys[pygame.K_LEFT]:
            self.rect.x -= self.speed
        if keys[pygame.K_RIGHT]:
            self.rect.x += self.speed
        if keys[pygame.K_UP]:
            self.rect.y -= self.speed
        if keys[pygame.K_DOWN]:
            self.rect.y += self.speed
    
    def draw(self, screen):
        screen.blit(self.image, self.rect)

# Usage
player = Player(100, 100)
all_sprites.add(player)
all_sprites.draw(screen)
```

### Sprite Groups

```python
# Create groups
all_sprites = pygame.sprite.Group()
enemies = pygame.sprite.Group()
bullets = pygame.sprite.Group()

# Add to groups
player = Player(100, 100)
all_sprites.add(player)
enemies.add(enemy1, enemy2)

# Update all sprites
all_sprites.update()

# Draw all sprites
all_sprites.draw(screen)

# Remove from groups
player.kill()

# Check group membership
if player in all_sprites:
    print("Player is alive")
```

### Loading Images

```python
# Load image
image = pygame.image.load("sprite.png")

# Load with transparency
image = pygame.image.load("sprite.png").convert_alpha()

# Convert for faster blitting
image = image.convert()  # Without alpha
image = image.convert_alpha()  # With alpha

# Load from string
import io
image = pygame.image.load(io.BytesIO(image_data))
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

## Camera

```python
class Camera:
    def __init__(self, width, height):
        self.camera = pygame.Rect(0, 0, width, height)
        self.width = width
        self.height = height
    
    def apply(self, entity):
        return entity.rect.move(self.camera.topleft)
    
    def apply_rect(self, rect):
        return rect.move(self.camera.topleft)
    
    def update(self, target):
        x = -target.rect.x + int(SCREEN_WIDTH / 2)
        y = -target.rect.y + int(SCREEN_HEIGHT / 2)
        
        # Limit scrolling to map size
        x = min(0, x)
        y = min(0, y)
        x = max(-(self.width - SCREEN_WIDTH), x)
        y = max(-(self.height - SCREEN_HEIGHT), y)
        
        self.camera = pygame.Rect(x, y, self.width, self.height)

# Usage
camera = Camera(map_width, map_height)
for entity in all_sprites:
    screen.blit(entity.image, camera.apply(entity))
```

## UI Elements

### Button

```python
class Button:
    def __init__(self, x, y, width, height, text, callback):
        self.rect = pygame.Rect(x, y, width, height)
        self.text = text
        self.callback = callback
        self.color = (100, 100, 100)
        self.hover_color = (150, 150, 150)
        self.font = pygame.font.Font(None, 36)
    
    def handle_event(self, event):
        if event.type == pygame.MOUSEBUTTONDOWN:
            if event.button == 1 and self.rect.collidepoint(event.pos):
                self.callback()
    
    def draw(self, screen):
        mouse_pos = pygame.mouse.get_pos()
        color = self.hover_color if self.rect.collidepoint(mouse_pos) else self.color
        
        pygame.draw.rect(screen, color, self.rect)
        pygame.draw.rect(screen, WHITE, self.rect, 2)  # Border
        
        text_surface = self.font.render(self.text, True, WHITE)
        text_rect = text_surface.get_rect(center=self.rect.center)
        screen.blit(text_surface, text_rect)
```

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