---
paths:
  - "Assets/**"
---

# Mobile Code Standards (Unity iOS/Android)

All code and assets in `Assets/` and `Assets/Scripts/` must follow these mobile standards.
Mobile devices have strict thermal, memory, and CPU/GPU budgets — violations cause
stutter, overheating, and store rejection, not just "slow code".

## Performance Budgets (Per Frame)
- **Draw calls**: < 80 mid-range Android, < 120 premium/iOS. NEVER > 150.
- **GC allocations**: zero in `Update`/`FixedUpdate`/physics hot paths. Every `new` in
  a hot path is a VIOLATION.
- **Realtime lights**: max 1 per screen; bake everything else.
- **Visible triangles**: < 300K mid-range, < 500K premium.
- **Sustained**: must hold budget for 15+ minutes, not just burst. Assume thermal throttling.

## Asset Loading — Load By Category, Not By Dogma

Neither "always Resources" nor "always Addressables" is correct. Choose by what the
asset *is*, and by which MVP mode is in play.

| Asset category | `demo` mode | `signal` mode | Ship |
|---|---|---|---|
| SO config (level order, tuning, flag catalog) | direct reference | Resources | Resources |
| Core prefabs (board, piece, UI shell) | direct reference | direct reference | direct reference |
| UI panels | `UIRegistry` → Resources | Resources | Resources |
| Level geometry prefabs | Resources | Resources | Resources |
| Skins / themes / seasonal content | — | Resources | Addressables |
| Remote or live-ops content | — | Addressables | Addressables |

Rules that follow from the table:
- **Do NOT install Addressables until there is genuine remote content to update.**
  Installing it "for later" adds build complexity and a catalog to maintain for nothing.
- All asset access goes through an abstraction (`IUILoader` for UI, `IAssetLoader` or
  the equivalent elsewhere) so a category can move between Resources and Addressables
  without touching call sites.
- If Addressables IS in use for a category: release EVERY handle. `UILoadedPrefab.Dispose()`,
  `Addressables.ReleaseInstance(obj)`, or release the handle. A leaked handle is a memory
  leak, and on low-end devices a memory leak is an OOM kill.
- `Resources` folders must stay bounded. Everything under `Resources/` is in the build
  and in the initial catalog scan — dumping unbounded content there slows cold start.

## Texture & Asset Discipline
- Android: ASTC 4x4/6x6 compression (fallback ETC2). iOS: ASTC only.
- Max texture size 2048² (4096² only for hero assets). UI sprites ≤ 1024², mipmaps OFF for UI.
- Never ship 32-bit uncompressed RGBA textures to device.
- Check the shader variant count after every material change — variant explosion
  (> 200 mobile variants) breaks build time and app size.

## Runtime Hygiene
- Pool everything spawned during gameplay: projectiles, particles, pieces, UI popups.
  NO `Instantiate`/`Destroy` after the loading screen. Use `IPoolService`.
- Cache `GetComponent<T>()` in `Awake()` — never call it in `Update()`.
- NO LINQ (`Where`, `Select`, `ToList`) in hot paths — use `for` loops.
- NO string concatenation in `Update()` — prebuild display strings, update only changed labels.
- Reuse collections: keep `List<T>` fields and `.Clear()` them rather than reallocating.
- UI anchors: HUD must respect `Screen.safeArea` — never anchor to absolute screen corners.

## Device Diversity
- Gate expensive features behind quality tiers per device class, never a single "max" preset.
- Test decisions against three tiers: flagship, mid-range, and budget Android.
  Assume users play on all three.
- Editor profiling hides mobile cost. Device profiling is the only real measurement.

## Build
- IL2CPP for all release builds; Mono for editor/dev only.
- ARM64 required. 32-bit Android is not shippable.
- Increment the bundle version before every store build.
