# Migration from v3

> This reference file is loaded on demand from `../SKILL.md`.

## Complete Breaking Changes Table

| Feature | v3 | v4 | Action Required |
|---------|----|----|----|
| Import | `@tailwind base/components/utilities` | `@import "tailwindcss"` | Replace all directives |
| Config | `tailwind.config.js` | `@theme` in CSS | Rewrite to @theme |
| Ring | `ring` (3px default) | `ring-3` | Add `-3` suffix |
| Shadow | `shadow` | `shadow-sm` | Shift all shadows down |
| Shadow | `shadow-sm` | `shadow-xs` | Shift down |
| Shadow | `shadow-md` | `shadow` | Remove `-md` |
| Shadow | `shadow-lg` | `shadow-md` | Remove `-lg` |
| Shadow | `shadow-xl` | `shadow-lg` | Remove `-xl` |
| Shadow | `shadow-2xl` | `shadow-xl` | Remove `-2xl` |
| Outline | `outline-none` | `outline-hidden` | Rename utility |
| Border | `gray-200` default | `currentColor` | Add explicit colors |
| Blur | `blur` | `blur-sm` | Add `-sm` suffix |
| Blur | `blur-sm` | `blur-xs` | Shift down |
| Blur | `blur-md` | `blur` | Remove `-md` |
| Blur | `blur-lg` | `blur-md` | Remove `-lg` |
| Blur | `blur-xl` | `blur-lg` | Remove `-xl` |
| Opacity | `bg-opacity-50` | `bg-red-500/50` | Use `/` modifier |
| Opacity | `text-opacity-75` | `text-red-500/75` | Use `/` modifier |
| Flex | `flex-shrink-0` | `shrink-0` | Remove `flex-` prefix |
| Flex | `flex-grow-1` | `grow-1` | Remove `flex-` prefix |
| Arbitrary | `bg-[--var]` | `bg-(--var)` | Change `[]` to `()` |
| Grid | `grid-cols-[a,b]` | `grid-cols-[a_b]` | Use `_` not `,` |
| Important | `!bg-red-500` | `bg-red-500!` | Move `!` to end |
| Theme fn | `theme('colors.red')` | `var(--color-red-500)` | Use CSS variables |
| Dark mode | Config option | Automatic | Remove config |
| Separator | `_` in arbitrary | `_` | Same, but fewer cases |
| Preflight | Various resets | Updated | Check dialog/button |

## Upgrade Tool

Run the official upgrade tool:

```bash
npx @tailwindcss/upgrade
```

This handles most migration automatically.

## Manual Changes Needed

1. **Rename shadow utilities:**
   ```html
   <!-- Change these -->
   <div class="shadow"></div>   <!-- now shadow-sm -->
   <div class="shadow-sm"></div> <!-- now shadow-xs -->
   ```

2. **Update ring utilities:**
   ```html
   <!-- Change these -->
   <input class="ring">        <!-- now ring-3 -->
   ```

3. **Fix outline:**
   ```html
   <!-- Change these -->
   <input class="outline-none"> <!-- now outline-hidden -->
   ```

4. **Update border colors:**
   ```html
   <!-- Need to specify color now -->
   <div class="border">         <!-- no longer gray-200 by default -->
   <div class="border border-gray-200"> <!-- explicit -->
   ```

5. **Opacity utilities:**
   ```html
   <!-- Change these -->
   <div class="bg-opacity-50">  <!-- now bg-black/50 -->
   <div class="text-opacity-75"> <!-- now text-gray-900/75 -->
   ```

6. **Flex shorthand removed:**
   ```html
   <!-- Change these -->
   <div class="flex-shrink-0">  <!-- now shrink-0 -->
   <div class="flex-grow-1">    <!-- now grow-1 -->
   ```

## New Features in v4

### Field Sizing
```html
<textarea class="field-sizing-content" placeholder="Auto-grows"></textarea>
```

### 3D Transforms
```html
<div class="transform-style-3d perspective-1000 rotate-x-45">
  3D content
</div>
```

### Container Queries
```html
<div class="@container">
  <div class="@xs:bg-red-500 @lg:bg-blue-500">
    Responsive to container, not viewport
  </div>
</div>
```

### @starting-style
```html
<div class="open:animate-fade-in" style="view-transition-name: modal">
  Modal content
</div>
```

### Linear Gradients (Improved)
```html
<div class="bg-linear-to-r from-red-500 via-orange-400 to-yellow-400">
  Gradient with stops
</div>
```

### Gradient Variants
Variants now preserve gradient values properly:

```html
<!-- Dark mode now preserves all gradient stops -->
<div class="bg-linear-to-r from-red-500 to-yellow-400 dark:from-blue-500 dark:to-teal-400">
```

To reset a gradient stop in a variant:

```html
<div class="bg-linear-to-r from-red-500 via-orange-400 to-yellow-400 dark:via-none">
```

## Preflight Changes

### Default Placeholder Color
Now uses `currentColor` at 50% opacity instead of `gray-400`.

### Button Cursor
Buttons now use `cursor: default` (browser default) instead of `pointer`.

### Dialog Margins
Margins on `<dialog>` elements are now reset to 0.