---
name: ratatui
description: "Rust terminal UI framework - widgets, components, layouts, events, input handling, and state management for TUI apps"
metadata:
  author: mte90
  version: "1.0.0"
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

## Ecosystem Libraries

### Tachyonfx

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

- **Official Documentation**: https://docs.rs/ratatui/
- **GitHub Repository**: https://github.com/ratatui-org/ratatui
- **Examples**: https://github.com/ratatui-org/ratatui/tree/main/examples
- **Crossterm Backend**: https://docs.rs/crossterm/
- **Ecosystem - Tachyonfx**: https://ratatui.rs/ecosystem/tachyonfx/
- **Ecosystem - Mousefood**: https://ratatui.rs/ecosystem/mousefood/
- **Ecosystem - Ratzilla**: https://ratatui.rs/ecosystem/ratzilla/
- **Showcase - Third Party Widgets**: https://ratatui.rs/showcase/third-party-widgets/
- **Recipes - Better Panic**: https://ratatui.rs/recipes/apps/better-panic/
- **Recipes - Color Eyre**: https://ratatui.rs/recipes/apps/color-eyre/
- **Recipes - Terminal and Event Handler**: https://ratatui.rs/recipes/apps/terminal-and-event-handler/
- **Recipes - CLI Arguments**: https://ratatui.rs/recipes/apps/cli-arguments/
- **Recipes - Testing Snapshots**: https://ratatui.rs/recipes/testing/snapshots/
- **Recipes - Debug Widget State**: https://ratatui.rs/recipes/testing/debug-widget-state/
- **Recipes - Custom Widgets**: https://ratatui.rs/recipes/widgets/custom/
- **Recipes - Block**: https://ratatui.rs/recipes/widgets/block/
- **Recipes - Paragraph**: https://ratatui.rs/recipes/widgets/paragraph/
- **Recipes - Overwrite Regions**: https://ratatui.rs/recipes/render/overwrite-regions/
- **Recipes - Display Text**: https://ratatui.rs/recipes/render/display-text/
- **Concepts - Backends**: https://ratatui.rs/concepts/backends/
- **Concepts - Mouse Capture**: https://ratatui.rs/concepts/backends/mouse-capture/