# Consumer UX Patterns

Reference models: Notion, Todoist, Things 3, Apple Notes, Spotify, Airbnb, Duolingo

These products serve a wide audience with varying technical fluency. The design challenge is making powerful functionality feel simple. Users visit regularly but not all day — every session must deliver value quickly.

## Contents

- [Core Philosophy](#core-philosophy)
- [Interaction Patterns](#interaction-patterns)
- [Layout Patterns](#layout-patterns)
- [Content and Tone](#content-and-tone)
- [Engagement Patterns](#engagement-patterns)
- [Performance for Consumer](#performance-for-consumer)

---

## Core Philosophy

**Obvious over clever.** If a user has to think about how to use it, the design has failed. Every action should be self-evident or one tap away from explanation.

**Delight earns loyalty.** Small moments of polish — a satisfying animation, a smart default, a well-timed suggestion — build an emotional connection that keeps users returning.

**Guide without constraining.** New users need onboarding. Power users need shortcuts. Design for both without forcing either path.

---

## Interaction Patterns

### Guided Onboarding

First-time experience is the product's first impression. Design it deliberately:

1. **Minimal signup**: Ask for the least possible. Name + email, or social login. Every additional field costs conversions.
2. **First-run value**: Get the user to their first "aha" moment in under 60 seconds. For a notes app: create their first note. For a task app: add their first task.
3. **Progressive education**: Do not dump a tutorial. Reveal features contextually, when the user is about to need them. Tooltips, coach marks, and inline hints.
4. **Templates and examples**: Pre-populated content that shows what is possible. Notion does this well — templates show the product's power without requiring the user to discover it.

### Touch-Friendly Interactions

Consumer apps must work beautifully on both desktop and mobile:

- **Tap targets**: 44x44px minimum. Space between adjacent targets matters too.
- **Swipe actions**: Swipe to delete, archive, or reveal secondary actions (mail apps, task apps).
- **Pull to refresh**: For list views and feeds. Show a satisfying animation.
- **Long press**: Reveal context menus on mobile (equivalent to right-click on desktop).
- **Gestures should have fallbacks**: Every swipe action should also be available via a button or menu.

### Smart Defaults

Reduce decisions. Pre-fill the most likely option:

- **Today as default date** for new tasks
- **Most recently used** project/folder selected
- **Smart suggestions** based on user behavior ("You usually tag this as...")
- **Remember last settings** — if they chose list view last time, show list view this time

### Micro-Animations

Purposeful motion that communicates:

- **State transitions**: Smooth morphing between views (not hard cuts)
- **Success feedback**: Checkmark animation on task completion (Things 3 nails this)
- **Drag and drop**: Item lifts with subtle shadow, landing zone highlights
- **Loading**: Branded, interesting loading states (Duolingo's character animations)
- **Empty → populated**: First item appearing should feel like a small celebration

Duration guide:
- Micro-interactions (button state, toggle): 100-200ms
- View transitions: 200-300ms
- Entrance animations: 300-500ms
- Never exceed 500ms for any animation — it starts to feel slow

---

## Layout Patterns

### Mobile-First with Desktop Enhancement

Design the mobile layout first. Then ask: "What can we add on desktop that would not work on mobile?"

```
Mobile (< 768px):
┌─────────────────┐
│ Top Bar          │ ← Title + key action
│─────────────────│
│                  │
│ Content Area     │ ← Full-width, scrollable
│                  │
│─────────────────│
│ ● ● ● ● ●      │ ← Bottom tab bar (3-5 items)
└─────────────────┘

Desktop (1024px+):
┌──────────┬──────────────────────────────┐
│ Sidebar  │ Content Area                 │
│          │                              │
│ Nav      │ (optional split into         │
│ items    │  list + detail on wide       │
│          │  screens)                    │
└──────────┴──────────────────────────────┘
```

### Card-Based Layouts

Cards work well for consumer apps because:
- They create visual hierarchy naturally
- They are inherently touch-friendly
- They work at any screen width (reflow in grid)
- They contain mixed content types gracefully

Card design rules:
- Consistent card sizes within a grid (variable height is OK, variable width is not)
- One primary action per card (tapping the card itself)
- Secondary actions hidden until hover/long-press
- Image/visual at top, text below, metadata last
- Rounded corners (8-12px feels friendly, 4px feels corporate)

### Bottom Sheets (Mobile)

The mobile equivalent of modals, but better:
- Slide up from bottom, dismissable by swipe-down
- Partial height by default (show most important content)
- Expandable to full height for more content
- Stack them (sheet over sheet) sparingly — 2 deep maximum

---

## Content and Tone

### Writing for Consumer UX

- **Short sentences.** No jargon. No technical language unless the domain demands it.
- **Active voice.** "Your task was completed" not "Task completion has been processed."
- **Personality, carefully.** A little warmth is good. Forced whimsy is bad. Todoist's "You're all done!" is right. Clippy was wrong.
- **Error messages that help.** Not "Error 422: Unprocessable Entity." Instead: "That name is already taken. Try a different one."

### Empty States as Onboarding

Consumer empty states should feel inviting, not empty:

- **Illustration**: A simple graphic that matches the product's personality
- **Headline**: What this space is for ("Your projects live here")
- **Subtext**: What the user should do ("Create your first project to get started")
- **Primary action**: A prominent button ("Create Project")
- **Optional**: Link to a template gallery or example

---

## Engagement Patterns

### Streaks and Progress

Use with care — these drive engagement but can become manipulative:

- **Progress bars**: Show completion toward a meaningful goal (not manufactured urgency)
- **Streaks**: Only if the habit genuinely benefits the user (language learning: yes; social media: questionable)
- **Celebrations**: Mark genuine milestones. First item created, week of activity, goal achieved.

### Notifications and Nudges

- **Ask permission contextually**: Do not ask to send notifications before the user understands why they would want them. Ask after they have created something worth being notified about.
- **Smart defaults**: Default to reasonable notification settings. Let users refine.
- **Batch notifications**: Group related notifications. Do not send 10 separate emails.
- **Respect attention**: Every notification is a cost to the user. Only send what is genuinely useful.

---

## Performance for Consumer

Consumer users are less tolerant of loading states than power users:

- **Perceived instant** is critical — use skeletons, optimistic updates, prefetching
- **Offline-first** when possible — let users read/create without connectivity, sync when reconnected
- **App-like transitions** — shared element transitions, crossfades between views, not hard reloads
- **Lazy load below the fold** — only load what is visible, fetch more as the user scrolls
