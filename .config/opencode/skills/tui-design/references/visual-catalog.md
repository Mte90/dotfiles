# TUI Visual Catalog

Pure reference material for terminal visual elements. Scan, don't read.

## Box-Drawing Characters

### Light (standard TUI borders)

```
┌───┬───┐    Corners: ┌ ┐ └ ┘
│   │   │    T-pieces: ├ ┤ ┬ ┴
├───┼───┤    Cross:    ┼
│   │   │    Lines:    ─ │
└───┴───┘
```

### Heavy (emphasis borders)

```
┏━━━┳━━━┓    Corners: ┏ ┓ ┗ ┛
┃   ┃   ┃    T-pieces: ┣ ┫ ┳ ┻
┣━━━╋━━━┫    Cross:    ╋
┃   ┃   ┃    Lines:    ━ ┃
┗━━━┻━━━┛
```

### Double (classic DOS/Norton style)

```
╔═══╦═══╗    Corners: ╔ ╗ ╚ ╝
║   ║   ║    T-pieces: ╠ ╣ ╦ ╩
╠═══╬═══╣    Cross:    ╬
║   ║   ║    Lines:    ═ ║
╚═══╩═══╝
```

### Rounded (modern, friendly)

```
╭───┬───╮    Corners: ╭ ╮ ╰ ╯
│   │   │    (T-pieces, cross, lines
├───┼───┤     same as light set)
│   │   │
╰───┴───╯
```

### Mixed: Heavy Header + Light Body

```
┏━━━━━━━━━━━━━━━━━━━━┓
┃  Panel Title        ┃
┡━━━━━━━━━━━━━━━━━━━━┩
│  Content here       │
│  using light lines  │
└─────────────────────┘
```

### When to Use Which

| Style             | Use Case                                           |
| ----------------- | -------------------------------------------------- |
| Light `─│`        | Default panel borders, dividers, tables            |
| Heavy `━┃`        | Active/focused panel, headers, emphasis            |
| Double `═║`       | Legacy/retro aesthetic, prominent sections         |
| Rounded `╭╯`      | Modern/friendly feel, cards, tooltips              |
| Mixed heavy+light | Focus indicator (heavy = active, light = inactive) |
| No border         | Background layering sufficient, minimal aesthetic  |

---

## Block Elements

### Fractional Blocks (horizontal, left-to-right fill)

```
▏ ▎ ▍ ▌ ▋ ▊ ▉ █
```

1/8 through 8/8 width. Use for sub-character precision in horizontal bar charts.

### Fractional Blocks (vertical, bottom-to-top fill)

```
▁ ▂ ▃ ▄ ▅ ▆ ▇ █
```

1/8 through 8/8 height. Use for sparklines and vertical bar charts.

### Shade Blocks

```
░ Light shade (25%)
▒ Medium shade (50%)
▓ Dark shade (75%)
█ Full block (100%)
```

Use for density visualization, heatmaps, and background patterns.

### Progress Bar Recipes

```
Simple:     [████████░░░░░░] 57%
Gradient:   [█████▓▒░░░░░░░] 57%
Thin:       ━━━━━━━━╸━━━━━━ 57%
Braille:    ⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀ 57%
Minimal:    ■■■■■■□□□□□□ 57%
```

---

## Braille Patterns (U+2800–U+28FF)

Each braille character is a 2-column × 4-row dot grid, encoding 8 bits:

```
Dot positions:    ⠁(1) ⠂(2) ⠄(3) ⡀(7)
                  ⠈(4) ⠐(5) ⠠(6) ⢀(8)

Combined: ⣿ = all dots    ⠀ = empty (blank braille)
```

Use for high-resolution terminal graphics. Each character cell provides 2×4 = 8 sub-pixels, enabling line charts, scatter plots, and pixel art at 2× horizontal and 4× vertical resolution.

### Sparkline with Braille

```
Network: ⣀⣤⣶⣿⣶⣤⣀⣀⣤⣶⣿⣿⣶⣤  Peak: 1.2 MB/s
```

---

## Status Indicators

### Dots and Bullets

```
●  Filled circle (active, online, enabled)
○  Empty circle (inactive, offline, disabled)
◉  Bullseye (selected, current)
◆  Filled diamond (important, pinned)
◇  Empty diamond (available, optional)
```

### Check and Cross

```
✓  Check mark (success, done, yes)      ✔  Heavy check
✗  Ballot X (failure, error, no)        ✘  Heavy X
☐  Unchecked checkbox                   ☑  Checked checkbox
```

### Severity/Priority

```
▲  Up triangle (increase, higher, expand)
▼  Down triangle (decrease, lower, collapse)
⚠  Warning sign
ℹ  Information
⬤  Large circle (status dot)
```

### Arrows

```
Navigation:  ← → ↑ ↓    ⇐ ⇒ ⇑ ⇓
Triangles:   ◀ ▶ ▲ ▼    ◁ ▷ △ ▽
Pointers:    ► ◄         ‣
Powerline:   ▏            (thin separator)
```

---

## Tree Drawing

### Standard Tree

```
├── src/
│   ├── main.rs
│   ├── lib.rs
│   └── utils/
│       ├── config.rs
│       └── helpers.rs
├── tests/
│   └── integration.rs
└── Cargo.toml
```

Characters: `├── ` (branch), `└── ` (last branch), `│   ` (continuation), `    ` (spacing)

### Compact Tree (for narrow panels)

```
├ src/
│ ├ main.rs
│ └ utils/
│   └ config.rs
└ Cargo.toml
```

---

## Table Formatting

### Standard Table

```
┌──────┬────────┬───────┐
│ Name │ Status │ CPU % │
├──────┼────────┼───────┤
│ web  │ ● Run  │  23.4 │
│ db   │ ● Run  │   8.1 │
│ cache│ ○ Stop │   0.0 │
└──────┴────────┴───────┘
```

### Minimal Table (no outer border)

```
 Name   Status   CPU %
 ─────  ──────   ─────
 web    ● Run     23.4
 db     ● Run      8.1
 cache  ○ Stop     0.0
```

### Zebra Stripe (alternating background)

Use `bg.surface` on even rows, `bg.base` on odd rows for scanability.

---

## Separator Styles

```
Light:     ────────────────────────
Heavy:     ━━━━━━━━━━━━━━━━━━━━━━━━
Double:    ════════════════════════
Dashed:    ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌
Dotted:    ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
Mixed:     ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
Labeled:   ──── Section Title ──────
```

---

## Diff Presentation

### Inline (unified)

```
  fn process(data: &str) {     (context - default color)
-     let result = parse(data); (removed - red + dim)
+     let result = parse_v2(data); (added - green)
      result.validate()         (context - default color)
  }
```

### Side-by-Side

```
│ fn process(data: &str) {     │ fn process(data: &str) {     │
│-  let result = parse(data);  │+  let result = parse_v2(data);│
│   result.validate()          │   result.validate()          │
```

Word-level diff highlighting within changed lines dramatically improves readability. Highlight the changed words/tokens, not just the whole line.

---

## Gauge Patterns

```
CPU:  [████████████████████░░░░░░░░░░] 67%
Mem:  [███████████████░░░░░░░░░░░░░░░] 50%  8.0G/16.0G
Disk: [██████████████████████████████] 99%  ← red when >90%
Bat:  [████████░░░░░░░░░░░░░░░░░░░░░] 27%  ⚡ charging
```

Color thresholds: green (0-60%), yellow (60-80%), red (80-100%).

---

## Common Nerd Font Icons

Only use when Nerd Font detection is available. Always provide a Unicode/ASCII fallback.

```
Nerd Font → Fallback
        → >     (directory/folder)
        → *     (file)
        → ⚙     (settings/config)
        → ●     (git branch)
        → ✓     (success)
        → ✗     (error)
        → ⚠     (warning)
        → ℹ     (info)
```

**Rule:** Never assume Nerd Fonts are installed. Always define a fallback using standard Unicode or ASCII.
