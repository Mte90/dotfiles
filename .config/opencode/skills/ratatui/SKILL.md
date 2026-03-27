---
name: ratatui
description: "Rust terminal UI framework - widgets, components, layouts, events, input handling, and state management for TUI apps"
metadata:
  author: "OSS AI Skills"
  version: "1.0.0"
  tags:
    - rust
    - tui
    - terminal
    - cli
    - user-interface
    - ratatui
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
ratatui = "0.28"
```

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

## References

- **Official Documentation**: https://docs.rs/ratatui/
- **GitHub Repository**: https://github.com/ratatui-org/ratatui
- **Examples**: https://github.com/ratatui-org/ratatui/tree/main/examples
- **Crossterm Backend**: https://docs.rs/crossterm/