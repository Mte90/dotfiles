# Game UI Design

## Patterns


---
  #### **Name**
Diegetic UI Integration
  #### **Description**
Embed UI elements within the game world for maximum immersion
  #### **When**
Designing UI for immersive experiences where breaking the fourth wall hurts engagement
  #### **Example**
    Diegetic UI examples:
    - Health shown on character's back display (Dead Space)
    - Ammo counter on the weapon itself (Halo)
    - Map as physical object character holds (Far Cry 2)
    - Quest markers in-world rather than minimap (Breath of the Wild)
    - Radio/phone for objectives (GTA series)
    
    Implementation considerations:
    - Must remain readable during gameplay
    - Needs fallback for accessibility
    - Camera angle affects visibility
    - Performance cost of 3D UI elements
    
    When NOT to use:
    - Competitive games where speed matters
    - When information is frequently referenced
    - Complex stat-heavy games (RPGs)
    

---
  #### **Name**
Contextual HUD Visibility
  #### **Description**
Show UI elements only when relevant, hiding them during exploration/cutscenes
  #### **When**
Balancing information display with visual immersion
  #### **Example**
    Visibility states:
    1. Hidden: During exploration, cutscenes, photo mode
    2. Peek: Brief appearance on relevant action
    3. Persistent: Always visible (health in combat)
    4. Expanded: Full detail on demand (hold button)
    
    Trigger examples:
    - Health bar: Hidden at full, appears when damaged, fades after 5s
    - Ammo: Appears on weapon switch/reload/low ammo
    - Minimap: Hidden in safe areas, visible in dangerous zones
    - Objectives: Toggle with button, auto-hide during combat
    
    Fade timing:
    - Instant appearance (0ms) for critical info
    - Quick fade-in (150ms) for standard elements
    - Slow fade-out (500ms) to avoid jarring disappearance
    - Hold threshold (2s) before auto-hide
    

---
  #### **Name**
Safe Zone Implementation
  #### **Description**
Keep critical UI within TV/monitor safe zones to prevent cutoff
  #### **When**
Designing for console games or any game played on varied displays
  #### **Example**
    Safe zone standards:
    - Action safe: 93% of screen (outer 3.5% may be cut)
    - Title safe: 90% of screen (outer 5% unreliable)
    - Modern TVs: Usually display full image, but assume they don't
    
    Implementation:
    ┌─────────────────────────────────────┐
    │  ┌─────────────────────────────┐    │
    │  │  Critical UI (health, ammo) │    │ <- Title safe (90%)
    │  │  ┌─────────────────────┐    │    │
    │  │  │   Game content      │    │    │ <- Action safe (93%)
    │  │  └─────────────────────┘    │    │
    │  └─────────────────────────────┘    │
    └─────────────────────────────────────┘
    
    Allow players to adjust:
    - Safe zone slider in options
    - Test pattern for calibration
    - Remember setting per-display
    

---
  #### **Name**
Controller-First Navigation
  #### **Description**
Design menu navigation for gamepad before mouse, ensuring full functionality without pointer
  #### **When**
Any game supporting controllers or console release
  #### **Example**
    Controller navigation principles:
    1. D-pad navigation between elements
    2. Clear visual focus indicator (not just color change)
    3. Logical flow (left-to-right, top-to-bottom)
    4. Wrap navigation (end of row goes to next row start)
    5. Remember last position when returning to menu
    
    Focus indicator requirements:
    - High contrast border/glow (not just highlight)
    - Animation to draw attention
    - Works on all backgrounds
    - Visible for colorblind users
    
    Button mapping:
    - A/X: Confirm, select
    - B/Circle: Back, cancel
    - Bumpers/Triggers: Tab switching, category navigation
    - Start: Pause menu
    - Select/Back: Secondary menu, map
    
    Example navigation grid:
    [Inv] [Map] [Quest] [Options]
      ↓     ↓      ↓        ↓
    Tab navigation with LB/RB
    

---
  #### **Name**
Readability Under Motion
  #### **Description**
Ensure UI remains readable during intense gameplay with camera shake, effects, and rapid movement
  #### **When**
Designing HUD for action games, FPS, racing, or any high-motion gameplay
  #### **Example**
    Readability techniques:
    
    1. Contrasting backgrounds:
       ┌──────────────────────┐
       │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  <- Dark container
       │ ▓  HEALTH: 85/100  ▓ │  <- Light text
       │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
       └──────────────────────┘
    
    2. Text outlines/shadows:
       - 2px outline in contrasting color
       - Drop shadow for depth
       - Both for maximum readability
    
    3. Stable anchor points:
       - HUD elements fixed to screen edges
       - Minimal animation during gameplay
       - Static during camera shake
    
    4. Size thresholds:
       - Minimum 14px at 1080p for body text
       - Minimum 24px for critical info (health)
       - Scale with resolution, not viewport
    
    5. Color coding with backup:
       - Red for danger + icon + label
       - Never color alone (colorblind users)
    

---
  #### **Name**
Progressive Information Disclosure
  #### **Description**
Layer information from critical to detailed, revealing more on demand
  #### **When**
Designing complex systems like inventory, skill trees, or stat screens
  #### **Example**
    Information layers:
    
    Layer 1 - Glance (always visible):
    [Sword Icon] "Iron Sword"  ATK: 25
    
    Layer 2 - Hover/Focus (on selection):
    [Sword Icon] "Iron Sword"
    ATK: 25  |  DEX: +5  |  Weight: 3.5
    "A reliable blade for any warrior"
    
    Layer 3 - Inspect (on button press):
    Full stat comparison, lore, upgrade paths,
    acquisition history, durability, enchantments
    
    Implementation:
    - Tooltips appear after 300ms hover
    - "More Info" button for layer 3
    - Controller: A for layer 2, hold A for layer 3
    - Touch: Tap for layer 2, long press for layer 3
    

---
  #### **Name**
Damage Number Design
  #### **Description**
Display combat feedback numbers that communicate without cluttering
  #### **When**
Designing feedback for RPGs, action games, or any combat system with numeric damage
  #### **Example**
    Damage number best practices:
    
    1. Differentiation by type:
       - Normal damage: White, standard size
       - Critical hit: Yellow, 150% size, shake
       - Elemental: Colored (fire=orange, ice=blue)
       - Healing: Green, upward float
       - Blocked/Resisted: Gray, smaller
    
    2. Animation patterns:
       - Float upward and fade (classic)
       - Pop and shrink (impactful)
       - Accumulate then burst (combo)
       - Slot machine roll (anticipation)
    
    3. Clustering for readability:
       - Combine rapid hits into single number
       - Show "12 + 12 + 12" then "36 TOTAL"
       - Stack vertically, most recent on top
       - Maximum 5-6 visible at once
    
    4. Performance consideration:
       - Object pool damage numbers
       - Limit particle effects per number
       - Reduce frequency in large battles
    

---
  #### **Name**
Radial Menu Design
  #### **Description**
Create efficient radial/wheel menus for quick selection with controller or mouse
  #### **When**
Quick-access menus for weapons, abilities, emotes, or commands
  #### **Example**
    Radial menu principles:
    
    1. Segment count:
       - 4 segments: Cardinal directions only
       - 8 segments: Optimal for controller
       - 12 segments: Maximum comfortable
       - Beyond 12: Use nested radials
    
    2. Layout:
       ┌─────────────────┐
       │        N        │
       │    ┌─────┐      │
       │  W │     │ E    │  8-way radial
       │    └─────┘      │  Stick direction = selection
       │        S        │
       └─────────────────┘
    
    3. Interaction modes:
       - Hold to open, release to select
       - Toggle open, confirm to select
       - Flick gesture (advanced)
    
    4. Visual feedback:
       - Selected segment highlights
       - Icon enlarges on hover
       - Preview of selection before confirm
       - Recent/favorite in easy positions (E, N)
    
    5. Time slow:
       - Optional slow-mo while menu open
       - Maintains gameplay flow
       - Not for multiplayer/competitive
    

---
  #### **Name**
Cooldown Indicator Design
  #### **Description**
Communicate ability availability and timing clearly
  #### **When**
Designing ability bars, skill cooldowns, or any time-based availability
  #### **Example**
    Cooldown visualization methods:
    
    1. Clock sweep:
       ┌───┐     ┌───┐     ┌───┐
       │░▓▓│  →  │░░▓│  →  │░░░│
       │▓▓▓│     │░▓▓│     │░░░│
       └───┘     └───┘     └───┘
       75% CD    50% CD    Ready!
    
    2. Fill bar:
       [████░░░░░░] 40% ready
    
    3. Countdown number:
       Ability icon with "3.2" overlay
    
    4. Combined (best):
       - Clock sweep for visual
       - Number overlay for precision
       - Flash/glow when ready
       - Audio cue at ready
    
    States to design:
    - On cooldown (dimmed, clock sweep)
    - Almost ready (subtle pulse)
    - Ready (full brightness, optional glow)
    - Active/in-use (highlighted border)
    - Disabled (grayed out, X overlay)
    

---
  #### **Name**
Minimap Best Practices
  #### **Description**
Design minimaps that aid navigation without becoming a crutch
  #### **When**
Open world games, exploration games, or any game needing spatial awareness
  #### **Example**
    Minimap design decisions:
    
    1. Shape and placement:
       - Circle: Classic, works for most games
       - Rectangle: Better for grid-based worlds
       - Compass only: Maximum immersion (Skyrim)
       - Top-right: Standard, out of primary focus
       - Bottom-left: Less common, evaluate per game
    
    2. Information hierarchy:
       - Player (always centered, clear indicator)
       - Objectives (distinct, pulsing)
       - Enemies (red, only when detected)
       - Allies (blue/green)
       - Points of interest (icons by type)
       - Terrain (subtle, shouldn't dominate)
    
    3. Rotation modes:
       - North-up: Easier map correlation
       - Player-up: Easier direction finding
       - Let player choose in settings
    
    4. Zoom and scale:
       - Default zoom fits immediate area
       - Pinch/scroll to zoom
       - Auto-zoom when fast travel/vehicle
    
    5. Fog of war:
       - Unexplored areas dimmed
       - Revealed on visit
       - Optional: Re-fog over time
    

---
  #### **Name**
Button Prompt Adaptation
  #### **Description**
Dynamically show correct input prompts based on active controller type
  #### **When**
Any game supporting multiple input methods (keyboard, controller, touch)
  #### **Example**
    Input detection and display:
    
    1. Detect input method:
       - Last input used determines prompts
       - Instant switch on new input type
       - Grace period to prevent flashing
    
    2. Platform-specific icons:
       Xbox:     [A] [B] [X] [Y] [LB] [RB]
       PS:       [X] [O] [□] [△] [L1] [R1]
       Switch:   [A] [B] [X] [Y] [L] [R]
       Keyboard: [Space] [E] [Tab] [Shift]
       Touch:    [Tap] [Hold] [Swipe]
    
    3. Rebinding support:
       - Show current binding, not default
       - "[Primary Action]" not "[A]" internally
       - Update prompts on rebind
    
    4. Prompt placement:
       - Context prompts near interaction point
       - Tutorial prompts center-screen
       - HUD prompts in consistent location
    
    5. Verb-first design:
       "Press [A] to Open" is clearer than
       "[A] Open" for new players
    

---
  #### **Name**
Notification Queue Management
  #### **Description**
Handle multiple notifications without overwhelming the player
  #### **When**
Games with achievements, loot drops, quest updates, or any frequent notifications
  #### **Example**
    Notification system design:
    
    1. Priority levels:
       - Critical: Immediate, interrupts (low health warning)
       - High: Next in queue (quest complete)
       - Normal: Standard queue (achievement)
       - Low: Batched (material collected x5)
    
    2. Queue behavior:
       - Maximum 2-3 visible at once
       - Newer pushes older up/out
       - Critical bypasses queue
       - Player can dismiss early
    
    3. Display timing:
       - Appear: 200ms slide in
       - Display: 3-5 seconds based on content
       - Dismiss: 300ms fade/slide out
       - Queue gap: 500ms between notifications
    
    4. Consolidation:
       "Gold +50" + "Gold +30" = "Gold +80"
       Only consolidate same types
       Show "x5" for repeated items
    
    5. History access:
       - Notification log in menu
       - Recent notification recall button
       - Never lose important info
    

## Anti-Patterns


---
  #### **Name**
Cluttered HUD
  #### **Description**
Showing all possible information at all times regardless of relevance
  #### **Why**
    Overwhelms players, reduces immersion, buries critical info in noise.
    Screen real estate is borrowed from the game world - every element has a cost.
    
  #### **Instead**
    Contextual visibility:
    - Health bar: Only when damaged
    - Ammo: Only when weapon out
    - Minimap: Only in dangerous areas
    - Quest tracker: Toggle on/off
    
    Ask for every element: "Does the player need this RIGHT NOW?"
    If not now, hide it or make it accessible on demand.
    

---
  #### **Name**
UI Blocking Action
  #### **Description**
Menus or UI elements that obscure important gameplay areas
  #### **Why**
    Players die to enemies they can't see. Inventory screens that don't pause
    leave players vulnerable. Critical info hidden behind tooltips during combat.
    
  #### **Instead**
    Safe positioning:
    - Pause game for full-screen menus (or provide option)
    - Position tooltips away from crosshair
    - Quick menus in corners, not center
    - Transparent backgrounds for non-critical UI
    - "Combat mode" that hides non-essential UI
    

---
  #### **Name**
Mouse-Only Navigation
  #### **Description**
Menus that require mouse/touch and cannot be navigated with controller
  #### **Why**
    Excludes controller players entirely. Many PC players prefer controller.
    Console ports become impossible. Accessibility failure.
    
  #### **Instead**
    Controller-first design:
    - Design grid navigation before pointer
    - Every element must be focusable
    - Every action must have button equivalent
    - Test complete flows with controller only
    

---
  #### **Name**
Tiny Touch Targets
  #### **Description**
Buttons and interactive elements too small for reliable touch or controller selection
  #### **Why**
    Misclicks frustrate players. Small targets are accessibility failures.
    Mobile players have varying finger sizes. Controller selection boxes need padding.
    
  #### **Instead**
    Size guidelines:
    - Touch: 44x44pt minimum (Apple), 48x48dp (Google)
    - Controller: Selection box larger than visible element
    - Spacing between targets prevents misselection
    - Important actions need larger targets
    

---
  #### **Name**
Color-Only Information
  #### **Description**
Using color as the sole differentiator for important game information
  #### **Why**
    8% of men have color vision deficiency. Game becomes unplayable for them.
    Red/green distinction fails most commonly - exactly what games use for enemy/ally.
    
  #### **Instead**
    Redundant encoding:
    - Color + shape: Red triangle danger, green circle safe
    - Color + icon: Elemental damage with element icon
    - Color + label: "CRITICAL" text with red styling
    - Colorblind modes: Deuteranopia, protanopia, tritanopia options
    

---
  #### **Name**
Resolution-Dependent Sizing
  #### **Description**
UI elements sized in absolute pixels that don't scale with resolution
  #### **Why**
    Playable on 1080p monitor, microscopic on 4K TV, massive on 720p handheld.
    Modern games run on wildly different display sizes and viewing distances.
    
  #### **Instead**
    Responsive scaling:
    - Base design at 1080p
    - Scale all elements proportionally
    - Provide UI scale slider (50% - 200%)
    - Test at 720p, 1080p, 1440p, 4K
    - Consider viewing distance (TV vs monitor vs handheld)
    

---
  #### **Name**
Inaccessible During Gameplay
  #### **Description**
Critical information only available by pausing or opening menus
  #### **Why**
    Breaking flow to check status is frustrating. Players shouldn't need to
    pause to know their health, ammo, or objective. Pause-menu-heavy design is a smell.
    
  #### **Instead**
    Glanceable critical info:
    - Health/shields always accessible (even if minimal)
    - Current objective one button away
    - Ammo visible when weapon drawn
    - Status effects visible on character or HUD
    

---
  #### **Name**
Inconsistent Button Mapping
  #### **Description**
Same button does different things in different menus without clear indication
  #### **Why**
    "B" means back in one menu, cancel in another, drop item in a third.
    Players learn muscle memory - inconsistency causes errors and frustration.
    
  #### **Instead**
    Consistent mapping rules:
    - A/X: Always confirm/select
    - B/Circle: Always back/cancel
    - Document and display current mapping
    - If context changes behavior, show prompt
    