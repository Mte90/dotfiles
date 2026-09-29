Loaded on demand from ../SKILL.md — Performance Optimization deep dive.

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