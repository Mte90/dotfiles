:::: hero
[![Cowboys & Beans --- Back to
home](../../images/cowboys-and-beans_monogram-1.1-on-dark.png){.hero-monogram}](../../)

A Philosophy of Spatial Composition

# The Layout Philosophy

On fluid composition, algorithmic restraint, and the art of letting the
browser think. A unified layout design philosophy for Cowboys & Beans
projects.

::: tag-row
[Intrinsic Design]{.tag} [Every Layout]{.tag} [Utopia]{.tag} [CUBE
CSS]{.tag} [CC0 --- Public Domain]{.tag} [March 2026]{.tag}
:::
::::

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: container
[]{#preamble}

::: section-label
Preamble
:::

## Why This Document Exists

::: prose
This is the layout counterpart to the Cowboys & Beans colour system,
type system, and brand guidelines. Where those documents describe *what
things look like*, this one describes *how things are arranged* --- and,
more importantly, *why*.

Most layout documentation tells you which CSS properties to use. This
document does something different. It articulates a **philosophy of
spatial composition** that can generate an infinite variety of layouts
from a small set of principles --- all of them consistent, all of them
fluid, none of them requiring media-query breakpoints, and every one of
them genuinely tailored to its content rather than stamped from a
template.

The philosophy synthesises two bodies of work that represent the current
state of the art in CSS layout thinking: **Every Layout** by Heydon
Pickering and Andy Bell, which defines composable layout primitives; and
**Utopia** by James Gilyead and Trys Mudford, which defines fluid
responsive mathematics. It also draws from the Arts & Crafts tradition,
from Müller-Brockmann\'s grid systems, from Vignelli\'s systematic
restraint, and from the C&B engineering manifesto\'s conviction that
good design is algebraic structure, not decorative intuition.

The goal is not to create a new set of constraints in which to bind
ourselves. It is to provide the knowledge, the vocabulary, and the tools
with which anyone can build the layout that *their* project needs --- a
layout that is beautiful, functional, and makes people want to stay and
explore. And perhaps even inspires them to build their own.
:::

::: {.epigraph style="margin-top: var(--space-xs);"}
Think of yourself as the browser\'s mentor, rather than its
micro-manager.

--- Heydon Pickering & Andy Bell, Every Layout
:::

------------------------------------------------------------------------

[]{#part-i}

::: section-label
Part I
:::

## The Intellectual Foundations

Two independent projects, arriving at the same truth from different
directions. Understanding where they converge --- and where each one
picks up where the other leaves off --- is the key to the whole system.

### Every Layout: The Grammar of Spatial Relationships

::: prose
Every Layout begins with a radical premise: **the web is already
responsive**. Before any CSS is written, browsers know how to wrap text,
scroll content, and fit boxes to their containers. The vast majority of
layout problems arise not from CSS\'s limitations but from designers
fighting its built-in algorithms --- applying fixed widths where
flexible ones would do, using pixel values where proportional ones would
adapt, writing media queries to undo the damage of earlier rigid
declarations.

The project\'s six \"Rudiment\" chapters build up a complete
epistemology of CSS layout from first principles. It starts with
**Boxes** --- the insight that everything on the web occupies a
rectangular region, and that the dimensions of that region should be
*derived from content and context*, not prescribed. The crucial
technical point is the difference between `width: 100%` (which
prescribes a size and then adds padding on top of it) and `width: auto`
(which lets the box fit its context naturally). This is not pedantry. It
is the atomic distinction between fighting the browser and collaborating
with it.

From Boxes, Every Layout moves to **Composition** --- the explicit
application of the Gang of Four software engineering principle
\"composition over inheritance\" to CSS layout. Where a typical approach
might create a bespoke `.dialog` class with dedicated styles for header,
body, and footer, compositional thinking decomposes the same dialog into
a Stack (for vertical spacing), a Box (for padding), a Cluster (for the
button row), and a Center (for the content width). The dialog is not a
thing to be styled; it is a *composition* of simpler things, each with a
single, reusable responsibility.

The **Units** chapter makes the case against pixels with precision. The
value of `1px` is not what it seems --- it varies across devices, zoom
levels, and display densities. More importantly, pixels create *no
relationship* between the value and the content it measures. The `ch`
unit, by contrast, is defined by the font\'s own geometry: `60ch` is
always roughly 60 characters wide, regardless of font size or screen
density. The `rem` unit anchors to the user\'s chosen root font size,
respecting their accessibility preferences. The `em` unit creates local
proportional relationships, so that a child element scales with its
parent. Each unit encodes a *kind of relationship*, and choosing the
right unit is choosing the right relationship.

**Global and local styling** establishes a three-tier architecture:
universal styles that pervade the entire document (set with the `*`
selector and element selectors), layout primitives that compose spatial
relationships (set with class selectors), and utility classes that
provide targeted overrides. The insight is that CSS\'s cascade is not a
bug to be worked around but a *feature to be exploited* --- the most
general rules should be the most pervasive, and exceptions should be
layered on top with increasing specificity.

The **Modular scale** chapter introduces the mathematical foundation
that Utopia will later make fluid. A modular scale generates values
through repeated multiplication by a ratio --- the same ratios used in
musical intervals. A perfect fourth (4:3 = 1.333) produces steps of
1rem, 1.333rem, 1.777rem, 2.369rem. The relationships between these
values are *proportional*, which is what human perception requires:
Weber\'s Law tells us that we perceive differences as ratios, not as
absolute distances.

Finally, **Axioms** introduces the most philosophically rich concept in
the entire project: *designing by constraint rather than by artifact*.
An axiom is a rule that pervades the system without exception --- \"the
measure should never exceed 60ch,\" for instance. You don\'t manually
apply this rule to each element; you write it once, as a universal
style, and then *the browser enforces it everywhere*. The consequences
that emerge from this axiom may surprise you --- elements with larger
font sizes will be physically wider, because `1ch` scales with font
size --- but those consequences are *sound*. They are your CSS doing
exactly what you intended. Designing for the web, Pickering and Bell
argue, is designing *without seeing* --- writing programs that generate
visual artefacts, rather than crafting the artefacts directly.
:::

::: {.epigraph style="margin-top: var(--space-xs);"}
Instead of telling browsers what to do, we allow browsers to make their
own calculations, and draw their own conclusions, to best suit the user,
their screen, and device.

--- Every Layout, \"Boxes\"
:::

### Utopia: The Mathematics of Continuous Adaptation

::: prose
Where Every Layout asks *how should things be arranged?*, Utopia asks
*how large should things be?* And it answers with a single, elegant
idea: define your design at two viewport sizes, and let the browser
interpolate smoothly between them.

The origin story is instructive. James Gilyead, a designer at Clearleft,
had grown frustrated with breakpoint-based typography. Every responsive
design required specifying font sizes at three, four, or five
breakpoints --- a process that felt like \"equal parts guesswork and
compromise, where the better we want it to work, the more stuff we need
to design.\" The insight that changed his practice was deceptively
simple: instead of setting discrete sizes at discrete widths, define a
*modular type scale* for small screens (say, 1.2 at 360px) and a
different one for large screens (say, 1.25 at 1240px), then let each
step in the scale interpolate linearly between the two endpoints. The
result is a set of type sizes that is always proportionally
harmonious --- always \"in tune with itself\" --- at every possible
viewport width, not just the three or four you happened to design for.

The CSS mechanism is `clamp()`, which takes a minimum value, a preferred
value (expressed as a linear function of viewport width), and a maximum
value. But the power of Utopia is not in the CSS function itself --- it
is in the *system* that generates the `clamp()` declarations. Because
both the minimum and maximum scales are modular (generated by repeated
multiplication), the interpolated values at any viewport width are also
modular. Headings grow *faster* than body text as the viewport widens,
because they occupy higher steps in the scale, and higher steps have a
greater absolute difference between their minimum and maximum values.
This is not an accidental side effect; it is a mathematically necessary
consequence of interpolating between two geometric progressions.

Trys Mudford, Utopia\'s developer co-creator, extended the same
principle to **spacing**. The base spacing unit (\"S\") equals the base
type size (\"step 0\"). From this origin, multipliers generate a palette
of space tokens: 3XS, 2XS, XS, S, M, L, XL, 2XL, 3XL. Because they are
built on the same fluid base, every space token is inherently
responsive. But Utopia\'s masterstroke is **space
pairs** --- interpolations *between* two space tokens. Where an
individual token like \"M\" grows modestly from mobile to desktop, a
pair like \"S→L\" grows at a much steeper rate. This gives developers
precise control over how aggressively different spacings scale, using a
single custom property: `var(--space-s-l)` in one declaration instead of
separate values at multiple breakpoints.

Utopia\'s most recent extension, the **fluid layout grid**, completes
the system. The grid calculator generates column and gutter widths from
the same space palette, so that the layout grid is mathematically
entangled with the type and space system. Change the base font size, and
the grid adjusts. Change the modular scale ratio, and every proportion
in the system shifts in concert. Gilyead describes this as *declarative
design* --- \"we describe some rules and let the browser interpret those
rules according to its current situation.\"
:::

::: {.epigraph style="margin-top: var(--space-xs);"}
Instead of tightening our grip by loading up on breakpoints, we can let
go, embracing the ebb and flow with a more fluid and systematic approach
to our design foundations.

--- Utopia homepage
:::

### Where They Meet: The Interface Between Composition and Scale

::: prose
Every Layout and Utopia are solving different problems, and their
overlap is narrow --- but that narrow overlap is the joint at which the
entire system connects.

Every Layout\'s primitives *consume* spacing values. The Stack needs a
`space` property. The Cluster needs a `gap`. The Grid needs a gutter.
But Every Layout is deliberately silent about where those values come
from. Utopia *produces* spacing values --- fluid tokens that interpolate
continuously across viewports. The interface between the two systems is
clean: Utopia provides the tokens, Every Layout consumes them. One
decides *where things go*; the other decides *how big they are*.

The shared philosophical commitments run deeper than the technical
interface. Both projects advocate: letting the browser resolve layout
rather than prescribing it; using constraints and tolerances rather than
fixed values; choosing CSS units that encode meaningful relationships;
treating the web as a fluid medium rather than a collection of fixed
canvases. Both projects were created by practitioners who had grown
tired of fighting CSS and decided to *listen to it instead*.

This is the foundation upon which our layout philosophy is built.
:::

------------------------------------------------------------------------

[]{#part-ii}

::: section-label
Part II
:::

## Seven Precepts for Fluid Composition

These precepts synthesise Every Layout\'s compositional thinking,
Utopia\'s fluid mathematics, and the C&B engineering manifesto\'s
commitment to algebraic design into a single, coherent framework. They
are not rules to follow but principles to internalise --- once
understood, they generate correct decisions automatically.

:::: {.principle-card numeral="I"}
### Suggest, Never Prescribe

::: prose
The single most important principle. Every fixed value in your CSS is a
place where you have overridden the browser\'s judgment with your own.
Sometimes this is necessary --- a maximum measure of `60ch`, a minimum
touch-target of `44px` --- but the default posture should always be to
*suggest* rather than prescribe. Use `min-`, `max-`, and `clamp()`
instead of fixed values. Use `auto` instead of `100%`. Use `flex-basis`
instead of `width`. Each of these is an invitation for the browser to
make a contextually appropriate decision.

This is not laziness. It is recognition that the browser knows things
you do not --- the user\'s font size preferences, their zoom level,
their screen dimensions, whether they are using a split-screen view,
whether they have a notch or a toolbar. Your CSS should provide
*constraints within which good outcomes are inevitable*, not blueprints
that are correct in one context and broken in all others.

**The test:** if you removed every media query from your stylesheet,
would the layout still be usable? If not, your constraints are not yet
well enough chosen.
:::
::::

:::: {.principle-card numeral="II"}
### Compose, Never Inherit

::: prose
No layout should be designed as a monolithic component. Every layout is
a composition of simpler, reusable primitives --- Stacks for vertical
flow, Boxes for padding, Centers for width constraints, Clusters for
horizontal groups, Sidebars for main-plus-aside patterns, Switchers for
responsive column-to-stack transitions, Covers for vertically centered
content, Grids for repeating patterns, Frames for aspect-ratio-locked
media, Reels for horizontal scrolling sequences.

These primitives have no semantic meaning in isolation. A Stack is not a
\"card body\" or a \"page section\" --- it is just vertical space
between adjacent elements. Meaning emerges from *composition*: a card is
a Box containing a Stack; a page header is a Cover containing a Center
containing a Stack. By working with primitives, you guarantee that every
spatial relationship in your system comes from a small, tested
vocabulary. Inconsistency becomes structurally impossible.

**The test:** can you describe any layout in your system as a
composition of named primitives? If you need a word that is not a
primitive name, you have either found a new primitive or you are
thinking at the wrong level of abstraction.
:::
::::

:::: {.principle-card numeral="III"}
### Let Dimensions Flow From Content

::: prose
The web is a content-driven medium. The width of a paragraph should be
determined by its measure (in `ch` units). The height of a section
should be determined by the amount of content it contains. The gap
between elements should be determined by the typographic scale (in `rem`
or Utopia space tokens). The number of columns in a grid should be
determined by the minimum acceptable item width and the available space
(via `auto-fit` and `minmax()`).

When you prescribe a height, you are declaring that you know how much
content will be present. You almost certainly do not. When you prescribe
a width in pixels, you are declaring that you know the user\'s viewport
size. You do not. When you prescribe a column count, you are declaring
that you know the container\'s width. In a world of container queries
and intrinsic design, you should not need to.

Content determines dimensions. Context determines arrangement. The
designer\'s job is to set the *rules of derivation*, not the values
themselves.

**The test:** if the content doubles in length, does the layout still
work? If the viewport halves in width, does it still work? If both
happen simultaneously, does it still work?
:::
::::

:::: {.principle-card numeral="IV"}
### Scale by Ratio, Never by Addition

::: prose
Human perception is logarithmic. The jump from 16px to 20px (+4px) looks
like a bigger change than the jump from 40px to 44px (+4px), even though
both are the same absolute difference. This is Weber\'s Law, and it is
the reason every sizing system in this philosophy is *multiplicative*.

Type sizes are generated by a modular scale: each step is the previous
step multiplied by a ratio (perfect fourth at 1.333 for C&B projects).
Spacing tokens are multiples of the base type size. Fluid interpolation
between two modular scales preserves the proportional relationships at
every viewport width. This is the mathematical invariant that holds the
entire system together: *proportions are constant across contexts*.

The Utopia system makes this concrete. Because both the minimum-viewport
and maximum-viewport scales use modular ratios, the interpolated scale
at *any* intermediate viewport is also modular. Headings grow faster
than body text, larger gaps grow faster than smaller gaps, and the
visual hierarchy intensifies on larger screens --- not because anyone
specified that behaviour, but because it is a mathematical consequence
of interpolating between two geometric progressions.

**The test:** are all the size values in your system derivable from a
base value and a ratio? If any value is arbitrary (\"I just thought 24px
looked right here\"), it is a crack in the system.
:::
::::

:::: {.principle-card numeral="V"}
### Encode Axioms, Not Artefacts

::: prose
An axiom is a design rule that pervades the entire system without
exception. \"The measure shall not exceed 60ch.\" \"The minimum touch
target shall be 44px.\" \"Spacing between sibling elements shall use
Utopia space tokens.\" These are not guidelines to remember; they are
*CSS declarations* that are written once and enforced everywhere.

The crucial insight from Every Layout\'s Axioms chapter is that
designing by axiom means designing *without seeing*. You cannot predict
every visual consequence of a well-chosen axiom, and *you do not need
to*. The axiom generates correct outcomes in contexts you never
anticipated, because it encodes a *principle* rather than a *specific
arrangement*. This is what makes axiom-based design scale: it does not
require a designer to manually verify every combination of content and
context.

Axioms are best implemented using exception-based CSS: apply the rule to
everything (`*`), then remove it from the specific elements that are
logical exceptions (containers, wrappers, structural elements). This
inverted approach means you only need to *remember the exceptions*, not
enumerate every element that should follow the rule.

**The test:** can you state each design rule in a single sentence? Can
that sentence be translated into a single CSS declaration? If so, it is
an axiom. If not, it may be a convention masquerading as a principle.
:::
::::

:::: {.principle-card numeral="VI"}
### Unify Type, Space, and Grid

::: prose
In the Utopian system, type, space, and grid are not separate concerns.
They are three expressions of a single mathematical structure. The base
font size *is* the base space unit. The modular type scale *generates*
the spacing palette. The spacing palette *defines* the grid gutters.
Change the base, and everything changes in concert. Change the ratio,
and every proportion in the system shifts harmoniously.

This unification has practical consequences. You never need to choose a
spacing value by eye, because the palette is already determined by the
type system. You never need to wonder whether a gutter is \"consistent\"
with the rest of the design, because it is derived from the same
mathematical root. The system cannot become inconsistent unless you
explicitly break it by introducing values from outside the scale.

Massimo Vignelli called this \"syntactical consistency\" --- the quality
that emerges when every element in a composition follows the same
proportional logic. When your type scale is built on musical interval
ratios, your space system inherits that proportional harmony
automatically, and your grid inherits it from both. The entire visual
system resonates at the same frequency.

**The test:** is every numerical value in your CSS traceable back to the
base font size and the modular scale ratio? If any value exists in
isolation, it is a foreign body in the system.
:::
::::

:::: {.principle-card numeral="VII"}
### Design Systems, Not Pages

::: prose
The word \"system\" has two meanings, as Heydon Pickering observes: a
set of principles (a method), and a set of interconnecting parts (a
mechanism). An effective design system is both --- an exemplification of
how to proceed. Weak systems are one or the other: either documentation
without mechanism (\"do as I say\") or components without principles
(\"here\'s what was done\").

An algorithmic approach to layout design is the synthesis. Your
primitives are the mechanism. Your axioms are the principles. Your fluid
tokens are the mathematical glue. Together, they constitute a *program
for generating layouts* --- not a collection of pre-built pages, but a
generative system from which any page can be composed.

This is the deepest connection between our layout philosophy and the
Arts & Crafts movement that inspires C&B\'s broader identity. William
Morris did not design wallpapers; he designed *systems for generating
patterns*. His repeating motifs follow strict mathematical symmetry
groups (the 17 wallpaper groups, the 7 frieze groups), but the patterns
they produce are endlessly various. Similarly, our layout system does
not produce \"a C&B layout.\" It produces an *infinite family of
layouts*, all consistent, all fluid, all grounded in the same
mathematical structure, and every one of them different.

**The test:** could someone who has never seen any existing C&B page use
these principles to create a new layout that is recognisably part of the
family? If so, the system works. If they would need to copy an existing
page as a starting point, it is a template, not a system.
:::
::::

------------------------------------------------------------------------

[]{#part-iii}

::: section-label
Part III
:::

## The Architecture in Practice

How the seven precepts materialise as CSS. This is the technical
layer --- the specific primitives, tokens, and patterns that implement
the philosophy.

### The Fluid Foundation: Utopia Tokens

::: prose
Every C&B project begins by defining two states: a `@min` viewport
(typically 360px) and a `@max` viewport (typically 1440px). At `@min`,
the base font size is 16px and the type scale ratio is 1.2 (minor
third). At `@max`, the base is 20px and the ratio is 1.333 (perfect
fourth). The Utopia calculators generate the `clamp()` declarations for
each step.

These two endpoints --- and the modular ratios that govern them --- are
the *only design decisions* required to generate the entire type and
space system. Everything else is mathematics.
:::

::: code-block
[/\* The two design decisions that generate everything \*/]{.comment}
[/\* \@min: 360px viewport, 16px base, 1.200 ratio (minor third)
\*/]{.comment} [/\* \@max: 1440px viewport, 20px base, 1.333 ratio
(perfect fourth) \*/]{.comment} [:root]{.sel} { [/\* Type scale: each
step is a clamp() between the two scales \*/]{.comment}
[\--step-0]{.prop}: [clamp(1rem, 0.9015rem + 0.4924vi,
1.3337rem)]{.val}; [\--step-1]{.prop}: [clamp(1.2rem, 1.0534rem +
0.7331vi, 1.7783rem)]{.val}; [\--step-2]{.prop}: [clamp(1.44rem,
1.2266rem + 1.0672vi, 2.3706rem)]{.val}; [/\* \... and so on
\*/]{.comment} [/\* Space scale: derived from the same base
\*/]{.comment} [\--space-s]{.prop}: [var(\--step-0)]{.val}; [/\* Space
\"S\" = type \"step 0\" \*/]{.comment} [\--space-m]{.prop}:
[clamp(1.5rem, 1.3523rem + 0.7385vi, 2.0006rem)]{.val};
[\--space-l]{.prop}: [clamp(2rem, 1.8030rem + 0.9848vi,
2.6674rem)]{.val}; [/\* \... \*/]{.comment} [/\* Space pairs: steeper
interpolation for component padding \*/]{.comment}
[\--space-s-m]{.prop}: [clamp(1rem, 0.7523rem + 1.2385vi,
2.0006rem)]{.val}; [\--space-s-l]{.prop}: [clamp(1rem, 0.5038rem +
2.4808vi, 2.6674rem)]{.val}; }
:::

### The Compositional Layer: Every Layout Primitives

::: prose
With the fluid foundation in place, layouts are composed from a
vocabulary of spatial primitives. Each primitive has a single
responsibility and is implemented as a CSS class (following CUBE CSS
methodology). They consume Utopia tokens for their spacing values.
:::

::::::::::::::::::::::::::::::::: concept-grid
::::::: concept-card
::::: {.card-head style="background: var(--brand-950); color: var(--brand-100);"}
::: {.card-label style="color: var(--brand-400);"}
Vertical Flow
:::

::: card-title
The Stack
:::
:::::

::: {.card-body style="background: var(--brand-50);"}
**Responsibility:** vertical spacing between adjacent sibling elements.
The most frequently used primitive --- nearly every block of content
lives inside a Stack.

**Mechanism:** `display: flex; flex-direction: column;` with `gap` set
to a Utopia space token. The owl selector (`* + *`) variant is also
common.

**Key parameter:** `--space` (which Utopia token to use for the gap).
:::
:::::::

::::::: concept-card
::::: {.card-head style="background: var(--neutral-100); color: var(--neutral-950); border-bottom: 1px solid var(--neutral-200);"}
::: {.card-label style="color: var(--neutral-600);"}
Padding & Containment
:::

::: {.card-title style="font-variation-settings: 'SOFT' 30, 'WONK' 0, 'opsz' 48;"}
The Box
:::
:::::

::: {.card-body style="background: var(--neutral-50);"}
**Responsibility:** inset padding around content. A Box is any element
that needs uniform internal spacing.

**Mechanism:** `padding` set to a Utopia space token, with optional
`border` and `background`.

**Key parameter:** `--padding` (which Utopia token, typically a space
pair like `--space-s-m` for fluid component padding).
:::
:::::::

::::::: concept-card
::::: {.card-head style="background: var(--books-700); color: var(--books-100);"}
::: {.card-label style="color: var(--books-300);"}
Width Constraint
:::

::: card-title
The Center
:::
:::::

::: {.card-body style="background: var(--books-100);"}
**Responsibility:** constraining content to a maximum width and centring
it horizontally. The measure axiom is typically enforced here.

**Mechanism:** `max-inline-size` with `margin-inline: auto`. Uses
`box-sizing: content-box` so that padding does not reduce the content
area.

**Key parameter:** `--measure` (maximum width, typically `60ch` for
prose, wider for layout containers).
:::
:::::::

::::::: concept-card
::::: {.card-head style="background: var(--art-700); color: var(--art-100);"}
::: {.card-label style="color: var(--art-300);"}
Horizontal Grouping
:::

::: card-title
The Cluster
:::
:::::

::: {.card-body style="background: var(--art-100);"}
**Responsibility:** grouping items horizontally with wrapping. Tags,
button rows, navigation links, metadata.

**Mechanism:** `display: flex; flex-wrap: wrap; gap` set to a Utopia
space token. Items wrap naturally when space runs out.

**Key parameter:** `--space` and `justify-content` for alignment.
:::
:::::::

::::::: concept-card
::::: {.card-head style="background: var(--home-700); color: var(--home-100);"}
::: {.card-label style="color: var(--home-300);"}
Main + Aside
:::

::: card-title
The Sidebar
:::
:::::

::: {.card-body style="background: var(--home-100);"}
**Responsibility:** a two-element layout where one element has a
preferred width (the sidebar) and the other takes the remaining space.
Stacks vertically when the main element would become too narrow.

**Mechanism:** Flexbox with `flex-basis` on the sidebar and `flex-grow`
on the main content. The `clamp()`-based variant uses no media query at
all.

**Key parameter:** `--sidebar-width` and `--content-min` (minimum main
content percentage before stacking).
:::
:::::::

::::::: concept-card
::::: {.card-head style="background: var(--neutral-900); color: var(--neutral-100);"}
::: {.card-label style="color: var(--neutral-400);"}
Responsive Columns
:::

::: {.card-title style="font-family: 'IBM Plex Mono', monospace; font-weight: 500; font-size: var(--step-1);"}
The Switcher
:::
:::::

::: {.card-body style="background: var(--neutral-50);"}
**Responsibility:** switching between a multi-column and a single-column
layout based on available space. No breakpoints.

**Mechanism:** `flex-wrap: wrap` with a calculated `flex-basis` that
causes items to wrap at the threshold width. The threshold is defined by
the content, not the viewport.

**Key parameter:** `--threshold` (the container width at which items
stack).
:::
:::::::
:::::::::::::::::::::::::::::::::

:::: notes
#### The Remaining Primitives

::: prose
The **Cover** centres one child vertically within a minimum-height
container (hero sections, full-viewport panels). The **Grid** creates
repeating equal-width columns using `auto-fit` and `minmax()`, requiring
no column count declaration --- the number of columns is derived from
the minimum item width and the available space. The **Frame** locks
media to an aspect ratio. The **Reel** creates horizontal overflow
scrolling (carousels, image strips). The **Imposter** positions an
element outside normal flow (modals, tooltips). The **Icon** sizes an
inline SVG relative to its adjacent text. The **Container** provides the
outermost width constraint for page content.

Together, these thirteen primitives can compose any layout. They are the
*atoms* of the system. Everything else --- cards, headers, navigation,
forms, footers --- is a *molecule* composed from these atoms.
:::
::::

### The Unified Stack

::: prose
When the Utopia fluid foundation and the Every Layout compositional
primitives are combined, they form a layered architecture that covers
the full spectrum of layout concerns.
:::

:::::::::::::::::: layer-stack
::::: {.layer style="border-color: var(--brand-700); background: var(--brand-50);"}
::: {.layer-name style="color: var(--brand-800);"}
Typography
:::

::: layer-desc
Utopia fluid type scale. Breakpoint-free, modular, accessible. Governs
all font sizes from captions to display headings.
:::
:::::

::::: {.layer style="border-color: var(--brand-600); background: oklch(96% 0.01 55);"}
::: {.layer-name style="color: var(--brand-700);"}
Spacing
:::

::: layer-desc
Utopia fluid space scale + space pairs. Derived from the type scale.
Provides every margin, padding, and gap value in the system.
:::
:::::

::::: {.layer style="border-color: var(--books-500); background: var(--books-100);"}
::: {.layer-name style="color: var(--books-700);"}
Composition
:::

::: layer-desc
Every Layout primitives (Stack, Box, Center, Cluster, Sidebar, Switcher,
Cover, Grid, Frame, Reel, Imposter, Icon, Container). Consumes Utopia
tokens.
:::
:::::

::::: {.layer style="border-color: var(--art-500); background: var(--art-100);"}
::: {.layer-name style="color: var(--art-700);"}
Methodology
:::

::: layer-desc
CUBE CSS (Composition, Utility, Block, Exception). The organisational
principle that structures how primitives, utilities, and
component-specific styles interact.
:::
:::::

::::: {.layer style="border-color: var(--home-500); background: var(--home-100);"}
::: {.layer-name style="color: var(--home-700);"}
Enhancement
:::

::: layer-desc
Modern CSS features (container queries, subgrid, `:has()`, scroll-driven
animations, view transitions) layered progressively on top of the
intrinsic base.
:::
:::::
::::::::::::::::::

------------------------------------------------------------------------

[]{#part-iv}

::: section-label
Part IV
:::

## The Deeper Current: Layout as Craft

Why this philosophy belongs to a tradition older than the web itself.

::: prose
William Morris, the founder of the Arts & Crafts movement, did not rail
against machines because he hated technology. He railed against machines
that produced *thoughtless work* --- objects that were identical,
characterless, and disconnected from the people who made or used them.
His response was not to reject industrialisation but to insist that even
industrially produced objects should be made with care, intention, and
respect for the craft.

The web design monoculture is our version of Morris\'s factory.
Bootstrap, WordPress themes, and Tailwind UI templates produce layouts
that are functional but characterless --- the metal folding chairs of
the digital world. The CHI 2021 research confirms this: web design has
measurably homogenised by 30% over sixteen years. Every SaaS landing
page follows the same hero-features-testimonials-CTA-footer pattern.
Users have learned to filter it out.

Our response mirrors Morris\'s: not to reject the tools, but to insist
on *craft within the tools*. Every Layout and Utopia are not
anti-framework; they are the intellectual infrastructure for building
layouts that *deserve to exist*. A layout composed from tested
primitives, scaled by mathematical proportion, and fluid across every
viewport is not a template. It is a *considered response to specific
content in a specific context*.

The Arts & Crafts movement believed that beautiful, well-made objects
had moral force --- that they improved the lives of both their makers
and their users. We believe something similar about layout. A site whose
spatial relationships are harmonious, whose typography breathes at every
viewport width, whose composition responds to content rather than
imposing a grid upon it --- such a site is not merely functional. It is
*hospitable*. It invites people in. It respects their time and their
attention. And it demonstrates, by example, that the web can be better
than it currently is.

This document is released under CC0 because we believe this knowledge
should be common property --- not locked behind a paywall or a
proprietary framework. The point is not that everyone should make C&B
layouts. The point is that everyone should be able to make *their own*
layouts, with the same rigour, the same mathematical foundation, and the
same respect for the medium. Mission chairs, not metal folding chairs.
But not *only* Mission chairs --- whatever chair *you* need, built
beautifully.
:::

:::: epigraph
> Have nothing in your houses that you do not know to be useful, or
> believe to be beautiful.

::: attr
--- William Morris, 1880
:::
::::

------------------------------------------------------------------------

[]{#part-v}

::: section-label
Part V
:::

## Applying the Philosophy: A Worked Example

To demonstrate that these principles are practical and not merely
aspirational, here is how a C&B book detail page might be composed from
the system.

::: prose
Imagine a page displaying a single book: cover image, title, author,
description, publication details, and related titles. A template
approach would design this page once, pixel-perfect at 1440px, then add
breakpoints at 1024px, 768px, and 375px to adapt it. That is four
designs, four sets of spacing values, four column configurations, and a
maintenance burden that grows with every design change.

The intrinsic approach composes the page from primitives and lets the
mathematics handle responsiveness.
:::

::: code-block
[/\* The page structure --- no breakpoints, no media queries
\*/]{.comment} [/\* Page: Container → Stack \*/]{.comment} [.page]{.sel}
{ [/\* Container: max-width, centred \*/]{.comment}
[max-inline-size]{.prop}: [1200px]{.val}; [margin-inline]{.prop}:
[auto]{.val}; [padding-inline]{.prop}: [var(\--space-s-l)]{.val}; [/\*
Fluid side padding \*/]{.comment} } [/\* Hero: Sidebar (cover image +
title info) \*/]{.comment} [.book-hero]{.sel} { [/\* Sidebar primitive
\*/]{.comment} [display]{.prop}: [flex]{.val}; [flex-wrap]{.prop}:
[wrap]{.val}; [gap]{.prop}: [var(\--space-l-xl)]{.val}; [/\* Steep fluid
gap \*/]{.comment} } [.book-hero \> .cover]{.sel} { [/\* Frame:
aspect-ratio locked \*/]{.comment} [flex-basis]{.prop}: [clamp(200px,
30%, 400px)]{.val}; [flex-grow]{.prop}: [0]{.val}; } [.book-hero \>
.info]{.sel} { [/\* Stack: title, author, metadata \*/]{.comment}
[flex-basis]{.prop}: [0]{.val}; [flex-grow]{.prop}: [999]{.val};
[min-inline-size]{.prop}: [55%]{.val}; [/\* Stacks when too narrow
\*/]{.comment} } [/\* Description: Center (measure-constrained prose)
\*/]{.comment} [.book-description]{.sel} { [max-inline-size]{.prop}:
[60ch]{.val}; [/\* The measure axiom \*/]{.comment} } [/\* Related
titles: Grid (intrinsic column count) \*/]{.comment}
[.related-grid]{.sel} { [display]{.prop}: [grid]{.val};
[grid-template-columns]{.prop}: [repeat(auto-fit, minmax(min(100%,
180px), 1fr))]{.val}; [gap]{.prop}: [var(\--space-s-m)]{.val}; }
:::

::: prose
This stylesheet is approximately 30 lines of CSS. It handles every
viewport from 320px to 4K. The cover image and title info sit
side-by-side on wide viewports and stack on narrow ones, with no
breakpoint --- the `min-inline-size: 55%` on the info panel triggers the
stack naturally when the sidebar primitive runs out of room. The related
titles grid shows 1 column on phones, 2 on tablets, 3--4 on desktops,
and more on ultrawides, with no column count ever specified --- it is
derived from the minimum acceptable card width (180px) and the available
space. All spacing is fluid, all type is fluid, and the whole thing is a
composition of four named primitives: Container, Sidebar, Center, and
Grid.

This is what \"designing systems, not pages\" looks like in practice.
:::

------------------------------------------------------------------------

[]{#part-vi}

::: section-label
Part VI
:::

## Sources, Lineage, and Further Reading

This philosophy stands on the shoulders of extraordinary work. Here is
where to go deeper.

  Source                   What It Provides                                                                                                                                                                                                                                                                                                                                                                                                                              Where to Find It
  ------------------------ --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------
  Every Layout             The 13 compositional primitives, the Rudiments philosophy (Boxes, Composition, Units, Global/Local, Modular Scale, Axioms), and the EPUB/website.                                                                                                                                                                                                                                                                                             every-layout.dev --- paid, partially free
  Utopia                   Fluid type and space calculators, the philosophical blog posts, utopia-core (JS/TS), utopia-core-scss, postcss-utopia, Figma plugins.                                                                                                                                                                                                                                                                                                         utopia.fyi --- free tools, free blog
  CUBE CSS                 The organisational methodology (Composition, Utility, Block, Exception) that structures how primitives and utilities interact in a stylesheet.                                                                                                                                                                                                                                                                                                cube.fyi --- free
  Vignelli Canon           Systematic restraint, syntactical consistency, the discipline of working within a chosen set of proportions.                                                                                                                                                                                                                                                                                                                                  Free PDF from RIT
  Müller-Brockmann         Mathematical grid construction, compound grids, the Swiss typographic tradition that anticipated CSS Grid by 40 years.                                                                                                                                                                                                                                                                                                                        Grid Systems in Graphic Design
  Bringhurst               Typographic measure, proportional systems, the musical-interval ratios that Tim Brown brought into web typography.                                                                                                                                                                                                                                                                                                                            Elements of Typographic Style, v4.0
  Refactoring UI           Tactical, pattern-oriented design guidance for developers. Constrained spacing scales, the \"design in greyscale first\" heuristic.                                                                                                                                                                                                                                                                                                           refactoringui.com
  Dao of Web Design        John Allsopp\'s 2000 essay arguing that web designers must relinquish control to the medium --- the philosophical ancestor of everything in this document.                                                                                                                                                                                                                                                                                    alistapart.com/article/dao/
  Kaplan (ed.)             The definitive international survey of the Arts & Crafts movement. 260 objects from 13 countries --- Britain, Ireland, the US, France, Belgium, Germany, Austria, Hungary, Scandinavia, Finland --- covering furniture, ceramics, metalwork, textiles, and works on paper. Country-by-country essays on how each nation adapted the Ruskin/Morris ideals to its own social context. The philosophical backbone of Part IV of this document.   *The Arts and Crafts Movement in Europe and America: Design for the Modern World, 1880--1920* (Thames & Hudson, 2004). 327pp, 360 illustrations.
  V&A / Greenhalgh (ed.)   The V&A\'s landmark exhibition catalogue, extending the story beyond Europe and America to include Japan and the movement\'s later manifestations. Covers architecture, garden design, photography, painting, and sculpture alongside the decorative arts. Leading scholars explore regional, national, and international variants. The most comprehensive single volume on the global scope of the movement.                                 *International Arts and Crafts* (V&A Publishing, 2005). Lavishly illustrated.

:::: {.accent-block .books}
#### For the mathematically inclined

::: prose
The fluid interpolation in Utopia\'s `clamp()` declarations is a linear
function: `y = mx + b`, where `m` is the slope between the min and max
values and `b` is the y-intercept. The `vi` unit (viewport inline) is
used instead of `vw` because it respects writing direction and,
critically, does not prevent browser zoom from scaling
text --- satisfying WCAG SC 1.4.4. The modular scale itself is a
geometric progression: `size(n) = base × ratio^n`. Interpolating between
two geometric progressions produces a family of curves, each
asymptotically approaching the higher progression as the viewport
widens. This is why the visual hierarchy intensifies on larger screens
without any explicit instruction to do so.
:::
::::

:::: {.accent-block .art}
#### For the philosophically inclined

::: prose
Every Layout\'s concept of \"axioms\" derives from Euclid\'s
postulates --- simple, irreducible rules from which complex geometries
follow. The Utopian idea of \"declarative design\" maps to the same
distinction computer science draws between imperative and declarative
programming: specify *what* you want, not *how* to achieve it. The Arts
& Crafts connection runs through Morris\'s pattern mathematics: the 17
wallpaper symmetry groups are themselves a kind of generative design
system, producing infinite variation from finite rules. The throughline
is always the same: good design is not about making beautiful things; it
is about making systems that *produce* beautiful things.
:::
::::

:::: {.accent-block .home}
#### For the practically inclined

::: prose
Start at utopia.fyi and generate a type scale and space scale. Paste the
custom properties into your stylesheet. Read the Every Layout chapters
on Stack and Sidebar --- those two primitives alone cover the majority
of layout needs. Set `max-inline-size: 60ch` on all text elements. Use
`gap` with Utopia space tokens for all spacing. Write zero media
queries. You will be astonished at how far this gets you.
:::
::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::: footer
::::: footer-inner
::: brand
[Cowboys](../../) [&]{.amp} [Beans](../../)
:::

::: meta
Layout Philosophy · March 2026 · CC0 Public Domain
:::
:::::
::::::
