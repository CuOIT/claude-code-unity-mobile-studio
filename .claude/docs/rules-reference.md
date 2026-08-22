# Path-Specific Rules

Rules in `.claude/rules/` are automatically enforced when editing files in matching
paths. Each rule declares its scope in YAML frontmatter (`paths:`) — a rule without
frontmatter does not scope and therefore does not apply.

| Rule File | Path Pattern | Enforces |
| ---- | ---- | ---- |
| `service-layer.md` | `Assets/Scripts/Services/**`, `Assets/Scripts/Core/**` | Check CuOCore before writing an interface; vendor types only in adapter assemblies; Null counterpart per adapter; bootstrap ordering with **consent before ads**; SO event channels only |
| `feature-flags.md` | `Assets/Scripts/**`, flag registry | Catalog is the single source; every flag read must be declared; three fail behaviours incl. kill-switch latency; ads + IAP kill-switches mandatory |
| `puzzle-code.md` | `Assets/Scripts/Gameplay/Puzzle/**` | Rules separated from presentation; determinism (no unseeded random, no `Time` in decisions, no physics as source of truth); level data model; undo as snapshot; validity + solvability checks |
| `code-health.md` | `Assets/Scripts/**` | One assembly per module; 600/1000-line ceilings; namespace required; no developer-named folders; singleton budget ≤5; dead code deleted; fail loudly not silently; dependency direction; profile with numbers |
| `mobile-code.md` | `Assets/Scripts/**`, `Assets/**` | Mobile budgets (draw calls, GC, triangles, sustained load); **asset-loading matrix by category × MVP mode**; ASTC textures; pooling; safe area; quality tiers |
| `upm-consumption.md` | `Packages/**` | Never fork a CuOCore package into the project; no `file:` refs in shared branches; excluded assemblies must fail loudly; no secrets in manifests; version policy deferred |
| `gameplay-code.md` | `Assets/Scripts/Gameplay/**` | Data-driven values, delta time, no UI references |
| `ui-code.md` | `Assets/Scripts/UI/**` | No game state ownership, localization-ready, accessibility |
| `test-standards.md` | `Assets/Tests/**` | Test naming, arrange/act/assert, **EditMode + PlayMode split**, adapter contract tests, regression test per bug fix |
| `design-docs.md` | `design/gdd/**` | Required sections, formula format, edge cases |
| `data-files.md` | `Assets/Data/**` | JSON validity, naming conventions, schema rules |
| `shader-code.md` | `Assets/Shaders/**` | Naming conventions, performance targets, cross-platform rules |

## Archived

Moved to `.claude/rules/_archived/` — not loaded, kept for reference:

| Rule | Why archived |
|---|---|
| `ai-code.md` | No AI/behaviour-tree systems in a puzzle game |
| `network-code.md` | No multiplayer |
| `narrative.md` | No narrative deliverables in this profile |
| `prototype-code.md` | Superseded by the MVP lane — MVP code is kept, not thrown away |
| `engine-code.md` | Merged into `code-health.md` (dependency direction, optimisation discipline, engine API verification, graceful degradation) |
