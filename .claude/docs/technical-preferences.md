# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

> **Profile**: Unity Mobile Puzzle. See `.claude/docs/puzzle-profile.md`.
>
> **Version policy**: this file records **capabilities**, not pinned versions. Engine,
> package, and SDK versions are decided at the moment of actual use — never assumed
> from this document. When a version matters for a decision, ask; do not infer.

## Engine & Language

- **Engine**: Unity 6 (exact release chosen at project setup — do not assume)
- **Language**: C# 9+
- **Rendering**: Universal Render Pipeline (URP)
- **Physics**: Unity Physics 2D (puzzle-typical); 3D only if the mechanic requires it
- **Scripting backend**: IL2CPP for release builds; Mono for editor/dev only
- **Async**: UniTask (the whole CuOCore suite is built on it — do not introduce a second async model)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: Mobile — iOS and Android
- **Input Methods**: Touch only
- **Primary Input**: Single-touch tap / drag
- **Gamepad Support**: None
- **Touch Support**: Full (New Input System)
- **Platform Notes**: HUD must respect `Screen.safeArea` (notch / punch-hole).
  Minimum touch target 44pt (iOS HIG) / 48dp (Material). Portrait-first unless the
  mechanic demands otherwise. Multi-touch disabled by default for puzzle input.

## Naming Conventions

- **Classes**: `PascalCase`
- **Variables**: `camelCase` for locals/params; `_camelCase` for private fields; `PascalCase` for properties
- **Signals/Events**: SO event channels named `<Subject><Verb>EventChannel` (e.g. `GameplayStartedEventChannel`); C# events named `On<Subject><Verb>`
- **Files**: one public type per file, filename matches type name
- **Scenes/Prefabs**: `PascalCase`; level prefabs follow the pattern chosen by `/level-pipeline`
- **Constants**: `PascalCase` for `const`/`static readonly`; `SCREAMING_SNAKE_CASE` only for interop/define symbols
- **Namespaces**: every file must declare one. No global namespace.

## Performance Budgets

- **Target Framerate**: 60 fps
- **Frame Budget**: 16.7 ms (hard floor 33.3 ms / 30 fps)
- **Draw Calls**: < 80 mid-range Android · < 120 premium/iOS · never > 150
- **Memory Ceiling**: < 256 MB managed heap mid-range · < 384 MB premium
- **GC in hot paths**: zero allocations in `Update`/`FixedUpdate`/physics callbacks
- **Sustained load**: must hold budget for 15+ minutes (thermal throttling), not burst

See `docs/engine-reference/unity/MOBILE-BEST-PRACTICES.md` for the full matrix.

## Testing

- **Framework**: Unity Test Framework (NUnit) — EditMode + PlayMode
- **Minimum Coverage**: every puzzle rule and formula has an EditMode test; every
  end-to-end flow (boot → home → gameplay → win/lose → retry) has a PlayMode test
- **Required Tests**: puzzle rules, level solvability/validity, undo snapshots,
  feature-flag resolution, adapter contract conformance (each adapter tested against
  the same suite as its Null counterpart)

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- Vendor SDK types (`MaxSdk`, `Firebase`, `UnityEngine.Purchasing`, `AppsFlyer`,
  `GameAnalytics`) referenced anywhere outside a designated adapter assembly
- Forking a CuOCore UPM package into `Assets/` instead of consuming it via UPM
- A second event bus / message broker / static event hub — SO event channels only
  for cross-module communication (see `.claude/rules/service-layer.md`)
- Reading a feature flag that has no `LiveOpsDefinition` in the catalog
- Initialising ads before consent has resolved
- `Instantiate`/`Destroy` during gameplay — pool via `IPoolService`
- LINQ, string concatenation, or `GetComponent` in hot paths
- Files over 1000 lines; folders named after a developer

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- **CuOCore UPM suite** (`com.cuongbs.*`, `com.cuobs.ui`) — the architecture layer.
  See `.claude/docs/cuocore-map.md` for what each package provides.
- **UniTask** — async/await for Unity (CuOCore baseline)
- **DOTween** — tweening. Serialize all params into the Inspector, grouped under headers.
- **TextMeshPro** — all text rendering
- **I2 Localization** — string tables (in use across shipped titles)
- **Spine** — 2D skeletal animation, if the art direction calls for it

Addressables is **not** installed by default. Do not add it until there is genuine
remote content to update. See the asset-loading matrix in `.claude/rules/mobile-code.md`.

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

Four ADRs are expected before Production: adapter boundary, feature-flag mechanism
(including kill-switch latency), level pipeline, SO event channel strategy.

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: `unity-specialist`
- **Language/Code Specialist**: `gameplay-programmer`
- **Shader Specialist**: `unity-shader-specialist`
- **UI Specialist**: `unity-ui-specialist`
- **Additional Specialists**: `unity-addressables-specialist` (asset loading strategy),
  `mobile-sdk-engineer` (adapters, consent, remote config), `puzzle-level-designer`
- **Routing Notes**: anything touching `Assets/Scripts/Services/**` routes to `mobile-sdk-engineer`
  first, then `unity-specialist` for Unity-idiom review. Puzzle rule code routes to
  `gameplay-programmer` with `systems-designer` for formula review.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (`.cs` under `Assets/Scripts/Gameplay/`) | `gameplay-programmer` |
| Service adapters (`.cs` under `Assets/Scripts/Services/`) | `mobile-sdk-engineer` |
| Shader / material (`.shader`, `.shadergraph`, `.mat`) | `unity-shader-specialist` |
| UI / screen (`.prefab` under UI, `UIRegistry` assets) | `unity-ui-specialist` |
| Scene / level prefab | `puzzle-level-designer` |
| Asset loading / UPM manifest | `unity-addressables-specialist` |
| Native extension / plugin files | `unity-specialist` |
| General architecture review | Primary |
