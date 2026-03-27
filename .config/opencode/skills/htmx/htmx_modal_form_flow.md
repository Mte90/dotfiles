# Skill: htmx_modal_form_flow

## Intent

Implement a complete modal-based form interaction using **pure HTMX**, where:

* A modal is loaded on demand
* User input is captured via a form
* The modal closes after submission
* The main screen updates with the newly captured data

All without custom JavaScript and using server-rendered HTML fragments.

---

## Core Principles

* HTMX-first, server-driven UI
* Zero custom JavaScript
* Clear separation of concerns between routes
* Progressive enhancement friendly
* Deterministic, repeatable interaction pattern

---

## Constraints (Non-Negotiable)

* ❌ No custom JavaScript
* ❌ No frontend frameworks
* ❌ No client-side state management
* ❌ No JSON responses
* ✅ Use `hx-*` attributes exclusively
* ✅ Use server-rendered HTML partials
* ✅ Modal lifecycle handled via swaps
* ✅ Modal dismissal handled via **out-of-band (OOB) swap**
* ✅ One route per responsibility

If JavaScript seems “easier,” stop and redesign using HTMX primitives.

---

## Required Inputs

* `modal_placeholder_id` — DOM id of the modal placeholder container
* `open_modal_endpoint` — GET endpoint that renders the modal HTML
* `submit_form_endpoint` — POST endpoint that processes the form
* `main_update_target_id` — DOM id of the main UI section to update
* `entity_name` — logical name of the entity being created (semantic only)

---

## UI Structure

### Static Placeholder (always present)

```html
<div id="modal-placeholder"></div>
```

This element is:

* Empty by default
* Replaced when opening the modal
* Restored (emptied) via OOB swap on submit

---

### Trigger Button

```html
<button
  hx-get="/items/new"
  hx-target="#modal-placeholder"
  hx-swap="innerHTML">
  Add Item
</button>
```

---

## Modal Fragment (GET /items/new)

Returned HTML fragment:

```html
<div class="modal-backdrop">
  <div class="modal">
    <h2>Add Item</h2>

    <form
      hx-post="/items"
      hx-target="#items-list"
      hx-swap="beforeend">

      <input type="text" name="name" required />
      <input type="number" name="quantity" required />

      <button type="submit">Save</button>
    </form>
  </div>
</div>
```

Notes:

* Modal is server-rendered
* No JS for opening or closing
* Form submission drives everything

---

## Response: POST /items

The server must return **multiple fragments**.

### 1. Main UI Update (normal swap)

```html
<li>
  Item: Apples (3)
</li>
```

This fragment updates the main screen via:

```html
hx-target="#items-list"
hx-swap="beforeend"
```

---

### 2. Modal Cleanup (OOB swap)

```html
<div
  id="modal-placeholder"
  hx-swap-oob="true">
</div>
```

This:

* Replaces the modal placeholder
* Removes the modal from the DOM
* Requires no client-side logic

---

## Route Responsibilities

### GET /items/new

* Returns modal HTML fragment only
* No side effects
* Idempotent

### POST /items

* Validates input
* Persists data
* Returns:

  * Main UI update fragment
  * Modal placeholder OOB fragment

---

## Interaction Flow (Mental Model)

1. User clicks **Add**
2. Modal HTML replaces placeholder
3. User submits form
4. Server processes data
5. Server responds with:

   * New UI fragment
   * Modal placeholder (OOB)
6. Modal disappears
7. Main UI updates

No JS. No state leakage. No magic.

---

## Validation and Error States

Validation errors return the modal fragment with inline errors and swap into the same placeholder.

```html
<div class="modal-backdrop">
  <div class="modal">
    <h2>Add Item</h2>

    <form
      hx-post="/items"
      hx-target="#modal-placeholder"
      hx-swap="innerHTML">

      <label>
        Name
        <input type="text" name="name" value="Apples" required />
        <span class="error">Name must be unique.</span>
      </label>

      <button type="submit">Save</button>
    </form>
  </div>
</div>
```

Errors are HTML, not JSON, and never require client-side rendering.

---

## Common Mistakes (Explicitly Forbidden)

* Adding JS to close the modal
* Returning JSON and rendering client-side
* Using a single endpoint for multiple concerns
* Hiding/showing modal with CSS instead of swaps
* Managing modal state on the client

---

## Why This Skill Exists

This pattern is frequently implemented using JavaScript by default, despite HTMX offering a simpler, more maintainable solution.

This skill encodes:

* Correct HTMX instincts
* Proper route discipline
* Server-driven UI philosophy

Use it whenever you are tempted to “just add a bit of JS.”

---

## Skill Completeness Criteria

This skill is considered correctly applied when:

* No custom JavaScript is present
* Modal lifecycle is fully server-controlled
* UI updates are declarative and predictable
* The interaction remains understandable by reading HTML alone
