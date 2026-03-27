:::: hero
[![Cowboys & Beans --- Back to
home](../../images/cowboys-and-beans_monogram-1.1-on-dark.png){.hero-monogram}](../../)

Strategies for Post-Template Web Design

# Breaking the Layout Monoculture

[A synthesis of academic research, modern CSS capabilities, editorial
design traditions, and spatial cognition applied to the question every
designer is asking: How do we make websites that don\'t all look the
same?]{.subtitle}

::: tag-row
[Research]{.tag} [CSS]{.tag} [Layout]{.tag} [Intrinsic Design]{.tag}
[Wayfinding]{.tag} [March 2026]{.tag}
:::
::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: container
::: section-label
The Problem
:::

## The Empirical Case Against Template Thinking

::: prose
The critique of web homogenisation is not aesthetic snobbery --- it is
backed by measurement. A landmark **CHI 2021 paper** (Proceedings of the
ACM Conference on Human Factors in Computing Systems) used computer
vision on a large dataset of websites from 2003--2019 and found a **30%
decrease in visual distance between websites** over that period, with
layout homogenisation accelerating. Interviews with 11 professionals
identified three drivers: shared code libraries, colour scheme
standardisation, and mobile-responsive constraints.
:::

::: epigraph
Every page consists of containers in containers in containers; sometimes
text, sometimes images. Nothing is truly designed, it\'s simply assumed.

--- Boris Müller, Professor of Interaction Design, FH Potsdam
:::

::: prose
Miriam Suzanne, a member of the W3C CSS Working Group, frames the
problem structurally: the 12-column grid that Bootstrap popularised was
never a design principle --- it was a workaround for CSS\'s layout
limitations. Now that those limitations are gone, the workaround
persists as convention.

The **cognitive cost** is real. Nielsen Norman Group\'s three decades of
banner blindness research demonstrates that users develop cognitive
schemas for familiar visual patterns and begin filtering them
automatically. The mechanism --- inattentional blindness --- extends
beyond banner ads to entire layout patterns. When every SaaS landing
page follows the same hero-features-testimonials-CTA-footer structure,
users shift into autopilot scanning, missing content in
expected-but-ignored zones. Research published in ACM Transactions on
Computer-Human Interaction further shows that even unviewed patterned
elements increase perceived cognitive workload and hinder visual search.
Template predictability doesn\'t just bore users; it measurably degrades
comprehension and engagement.

**Root causes are structural, not individual.** Bootstrap powers over 7
million websites. WordPress powers roughly 30% of the web. The
responsive design era\'s implicit bargain --- \"stick to columns and
blocks and your layout will just work\" --- rewarded conformity. Design
systems, while powerful for consistency, too often produce cookie-cutter
environments. Vasilis van Gemert (Amsterdam University of Applied
Sciences) argues that designers have reached \"peak graphical user
interface\" and proposes designing for specificity of context rather
than generic templates.
:::

------------------------------------------------------------------------

::: section-label
The Toolkit
:::

## The New CSS Toolkit Makes Intrinsic Layout Real

The most important development of 2023--2025 is not any single CSS
feature but their compound effect: for the first time, the web platform
supports genuinely two-dimensional, content-responsive, breakpoint-free
layout without JavaScript.

::::::: feature-grid
::: feature-card
[97%+ baseline]{.support-tag .support-baseline}

#### CSS Subgrid

Solves the long-standing problem of aligning nested content across
sibling components. A parent grid\'s track definitions pass through to
children via `grid-template-rows: subgrid`. This is the first web
technology that genuinely implements compound grids as envisioned by
Müller-Brockmann.
:::

::: feature-card
[93--96% baseline]{.support-tag .support-baseline}

#### Container Queries

Shift responsive design from viewport to component. Using `ch` units in
container queries eliminates magic-number breakpoints entirely.
Components adapt based on the space they actually occupy, not the
browser window size. Combined with container query units (`cqw`, `cqh`),
sizing becomes relative to context.
:::

::: feature-card
[Chrome/Edge + Safari 26]{.support-tag .support-partial}

#### Scroll-Driven Animations

Replace heavy JavaScript scroll libraries with native CSS.
`animation-timeline: scroll()` maps animation progress to scroll
position; `animation-timeline: view()` triggers as elements enter the
viewport. Editorial pacing without a single line of JavaScript.
:::

::: feature-card
[MPA + SPA support]{.support-tag .support-partial}

#### View Transitions API

Animated transitions between pages or states. The CSS-only opt-in:
`@view-transition { navigation: auto; }`. Elements maintain visual
identity across page transitions via `view-transition-name` --- what
wayfinding researchers call \"threshold design.\"
:::
:::::::

::: notes
### Other Capabilities Worth Noting

**CSS `:has()`** (90%+ support): parent-aware, content-conditional
layout logic in pure CSS. Style a grid differently based on how many
children it contains.

**Anchor positioning** (Chrome/Edge, Safari 26): declarative positioning
relative to other elements, replacing JavaScript libraries like Floating
UI.

**CSS math functions** (`round()`, `mod()`): snap fluid values to rhythm
grids. George Francis demonstrated combining `round()` with fluid
typography to achieve true baseline grid alignment --- a 15-year quest
finally resolved.

**CSS Grid Lanes (masonry)**: led by Jen Simmons at WebKit, with Safari
Technology Preview implementing `display: grid-lanes` for native
waterfall layouts.

**`@scope`** (Miriam Suzanne): bounded style ranges, preventing style
leakage without heavy BEM conventions or CSS-in-JS.

**Every feature listed above is pure CSS.** A sophisticated, distinctive
layout system can be built without JavaScript for layout.
:::

------------------------------------------------------------------------

::: section-label
The Stack
:::

## The Intrinsic Design Stack

The most intellectually rigorous approach to web layout currently
available combines Every Layout\'s composable primitives with Utopia\'s
fluid responsive mathematics.

### Every Layout\'s Primitives

::: prose
Every Layout (Heydon Pickering and Andy Bell) defines 12 layout
primitives --- Stack, Box, Center, Cluster, Sidebar, Switcher, Cover,
Grid, Frame, Reel, Imposter, and Icon --- designed for **zero media
queries**. The philosophy is \"the CSS of suggestion\": set constraints
rather than fixed dimensions, and let the browser resolve layout within
those constraints. This anticipated what Jen Simmons calls \"intrinsic
web design\" by several years.

Modern CSS enhances every primitive: the Stack benefits from CSS gap in
flex; the Sidebar gets more elegant sizing via `fit-content()` in Grid;
the Switcher can use container queries for clearer intent; the Grid
primitive gains subgrid for nested alignment; the Cover uses `dvh` to
fix mobile viewport height issues; the Reel gains scroll-driven
animations for progress indicators.
:::

### Utopia\'s Fluid Mathematics {#utopias-fluid-mathematics style="margin-top: var(--space-l);"}

::: prose
Utopia (James Gilyead and Trys Mudford) defines type and space at
minimum and maximum viewport widths with different modular scale ratios,
then interpolates between them via `clamp()` with mixed `rem` and `vi`
units. The result: smooth, continuous type and spacing transitions with
no jarring layout shifts at any viewport size. The use of `vi` (viewport
inline) rather than `vw` preserves zoom accessibility, satisfying WCAG
requirements.

Space tokens derived from the same modular scale as typography create
what Massimo Vignelli called \"syntactical consistency\" --- spacing and
type as a unified mathematical system. When the type scale is built on
musical interval ratios (perfect fourth at 4:3, perfect fifth at 3:2,
major third at 5:4), the space system inherits that proportional harmony
automatically.
:::

### The Full Stack at a Glance {#the-full-stack-at-a-glance style="margin-top: var(--space-l);"}

  Layer          Tool                                 Purpose
  -------------- ------------------------------------ ------------------------------------------
  Typography     Utopia fluid type scale              Breakpoint-free, modular, accessible
  Spacing        Utopia fluid space scale             Harmonised with type, clamp()-based
  Colour         OKLCH + color-mix() + light-dark()   Perceptually uniform, CSS-native
  Layout         Every Layout primitives              Composable, intrinsically responsive
  Alignment      CSS Subgrid                          Nested content alignment
  Adaptation     Container queries                    Component-level responsiveness
  Transitions    View Transitions API                 Perceptual continuity between pages
  Scroll         Scroll-driven animations             Editorial pacing, progressive disclosure
  Architecture   \@scope + nesting + \@layer          Clean cascade management
  Methodology    CUBE CSS                             Composition-first CSS architecture

------------------------------------------------------------------------

::: section-label
Historical Roots
:::

## Editorial Design Principles, Finally Expressible in CSS

::: prose
The tension between print editorial ambition and web fluidity is
dissolving. CSS Grid is the first web technology that is truly
two-dimensional --- enabling designers to think in rows and columns
simultaneously, exactly as print designers always have.
:::

::: {.notes style="margin-top: var(--space-m);"}
### Historical Principles Map to CSS with Remarkable Directness

**Tschichold\'s asymmetric typography** (1928) becomes
`grid-template-columns: 2fr 5fr 3fr` instead of the ubiquitous
`1fr 1fr 1fr`. His principle that \"form must be created out of
function\" parallels intrinsic sizing (`min-content`, `max-content`,
`fit-content()`).

**Müller-Brockmann\'s modular grids** (1981) --- rows AND columns
creating discrete cells --- are native CSS Grid: `grid-template-columns`
plus `grid-template-rows`, with subgrid for compound grids and named
areas for hierarchical structures.

**Vignelli\'s systematic restraint** --- limited typefaces, strict
grids, spacing as syntax --- is precisely the design token and custom
property approach. Jon Yablonski\'s Swiss in CSS project
(swissincss.com) recreates iconic Swiss Style posters entirely in CSS
with animation.
:::

::: {.prose style="margin-top: var(--space-l);"}
**Techniques that now work in pure CSS:** named grid areas for layout
declared in ASCII-art syntax; named grid lines for editorial column
structures with full-bleed breakouts; overlapping elements via same-cell
grid placement with z-index; baseline grids using the CSS `cap` unit;
editorial pacing through alternating dense and airy sections;
`shape-outside` for text wrapping; `clip-path` for non-rectangular
crops; and `initial-letter` for drop caps.
:::

------------------------------------------------------------------------

::: section-label
Spatial Cognition
:::

## Wayfinding Science and Spatial Navigation

::: prose
For hub pages, portal sites, and any page whose primary job is to help
visitors find their way to deeper content, the most useful academic
framework comes from **Kevin Lynch\'s** urban planning research,
translated to digital spaces by Mark Foltz\'s MIT thesis \"Designing
Navigable Information Spaces.\" Lynch identified five elements of
legible environments: **paths, landmarks, regions, edges, and nodes**. A
homepage is a node; each major section is a region; the visual
transitions between them are edges.
:::

::: {.notes style="margin-top: var(--space-m);"}
### Key Principles from Spatial Cognition Research

**Gestalt grouping:** proximity groups related elements; similarity
within sections creates coherence; dissimilarity across sections creates
distinction. Common region (elements within shared boundaries) defines
territory. Closure --- the mind filling in gaps --- means partial
content revelation signals \"there\'s more,\" a powerful progressive
disclosure cue.

**Spatial memory:** Nielsen Norman Group research shows that spatially
stable interfaces reduce cognitive effort across return visits. Users
develop spatial memory relative to boundaries and landmarks. Broad,
shallow hierarchies are more efficient than narrow, deep ones.

**Information scent** (Pirolli & Card, PARC): users are \"informavores\"
following scent trails. Each section must emit strong, differentiated
signals --- unambiguous labels, visual context, and spatial grouping
that keeps each area\'s cues coherent.

**Tufte\'s data-ink ratio:** maximise the proportion of visual elements
that communicate useful information. Support both overview scanning and
detailed reading. Use \"small multiples\" --- consistent templates
across repeated content types.
:::

### Museum Wayfinding: The Strongest Design Analogue {#museum-wayfinding-the-strongest-design-analogue style="margin-top: var(--space-xl);"}

Museum websites face the same challenge as any multi-section portal:
making diverse content discoverable while creating a sense of
exploration.

::::::::::::::: museum-grid
:::: museum-item
::: museum-name
Victoria & Albert Museum
:::

Colour reserved exclusively for revenue-generating content as a
\"breadcrumb trail.\" A \"city wayfinding\" approach treating the museum
as neighbourhoods, encouraging exploration of lesser-known areas.
::::

:::: museum-item
::: museum-name
Whitney Museum
:::

A typographic grid derived from the logo serves as a container for
directional information --- functionally effective yet subdued enough
not to compete with the art.
::::

:::: museum-item
::: museum-name
Nordiska Museet
:::

2025 Webby winner. Each exhibition gets its own adapted colour palette
while maintaining overall coherence, with scroll-responsive text
animations within a unified system.
::::

:::: museum-item
::: museum-name
MIT Museum
:::

Images behind blocks of colour with geometric \"peephole\" shapes
created by CSS clip-path --- partial revelation as an engagement
mechanism, inviting curiosity without revealing everything.
::::

:::: museum-item
::: museum-name
British Museum
:::

Each exhibition\'s colour is drawn from the exhibition content itself,
appearing on hover elsewhere --- content-derived theming.
::::

:::: museum-item
::: museum-name
Van Gogh Museum
:::

Horizontal scrolling on the homepage, signalling \"this is an
exploration space\" rather than linear consumption --- achievable with
CSS scroll-snap-type.
::::
:::::::::::::::

------------------------------------------------------------------------

::: section-label
The Approaches
:::

## Seven Concrete Approaches for Breaking Out

Synthesising across all the research streams above: the most
research-grounded, CSS-implementable, intrinsic-design-compatible
approaches for building layouts that break away from the template
monoculture.

:::: {.approach-card num="1"}
### Spatial Zoning Over Card Grids

::: prose
Treat the page as a **spatial map with distinct zones** --- each
occupying defined territory on the viewport with a unique visual
identity. CSS Grid with named areas, OKLCH-derived per-section colour
via custom properties, and typographic micro-variations per zone. This
follows Lynch\'s \"regions\" principle and leverages Gestalt common
region and proximity. The page becomes a landscape to survey, not a menu
to read. Pure CSS, no JavaScript required.
:::
::::

:::: {.approach-card num="2"}
### Thematic Colour Differentiation with Content-Derived Palettes

::: prose
Following the Nordiska Museet and British Museum model, each section
gets its own OKLCH colour palette cascading through custom properties.
Colour becomes a wayfinding beacon, reserved for section identity rather
than decoration. Use `color-mix()` in OKLCH for tint/shade variations.
The V&A principle: colour as breadcrumb trail. Pure CSS.
:::
::::

:::: {.approach-card num="3"}
### View Transitions as Threshold Design

::: prose
When navigating between pages or major sections, CSS View Transitions
provide perceptual continuity --- the visual \"threshold\" that museum
wayfinding research identifies as critical. Elements maintain identity
across transitions via `view-transition-name`. For multi-page
architecture: `@view-transition { navigation: auto; }`. CSS-only.
:::
::::

:::: {.approach-card num="4"}
### Editorial Pacing Through Varied Grid Configurations

::: prose
Instead of uniform sections, alternate between dense and airy
compositions. Use subgrid to maintain a macro typographic grid while
varying column structures section by section. Asymmetric `fr` ratios
(Tschichold) create visual interest; `auto-fit`/`auto-fill` with
`minmax()` creates intrinsically responsive columns. Implement baseline
alignment with the `cap` unit breakthrough. Pure CSS.
:::
::::

:::: {.approach-card num="5"}
### Progressive Disclosure via Scroll-Driven Animation

::: prose
Use native CSS scroll-driven animations for subtle content revelation
--- not parallax spectacle, but informational unfolding.
`animation-timeline: view()` triggers as elements enter the viewport;
`animation-range` provides fine-grained control. Combined with `:has()`
for content-conditional styling, layout can respond to what is present
rather than requiring media queries.
:::
::::

:::: {.approach-card num="6"}
### Partial Revelation Using Clip-Path

::: prose
The MIT Museum\'s \"peephole\" approach --- showing content behind
geometric shapes that invite curiosity --- translates directly to CSS
`clip-path`. Tease imagery or content through shaped windows that signal
\"there\'s more.\" Combined with hover states that expand the reveal,
this creates engagement without heavy imagery. Pure CSS.
:::
::::

:::: {.approach-card num="7"}
### Horizontal or Lateral Exploration

::: prose
For certain content types, horizontal scrolling with CSS
`scroll-snap-type` signals exploration rather than linear consumption.
The Van Gogh Museum demonstrates this at the page level. Every Layout\'s
Reel primitive provides the composable abstraction. This creates a
scanning pattern distinct from the vertical scroll and is achievable
entirely in CSS with scroll-snap.
:::
::::

------------------------------------------------------------------------

::: section-label
Synthesis
:::

## The Deeper Point

::: epigraph
The grid is not the enemy. It\'s our launchpad. Every audacious layout
choice must be a stepping stone, not a stumbling block, on the user\'s
path.

--- KOTA
:::

::: prose
The key insight from this research is that **breaking layout conventions
effectively requires stronger principles, not weaker ones**. The sites
and systems doing genuinely innovative work --- Every Layout, Utopia,
the Nordiska Museet, the V&A wayfinding system --- are all characterised
by extreme systematicity. They are not \"creative\" in the sense of
arbitrary novelty; they are creative because their constraints are
better chosen.

The convergence of modern CSS capabilities with historical design
principles creates a genuine inflection point. Subgrid enables
Müller-Brockmann\'s compound grids. Asymmetric `fr` ratios express
Tschichold\'s dynamic balance. Custom properties encode Vignelli\'s
systematic restraint. Container queries make intrinsic design
component-aware. Scroll-driven animations create editorial pacing
without JavaScript.

The CHI 2021 research confirms web design has measurably homogenised ---
and the cognitive science (banner blindness, schema filtering,
inattentional blindness) confirms this has real costs. But the antidote
is not novelty for its own sake. It is principled design using better
constraints. The tools are here. The research supports it. The only
remaining question is whether we\'re willing to stop reaching for the
template.
:::

------------------------------------------------------------------------

::: section-label
Appendix
:::

## Key References and Resources

::: ref-section
#### Academic Research

- CHI 2021: *Investigating the Homogenization of Web Design: A
  Mixed-Methods Approach* (ACM)
- Czerwinski & Larson (2002): *Cognition and the Web*, Microsoft
  Research
- Pirolli & Card: Information scent / information foraging theory, Xerox
  PARC
- NN/g: *Banner Blindness Revisited*; *Spatial Memory: Why It Matters
  for UX Design*
- ACM TOCHI: *High-cost banner blindness: Ads increase perceived
  workload*
- ACM Interactions, May--June 2025: *Where Is \'Spatial\' in Spatial
  Design?*
- Foltz, M.: *Designing Navigable Information Spaces* (MIT thesis)
:::

::: ref-section
#### Books and Primary Sources

- Tschichold, J. (1928): *The New Typography*
- Müller-Brockmann, J. (1981): *Grid Systems in Graphic Design*
- Vignelli, M. (2010): *The Vignelli Canon* (free PDF)
- Lynch, K. (1960): *The Image of the City*
- Tufte, E.: *The Visual Display of Quantitative Information*;
  *Envisioning Information*
:::

::: ref-section
#### Online Resources

- Every Layout: every-layout.dev (Pickering & Bell)
- Utopia: utopia.fyi (Gilyead & Mudford)
- CUBE CSS: cube.fyi (Andy Bell)
- Swiss in CSS: swissincss.com (Jon Yablonski)
- Jen Simmons\' Layout Lab: labs.jensimmons.com
- Josh Comeau: joshwcomeau.com/css/subgrid/
- Make Type Work (baseline grids): maketypework.com
- MDN: Subgrid, Container Queries, View Transitions, Scroll-Driven
  Animations
- Smashing Magazine: *Editorial Design Patterns with CSS Grid* (Rachel
  Andrew)
- Boris Müller: *Why Do All Websites Look the Same?* (Medium)
:::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::: footer
::::: footer-inner
::: brand
[Cowboys](../../) [&]{.amp} [Beans](../../)
:::

::: meta
Breaking the Layout Monoculture · Research · March 2026 · CC0 Public
Domain
:::
:::::
::::::
