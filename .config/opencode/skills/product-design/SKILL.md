---
name: product-design
description: Designs production-quality user experiences for web and desktop applications with strong information hierarchy, interaction design, and state management. Use when building interactive apps, dashboards, admin panels, settings flows, multi-step workflows, or data-dense interfaces where the product needs to feel real and operational rather than decorative. Triggers include requests such as "make it feel like Linear", "production-quality UX", "real app feel", "good UX", or requests involving command palettes, keyboard shortcuts, inline editing, progressive disclosure, dense tables, or multi-screen flows. Pair with a visual design skill when the user also needs styling, theming, or brand expression.
---

# Product Design

I help turn vague UI requests into product-quality interaction decisions. I focus on how the product works, what the user sees first, which actions stay on the critical path, and how the interface behaves across empty, loading, error, and edge states.

Use me for UX structure and interaction behavior. Pair me with a visual design skill when the user also needs aesthetic direction, theming, or brand polish.

## Workflow

1. Classify the product paradigm and load the matching reference file.
2. Enter plan mode before multi-screen, multi-file, or architecture-shaping implementation work.
3. Write down the job to be done, hierarchy, critical path, and state inventory before coding.
4. Choose interaction, layout, and data presentation patterns that fit the product paradigm.
5. Build or review the interface with keyboard support, accessibility, and realistic product states.

## Step 0: Choose The Paradigm

Read the closest matching reference before making UX decisions:

- **Power-user / keyboard-first tools**: [references/power-user-patterns.md](references/power-user-patterns.md)
- **Consumer / prosumer apps**: [references/consumer-patterns.md](references/consumer-patterns.md)
- **B2B SaaS / data-dense dashboards**: [references/b2b-data-patterns.md](references/b2b-data-patterns.md)

Use these signals to choose:

- **Power-user**: Users spend hours per day in the product, value speed, and benefit from dense layouts and shortcuts.
- **Consumer**: The audience is broad, the experience must feel obvious, and mobile or onboarding quality matters heavily.
- **B2B data**: The primary job is analyzing data, monitoring systems, configuring operations, or managing records at scale.

If the paradigm materially affects the result and the request is still ambiguous, use `AskUserQuestion` to present these options:

- **Power-user**: Faster, denser, keyboard-first workflows for expert repeat users.
- **Consumer**: More obvious, guided, touch-friendly flows for broad audiences.
- **B2B data**: Data-dense tables, filters, dashboards, and operational workflows.

When a follow-up would only add delay, state the assumption you are making and proceed with the closest fit.

## Step 1: Think Before Coding

Do not jump straight to implementation for non-trivial UI work. Write the minimum viable UX brief first.

### 1a. Job To Be Done

State the user's job in one sentence:

`The user needs to _____ so they can _____.`

This sentence filters every later decision. If an element does not support the job, cut it.

### 1b. Information Hierarchy

Rank every element by importance:

- **Primary**: The main task or information the user came for.
- **Secondary**: Context that helps the user complete the primary task.
- **Tertiary**: Useful but non-urgent details revealed through progressive disclosure.
- **Remove**: Anything that does not earn space on the screen.

Ask: "If the user only saw this screen for two seconds, what should they remember?"

### 1c. Critical Path

Map the path through the screen:

1. Where did the user come from?
2. What do they need to do here?
3. What should happen next?

Every screen needs an obvious next action.

### 1d. State Inventory

Design these states deliberately:

| State | Requirement |
|-------|-------------|
| **Empty** | Explain what belongs here and guide the first action. |
| **Loading** | Preserve layout with skeletons or staged loading. |
| **Partial** | Show available data without blocking on everything else. |
| **Populated** | Make the happy path fast and legible. |
| **Error** | Explain the failure and offer recovery. |
| **Edge** | Handle extremes such as one item, 1000 items, long values, and missing fields. |

If only the populated state is designed, the product is underdesigned.

## Step 2: Choose Interaction Patterns

### Speed Over Ceremony

Reduce steps wherever the task allows:

- Prefer optimistic updates for reversible operations.
- Prefer inline editing over separate edit screens for simple changes.
- Prefer batch actions when users repeat the same task across many items.
- Prefer undo over confirmation modals except for destructive, irreversible actions.

### Progressive Disclosure

Reveal complexity in layers:

- **Level 1**: Core action visible immediately.
- **Level 2**: Secondary actions on hover or in contextual menus.
- **Level 3**: Advanced configuration behind an overflow menu or settings panel.
- **Level 4**: Power-user affordances such as shortcuts or command palettes.

A new user should be able to complete the primary job without needing Level 3 or 4.

### Feedback

Every action needs visible feedback:

- **Immediate**: Button state, local UI update, selection state.
- **Short-term**: Toast or status message for background work.
- **Persistent**: Ongoing status indicators for long-running processes.
- **Error**: Inline guidance at the point of failure.

### Navigation

Choose the smallest navigation system that matches the information architecture:

| Pattern | Best for |
|---------|----------|
| **Sidebar + main content** | Persistent navigation across product areas |
| **Tab bar** | Small top-level IA, especially on mobile |
| **Breadcrumbs** | Deep hierarchies where location matters |
| **Command palette** | Action-heavy interfaces with repeat users |
| **Stacked panels** | Drill-down detail without losing context |

Do not mix multiple navigation paradigms unless each one solves a distinct problem.

## Step 3: Calibrate Density And Layout

Choose density intentionally:

- **High density**: Users live in the product. Tight spacing, compact controls, more information per viewport.
- **Medium density**: Balanced readability and efficiency.
- **Low density**: Focused flows such as onboarding or lightweight consumer actions.

Rework the layout by breakpoint instead of simply shrinking it:

- **Desktop**: Sidebars, split panes, multi-column layouts.
- **Tablet**: Collapsible navigation and simpler column structures.
- **Mobile**: Stacked content, larger touch targets, simplified action surfaces.

Touch targets on mobile should be at least `44x44px`.

## Step 4: Present Data Intentionally

Choose the view that matches the job:

| View | Best for |
|------|----------|
| **Table** | Comparing many records with shared attributes |
| **List** | Scanning labels with supporting metadata |
| **Cards / grid** | Visual or uneven content |
| **Kanban** | Status-based workflows |
| **Timeline** | Time-based data or history |
| **Tree** | Hierarchical structures |

For table-heavy interfaces:

- Make columns sortable when ordering matters.
- Keep headers visible during scroll.
- Support batch selection where repeated actions are likely.
- Handle overflow with truncation plus reveal on hover or expand.
- Avoid showing raw null-like placeholder values.

For search and filters:

- Place search above the content it filters.
- Make active filters obvious.
- Use pagination for position-sensitive records and infinite scroll for feed-like content.
- Plan for virtualization when scale demands it.

## Step 5: Apply Component Rules

### Forms

- Put labels above inputs.
- Validate inline at the right moment instead of dumping errors at submit time.
- Show submission progress.
- Break long forms into sections or steps.

### Dialogs

Prefer inline editing first, then slide-overs, then modals. Use full-page flows only when the task truly needs dedicated space.

When a modal is necessary:

- Support Escape and backdrop dismissal unless the task is intentionally blocking.
- Keep focus trapped inside.
- Return focus to the trigger when it closes.

### Empty States

Empty states should explain the space, present a clear first action, and optionally show an example or template.

## Step 6: Build For Keyboard And Accessibility

Minimum keyboard support:

- Logical tab order
- Enter and Space activation where appropriate
- Escape closes transient UI

Add richer keyboard behavior for repeat-use tools:

- Single-key shortcuts for common actions
- Command palette for large action surfaces
- Arrow-key navigation for lists and tables

Accessibility baseline:

- Visible focus indicators
- Adequate contrast
- Labels for icon-only controls
- Error text tied to the related field
- No information conveyed by color alone

## Output Expectations

For implementation or review work, produce a short UX brief before or alongside code changes:

1. Product paradigm and any stated assumption
2. Job to be done
3. Primary, secondary, and hidden information
4. Critical path
5. Required states
6. Interaction patterns chosen
7. Accessibility or keyboard requirements worth preserving

Keep the brief concise. The point is to force decisions, not create design theater.

## Anti-Patterns

Flag these immediately because they make product work feel like a demo:

- Missing loading, empty, or error states
- Modal-heavy flows that should be inline
- Fake placeholder data that destroys credibility
- Nested scrolling regions with unclear ownership
- Icon-only actions without labels or tooltips
- Tables without sticky headers or clear row actions
- "Submit" flows that ignore validation, latency, or edge cases
