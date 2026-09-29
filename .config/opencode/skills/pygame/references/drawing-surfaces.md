Loaded on demand from ../SKILL.md — Drawing and Surfaces deep dive.

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