---
name: visual-design-system
description: |
  Visual design principles, colour, typography, layout, and spatial composition
  for Cowboys & Beans projects. Use when: designing web pages or components,
  choosing colours, setting up type scales, composing layouts, writing CSS,
  building design tokens, creating fluid responsive designs, reviewing visual
  quality, breaking out of template patterns, designing navigation/wayfinding,
  theming across multiple sites, or answering any visual design question.
---

# Visual Design Skill — Principled Design for the Web

This project's visual design is grounded in perceptual science, mathematical proportion, and composable spatial primitives. It produces work that is distinctive, fluid, and formally rigorous — not another Bootstrap clone. The six guides below encode the system; this skill teaches you how to use them.

**Core stance**: Design decisions are engineering problems — constrained, measurable, and composable. The best design systems are algebraic structures, not collections of components.

---

## What Each Guide Does For You

Load the right `design` subfolder for your task. Each one gives you a different superpower.

| Guide | File | What It Gives You | When To Load |
|-------|------|-------------------|--------------|
| **Design Manifesto** | `design.md` | The *why* — seven principles grounded in perceptual science. This is the philosophical backbone. | When you need to justify a design decision, resolve a trade-off, or check whether a choice is principled or arbitrary. |
| **Foundations of Design** | `foundations-of-design.md` | Comprehensive research survey — competency questions, source analysis, mathematical structure (Fitts's Law, Weber-Fechner, Stevens's Power Law, gestalt formalisations), cross-domain analogies, notation conventions, CSS landscape. | When you need intellectual depth: understanding *why* geometric scales work, *why* OKLCH matters, the empirical grounding for any design choice, or bridging to music theory / software engineering / mathematics. |
| **Colour System** | `colour.md` | The actual token architecture — OKLCH scales for brand, neutrals, and per-site accents; semantic layer (surfaces, text, borders, interactive); three-site theming. | When writing CSS colour values, building palettes, creating themes, mapping primitives to semantic tokens, or choosing any colour. |
| **Type System** | `type.md` | The three-voice type stack (Fraunces, Literata, IBM Plex Mono), perfect fourth modular scale, fluid interpolation math, per-site axis tuning, variable font axis usage. | When setting font sizes, choosing typefaces, configuring variable font axes, building type hierarchies, or writing any `font-*` CSS. |
| **Layout Philosophy** | `layout.md` | The spatial composition system — seven precepts, Every Layout primitives (Stack, Box, Center, Cluster, Sidebar, Switcher, Cover, Grid, Frame, Reel, Imposter, Icon, Container), Utopia fluid tokens, CUBE CSS methodology, worked example. | When composing any layout, writing structural CSS, choosing spacing values, or building any page from primitives. This is the most frequently needed guide. |
| **Breaking the Monoculture** | `breaking-the-layout-monoculture.md` | Research-backed strategies for distinctive layouts — CHI 2021 homogenisation data, spatial zoning, editorial pacing, view transitions, scroll-driven animations, clip-path reveals, wayfinding science (Lynch's five elements), museum design case studies. | When designing a homepage, portal page, or any page that needs to feel *distinctive* rather than template-stamped. Also for progressive disclosure, transitions between pages/sections, and horizontal exploration patterns. |

---

## Document Selection by Task

| Task | Load These |
|------|-----------|
| **Design a new page from scratch** | `layout.md` (always first), `colour.md`, `type.md` |
| **Build a homepage / portal** | `breaking-the-layout-monoculture.md`, `layout.md`, `colour.md` |
| **Write CSS for a component** | `layout.md` (primitives), `colour.md` (tokens), `type.md` (scale) |
| **Choose or adjust colours** | `colour.md`, then `design.md` Principle II (perceptual uniformity) |
| **Set up typography** | `type.md`, then `layout.md` Precept VI (unified type/space/grid) |
| **Create spacing / layout tokens** | `layout.md` (Utopia section), `type.md` (scale math) |
| **Review visual quality** | `design.md` (seven principles), `foundations-of-design.md` (six developer mistakes) |
| **Justify a design decision** | `design.md` (principles), `foundations-of-design.md` (empirical grounding) |
| **Theme across multiple sites** | `colour.md` (per-site accents), `type.md` (per-site axis tuning), `design.md` Principle V (unity ≠ uniformity) |
| **Add animation / transitions** | `breaking-the-layout-monoculture.md` (scroll-driven, view transitions) |
| **Design wayfinding / navigation** | `breaking-the-layout-monoculture.md` (Lynch, museum case studies, spatial cognition) |
| **Build a design token file** | `colour.md` (three-tier architecture), `foundations-of-design.md` (DTCG spec, notation conventions) |
| **Explain design to a developer** | `foundations-of-design.md` (Rosetta Stone section — software engineering ↔ design mappings) |
| **Respond to "it looks off"** | `design.md` Principle I (geometric scales), Principle VI (proximity carries meaning), `foundations-of-design.md` (six developer mistakes) |

---

## The Seven Principles (from `design.md`)

Memorize these. They resolve almost every design trade-off.

| # | Principle | One-Sentence Rule | Violation Smell |
|---|-----------|-------------------|-----------------|
| I | **Multiply, Never Add** | All scales (type, space, colour lightness) must be geometric, not arithmetic. | A spacing value that's "4px more than the last one" instead of "1.333× the last one." |
| II | **Perception Is the Only Coordinate System** | Use OKLCH for colour, `rem`/`ch`/`vi` for sizing — units that describe experience, not mechanism. | Hex colours, `px` for type sizes, `vw` instead of `vi`. |
| III | **Name the Role, Not the Value** | Three-tier tokens: primitive → semantic → component. Never use `var(--brand-700)` in a component. | `background: var(--brand-700)` instead of `background: var(--interactive-primary)`. |
| IV | **Constraint Liberates** | Small, well-chosen palettes (3 fonts, 9 space tokens, 1 accent hue per site) produce better outcomes than infinite options. | "I'll just pick whatever looks good here." |
| V | **Unity Is Not Uniformity** | Shared mathematical structure, site-specific expression. Same skeleton, different posture. | Three sites that look identical, or three sites with nothing in common. |
| VI | **Proximity Carries Meaning** | Intra-group spacing < inter-group spacing. Always. Uniform spacing destroys information. | Same `16px` gap inside cards, between cards, and between sections. |
| VII | **Design the Invariants** | Define relationships (ratios, mappings, axioms), not individual values. The system generates instances. | Hand-picking a font size for one specific heading instead of using the scale. |

---

## The Layout Primitives (from `layout.md`)

Every layout is a composition of these. No bespoke CSS layouts — compose from primitives.

| Primitive | Responsibility | Key CSS | When To Use |
|-----------|---------------|---------|-------------|
| **Stack** | Vertical spacing between siblings | `flex-direction: column; gap: var(--space-*)` | Nearly everything — any vertical flow of content |
| **Box** | Inset padding | `padding: var(--space-*)` | Cards, panels, any padded container |
| **Center** | Max-width + horizontal centering | `max-inline-size: 60ch; margin-inline: auto` | Prose, any width-constrained content |
| **Cluster** | Horizontal wrapping group | `flex-wrap: wrap; gap: var(--space-*)` | Tags, buttons, nav links, metadata |
| **Sidebar** | Main + aside (stacks when narrow) | `flex-basis` on sidebar, `flex-grow: 999` on main | Any two-panel layout |
| **Switcher** | Multi-col → single-col based on space | `flex-wrap: wrap` with calculated `flex-basis` | Responsive columns without breakpoints |
| **Cover** | Vertically centered content | `min-block-size` with `place-items: center` | Hero sections, full-viewport panels |
| **Grid** | Repeating equal columns | `auto-fit` + `minmax()` | Card grids, galleries, any repeating pattern |
| **Frame** | Aspect-ratio-locked media | `aspect-ratio` | Images, video embeds |
| **Reel** | Horizontal overflow scroll | `overflow-x: auto; scroll-snap-type` | Carousels, image strips |
| **Imposter** | Positioned outside flow | `position: absolute/fixed` | Modals, tooltips, overlays |
| **Icon** | Inline SVG sized to text | `inline-size: 0.75em; block-size: 0.75em` | Icons next to text |
| **Container** | Outermost page width | `max-inline-size` + `padding-inline` | Page wrapper |

**Composition example**: A card = Box (padding) containing a Stack (vertical flow). A page header = Cover containing a Center containing a Stack. A navigation = Cluster inside a Box.

---

## The Colour Architecture (from `colour.md`)

### Three-Tier Tokens

```
Primitive:    --brand-700, --neutral-200, --books-500
                    ↓
Semantic:     --interactive-primary, --surface-secondary, --text-brand
                    ↓
Component:    --button-primary-bg (future layer)
```

**Rule**: Components reference semantic tokens, never primitives.

### The Palette

- **Brand browns**: Hue ~50° (warm amber), 11 steps (950→50), OKLCH lightness 15→95
- **Warm neutrals**: Hue 55°, chroma 0.01, 11 steps — reads grey but carries warm undertone
- **Per-site accents** (5 steps each):
  - `books.cnbb.pub` → Ink blue, hue 255°
  - `art.cnbb.pub` → Sage green, hue 155°
  - `cnbb.pub` → Terracotta, hue 35°

### Semantic Tokens

| Role | Token | Maps To |
|------|-------|---------|
| Page background | `surface-primary` | `brand-50` |
| Cards, sections | `surface-secondary` | `neutral-100` |
| Modals | `surface-elevated` | `neutral-50` |
| Dark sections | `surface-inverse` | `brand-950` |
| Body text | `text-primary` | `neutral-950` |
| Captions | `text-secondary` | `neutral-700` |
| Disabled | `text-tertiary` | `neutral-500` |
| Buttons, links | `interactive-primary` | `brand-700` |
| Hover | `interactive-hover` | `brand-800` |
| Active | `interactive-active` | `brand-900` |
| Soft dividers | `border-subtle` | `neutral-200` |
| Standard borders | `border-default` | `neutral-300` |

---

## The Type System (from `type.md`)

### Three Voices

| Role | Typeface | Axes | Use For |
|------|----------|------|---------|
| **Display & Headlines** | Fraunces | WONK, SOFT, opsz, wght | Headlines, titles, brand moments |
| **Body & Long-form** | Literata | opsz, wght | Prose, descriptions, reading |
| **UI & System** | IBM Plex Mono | wght | Metadata, dates, ISBNs, nav labels, code, captions |

### The Scale

**Perfect fourth** (4:3 = 1.333). Fluid: tightens to major third (1.25) at 360px, opens to full 4:3 at 1440px.

| Step | Role | Typeface |
|------|------|----------|
| step 5 | Display | Fraunces 800, SOFT 50, WONK 1 |
| step 4 | Hero heading | Fraunces 700, SOFT 40, WONK 1 |
| step 3 | Section heading | Fraunces 600, SOFT 30, WONK 1 |
| step 2 | Subsection | Fraunces 600, SOFT 20, WONK 0 |
| step 1 | Lead / large body | Literata 400, opsz 20 |
| step 0 | Body text | Literata 400, opsz 14 |
| step −1 | Small / caption | Literata 400, opsz 10 |
| step −2 | Micro / meta | Plex Mono 400 |

### Per-Site Axis Tuning

Same typefaces, different personality via axis settings:

| Site | Fraunces Weight | SOFT | WONK | Character |
|------|-----------------|------|------|-----------|
| `books.cnbb.pub` | 700 | 20 | 0 | Sharp, editorial, no wonk |
| `art.cnbb.pub` | 300 | 70 | 0 | Light, soft, airy, recessive |
| `cnbb.pub` | 900 | 60 | 1 | Heavy, soft, wonky — full personality |

---

## Fluid Responsive System (from `layout.md` + `type.md`)

### The Two Design Decisions

Everything derives from these:
- **@min**: 360px viewport, 16px base, ratio 1.200 (minor third)
- **@max**: 1440px viewport, 20px base, ratio 1.333 (perfect fourth)

### Utopia Tokens

Type, space, and grid are **one unified mathematical system**. The base space token equals the base type size. Space pairs (e.g., `--space-s-l`) interpolate steeply for component padding.

```css
/* Type scale */
--step-0: clamp(1rem, 0.9015rem + 0.4924vi, 1.3337rem);
--step-1: clamp(1.2rem, 1.0534rem + 0.7331vi, 1.7783rem);

/* Space scale (derived from type) */
--space-s: var(--step-0);
--space-m: clamp(1.5rem, 1.3523rem + 0.7385vi, 2.0006rem);

/* Space pairs (steeper interpolation) */
--space-s-l: clamp(1rem, 0.5038rem + 2.4808vi, 2.6674rem);
```

### Zero Breakpoints

No media queries for layout. Primitives + fluid tokens handle all responsiveness. The test: if you removed every media query, would the layout still work?

---

## Breaking Templates (from `breaking-the-layout-monoculture.md`)

### Why It Matters

Web design has homogenised 30% over 16 years (CHI 2021). Users develop banner blindness to template patterns. The antidote is **stronger principles, not weaker ones**.

### Seven Strategies

| # | Strategy | CSS Tools | When |
|---|----------|-----------|------|
| 1 | **Spatial Zoning** | Named grid areas, per-section custom properties | Homepages, portals — treat page as landscape, not list |
| 2 | **Content-Derived Colour** | `color-mix()` in OKLCH, custom properties per section | Multi-section pages — colour as wayfinding beacon |
| 3 | **View Transitions** | `@view-transition { navigation: auto; }`, `view-transition-name` | Page-to-page navigation — perceptual continuity |
| 4 | **Editorial Pacing** | Subgrid, asymmetric `fr` ratios, varied grid configs | Long-form pages — alternate dense and airy |
| 5 | **Scroll-Driven Reveal** | `animation-timeline: view()`, `animation-range` | Content revelation — informational unfolding, not spectacle |
| 6 | **Clip-Path Reveals** | `clip-path`, hover expansion | Tease content through geometric windows |
| 7 | **Horizontal Exploration** | `scroll-snap-type`, Reel primitive | Gallery/exploration contexts — signal non-linear browsing |

### Wayfinding (Lynch's Five Elements)

When designing navigation-heavy pages, think in spatial terms:
- **Paths**: How users move through the site (navigation, links, scroll)
- **Landmarks**: Visually distinctive elements that orient (hero images, brand marks)
- **Regions**: Distinct areas with their own visual identity (colour-coded sections)
- **Edges**: Boundaries between regions (transitions, borders, whitespace shifts)
- **Nodes**: Decision points where paths converge (homepages, hub pages)

---

## The Six Developer Design Mistakes (from `foundations-of-design.md`)

Check every design output against these. They account for the majority of the quality gap between developer-built and designer-built interfaces.

| # | Mistake | Fix |
|---|---------|-----|
| 1 | **No visual hierarchy** — everything has equal weight | Assign primary/secondary/tertiary to every element. Use size, weight, colour, contrast together. |
| 2 | **Inconsistent spacing** — no system | Use Utopia space tokens exclusively. Never pick a pixel value by eye. |
| 3 | **Unconstrained colour** — too many unrelated hues | One accent hue per site + brand browns + warm neutrals. Semantic tokens only. |
| 4 | **No type scale** — random font sizes | Perfect fourth modular scale. Every size from `--step-*`. |
| 5 | **Data-model UI** — organised by database tables, not user tasks | Organise around goals ("Process orders"), not entities ("Orders table"). |
| 6 | **Equal-weight buttons** — no primary/secondary distinction | One primary action per context. Secondary and tertiary buttons visually recede. |

---

## Workflows

### Designing a New Page

1. **Start with layout.md**: Identify which primitives compose this page (Container → Stack → Sidebar → Grid, etc.)
2. **Load colour.md**: Map semantic tokens to surfaces, text, borders, interactive elements
3. **Load type.md**: Assign scale steps to headings, body, captions, metadata
4. **Check against the six mistakes**: Hierarchy? Consistent spacing? Constrained colour? Type scale? Task-driven? Button hierarchy?
5. **Check against the seven principles**: Every value from a scale? Semantic token names? Proximity encoding meaning? Constraint-based?

### Reviewing Visual Quality

1. **Squint test**: Does hierarchy survive? Can you tell primary from secondary content?
2. **Spacing audit**: Is intra-group < inter-group everywhere? Any arbitrary pixel values?
3. **Colour audit**: Only semantic tokens? No raw primitives in components? Accessible contrast?
4. **Type audit**: Every size from `--step-*`? Correct typeface per role? Fluid via `clamp()`?
5. **Breakpoint test**: Remove all media queries mentally — does it still work?
6. **Template test**: Does this page look like it could have come from a generic template? If yes, load `breaking-the-layout-monoculture.md`.

### Making a Page Distinctive

1. **Load `breaking-the-layout-monoculture.md`** first
2. **Choose 2-3 strategies** from the seven (spatial zoning + editorial pacing + scroll-driven reveal, for example)
3. **Apply wayfinding thinking**: What are the landmarks? The regions? The paths?
4. **Use asymmetry**: `2fr 5fr 3fr` instead of `1fr 1fr 1fr`. Tschichold, not Bootstrap.
5. **Verify it's still principled**: Distinctive ≠ arbitrary. Every choice should trace back to a principle.

---

## Quick Reference: CSS Patterns

### Fluid Type Step

```css
h2 { font-size: var(--step-3); }
```

### Fluid Spacing

```css
.section + .section { margin-block-start: var(--space-l-xl); }
.card { padding: var(--space-s-m); }
```

### Stack Primitive

```css
.stack { display: flex; flex-direction: column; gap: var(--space-s); }
```

### Sidebar Primitive

```css
.with-sidebar {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-l);
}
.with-sidebar > .sidebar { flex-basis: 20rem; flex-grow: 1; }
.with-sidebar > .main { flex-basis: 0; flex-grow: 999; min-inline-size: 55%; }
```

### Intrinsic Grid (no column count)

```css
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 250px), 1fr));
  gap: var(--space-s-m);
}
```

### Measure Axiom

```css
* { max-inline-size: 60ch; }
html, body, div, header, nav, main, footer { max-inline-size: none; }
```

### Semantic Colour Usage

```css
/* Correct: semantic token */
.button { background: var(--interactive-primary); }
.button:hover { background: var(--interactive-hover); }

/* Wrong: primitive token in component */
.button { background: var(--brand-700); }
```

### Per-Site Theming via Accent Override

```css
/* books.cnbb.pub */
:root { --accent-500: var(--books-500); --accent-700: var(--books-700); }

/* art.cnbb.pub */
:root { --accent-500: var(--art-500); --accent-700: var(--art-700); }
```

---

## The Deeper Structure (for reasoning about trade-offs)

When principles seem to conflict, these foundational insights resolve them:

- **Human perception is logarithmic** (Weber-Fechner). Every quantitative scale must be geometric. This is not preference — it is neuroscience.
- **Proximity is processed before all other cues** (Gestalt). Spacing is not decoration; it is syntax.
- **Regular patterns are metabolically cheap to process** (neural efficiency). "It just looks off" = the viewer detected a mathematical irregularity they can't name.
- **Musical intervals and type ratios use the same mathematics** (rigorous, not metaphor). Perfect fourth in music = perfect fourth in type = 4:3 ratio.
- **Colour space conversions are 3×3 matrix multiplications** (linear algebra). OKLCH's perceptual uniformity is analogous to equal temperament in music — both uniformise inherently non-uniform perceptual spaces.
- **"Composition over inheritance" applies to CSS exactly as to software** (Every Layout explicitly argues this). Compose from primitives; don't build monolithic components.
- **The token architecture IS the separation of concerns** — primitives are type definitions, semantic tokens are interfaces, component tokens are implementations.
