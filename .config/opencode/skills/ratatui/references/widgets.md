# Widget Recipes

Loaded on demand — entry point is ../SKILL.md

## Paragraph

Display text with styling, wrapping, and alignment.

```rust
use ratatui::widgets::{Block, Borders, Paragraph, Wrap, Alignment};

// Basic
let p = Paragraph::new("Hello, World!");

// With styling and borders
let p = Paragraph::new("Hello, World!")
    .style(Style::default().fg(Color::Yellow))
    .block(Block::default().borders(Borders::ALL).title("Title"));

// Wrapping
let p = Paragraph::new("A very long text...").wrap(Wrap { trim: true });

// Alignment
let p = Paragraph::new("Centered Text").alignment(Alignment::Center);

// Styled text with Spans
let p = Paragraph::new(Text::from(vec![
    Line::from(vec![
        Span::styled("Hello ", Style::default().fg(Color::Yellow)),
        Span::styled("World", Style::default().fg(Color::Blue)),
    ])
]));

// Scrolling
let mut p = Paragraph::new("Long content...").scroll((1, 0));
```

## Block

Frame and title other widgets.

```rust
use ratatui::widgets::{Block, BorderType, Borders};

let block = Block::default()
    .title("Header")
    .borders(Borders::ALL)
    .border_style(Style::default().fg(Color::Magenta))
    .border_type(BorderType::Rounded);

// Multiple titles with alignment
let block = Block::default()
    .title(Line::from("Left").left_aligned())
    .title(Line::from("Center").centered())
    .title(Line::from("Right").right_aligned());

// Border merging (v0.30+)
use ratatui::widgets::MergeStrategy;
let block = Block::bordered().merge_strategy(MergeStrategy::Merge);

// New border types (v0.30+)
BorderType::LightDoubleDashed
BorderType::HeavyDoubleDashed
BorderType::LightTripleDashed
BorderType::HeavyTripleDashed
```

## Button

Clickable buttons with pressed state.

```rust
use ratatui::widgets::Button;

let button = Button::default()
    .text("Click Me")
    .style(Style::default().fg(Color::White).bg(Color::Blue))
    .pressed_style(Style::default().fg(Color::Blue).bg(Color::White));

f.render_widget(button, area);
```

## Checkbox

Boolean toggle with custom symbols.

```rust
use ratatui::widgets::Checkbox;

let checkbox = Checkbox::new("Enable feature", true)
    .style(Style::default().fg(Color::White))
    .check_style(Style::default().fg(Color::Green));
```

## List

Selectable item lists.

```rust
use ratatui::widgets::{List, ListItem};

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

f.render_stateful_widget(list, area, &mut list_state);
```

## Table

Tabular data with column selection and cell selection (v0.29+).

```rust
use ratatui::widgets::{Table, Row, Cell, TableState};

let rows = vec![
    Row::new(vec!["Row1", "Data1"]),
    Row::new(vec!["Row2", "Data2"]),
];

let table = Table::new(rows, &[Constraint::Length(10), Constraint::Min(20)])
    .block(Block::bordered().title("Table"))
    .row_highlight_style(Style::default().fg(Color::Yellow));

f.render_stateful_widget(table, area, &mut table_state);
```

### Column Span (v0.30.1+)

```rust
let rows = vec![
    Row::new(vec![
        Cell::new("Name").column_span(2),
        Cell::new("Score"),
    ]),
];
```

### Column Selection (v0.29+)

```rust
table.select_column(2);
table.select_first_column();
table.select_next_column();
table.select_cell();
table.scroll_right_by(2);
```

## Gauge

Progress percentage display.

```rust
use ratatui::widgets::Gauge;

let gauge = Gauge::default()
    .label("Progress")
    .gauge_style(Style::default().fg(Color::Green))
    .percent(75);
```

## Sparkline

Compact data visualization with absent value handling (v0.29+).

```rust
use ratatui::widgets::Sparkline;

let data = vec![1, 5, 3, 7, 2, 8, 5, 3, 6, 4];

let sparkline = Sparkline::default()
    .data(&data)
    .style(Style::default().fg(Color::Cyan))
    .bar_set(" ▎▏");

// Absent values (v0.29+)
let data = vec![Some(1), Some(5), None, Some(3), Some(0), None];
let sparkline = Sparkline::default()
    .data(&data)
    .absent_value_style(Style::default().fg(Color::DarkGray))
    .absent_value_symbol('·');
```

## Chart

Multi-dataset plots with axes and markers (v0.30+).

```rust
use ratatui::widgets::{Chart, Axis, Dataset, Marker, GraphType};

let data = vec![(0.0, 1.0), (1.0, 3.0), (2.0, 2.0), (3.0, 5.0)];

let chart = Chart::new(vec![Dataset::default()
    .data(&data)
    .name("Series")
    .style(Style::default().fg(Color::Cyan))])
    .block(Block::bordered().title("Chart"))
    .x_axis(Axis::default().bounds([0.0, 4.0]))
    .y_axis(Axis::default().bounds([0.0, 6.0]));

// New markers (v0.30+)
chart.marker(Marker::Quadrant);   // 2x2 pseudo-pixel
chart.marker(Marker::Sextant);    // 2x3 resolution
chart.marker(Marker::Octant);     // 2x4 resolution
chart.marker(Marker::Custom('x'));

// Filled area (v0.30.1+)
Dataset::default()
    .graph_type(GraphType::Area)
    .fill_to_y(0.0);
```

## Canvas

Custom drawing with various marker types.

```rust
use ratatui::widgets::{Canvas, FilledLine, Marker};

let canvas = Canvas::default()
    .marker(Marker::Quadrant)
    .paint(|ctx| {
        ctx.draw(&FilledLine {
            x1: 0.0, y1: 0.0, x2: 10.0, y2: 5.0,
            color: Color::Blue,
        });
    });
```

## Calendar

Date display with Chrono.

```rust
use ratatui::widgets::{Calendar, Chrono};

let calendar = Calendar::default()
    .block(Block::bordered().title("2024"))
    .chrono(Chrono::Monthly)
    .show_months(true);
```

## RatatuiLogo & RatatuiMascot

```rust
use ratatui::widgets::{RatatuiLogo, RatatuiMascot};

let logo = RatatuiLogo::tiny();  // or .small()
let mascot = RatatuiMascot::default().eye_color(Color::Yellow);
```

## Fill

Paint entire area with same symbol (v0.30.1+).

```rust
use ratatui::widgets::Fill;

let fill = Fill::new("█")
    .style(Style::default().fg(Color::Blue).bg(Color::Black));
f.render_widget(fill, area);
```

## Custom Widget: Progress Bar

```rust
use ratatui::{buffer::Buffer, layout::Rect, style::Color, widgets::Widget, Block};

struct ProgressBar {
    percentage: u16,
    label: String,
    block: Option<Block<'static>>,
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

        if !self.label.is_empty() {
            let label = format!(" {}% ", self.percentage);
            buf.set_string(inner.x + bar_width + 1, inner.y, &label, Style::default().fg(Color::White));
        }
    }
}
```

## Custom Widget: Modal Dialog

```rust
use ratatui::{buffer::Buffer, layout::Rect, style::Color, widgets::{Block, Borders, Clear, Paragraph, Widget}};

struct Modal {
    title: String,
    message: String,
    width: u16,
    height: u16,
}

impl Widget for Modal {
    fn render(self, area: Rect, buf: &mut Buffer) {
        let x = area.x + (area.width.saturating_sub(self.width)) / 2;
        let y = area.y + (area.height.saturating_sub(self.height)) / 2;
        let modal_area = Rect::new(x, y, self.width, self.height);

        Clear.render(modal_area, buf);

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
```

## Reusable Layout Helpers

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

// Usage
let popup_area = centered_rect(60, 40, frame.area());
```

## Styled Text Building Blocks

```rust
use ratatui::{style::{Color, Modifier, Style}, text::{Line, Span, Text}, widgets::Paragraph};

fn build_styled_header(title: &str, subtitle: &str) -> Paragraph {
    let title_line = Line::from(vec![
        Span::styled(title, Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD)),
        Span::raw(" - "),
        Span::styled(subtitle, Style::default().fg(Color::Gray).add_modifier(Modifier::DIM)),
    ]);

    let text = Text::from(vec![title_line]);
    Paragraph::new(text)
        .alignment(Alignment::Center)
        .block(Block::bordered().title("Header"))
}
```

## Rendering: Clear for Popups

```rust
use ratatui::widgets::{Block, Borders, Clear, Paragraph, Widget};

struct Popup {
    title: String,
    content: String,
}

impl Widget for Popup {
    fn render(self, area: Rect, buf: &mut Buffer) {
        Clear.render(area, buf);  // Prevent content bleeding

        let block = Block::new().title(self.title).borders(Borders::ALL);
        Paragraph::new(self.content).block(block).render(area, buf);
    }
}
```

## Third-Party Widgets Showcase

- **ratatui-image** - Image widget with graphics protocol backends (sixel, iTerm2, kitty)
- **ratatui-textarea** - Multi-line text editor widget
- **throbber-widgets-tui** - Activity indicator, spinner
- **tui-checkbox** - Customizable checkbox with custom symbols
- **tui-logger** - Widget for capturing and displaying logs
- **tui-menu** - Menu widget with nested submenus
- **tui-nodes** - Node graph visualization
- **tui-piechart** - Pie chart widget
- **tui-scrollview** - Scrollable view widget
- **tui-term** - Pseudoterminal widget
- **tui-tree-widget** - Tree data structure visualization
- **tui-widget-list** - Stateful widget list implementation