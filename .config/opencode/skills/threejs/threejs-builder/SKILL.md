---
name: threejs-builder
description: "Design and implement lightweight Three.js (r150+) ES-module scenes—hero sections, interactive product viewers, particle backdrops, GLTF showcases, or quick prototypes—whenever prompts mention 'three.js/threejs scene', '3D web background', 'orbit controls', or 'WebGL demo'."
metadata:
  short-description: "Craft modern Three.js ES-module scenes."
---

# Three.js Builder

A Codex-ready framework for shipping elegant, performant Three.js web experiences with modern ES modules.

## Reference Files

> **Read the appropriate reference when working on specific topics:**

| Topic | File | Use When |
|-------|------|----------|
| **GLTF Models** | `references/gltf-loading-guide.md` | Loading, caching, cloning 3D models, SkeletonUtils |
| **Reference Frames** | `references/reference-frame-contract.md` | Calibration, anchoring, axis correctness, debugging |
| **Game Development** | `references/game-patterns.md` | State machines, animation switching, parallax, pooling |
| **Advanced Topics** | `references/advanced-topics.md` | Post-processing, shaders, physics, instancing |
| **Calibration Helpers** | `scripts/README.md` | GLTF calibration helper installation and usage |

---

## Philosophy: Start from Scene Intent

Three.js work lives inside a scene graph: parents transform children, and everything in `scene` is rendered.

**Before writing code, ask**:
- What is the core visual element or metaphor (hero object, particle field, data glyph)?
- How should visitors manipulate or perceive it (static hero, orbit control, camera-relative movement)?
- What level of hardware/performance do we target (mobile hero snippet vs. desktop interactive)?
- Which animation best communicates the story (continuous rotation, bobbing, interaction-driven)?

**Core principles**:
1. **Scene graph first** – model hierarchy and transforms before materials.
2. **Intent-driven primitives** – boxes, spheres, torus, planes cover 80% of hero cases; reach for GLTF only when fidelity demands it.
3. **Animation as transformation** – treat animation as evolving position/rotation/scale with `renderer.setAnimationLoop`.
4. **Performance through restraint** – reuse geometries/materials, clamp device pixel ratio, keep draw calls low.

---

## Foundational Principle: Lock a “Reference Frame Contract” First

Most Three.js bugs are not “rendering bugs” — they’re **reference-frame bugs**: wrong origin, wrong up-axis assumption, wrong forward direction, wrong “ground = y=0” semantics, wrong color space, or wrong loading environment.

Treat your scene like a contract you must prove once, then never violate:
- **Axes**: which way is forward for gameplay, and how do models map to it?
- **Anchors**: what does “on the ground” mean for each asset class?
- **Units**: what is 1 unit (meter-ish? pixel-ish?) and how do imported assets fit?
- **Color**: are textures and output color space correct?

If you don’t lock this contract early, you will chase symptoms: inverted movement, floating/sinking models, “wrongly loaded” textures, and end-state hangs caused by tangled state transitions.

### The Calibration Pass (do this before building gameplay)
Do a 60-second calibration scene and lock constants (axes/anchors/scale/color) before shipping gameplay systems.

Deep guide + troubleshooting map: `references/reference-frame-contract.md`

### Mesh Forward Verification (Do Not Guess)
Don’t “eyeball rotate until it looks right” and don’t assume “GLTF faces `-Z`”.

In the calibration scene, **prove** each imported model’s forward direction and lock it as a constant (global `MODEL_YAW_OFFSET` or per-asset `yawOffset`).

If you want a reusable helper module instead of hand-rolling arrows/box helpers each time:
- Install (repo-scoped): run `python3 .agents/skills/threejs-builder/scripts/install-gltf-calibration-helpers.py --out ./gltf-calibration-helpers.mjs`
- Install (from within the skill folder): run `python3 scripts/install-gltf-calibration-helpers.py --out ./gltf-calibration-helpers.mjs`
- Use: import and call `attachGltfCalibrationHelpers(...)` (see `scripts/README.md`)

Minimal check:
```js
// In Three.js, an Object3D’s "forward" is its local -Z axis.
const localForward = new THREE.Vector3(0, 0, -1);

// Attach a visible arrow to the model so you can *see* its forward.
const forwardArrow = new THREE.ArrowHelper(localForward, new THREE.Vector3(0, 1.2, 0), 1.2, 0xff00ff);
modelRoot.add(forwardArrow);

// Also log the current world-forward for debugging (post-normalization and post-rotation).
const worldForward = new THREE.Vector3();
modelRoot.getWorldDirection(worldForward);
console.log('model world forward (-Z):', worldForward.toArray());
```

Then decide:
- If the mesh runs backward, set `yawOffset = Math.PI`.
- If it faces the camera (common symptom), your yaw convention is wrong—flip the offset and re-check.

## Coordinate System & Camera Awareness (Critical)

Three.js is right-handed: +X right, +Y up, +Z toward the camera. Many GLTF assets are authored facing `-Z`, but **verify per pack** (don’t assume). Camera-relative controls must project the camera forward vector onto the XZ plane, normalize, then derive the right vector via a right-handed cross product to avoid inverted WASD when the camera orbits.

```
const forward = new THREE.Vector3();
camera.getWorldDirection(forward);
forward.y = 0;
forward.normalize();
// Right-handed basis (DON'T swap arguments): right = forward × up
const right = new THREE.Vector3().crossVectors(forward, new THREE.Vector3(0, 1, 0));
```

Practical rule:
- If A/D is inverted, your cross product order is wrong (or you need to flip `forward` with `forward.negate()` depending on your convention). Fix the basis, not the key mapping.

---

## Origins & “Ground” Anchors (Stop Guessing)

Anchoring is an asset-contract decision, not a “tweak until it looks right” decision.

Rule of thumb:
- Characters/props: `minY = 0`
- Ground tiles: often `maxY = 0` (walkable surface)

Deep guide + example code: `references/reference-frame-contract.md`

---

## Build Flow

### 1. Frame the Experience
- Define the vibe (portfolio, gamey, data viz) and jot a mini mood board (colors, light style, animation verbs).
- Choose interaction tier: static render, auto-rotation, OrbitControls, or custom camera/gameplay loop.
- Sketch layout: do you need a ground plane, backdrop gradient, floating particles, or spotlight object?

### 2. Establish Runtime Foundations
- Use modern ES modules—no global `THREE`. Import from `three` package or CDN versions (>=0.150).
- Minimal HTML template:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Three.js Scene</title>
  <style>body{margin:0;overflow:hidden;background:#010103;}canvas{display:block;}</style>
</head>
<body>
  <script type="module">
    import * as THREE from 'https://unpkg.com/three@0.160.0/build/three.module.js';

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(60, innerWidth / innerHeight, 0.1, 2000);
    camera.position.set(0, 1.5, 4.5);

    const renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(innerWidth, innerHeight);
    renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    document.body.appendChild(renderer.domElement);

    window.addEventListener('resize', () => {
      camera.aspect = innerWidth / innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(innerWidth, innerHeight);
    });
  </script>
</body>
</html>
```

- Plug OrbitControls from `three/addons/controls/OrbitControls.js` when interaction is needed, enable damping, and call `controls.update()` each frame.

### 2.5 GLTF Loading Guardrails (When You Use Models)
- Run via a local server (not `file://`) so relative resources resolve reliably.
- For animated/skinned GLTF instancing, use `SkeletonUtils.clone()` (plain `.clone()` breaks skeleton links).
- Always log animation clip names after load and select by exact string (avoid “best guess” name matching unless it’s a deliberate fallback).
- If your asset pack uses an atlas, avoid “multiply tinting” materials (it can turn textured models into weird flat colors). Prefer leaving `material.color` at white and using emissive/lighting for emphasis.

### 3. Compose the Scene
- **Geometries**: prefer built-ins (Box, Sphere, Torus, Plane, Cone, Icosahedron). For particle clouds use `BufferGeometry` + `Float32Array` positions.
- **Materials**: pick `MeshStandardMaterial` as default (tweak `roughness`/`metalness`), `MeshPhysicalMaterial` for glass/liquids, `MeshBasicMaterial` for unlit accents, `PointsMaterial` for particles.
- **Lighting**: start with Ambient (0.3–0.5) + Directional key + colored fill; enable shadows only when necessary and set `renderer.shadowMap.enabled = true` + map sizes of 1024–2048.
- **Color palettes**: define constants (e.g., `const COLORS = { primary: 0xff6600, accent: 0x0ff0ff }`) and keep backgrounds dark to let emissive tones pop.

### 4. Animate & Interact
- Implement animation loops with `renderer.setAnimationLoop((time) => { ... renderer.render(scene, camera); });`.
- Common patterns:
  - Continuous rotation with `mesh.rotation.y = time * 0.001`.
  - Bobbing via `mesh.position.y = Math.sin(time * 0.002) * 0.4`.
  - Mouse-reactive tilt: normalize pointer coords and lerp rotations for smoothness.
  - Camera-relative character motion for interactive demos (see snippet above for direction vectors).
- Store state outside the loop (e.g., `const inputState = { up: false, ... }`).

### 4.5 State Machines & “Time Ran Out” Bugs
If your app “hangs” at time-out, it’s almost always because multiple systems are competing to transition state.

Guardrails:
- Use a single `state.mode` and a single transition function.
- Treat `timeLeft <= 0` as terminal and clamp it once: `timeLeft = Math.max(0, timeLeft - dt)`.
- Add a one-way latch like `hasEnded` so the end transition can only happen once.

### 5. Polish & Performance
- Cap `renderer.setPixelRatio(Math.min(devicePixelRatio, 2))` to keep 4K laptops smooth.
- Reuse geometries/materials, avoid instantiating inside the animation loop.
- Use helpers (GridHelper, AxesHelper) for debugging, but remove them for production scenes.
- Separate setup helpers (e.g., `createLights()`/`createMeshes()`) to keep files navigable.

---

## Anti-Patterns to Avoid

❌ **Legacy global builds**: Using `<script src="three.js"></script>` and accessing `THREE` globals breaks tree-shaking and OrbitControls imports. Use ES modules.

❌ **Camera-blind controls**: Mapping WASD directly to world axes feels wrong once the camera rotates. Always derive movement vectors from the camera orientation.

❌ **Floating/sinking fixes by “random y offsets”**: If you’re tweaking `position.y` in 5 places, your anchoring strategy is missing.
Why bad: you’ll never converge across ground tiles vs characters vs props.
Better: normalize each asset to a declared anchor (`minY` or `maxY`) at load time and only place the wrapper.

❌ **Asset guessing**: Assuming GLTF forward direction, scale, or animation names without a calibration pass.
Better: build a 60-second calibration scene and lock constants (forward offsets, anchors, heights).

❌ **Off-center canvases from transform math**: Mixing `translate()` + `scale()` with the wrong `transform-origin` makes the render area drift.
Better: center via layout (flex/grid) and apply `scale()` only, with `transform-origin: center`.

❌ **Geometry churn inside loops**: Creating geometries/materials each frame tanks GC and FPS. Instantiate once and mutate transforms only.

❌ **Overly dense primitives**: Jumping to `SphereGeometry(1, 128, 128)` without purpose wastes perf; start with defaults and scale segments only when silhouetted edges demand it.

❌ **Unbounded pixel ratio**: Forgetting to clamp `devicePixelRatio` makes retina users suffer. Always clamp to ≤2 unless photorealism is mandatory.

---

## Variation Guidance

- **Purpose-specific styling**:
  - Portfolio hero → slow easing, glossy lighting, analogous palettes.
  - Game prototype → punchy colors, contrasty lights, camera-relative controls, particles.
  - Data viz → clean planes, grid helpers, consistent units, annotations.
  - Background loop → subtle gradients, low-frequency motion, ambient glow.
- **Mix geometry/material** choices: cycle through spheres, rounded boxes, low-poly icosahedrons, tubes. Experiment with `flatShading`, `wireframe`, emissive blooms.
- **Camera moods**: alternate between dolly-in hero (z≈4), aerial tilt (camera.set(8, 11, -6)), or isometric (45° yaw). Pair with matching movement logic.
- **Animation verbs**: rotate, pulse, orbit, flock, noise-driven drift. Avoid always rotating cubes at `0.001` speed.

---

## Remember

Three.js scenes succeed when the mental model (scene graph + intent) guides the build. Lead with philosophy, respect the coordinate system, keep loops lean, and vary geometry, lighting, and animation so every experience feels purpose-built. Let these patterns unlock creativity—they are rails, not cages.

For specific topics, see the **Reference Files** table at the top of this document.
