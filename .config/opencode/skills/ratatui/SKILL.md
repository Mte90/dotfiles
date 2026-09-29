---
name: ratatui
description: "Use when building terminal user interfaces in Rust with the ratatui crate - layout system, widget usage, input/event handling, app state architecture, TUI testing, or migrating between ratatui 0.29 and 0.30"
metadata:
  author: mte90
  version: "2.0.0"
  tags:
    - rust
    - tui
    - terminal
    - cli
    - ratatui
    - tachyonfx
    - mousefood
    - ratzilla
---

# Ratatui

Rust terminal UI framework for building interactive command-line applications.

## Overview

Ratatui provides widgets, layout systems, event handling, and rendering for TUI apps.

**Key Features:**
- Multiple layout systems (blocks, flex, horizontal, vertical)
- Built-in widgets (buttons, checkboxes, tables, charts)
- Event-driven input handling with keyboard and mouse support
- Multiple backends (crossterm, termion, termwiz)
- `no_std` support for embedded targets

## Installation

```toml
[dependencies]
ratatui = "0.30.1"
```

### Feature Flags

```toml
ratatui = { version = "0.30.1", default-features = false, features = [
    "crossterm_0_28",  # Crossterm backend
    "layout-cache",    # Layout caching (default enabled)
    "palette",         # HSLuv color support
    "anstyle",         # anstyle conversions
] }
```

MSRV: 1.88.0 (v0.30.1)

## Quick Start

```rust
use ratatui::{
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout},
    style::{Color, Style},
    widgets::{Block, Borders, Paragraph},
    Frame, Terminal,
};
use std::io;

fn main() -> io::Result<()> {
    let backend = CrosstermBackend::new(io::stdout());
    let mut terminal = Terminal::new(backend)?;

    loop {
        terminal.draw(|f| {
            let chunks = Layout::default()
                .direction(Direction::Vertical)
                .constraints([Constraint::Length(3), Constraint::Min(0)])
                .split(f.area());

            let title = Paragraph::new("Hello, Ratatui!")
                .block(Block::bordered().title("Welcome"))
                .style(Style::default().fg(Color::Cyan));
            f.render_widget(title, chunks[0]);

            let instructions = Paragraph::new("Press 'q' to quit")
                .block(Block::bordered().title("Instructions"));
            f.render_widget(instructions, chunks[1]);
        })?;

        break;  // Add your event handling here
    }

    Ok(())
}
```

## Layout System

### Constraint Types

```rust
use ratatui::layout::{Constraint, Direction, Layout};

let chunks = Layout::default()
    .direction(Direction::Horizontal)
    .constraints([
        Constraint::Percentage(30),  // 30% of area
        Constraint::Length(50),      // 50 characters
        Constraint::Min(10),         // At least 10
        Constraint::Ratio(1, 4),     // 1/4 of remaining
    ])
    .split(area);
```

### Flex Modes

```rust
use ratatui::layout::Flex;

// Center alignment
let chunks = Layout::default()
    .direction(Direction::Horizontal)
    .flex(Flex::Center)
    .constraints([Constraint::Length(20)])
    .split(area);

// SpaceEvenly - equal spacing including edges (v0.30+)
let chunks = Layout::default()
    .flex(Flex::SpaceEvenly)
    .constraints([Constraint::Length(20), Constraint::Length(20)])
    .split(area);

// SpaceAround - middle spacers twice the size of edges (v0.30+)
let chunks = Layout::default()
    .flex(Flex::SpaceAround)
    .constraints([Constraint::Length(20), Constraint::Length(20)])
    .split(area);
```

### Overlapping Layouts

```rust
use ratatui::layout::Spacing;

// Overlap layouts by -1 spacing (useful for border overlap)
let chunks = Layout::default()
    .spacing(Spacing::Overlap)
    .constraints([Constraint::Length(3), Constraint::Length(3)])
    .split(area);
```

### Ergonomic Rect Methods (v0.30+)

```rust
use ratatui::layout::Rect;

let centered = area.centered();                    // Both dimensions
let centered_h = area.centered_horizontally();
let centered_v = area.centered_vertically();
let outer = area.outer(Offset::new(1, 0));         // 1 cell to the right

// Split with compile-time array
let [left, right] = area.layout::<2>(Direction::Horizontal, &constraints);
```

### Nested Layouts

```rust
let chunks = Layout::default()
    .direction(Direction::Vertical)
    .constraints([Constraint::Length(3), Constraint::Min(0)])
    .split(area);

let sub_chunks = Layout::default()
    .direction(Direction::Horizontal)
    .constraints([Constraint::Percentage(50), Constraint::Percentage(50)])
    .split(chunks[1]);
```

## Widgets

See [references/widgets.md](references/widgets.md) for detailed widget recipes.

| Widget | When to Use | Reference |
|--------|-------------|-----------|
| Paragraph | Text display with styling/wrapping | [widgets.md#paragraph](references/widgets.md#paragraph) |
| Block | Framing and titling other widgets | [widgets.md#block](references/widgets.md#block) |
| Button | Clickable buttons with pressed state | [widgets.md#button](references/widgets.md#button) |
| Checkbox | Boolean toggle with custom symbols | [widgets.md#checkbox](references/widgets.md#checkbox) |
| List | Selectable item lists | [widgets.md#list](references/widgets.md#list) |
| Table | Tabular data with column selection | [widgets.md#table](references/widgets.md#table) |
| Gauge | Progress percentage display | [widgets.md#gauge](references/widgets.md#gauge) |
| Sparkline | Compact data visualization | [widgets.md#sparkline](references/widgets.md#sparkline) |
| Chart | Multi-dataset plots with axes | [widgets.md#chart](references/widgets.md#chart) |
| Canvas | Custom drawing with markers | [widgets.md#canvas](references/widgets.md#canvas) |
| Calendar | Date display with Chrono | [widgets.md#calendar](references/widgets.md#calendar) |
| Fill | Paint area with symbol | [widgets.md#fill](references/widgets.md#fill) |

## Input Handling

### Event Handling

```rust
use ratatui::event::{Event, EventHandler, KeyCode, KeyModifiers};

if let Some(Event::Key(key)) = handle_events(&mut handler) {
    match key.code {
        KeyCode::Char('q') => break,
        KeyCode::Char('c') if key.modifiers.contains(KeyModifiers::CONTROL) => break,
        KeyCode::Down | KeyCode::Char('j') => move_next(),
        KeyCode::Up | KeyCode::Char('k') => move_previous(),
        _ => {}
    }
}
```

### Mouse Support

```rust
use ratatui::event::{Event, MouseEventKind};

if let Some(Event::Mouse(mouse)) = handle_events(&mut handler) {
    match mouse.kind {
        MouseEventKind::LeftClick => {
            // Handle click at mouse.column, mouse.row
        }
        MouseEventKind::ScrollDown => {
            // Handle scroll
        }
        _ => {}
    }
}

// Enable mouse capture
crossterm::execute!(stderr(), EnableMouseCapture)?;
```

## State Management

See [references/architecture.md](references/architecture.md) for MVU/Flux patterns.

```rust
use ratatui::widgets::ListState;

struct AppState {
    items: Vec<String>,
    selected: usize,
    list_state: ListState,
}

impl AppState {
    fn new(items: Vec<String>) -> Self {
        let mut list_state = ListState::default();
        list_state.select(Some(0));
        Self { items, selected: 0, list_state }
    }

    fn next(&mut self) {
        if let Some(selected) = self.list_state.selected {
            let next = (selected + 1) % self.items.len();
            self.list_state.select(Some(next));
            self.selected = next;
        }
    }
}
```

## Styling

```rust
use ratatui::style::{Color, Modifier, Style, Stylize};

let style = Style::default()
    .fg(Color::White)
    .bg(Color::Black)
    .add_modifier(Modifier::BOLD);

// Stylize trait (v0.30+)
let style = Style::new().blue().on_black().bold();
let styled: Text = "hello".yellow();
```

### Color Types

```rust
Color::Reset        // Terminal default
Color::Red          // Basic terminal colors
Color::Rgb(255, 128, 0)  // True color
Color::Indexed(42)  // 256-color palette
Color::from_hsluv(Hsluv::new(0.0, 100.0, 50.0))  // HSLuv (requires "palette" feature)
```

## Best Practices & Performance

### Separate State from View

Keep state management separate from rendering logic. Use MVU pattern for predictable data flow.

### Minimize Redraws

```rust
if app.state_changed {
    terminal.draw(|f| render_app(f, &app))?;
    app.state_changed = false;
}
```

### Use Clear for Popups

Prevent content bleeding by clearing popup areas:

```rust
use ratatui::widgets::Clear;
Clear.render(popup_area, buf);
```

### Handle Resize

```rust
use ratatui::event::Event;

if let Ok(Event::Resize(width, height)) = term.read_event() {
    term.resize(width, height)?;
}
```

### Panic Recovery

```rust
std::panic::set_hook(Box::new(|_| {
    let _ = ratatui::restore();
}));
```

## Breaking Changes: v0.29 → v0.30

| Change | Migration |
|--------|-----------|
| `Block::title()` removed | Use `Block::new().title(Line::from("foo"))` |
| `block::Title` deprecated | Use `Line` directly (removal in v0.31) |
| `Style` no longer implements `Styled` | Use `Style::new().blue()` then `widget.style(style)` |
| `Table::highlight_style()` deprecated | Use `table.row_highlight_style(...)` |
| `Marker` is `#[non_exhaustive]` | Use `Marker::Custom('x')` for custom markers |
| Backend requires `Error` type | Add associated `Error` type to your backend |
| `Rect::area()` returns `u32` | Update type expectations |

### Migration Example

```rust
// Old
Block::new().title("foo")

// New
Block::new().title(Line::from("foo").centered())

// Old
table.highlight_style(Style::default().fg(Color::Yellow))

// New
table.row_highlight_style(Style::default().fg(Color::Yellow))
```

## Deep Dives

- Detailed widget recipes: [references/widgets.md](references/widgets.md)
- Advanced state patterns (MVU/Flux): [references/architecture.md](references/architecture.md)
- Application recipes (panic hooks, error handling): [references/recipes.md](references/recipes.md)
- Testing with insta snapshots: [references/testing.md](references/testing.md)
- Ecosystem libraries: [references/ecosystem.md](references/ecosystem.md)