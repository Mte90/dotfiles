# Ecosystem Libraries

## tachyonfx

Effects and animation library for Ratatui applications.

```toml
[dependencies]
tachyonfx = "0.2"
```

Key features:
- Compose and layer simple effects
- Smooth transitions and visual polish
- Interactive demo: https://junkdog.github.io/tachyonfx-ftl/

## mousefood

Embedded-graphics backend for Ratatui. Supports `no_std`.

```toml
[dependencies]
mousefood = "0.1"
```

Key features:
- Use Ratatui with embedded displays
- Works with various embedded-graphics draw targets
- Example: Tuitar - guitar learning tool

## ratzilla

Build terminal-themed web applications with Rust and WebAssembly.

```toml
[dependencies]
ratzilla = "0.1"
```

Key features:
- Run Ratatui apps in the browser
- Demo: https://ratatui.github.io/ratzilla/demo/

## tui-logger

Logger and smart widget for ratatui.

```toml
[dependencies]
tui-logger = "0.14"
```

```rust
use tui_logger::{init_logger, TuiLoggerWidget};

fn main() {
    init_logger(log::LevelFilter::Trace).unwrap();
    tui_logger::set_default_level(log::LevelFilter::Debug);
}

// In the draw closure:
frame.render_widget(
    TuiLoggerWidget::default()
        .block(Block::bordered().title("Logs")),
    area,
);
```

Key features:
- Hot buffer (1000 entries) + main buffer (10000)
- Per-target capture and display levels
- `slog` and `tracing-subscriber` support
- `wait()` / `wait_timeout()` for event-loop-driven redraws
- Env-var config (`RUST_LOG`) via `set_env_filter_from_env()`

Smart widget commands:
| Key | Action |
|-----|--------|
| `h` | Toggle target selector |
| `f` | Focus selected target |
| `+` / `-` | Increase / decrease captured level |
| `Right` / `Left` | Increase / decrease shown level |
| `PageUp` / `PageDown` | Page mode scroll |
| `Esc` | Exit page mode |
| `Space` | Hide targets with no enabled level |

- **Repository**: https://github.com/gin66/tui-logger
- **Docs**: https://docs.rs/tui-logger/
- **DeepWiki**: https://deepwiki.com/gin66/tui-logger

## tui-breadcrumb

Customizable, interactive hierarchical breadcrumb navigation widget.

```toml
[dependencies]
tui-breadcrumb = "0.1"
```

Key features:
- Separator presets (`>`, `→`, `/`, custom)
- Five truncation strategies: `Middle`, `Start`, `ShortenNames`, `End`, `None`
- Interactive: keyboard and mouse navigation
- `Breadcrumb::from_path()` builds from `std::path::Path`
- Unicode-aware via `unicode-width`

- **Repository**: https://github.com/shadowmkj/tui-breadcrumb

## ratcn

Shadcn-inspired, themeable component library for Ratatui.

```toml
[dependencies]
ratcn = { version = "0.0.1", features = ["crossterm"] }
```

Key features:
- 12 components: `Button`, `List`, `Select`, `Tabs`, `Dialog`, `ToasterWidget`, `BarChartWidget`, `Tooltip`, `ScrollArea`, `Checkbox`, `Cycle`, `ProgressWidget`
- Full theme system (`Theme`); `Theme::adaptive` for terminal colors
- Browser build via `ratzilla` (WASM)
- Components are copy-into-your-project modules

> Preview status (0.0.1) — API will break; pin exact versions.

- **Documentation**: https://ratcn.kristoferlund.se/
- **Repository**: https://github.com/kristoferlund/ratcn

## edtui

Vim-inspired text editor widget for Ratatui.

```toml
[dependencies]
edtui = "0.11"
```

Key features:
- Vim keybindings (Emacs mode available)
- Custom keybindings and theming
- Mouse events
- Copy/paste to system clipboard
- Line wrapping and line numbers
- Syntax highlighting via syntect
- `system-editor` feature

- **Repository**: https://github.com/preiter93/edtui

## malevich

Terminal plotting library.

```toml
[dependencies]
malevich = { version = "1.17", features = ["ratatui"] }
```

Key features:
- 8 marks (line, points, bars, area, cells, range, rule, text)
- Statistical layer: box plots, KDE violins, trend lines, ECDFs, 2D densities
- ~10M points in tens of ms via M4 aggregation
- Extended-Wilkinson tick placement
- Rendering ladder: truecolor → 256 → 16 → ASCII
- `pixel` feature for sixel/kitty/iTerm2 images
- CLI tool `kaz` (`malevich-cli`)

- **Repository**: https://github.com/shergin/malevich
- **crates.io**: https://crates.io/crates/malevich

## ratatui-explorer

File explorer widget for Ratatui.

```toml
[dependencies]
ratatui-explorer = "0.3"
```

Key features:
- Input handling via crossterm, termion, or termwiz
- Theming/customization
- Toggle hidden files (Ctrl+h)
- Configurable keyboard bindings

- **Repository**: https://github.com/tatounee/ratatui-explorer

## ratatui-textarea

Multi-line text editor widget for Ratatui.

```toml
[dependencies]
ratatui-textarea = "0.9"
```

Key features:
- Multi-line editing with cursor, selection, clipboard
- Backend features: `crossterm`, `termion`, `termwiz`
- `search` feature (regex), `serde`, `arbitrary`

- **Repository**: https://github.com/ratatui/ratatui-textarea
- **crates.io**: https://crates.io/crates/ratatui-textarea

## ratatui-code-editor

Code editor widget with Tree-sitter syntax highlighting.

```toml
[dependencies]
ratatui-code-editor = { version = "0.0.6", features = ["crossterm"] }
```

Key features:
- Tree-sitter syntax highlighting (16 languages)
- Mouse support: clicks, scroll, selection
- Copy/paste via system clipboard (arboard)
- Undo/redo, visual text selection
- Customizable themes (`vesper` default)
- Diff views with expandable unchanged sections
- Code folding via Tree-sitter
- Emoji/Unicode aware

- **Repository**: https://github.com/vipmax/ratatui-code-editor

## ratatui-markdown

Markdown rendering for Ratatui.

```toml
[dependencies]
ratatui-markdown = { version = "0.3", features = ["preview"] }
```

Key features:
- Markdown: headings, lists, code blocks, blockquotes, tables, images
- Mermaid diagrams: sequence, pie, gantt, state (`mermaid` feature)
- Tree-sitter code-block highlighting
- Image support via `ImageResolver` (`image` feature)
- `RenderHooks` to override rendering
- Collapsible JSON/TOML trees
- `RichTheme` theming (15+ color slots)
- CJK-aware wrapping

> Licensed under Synthetic Source License (SySL) 1.0 — verify compatibility.

- **Repository**: https://github.com/celestia-island/ratatui-markdown

## tui-menu

Menu widget with nested submenu groups.

```toml
[dependencies]
tui-menu = "0.3"
```

Key features:
- Nested submenu groups (`MenuItem::group`)
- Intuitive keyboard movement
- Generic item data — any `Clone` type
- Stateful rendering + event draining

- **Repository**: https://github.com/shuoli84/tui-menu

## rat-widget

Extended widget library for ratatui.

```toml
[dependencies]
rat-widget = "3.2"
```

Key features:
- Extended widget library
- Companion event-loop crate (`rat-salsa`)
- Family of sibling widgets (menus, dialogs, popups, markdown, ftable, scrolled, focus, text, theme)

- **Repository**: https://github.com/thscharler/rat-salsa
- **crates.io**: https://crates.io/crates/rat-widget

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