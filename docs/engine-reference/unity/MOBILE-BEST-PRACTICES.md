# Unity 6 — Mobile Best Practices (iOS / Android)

**Last verified:** 2026-08-19

Mobile-specific guidance for this edition. These are the budgets, APIs, and
patterns that differentiate a mobile build from a PC/console build. Always
cross-reference this document before writing gameplay, rendering, or asset code
for `Assets/` or `Assets/Scripts/` that will run on device.

---

## Platform Budgets (Default Targets)

These defaults are written to `.claude/docs/technical-preferences.md` by
`/setup-engine` when the mobile profile is selected. Override per-project in
`technical-preferences.md`.

| Metric | Mid-range Android Target | Premium/iOS Target | Hard Limit |
|--------|--------------------------|--------------------|------------|
| **Frame time** | 16.7ms (60 fps) | 16.7ms (60 fps) | 33.3ms (30 fps) |
| **Draw calls** | < 80 | < 120 | 150 |
| **Triangles (on screen)** | < 300K | < 500K | 1M |
| **Managed heap (typical)** | < 256MB | < 384MB | 512MB |
| **Texture memory** | < 300MB | < 450MB | Device-dependent |
| **Texture size (max)** | 2048² | 2048² (4096² hero only) | 4096² |
| **Build size (AAB)** | < 150MB | < 200MB | 150MB on-device install budget |
| **Cold start (launch)** | < 8s | < 6s | 12s |
| **Thermal throttling check** | Sustain 15 min at budget | Sustain 30 min | — |

GC allocations in hot paths are not allowed (see `.claude/rules/engine-code.md`).
On mobile, every 1KB/frame of GC triggers frame hitches — GC is the single most
common cause of mobile stutter.

---

## Graphics / Rendering (URP Mobile)

### Texture Compression — Always Pin Per-Platform

- **Android**: ASTC 4x4 / 6x6 (fallback ETC2 for very old devices)
- **iOS**: ASTC only (all supported devices)
- Normal maps: BC7/DXT5nm on Android is wrong — use ASTC for normals too
- UI sprites: use `Crunch`-disabled, max 1024², mipmap off for UI
- Never ship 32-bit RGBA uncompressed textures to device

### URP Settings for Mobile

- Enable **Render Graph** with mobile-friendly pass ordering; disable unused
  URP features (SSAO, screen-space shadows, decals) on Android mid-range
- Use **Forward+** only for premium tier; **Forward renderer** for mid-range
- **GPU Resident Drawer** (Unity 6) is the primary draw-call reducer — use it
  with LOD Group; still budget total visible instances
- Enable **Static Batching** for static scenery; **GPU Instancing** for repeated
  dynamic prefabs
- Limit real-time lights to 1–2 per screen; bake everything else (Lightmaps /
  Light Probes)
- Shadow distance < 30m; 1 cascaded shadow map; soft shadows off on mid-range

### Shaders

- Write Shader Graph shaders with mobile in mind: no per-pixel `smoothstep`
  cascades, prefer unlit/low-complexity lit materials for background elements
- Check the **shader variant count** after every material change — variant
  explosion (> 200 mobile shader variants) breaks build time and app size
- Use `UNITY_BRANCH`/`UNITY_FLATTEN` to reduce uniform cost in fragment shaders

---

## Memory Management (Mobile-Critical)

### Asset Loading Discipline

**Load by asset category, not by dogma.** Neither "always Resources" nor "always
Addressables" is correct here. The binding matrix lives in `.claude/rules/mobile-code.md`
and varies by category and MVP mode; the short version:

- SO config, core prefabs, UI panels, and level geometry → **Resources or direct reference**
- Skins, themes, seasonal content → Resources now, Addressables when it must update remotely
- Remote / live-ops content → **Addressables**

**Do not install Addressables until there is genuine remote content to update.** All five
reference codebases on this machine ship on Resources; three carry Addressables installed
with zero or near-zero call sites, paying build and catalog cost for nothing.

Access every asset through an abstraction (`IUILoader` for UI, the equivalent elsewhere)
so a category can move between Resources and Addressables without touching call sites.

**When Addressables IS in use for a category:**
- Use `Addressables.LoadAssetAsync<T>` with `await handle.Task`; never `LoadAsset`
  synchronously on the main thread
- Release EVERY handle: `Addressables.ReleaseInstance(obj)` or release the handle
- Pre-warm critical assets during loading scenes; never lazy-load during gameplay
- Bundle scenes by feature (level packs), not one giant catalog

### GC Hygiene

- Reuse collections: keep `List<T>` fields and `.Clear()` each frame (see
  `.claude/rules/engine-code.md` example)
- Avoid LINQ in hot paths; use `for` loops
- Cache `GetComponent<T>()` results in `Awake()`; never call in `Update()`
- Use `string.Intern` sparingly; avoid string concatenation in `Update()`
- Pool particles, projectiles, and UI elements — no `Instantiate`/`Destroy`
  during gameplay
- Run `GC.GetTotalMemory(false)` at soak-test checkpoints

---

## Input (Touch)

- New Input System only; define **Touch** bindings with **EnhancedTouch** for
  gesture support (multi-touch, swipe, long-press)
- Minimum touch target: 44pt (iOS HIG) / 48dp (Material) equivalent in canvas
- Thumb-zone aware UI layout for landscape portrait-optional games
- Add on-screen virtual joystick only when genre demands; prefer tap/drag
- Test with `Unity Remote` AND real device — Remote input latency lies

---

## Build Pipeline (From Code to Device)

The skills layer does not run the Unity editor; the build pipeline runs in CI:

| Step | Tool | Notes |
|------|------|-------|
| Build Android | IL2CPP backend → Gradle → AAB | Mono backend only for dev builds |
| Code signing (Android) | Play App Signing / keystore | Store secrets in CI vaults, never repo |
| Build iOS | macOS runner (GitHub Actions macOS) → Xcode | Requires Apple dev account + provisioning profile |
| Test | Unity Test Runner in EditMode + PlayMode | `-runTests -testPlatform EditMode` |
| Distribute | Google Play Internal Testing / TestFlight | Behind feature flags (live-ops) |

`/mobile-build-check` (this edition's skill) validates the project against the
mobile build checklist WITHOUT requiring a running Unity editor — run it before
handing a branch to CI.

---

## Platform Fragmentation & Low-End Devices

- Test against the 3-tier matrix: flagship (last-gen), mid-range (Snapdragon 6xx
  class), budget Android (Helio G-series class)
- Gate expensive features behind quality tiers (`QualitySettings` profile per
  device class), not a single "max" preset
- On low-end: disable post-processing, halve shadow maps, drop VSync tolerance
  to Adaptive
- Use the **Unity Profiler** and **Frame Debugger** on device (deep profiling) —
  not just the editor profiler
- Watch thermal throttling: measure sustained FPS over 15–30 min, not burst
  FPS

---

## Platform-Specific Gotchas (Post-Cutoff, HIGH RISK)

- **Android 14+ / API 34**: background activity launch restrictions affect
  deep links and ad SDK popups
- **iOS ATT**: AdSupport requires AppTrackingTransparency prompt; never assume
  IDFA availability
- **64-bit only**: IL2CPP always; 32-bit Android is unsupported by Play Store
- **Gradle plugin versions**: Unity 6 pins its own Gradle; do not upgrade the
  Gradle plugin in `mainTemplate.gradle` without verifying against Unity 6 LTS
- **Notch / punch-hole**: use `Screen.safeArea` for HUD; never anchor HUD to
  screen corners absolutely

---

## Summary: Mobile-Only Rules

1. Zero allocations in hot paths — GC hitches are the #1 mobile performance
   complaint.
2. Load by category — Resources by default, Addressables only for content that must update remotely. Release every Addressables handle.
3. ASTC textures, mipmap discipline, 2048² cap.
4. One realtime light max; bake the rest.
5. IL2CPP for all release builds; Mono for editor/dev only.
6. Test on device, not just in editor — editor profiler hides mobile cost.
7. Quality tiers per device class; no single "max" preset.

**Sources:**
- https://docs.unity3d.com/Manual/BestPracticeGuides.html
- https://docs.unity3d.com/Manual/optimizing-graphics-performance.html
- https://developer.android.com/guide/practices/split-apks
- https://developer.apple.com/app-store/review/guidelines/
