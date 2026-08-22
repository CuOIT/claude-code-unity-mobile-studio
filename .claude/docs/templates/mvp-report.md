# MVP Report: [Concept Name]

> **Date**: [YYYY-MM-DD]
> **Mode**: [demo / signal]
> **Concept File**: design/gdd/game-concept.md
> **Code location**: `Assets/Scripts/` — **this code is kept.** Production continues from it.

---

## The Question

[One sentence, written at the start of the run before any code existed.

demo mode: "What must be true for this mechanic to be worth building?"
signal mode: "What number, at what threshold, would make you commit to this game?"]

**Threshold (signal mode only):** [The specific figure agreed up front — day-1 retention,
session length, level-completion rate. If this is vague, the run should have been `demo`.]

---

## Scope

**Core loop as built** (max six steps):
1. [...]

**Deliberately cut, and where it went:**

| Cut | Reason | Deferred to |
|---|---|---|
| [...] | [...] | [...] |

Anything not listed here was not considered. An unlisted cut becomes an assumed feature
later, which is why this table matters more than it looks.

---

## What Was Built vs What Came For Free

**Reused from the CuOCore suite** (not built — see `.claude/docs/cuocore-map.md`):
- [e.g., boot → home → gameplay orchestration, in-level state machine, win/lose/retry
  flow, scene transition, object pooling, UI screen manager, feature-flag system]

**Built for this MVP:**
- [The puzzle rules, level data model, loader and session, level provider — plus adapters
  in signal mode]

**Assemblies added:** [one per module — list them]

---

## Level Representation

**Approach used:** [prefab / spreadsheet / CSV / hybrid]
**Provisional?** [demo mode: yes — `/level-pipeline` has not run yet. signal mode: no.]
**Levels built:** [N]
**Content and ordering separated?** [yes / no — if no, say why and what it costs later]

---

## Verification

Evidence, not assertion. Fill every row or state plainly that it was not run.

| Check | Result |
|---|---|
| EditMode tests | [N passing / N total] |
| PlayMode loop test | [PASS / FAIL / not written] |
| `/mobile-build-check` | [READY / BLOCKED — list errors] |
| Bootstrap order matches registry | [signal only: yes / no] |
| Consent sorts before ads | [signal only: yes / no — this is a store gate] |
| `/feature-flag audit` | [signal only: CLEAN / DRIFT / BROKEN] |
| Ran on device | [device and OS, or "editor only"] |

---

## Play Debrief

**Did it answer the question?** [Yes / No] — [one sentence why]

**What surprised us:**
[...]

**What we wanted to do but could not:**
[...]

**signal mode — the number against the threshold:**
[Measured value vs the Phase 1 threshold. State it even when unflattering.]

---

## Verdict: [PROCEED / PIVOT / KILL]

[One paragraph, grounded in the debrief and verification above. Not a summary of effort —
a judgement about the question.]

---

## If Proceeding

**Tuning values discovered:** [Specific numbers that felt right]
**Assumptions confirmed:** [What the concept assumed that held]
**Assumptions disproved:** [What the concept assumed that did not]
**Emergent behaviour worth keeping:** [What appeared that nobody designed]

**Next steps:**
- demo mode → `/level-pipeline`, then `/puzzle-mvp --mode signal --from-demo`
- signal mode → `/design-system [mvp systems]`, then `/gate-check`

---

## If Pivoting

**What to change:** [Specific, not "make it more fun"]
**What to keep:** [What worked and must survive the pivot]
**Pivot count for this concept:** [N — at 3, force a KILL decision]
**Next step:** `/puzzle-mvp --mode [same mode]`

---

## If Killing

**The signal that decided it:** [Specific observation or number]

A cheap no is the purpose of this lane. Record it plainly; there is nothing to salvage
and no further action on this concept.

**Next step:** `/brainstorm [new direction]`

---

## Debt Taken On Deliberately

Small scope is fine; hidden shortcuts are not. List anything that must be paid down
before Production, so it does not surface as a surprise.

| Shortcut | Where | Must be fixed before |
|---|---|---|
| [...] | [...] | [...] |

---

## Lessons

- **What did building this break in our assumptions?**
- **What did the concept document get wrong?**
- **What would we scope differently next time?**
