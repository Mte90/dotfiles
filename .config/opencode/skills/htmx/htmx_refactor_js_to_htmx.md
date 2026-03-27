# Skill: htmx_refactor_js_to_htmx

## Intent

Refactor JS-heavy UI templates into maintainable, server-driven HTMX patterns by incrementally replacing client-side orchestration with server-rendered HTML fragments and declarative swaps.

---

## Core Principles

- Server-driven UI
- HTML as the primary contract
- No custom JavaScript by default
- Clear route responsibilities
- One skill = one user intent
- Progressive enhancement friendly

---

## Constraints (Non-Negotiable)

- NO: custom JavaScript unless HTMX cannot express the behavior
- NO: JSON responses for UI composition
- NO: client-side state management
- YES: server-rendered HTML fragments
- YES: `hx-*` attributes for interaction and swaps
- YES: small, reviewable diffs
- YES: one route per responsibility

If the behavior can be modeled as "request -> response -> swap," JavaScript is disallowed.

---

## Required Inputs

- `entry_template_path` - template file containing the JS-driven UI
- `partial_targets` - list of DOM targets to be swapped (ids or selectors)
- `interaction_list` - list of JS interactions to replace (clicks, submits, toggles)
- `route_map` - mapping of interactions to routes and responsibilities

---

## Workflow (Incremental Refactor)

### Step 1: Extract Server-Rendered Partials

1. Identify self-contained UI regions controlled by JS.
2. Move each region into a server-rendered partial.
3. Replace the original region with a placeholder target.

Example placeholder:

```html
<div id="items-list"><!-- server-rendered list --></div>
```

---

### Step 2: Replace JS Interactions With HTMX

For each interaction:

- Identify the trigger element
- Assign `hx-get` or `hx-post`
- Set `hx-target` to the placeholder or component root
- Choose the minimal `hx-swap` (e.g., `innerHTML`, `beforeend`)

Example conversion:

```html
<button
  hx-get="/items/new"
  hx-target="#modal-placeholder"
  hx-swap="innerHTML">
  Add Item
</button>
```

---

### Step 3: Use OOB Swaps for Cross-Target Updates

When a single action must update multiple regions:

1. Return the main fragment in the normal response
2. Add extra fragments with `hx-swap-oob="true"`

Example:

```html
<div id="modal-placeholder" hx-swap-oob="true"></div>
<div id="toast" hx-swap-oob="true">Saved</div>
```

---

## Route Responsibilities

Each interaction maps to a single, clear route:

- GET routes return fragments only
- POST routes validate, persist, and return fragments
- No endpoint should render both full page and fragment in the same response

---

## Validation and Error States

Errors return HTML fragments that re-render the same target with inline errors.
Never return JSON for validation or error display.

Example:

```html
<form
  hx-post="/items"
  hx-target="#modal-placeholder"
  hx-swap="innerHTML">
  <input name="name" value="Apples" />
  <span class="error">Name must be unique.</span>
</form>
```

---

## Common Mistakes (Explicitly Forbidden)

- Leaving JS event handlers in place after adding HTMX
- Returning JSON and rendering in client-side templates
- Overloading a single route for multiple UI concerns
- Using CSS to toggle visibility instead of swaps
- Performing "full refresh" swaps when a small fragment is sufficient

---

## Why This Skill Exists

AI assistants often preserve existing JS behavior and "wrap" it with HTMX instead of replacing it with server-driven patterns. This skill enforces a disciplined, incremental migration that removes client-side orchestration while keeping changes small and reviewable.

---

## Skill Completeness Criteria

This skill is correctly applied when:

- JS interactions are replaced by `hx-*` attributes
- UI updates return HTML fragments only
- OOB swaps are used for multi-target updates
- Routes have single, clear responsibilities
- Diffs are small and easy to review
