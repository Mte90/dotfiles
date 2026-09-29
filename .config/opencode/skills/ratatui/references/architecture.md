# Advanced State Management

## Model-View-Update (MVU/Elm Architecture)

Predictable data flow for complex TUIs.

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

    let counter_text = format!("Counter: {}", app.counter);
    let counter = Paragraph::new(counter_text)
        .style(Style::default().fg(Color::Cyan))
        .block(Block::bordered().title("Counter"));
    frame.render_widget(counter, chunks[0]);

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
                        continue;
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

## Flux Architecture Pattern

For complex applications with multiple stores.

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
        let dispatcher = Self { sender, subscribers: Vec::new() };

        std::thread::spawn(move || {
            for action in receiver {
                // Broadcast to all subscribers
            }
        });

        dispatcher
    }

    fn dispatch(&self, action: Action) {
        self.sender.send(action).unwrap();
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
```

## Component-Based Architecture

Object-oriented approach with trait-based components.

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

## State Management with Widgets

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