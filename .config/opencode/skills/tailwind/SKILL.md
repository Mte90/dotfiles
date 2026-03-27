---
name: tailwind
description: Utility-first CSS framework for rapid UI development with customizable design system.
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - css
    - frontend
    - utility-first
    - responsive
    - design-system
---

## Overview and Philosophy

Tailwind CSS is a utility‑first CSS framework that enables rapid UI development with a customizable design system. It provides low‑level utility classes that can be composed to build any design, avoiding the need for custom CSS.

## Installation

### npm / Yarn
```bash
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```
### CDN
```html
<link href="https://cdn.jsdelivr.net/npm/tailwindcss@3.4.0/dist/tailwind.min.css" rel="stylesheet">
```
### PostCSS
Add the Tailwind directives to your CSS file:
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

## Configuration (`tailwind.config.js`)

```js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{html,js,ts,tsx,jsx}",
    "./public/index.html",
  ],
  theme: {
    extend: {
      colors: {
        brand: "#1fb6ff",
      },
    },
  },
  darkMode: "class", // or 'media'
  plugins: [],
};
```
Customize the `theme`, `screens`, and add plugins as needed.

## Utility Classes Reference

- **Layout**: `container`, `box-border`, `box-content`, `block`, `inline-block`, `flex`, `grid`
- **Flexbox**: `flex-row`, `flex-col`, `justify-center`, `items-center`, `gap-4`
- **Grid**: `grid-cols-3`, `grid-rows-2`, `gap-2`
- **Spacing**: `m-4`, `mt-2`, `p-3`, `px-5`
- **Sizing**: `w-full`, `h-screen`, `max-w-lg`
- **Typography**: `text-sm`, `font-medium`, `leading-6`, `tracking-wide`
- **Colors**: `text-gray-700`, `bg-indigo-500`, `border-red-300`
- **Backgrounds**: `bg-cover`, `bg-center`, `bg-gradient-to-r`
- **Borders**: `border`, `border-2`, `rounded`, `rounded-lg`
- **Effects**: `shadow`, `opacity-75`, `ring-2`
- **Filters**: `blur-sm`, `grayscale`
- **Transforms**: `scale-105`, `rotate-12`, `translate-x-2`
- **Transitions**: `transition`, `duration-300`, `ease-in-out`
- **Animations**: `animate-spin`, `animate-pulse`

## Responsive Design

Tailwind uses a mobile‑first breakpoint system (`sm`, `md`, `lg`, `xl`, `2xl`). Prefix utilities with the breakpoint to apply at that size:
```html
<div class="text-base md:text-lg lg:text-xl">Responsive text</div>
```
Breakpoints can be customized in `tailwind.config.js`.

## Dark Mode Implementation

Enable `darkMode: "class"` in the config and toggle a `dark` class on the root element:
```html
<html class="dark">
  <body class="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
    ...
  </body>
</html>
```
You can also use the `media` strategy to follow the OS setting.

## Component Patterns (`@apply`)

Create reusable component classes in your CSS:
```css
.btn-primary {
  @apply bg-blue-600 text-white font-bold py-2 px-4 rounded hover:bg-blue-700;
}
```
Use `<button class="btn-primary">` in markup. Extract components with `@layer components` for better tree‑shaking.

## State Variants

Tailwind provides variants for many states: `hover:`, `focus:`, `active:`, `disabled:`, `visited:`, `group-hover:`, `motion-reduce:` etc.
```html
<button class="bg-green-500 hover:bg-green-600 focus:outline-none disabled:opacity-50">Click</button>
```

## Integration with Frameworks

- **React**: Install via npm, import the CSS, and use `className` strings.
- **Vue**: Use the `<style>` block with `@import 'tailwindcss/base';` or the `vite` plugin.
- **SolidJS**: Same as React, use class strings or the `solid-tailwindcss` preset.
- **Django**: Compile Tailwind with `django-tailwind` app, reference the generated CSS in templates.

## Optimization

- **Purging**: Tailwind automatically removes unused classes based on the `content` paths.
- **JIT Mode**: Enabled by default in Tailwind 3; generates only the utilities you use.
- **Content Configuration**: Ensure all template files are listed in `content` to avoid missing classes.

## Custom Utilities and Plugins

Add custom utilities in `tailwind.config.js`:
```js
module.exports = {
  plugins: [
    function({ addUtilities }) {
      const newUtilities = {
        ".skew-10": { transform: "skewY(-10deg)" },
      };
      addUtilities(newUtilities);
    },
  ],
};
```
Or use official plugins like `@tailwindcss/forms`, `@tailwindcss/typography`.

## Best Practices and Anti‑Patterns

- **Prefer utility classes over custom CSS**.
- **Group related utilities** (`flex`, `items-center`, `justify-between`).
- **Avoid deep nesting**; keep HTML shallow.
- **Do not duplicate Tailwind utilities**; use `@apply` for reusable patterns.
- **Limit use of `!important`**; Tailwind utilities are already specific.

## Common Issues and Solutions

- **Missing classes after build**: Verify `content` paths include all template files.
- **Dark mode not applying**: Ensure `dark` class is on a parent element and `darkMode` is set to `class`.
- **Performance hit**: Keep `purge` paths accurate; enable JIT.
- **Conflicts with other CSS frameworks**: Namespace Tailwind with a prefix in `tailwind.config.js`.
