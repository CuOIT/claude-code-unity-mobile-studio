---
name: puzzle-mvp
description: "Build a playable mobile puzzle MVP on the CuOCore suite. Two modes: demo prioritises speed to something demonstrable; signal wires real SDKs and flags to run on device and gather real signal. Unlike a prototype, this code is KEPT — Production continues from it."
argument-hint: "[--mode demo|signal] [--from-demo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion, Task
model: sonnet
---

# Puzzle MVP

The fastest honest path from a concept to something you can hold and judge.

**This is not a prototype.** Prototype code is throwaway by design; MVP code is the seed
of the real game. The architecture is correct from the first line — the *scope* is what
is small, not the quality. Production continues from this code, it does not replace it.

Required before running: `.claude/docs/technical-preferences.md` filled in, and a game
concept at `design/gdd/game-concept.md`. That is the whole prerequisite list.

Read first: `.claude/docs/cuocore-map.md`. Most of the shell already exists.

## Two modes

| | `demo` | `signal` |
|---|---|---|
| **Question it answers** | "Is this mechanic worth building?" | "Will real players play it, and will it earn?" |
| Scenes | One | Three (boot / home / gameplay), from the upstream sample |
| Adapters | Null only — no SDKs at all | Real adapters wired |
| Feature flags | Local defaults only | All three tiers live |
| Progress | In memory | Persisted |
| Meta systems | None | Minimum viable: progress, one currency |
| Levels | 3–5 hand-built | Enough to reach a retention read |
| Consent | Not applicable | **Required** — store gate |
| Ends in | A feel judgement | A soft-launch build |

Both modes use the same contracts. Moving `demo` → `signal` changes which adapters the
composition root registers. It is not a rewrite. Run `/puzzle-mvp --mode signal --from-demo`
to promote an existing demo rather than starting over.

## How to Run

```
/puzzle-mvp                              # ask which mode, then run
/puzzle-mvp --mode demo
/puzzle-mvp --mode signal
/puzzle-mvp --mode signal --from-demo    # promote an existing demo
```

---

## Phase 1: Frame the question

Ask for one sentence, in plain text, not a widget:

- `demo` → "What must be true for this mechanic to be worth building?"
- `signal` → "What number, at what threshold, would make you commit to this game?"

For `signal`, push for a real threshold — a day-1 retention figure, a session length, a
level-completion rate. "See how it feels" is not a signal; it is what `demo` already
answered. If the user cannot name a threshold, say so and recommend `demo` instead.

Write the question into the report skeleton immediately (Phase 8).

## Phase 2: Scope the core loop to one screen of text

Read `design/gdd/game-concept.md`. Restate the loop as a numbered list of at most six
steps, then get agreement.

Then cut. For each element, ask whether the Phase 1 question can be answered without it.
Anything that survives is in scope; everything else is explicitly deferred and listed in
the report. Name the cuts out loud — an unlisted cut becomes an assumed feature later.

`demo` mode has no meta systems. No currency, no boosters, no daily reward, no shop, no
progression curve. If the mechanic needs a booster to be fun, that is a finding about the
mechanic, not a reason to widen scope.

## Phase 3: Confirm what you are NOT building

State plainly, so it is not rebuilt by reflex. From `.claude/docs/cuocore-map.md`, the
suite already provides: boot → home → gameplay orchestration, the in-level state machine
(loading / playing / paused / resolving-lose / showing-result / exiting), win / lose /
retry / revive / pause / quit flow, scene transition with a loading overlay, a heart-gated
entry pipeline, interstitial insertion points, object pooling, a UI screen manager with
per-type pooling, audio, haptics, inventory, cloud save, and the feature-flag system.

The sample also ships three scenes, eleven panel prefabs, a UI registry asset, and one
end-to-end PlayMode test.

**What is genuinely yours to build:** the puzzle rules, the level data model, the level
loader and session, and a persistent level provider. In `signal` mode, add the adapters.

If you catch yourself writing a manager for anything in the first list, stop and read the
map again.

## Phase 4: Decide the level representation (minimally)

`demo` mode does **not** run `/level-pipeline` — that is a decision for when the mechanic
is known, which is what this run is establishing. Instead pick the cheapest thing that
holds 3–5 hand-built levels, and record that it is provisional.

Default: prefabs, geometry authored by hand, parsed into an explicit model at load.

The model constraint applies from the start, because it is what makes the rules testable:
bind pieces to slots **by identity, not by runtime position**; no physics query as the
source of truth for legality; deterministic evaluation with no scene loaded. See
`.claude/rules/puzzle-code.md`.

`signal` mode requires `/level-pipeline` to have run.

## Phase 5: Build

Ask before each write: "May I write this to [filepath]?"

### Both modes — the puzzle layer first

1. **The level data model** — plain types, no Unity dependency. Testable with no scene.
2. **The rules** — takes a state and a move, returns a result. No `MonoBehaviour` state it
   does not own, no UI types, no tweens, no audio, no service references.
3. **EditMode tests for the rules** — write these alongside, not after. They are the reason
   the layer is isolated, and they are cheap only while the layer is small.
4. **`IGameplaySession` + `IGameplayLoader`** — the bridge from the model into the upstream
   flow machine.
5. **Presentation** — reacts to rule results. Thin. It may be ugly; it may not be smart.

### `demo` mode

6. One scene. Direct asset references, no `Resources`, no registry indirection.
7. Register **Null adapters only** in the composition root. No SDK packages installed.
8. Hand-build 3–5 levels spanning easy → hard enough to be interesting.
9. Stop. No home screen, no persistence, no currency, no polish pass.

### `signal` mode

6. Start from the upstream sample rather than building scenes: three scenes, the panel
   prefabs, the UI registry, and the end-to-end PlayMode test come with it.
7. **A persistent level provider.** The sample's is in-memory and increments without
   bound. Replace it: real persistence, a real content bound, and an explicit decision
   about what happens past the last authored level.
8. **Consent adapter first**, via `/sdk-integrate consent`. Before ads. Non-negotiable —
   see `.claude/rules/service-layer.md`.
9. **Then** `/sdk-integrate ads tracking`. IAP only if the Phase 1 threshold is monetary.
10. **Feature flags** via `/feature-flag add` for every switchable feature. Ads and IAP
    each need a kill-switch. Default everything unproven to **off**.
11. **Safe area** on the HUD. Never anchor to absolute screen corners.
12. One PlayMode test covering the full loop on top of the sample's.

## Phase 6: Verify it actually runs

Do not report a working MVP without evidence.

- EditMode tests pass — state the count.
- The PlayMode loop test passes.
- `/mobile-build-check` returns READY, or its errors are listed as known.
- `signal` mode additionally: the bootstrap order in the composition root matches
  `docs/registry/services.yaml`, with consent sorting before ads; `/feature-flag audit`
  returns CLEAN or DRIFT, never BROKEN.

If something does not pass, say so with the output. A reported-working MVP that does not
run is worse than an honest failure.

## Phase 7: Play it, then debrief

The developer plays it. Then, in plain text:

- Did it answer the Phase 1 question? Yes or no, and why in one sentence.
- What surprised you?
- What did you want to do that you could not?
- `signal` mode: what does the number say against the threshold you set?

Do not lead the answers. A `demo` that reveals the mechanic is flat has done its job
correctly and cheaply.

## Phase 8: Report and verdict

Write `production/mvp-report.md` using `.claude/docs/templates/mvp-report.md`. Create the
skeleton at Phase 1 and fill it as you go, so a crash or compaction loses nothing.

Verdict:

| Verdict | Meaning | Next |
|---|---|---|
| **PROCEED** | The question is answered yes | `demo` → `/level-pipeline` then `--mode signal`. `signal` → systems design and Production. |
| **PIVOT** | The core is interesting, the shape is wrong | Name the specific change. Re-run the same mode. |
| **KILL** | The question is answered no | Say so plainly. A cheap no is the point of this lane. |

Three PIVOT verdicts on one concept forces a KILL decision. Two or three different
concepts, each built cheaply, beat four iterations of one struggling concept.

## Phase 9: Update state

- `production/session-state/active.md` — verdict, kept code paths, next step
- `docs/registry/services.yaml` — any adapter status that changed
- `docs/registry/feature-flags.yaml` — any flag added

Recommend `/gate-check` before Production. Do not advance the phase yourself.

---

## Constraints

- **The code is kept.** Do not write throwaway shortcuts you would be unwilling to build
  on. Small scope, correct structure.
- **Do not rebuild the shell.** Read `.claude/docs/cuocore-map.md` first, every time.
- Puzzle rules stay deterministic and scene-free from the first commit. Retrofitting
  testability into physics-driven legality checks is the expensive mistake this avoids —
  it is why the closest shipped title in this studio has no automated rule coverage.
- One assembly per module from the start. Two shipped titles have zero, and neither can
  enforce any boundary as a result.
- `demo` mode installs no SDK packages. Not "installed but disabled" — absent.
- Never report PROCEED without the Phase 6 evidence.
- No commits without instruction.
