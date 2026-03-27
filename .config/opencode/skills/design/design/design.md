:::: hero
[![Cowboys & Beans --- Back to
home](../../images/cowboys-and-beans_monogram-1.1-on-dark.png){.hero-monogram}](../../)

A Manifesto for Visual Systems

# Design as Engineering

[On the convergence of mathematical proportion, perceptual science, and
software architecture in the construction of visual
identity.]{.subtitle}

::: tag-row
[Manifesto]{.tag} [Design Systems]{.tag} [Perceptual Science]{.tag}
[March 2026]{.tag}
:::
::::

:::::::::::::::::::::::::::::::::::::: container
::: section-label
Preamble
:::

::: epigraph
The details are not the details. They make the design.

--- Charles Eames
:::

::: {.preamble style="margin-top: var(--space-m);"}
This document is a statement of principles. It describes an approach to
visual design that treats aesthetic decisions not as matters of taste
but as engineering problems --- constrained, measurable, and composable.
It argues that the best design systems are not collections of components
but algebraic structures: closed under composition, governed by
invariants, and provably consistent.

These principles emerged from the practical work of building a unified
identity for a small publishing and arts collective. But they are not
specific to that project. They are an articulation of what happens when
you take seriously the idea that visual design and software engineering
are not adjacent disciplines but convergent ones --- that the same
mathematical structures underpin both, and that recognising this
convergence produces better work in each.

This is not a style guide. Style guides describe what to do. This
describes why.
:::

::: dot-divider
• • •
:::

::: section-label
Section I
:::

## The Convergence Thesis

::: prose
The three most influential design systems of the current era ---
Google\'s Material Design, IBM\'s Carbon, and Shopify\'s Polaris ---
were built independently, by different teams, for different products,
serving different users. And yet they converged on the same fundamental
architecture.

All three define a layered token system: primitive values at the base,
semantic aliases in the middle, component-specific bindings at the top.
All three use multiplicative type scales rather than arbitrary font
sizes. All three enforce spacing systems built on a base unit with
constrained multipliers. All three separate colour into tonal scales
with systematic lightness progressions.

This convergence is not coincidence. It is the signature of underlying
mathematical structure asserting itself through independent discovery
--- the same way calculus was discovered independently by Newton and
Leibniz, because the problems they were solving demanded it. The
problems of visual consistency at scale demand token architecture. The
problems of typographic hierarchy demand geometric progression. The
problems of colour harmony demand perceptually uniform spaces.

**When multiple teams, working independently, arrive at the same
solution, the solution is no longer a design choice. It is a design
fact.**
:::

::: dot-divider
• • •
:::

::: section-label
Section II
:::

## Seven Principles

::::: {.principle-card numeral="I"}
### Multiply, Never Add

::: {.epigraph style="margin-top: var(--space-xs);"}
Just-noticeable differences are proportional to the stimulus intensity.

--- Ernst Heinrich Weber, 1834
:::

::: prose
Human perception is logarithmic. Weber and Fechner established this in
the nineteenth century: the smallest detectable change in a stimulus is
a constant proportion of the stimulus itself. This is why we perceive
the difference between 12px and 16px text as roughly the same \"jump\"
as between 24px and 32px --- both are a ratio of 1.333, even though the
absolute differences are 4px and 8px.

This means every quantitative scale in a design system --- type sizes,
spacing values, colour lightness steps --- must be geometric
(multiplicative), not arithmetic (additive). An arithmetic scale with a
constant increment of 4px would produce steps that feel compressed at
large sizes and spread apart at small ones. A geometric scale with a
constant ratio produces steps that feel perceptually equal.

**The practical implication:** choose a ratio and commit to it. The
perfect fourth (4:3 = 1.333) is not the only valid choice, but it is a
good one --- assertive enough for clear hierarchy, gentle enough for
nuanced intermediate levels. The ratio is the grammar of your visual
language. Every departure from it is a grammatical error that the eye
detects even when the mind cannot name it.
:::
:::::

:::: {.principle-card numeral="II"}
### Perception Is the Only Coordinate System That Matters

::: prose
For most of typographic history, colour was specified in spaces that
describe how displays produce light (sRGB) rather than how humans
perceive it. This is like measuring distance in engine revolutions
instead of kilometres. It tells you something about the machine and
nothing about the journey.

OKLCH is, at present, the best available perceptually uniform colour
space for design work. Its lightness axis is calibrated so that equal
numerical steps produce equal perceived brightness --- across all hues.
This means you can hold chroma and hue constant, step lightness from 15%
to 95% in equal increments, and produce a tonal scale where every
adjacent pair feels like the same \"jump.\" You cannot do this in HSL.
You cannot do this in sRGB.

The same principle applies beyond colour. Fluid type scales that
interpolate between viewport widths should use the `vi` unit (viewport
inline), which respects writing direction. Spacing should be defined in
`rem`, which scales with the user\'s font size preference. Every unit of
measurement should describe the experience, not the mechanism.
:::
::::

:::: {.principle-card numeral="III"}
### Name the Role, Not the Value

::: prose
A colour called `brand-700` describes what it is. A colour called
`interactive-primary` describes what it does. Both are necessary, but
they serve different functions in the system, and conflating them is the
single most common architectural error in design token systems.

The three-tier token architecture --- primitive, semantic, component ---
is not a convention. It is the design equivalent of the separation of
concerns that every competent software architecture enforces. Primitives
are your type definitions. Semantic tokens are your interfaces.
Component tokens are your implementations. Changing a primitive\'s value
propagates automatically. Renaming a semantic token requires deliberate
refactoring. This is not a limitation; it is a feature. It means the
system is legible in the same way that well-structured code is legible:
you can understand any part of it without understanding all of it.

**The practical implication:** never write
`background: var(--brand-700)` in a component. Write
`background: var(--interactive-primary)`. When the brand evolves, the
interactive colour changes in one place. When a new site joins the
system, it maps its own primitives to the same semantic tokens and
inherits every component for free.
:::
::::

::::: {.principle-card numeral="IV"}
### Constraint Liberates; Freedom Paralyses

::: {.epigraph style="margin-top: var(--space-xs);"}
Real freedom is not the absence of structure but the presence of the
right structure.

--- After Barry Schwartz
:::

::: prose
A spacing system with nine named values (3xs through 3xl) is more useful
than one that permits arbitrary pixel values, for the same reason that a
pentatonic scale is more useful to an improvising musician than the
instruction \"play any frequency you like.\" Constraint creates
coherence. It makes the right choice easy and the wrong choice
effortful.

This applies at every level of the system. A type stack of three
families (display, body, mono) is a constraint. A palette with one
accent hue per site is a constraint. A modular scale with a single ratio
is a constraint. Each one eliminates a category of bad decisions while
preserving the full space of good ones.

The test of a well-constrained system is not whether it prevents ugly
outcomes --- any sufficiently restrictive system does that --- but
whether it still permits beautiful ones. The best constraints are like
the rules of a sonnet: they do not limit expression, they concentrate
it.
:::
:::::

:::: {.principle-card numeral="V"}
### Unity Is Not Uniformity

::: prose
Three sites that look identical are not a design system. They are a
template applied three times. A design system is the set of shared
principles and primitives that allows different expressions to be
recognisably part of the same family --- the way siblings share bone
structure without sharing faces.

The mechanism is the separation of what is shared from what is
site-specific. Shared: the colour primitives, the type scale ratio, the
spacing rhythm, the semantic token names. Site-specific: the accent hue,
the display font\'s axis settings, the surface temperature, the amount
of whitespace, the attitude.

A variable font with multiple axes is the typographic embodiment of this
principle. The same typeface --- the same letterforms, the same
underlying design --- can be sharp and editorial in one context, soft
and airy in another, and bold and playful in a third. The unity is in
the skeleton. The variety is in the posture. This is what allows
\"different departments, each an expert in their own field\" to produce
work that belongs together without being interchangeable.
:::
::::

:::: {.principle-card numeral="VI"}
### Proximity Carries Meaning; Uniformity Erases It

::: prose
Gestalt psychology established, a century ago, that the human visual
system groups elements by proximity before it considers any other cue
--- colour, shape, size, label. Two elements 8px apart feel related. The
same two elements 32px apart feel independent. This is not a design
preference. It is a perceptual fact, as reliable as gravity.

A design that uses the same spacing value everywhere --- 16px padding,
16px between items, 16px between sections --- is a design that has
destroyed all spatial information. The eye cannot determine what belongs
together because everything is equidistant. This is the visual
equivalent of writing without punctuation: technically complete,
structurally illegible.

**The rule is simple and absolute:** intra-group spacing must be tighter
than inter-group spacing. Title to author: 8px. Card padding: 16px.
Between cards: 32px. Three different scales communicate three different
structural relationships. The numbers are secondary. The principle ---
that spacing is not decoration but syntax --- is primary.
:::
::::

::::: {.principle-card numeral="VII"}
### Design the Invariants, Not the Instances

::: {.epigraph style="margin-top: var(--space-xs);"}
Show me your flowchart and conceal your tables, and I shall continue to
be mystified. Show me your tables, and I won\'t usually need your
flowchart.

--- Fred Brooks (paraphrased)
:::

::: prose
A design system is not a collection of designed screens. It is a set of
invariants --- relationships that remain true across all screens, all
viewports, all contexts. The ratio between heading sizes is an
invariant. The mapping from semantic token to primitive token is an
invariant. The rule that body text never exceeds 60ch is an invariant.

Screens are instances. They are generated by applying the invariants to
specific content in specific contexts. If you have defined your
invariants well, most screens design themselves --- the constraints
leave only a narrow corridor of valid compositions, and the corridor
leads somewhere good.

This is why a token file and a type scale and a spacing system are not
preliminary work that precedes design. **They are the design.**
Everything else is layout.
:::
:::::

::: dot-divider
• • •
:::

::: section-label
Section III
:::

## The Deeper Structure

::: prose
Underneath these seven principles lies a single insight that unifies all
of them: the visual properties that humans perceive as \"harmonious\" or
\"consistent\" or \"professional\" are, without exception, properties
that exhibit mathematical regularity. Geometric type scales.
Perceptually uniform colour spaces. Proportional spacing. Systematic
tonal progressions. Consistent axis ratios.

This is not a coincidence and it is not a cultural construction. It is a
consequence of how neural systems process sensory information. Pattern
recognition is metabolically expensive; regular patterns are cheap to
process and therefore experienced as pleasant. Irregular patterns demand
more processing and are experienced as effortful --- which the mind
interprets as \"something is wrong,\" even when it cannot identify what.

This is why \"it just looks off\" is a reliable design critique even
from non-designers. They are detecting a violation of mathematical
regularity that they cannot name. The purpose of a principled design
system is to make that violation structurally impossible --- to ensure
that every composition the system permits is one that the visual cortex
will process as coherent.

This is also why the convergence of Material Design, Carbon, and Polaris
is significant. These systems were built by teams with different
aesthetic preferences, different brand requirements, different technical
constraints. What they share is not style but structure. The structure
is dictated by human perception, and human perception does not vary by
brand.
:::

::: dot-divider
• • •
:::

::: section-label
Section IV
:::

## On Tools and Technology

::: prose
**Variable fonts** are not an incremental improvement over static font
files. They are a phase transition --- the moment when a typeface stops
being a fixed artifact and becomes a continuous design space. A
four-axis variable font like Fraunces does not contain styles; it
contains the mathematical surface from which any style can be derived.
This is the difference between a table of values and a function. The
function is infinitely more powerful because it can produce values that
were never explicitly designed but are nonetheless correct.

**OKLCH** is not merely a \"better colour picker.\" It is the first
widely-supported colour space in CSS that is aligned with human
perception rather than display hardware. Designing in OKLCH is the
typographic equivalent of switching from imperial to metric: the numbers
finally mean what you think they mean.

**Fluid type and spacing via CSS `clamp()`** is not a responsive design
technique. It is the elimination of responsive design as a separate
concern. When your type scale interpolates continuously between two
viewport widths, there are no breakpoints to manage, no discrete jumps
to smooth over, no \"mobile version\" and \"desktop version.\" There is
one design that is correct at every size, because the mathematical
relationships that define it hold across the entire range.

**The design token specification (DTCG)** is not a file format. It is a
contract --- an agreement that the same semantic name means the same
thing in every context, on every platform, in every tool. A token file
is to a design system what a type signature is to a function: a
guarantee about the shape of the input and the shape of the output,
independent of implementation.
:::

::: dot-divider
• • •
:::

::: section-label
Section V
:::

## Coda

::: prose
There is a persistent mythology that design and engineering are opposed
--- that rigour constrains creativity, that systems suppress expression,
that mathematics is the enemy of beauty. The evidence says otherwise.

The most enduring visual works in human history --- the Parthenon, the
illuminated manuscripts, the Renaissance canvases, the Swiss typographic
posters, the Braun products --- are without exception works of profound
mathematical regularity. Their creators did not experience the golden
ratio and the modular grid and the baseline rhythm as constraints on
their art. They experienced them as the medium through which their art
became possible.

A well-built design system is not a cage. It is an instrument. Like any
good instrument, it has constraints --- a piano has 88 keys, not
infinite frequencies --- and those constraints are precisely what allow
a skilled practitioner to produce music instead of noise.

**Build the instrument well. Tune it to human perception. Then play.**
:::

::: dot-divider
• • •
:::
::::::::::::::::::::::::::::::::::::::

:::::: footer
::::: footer-inner
::: brand
[Cowboys](../../) [&]{.amp} [Beans](../../)
:::

::: meta
Design Manifesto · March 2026 · CC0 Public Domain
:::
:::::
::::::
