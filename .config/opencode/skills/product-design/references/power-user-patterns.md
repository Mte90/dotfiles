# Power-User UX Patterns

Reference models: Linear, Figma, Raycast, VS Code, Superhuman, Arc Browser

These products share a philosophy: respect the user's time and intelligence. Every interaction is optimized for speed and flow state. Users spend hours per day in these tools, so every millisecond of friction compounds.

## Contents

- [Core Philosophy](#core-philosophy)
- [Interaction Patterns](#interaction-patterns)
- [Layout Patterns](#layout-patterns)
- [Data Density Guidelines](#data-density-guidelines)
- [Performance Perception](#performance-perception)

---

## Core Philosophy

**Speed is the feature.** Not just performance speed — interaction speed. How many keystrokes, clicks, and context switches does it take to accomplish a task? The answer should always be "fewer than you'd expect."

**Trust the user.** Power users do not need confirmation dialogs, tutorials on every feature, or guardrails that slow them down. Provide an undo mechanism and let them move fast.

**Density earns its place.** Every element on screen must justify its existence. If removing something would not hurt the user's ability to do their job, remove it.

---

## Interaction Patterns

### Command Palette (Cmd/Ctrl + K)

The defining interaction of modern power tools. A unified entry point for every action.

- **Search everything**: Actions, navigation, settings, recent items, entities
- **Fuzzy matching**: "crt iss" should find "Create Issue"
- **Recent/frequent items**: Show before the user types
- **Scoped commands**: Context-aware — different commands available in different views
- **Keyboard-only**: Arrow keys to navigate, Enter to select, Escape to close
- **Nested commands**: Select "Change Status" then show status options as a sub-menu

Implementation: Place at the top of the viewport, ~500px wide, with a subtle backdrop overlay. Show 6-8 results max. Update results as the user types with no perceptible delay.

### Keyboard Shortcuts

Layer shortcuts by frequency of use:

| Layer | Access | Examples |
|-------|--------|----------|
| **Universal** | Cmd/Ctrl + key | Cmd+K (command), Cmd+N (new), Cmd+/ (help) |
| **Contextual** | Single key | C (create), E (edit), D (delete/archive), Enter (open) |
| **Navigation** | Arrows / vim keys | J/K (up/down in lists), H/L (collapse/expand) |
| **Selection** | Modifiers | Shift+click (range), Cmd+click (toggle), Cmd+A (all) |

Show available shortcuts:
- In command palette results (right-aligned hint)
- In tooltip on hover (after short delay)
- In a dedicated shortcuts panel (? key)

### Optimistic Updates

Show the result immediately. Reconcile with the server in the background.

- Immediately move the item to its new position/state
- If the server rejects, revert with a subtle animation + toast explaining why
- Use this for: status changes, drag-and-drop reordering, toggling properties, archiving
- Do NOT use this for: destructive deletes (use undo toast instead), operations with complex validation

### Inline Everything

Minimize context switches. If the user can accomplish something without leaving their current view, they should.

- **Inline editing**: Click a title to edit it. Click a property to change it. No "edit mode" — the content IS the editor.
- **Inline creation**: "New item" input directly in the list, not in a modal. Press Enter to create, Escape to cancel.
- **Inline detail**: Side panel or expanding row for details, not full-page navigation.
- **Inline search**: Filter the current view, not navigate to a search results page.

---

## Layout Patterns

### Sidebar + Main Content (Standard)

```
┌─────────────┬──────────────────────────────┐
│  Sidebar    │  Main Content                │
│  (200-240px)│                              │
│             │                              │
│  Navigation │  Header (title + actions)    │
│  Sections   │  ─────────────────────       │
│  Projects   │  Content area                │
│  Settings   │                              │
│             │                              │
└─────────────┴──────────────────────────────┘
```

- Sidebar: collapsible (Cmd+\), persistent selection state, hierarchical with expand/collapse
- Main content: fills remaining width, has its own scroll context
- Resizable divider between sidebar and content (drag or double-click to reset)

### Sidebar + Main + Detail Panel (Three-Pane)

```
┌──────────┬────────────────────┬──────────────┐
│ Sidebar  │ List/Table         │ Detail Panel │
│ (200px)  │ (flexible)         │ (320-400px)  │
│          │                    │              │
│          │ Selected item →    │ Full details │
│          │                    │ of selection │
└──────────┴────────────────────┴──────────────┘
```

Use when: Users need to browse a list AND see details without losing context.
The detail panel: opens on item selection, closes on Escape, resizable.

### Focus Mode

Temporarily hide sidebar and panels. Full-width content area.
Access: Cmd+\ or a toggle button. Remember the state per session.

---

## Data Density Guidelines

### Typography

- **Body text**: 12-13px, regular weight
- **Labels / metadata**: 11-12px, medium or semibold, muted color
- **Headings**: 14-16px, semibold (do not go larger — density matters)
- **Monospace**: For IDs, codes, technical values — slightly smaller than body

### Spacing

- **Between items in a list**: 0-2px (use borders or alternating backgrounds for separation)
- **Between sections**: 16-24px
- **Padding inside cards/containers**: 12-16px
- **Between a label and its value**: 4px

### Color Usage

- **Low-saturation backgrounds**: Avoid pure white (#fff). Use very subtle warm or cool grays.
- **Status colors**: Small, saturated indicators (dots, badges, underlines). Never fill a whole row with color.
- **Hover states**: Subtle background change (2-4% darker/lighter). Not borders, not shadows.
- **Selected state**: Slightly more prominent than hover. Distinct from hover.
- **Focus state**: Ring or outline. Must be visible on any background.

---

## Performance Perception

Actual speed matters, but perceived speed matters more:

- **Instant** (<100ms): UI should already reflect the change (optimistic updates)
- **Fast** (100-300ms): Acceptable for most interactions, no loading indicator needed
- **Noticeable** (300ms-1s): Show subtle progress (skeleton, progress bar)
- **Slow** (>1s): Show clear loading state, allow the user to do other things

Techniques:
- **Prefetch on hover**: If a user hovers on an item, start loading its detail
- **Cached navigation**: Going "back" should be instant — use cached data
- **Skeleton layouts**: Match the shape of the content that will load
- **Staggered loading**: Show the layout immediately, fill in data as it arrives
