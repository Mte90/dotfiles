---
name: tailwind
description: Use when styling with Tailwind CSS v4 - @theme directive and design tokens, custom utilities and variants, dark mode, the Oxide engine, arbitrary values, framework integration, or migrating from v3
metadata:
  author: mte90
  version: 3.0.0
  tags:
    - css
    - tailwind
    - v4
    - utility-first
    - oxide-engine
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

## Framework Integration

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

## Deep Dives

Load these reference files for detailed information:

- **Theme Configuration** — `@theme` directive syntax, design tokens, colors, spacing, breakpoints, animations — `references/theme.md`
- **Custom Utilities & Variants** — `@utility`, `@variant` directives, utility classes reference — `references/utilities-variants.md`
- **Migration from v3** — Breaking changes, upgrade tool, new features, Preflight changes — `references/migration-v4.md`

## References

- [Tailwind CSS v4 Official Documentation](https://tailwindcss.com/docs)
- [Tailwind CSS v4: Everything You Need to Know](https://tailwindcss.com/blog/tailwindcss-v4)
- [Oxide Engine Announcement](https://tailwindcss.com/blog/oxcide)
- [Migration Guide: v3 to v4](https://tailwindcss.com/docs/upgrade-guide)
- [Tailwind CSS on GitHub](https://github.com/tailwindlabs/tailwindcss)
- [Lightning CSS - CSS parser and formatter](https://lightningcss.dev/)