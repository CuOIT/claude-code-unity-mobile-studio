---
paths:
  - "assets/**"
  - "src/**"
  - "**/*.cs"
---
# Mobile Code Standards (Unity iOS/Android)
All code and assets in `assets/` and `src/` must follow these mobile standards.
Mobile devices have strict thermal, memory, and CPU/GPU budgets — violations
cause stutter, overheating, and store rejection, not just "slow code".

## Performance Budgets (Per Frame)
- **Draw calls**: < 80 mid-range Android, < 120 premium/iOS. NEVER > 150.
- **GC allocations**: zero in `Update`/`FixedUpdate`/physics hot paths. Every
  `new` in a hot path is a VIOLATION.
- **Realtime lights**: max 1 per screen; bake everything else.
- **Visible triangles**: < 300K mid-range, < 500K premium.

## Texture & Asset Discipline
- Android: ASTC 4x4/6x6 compression (fallback ETC2). iOS: ASTC only.
- Max texture size 2048² (4096² only for hero assets). UI sprites ≤ 1024²,
  mipmaps OFF for UI.
- Never ship 32-bit uncompressed RGBA textures to device.
- Every asset loaded after the first scene MUST go through Addressables —
  `Resources.Load` is FORBIDDEN outside the first scene.

## Runtime Hygiene
- Pool everything spawned during gameplay: projectiles, particles, enemies,
  UI popups. NO `Instantiate`/`Destroy` after the loading screen.
- Cache `GetComponent<T>()` in `Awake()` — never call in `Update()`.
- NO LINQ (`Where`, `Select`, `ToList`) in hot paths — use `for` loops.
- NO string concatenation in `Update()` — prebuild display strings, update
  only changed labels.
- Release EVERY Addressables handle: `Addressables.ReleaseInstance(obj)` or
  release the handle. Leaked handles = memory leaks = OOM kills on low-end
  devices.
- UI anchors: HUD must respect `Screen.safeArea` — never anchor to absolute
  screen corners.

## Device Diversity
- Gate expensive features behind quality tiers (per device class), never a
  single "max" preset.
- Assume thermal throttling: code must sustain budget for 15+ minutes, not
  just burst.
- Test decisions against: flagship, mid-range (Snapdragon 6xx class), and
  budget Android (Helio G class) — assume users play on all three.
