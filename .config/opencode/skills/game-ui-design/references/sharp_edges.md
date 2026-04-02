# Game Ui Design - Sharp Edges

## Safe Zone Violation

### **Id**
safe-zone-violation
### **Summary**
Critical UI elements placed outside TV safe zones
### **Severity**
critical
### **Situation**
  Health bar in corner gets cut off on TVs. Ammo counter invisible on some displays.
  Quest text runs off screen edge. Players complain "I can't see my health."
  
### **Why**
  TVs have overscan - they cut off 3-10% of edges. This varies by manufacturer, model,
  and settings. Unlike monitors, TVs assume video content with safe margins. Console
  certification often requires safe zone compliance. Players will refund games they
  can't play properly on their setup.
  
### **Solution**
  # Safe zone implementation
  
  Action safe (93% of screen):
  - Gameplay can extend to edges
  - Moving elements can reach here
  
  Title safe (90% of screen):
  - All static HUD elements
  - All text must be within this
  - All interactive elements
  
  Implementation:
  // Calculate safe margins
  float safeMargin = screenWidth * 0.05f; // 5% each side = 90% safe
  Rect safeArea = new Rect(
      safeMargin, safeMargin,
      screenWidth - safeMargin * 2,
      screenHeight - safeMargin * 2
  );
  
  // Position HUD elements within safeArea
  healthBar.position = safeArea.topLeft + offset;
  
  Required: Safe zone slider in options (0-10%)
  Default to conservative 5% for console, 0% for PC
  
### **Symptoms**
  - I can't see my health bar
  - Text is cut off on my TV
  - Console certification failure
  - Player complaints vary by display
### **Detection Pattern**
position:\s*(0|0px|0%)|anchor.*=.*0.*0|margin.*=.*0

## Controller Navigation Deadend

### **Id**
controller-navigation-deadend
### **Summary**
Menu elements unreachable or trapped via controller navigation
### **Severity**
critical
### **Situation**
  Can't select certain buttons with D-pad. Tab key navigates but controller can't
  switch tabs. Inventory grid has no exit point. Confirmation popup not focusable.
  
### **Why**
  Controller players literally cannot complete actions. Game becomes unplayable.
  This is the #1 cause of "unplayable with controller" reviews. Mouse was added
  as fallback but controller-only players (console, Steam Deck) are stuck.
  
### **Solution**
  # Controller navigation audit checklist
  
  1. Focus system:
     - Every interactive element can receive focus
     - Visual focus indicator is obvious (not subtle)
     - Focus indicator works on all backgrounds
  
  2. Navigation:
     - D-pad moves focus logically (not randomly)
     - Wrapping: End of row -> Start of next row
     - Escape routes: Every menu has clear "back" path
     - Tab equivalent: LB/RB switch major sections
  
  3. Test flow:
     Start game with controller only:
     ✓ Main menu -> Options -> All submenus -> Back
     ✓ Game -> Pause -> All menu items -> Resume
     ✓ Inventory -> All slots -> Equip -> Exit
     ✓ Shop -> Browse -> Buy -> Exit
     ✓ Dialogue -> All choices -> Advance
  
  4. Focus traps to fix:
     - Modal dialogs must trap then release focus
     - Dropdowns must be navigable and closable
     - Nested menus need clear back behavior
  
  // Unity example - ensure navigation
  button.navigation = new Navigation {
      mode = Navigation.Mode.Explicit,
      selectOnUp = upButton,
      selectOnDown = downButton,
      selectOnLeft = leftButton,
      selectOnRight = rightButton
  };
  
### **Symptoms**
  - Can't select this with controller
  - Focus indicator disappears
  - Stuck in submenu
  - Must use mouse to continue
### **Detection Pattern**


## Resolution Scaling Failure

### **Id**
resolution-scaling-failure
### **Summary**
UI designed for one resolution, broken at others
### **Severity**
critical
### **Situation**
  UI perfect at 1080p. At 4K, elements are tiny. At 720p, elements overlap.
  On ultrawide, HUD is stretched or off-center. On Steam Deck, unreadable.
  
### **Why**
  Modern games run on displays from 720p handhelds to 8K TVs. Viewing distance
  varies from 1 foot (monitor) to 10 feet (TV). Fixed pixel sizes become
  microscopic or massive. Players shouldn't need perfect vision to play.
  
### **Solution**
  # Resolution-independent UI design
  
  1. Reference resolution:
     - Design at 1080p (1920x1080)
     - This is your "100% scale" baseline
  
  2. Scaling modes:
     - Scale With Screen Size (Unity Canvas Scaler)
     - Match Width Or Height based on game type
     - Wide games: Match height (1080p reference)
     - Tall games: Match width
  
  3. UI Scale option:
     Settings -> UI Scale: [50%] [75%] [100%] [125%] [150%] [200%]
     Apply immediately, save preference
     Default higher for TV/console
  
  4. Testing checklist:
     □ 1280x720 (Steam Deck, Switch)
     □ 1920x1080 (baseline)
     □ 2560x1440 (gaming monitors)
     □ 3840x2160 (4K TVs)
     □ 2560x1080 (ultrawide)
     □ 3440x1440 (ultrawide)
  
  5. Minimum readable sizes at 1080p:
     - Body text: 16px (scale up from here)
     - Important info: 24px+
     - Icons: 32x32px minimum
  
  // Unity Canvas Scaler setup
  canvasScaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
  canvasScaler.referenceResolution = new Vector2(1920, 1080);
  canvasScaler.matchWidthOrHeight = 1f; // Match height
  
### **Symptoms**
  - UI tiny on 4K
  - Elements overlap at low resolution
  - Text unreadable on Steam Deck
  - Ultrawide has centered HUD with empty sides
### **Detection Pattern**
fontSize:\s*[0-9]px|width:\s*[0-9]{3}px|height:\s*[0-9]{2}px

## Input Prompt Mismatch

### **Id**
input-prompt-mismatch
### **Summary**
Showing wrong controller button icons for current input device
### **Severity**
high
### **Situation**
  Playing with PlayStation controller, shows Xbox buttons. Switch between
  keyboard and controller, prompts don't update. "[Press A]" but I have
  no A button.
  
### **Why**
  Players don't know what button to press. Breaks tutorials completely.
  Creates confusion and support tickets. PlayStation players see Xbox prompts
  as disrespectful. Professional games handle this seamlessly.
  
### **Solution**
  # Input prompt system
  
  1. Detect input type:
     - Track last input device used
     - Switch prompts on ANY input from different device
     - Small delay (200ms) prevents flashing
  
  2. Icon sets needed:
     - Xbox (default for "generic gamepad")
     - PlayStation (detect DualShock/DualSense)
     - Nintendo Switch (button positions differ!)
     - Keyboard + Mouse
     - Touch (mobile)
  
  3. Button mapping awareness:
     // Don't hardcode "[Press A]"
     string prompt = GetPromptForAction("confirm");
     // Returns "[A]" or "[X]" or "[Space]" etc.
  
     // Handle rebinding
     if (playerReboundConfirm) {
         prompt = GetBoundKeyPrompt("confirm");
     }
  
  4. Platform detection:
     // Unity example
     if (Gamepad.current is DualShockGamepad) {
         UsePlayStationIcons();
     } else if (Gamepad.current != null) {
         UseXboxIcons(); // Default for generic
     } else {
         UseKeyboardIcons();
     }
  
  5. Steam Input consideration:
     - Steam can remap any controller
     - Use Steam Input API glyphs when available
     - Falls back to detected type otherwise
  
### **Symptoms**
  - Says press A but I'm on PlayStation
  - Prompts show keyboard when using controller
  - Tutorial impossible to follow
  - Prompts don't update when switching input
### **Detection Pattern**
"Press A"|"Press X"|"Press \[A\]"

## Colorblind Failure

### **Id**
colorblind-failure
### **Summary**
Critical information conveyed only through color
### **Severity**
critical
### **Situation**
  Enemy health bars red, friendly bars green - colorblind players can't distinguish.
  Rarity indicated only by color glow. Damage types by color with no icon.
  "Red means stop" but 8% of players can't see red properly.
  
### **Why**
  8% of men and 0.5% of women have color vision deficiency. Red-green blindness
  (deuteranopia/protanopia) is most common - exactly the colors games use for
  enemy/ally. Without accommodation, games are literally unplayable for millions.
  
### **Solution**
  # Colorblind-accessible design
  
  1. Never color alone:
     - Enemy: Red + hostile icon + "Enemy" label
     - Ally: Blue + friendly icon + "Ally" label
     - Health: Red bar + "HP" text + current/max numbers
  
  2. Shape differentiation:
     Common   | Danger  | Safe    | Neutral
     Circle   | Triangle| Diamond | Square
     ●        | ▲       | ◆       | ■
  
  3. Rarity without color:
     Common:    Plain border
     Uncommon:  Single line border
     Rare:      Double border
     Epic:      Border + corner ornament
     Legendary: Full ornate frame
  
  4. Built-in colorblind modes:
     Settings -> Accessibility -> Colorblind Mode:
     - Off
     - Deuteranopia (red-green, most common)
     - Protanopia (red-green, different)
     - Tritanopia (blue-yellow, rare)
  
     Adjust affected colors:
     - Enemy red -> Orange/Pink
     - Ally green -> Blue/Cyan
     - Increase contrast
  
  5. Testing tools:
     - Coblis color blindness simulator
     - Photoshop: View -> Proof Setup -> Color Blindness
     - Windows: Ease of Access -> Color Filters
  
### **Symptoms**
  - Can't tell enemies from allies
  - What rarity is this item?
  - Player complaints from colorblind users
  - Accessibility certification failure
### **Detection Pattern**


## Font Size Disaster

### **Id**
font-size-disaster
### **Summary**
Text too small to read on target displays
### **Severity**
high
### **Situation**
  Designed on 27" monitor, unreadable on TV from couch. Tooltips require
  squinting. Damage numbers illegible during combat. Item descriptions
  need a magnifying glass.
  
### **Why**
  Viewing distance varies drastically. 1080p on 24" monitor at 2 feet is very
  different from 1080p on 50" TV at 10 feet. Small text strains eyes, excludes
  players with vision impairment, and creates accessibility failures.
  
### **Solution**
  # Font size guidelines
  
  1. Minimum sizes at 1080p (scale proportionally):
     - Critical HUD (health, ammo): 24px+
     - Standard UI text: 18px
     - Secondary info: 16px
     - Minimum for anything: 14px
  
  2. TV/Console multiplier:
     Base PC size * 1.25 to 1.5 for TV viewing
     Or detect TV mode and adjust automatically
  
  3. Font size option:
     Settings -> Accessibility -> Text Size:
     [Small] [Normal] [Large] [Larger]
     Affects ALL text proportionally
  
  4. Font choice matters:
     - Sans-serif for UI (clean, readable)
     - Avoid thin weights (Light, Thin)
     - Test lowercase readability (a, e, c)
     - High x-height fonts read better small
  
  5. Contrast for readability:
     - Dark text on light: #333 on #FFF
     - Light text on dark: #FFF on #222
     - Minimum 4.5:1 contrast ratio
     - Higher contrast for smaller text
  
  6. Dynamic sizing test:
     □ Read all text from 10 feet away
     □ Readable while character is moving
     □ Legible during intense action
     □ Check tooltip/description text
  
### **Symptoms**
  - Text too small
  - Players lean forward to read
  - Squinting during gameplay
  - Requests for text size option
### **Detection Pattern**
fontSize:\s*1[0-4](px)?|font-size:\s*1[0-4]px

## Motion Sickness Trigger

### **Id**
motion-sickness-trigger
### **Summary**
UI animations that cause discomfort or vestibular issues
### **Severity**
high
### **Situation**
  UI slides in from off-screen constantly. Screen shake applied to UI elements.
  Parallax scrolling in menus. Aggressive camera animations on menu transitions.
  
### **Why**
  Vestibular disorders affect millions. Excessive motion causes nausea, headaches,
  and disorientation. Some players physically cannot play games with excessive
  motion. This is an accessibility requirement, not a preference.
  
### **Solution**
  # Motion-safe UI design
  
  1. Respect system preferences:
     // Check OS-level reduced motion setting
     if (SystemPreferences.ReducedMotion) {
         DisableUIAnimations();
         UseInstantTransitions();
     }
  
  2. In-game option:
     Settings -> Accessibility -> Reduce Motion: [On/Off]
     Affects:
     - Screen shake intensity (separate slider)
     - UI transition animations
     - Camera motion in menus
     - Parallax effects
  
  3. Safe vs problematic animations:
     SAFE:
     - Fade in/out (opacity only)
     - Scale from 95% to 100% (subtle)
     - Color transitions
     - Progress bar fills
  
     PROBLEMATIC:
     - Slide from off-screen
     - Bounce/elastic effects
     - Screen shake
     - Rotation
     - Parallax scrolling
     - Zoom animations
  
  4. When motion is needed:
     - Duration under 200ms
     - Ease-out only (starts fast, slows)
     - Small travel distance
     - Single direction (no zig-zag)
  
  5. Screen shake specifically:
     Settings -> Camera Shake: [Off] [Low] [Medium] [High]
     NEVER apply shake to UI, only world
  
### **Symptoms**
  - Reports of nausea
  - Too much animation
  - Requests for reduced motion
  - Players quitting after short sessions
### **Detection Pattern**
animation-duration:\s*[5-9][0-9]{2}ms|animation-duration:\s*[1-9]s

## Touch Target Too Small

### **Id**
touch-target-too-small
### **Summary**
Interactive elements too small for reliable touch or controller selection
### **Severity**
high
### **Situation**
  Mobile port has tiny buttons. Close button is 16x16 pixels. Inventory
  slots require surgical precision. Controller selection boxes smaller
  than visual elements.
  
### **Why**
  Fingers are imprecise. Thumbs on touchscreen are worse. Controller stick
  navigation needs generous selection areas. Small targets cause misclicks,
  frustration, and make games feel broken. Apple and Google have guidelines
  for a reason.
  
### **Solution**
  # Touch and selection target sizes
  
  1. Minimum sizes:
     - Apple: 44x44pt minimum
     - Google: 48x48dp minimum
     - Game UI: 48x48 pixels at 1080p (scale up)
     - Generous: 56x56+ for important actions
  
  2. Visual vs touchable area:
     Icon can be 24x24, but touch area must be 48x48
     ┌────────────────┐
     │   ┌────────┐   │
     │   │ [icon] │   │ <- Visual 24x24
     │   └────────┘   │
     └────────────────┘  <- Touch 48x48
  
  3. Spacing between targets:
     Minimum 8px gap between touchable areas
     Prevents accidental adjacent selection
  
  4. Controller selection:
     - Selection highlight larger than element
     - D-pad navigation snaps to logical grid
     - Visible focus indicator, not just color
  
  5. Implementation:
     // Unity Button with invisible expanded hitbox
     [RequireComponent(typeof(Image))]
     public class TouchExpander : MonoBehaviour {
         public void OnValidate() {
             GetComponent<Image>().alphaHitTestMinimumThreshold = 0f;
             // Expand RectTransform beyond visible content
         }
     }
  
  6. Test protocol:
     - Test with thumb, not stylus/mouse
     - Test in motion (simulated gameplay)
     - Test one-handed (portrait mobile)
     - Test with controller only
  
### **Symptoms**
  - Misclicks and wrong selections
  - Buttons too small
  - Controller navigation feels imprecise
  - Mobile players struggle
### **Detection Pattern**
width:\s*[0-3][0-9]px|height:\s*[0-3][0-9]px|size.*=.*[0-3][0-9]

## Hud Obscures Gameplay

### **Id**
hud-obscures-gameplay
### **Summary**
UI elements blocking critical gameplay visibility
### **Severity**
high
### **Situation**
  Health bar placed over where enemies spawn. Minimap covers corner where
  snipers hide. Dialogue box obscures player character. Quest tracker
  blocks loot on ground.
  
### **Why**
  Players die to things they can't see. Information meant to help them
  actually hurts them. Screen real estate is precious - every UI element
  costs visibility. This breaks the fundamental contract of fair play.
  
### **Solution**
  # HUD positioning principles
  
  1. Critical gameplay areas:
     - Center: Crosshair area must be clear
     - Player character: Must be visible
     - Immediate threat zone: Usually center/forward
     - Interaction zone: Where player looks
  
  2. Safe HUD positions:
     ┌───────────────────────────────────┐
     │ [Health]          [Minimap] │ <- Corners
     │                             │
     │                             │
     │                             │ <- Center is sacred
     │                             │
     │ [Abilities]    [Objectives] │ <- Bottom corners
     └───────────────────────────────────┘
  
  3. Dynamic hiding:
     - Combat mode: Hide non-essential UI
     - Cinematic mode: Hide all UI
     - Photo mode: Complete UI removal
     - Aim down sights: Clear crosshair area
  
  4. Transparency for non-critical:
     - Minimap: 60-80% opacity
     - Quest tracker: 70% opacity
     - Background of tooltips: Semi-transparent
  
  5. Player control:
     Settings -> HUD Position: [Preset/Custom]
     Allow repositioning of individual elements
     Save per-element opacity preferences
  
  6. Special case - dialogue:
     - Position at bottom with speaker portrait
     - Never over player character
     - Semi-transparent or opaque options
     - Auto-advance option for accessibility
  
### **Symptoms**
  - Enemy came from behind the minimap
  - Can't see my character
  - Players turn off helpful UI
  - Deaths blamed on UI obscuring threats
### **Detection Pattern**


## No Text Outline Or Shadow

### **Id**
no-text-outline-or-shadow
### **Summary**
Text without outline/shadow becomes unreadable on varied backgrounds
### **Severity**
high
### **Situation**
  White text on bright sky - invisible. Dark text on shadows - invisible.
  Health numbers unreadable over fire effects. Damage numbers lost in
  spell particles.
  
### **Why**
  Games have dynamic backgrounds. What's readable on one frame is invisible
  on the next. UI text must be legible regardless of what's behind it.
  This is the most common HUD readability problem and easiest to fix.
  
### **Solution**
  # Text readability techniques
  
  1. Text outline (best):
     2px stroke in contrasting color
     White text -> Black outline
     Black text -> White outline
     Colored text -> Dark outline
  
  2. Drop shadow (good):
     2-4px offset, 50% opacity
     Direction: Down-right (light from top-left)
     Blur: 0-2px (sharp better than blurry)
  
  3. Background panel (safest):
     Semi-transparent dark background
     20-40% black behind text
     Consistent container approach
  
  4. Combined approach (recommended):
     Text + 1px outline + subtle shadow + panel
     Readable in any situation
  
  5. Never:
     - Thin fonts without outline
     - Low contrast (gray on gray)
     - Relying on background being consistent
  
  // CSS example
  .hud-text {
      color: white;
      text-shadow:
          -2px -2px 0 black,
           2px -2px 0 black,
          -2px  2px 0 black,
           2px  2px 0 black,
          0 2px 4px rgba(0,0,0,0.5);
  }
  
  // Unity TextMeshPro
  Set Outline Width: 0.2
  Set Outline Color: Black
  Enable Underlay for shadow effect
  
### **Symptoms**
  - Can't read the numbers
  - Text disappears on certain backgrounds
  - HUD elements "flash" as background changes
  - Screenshots show unreadable UI
### **Detection Pattern**
text-shadow:\s*none|textShadow:\s*"none"

## Inconsistent Button Behavior

### **Id**
inconsistent-button-behavior
### **Summary**
Same button does different things across different screens
### **Severity**
high
### **Situation**
  "B" backs out of inventory but closes the game in pause menu. "Y" confirms
  here but cancels there. Accept/Cancel positions swap between menus.
  
### **Why**
  Players build muscle memory. Inconsistency causes them to accidentally
  close games, delete saves, or make wrong purchases. Every surprise
  breaks trust. This is death by a thousand cuts.
  
### **Solution**
  # Consistent button mapping
  
  1. Universal mappings (never change):
     A/Cross: Confirm, Select, Progress
     B/Circle: Back, Cancel, Close
     Start: Pause, Menu
     Select: Map, Secondary menu
  
  2. Contextual mappings (show prompts):
     Y/Triangle: Context action 1 (inspect, pickup)
     X/Square: Context action 2 (drop, use)
     Bumpers: Navigate tabs, cycle
     Triggers: Page up/down, zoom
  
  3. Position consistency:
     - "Back" always same position in menu
     - "Confirm" always same position
     - Sort order consistent (Accept-Cancel, not Cancel-Accept)
  
  4. Dangerous actions:
     - Require hold, not tap
     - Different button than adjacent actions
     - Confirmation dialog
     - "Are you sure?" for delete/quit
  
  5. Document and display:
     - Button legend on screen
     - Prompts update with context
     - Settings shows full mapping
  
  6. Platform conventions:
     Xbox: A=Yes, B=No
     PlayStation (Japan): Circle=Yes, Cross=No
     PlayStation (West): Cross=Yes, Circle=No
     Support both conventions in settings
  
### **Symptoms**
  - I accidentally quit the game
  - B should go back, not close
  - Players confused by changing behavior
  - Wrong action taken frequently
### **Detection Pattern**


## No Keyboard Shortcut Display

### **Id**
no-keyboard-shortcut-display
### **Summary**
Keyboard controls exist but aren't shown, or rebinding breaks prompts
### **Severity**
medium
### **Situation**
  "There are keyboard shortcuts?" "I rebound WASD but prompts still show WASD."
  Alt+F4 closes game with no warning. Hidden shortcuts in tooltip footnotes only.
  
### **Why**
  Players don't discover helpful shortcuts. Rebinding makes prompts lies.
  Power users frustrated by hidden functionality. New players miss efficiency.
  
### **Solution**
  # Keyboard shortcut visibility
  
  1. Show bound keys, not defaults:
     // Wrong
     prompt = "Press SPACE to jump";
  
     // Right
     string jumpKey = GetBoundKey("Jump");
     prompt = $"Press {jumpKey} to jump";
  
  2. Tooltip shortcuts:
     Inventory (I)
     Map (M)
     Quest Log (J)
     Show bound key, not hardcoded
  
  3. Key legend option:
     Settings -> Controls -> Show Keybinds: On/Off
     Toggle key legend overlay
  
  4. Rebinding awareness:
     - On rebind, update all prompts
     - Show conflicts when rebinding
     - "Reset to defaults" option
  
  5. Alt+F4 handling:
     - Either disable or show save confirmation
     - Don't lose unsaved progress
     - Or explicitly support it as "quick quit"
  
  6. Hidden shortcuts documentation:
     Controls screen lists ALL shortcuts
     Include "advanced" section
     Searchable if extensive
  
### **Symptoms**
  - Didn't know there was a shortcut
  - Prompts show wrong key after rebind
  - Player loses progress to Alt+F4
  - What does this key do?
### **Detection Pattern**
"Press [A-Z]"|"Press Space"|"Press Enter"