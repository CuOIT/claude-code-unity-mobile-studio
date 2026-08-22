---
name: team-puzzle-level
description: "Orchestrate a batch of puzzle levels end to end: puzzle-level-designer + systems-designer + art-director + qa-tester. Covers the level set's teaching intent, rule coverage, visual readability, and solvability verification."
argument-hint: "[level range or set name, e.g. '1-20' or 'chapter-2'] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion
model: sonnet
---

Coordinate a **batch** of puzzle levels rather than one level at a time. A single puzzle
level is rarely worth orchestrating; a set of twenty that must teach in sequence, cover
the rule space, stay readable, and all be solvable is.

**Decision Points:** At each step transition, use `AskUserQuestion` to present the
subagent's proposals as selectable options. Write the agent's full analysis in
conversation, then capture the decision with concise labels. The user approves before the
next step.

## Phase 0: Resolve Review Mode

1. If `--review [mode]` was passed, use it.
2. Else read `production/review-mode.txt`.
3. Else default to `lean`.

- `full` — spawn all director and lead gates
- `lean` — skip director gates unless PHASE-GATE type
- `solo` — skip all gates

Store the resolved mode for all subsequent phases.

## Prerequisites — check before spawning anyone

- `design/gdd/game-concept.md` exists
- The level pipeline ADR exists. **If it does not, stop** and run `/level-pipeline` first —
  authoring a batch before the pipeline is decided means re-authoring it.
- A level validity checker exists, or the user has accepted that solvability is verified
  by hand for this batch.

## The team

| Agent | Owns |
|---|---|
| `puzzle-level-designer` | Level content, teaching order, difficulty curve, solve-time targets |
| `systems-designer` | Whether the rules support the levels being asked for |
| `art-director` | Visual readability — can the player parse the board at a glance |
| `qa-tester` | Solvability verification and the test checklist |

## Step 1: Teaching intent and rule coverage (parallel)

Spawn `puzzle-level-designer` and `systems-designer` **simultaneously**.

`puzzle-level-designer` produces, for the batch:
- What each level teaches, varies, combines, or subverts
- The intended curve: target solve time and expected failure count per level
- Where the batch sits relative to what the player already knows

`systems-designer` produces:
- Which rules the batch exercises, and which rules go untouched
- Any level intent the current rules **cannot** express — surfaced as a gap, not designed around
- Whether any requested difficulty depends on a tuning knob that does not exist yet

**Collect both before proceeding.** If `systems-designer` reports a missing rule, resolve
that first — do not let the level designer invent a workaround for a rule gap.

## Step 2: Visual readability (`art-director`)

Pass Step 1's output as explicit constraints. `art-director` reviews:
- Can the player distinguish every piece type and state at a glance, at phone size?
- Does the hardest level in the batch stay readable, or does it become visual noise?
- Colour-only distinctions that fail for colourblind players
- Whether the board fits the safe area with the HUD present

Readability failures found here are cheap. Found after a hundred levels are authored, they
are not.

## Step 3: Author the batch (`puzzle-level-designer`)

With Steps 1 and 2 as constraints, author the levels. Ask before writing:
"May I write these levels to [path]?"

Every level must have its solution recorded. A level whose solution nobody has written
down is not done.

## Step 4: Solvability and coverage verification (`qa-tester`)

`qa-tester` verifies:
- Every level in the batch parses and passes the validity checker
- Every level has a recorded solution
- The batch's actual difficulty progression matches the intended curve — flag inversions
- No level is solvable by an unintended trivial path
- A test checklist for the batch

**Solvability is a blocking gate.** None of the four reference titles on this machine has
an automated solvability check, and all of them shipped broken levels found by players.
If the checker does not exist, verification is by hand and must be recorded as such.

## Step 5: Curve review

Present the batch's measured curve against the intended curve. Where they diverge, ask
whether to retune the levels or revise the intent.

Because content and ordering are separate (see the level pipeline ADR), retuning the
sequence does not mean re-authoring content. Use that.

## Step 6: Gates (per resolved review mode)

Apply the mode check from Phase 0 before each spawn. See `.claude/docs/director-gates.md`.

- `AD-VISUAL` — art director sign-off on readability
- `CD-PLAYTEST` — if playtest data for this batch exists

## Step 7: Handoff

- Update the level index or ordering data with the new batch
- Record the batch in `production/session-state/active.md`
- Recommend `/playtest-report` once the batch has been played
- If any rule gap was surfaced in Step 1 and left unresolved, state it plainly as an open
  item — do not let it disappear into the batch

## Constraints

- Do not author a batch before the level pipeline is decided.
- Do not design around a missing rule. Surface it to `systems-designer` and stop.
- Do not mark a level done without a recorded solution.
- Difficulty values are data, never constants in rule code.
- One teaching idea per level. A level that teaches two things teaches neither.
