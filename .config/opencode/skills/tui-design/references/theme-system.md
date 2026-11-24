# Theme & Color System — Deep Reference

Companion to SKILL.md §4 (Color System — Core).

## Visual Hierarchy Techniques

Color is one tool among several — combine them:

| Technique                 | Effect                  | Use For                              |
| ------------------------- | ----------------------- | ------------------------------------ |
| **Bold** (SGR 1)          | Increases visual weight | Headers, labels, active items        |
| **Dim** (SGR 2)           | Decreases visual weight | Metadata, timestamps, secondary info |
| **Italic** (SGR 3)        | Semantic distinction    | Comments, types, annotations         |
| **Underline** (SGR 4)     | Links, actionable items | Clickable elements, URLs             |
| **Reverse** (SGR 7)       | Swaps fg/bg             | Selection highlight (always works!)  |
| **Strikethrough** (SGR 9) | Negation                | Deleted items, deprecated features   |

## Background Layering

Create depth without borders by layering background lightness:

```
bg.base (darkest) → bg.surface → bg.overlay (lightest)
```

Each step ~5-8% lighter in dark themes. The eye perceives depth from the contrast gradient — this reduces the need for box-drawing borders while maintaining clear visual zones.

## Theme Architecture

Follow the Base16 pattern: 16 named color slots mapped semantically:

- **8 monotones** (base00-base07): background/foreground gradient
- **8 accents** (base08-base0F): syntax/semantic colors

Ship a dark theme by default. Detect light/dark terminal via OSC escape query or `terminal-light` crate. Provide at least one light variant. Respect `NO_COLOR`.

Typical dark-theme slot mapping:

| Slot               | Purpose                     | Typical value          |
| ------------------ | --------------------------- | ---------------------- |
| `fg.default`       | Body text                   | Off-white (#c0caf5)    |
| `fg.muted`         | Secondary text, metadata    | Gray (#565f89)         |
| `fg.emphasis`      | Headers, focused items      | Bright white (#e0e0e0) |
| `bg.base`          | Primary background          | Near-black (#1a1b26)   |
| `bg.surface`       | Panel/widget backgrounds    | Slightly lighter (#24283b) |
| `bg.overlay`       | Popup/dialog backgrounds    | Lighter still (#414868)|
| `bg.selection`     | Selected item highlight     | Distinct (#364a82)     |
| `accent.primary`   | Interactive elements, focus | Brand color (#7aa2f7)  |
| `accent.secondary` | Supporting interactions     | Complementary (#bb9af7)|
| `status.error`     | Errors, deletions           | Red (#f7768e)          |
| `status.warning`   | Warnings, caution           | Yellow (#e0af68)      |
| `status.success`   | Success, additions          | Green (#9ece6a)       |
| `status.info`      | Informational               | Cyan (#7dcfff)        |

## Accessibility Test Matrix

- **Contrast:** WCAG AA — 4.5:1 for body text, 3:1 for large text/UI elements.
- **Never color alone:** pair with symbols (checkmark, X, triangle), text labels, position, or typography.
- **Color-blind-safe pairs:** blue+orange, blue+yellow, black+white. Never rely on red vs green.
- **Test on:** monochrome mode, a color-blindness simulator, 3+ terminal emulators, light and dark themes.
