# Theme Configuration with @theme

> This reference file is loaded on demand from `../SKILL.md`.

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

## Using Theme Values

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