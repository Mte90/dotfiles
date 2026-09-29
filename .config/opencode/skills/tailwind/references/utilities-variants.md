# Custom Utilities & Variants

> This reference file is loaded on demand from `../SKILL.md`.

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