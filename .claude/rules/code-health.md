---
paths:
  - "Assets/Scripts/**"
---

# Code Health Standards (`Assets/Scripts/**`)

Every rule here was written against a specific failure observed in a shipped title on
this machine. They are cheap to follow from day one and expensive to retrofit.

## One assembly per module

- Every module under `Assets/Scripts/` has its own assembly definition. From the first commit,
  not "once it gets big".
- The CuOCore suite already does this (roughly one assembly per package). **Do not
  regress it** by dropping game code into a single catch-all assembly.
- Reference: the largest shipped title in this studio compiles 1199 first-party scripts
  into one assembly, giving a 200 KB project file and a full recompile on every edit.
  Two other titles have zero first-party assemblies.
- Assembly references are also how the service boundary is enforced — see
  `.claude/rules/service-layer.md`. A module structure with no assemblies has no
  enforceable boundaries at all.

## File size ceiling

- **600 lines: WARNING.** Consider splitting.
- **1000 lines: ERROR.** Split before merging.
- Observed in shipped titles: 4693, 2805, 1856, and 1496-line files. Each is a class
  nobody can safely change, and each started under 600 lines.
- A partial class spread across one physical file does not count as splitting.

## Namespaces

- Every file declares a namespace. No exceptions.
- Four CuOCore packages declare none, so their types sit in the global namespace and can
  collide with game code. Do not add to that surface.

## Folder structure follows the system, not the author

- Folders are named after what is inside them: `Board`, `Pieces`, `Boosters`, `Services`.
- **Never name a folder after a developer.** One shipped title has five such folders in
  its source tree, and finding anything in it requires knowing who wrote it.
- Feature code lives with its feature. Shared infrastructure lives in a clearly shared
  location, not inside whichever feature happened to need it first.

## Singleton budget

- At most five singletons in the project, each justified in an ADR.
- Prefer the CuOCore service registry with explicit registration at the composition root.
- Reference: one shipped title has three separate singleton base classes plus 38
  hand-rolled `static Instance` properties. Initialisation order became unknowable.

## Dead code does not stay

- Commented-out code is deleted, not left as documentation. Git remembers it.
- Observed: a 522-line fully commented-out purchase manager sitting beside the live one,
  and an orphaned scripting define referencing a mediation SDK that is not installed.
- Orphaned define symbols, unused packages, and unreferenced assets are technical debt.
  `/tech-debt` surfaces them at phase gates.

## Failing loudly beats failing silently

- Code excluded from a build by a `#if` guard must be *visible* as excluded. A capability
  that silently is not there is worse than a compile error.
- Reference: an adapter in the CuOCore template is currently compiled out by its guard.
  No error, no warning — the feature simply does not exist, and nothing says so.
- Where a guard controls an optional capability, provide a Null implementation and a
  startup log line stating which implementation is active.

## Public API

- Public members on shared types get doc comments. Internal helpers do not need them.
- Prefer `internal` by default; make something `public` when another assembly needs it.
- Gameplay values are data-driven, never hardcoded constants in behaviour classes.
- Changing a public signature another assembly depends on needs a deprecation path, not
  a silent break.

## Dependency direction

- Core and service code MUST NOT depend on gameplay code. The arrow points one way:
  gameplay → services → abstractions. Never back.
- A core type that knows about a specific puzzle mechanic is misplaced.

## Optimisation discipline

- Profile before AND after every optimisation, and record the measured numbers in the
  commit or the story. "Felt faster" is not a result.
- Device measurement is the only real measurement. Editor profiling hides mobile cost.
- No speculative optimisation. An unmeasured optimisation is a guess that costs
  readability for nothing.

## Engine API verification

- Before using an engine API you have not seen used elsewhere in this project, verify it
  against the installed version. Grep the codebase first, then the docs for that release.
- Never state or assume an API signature or a version from memory. If you cannot verify,
  say so and ask. See `docs/engine-reference/unity/VERSION.md`.

## Graceful degradation

- A missing optional capability degrades; it does not crash. Absent SDK, absent remote
  config, absent network, absent optional package — each has a defined fallback.
- Resource cleanup is deterministic. Dispose what you acquire, in the scope that acquired it.
