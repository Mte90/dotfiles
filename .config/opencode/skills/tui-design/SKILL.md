---
name: tui-design
description: This skill should be used when designing terminal user interfaces, creating TUI layouts, choosing TUI color schemes, implementing keyboard navigation, building terminal dashboards, or working with any TUI framework. Activates on mentions of TUI design, terminal UI, Ratatui layout, Ink components, Textual widgets, Bubbletea views, terminal color palette, keybinding design, panel layout, split panes, terminal dashboard, box-drawing characters, sparklines, progress bars, modal dialogs, focus management, or terminal accessibility.
---

# TUI Design System

Universal design patterns for building exceptional terminal user interfaces. Framework-agnostic — works with Ratatui, Ink, Textual, Bubbletea, or any TUI toolkit.

**Core philosophy:** TUIs earn their power through spatial consistency, keyboard fluency, and information density that respects human attention. Design for the expert's speed without abandoning the beginner's discoverability.

## TUI Design Process

Pick paradigm → design interaction model → define visual system → validate against anti-patterns → ship. (Detailed flowchart in `references/motion-rendering.md` appendix.)

## 1. Layout Paradigm Selector

| App Type           | Paradigm                 | Examples            |
| ------------------ | ------------------------ | ------------------- |
| File manager       | Miller Columns           | yazi, ranger        |
| Git / DevOps tool  | Persistent Multi-Panel   | lazygit, lazydocker |
| System monitor     | Widget Dashboard         | btop, bottom, oxker |
| Data browser / K8s | Drill-Down Stack         | k9s, diskonaut      |
| SQL / HTTP client  | IDE Three-Panel          | harlequin, posting  |
| Shell augmentation | Overlay / Popup          | atuin, fzf          |
| Log / event viewer | Header + Scrollable List | htop, tig           |

- **Persistent Multi-Panel** — simultaneous context (git clients, container managers); panels keep fixed positions across sessions, never rearrange without user action.
- **Miller Columns** — hierarchical navigation: parent / current / preview; preview content adapts to selection type (code → highlighting, dirs → contents).
- **Drill-Down Stack** — `Enter` descends, `Esc` ascends; always show the navigation breadcrumb; `:resource` command mode for direct jumps.
- **Widget Dashboard** — self-contained panels, no navigation; braille/block characters for high-density data.
- **IDE Three-Panel** — sidebar + editor/main (tabs) + detail output; sidebar toggles with one key; bottom panel expands full-height.
- **Overlay / Popup** — appears over the shell on demand, returns selection to caller, never disrupts scrollback.
- **Header + Scrollable List** — fixed header with meters, scrollable data, function bar; sort by the most actionable dimension by default.

ASCII mockups for the visual paradigms: [references/layout-galleries.md](references/layout-galleries.md).

## 2. Responsive Terminal Design

| Strategy               | When                                                                        |
| ---------------------- | --------------------------------------------------------------------------- |
| **Proportional split** | Panels maintain percentage ratios on resize                                 |
| **Priority collapse**  | Less important panels hide first below minimum width                        |
| **Stacking**           | Panels collapse to title-only bars, active one expands (zellij pattern)     |
| **Breakpoint modes**   | Switch layout entirely below a threshold (e.g., multi-panel → single panel) |
| **Minimum size gate**  | Display "terminal too small" if below usable minimum                        |

Rules: define a minimum size (typically 80x24); never crash on resize (handle `SIGWINCH`); constraint-based layouts (percentages, min/max, ratios), not absolute positions; test at 80x24, 120x40, 200x60.

## 3. Interaction Model

**Navigation styles:** single-purpose <20 actions → direct keybinding · multi-view complex → vim-style modes + contextual footer · IDE-like → command palette + tabs + vim motions · data browser → drill-down + fuzzy search + `:` command mode.

**Keyboard layers:**

| Layer               | Keys                                         | Audience      | Always show? |
| ------------------- | -------------------------------------------- | ------------- | ------------ |
| **L0: Universal**   | Arrow keys, Enter, Esc, q                    | Everyone      | Yes (footer) |
| **L1: Vim motions** | hjkl, /, ?, :, gg, G                         | Intermediate  | Yes (footer) |
| **L2: Actions**     | Single mnemonics: d(elete), c(ommit), p(ush) | Regular users | On `?` help  |
| **L3: Power**       | Composed commands, macros, custom bindings   | Power users   | Docs only    |

Lingua franca: `j`/`k` down/up · `h`/`l` left/right · `/` search · `?` help · `:` command mode · `q` quit (or `Esc` back one level) · `Enter` select/confirm/drill · `Tab` switch focus · `Space` toggle · `g`/`G` top/bottom.
**Never bind:** `Ctrl+C`, `Ctrl+Z`, `Ctrl+\` — they belong to the terminal.

**Focus:** one widget receives input at a time; `Tab`/`Shift+Tab` cycle; focus = highlighted border/color/cursor; unfocused panels dim; modal dialogs are focus traps; outer containers route events to focused children.

**Search:** `/` + live filtering (`n`/`N` next/prev, `Esc` dismiss), fuzzy by default, `'` prefix = exact, highlight matched chars, preview updates for the highlighted result.

**Help tiers:** footer (3-5 essential shortcuts, context-sensitive, current-actions only) · `?` overlay (full keybindings for the active context) · docs (`--help`, man). Footer format: `[q]uit [/]search [?]help [Tab]focus [Enter]select`.

**Severity-matched dialogs:** reversible → just do it + status-bar note · moderate (delete file) → inline "press y to confirm" · severe (drop database) → modal requiring resource-name input · irreversible batch → `--dry-run` + explicit confirm. Modals render over dimmed background; toasts auto-dismiss 3-5s; status messages auto-fade.

## 4. Color System — Core

| Tier           | Escape Sequence          | Strategy                                              |
| -------------- | ------------------------ | ----------------------------------------------------- |
| **16 ANSI**    | `\033[31m`               | Foundation. Terminal theme controls appearance.       |
| **256 Color**  | `\033[38;5;{n}m`         | Extended palette. Fixed colors may clash with themes. |
| **True Color** | `\033[38;2;{r};{g};{b}m` | Full control. Requires `COLORTERM=truecolor`.         |

Detection: `$COLORTERM` truecolor/24bit → 256color in `$TERM` → `$NO_COLOR` disables all → default 16 ANSI.

**Golden rule:** the TUI must be *usable* in 16-color mode. True color enhances — it never creates the hierarchy.

Semantic slots (never hardcode hex in widget code): `fg.default` body · `fg.muted` metadata · `fg.emphasis` headers/focused · `bg.base`/`bg.surface`/`bg.overlay` layered backgrounds · `bg.selection` · `accent.primary`/`accent.secondary` interactive · `status.error`/`warning`/`success`/`info`.

**Hierarchy recipe:** 80% of content in `fg.default`; headers in bold + `fg.emphasis`; metadata in dim + `fg.muted`; status colors for status; accents for interactive elements only.

**Accessibility (binding):** WCAG AA contrast (4.5:1 body, 3:1 large/UI); never color alone — pair with symbols, labels, position; colorblind-safe pairs (blue+orange, blue+yellow, black+white; avoid relying on red vs green).

Theme architecture (Base16, light/dark detection), background layering depth, SGR technique table, and the test matrix → [references/theme-system.md](references/theme-system.md).

## 5. Data Visualization

| Element          | Characters                | Resolution    | Use For                             |
| ---------------- | ------------------------- | ------------- | ----------------------------------- |
| **Full blocks**  | `█▉▊▋▌▍▎▏`                | 8 steps/cell  | Progress bars, bar charts           |
| **Shade blocks** | `░▒▓█`                    | 4 densities   | Heatmaps, density plots             |
| **Braille**      | `⠁⠂⠃...⣿` (U+2800-U+28FF) | 2x4 dots/cell | High-res line graphs, scatter plots |
| **Sparkline**    | `▁▂▃▄▅▆▇█`                | 8 heights     | Inline mini-charts                  |

| Widget           | Pattern                           | Key tips                                                            |
| ---------------- | --------------------------------- | -------------------------------------------------------------------- |
| **Progress bar** | `[████████░░░░] 67%`              | Percentage + ETA; color gradient green→yellow→red by urgency        |
| **Sparkline**    | `▁▂▃▅▇█▇▅▃▂`                      | Inline time-series in headers/status bars                           |
| **Gauge**        | `CPU [██████████░░] 83%`          | Label + bar + value; color by threshold                             |
| **Table**        | Sortable columns, zebra stripes   | Numbers right / text left; truncate with `…`                         |
| **Tree**         | `├── `, `└── `, `│   ` guides     | 2-4 chars per level; expand/collapse with Enter                      |
| **Diff**         | Green `+`, red `-`               | Word-level highlighting within changed lines elevates quality      |
| **Log**          | Level, timestamp, message        | TRACE=dim, DEBUG=cyan, INFO=default, WARN=yellow, ERROR=red+bold     |

Spinner selection table and indeterminate-state policies → [references/motion-rendering.md](references/motion-rendering.md).

## 6. Animation — Binding Rule

**Animations must never delay user input.** A key pressed during a transition cancels it and responds immediately. Cap dashboard refresh at 15-30 FPS; differential updates (redraw only changed cells); stream text at reading pace; background operations go to the status bar, never the main loop.

Flicker-free rendering stack (double buffering, synchronized output `CSI ? 2026`, batched writes) and the when-to-animate table → [references/motion-rendering.md](references/motion-rendering.md).

## 7. The Seven Design Principles

1. **Keyboard-first, mouse-optional** — every feature accessible via keyboard; `Shift+click` bypasses mouse capture for text selection.
2. **Spatial consistency** — panels stay in fixed positions; tabs are stable landmarks.
3. **Progressive disclosure** — footer floor, `?` ceiling, docs sky.
4. **Async everything** — never freeze the UI; all long ops background + progress + `Esc` cancel.
5. **Semantic color** — color encodes meaning; stripped of all color the interface must remain usable.
6. **Contextual intelligence** — keybindings, status, and help show what is actionable right now.
7. **Design in layers** — monochrome (usable?) → 16 ANSI (readable?) → true color (beautiful?); each tier stands alone.

## 8. Anti-Pattern Checklist

| #   | Anti-Pattern                             | Fix                                                                           |
| --- | ---------------------------------------- | ----------------------------------------------------------------------------- |
| 1   | **Colors break on different terminals**  | Use 16 ANSI colors as foundation. Test 3+ emulators + light/dark themes.      |
| 2   | **Flickering / full redraws**            | Double buffer + synchronized output + batched writes. Overwrite, never clear. |
| 3   | **Undiscoverable keybindings**           | Context-sensitive footer + `?` help overlay + Which-Key-style hints.          |
| 4   | **Broken on Windows / WSL**              | Test on Windows Terminal. Avoid advanced Unicode beyond box-drawing.          |
| 5   | **Unicode rendering inconsistency**      | Stick to box-drawing + block elements. Restrict emoji to Unicode 9.0.         |
| 6   | **Terminal multiplexer incompatibility** | Test inside tmux and zellij. Mouse capture must not break selection.          |
| 7   | **No accessibility support**              | Respect `NO_COLOR`, provide monochrome mode, never color-only meaning.        |
| 8   | **Blocking UI during operations**         | Show feedback within 100ms. Use async + spinners + progress bars.             |
| 9   | **Modal confusion**                       | Always show current mode in status bar. Cursor shape changes per mode.        |
| 10  | **Over-decorated chrome**                | Borders and colors serve content, not ego. The content IS the interface.      |

## 9. Compatibility Checklist

- [ ] Works at 80x24 minimum terminal size; handles resize without crash
- [ ] Correct on dark AND light themes; respects `NO_COLOR`
- [ ] Works inside tmux / zellij / screen and over SSH
- [ ] Mouse capture doesn't break text selection (`Shift+click`); all features keyboard-only accessible
- [ ] No ANSI leaks to piped output; clean exit on `Ctrl+C` (terminal state restored)

## References

- [references/layout-galleries.md](references/layout-galleries.md) — ASCII mockups per layout paradigm
- [references/theme-system.md](references/theme-system.md) — theme architecture, SGR techniques, background layering, test matrix
- [references/motion-rendering.md](references/motion-rendering.md) — flicker-free stack, when-to-animate, spinner selection
- [references/visual-catalog.md](references/visual-catalog.md) — Unicode character tables and border style gallery
- [references/app-patterns.md](references/app-patterns.md) — real-world TUI app design analysis
