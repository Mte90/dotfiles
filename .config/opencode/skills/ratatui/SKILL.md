---
name: ratatui
description: "Rust terminal UI framework - widgets, components, layouts, events, input handling, and state management for TUI apps"
metadata:
  author: mte90
  version: "1.0.1"
  tags:
    - rust
    - tui
    - terminal
    - cli
    - user-interface
    - ratatui
    - ecosystem
    - tachyonfx
    - mousefood
    - ratzilla
---

# Ratatui

Rust terminal UI framework.

## Overview

Ratatui is a Rust library for building terminal user interfaces (TUI). It provides a set of widgets and tools for creating interactive command-line applications.

**Key Features:**
- Multiple layout systems (blocks, flex, horizontal, vertical)
- Built-in widgets (buttons, checkboxes, calendars, charts, tables)
- Event-driven input handling
- Cross-platform support
- Mouse support
- ANSI escape sequences
- Multiple buffer rendering

### Installation

```toml
# Cargo.toml
[dependencies]
ratatui = "0.30.1"
```

### Crate Modularization (v0.30+)

v0.30 introduced a workspace structure. You can depend on specific crates:

```toml
# Cargo.toml
[dependencies]
# Full crate (recommended for most users)
ratatui = "0.30.1"

# Or individual crates for more control
ratatui-core = "0.30.1"      # Core types, traits, utilities
ratatui-widgets = "0.30.1"   # Built-in widgets
ratatui-crossterm = "0.30.1" # Crossterm backend
ratatui-termion = "0.30.1"   # Termion backend
ratatui-termwiz = "0.30.1"   # Termwiz backend
ratatui-macros = "0.30.1"    # Macro utilities
```

**Feature flags:**
```toml
[dependencies]
ratatui = { version = "0.30.1", default-features = false, features = [
    "crossterm_0_28",      # Use crossterm 0.28 (default: 0.29)
    "layout-cache",        # Enable layout caching (default: enabled)
    "palette",             # HSLuv color support
    "anstyle",             # anstyle conversions
] }
```

MSRV: 1.88.0 (v0.30.1)

## Quick Start

### Basic Application

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
    // Initialize terminal
    let backend = CrosstermBackend::new(io::stdout());
    let mut terminal = Terminal::new(backend)?;

    // Main loop
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

        // Handle events (add your own event handling)
        break;  // Exit for now
    }

    Ok(())
}
```

## Layout System

### Block Layout

```rust
use ratatui::layout::{Constraint, Direction, Layout};

let chunks = Layout::default()
    .direction(Direction::Horizontal)
    .constraints([
        Constraint::Percentage(30),  // 30%
        Constraint::Length(50),     // 50 characters
        Constraint::Min(10),        // At least 10
        Constraint::Ratio(1, 4),    // 1/4 of remaining
    ])
    .split(area);
```

### Flex Layout

```rust
use ratatui::layout::Flex;

let chunks = Layout::default()
    .direction(Direction::Horizontal)
    .flex(Flex::Center)  // Center content
    .constraints([Constraint::Length(20)])
    .split(area);
```

### Flex::SpaceEvenly (v0.30+)

```rust
use ratatui::layout::Flex;

// v0.30+: SpaceEvenly - equal spacing including edges
let chunks = Layout::default()
    .direction(Direction::Horizontal)
    .flex(Flex::SpaceEvenly)
    .constraints([Constraint::Length(20), Constraint::Length(20), Constraint::Length(20)])
    .split(area);

// SpaceAround - middle spacers twice the size of edges (CSS-like, v0.30+)
let chunks = Layout::default()
    .direction(Direction::Horizontal)
    .flex(Flex::SpaceAround)
    .constraints([Constraint::Length(20), Constraint::Length(20)])
    .split(area);
```

### Overlapping Layouts (v0.29+)

Create layouts where segments share pixels (useful for border overlap):

```rust
use ratatui::layout::Spacing;

// Overlap layouts by -1 spacing
let chunks = Layout::default()
    .direction(Direction::Horizontal)
    .spacing(Spacing::Overlap)  // or .spacing(-1)
    .constraints([
        Constraint::Length(3),
        Constraint::Length(3),
        Constraint::Length(3),
    ])
    .split(area);

// Example: stacked borders
let stacked = Layout::default()
    .direction(Direction::Vertical)
    .spacing(Spacing::Overlap)
    .constraints([
        Constraint::Length(1),
        Constraint::Length(1),
        Constraint::Length(1),
    ])
    .split(area);
```

### Ergonomic Rect Methods (v0.30+)

```rust
use ratatui::layout::Rect;

// Center a rect within another
let centered = area.centered();           // Both dimensions
let centered_h = area.centered_horizontally();
let centered_v = area.centered_vertically();

// Create rect outside current with margin
let outer = area.outer(Offset::new(1, 0));  // 1 cell to the right

// Split with compile-time array (v0.30+)
let [left, right] = area.layout::<2>(Direction::Horizontal, &constraints);
let [top, middle, bottom] = area.layout::<3>(Direction::Vertical, &constraints);

// Try versions return Result
let result = area.try_layout::<2>(Direction::Horizontal, &constraints);
let vec = area.layout_vec(Direction::Horizontal, &constraints);
```

### Nested Layouts

```rust
let chunks = Layout::default()
    .direction(Direction::Vertical)
    .constraints([
        Constraint::Length(3),
        Constraint::Min(0),
    ])
    .split(area);

let sub_chunks = Layout::default()
    .direction(Direction::Horizontal)
    .constraints([Constraint::Percentage(50), Constraint::Percentage(50)])
    .split(chunks[1]);
```

## Widgets

### Paragraph

```rust
use ratatui::widgets::{Block, Borders, Paragraph, Wrap};

let paragraph = Paragraph::new("Your text here")
    .block(Block::bordered().title("Title"))
    .style(Style::default().fg(Color::White))
    .wrap(Wrap { trim: true });

// Render
f.render_widget(paragraph, area);
```

### Block

```rust
use ratatui::widgets::{Block, BorderType, Borders};

let block = Block::bordered()
    .title("My Block")
    .title_style(Style::default().fg(Color::Yellow))
    .border_type(BorderType::Rounded)
    .border_style(Style::default().fg(Color::Blue));

let inner = Paragraph::new("Content");
f.render_widget(block.inner(area), area);
f.render_widget(inner, block.inner(area));
```

### Block Border Merging (v0.30+)

Overlapping borders automatically merge into clean single borders:

```rust
use ratatui::widgets::{Block, BorderType, MergeStrategy};

// Use MergeStrategy to control behavior
let block = Block::bordered()
    .title("Merged")
    .merge_strategy(MergeStrategy::Merge);

// New BorderType variants (v0.30+)
let block = Block::bordered()
    .border_type(BorderType::LightDoubleDashed)
    .border_type(BorderType::HeavyDoubleDashed)
    .border_type(BorderType::LightTripleDashed)
    .border_type(BorderType::HeavyTripleDashed)
    .border_type(BorderType::LightQuadrupleDashed)
    .border_type(BorderType::HeavyQuadrupleDashed);
```

### Block Shadow (v0.30.1+)

```rust
use ratatui::widgets::{Block, Shadow};
use ratatui::layout::Offset;

let block = Block::bordered()
    .title("Popup")
    .shadow(Shadow::dark_shade()  // Preset: dark shade effect
        .black()                   // Shadow color
        .on_white()               // Background color
        .offset(Offset::new(2, 1)));  // Offset x, y

// Custom shadow
let block = Block::bordered()
    .shadow(Shadow::default()
        .symbol('░')
        .style(Style::default().fg(Color::DarkGray))
        .offset(Offset::new(1, 1)));
```

### Button

```rust
use ratatui::widgets::Button;

let button = Button::default()
    .text("Click Me")
    .style(Style::default().fg(Color::White).bg(Color::Blue))
    .pressed_style(Style::default().fg(Color::Blue).bg(Color::White));

f.render_widget(button, area);
```

### Checkbox

```rust
use ratatui::widgets::Checkbox;

let checkbox = Checkbox::new("Enable feature", true)
    .style(Style::default().fg(Color::White))
    .check_style(Style::default().fg(Color::Green));

f.render_widget(checkbox, area);
```

### List

```rust
use ratatui::widgets::List, ListItem;

let items = [
    ListItem::new("Item 1"),
    ListItem::new("Item 2"),
    ListItem::new("Item 3"),
];

let list = List::new(items)
    .block(Block::bordered().title("Items"))
    .style(Style::default().fg(Color::White))
    .highlight_style(Style::default().fg(Color::Yellow))
    .highlight_symbol(">> ");

f.render_widget(list, area);
```

### Table

```rust
use ratatui::widgets::{Table, Row, Cell};

let rows = vec![
    Row::new(vec!["Row1", "Data1"]),
    Row::new(vec!["Row2", "Data2"]),
];

let table = Table::new(
    rows,
    // Column widths
    &[Constraint::Length(10), Constraint::Min(20)],
)
    .block(Block::bordered().title("Table"))
    .header_style(Style::default().fg(Color::Yellow))
    .widths(&[Constraint::Length(10), Constraint::Min(20)]);

f.render_widget(table, area);
```

### Table Column Selection (v0.29+)

```rust
use ratatui::widgets::{Table, Row, Cell, TableState};

let mut table_state = TableState::default();

// Column selection methods
table.select_column(2);                           // Select column 2
table.select_first_column();
table.select_next_column();
table.select_previous_column();
table.select_last_column();

// Cell selection (v0.29+)
table.select_cell();

// Scrolling
table.scroll_right_by(2);
table.scroll_left_by(1);

// Styling
table.column_highlight_style(Style::default().fg(Color::Yellow).bg(Color::DarkGray));
table.cell_highlight_style(Style::default().fg(Color::White).bg(Color::Blue));

f.render_stateful_widget(table, area, &mut table_state);
```

### Table Column Span (v0.30.1+)

```rust
use ratatui::widgets::{Table, Row, Cell};

let rows = vec![
    Row::new(vec![
        Cell::new("Name").column_span(2),  // Span 2 columns
        Cell::new("Score"),
    ]),
    Row::new(vec![
        Cell::new("Long Name").column_span(3),  // Span 3 columns
    ]),
];

let table = Table::new(rows, &[Constraint::Length(10), Constraint::Length(10), Constraint::Length(10)])
    .block(Block::bordered());

f.render_widget(table, area);
```

### Gauge

```rust
use ratatui::widgets::Gauge;

let gauge = Gauge::default()
    .label("Progress")
    .gauge_style(Style::default().fg(Color::Green))
    .percent(75);

f.render_widget(gauge, area);
```

### Sparkline

```rust
use ratatui::widgets::Sparkline;

let data = vec![1, 5, 3, 7, 2, 8, 5, 3, 6, 4];

let sparkline = Sparkline::default()
    .data(&data)
    .style(Style::default().fg(Color::Cyan))
    .bar_set(" ▎▏");

f.render_widget(sparkline, area);
```

### Sparkline absent values (v0.29+)

```rust
use ratatui::widgets::Sparkline;

// Handle missing/None values distinctly from zero
let data = vec![Some(1), Some(5), None, Some(3), Some(0), None];

let sparkline = Sparkline::default()
    .data(&data)
    .absent_value_style(Style::default().fg(Color::DarkGray))  // For None
    .absent_value_symbol('·');  // Symbol for absent values
```

### Calendar

```rust
use ratatui::widgets::{Calendar, Chrono};

let calendar = Calendar::default()
    .block(Block::bordered().title("2024"))
    .chrono(Chrono::Monthly)
    .show_months(true);

f.render_widget(calendar, area);
```

### Chart

```rust
use ratatui::widgets::{Chart, Axis, Dataset};

let data = vec![
    (0.0, 1.0),
    (1.0, 3.0),
    (2.0, 2.0),
    (3.0, 5.0),
];

let chart = Chart::new(vec![Dataset::default()
    .data(&data)
    .name("Series")
    .style(Style::default().fg(Color::Cyan))])
    .block(Block::bordered().title("Chart"))
    .x_axis(Axis::default().bounds([0.0, 4.0]))
    .y_axis(Axis::default().bounds([0.0, 6.0]));

f.render_widget(chart, area);
```

### Canvas/Chart New Markers (v0.30+)

```rust
use ratatui::widgets::Marker;

// New marker types (v0.30+)
let canvas = Canvas::default()
    .marker(Marker::Quadrant)   // 2x2 pseudo-pixel
    .marker(Marker::Sextant)    // 2x3 resolution
    .marker(Marker::Octant);    // 2x4 resolution (alternative to Braille)

// Custom marker (v0.30.1+)
let canvas = Canvas::default()
    .marker(Marker::Custom('+'));

let chart = Chart::new(vec![Dataset::default()
    .marker(Marker::Custom('x'))]);
```

### Canvas/Chart Filled Areas (v0.30.1+)

```rust
use ratatui::widgets::{Canvas, FilledLine, Marker};

// Canvas: use FilledLine to fill area under line
let canvas = Canvas::default()
    .paint(|ctx| {
        ctx.draw(&FilledLine {
            x1: 0.0,
            y1: 0.0,
            x2: 10.0,
            y2: 5.0,
            color: Color::Blue,
        });
    });

// Chart: use GraphType::Area with Dataset::fill_to_y
use ratatui::widgets::GraphType;
let chart = Chart::new(vec![Dataset::default()
    .data(&data)
    .graph_type(GraphType::Area)
    .fill_to_y(0.0)  // Fill area down to y=0
    .style(Style::default().fg(Color::Cyan))]);
```

### RatatuiLogo (v0.29+)

```rust
use ratatui::widgets::RatatuiLogo;

let logo = RatatuiLogo::default();
// Sizes: tiny (2x15), small (2x27)
let logo = RatatuiLogo::tiny();
let logo = RatatuiLogo::small();

f.render_widget(logo, area);
```

### RatatuiMascot (v0.30+)

```rust
use ratatui::widgets::RatatuiMascot;

let mascot = RatatuiMascot::default()
    .eye_color(Color::Yellow);  // Customize eye color

f.render_widget(mascot, area);
```

### Fill (v0.30.1+)

```rust
use ratatui::widgets::Fill;

// Paint entire area with same symbol and style
let fill = Fill::new("█")
    .style(Style::default().fg(Color::Blue).bg(Color::Black));

f.render_widget(fill, area);

// Useful for backgrounds, separators, etc.
```

## Input Handling

### Event Handling

```rust
use ratatui::event::{Event, EventHandler, KeyEvent, MouseEvent};

fn handle_events(events: &mut EventHandler) -> Option<Event> {
    // Try to read event (non-blocking)
    if let Ok(event) = events.try_read() {
        return Some(event);
    }
    None
}

// Key events
if let Some(Event::Key(key)) = handle_events(&mut handler) {
    match key.code {
        KeyCode::Char('q') => break,
        KeyCode::Char('c') if key.modifiers.contains(KeyModifiers::CONTROL) => break,
        _ => {}
    }
}

// Mouse events
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
```

### State Management

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
    
    fn previous(&mut self) {
        if let Some(selected) = self.list_state.selected {
            let prev = if selected == 0 {
                self.items.len() - 1
            } else {
                selected - 1
            };
            self.list_state.select(Some(prev));
            self.selected = prev;
        }
    }
}
```

## Styling

### Styles

```rust
use ratatui::style::{Color, Modifier, Style, Stylize};

let style = Style::default()
    .fg(Color::White)
    .bg(Color::Black)
    .add_modifier(Modifier::BOLD)
    .add_modifier(Modifier::ITALIC);

// Apply to widget
let paragraph = Paragraph::new("Styled text")
    .style(style);
```

### Color Palette

```rust
// Terminal colors
Color::Reset        // Reset to terminal default
Color::Black
Color::Red
Color::Green
Color::Yellow
Color::Blue
Color::Magenta
Color::Cyan
Color::White

// Bright variants
Color::DarkGray
Color::LightRed
Color::LightGreen
Color::LightYellow
Color::LightBlue
Color::LightMagenta
Color::LightCyan
Color::Gray

// Indexed colors (256-color)
Color::Indexed(42)

// RGB colors
Color::Rgb(255, 128, 0)

// HSLuv colors (v0.29+) - perceptually uniform
// Requires "palette" feature
Color::from_hsluv(Hsluv::new(0.0, 100.0, 50.0))  // Red

// Tuple conversions (v0.30+)
Color::from([255, 0, 0]);    // RGB array
Color::from((255, 0, 0));    // RGB tuple
Color::from((255, 0, 0, 255)); // RGBA tuple
```

### Stylize Trait Methods (v0.30+)

```rust
use ratatui::style::Stylize;

// Methods directly on Style
let style = Style::new().blue().on_black().bold();

// Styled for primitives (v0.30+)
let styled: Text = "hello".yellow();
let styled: Span = "world".blue().bold();
let styled: Line = "text".red().italic();

// From anstyle (v0.30+)
use ratatui::anstyle::AnsiColor;
let color = Color::from(AnsiColor::Blue);
```

### Modifiers

```rust
use ratatui::style::Modifier;

// Text modifiers
Modifier::BOLD
Modifier::DIM
Modifier::ITALIC
Modifier::UNDERLINED
Modifier::REVERSED
Modifier::HIDDEN
Modifier::CROSSED_OUT
```

## Mouse Support

```rust
use ratatui::event::{Event, EventKind, MouseEventKind};

terminal.draw(|f| {
    // Enable mouse handling
    let event = Event::Mouse(MouseEvent {
        kind: MouseEventKind::Moved,
        column: 10,
        row: 5,
        ..
    });
    // Handle in event loop
})?;
```

## Example: Interactive List

```rust
use ratatui::{
    backend::CrosstermBackend,
    event::{Event, KeyCode, KeyEventKind},
    layout::Constraint,
    style::Stylize,
    widgets::{Block, Borders, List, ListItem, ListState},
    Frame, Terminal,
};
use std::io;

fn main() -> io::Result<()> {
    let items = vec![
        ListItem::new("Option 1"),
        ListItem::new("Option 2"),
        ListItem::new("Option 3"),
        ListItem::new("Option 4"),
    ];

    let mut list_state = ListState::default();
    list_state.select(Some(0));

    let backend = CrosstermBackend::new(io::stdout());
    let mut terminal = Terminal::new(backend)?;

    loop {
        terminal.draw(|f| {
            let list = List::new(items.clone())
                .block(Block::bordered().title("Select Option"))
                .style(Style::default().fg(Color::White))
                .highlight_style(Style::default().fg(Color::Yellow).add_modifier(ratatui::style::Modifier::BOLD))
                .highlight_symbol(">> ");

            f.render_stateful_widget(list, f.area(), &mut list_state);
        })?;

        // Handle input
        if let Event::Key(key) = terminal.peek_event()? {
            if key.kind == KeyEventKind::Press {
                match key.code {
                    KeyCode::Down => {
                        if let Some(i) = list_state.selected {
                            list_state.select(Some((i + 1) % items.len()));
                        }
                    }
                    KeyCode::Up => {
                        if let Some(i) = list_state.selected {
                            list_state.select(Some(if i == 0 { items.len() - 1 } else { i - 1 }));
                        }
                    }
                    KeyCode::Enter => {
                        if let Some(i) = list_state.selected {
                            println!("Selected: {}", items[i]);
                        }
                    }
                    KeyCode::Char('q') => break,
                    _ => {}
                }
            }
        }
    }

    Ok(())
}
```

## Breaking Changes (v0.29 - v0.30.1)

### v0.30 Breaking Changes

- **Block::title() removed**: Use `Line` with alignment instead
  ```rust
  // Old (removed)
  Block::new().title("foo")
  
  // New (v0.30+)
  Block::new().title(Line::from("foo"))
  ```

- **block::Title deprecated**: Use `Line` directly (will be removed in v0.31)

- **Style no longer implements Styled**: Use methods directly on `Style`
  ```rust
  // Old
  let style = Style::default().fg(Color::Blue).apply_to(widget);
  
  // New (v0.30+)
  let style = Style::default().blue();
  widget.style(style);
  ```

- **Table::highlight_style() deprecated**: Use `row_highlight_style()`

- **Marker is #[non_exhaustive]**: Use `Marker::Custom()` for custom markers

- **Backend trait changes**: 
  - Requires associated `Error` type
  - Requires `clear_region()` method

- **List::highlight_symbol()**: Now accepts `Into<Line>`

### v0.29 Breaking Changes

- **Rect::area() returns u32**: Previously returned u16

- **TableState serialization**: Now includes `selected_column` field

- **Sparkline::data()**: No longer `const`

### Migration Tips

```rust
// Migrate from Block::title() to Line
let block = Block::bordered()
    .title(Line::from("Title").centered())
    .title_top(Line::from("Subtitle").left_aligned());

// Migrate Table highlight style
table = table.row_highlight_style(Style::default().fg(Color::Yellow));
```

## Best Practices

### 1. Separate State

```rust
// Good: Separate state from view
struct App {
    items: Vec<Item>,
    selected: usize,
    // ... state
}

// In draw
f.render_stateful_widget(list, area, &mut self.list_state);
```

### 2. Handle Resize

```rust
use ratatui::event::Event;

if let Ok(Event::Resize(width, height)) = term.read_event() {
    term.resize(width, height)?;
}
```

### 3. Panic Hook

```rust
// Restore terminal on panic
std::panic::set_hook(Box::new(|_| {
    let _ = ratatui::restore();
}));
```

### 4. Buffered Rendering

```rust
// Render to buffer first for complex UIs
let mut terminal = Terminal::new(CrosstermBackend::new(io::BufWriter::new(buf)))?;
```

## TUI Design Principles

### Keyboard-First Interaction

TUIs should prioritize keyboard navigation over mouse interaction:

```rust
// Consistent keybindings across views
match key.code {
    // Navigation
    KeyCode::Up | KeyCode::Char('k') => move_previous(),
    KeyCode::Down | KeyCode::Char('j') => move_next(),
    KeyCode::Left | KeyCode::Char('h') => move_left(),
    KeyCode::Right | KeyCode::Char('l') => move_right(),
    
    // Actions
    KeyCode::Char('a') => add_item(),
    KeyCode::Char('d') => delete_item(),
    KeyCode::Char('e') => edit_item(),
    KeyCode::Enter => select_item(),
    KeyCode::Escape => go_back(),
    KeyCode::Char('q') => quit(),
    
    // Help
    KeyCode::Char('?') | KeyCode::F(1) => show_help(),
    _ => {}
}
```

**Key Principles:**
- Display hotkeys prominently in status bars or help sections
- Use Vim-like bindings where appropriate (j/k for up/down)
- Make destructive actions require confirmation (e.g., 'd' then 'y' to confirm)
- Provide context-sensitive help per view

### Visual Hierarchy

Use contrast and positioning to guide users:

```rust
// High contrast for important elements
let title = Paragraph::new("Critical Alert")
    .style(Style::default().fg(Color::Red).add_modifier(Modifier::BOLD));

// Muted styles for secondary information
let hint = Paragraph::new("Press 'q' to quit")
    .style(Style::default().fg(Color::DarkGray));

// Highlight selected items
let selected_style = Style::default()
    .fg(Color::Black)
    .bg(Color::Yellow)
    .add_modifier(Modifier::BOLD);
```

**Design Rules:**
- Primary actions: Bright colors (Cyan, Yellow, Green)
- Secondary info: Muted colors (Gray, DarkGray)
- Errors/Warnings: Red/Orange with bold modifier
- Selected focus: High contrast (inverse or bright bg)
- Use borders to separate logical sections

### Immediate Visual Feedback

Users need instant feedback on every interaction:

```rust
// Show loading state
if app.is_loading {
    let spinner = ["\\", "|", "/", "-"][app.spinner_frame % 4];
    let loading = Paragraph::new(format!("{} Loading...", spinner))
        .style(Style::default().fg(Color::Cyan));
    f.render_widget(loading, status_area);
    app.spinner_frame += 1;
}

// Show confirmation messages
if let Some(message) = app.last_action {
    let toast = Paragraph::new(message)
        .style(Style::default().fg(Color::Green))
        .alignment(Alignment::Center);
    f.render_widget(toast, toast_area);
}
```

**Feedback Types:**
- **Progress indicators**: Spinners, progress bars for long operations
- **Status messages**: Temporary toast notifications for actions
- **Selection highlighting**: Always show what's currently focused
- **Mode indicators**: Clear visual distinction between modes (normal/insert)
- **Error states**: Red borders, shake animations, or error dialogs

### Responsive Layouts

Design for various terminal sizes (80, 132, 256 columns):

```rust
// Use flexible constraints
let chunks = Layout::default()
    .direction(Direction::Horizontal)
    .constraints([
        Constraint::Min(20),      // Minimum width for sidebar
        Constraint::Percentage(50), // Flexible main content
        Constraint::Max(40),      // Optional info panel
    ])
    .split(area);

// Hide optional panels on small screens
let show_sidebar = width > 100;
let show_info = width > 140 && height > 25;
```

**Responsive Patterns:**
- Always use `Min()` for minimum readable width
- Hide non-essential panels on small terminals
- Stack vertically when horizontal space is limited
- Test at 80x24, 120x40, and 200x60

## Usability & Accessibility

### Color Contrast Guidelines

Ensure readability across terminal emulators:

```rust
// Safe color combinations (high contrast)
let good_combo = Style::default().fg(Color::Yellow).bg(Color::Black);
let good_combo2 = Style::default().fg(Color::Cyan).bg(Color::Blue);

// Avoid low-contrast combinations
let bad_combo = Style::default().fg(Color::Green).bg(Color::Blue); // Hard to read
let bad_combo2 = Style::default().fg(Color::DarkGray).bg(Color::Black); // Too dim
```

**Color Best Practices:**
- Foreground should be significantly brighter than background
- Test with grayscale conversion (remove all color, check contrast)
- Provide themes for different terminal backgrounds (light/dark)
- Avoid red/green combinations (color blindness)
- Use text modifiers (bold, underline) as secondary indicators

### Screen Reader Support

TUIs have limited screen reader compatibility, but can improve:

```rust
// Provide text alternatives
let aria_label = format!("List of {} items, {} selected", items.len(), selected);
let descriptive_text = Paragraph::new(aria_label)
    .style(Style::default().fg(Color::DarkGray));

// Logical reading order (top-to-bottom, left-to-right)
// Avoid complex multi-pane layouts that confuse screen readers
```

**Accessibility Tips:**
- Offer a pure CLI fallback mode for screen reader users
- Use clear, descriptive labels (not just icons)
- Maintain consistent element ordering
- Provide verbose help text that explains context
- Document keyboard shortcuts in help section

### Discoverability

Make features findable without memorization:

```rust
// Context-sensitive help
fn render_help(f: &mut Frame, current_view: &str) {
    let help_text = match current_view {
        "list" => vec![
            "↑/k - Move up",
            "↓/j - Move down",
            "Enter - Select",
            "d - Delete",
            "a - Add new item",
            "? - Show all shortcuts",
        ],
        "editor" => vec![
            "i - Insert mode",
            "Esc - Normal mode",
            "dd - Delete line",
            "yy - Yank line",
            "p - Paste",
        ],
        _ => vec!["? - Show available commands"],
    };
    
    let help = List::new(help_text)
        .block(Block::bordered().title("Shortcuts"));
    f.render_widget(help, help_area);
}
```

**Discoverability Patterns:**
- Show most-used shortcuts in status bar
- Implement command palette (Ctrl+K or /) to search commands
- Provide tooltips on hover (mouse support)
- Contextual help that changes per view
- Progressive disclosure (basic help → full help)

### Error Handling & Recovery

Design forgiving interfaces:

```rust
// Confirmation for destructive actions
if action == Action::Delete && !app.confirmed {
    let dialog = ConfirmDialog::new("Delete this item?")
        .yes_label("Yes, delete")
        .no_label("Cancel")
        .danger();
    f.render_widget(dialog, popup_area);
    return; // Wait for confirmation
}

// Undo support
app.history.push(current_state.clone());
if action == Action::Undo {
    app.current_state = app.history.pop().unwrap();
}
```

**Error Prevention:**
- Require confirmation for destructive actions
- Provide undo/redo where possible
- Show preview before committing changes
- Clear error messages with recovery steps
- Auto-save work in progress

## Performance Optimization

### Minimize Redraws

Only update changed regions:

```rust
// Track what changed
if app.state_changed {
    terminal.draw(|f| render_app(f, &app))?;
    app.state_changed = false;
}

// Use Clear widget for popups to prevent bleeding
use ratatui::widgets::Clear;
Clear.render(popup_area, buf);
```

### Efficient Event Handling

```rust
// Debounce rapid events
let mut last_render = Instant::now();
let render_interval = Duration::from_millis(16); // ~60fps

if key_event.is_some() || last_render.elapsed() > render_interval {
    terminal.draw(|f| render_app(f, &app))?;
    last_render = Instant::now();
}
```

### Memory Management

```rust
// Pre-allocate buffers for repeated rendering
struct RenderCache {
    buffer: Vec<String>,
    last_modified: Instant,
}

// Reuse widget instances where possible
static BUTTON_STYLE: Lazy<Style> = Lazy::new(|| Style::default().fg(Color::Blue));
```

## Complete Example

```rust
use ratatui::{
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout},
    style::{Color, Stylize},
    widgets::{Block, Borders, Paragraph},
    Frame, Terminal,
};
use std::io;

struct App {
    counter: i32,
}

impl App {
    fn new() -> Self {
        Self { counter: 0 }
    }
    
    fn increment(&mut self) {
        self.counter += 1;
    }
    
    fn decrement(&mut self) {
        self.counter -= 1;
    }
    
    fn draw(&self, f: &mut Frame) {
        let chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([
                Constraint::Length(3),
                Constraint::Min(0),
            ])
            .split(f.area());

        let title = Paragraph::new(format!("Counter: {}", self.counter))
            .block(Block::bordered().title("Counter App"))
            .style(Style::default().fg(Color::Cyan))
            .centered();
        
        let instructions = Paragraph::new("Use UP/DOWN arrows, 'q' to quit")
            .block(Block::bordered().title("Instructions"))
            .style(Color::Gray)
            .centered();

        f.render_widget(title, chunks[0]);
        f.render_widget(instructions, chunks[1]);
    }
}

fn main() -> io::Result<()> {
    let backend = CrosstermBackend::new(io::stdout());
    let mut terminal = Terminal::new(backend)?;
    let mut app = App::new();

    loop {
        app.draw(&mut terminal);
        
        if let Ok(event) = terminal.read_event() {
            use ratatui::event::{Event, KeyCode, KeyEventKind};
            
            if let Event::Key(key) = event {
                if key.kind == KeyEventKind::Press {
                    match key.code {
                        KeyCode::Up => app.increment(),
                        KeyCode::Down => app.decrement(),
                        KeyCode::Char('q') => break,
                        _ => {}
                    }
                }
            }
        }
    }

    Ok(())
}
```

## Advanced State Management Patterns

### Model-View-Update (MVU/Elm Architecture)

Ideal for predictable data flow in complex TUIs:

```rust
use ratatui::{backend::CrosstermBackend, Terminal};
use std::io;

// MODEL: Application state
#[derive(Default)]
struct App {
    counter: i32,
    mode: AppMode,
    items: Vec<String>,
    selected: Option<usize>,
}

enum AppMode {
    Normal,
    Insert,
    Help,
}

// MESSAGES: Actions that trigger state changes
enum Msg {
    Increment,
    Decrement,
    AddItem(String),
    DeleteSelected,
    ToggleMode,
    Quit,
}

// UPDATE: State transformation logic
fn update(app: &mut App, msg: Msg) {
    match msg {
        Msg::Increment => app.counter += 1,
        Msg::Decrement => app.counter -= 1,
        Msg::AddItem(name) => {
            app.items.push(name);
            if app.selected.is_none() {
                app.selected = Some(0);
            }
        },
        Msg::DeleteSelected => {
            if let Some(idx) = app.selected {
                app.items.remove(idx);
                app.selected = if app.items.is_empty() {
                    None
                } else {
                    Some(idx.min(app.items.len() - 1))
                };
            }
        },
        Msg::ToggleMode => {
            app.mode = match app.mode {
                AppMode::Normal => AppMode::Help,
                AppMode::Help => AppMode::Normal,
                AppMode::Insert => AppMode::Normal,
            };
        },
        Msg::Quit => std::process::exit(0),
    }
}

// VIEW: Render function (pure, no side effects)
fn view(app: &App, frame: &mut ratatui::Frame) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),
            Constraint::Min(0),
            Constraint::Length(3),
        ])
        .split(frame.area());

    // Counter display
    let counter_text = format!("Counter: {}", app.counter);
    let counter = Paragraph::new(counter_text)
        .style(Style::default().fg(Color::Cyan))
        .block(Block::bordered().title("Counter"));
    frame.render_widget(counter, chunks[0]);

    // Item list
    let items: Vec<ListItem> = app.items
        .iter()
        .map(|i| ListItem::new(i.as_str()))
        .collect();
    
    let list = List::new(items)
        .block(Block::bordered().title("Items"))
        .highlight_style(Style::default().fg(Color::Yellow).add_modifier(Modifier::BOLD))
        .highlight_symbol(">> ");
    
    frame.render_stateful_widget(
        list,
        chunks[1],
        &mut ListState::default().with_selected(app.selected),
    );

    // Mode indicator
    let mode_text = match app.mode {
        AppMode::Normal => "Mode: Normal (↑/↓ to navigate, a to add, d to delete, ? for help)",
        AppMode::Help => "Mode: Help (Press '?' to close)",
        AppMode::Insert => "Mode: Insert (Not implemented)",
    };
    let mode = Paragraph::new(mode_text)
        .style(Style::default().fg(Color::Green))
        .block(Block::bordered().title("Status"));
    frame.render_widget(mode, chunks[2]);
}

// MAIN LOOP: Event handling and message dispatch
fn main() -> io::Result<()> {
    let backend = CrosstermBackend::new(io::stdout());
    let mut terminal = Terminal::new(backend)?;
    let mut app = App::default();

    loop {
        terminal.draw(|f| view(&app, f))?;

        if let Event::Key(key) = terminal.read_event()? {
            let msg = match key.code {
                KeyCode::Char('q') => Msg::Quit,
                KeyCode::Up | KeyCode::Char('k') => {
                    if let Some(selected) = app.selected {
                        app.selected = Some(if selected == 0 {
                            app.items.len().saturating_sub(1)
                        } else {
                            selected - 1
                        });
                        continue; // No message, direct state update
                    }
                    continue;
                },
                KeyCode::Down | KeyCode::Char('j') => {
                    if let Some(selected) = app.selected {
                        app.selected = Some((selected + 1) % app.items.len().max(1));
                        continue;
                    }
                    continue;
                },
                KeyCode::Char('a') => Msg::AddItem("New Item".to_string()),
                KeyCode::Char('d') => Msg::DeleteSelected,
                KeyCode::Char('?') => Msg::ToggleMode,
                _ => continue,
            };
            update(&mut app, msg);
        }
    }
}
```

### Flux Architecture Pattern

For complex applications with multiple stores:

```rust
use std::sync::{Arc, Mutex};
use crossbeam::channel::{unbounded, Sender, Receiver};

// Dispatcher: Central hub for all actions
struct Dispatcher {
    sender: Sender<Action>,
    subscribers: Vec<Box<dyn Fn(Action) + Send>>,
}

impl Dispatcher {
    fn new() -> Self {
        let (sender, receiver) = unbounded();
        let dispatcher = Self {
            sender,
            subscribers: Vec::new(),
        };
        
        // Spawn listener thread
        std::thread::spawn(move || {
            for action in receiver {
                // Broadcast to all subscribers
                // (simplified - real implementation needs proper synchronization)
            }
        });
        
        dispatcher
    }
    
    fn dispatch(&self, action: Action) {
        self.sender.send(action).unwrap();
    }
    
    fn subscribe(&mut self, callback: Box<dyn Fn(Action) + Send>) {
        self.subscribers.push(callback);
    }
}

// Actions: Describe what happened
enum Action {
    UserPressedKey(KeyCode),
    DataLoaded(Vec<String>),
    ErrorOccurred(String),
    TimerTick,
}

// Stores: Hold application state
struct ItemStore {
    items: Vec<String>,
    selected: Option<usize>,
}

impl ItemStore {
    fn on_action(&mut self, action: &Action) {
        match action {
            Action::DataLoaded(new_items) => {
                self.items = new_items.clone();
                self.selected = Some(0);
            },
            Action::UserPressedKey(KeyCode::Char('d')) => {
                if let Some(idx) = self.selected {
                    self.items.remove(idx);
                }
            },
            _ => {}
        }
    }
}

// Views: Render based on store state
fn render_items(store: &ItemStore, frame: &mut Frame) {
    // Render logic here
}
```

### Component-Based Architecture

Object-oriented approach with trait-based components:

```rust
trait Component {
    fn render(&mut self, frame: &mut Frame, area: Rect);
    fn handle_events(&mut self, event: &Event) -> Option<Action>;
    fn update(&mut self, action: Action);
}

struct Sidebar {
    items: Vec<String>,
    selected: usize,
}

impl Component for Sidebar {
    fn render(&mut self, frame: &mut Frame, area: Rect) {
        let list = List::new(self.items.clone())
            .block(Block::bordered().title("Sidebar"));
        frame.render_stateful_widget(
            list,
            area,
            &mut ListState::default().with_selected(Some(self.selected)),
        );
    }
    
    fn handle_events(&mut self, event: &Event) -> Option<Action> {
        if let Event::Key(key) = event {
            match key.code {
                KeyCode::Up => {
                    self.selected = self.selected.saturating_sub(1);
                },
                KeyCode::Down => {
                    self.selected = (self.selected + 1) % self.items.len().max(1);
                },
                _ => {}
            }
        }
        None
    }
    
    fn update(&mut self, _action: Action) {
        // Handle state updates
    }
}

struct MainContent {
    // ...
}

impl Component for MainContent {
    // ...
}

struct App {
    sidebar: Sidebar,
    main: MainContent,
}

impl App {
    fn render(&mut self, frame: &mut Frame) {
        let chunks = Layout::default()
            .direction(Direction::Horizontal)
            .constraints([Constraint::Length(20), Constraint::Min(0)])
            .split(frame.area());
        
        self.sidebar.render(frame, chunks[0]);
        self.main.render(frame, chunks[1]);
    }
    
    fn handle_event(&mut self, event: Event) {
        if let Some(action) = self.sidebar.handle_events(&event) {
            self.sidebar.update(action.clone());
            self.main.update(action);
        }
    }
}
```

## Widget Composition & Custom Recipes

### Composing Widgets

Build complex UIs by combining simple widgets:

```rust
fn render_card(frame: &mut Frame, area: Rect, title: &str, content: &str) {
    let block = Block::bordered()
        .title(title)
        .border_style(Style::default().fg(Color::Blue))
        .border_type(BorderType::Rounded);
    
    let inner = block.inner(area);
    let paragraph = Paragraph::new(content)
        .style(Style::default().fg(Color::White))
        .wrap(Wrap { trim: true });
    
    frame.render_widget(block, area);
    frame.render_widget(paragraph, inner);
}

// Usage
render_card(frame, area, "Info", "Some important data here...");
```

### Custom Widget: Progress Bar

```rust
use ratatui::{
    buffer::Buffer,
    layout::Rect,
    style::{Color, Style},
    widgets::{Widget, Block},
};

struct ProgressBar {
    percentage: u16,
    label: String,
    block: Option<Block<'static>>,
}

impl ProgressBar {
    fn new(percentage: u16) -> Self {
        Self {
            percentage,
            label: String::new(),
            block: None,
        }
    }
    
    fn label(mut self, label: impl Into<String>) -> Self {
        self.label = label.into();
        self
    }
    
    fn block(mut self, block: Block<'static>) -> Self {
        self.block = Some(block);
        self
    }
}

impl Widget for ProgressBar {
    fn render(self, area: Rect, buf: &mut Buffer) {
        let inner = self.block.map_or(area, |b| {
            let inner = b.inner(area);
            b.render(area, buf);
            inner
        });
        
        if inner.width < 2 || inner.height < 1 {
            return;
        }
        
        // Draw bar
        let bar_width = inner.width.saturating_sub(2) as u16;
        let filled = (bar_width * self.percentage) / 100;
        
        let mut x = inner.x + 1;
        for i in 0..bar_width {
            let cell = if i < filled { "█" } else { "░" };
            let style = if i < filled {
                Style::default().fg(Color::Green)
            } else {
                Style::default().fg(Color::DarkGray)
            };
            buf.set_string(x, inner.y, cell, style);
            x += 1;
        }
        
        // Draw label
        if !self.label.is_empty() {
            let label = format!(" {}% ", self.percentage);
            buf.set_string(
                inner.x + bar_width + 1,
                inner.y,
                &label,
                Style::default().fg(Color::White),
            );
        }
    }
}

// Usage
let progress = ProgressBar::new(75)
    .label("Loading")
    .block(Block::bordered().title("Progress"));
frame.render_widget(progress, area);
```

### Custom Widget: Modal Dialog

```rust
use ratatui::{
    buffer::Buffer,
    layout::Rect,
    style::{Color, Style},
    widgets::{Block, Borders, Clear, Paragraph, Widget},
};

struct Modal {
    title: String,
    message: String,
    width: u16,
    height: u16,
}

impl Modal {
    fn new(title: impl Into<String>, message: impl Into<String>) -> Self {
        Self {
            title: title.into(),
            message: message.into(),
            width: 60,
            height: 10,
        }
    }
}

impl Widget for Modal {
    fn render(self, area: Rect, buf: &mut Buffer) {
        // Calculate centered position
        let x = area.x + (area.width.saturating_sub(self.width)) / 2;
        let y = area.y + (area.height.saturating_sub(self.height)) / 2;
        let modal_area = Rect::new(x, y, self.width, self.height);
        
        // Clear area to prevent content bleeding
        Clear.render(modal_area, buf);
        
        // Render modal content
        let block = Block::default()
            .title(self.title)
            .borders(Borders::ALL)
            .border_style(Style::default().fg(Color::Yellow))
            .style(Style::default().bg(Color::Black));
        
        let inner = block.inner(modal_area);
        block.render(modal_area, buf);
        
        let paragraph = Paragraph::new(self.message)
            .style(Style::default().fg(Color::White))
            .wrap(Wrap { trim: true });
        paragraph.render(inner, buf);
    }
}

// Usage
let modal = Modal::new("Alert", "Operation completed successfully.");
frame.render_widget(modal, frame.area());
```

### Reusable Layout Helpers

```rust
fn centered_rect(percent_x: u16, percent_y: u16, r: Rect) -> Rect {
    let popup_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage((100 - percent_y) / 2),
            Constraint::Percentage(percent_y),
            Constraint::Percentage((100 - percent_y) / 2),
        ])
        .split(r);
    
    Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage((100 - percent_x) / 2),
            Constraint::Percentage(percent_x),
            Constraint::Percentage((100 - percent_x) / 2),
        ])
        .split(popup_layout[1])[1]
}

// Usage for popups
let popup_area = centered_rect(60, 40, frame.area());
```

### Styled Text Building Blocks

```rust
use ratatui::{
    style::{Color, Modifier, Style},
    text::{Line, Span, Text},
    widgets::Paragraph,
};

fn build_styled_header(title: &str, subtitle: &str) -> Paragraph {
    let title_line = Line::from(vec![
        Span::styled(title, Style::default()
            .fg(Color::Cyan)
            .add_modifier(Modifier::BOLD)),
        Span::raw(" - "),
        Span::styled(subtitle, Style::default()
            .fg(Color::Gray)
            .add_modifier(Modifier::DIM)),
    ]);
    
    let text = Text::from(vec![title_line]);
    Paragraph::new(text)
        .alignment(Alignment::Center)
        .block(Block::bordered().title("Header"))
}
```

## Ecosystem Libraries

An effects and animation library for Ratatui applications. Build complex animations by composing and layering simple effects, bringing smooth transitions and visual polish to the terminal.

```toml
# Cargo.toml
[dependencies]
tachyonfx = "0.2"
```

Key features:
- Compose and layer simple effects
- Smooth transitions and visual polish
- Interactive demo available at https://junkdog.github.io/tachyonfx-ftl/

### Mousefood

An embedded-graphics backend for Ratatui. Supports `no_std` environments.

```toml
# Cargo.toml
[dependencies]
mousefood = "0.1"
```

Key features:
- Use Ratatui with embedded displays
- Works with various embedded-graphics draw targets
- Example: Tuitar - guitar learning tool built with Ratatui & Mousefood

### Ratzilla

Build terminal-themed web applications with Rust and WebAssembly.

```toml
# Cargo.toml
[dependencies]
ratzilla = "0.1"
```

Key features:
- Run Ratatui apps in the browser
- Demo available at https://ratatui.github.io/ratzilla/demo/

### tui-logger

A logger and smart widget for ratatui — captures `log` records into a circular
buffer and renders them in a scrollable pane with a per-target level selector.

```toml
# Cargo.toml
[dependencies]
tui-logger = "0.14"
```

Initialize once at startup, then render the widget in your draw loop:

```rust
use tui_logger::{init_logger, TuiLoggerWidget};

fn main() {
    init_logger(log::LevelFilter::Trace).unwrap();
    tui_logger::set_default_level(log::LevelFilter::Debug);
    // ... app loop ...
}

// In the draw closure:
frame.render_widget(
    TuiLoggerWidget::default()
        .block(Block::bordered().title("Logs")),
    area,
);
```

Key features:
- Hot buffer (1000 entries) + main buffer (10000) so logging never blocks the UI thread — `move_events()` drains hot into main every 10ms
- Per-target capture and display levels, toggled at runtime via the target selector widget
- `slog` and `tracing-subscriber` support (features `slog-support`, `tracing-support`)
- `wait()` / `wait_timeout()` (feature `waiter`) for event-loop-driven redraws without polling
- Env-var config (`RUST_LOG`) via `set_env_filter_from_env()`
- Custom formatters via `LogFormatter`
- File logging alongside the widget

Smart widget key commands (driven by feeding `TuiWidgetEvent` to `TuiWidgetState::transition()`):

| Key | Action |
|-----|--------|
| `h` | Toggle target selector visibility |
| `f` | Focus selected target only |
| `+` / `-` | Increase / decrease captured level |
| `Right` / `Left` | Increase / decrease shown level |
| `PageUp` / `PageDown` | Page mode scroll through history |
| `Esc` | Exit page mode |
| `Space` | Hide targets with no enabled level |

Run the demo: `cargo run --example demo --features crossterm`

- **Repository**: https://github.com/gin66/tui-logger
- **Docs**: https://docs.rs/tui-logger/
- **DeepWiki**: https://deepwiki.com/gin66/tui-logger

## Third-Party Widgets Showcase

Ratatui has a vibrant ecosystem of third-party widgets:

- **ratatui-image** - Image widget with multiple graphics protocol backends (sixel, iTerm2, kitty, etc.)
- **ratatui-textarea** - Multi-line text editor widget like HTML `<textarea>`
- **throbber-widgets-tui** - Activity indicator, progress bar, loading icon, spinner
- **tui-big-text** - Renders large pixel text using font8x8 glyphs
- **tui-checkbox** - Customizable checkbox widget with custom styling and symbols
- **tui-logger** - Widget for capturing and displaying logs
- **tui-menu** - Menu widget for rendering nestable menus
- **tui-nodes** - Node graph visualization widget
- **tui-piechart** - Versatile pie chart widget with multiple symbol sets
- **tui-scrollview** - Widget for creating scrollable views
- **tui-term** - Pseudoterminal widget
- **tui-tree-widget** - Tree data structure visualization widget
- **tui-widget-list** - Stateful widget list implementation for Ratatui

## Application Recipes

### Better Panic Hooks

Use `better-panic` for pretty backtraces and `human-panic` for user-friendly error handling:

```toml
# Cargo.toml
[dependencies]
better-panic = "0.3"
human-panic = "1.2"
color-eyre = "0.6"
libc = "1.0"
strip-ansi-escapes = "0.2"
```

```rust
use better_panic::Settings;

pub fn initialize_panic_handler() {
    std::panic::set_hook(Box::new(|panic_info| {
        // Exit terminal cleanly
        crossterm::execute!(std::io::stderr(), crossterm::terminal::LeaveAlternateScreen).unwrap();
        crossterm::terminal::disable_raw_mode().unwrap();
        
        // Show pretty backtrace
        Settings::auto()
            .most_recent_first(false)
            .lineno_suffix(true)
            .create_panic_handler()(panic_info);
    }));
}
```

For release builds, use human-panic for user-friendly messages:

```rust
use human_panic::{handle_dump, print_msg, Metadata};

pub fn initialize_panic_handler() -> Result<()> {
    std::panic::set_hook(Box::new(move |panic_info| {
        let meta = Metadata::new(env!("CARGO_PKG_NAME"), env!("CARGO_PKG_VERSION"))
            .authors(format!("authored by {}", env!("CARGO_PKG_AUTHORS")))
            .support(format!("You can open a support request at {}", env!("CARGO_PKG_REPOSITORY")));
        
        let file_path = handle_dump(&meta, panic_info);
        print_msg(file_path, &meta).expect("human-panic: printing error message failed");
        std::process::exit(libc::EXIT_FAILURE);
    }));
    Ok(())
}
```

### Color-Eyre Error Hooks

Use color_eyre for beautiful error reports:

```toml
# Cargo.toml
[dependencies]
color-eyre = "0.6"
```

```rust
use color_eyre::Result;

fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;
    let terminal = tui::init()?;
    let result = run(terminal).wrap_err("run failed");
    if let Err(err) = tui::restore() {
        eprintln!("failed to restore terminal: {err}");
    }
    result
}

fn set_panic_hook() {
    let hook = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |panic_info| {
        let _ = restore();
        hook(panic_info);
    }));
}
```

### Terminal and Event Handler

Create a reusable Tui struct with Terminal and EventHandler:

```toml
# Cargo.toml
[dependencies]
ratatui = "0.28"
tokio = { version = "1", features = ["sync", "task", "time"] }
tokio-util = "0.7"
futures = "0.3"
color-eyre = "0.6"
```

```rust
use std::ops::{Deref, DerefMut};
use std::time::Duration;

use color_eyre::eyre::Result;
use futures::{FutureExt, StreamExt};
use ratatui::backend::CrosstermBackend as Backend;
use ratatui::crossterm::{
    cursor,
    event::{DisableBracketedPaste, DisableMouseCapture, EnableBracketedPaste, EnableMouseCapture, Event as CrosstermEvent, KeyEvent, KeyEventKind, MouseEvent},
    terminal::{EnterAlternateScreen, LeaveAlternateScreen},
};
use serde::{Deserialize, Serialize};
use tokio::{sync::mpsc::{self, UnboundedReceiver, UnboundedSender}, task::JoinHandle};
use tokio_util::sync::CancellationToken;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum Event {
    Init, Quit, Error, Closed, Tick, Render,
    FocusGained, FocusLost, Paste(String),
    Key(KeyEvent), Mouse(MouseEvent), Resize(u16, u16),
}

pub struct Tui {
    pub terminal: ratatui::Terminal<Backend<std::io::Stderr>>,
    pub task: JoinHandle<()>,
    pub cancellation_token: CancellationToken,
    pub event_rx: UnboundedReceiver<Event>,
    pub event_tx: UnboundedSender<Event>,
}

impl Tui {
    pub fn new() -> Result<Self> {
        let terminal = ratatui::Terminal::new(Backend::new(std::io::stderr()))?;
        let (event_tx, event_rx) = mpsc::unbounded_channel();
        let cancellation_token = CancellationToken::new();
        let task = tokio::spawn(async {});
        Ok(Self { terminal, task, cancellation_token, event_tx, event_rx })
    }

    pub fn enter(&mut self) -> Result<()> {
        crossterm::terminal::enable_raw_mode()?;
        crossterm::execute!(std::io::stderr(), EnterAlternateScreen, cursor::Hide)?;
        if self.mouse {
            crossterm::execute!(std::io::stderr(), EnableMouseCapture)?;
        }
        self.start();
        Ok(())
    }

    pub fn exit(&mut self) -> Result<()> {
        self.stop()?;
        if crossterm::terminal::is_raw_mode_enabled()? {
            self.flush()?;
            if self.mouse {
                crossterm::execute!(std::io::stderr(), DisableMouseCapture)?;
            }
            crossterm::execute!(std::io::stderr(), LeaveAlternateScreen, cursor::Show)?;
            crossterm::terminal::disable_raw_mode()?;
        }
        Ok(())
    }

    pub async fn next(&mut self) -> Option<Event> {
        self.event_rx.recv().await
    }
}

impl Drop for Tui {
    fn drop(&mut self) {
        self.exit().unwrap();
    }
}
```

### CLI Arguments

Use clap for command-line argument parsing:

```toml
# Cargo.toml
[dependencies]
clap = { version = "4", features = ["derive"] }
```

```rust
use clap::Parser;

#[derive(Parser, Debug)]
#[command(version = version(), about = "My TUI App")]
struct Args {
    /// App tick rate in milliseconds
    #[arg(short, long, default_value_t = 1000)]
    tick_rate: u64,
    
    /// Enable mouse support
    #[arg(short, long)]
    mouse: bool,
}

fn main() {
    let args = Args::parse();
    // Use args.tick_rate, args.mouse, etc.
}
```

## Widget Recipes

### Custom Widgets

Create custom widgets by implementing the Widget trait:

```rust
use ratatui::{buffer::Buffer, layout::Rect, widgets::Widget, style::Color};

pub struct MyWidget {
    content: String,
}

impl Widget for MyWidget {
    fn render(self, area: Rect, buf: &mut Buffer) {
        buf.set_string(area.left(), area.top(), &self.content, Style::default().fg(Color::Green));
    }
}
```

For stateful widgets, use StatefulWidget:

```rust
use ratatui::{buffer::Buffer, layout::Rect, widgets::StatefulWidget, style::Style};

pub struct ListWidget {
    items: Vec<String>,
}

pub struct ListState {
    selected: usize,
}

impl StatefulWidget for ListWidget {
    type State = ListState;

    fn render(self, area: Rect, buf: &mut Buffer, state: &mut Self::State) {
        // Render items, highlight selected one based on state.selected
    }
}
```

### Block Widget

Use Block for framing and titling widgets:

```rust
use ratatui::widgets::{Block, BorderType, Borders};

let block = Block::default()
    .title("Header")
    .borders(Borders::ALL);

// Multiple titles with alignment
let block = Block::default()
    .title(Line::from("Left").left_aligned())
    .title(Line::from("Center").centered())
    .title(Line::from("Right").right_aligned())
    .border_style(Style::default().fg(Color::Magenta))
    .border_type(BorderType::Rounded)
    .borders(Borders::ALL);

f.render_widget(block, area);
```

### Paragraph Widget

Display text with wrapping, alignment, and styling:

```rust
use ratatui::widgets::{Block, Borders, Paragraph, Wrap, Alignment};

// Basic usage
let p = Paragraph::new("Hello, World!");

// With styling and borders
let p = Paragraph::new("Hello, World!")
    .style(Style::default().fg(Color::Yellow))
    .block(Block::default()
        .borders(Borders::ALL)
        .title("Title")
        .border_type(BorderType::Rounded));

// Wrapping
let p = Paragraph::new("A very long text...")
    .wrap(Wrap { trim: true });

// Alignment
let p = Paragraph::new("Centered Text")
    .alignment(Alignment::Center);

// Styled text with Spans
let p = Paragraph::new(Text::from(vec![
    Line::from(vec![
        Span::styled("Hello ", Style::default().fg(Color::Yellow)),
        Span::styled("World", Style::default().fg(Color::Blue).bg(Color::White)),
    ])
]));

// Scrolling
let mut p = Paragraph::new("Long content...")
    .scroll((1, 0));  // Vertical, horizontal scroll
```

## Rendering Recipes

### Overwrite Regions (Popups)

Use the Clear widget to prevent content bleeding:

```rust
use ratatui::widgets::{Block, Borders, Clear, Paragraph, Widget};

struct Popup {
    title: String,
    content: String,
}

impl Widget for Popup {
    fn render(self, area: Rect, buf: &mut Buffer) {
        // Clear area first to avoid leaking content
        Clear.render(area, buf);
        
        let block = Block::new()
            .title(self.title)
            .borders(Borders::ALL);
        
        Paragraph::new(self.content)
            .block(block)
            .render(area, buf);
    }
}

// Usage
frame.render_widget(popup, popup_area);
```

### Displaying Text

Use Span, Line, and Text for styled text:

```rust
use ratatui::{prelude::*, widgets::*};

// Span - styled text segment
let span = Span::raw("unstyled");
let span = Span::styled("styled", Style::default().fg(Color::Yellow));
let span = "using stylize trait".yellow();  // via Stylize trait

// Line - collection of Spans
let line = Line::from(vec![
    "hello".red(),
    " ".into(),
    "world".red().bold()
]);
let line = Line::from("hello world");
let line: Line = "hello world".yellow().into();
let line = Line::from("hello world").centered();

// Text - collection of Lines
let text = Text::from(vec![
    Line::from("line 1"),
    Line::from("line 2").blue(),
]);
let text = Text::from("multi\nline\ntext");

// Use with Paragraph
f.render_widget(Paragraph::new(text).block(Block::bordered()), area);
```

## Backend Concepts

Ratatui supports multiple backends for terminal interaction:

### Crossterm Backend (Default)

```toml
# Cargo.toml
[dependencies]
ratatui = { version = "0.28", default-features = false, features = ["crossterm"] }
crossterm = "0.28"
```

```rust
use ratatui::backend::CrosstermBackend;
use ratatui::Terminal;
use std::io::stdout;

let backend = CrosstermBackend::new(stdout());
let mut terminal = Terminal::new(backend)?;
```

### Termion Backend

```toml
# Cargo.toml
[dependencies]
ratatui = { version = "0.28", features = ["termion"] }
termion = "1.5"
```

```rust
use ratatui::backend::TermionBackend;
use ratatui::Terminal;
use std::io::stdout;

let backend = TermionBackend::new(stdout());
let mut terminal = Terminal::new(backend)?;
```

### Termwiz Backend

```toml
# Cargo.toml
[dependencies]
ratatui = { version = "0.28", features = ["termwiz"] }
termwiz = "0.22"
```

```rust
use ratatui::backend::TermwizBackend;
use ratatui::Terminal;
use termwiz::caps::Caps;

let backend = TermwizBackend::new(Caps::new()?);
let mut terminal = Terminal::new(backend)?;
```

### Test Backend

Useful for unit testing:

```rust
use ratatui::backend::TestBackend;
use ratatui::Terminal;

let backend = TestBackend::new(80, 20);
let mut terminal = Terminal::new(backend);

// Render and check output
terminal.draw(|frame| {
    frame.render_widget(Paragraph::new("Test"), frame.area());
}).unwrap();

// Assert on terminal.backend() content
```

### no_std Support (v0.30+)

Full `no_std` compilation for embedded targets (ESP32, STM32H7, PSP, UEFI):

```toml
# Cargo.toml
[dependencies]
ratatui = { version = "0.30", default-features = false }

# For embedded without allocator, also add:
# Use custom backend like mousefood
mousefood = "0.1"

# For atomic types (v0.30.1+)
ratatui = { version = "0.30.1", default-features = false, features = ["layout-cache"] }
```

```rust
// In your lib.rs
#![no_std]

extern crate alloc;

// Use with custom backend for no_std
use ratatui::backend::Backend;
```

Requirements for no_std:
- Global allocator (e.g., `alloc`)
- Atomic types (use `portable-atomic` feature if needed)

### Execution API (v0.30+)

Simplified terminal lifecycle with `ratatui::run()`:

```rust
use ratatui::{ratatui, Terminal};

ratatui::run(|terminal| {
    // Your app loop
    loop {
        terminal.draw(|frame| {
            // Render your app
        })?;
        
        // Handle events...
        break; // Exit
    }
    Ok(())
})?;
```

Manual lifecycle with `init()` and `restore()`:

```rust
use ratatui::Terminal;

let backend = CrosstermBackend::new(std::io::stdout());
ratatui::init()?;  // Initialize terminal (alternate screen, raw mode)

let terminal = Terminal::new(backend)?;

// ... your app ...

ratatui::restore()?;  // Restore terminal (leave alternate screen)
```

### Mouse Capture

Each backend handles mouse capture differently. Enable mouse events:

```rust
use ratatui::crossterm::event::{EnableMouseCapture, DisableMouseCapture};

// Enable mouse capture
crossterm::execute!(stderr(), EnableMouseCapture)?;

// In your event handling
if let Event::Mouse(mouse_event) = event {
    match mouse_event.kind {
        MouseEventKind::LeftClick { column, row } => { /* handle click */ }
        MouseEventKind::ScrollDown => { /* handle scroll */ }
        _ => {}
    }
}

// Disable on exit
crossterm::execute!(stderr(), DisableMouseCapture)?;
```

## Testing Recipes

### Snapshot Testing with Insta

Use insta and TestBackend for snapshot testing:

```toml
# Cargo.toml
[dev-dependencies]
insta = "1.39"
```

```rust
use insta::assert_snapshot;
use ratatui::{backend::TestBackend, Terminal, widgets::Paragraph};

#[test]
fn test_render_app() {
    let app = App::default();
    let mut terminal = Terminal::new(TestBackend::new(80, 20)).unwrap();
    terminal
        .draw(|frame| frame.render_widget(&app, frame.area()))
        .unwrap();
    assert_snapshot!(terminal.backend());
}
```

Run tests and accept snapshots:
```bash
cargo test
cargo insta review  # Review and accept changes
```

### Debug Widget State

Render debug info for development:

```rust
struct AppState {
    show_debug: bool,
    // your app state
}

fn render(frame: &mut Frame, state: &AppState) {
    // Create area for debug view (0 width when disabled)
    let debug_width = u16::from(state.show_debug);
    let [main, debug] = Layout::horizontal([
        Constraint::Fill(1),
        Constraint::Fill(debug_width)
    ]).areas(frame.area());
    
    // Render main content
    frame.render_widget(&state.content, main);
    
    // Render debug info when enabled
    if state.show_debug {
        let debug_text = Text::from(format!("state: {state:#?}"));
        frame.render_widget(debug_text, debug);
    }
}

// Toggle with a key (e.g., 'd' key)
KeyCode::Char('d') => state.show_debug = !state.show_debug,
```

## References

### Official Resources
- **Official Documentation**: https://docs.rs/ratatui/
- **GitHub Repository**: https://github.com/ratatui-org/ratatui
- **Official Examples**: https://github.com/ratatui-org/ratatui/tree/main/examples
- **Crossterm Backend**: https://docs.rs/crossterm/
- **Ratatui Book**: https://ratatui.rs/

### Ecosystem Libraries
- **Tachyonfx (Animations)**: https://ratatui.rs/ecosystem/tachyonfx/
- **Mousefood (Embedded)**: https://ratatui.rs/ecosystem/mousefood/
- **Ratzilla (WebAssembly)**: https://ratatui.rs/ecosystem/ratzilla/
- **tui-logger (Logging)**: https://github.com/gin66/tui-logger
- **Third-Party Widgets**: https://ratatui.rs/showcase/third-party-widgets/

### Official Recipes
- **Better Panic Handling**: https://ratatui.rs/recipes/apps/better-panic/
- **Color Eyre Errors**: https://ratatui.rs/recipes/apps/color-eyre/
- **Terminal Event Handler**: https://ratatui.rs/recipes/apps/terminal-and-event-handler/
- **CLI Arguments**: https://ratatui.rs/recipes/apps/cli-arguments/
- **Testing Snapshots**: https://ratatui.rs/recipes/testing/snapshots/
- **Debug Widget State**: https://ratatui.rs/recipes/testing/debug-widget-state/
- **Custom Widgets**: https://ratatui.rs/recipes/widgets/custom/
- **Block Widget**: https://ratatui.rs/recipes/widgets/block/
- **Paragraph Widget**: https://ratatui.rs/recipes/widgets/paragraph/
- **Overwrite Regions (Popups)**: https://ratatui.rs/recipes/render/overwrite-regions/
- **Display Text**: https://ratatui.rs/recipes/render/display-text/

### Concepts & Architecture
- **Backends Overview**: https://ratatui.rs/concepts/backends/
- **Mouse Capture**: https://ratatui.rs/concepts/backends/mouse-capture/

### Community & Inspiration
- **Awesome Ratatui**: https://github.com/ratatui-org/awesome-ratatui
- **Ratatui Discord**: https://discord.gg/p2wdh46R6d
- **Ratatui Twitter/X**: https://twitter.com/ratatui_rs