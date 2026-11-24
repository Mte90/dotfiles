# Layout Paradigm Galleries

ASCII mockups for the visual layout paradigms of the TUI Design System. Sizes assume ≥80x24 — adapt proportionally. Process flow: what are you building → select layout paradigm → design interaction model → define visual system → validate against anti-patterns → ship.

## Persistent Multi-Panel (lazygit, lazydocker)

All panels visible simultaneously; focus shifts between them; users build spatial memory ("branches are always top-left").

```
┌─ Status ──┬─────────── Detail ──────────┐
├─ Files ───┤                              │
│ > file.rs │  diff content here...        │
│   main.rs │                              │
├─ Branches ┤                              │
│ * main    │                              │
│   feat/x  │                              │
├─ Commits ─┤                              │
│ abc1234   │                              │
└───────────┴──────────────────────────────┘
  [q]uit [c]ommit [p]ush [?]help
```

Key rule: panels maintain fixed positions across sessions. Never rearrange without user action.

## Miller Columns (yazi, ranger)

Three-pane past/present/future navigation: parent directory (left), current (center), preview (right).

```
┌── Parent ──┬── Current ──┬── Preview ────────┐
│   ..       │ > config/   │ port: 8080        │
│   src/     │   lib/      │ host: localhost    │
│ > config/  │   main.rs   │ log_level: debug   │
│   tests/   │   mod.rs    │ db_url: postgres://│
└────────────┴─────────────┴───────────────────┘
```

Key rule: preview pane content adapts to selection type — code gets highlighting, images render, directories show contents.

## Widget Dashboard (btop, bottom)

Self-contained widget panels with independent data; no navigation required.

```
┌─── CPU ──────────────┬─── Memory ──────────┐
│ ▁▂▃▅▇█▇▅▃▂▁▂▃▅▇     │ ████████░░ 78%      │
│ core0: 45% core1: 67%│ 12.4G / 16.0G       │
├─── Network ──────────┼─── Disk ────────────┤
│ ▲ 1.2 MB/s  ▼ 340KB/s│ /: 67%  /home: 45%  │
├─── Processes ────────┴─────────────────────┤
│ PID   USER  CPU%  MEM%  CMD                 │
│ 1234  root  23.4  4.5   postgres             │
└─────────────────────────────────────────────┘
```

Key rule: each widget is self-contained with its own title; use braille/block characters for high-density data.

## Non-visual paradigms (spec in SKILL.md §1)

- **Drill-Down Stack** (k9s, diskonaut): `Enter` descends / `Esc` ascends; breadcrumb always visible; `:resource` direct jumps.
- **IDE Three-Panel** (harlequin, posting): sidebar + tabbed editor + expandable bottom output.
- **Overlay / Popup** (atuin, fzf): on-demand_overlay over the shell; returns selection; never disrupts scrollback.
- **Header + Scrollable List** (htop, tig): fixed metrics header, scrollable body, action bar; sort by the most actionable dimension.
