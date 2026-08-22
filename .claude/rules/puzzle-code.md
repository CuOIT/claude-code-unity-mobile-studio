---
paths:
  - "Assets/Scripts/Gameplay/Puzzle/**"
---

# Puzzle Rule Standards (`Assets/Scripts/Gameplay/Puzzle/**`)

The puzzle rules are the one part of this project nothing else can supply. CuOCore
gives the shell — boot, home, gameplay flow, win/lose/retry — but a level is just an
integer to it and the sample "game" is two buttons. Everything here is yours to build,
so build it testable.

## Separate the rules from the presentation

- The rule layer decides *what happened*. The view layer decides *how it looks*.
- Rule code MUST NOT reference `MonoBehaviour` state it does not own, UI types, tween
  libraries, audio, or any service contract. It takes a state, applies a move, returns
  a result.
- A rule function that needs a `Transform` position to decide legality is a design smell.
  Resolve spatial questions into the level data model at load time, then reason over data.
- Presentation reacts to rule results through events or direct calls from the module
  that owns both.

## Determinism is a hard requirement

Rules must produce the same result from the same input, every run.

- No `UnityEngine.Random` without an explicit seed carried in the level or session state.
- No dependence on `Time.time`, `Time.deltaTime`, `DateTime.Now`, or frame count inside
  a rule decision. Timers belong to the session layer and are passed in.
- No dependence on collection enumeration order that is not itself deterministic.
- No physics query as the source of truth for legality. Physics may drive presentation;
  it must not decide whether a move is allowed. A shipped title in this studio resolves
  placement legality with runtime overlap queries and 10-point rim sampling — it works,
  but it is untestable and it is why that title has no automated rule coverage.

If a rule cannot be evaluated in an EditMode test with no scene loaded, it is in the
wrong layer.

## Level data model

- A level is **data**, not a scene graph you interrogate at runtime. Whatever the
  authoring format (`/level-pipeline` decides), it is parsed into an explicit model
  before gameplay begins.
- The model carries everything legality depends on: piece identities, slot identities,
  adjacency or stacking relationships, locks, and win condition parameters.
- Binding by spatial proximity ("claim any piece whose position is inside this radius")
  is forbidden in the model. Bind by identity.
- Level identity and level *order* are separate concerns. Keep the mapping from display
  index to content in data so ordering can change without renaming content.

## Undo

- Undo is a **snapshot**, not an inverse operation. Inverse operations drift.
- Every snapshot type has a test that applies N moves, undoes N times, and asserts the
  state equals the initial state exactly.
- Snapshot what the rules own. Presentation state (tween progress, particle lifetime)
  is rebuilt from the restored rule state, never snapshotted.

## Validity and solvability

- Every level must be machine-checkable for structural validity: no orphan references,
  no piece bound to a nonexistent slot, no unreachable win condition.
- A solvability check is strongly preferred. None of the reference titles has one, and
  all of them ship broken levels found only by players.
- Validation runs in the editor and in CI, not just when a designer remembers to press
  a button.

## Difficulty

- Difficulty parameters are data, never constants in rule code.
- Difficulty tuning must be adjustable without touching level content, so a curve can be
  retuned without re-authoring levels.

## Testing

- EditMode test per rule and per formula. These are cheap and they are the reason this
  layer is isolated.
- PlayMode test for the full loop: load a level, make winning moves, assert win; make
  losing moves, assert lose; retry and assert clean state.
- Boundary tests where the exact number is the point (first move, last piece, full board,
  empty board) may use literal values.
- No test may depend on execution order or on another test's state.
