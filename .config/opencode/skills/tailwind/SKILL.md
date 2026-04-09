---
name: tailwind
description: Utility-first CSS framework v4 with CSS-first configuration, @theme directive, and the new Oxide engine.
metadata:
  author: OSS AI Skills
  version: 2.1.0
  tags: [css, tailwind, v4, utility-first, oxide-engine]
---

## Overview

Tailwind CSS v4 is a complete rewrite of the framework, built on a new Rust-based Oxide engine that's 10x faster. The biggest change: **configuration is now done in CSS**, not JavaScript. No more `tailwind.config.js` for most projects.

**Browser support:** Safari 16.4+, Chrome 111+, Firefox 128+

## The Oxide Engine (Performance)

Tailwind v4 uses a new Rust-based **Oxide** engine with dramatically improved performance:

| Operation | v3 Speed | v4 Speed (Oxide) | Improvement |
|-----------|----------|-----------------|-------------|
| Cold build | 8s | 2.1s | **3.78x faster** |
| Incremental | 450ms | 51ms | **8.8x faster** |
| HMR (Hot Module Reload) | 350ms | 12ms | **28x faster** |
| Memory usage | Higher | Lower | ~50% reduction |

### Why It's Faster

- **Rust-native**: Core processing in Rust, not JavaScript
- **Parallel processing**: Uses all CPU cores efficiently
- **Better caching**: Improved incremental build detection
- **Optimized CSS generation**: Less overhead in utility generation

### Requirements

```bash
# Node.js 18+ required for Oxide engine
node --version  # Should be 18 or higher

# Install with Vite (recommended for best performance)
npm install tailwindcss @tailwindcss/vite

# Or PostCSS (also fast)
npm install tailwindcss @tailwindcss/postcss
```

## Installation

### Vite (Recommended)
```bash
npm install tailwindcss @tailwindcss/vite
```

```js
// vite.config.js
import tailwindcss from "@tailwindcss/vite";

export default {
  plugins: [tailwindcss()],
};
```

### PostCSS
```bash
npm install -D tailwindcss @tailwindcss/postcss
```

```js
// postcss.config.js
export default {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};
```

### CLI
```bash
npm install -D @tailwindcss/cli
npx @tailwindcss/cli -i input.css -o output.css --watch
```

## Basic Setup

### The CSS File

```css
/* input.css */
@import "tailwindcss";

/* Your custom styles below */
```

That's it. No `@tailwind base/components/utilities` directives—they're gone.

## Theme Configuration with @theme

Customize your design tokens directly in CSS using the `@theme` directive:

```css
@import "tailwindcss";

@theme {
  /* Custom colors */
  --color-brand: oklch(65% 0.25 250);
  --color-brand-light: oklch(75% 0.25 250);
  --color-brand-dark: oklch(55% 0.25 250);
  
  /* Custom fonts */
  --font-display: "Clash Display", "sans-serif";
  --font-body: "Satoshi", "sans-serif";
  
  /* Custom spacing */
  --spacing-18: 4.5rem;
  --spacing-22: 5.5rem;
  
  /* Custom breakpoints */
  --breakpoint-3xl: 120rem;
  
  /* Custom animations */
  --animate-fade-in: fade-in 0.5s ease-out;
  
  /* Shadow customization */
  --shadow-card: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
}

@keyframes fade-in {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}
```

### Using Theme Values

All theme values become CSS variables automatically:

```css
/* These are automatically generated from @theme */
.btn {
  background-color: var(--color-brand);
  font-family: var(--font-display);
}
```

In your HTML, use them directly as utility values:

```html
<button class="bg-brand hover:bg-brand-dark font-display px-4 py-2">
  Click me
</button>
```

## Dark Mode

In v4, dark mode uses `@media (prefers-color-scheme)` by default—no config needed.

```html
<!-- Automatically responds to OS preference -->
<div class="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
  Hello, dark mode!
</div>
```

For manual toggle, add `.dark` class to `<html>` element:

```html
<html class="dark">
  <div class="bg-white dark:bg-gray-900">...</div>
</html>
```

No `darkMode` config option needed—it just works.

## Custom Utilities with @utility

Create reusable utilities directly in CSS:

```css
@utility container {
  margin-inline: auto;
  padding-inline: 1.5rem;
}

@utility tab-4 {
  tab-size: 4;
}

@utility btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 0.5rem;
  padding: 0.5rem 1rem;
  font-weight: 600;
  transition: background-color 0.2s;
  
  &:hover {
    filter: brightness(1.1);
  }
}
```

Usage in HTML:

```html
<button class="btn bg-blue-600 text-white">Button</button>
<div class="tab-4">Code block</div>
<div class="container">Centered content</div>
```

## Custom Variants with @variant

Define your own variants:

```css
/* Custom variant for external links */
@custom-variant external (&[rel="external"]);

/* Custom variant for touch devices */
@custom-variant touch (&:hover@media (hover: none));
```

Usage:

```html
<a href="https://example.com" rel="external" class="external:text-blue-600">
  External link
</a>
```

### Built-in Variants

Common variants work the same as v3:

```html
<button class="hover:bg-blue-600 focus:ring-2 active:scale-95 disabled:opacity-50">
  Interactive Button
</button>
```

### Variant Stacking Order

In v4, stacked variants apply left-to-right (CSS-like order):

```html
<!-- v3 (right-to-left): -->
<div class="first:*:pt-0 last:*:pb-0">

<!-- v4 (left-to-right): -->
<div class="*:first:pt-0 *:last:pb-0">
</div>
```

## Arbitrary Values

### CSS Variables (New Syntax)

Variables now use parentheses, not brackets:

```html
<!-- v3 -->
<div class="bg-[--brand-color]">

<!-- v4 -->
<div class="bg-(--brand-color)">
```

### Grid Values

Use underscores for spaces, not commas:

```html
<!-- v3 -->
<div class="grid-cols-[max-content,auto]">

<!-- v4 -->
<div class="grid-cols-[max-content_auto]">
```

## The Important Modifier

The `!` now goes at the end of the utility:

```html
<!-- v3 -->
<div class="!bg-red-500">

<!-- v4 -->
<div class="bg-red-500!">
```

Both work in v4, but the new syntax is preferred.

## Automatic Content Detection

No more `content` array in config. Tailwind v4 automatically scans for classes in your project.

## Backward Compatibility with @config

Need to keep your old `tailwind.config.js`? Use `@config`:

```css
@import "tailwindcss";
@config "../../tailwind.config.js";
```

Note: `corePlugins`, `safelist`, and `separator` options are not supported in v4.

## The @theme Directive (Complete Reference)

The `@theme` directive is the heart of v4 configuration. It defines design tokens that become CSS variables and utility classes.

### Color System

```css
@theme {
  /* Brand colors using OKLCH - recommended for P3 gamut */
  --color-brand: oklch(65% 0.25 250);
  --color-brand-50: oklch(98% 0.02 250);
  --color-brand-100: oklch(95% 0.05 250);
  --color-brand-200: oklch(90% 0.1 250);
  --color-brand-300: oklch(80% 0.15 250);
  --color-brand-400: oklch(70% 0.2 250);
  --color-brand-500: oklch(65% 0.25 250);
  --color-brand-600: oklch(55% 0.25 250);
  --color-brand-700: oklch(45% 0.25 250);
  --color-brand-800: oklch(35% 0.25 250);
  --color-brand-900: oklch(25% 0.25 250);
  --color-brand-950: oklch(15% 0.2 250);

  /* Semantic colors */
  --color-success: #22c55e;
  --color-warning: #f59e0b;
  --color-error: #ef4444;
  --color-info: #3b82f6;
  
  /* Extend existing colors */
  --color-blue-950: oklch(20% 0.15 240);
}
```

### OKLCH Color Syntax

v4 uses OKLCH by default for better color accuracy:

```css
/* Syntax: oklch(lightness chroma hue [opacity]) */
--color-primary: oklch(60% 0.18 250);
--color-translucent: oklch(60% 0.18 250 / 50%);
```

**Benefits of OKLCH:**
- P3 color gamut support (more vibrant colors)
- Predictable interpolation (no more gray shifts in gradients)
- CSS native (no runtime conversion)

### Spacing Scale

```css
@theme {
  /* Add custom spacing */
  --spacing-18: 4.5rem;
  --spacing-22: 5.5rem;
  --spacing-26: 6.5rem;
  --spacing-72: 18rem;
  --spacing-84: 21rem;
  --spacing-96: 24rem;
  
  /* Spacing for specific use cases */
  --spacing-header: 4rem;
  --spacing-card: 1.5rem;
}
```

### Breakpoints

```css
@theme {
  /* Add custom breakpoints */
  --breakpoint-3xl: 120rem;
  --breakpoint-4xl: 140rem;
  
  /* Modify existing */
  --breakpoint-sm: 30rem;  /* 480px */
  --breakpoint-md: 40rem;  /* 640px */
}
```

### Shadows

```css
@theme {
  /* Custom shadows */
  --shadow-card: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  --shadow-elevated: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
  --shadow-glow: 0 0 20px oklch(65% 0.25 250 / 50%);
  --shadow-inner-lg: inset 0 2px 4px 0 rgb(0 0 0 / 0.05);
}
```

### Typography

```css
@theme {
  /* Custom fonts */
  --font-sans: "Inter", system-ui, sans-serif;
  --font-display: "Clash Display", sans-serif;
  --font-mono: "JetBrains Mono", monospace;
  
  /* Font sizes */
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;
  --text-4xl: 2.25rem;
  --text-5xl: 3rem;
  --text-6xl: 3.75rem;
  --text-7xl: 4.5rem;
  --text-8xl: 6rem;
  --text-9xl: 8rem;
  
  /* Line heights */
  --leading-none: 1;
  --leading-tight: 1.25;
  --leading-snug: 1.375;
  --leading-normal: 1.5;
  --leading-relaxed: 1.625;
  --leading-loose: 2;
  
  /* Letter spacing */
  --tracking-tighter: -0.05em;
  --tracking-tight: -0.025em;
  --tracking-normal: 0em;
  --tracking-wide: 0.025em;
  --tracking-wider: 0.05em;
  --tracking-widest: 0.1em;
}
```

### Animations

```css
@theme {
  /* Custom animations */
  --animate-fade-in: fade-in 0.5s ease-out;
  --animate-fade-out: fade-out 0.5s ease-out;
  --animate-slide-in-up: slide-in-up 0.3s ease-out;
  --animate-slide-in-down: slide-in-down 0.3s ease-out;
  --animate-scale-in: scale-in 0.2s ease-out;
  --animate-spin-slow: spin 2s linear infinite;
  --animate-pulse-slow: pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite;
  --animate-bounce-slow: bounce 2s infinite;
  --animate-shake: shake 0.5s ease-in-out;
  
  /* Keyframes are still needed */
  --animate-enter: enter 0.3s ease-out;
  --animate-leave: leave 0.2s ease-in;
}

@keyframes fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slide-in-up {
  from { transform: translateY(100%); }
  to { transform: translateY(0); }
}

@keyframes scale-in {
  from { transform: scale(0.9); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
}
```

### @theme Flags

You can use CSS-wide keywords as values:

```css
@theme {
  /* Use initial to not extend the default */
  --color-gray-500: initial;  /* Removes the default gray-500 */
  
  /* Use inherit when needed */
  --color-inherit: inherit;
  
  /* Use unset to reset */
  --font-family: unset;
}
```

### Inline Theme Values

Use `--inline-*` to generate values that don't create CSS variables:

```css
@theme {
  --animate-bounce: bounce 1s infinite;
  --animate-spin: spin 1s linear infinite;
  
  /* These create variables but utilities also use them */
}
```

## Migration from v3

### Complete Breaking Changes Table

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
| Arbitrary | `bg-[--var]` | `bg-(--var)` | Change `[]` to `()` |
| Grid | `grid-cols-[a,b]` | `grid-cols-[a_b]` | Use `_` not `,` |
| Important | `!bg-red-500` | `bg-red-500!` | Move `!` to end |
| Theme fn | `theme('colors.red')` | `var(--color-red-500)` | Use CSS variables |
| Dark mode | Config option | Automatic | Remove config |
| Separator | `_` in arbitrary | `_` | Same, but fewer cases |
| Preflight | Various resets | Updated | Check dialog/button |

### Upgrade Tool

Run the official upgrade tool:

```bash
npx @tailwindcss/upgrade
```

This handles most migration automatically.

### Manual Changes Needed

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

5. **Space-between changes:**
   ```html
   <!-- The selector changed -->
   <div class="space-y-4">...   <!-- now uses :not(:last-child) -->
   ```

## New Features in v4

### Field Sizing
```html
<textarea class="field-sizing-content" placeholder="Auto-grows"></textarea>
```

### Container Queries
```html
<div class="@container">
  <div class="@xs:bg-red-500 @lg:bg-blue-500">
    Responsive to container, not viewport
  </div>
</div>
```

### 3D Transforms
```html
<div class="transform-style-3d perspective-1000 rotate-x-45">
  3D content
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

## Using with Vue, Svelte, CSS Modules

In v4, styles in separate files (Vue `<style>`, Svelte, CSS modules) don't see theme variables by default. Use `@reference`:

```vue
<template>
  <h1>Hello</h1>
</template>

<style>
@reference "../app.css";

h1 {
  @apply text-2xl font-bold text-red-500;
}
</style>
```

## Common Issues and Solutions

### Missing classes after build
- Run `npx @tailwindcss/upgrade` to set up v4 correctly
- Ensure CSS is processed by the v4 plugin

### Dark mode not applying
- Use automatic mode (no config needed in v4)
- Add `class="dark"` to `<html>` for manual toggle

### Custom utilities not working
- Use `@utility` directive instead of `@layer utilities`
- Ensure the CSS file with `@theme` definitions is imported

### Performance issues
- v4 is 10x faster with the Oxide engine
- Ensure you're using the latest `@tailwindcss/vite` or `@tailwindcss/postcss`

### Prefix changes
Prefixes now work like variants—always at the beginning:

```html
<div class="tw:flex tw:bg-red-500 tw:hover:bg-red-600">
```

## Utility Classes Reference (v4)

### Layout
- **Display:** `block`, `inline-block`, `flex`, `grid`, `inline-flex`, `inline-grid`, `hidden`
- **Position:** `static`, `relative`, `absolute`, `fixed`, `sticky`
- **Container:** `container` (customize with `@utility container`)

### Flexbox & Grid
- **Flex:** `flex-row`, `flex-col`, `flex-wrap`, `flex-1`, `flex-auto`, `flex-none`
- **Justify:** `justify-start`, `justify-center`, `justify-between`, `justify-around`, `justify-end`
- **Align:** `items-start`, `items-center`, `items-stretch`, `items-end`
- **Gap:** `gap-4`, `gap-x-4`, `gap-y-4`, `gap-4`
- **Grid:** `grid-cols-3`, `grid-rows-2`, `col-span-2`, `row-span-2`

### Sizing
- **Width/Height:** `w-full`, `w-auto`, `w-screen`, `h-full`, `h-screen`
- **Max/Min:** `max-w-lg`, `max-w-screen-md`, `min-h-screen`
- **Container queries:** `@container`, `@xs:`, `@sm:`, `@md:`, `@lg:`, `@xl:`

### Spacing
- **Margin:** `m-4`, `mx-4`, `my-4`, `mt-4`, `mr-4`, `mb-4`, `ml-4`, `-m-4`
- **Padding:** `p-4`, `px-4`, `py-4`, `pt-4`, `pr-4`, `pb-4`, `pl-4`

### Typography
- **Size:** `text-xs`, `text-sm`, `text-base`, `text-lg`, `text-xl`, `text-2xl`, `text-4xl`
- **Weight:** `font-thin`, `font-light`, `font-normal`, `font-medium`, `font-bold`, `font-black`
- **Style:** `italic`, `not-italic`, `uppercase`, `lowercase`, `capitalize`
- **Leading:** `leading-none`, `leading-tight`, `leading-normal`, `leading-relaxed`, `leading-loose`
- **Tracking:** `tracking-tighter`, `tracking-tight`, `tracking-normal`, `tracking-wide`

### Colors
- **Background:** `bg-red-500`, `bg-[--custom-color]`, `bg-(--variable)`
- **Text:** `text-gray-700`, `text-transparent`
- **Border:** `border`, `border-2`, `border-gray-200`, `border-t-2`, `border-b`
- **Gradient:** `bg-linear-to-r`, `bg-radial-gradient`, `bg-conic-gradient`

### Visual Effects
- **Shadow:** `shadow-xs`, `shadow-sm`, `shadow`, `shadow-md`, `shadow-lg`, `shadow-xl`, `shadow-2xl`
- **Opacity:** `opacity-0` through `opacity-100`, `opacity-50/`
- **Blend:** `mix-blend-multiply`, `mix-blend-screen`, `mix-blend-overlay`
- **Filter:** `blur`, `blur-sm`, `blur-xs`, `brightness-50`, `contrast-50`, `grayscale`, `sepia`

### Transitions & Animation
- **Transition:** `transition`, `transition-all`, `transition-colors`, `transition-opacity`, `transition-transform`
- **Duration:** `duration-75`, `duration-100`, `duration-200`, `duration-300`, `duration-500`
- **Easing:** `ease-linear`, `ease-in`, `ease-out`, `ease-in-out`
- **Animation:** `animate-spin`, `animate-pulse`, `animate-bounce`, `animate-none`

### Transform
- **Scale:** `scale-0`, `scale-50`, `scale-75`, `scale-90`, `scale-95`, `scale-100`, `scale-105`, `scale-110`, `scale-125`, `scale-150`
- **Rotate:** `rotate-0`, `rotate-1`, `rotate-2`, `rotate-12`, `rotate-45`, `rotate-90`, `rotate-180`
- **Translate:** `translate-x-0`, `translate-x-4`, `translate-y-4`, `translate-x-1/2`
- **Perspective:** `perspective-0`, `perspective-1000`, `perspective-3d`

### Interactivity
- **Cursor:** `cursor-pointer`, `cursor-not-allowed`, `cursor-text`, `cursor-move`
- **Pointer:** `pointer-events-none`, `pointer-events-auto`
- **Select:** `select-none`, `select-text`, `select-all`, `select-auto`
- **Resize:** `resize`, `resize-none`, `resize-y`, `resize-x`
- **Field sizing:** `field-sizing-content`, `field-sizing-fixed`

### State Variants
- **Interaction:** `hover:`, `focus:`, `active:`, `visited:`, `focus-within:`, `focus-visible:`
- **Disabled:** `disabled:`, `disabled:opacity-50`, `disabled:cursor-not-allowed`
- **Group:** `group`, `group-hover:`, `group-focus:`, `peer`, `peer-hover:`
- **Motion:** `motion-reduce:`, `motion-safe:`
- **Media:** `dark:`, `@media (prefers-reduced-motion):`
- **Structural:** `first:`, `last:`, `odd:`, `even:`, `first-child:`, `last-child:`, `only:`, `empty:`

## Best Practices

### Do:
- Use `@theme` for all custom design tokens
- Use `@utility` for reusable patterns
- Leverage the CSS variables (`var(--color-*)`) in JavaScript
- Let dark mode be automatic
- Use `@config` only for legacy projects

### Don't:
- Create a `tailwind.config.js` for new projects
- Use Sass/Less/Stylus—they don't work with v4
- Use the old `theme()` function—use CSS variables instead
- Use brackets for CSS variables—use parentheses: `bg-(--var)`

## Migration Checklist

- [ ] Run `npx @tailwindcss/upgrade`
- [ ] Replace `@tailwind` directives with `@import "tailwindcss"`
- [ ] Convert `tailwind.config.js` to `@theme` in CSS
- [ ] Replace `ring` with `ring-3`
- [ ] Replace `shadow` with `shadow-sm`, `shadow-sm` with `shadow-xs`
- [ ] Replace `outline-none` with `outline-hidden`
- [ ] Add explicit border colors where needed
- [ ] Update variant stacking order
- [ ] Update arbitrary value syntax (`[...]` → `(...)`)
- [ ] Update grid syntax (`,` → `_`)
- [ ] Move `!` to end of utility for important
- [ ] Test dark mode
- [ ] Verify custom utilities work with `@utility`
- [ ] Update Vue/Svelte components with `@reference` if needed