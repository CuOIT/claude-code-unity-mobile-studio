---
name: level-pipeline
description: "Decide and scaffold how puzzle levels are authored, stored, and loaded. Presents the three approaches proven in this studio's shipped titles with their real costs, produces an ADR, and scaffolds the loader and validation tooling."
argument-hint: "[--decide|--scaffold] [prefab|excel|csv|hybrid]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Task
model: sonnet
---

# Level Pipeline

How levels get authored, stored, ordered, and loaded. This is the largest greenfield
decision in the project — the CuOCore template treats a level as a bare integer and its
sample "game" is two buttons, so everything here is yours to build.

Run this **after** the core mechanic is known (during or just after `/puzzle-mvp --mode
demo`) and **before** any level content is authored at volume. Changing the pipeline after
200 levels exist is expensive.

## How to Run

```
/level-pipeline                      # decide, then scaffold
/level-pipeline --decide             # decision + ADR only
/level-pipeline --scaffold prefab    # scaffold an already-decided approach
```

---

## Phase 1: Understand the mechanic first

The right pipeline depends on what a level actually *is*. Read the concept and any
existing puzzle rule code, then determine:

- **Is the level spatial or tabular?** Free-placed pieces with geometry, or cells on a grid?
- **Does physics participate?** If bodies fall, collide, or settle, the authored layout
  needs visual verification.
- **How many levels will ship?** Tens, hundreds, or over a thousand.
- **Who authors them?** A designer inside Unity, or someone who should never open Unity.
- **Will level ordering change after release?** A/B testing the sequence, or difficulty retuning?

If the mechanic is not yet settled, **stop**. Say so and recommend finishing the MVP demo
first. A pipeline chosen before the mechanic is a guess.

## Phase 2: Present the three proven approaches

All three are running in shipped titles on this machine. Present the real trade-offs, not
a generic comparison. Use `AskUserQuestion`.

### Prefab per level
One prefab per level; the hierarchy *is* the level. Ordering held separately in data.

- **Proven at**: 508 prefabs in one title, 1398 in another.
- **Strong when**: geometry is free-placed, physics participates, layout needs to be seen
  to be judged.
- **Costs**: repository weight; a level cannot be reviewed in a diff; content and ordering
  must be deliberately separated or A/B testing becomes impossible.
- **Note**: the proven titles bind pieces to slots by *spatial proximity at runtime*.
  `.claude/rules/puzzle-code.md` forbids that — bind by identity in the parsed model.
  Keep the visual authoring, drop the runtime-overlap legality checks.

### Spreadsheet → ScriptableObject
Designers author in a spreadsheet; an importer bakes it into an asset.

- **Proven at**: 170 levels on a fixed grid in one title; another uses it for level
  *ordering and metadata* alongside prefab geometry.
- **Strong when**: levels are tabular, and whoever authors them should not need Unity.
- **Costs**: no importer exists anywhere in the CuOCore suite — zero spreadsheet, CSV, or
  importer code. It must be built or ported. Poor fit for free-placed geometry.

### CSV + a grid-painter editor window
Levels as text; a custom editor window paints them and play-tests in place.

- **Proven at**: 40 unique levels behind a 4193-line editor window in one title.
- **Strong when**: levels are grid-based and iteration speed matters most; in-editor
  play-test from the painter is the fastest authoring loop of the three.
- **Costs**: the largest upfront build. **There is no `EditorWindow` anywhere in the
  CuOCore suite** — every editor tool is a custom inspector or a menu item. This is
  entirely from scratch.

### Hybrid — prefab geometry + data ordering
Geometry as prefabs; order, difficulty, and metadata as imported data.

- **Proven at**: the studio's largest shipped title, with five parallel level sets
  switched remotely.
- **Strong when**: you want visual authoring *and* the ability to retune sequence or
  difficulty without touching content, including after release.
- **Costs**: two pipelines to maintain.

**Default recommendation: prefab per level**, with content and ordering separated from day
one so the hybrid remains available later without rework. Recommend hybrid directly if
remote A/B testing of level order is already a known requirement.

## Phase 3: Separate content from ordering — always

Whichever approach is chosen, enforce this:

- **Level identity** (which content) and **level order** (which position) are different
  concerns, stored separately.
- Display index → content id is a data mapping, so re-sequencing never means renaming files.
- Define behaviour past the last authored level explicitly. Shipped titles wrap into an
  earlier range; that is a design decision, not a default. Decide it now and record it.

## Phase 4: Define the level data model

Regardless of authoring format, levels are parsed into an explicit model before gameplay.
Specify it:

- Piece identities, slot identities, and the relationships legality depends on
  (adjacency, stacking, locks)
- Win condition parameters
- Difficulty parameters — **data, never constants in rule code**
- The seed, if any randomness participates

`.claude/rules/puzzle-code.md` is binding here: no spatial-proximity binding in the model,
no physics as the source of truth for legality, deterministic evaluation with no scene loaded.

## Phase 5: ADR

Write an ADR through `/architecture-decision` covering: the approach chosen and why, the
alternatives rejected with their real costs, the content/ordering separation, past-last-level
behaviour, and the data model. Register the decision id in `docs/registry/services.yaml`
against `IGameplayLoader` and `IGameplayLevelProvider`.

## Phase 6: Scaffold

Produce, asking before each write:

1. **The level data model** — plain types, no `MonoBehaviour`, no Unity dependency in the
   model itself so it is testable with no scene.
2. **`IGameplayLoader`** — parses the authored format into the model and produces a session.
3. **`IGameplayLevelProvider`** — persistent current-level tracking with a real content
   bound. The upstream sample is in-memory and increments without limit; do not ship that.
4. **A validity checker** — every level parses, no orphan references, win condition
   reachable. Runs in the editor **and** in CI, not only when a designer remembers.
5. **EditMode tests** — the model parses a known fixture; the validator rejects a known
   bad fixture.

Update `docs/registry/services.yaml`: `IGameplayLoader` and `IGameplayLevelProvider` move
from `missing` toward `partial` or `exists`.

## Phase 7: Recommend a solvability check

None of the four shipped titles on this machine has one, and all of them shipped levels
that were only found to be broken by players. Recommend it explicitly, scoped to the
mechanic. If the puzzle has a tractable state space, a brute-force solver used only in
the editor and CI pays for itself the first time it catches an unsolvable level.

Do not build it in this run unless asked — record it as a follow-up.

---

## Constraints

- Do not choose a pipeline before the mechanic is known.
- Do not author level content at volume before the validator exists.
- Do not put difficulty constants in rule code.
- Do not bind pieces to slots by runtime position — bind by identity in the model.
- Do not let the level model depend on Unity types. If it cannot be tested in EditMode
  with no scene loaded, it is in the wrong layer.
