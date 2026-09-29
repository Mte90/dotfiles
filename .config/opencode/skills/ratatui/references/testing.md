# Testing Recipes

## Snapshot Testing with Insta

Use insta and TestBackend for snapshot testing.

```toml
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

## Debug Widget State

Render debug info for development.

```rust
struct AppState {
    show_debug: bool,
    // your app state
}

fn render(frame: &mut Frame, state: &AppState) {
    let debug_width = u16::from(state.show_debug);
    let [main, debug] = Layout::horizontal([
        Constraint::Fill(1),
        Constraint::Fill(debug_width)
    ]).areas(frame.area());

    frame.render_widget(&state.content, main);

    if state.show_debug {
        let debug_text = Text::from(format!("state: {state:#?}"));
        frame.render_widget(debug_text, debug);
    }
}

// Toggle with a key (e.g., 'd' key)
KeyCode::Char('d') => state.show_debug = !state.show_debug,
```