# Application Recipes

## Better Panic Hooks

Use `better-panic` for pretty backtraces and `human-panic` for user-friendly error handling.

```toml
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
        crossterm::execute!(std::io::stderr(), crossterm::terminal::LeaveAlternateScreen).unwrap();
        crossterm::terminal::disable_raw_mode().unwrap();

        Settings::auto()
            .most_recent_first(false)
            .lineno_suffix(true)
            .create_panic_handler()(panic_info);
    }));
}
```

For release builds, use human-panic:

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

## Color-Eyre Error Hooks

```toml
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

## Terminal and Event Handler

```toml
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

## CLI Arguments

```toml
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

## Backend Concepts

### Crossterm Backend (Default)

```toml
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

```rust
use ratatui::backend::TestBackend;
use ratatui::Terminal;

let backend = TestBackend::new(80, 20);
let mut terminal = Terminal::new(backend);

terminal.draw(|frame| {
    frame.render_widget(Paragraph::new("Test"), frame.area());
}).unwrap();
```

### no_std Support (v0.30+)

```toml
[dependencies]
ratatui = { version = "0.30", default-features = false }
mousefood = "0.1"
ratatui = { version = "0.30.1", default-features = false, features = ["layout-cache"] }
```

```rust
#![no_std]

extern crate alloc;

use ratatui::backend::Backend;
```

Requirements:
- Global allocator (e.g., `alloc`)
- Atomic types (use `portable-atomic` feature if needed)

### Execution API (v0.30+)

```rust
use ratatui::{ratatui, Terminal};

ratatui::run(|terminal| {
    loop {
        terminal.draw(|frame| {
            // Render your app
        })?;

        break; // Exit
    }
    Ok(())
})?;
```

Manual lifecycle:

```rust
use ratatui::Terminal;

let backend = CrosstermBackend::new(std::io::stdout());
ratatui::init()?;

let terminal = Terminal::new(backend)?;

// ... your app ...

ratatui::restore()?;
```

### Mouse Capture

```rust
use ratatui::crossterm::event::{EnableMouseCapture, DisableMouseCapture};

crossterm::execute!(stderr(), EnableMouseCapture)?;

if let Event::Mouse(mouse_event) = event {
    match mouse_event.kind {
        MouseEventKind::LeftClick { column, row } => { /* handle click */ }
        MouseEventKind::ScrollDown => { /* handle scroll */ }
        _ => {}
    }
}

crossterm::execute!(stderr(), DisableMouseCapture)?;
```