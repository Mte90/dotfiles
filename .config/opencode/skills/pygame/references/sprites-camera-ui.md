Loaded on demand from ../SKILL.md — Sprites, Camera, and UI Elements deep dive.

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