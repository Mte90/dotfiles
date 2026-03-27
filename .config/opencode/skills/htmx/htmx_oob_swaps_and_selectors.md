# Skill: htmx_oob_swaps_and_selectors

## Intent

Return a single HTMX response that updates the primary target and one or more other DOM locations using out-of-band swaps with explicit selectors, without any custom JavaScript.

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

- NO: custom JavaScript or client-side orchestration
- NO: JSON responses for UI composition
- NO: hiding UI state via CSS toggles instead of swaps
- YES: server-rendered HTML fragments
- YES: `hx-swap-oob` for all secondary updates
- YES: oob targets must already exist in the DOM
- YES: use explicit selectors when the target has no matching id

If JavaScript seems "easier," stop and redesign using HTMX primitives.

---

## Required Inputs

- `primary_target_id` - id of the main HTMX target for the request
- `primary_swap` - the swap strategy for the primary target (e.g., `innerHTML`, `beforeend`)
- `oob_targets` - list of `{selector, swap_strategy}` pairs for secondary updates
- `response_context` - what the response is updating (e.g., "create contact", "update row")

---

## UI Structure

### Primary Target (always present)

```html
<div id="main-target"></div>
```

### Trigger Element

```html
<button
  hx-post="/items"
  hx-target="#main-target"
  hx-swap="beforeend">
  Add Item
</button>
```

---

## Response: POST /items

Return the main fragment plus any number of oob fragments. Every oob fragment must include `hx-swap-oob` and a selector or rely on a matching id.

### Primary Update (normal swap)

```html
<div class="item-row">
  Item: Apples (3)
</div>
```

### OOB Update: Explicit Selector

```html
<div hx-swap-oob="innerHTML:#alerts">
  Saved!
</div>
```

### OOB Update: Matching id (implicit selector)

```html
<div id="sidebar-stats" hx-swap-oob="true">
  Total Items: 12
</div>
```

Notes:
- `true` is equivalent to `outerHTML`.
- If you provide a swap strategy other than `outerHTML`, the encapsulating tag is stripped.
- Always ensure the selector exists in the DOM before the response arrives.

---

## Swap Strategy Notes (Selector + Context)

If you use a swap strategy other than `outerHTML`, wrap the content in a tag that is valid for the destination context:

```html
<tbody hx-swap-oob="beforeend:#table tbody">
  <tr>
    <td>...</td>
  </tr>
</tbody>
```

```html
<ul hx-swap-oob="beforeend:#list1">
  <li>...</li>
</ul>
```

```html
<span hx-swap-oob="beforeend:#text">
  <p>...</p>
</span>
```

---

## Troublesome Tables and Lists

Use `<template>` to wrap elements that cannot stand alone (`tr`, `td`, `th`, `thead`, `tbody`, `tfoot`, `colgroup`, `caption`, `col`, `li`). The template tag is removed after the swap.

```html
<template>
  <tr id="row-1" hx-swap-oob="true">
    <td>...</td>
  </tr>
</template>
```

---

## Slippery SVGs

To preserve SVG namespaces, wrap with `template` and `svg`:

```html
<template><svg>
  <circle id="circle1" hx-swap-oob="true" r="35" cx="50" cy="50" fill="red" />
</svg></template>
<template><svg hx-swap-oob="beforebegin:#circle1">
  <circle id="circle2" r="45" cx="50" cy="50" fill="blue" />
</svg></template>
```

---

## Nested OOB Swaps

By default, any `hx-swap-oob` element anywhere in the response is processed. If you are returning reusable fragments that include oob targets, this can remove content unintentionally. Set `htmx.config.allowNestedOobSwaps = false` to only process oob elements adjacent to the main response element.

---

## Route Responsibilities

### POST /items

- Validates input
- Persists state
- Returns:
  - Primary fragment for `primary_target_id`
  - One or more oob fragments for `oob_targets`

---

## Interaction Flow (Mental Model)

1. User triggers the action
2. Server processes and renders HTML
3. Primary target swaps in normally
4. Each oob fragment swaps into its selector

No JS. No client-side state.

---

## Validation and Error States

Errors return HTML fragments and may include oob updates (e.g., alert banners). Do not return JSON or rely on client-side rendering.

---

## Common Mistakes (Explicitly Forbidden)

- Returning oob fragments without matching DOM targets
- Using `hx-swap-oob` without a selector when no matching id exists
- Returning invalid table or list fragments without proper wrappers
- Relying on nested oob swaps without considering reuse

---

## Why This Skill Exists

Agents often add JavaScript or multiple requests to update several UI regions. This skill encodes the HTMX-native way to return one response that updates many DOM targets safely and predictably.

---

## Skill Completeness Criteria

This skill is correctly applied when:

- A single response updates multiple DOM locations
- All secondary updates are done via `hx-swap-oob`
- Targets exist and are correctly selected
- The behavior is understandable by reading HTML alone
