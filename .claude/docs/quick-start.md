# Quick Start

Orientation for a new session. This file deliberately stays short and points at the
canonical sources rather than copying them — a duplicated list is a list that drifts.

## What Is This?

A Claude Code configuration for building a **mobile puzzle game** on Unity 6, on top of
the in-house **CuOCore** UPM suite. 27 agents, 58 slash commands, 12 path-scoped rules,
and 15 hooks, arranged around three priorities: get to a playable MVP early, make SDK
integration cheap, and make every feature switchable.

## Read these first, in order

| # | File | Why |
|---|---|---|
| 1 | `CLAUDE.md` | Master config; imports the rest |
| 2 | `.claude/docs/cuocore-map.md` | **What already exists.** Most infrastructure is already a tested contract. Read this before proposing any service or manager code |
| 3 | `.claude/docs/puzzle-profile.md` | The active profile, and the anti-pattern table every rule traces back to |
| 4 | `.claude/docs/technical-preferences.md` | Conventions, budgets, forbidden patterns |
| 5 | `docs/registry/services.yaml` | Which adapters exist and which are missing |
| 6 | The rule file matching whatever you are about to edit | `.claude/docs/rules-reference.md` maps path → rule |

## The one thing that shapes everything

**CuOCore supplies tested contracts and Null implementations. It contains no vendor SDK
code.** So the work is adapters, not interfaces. Writing a parallel interface for
something that already has a contract is the most likely way to waste effort here.

## Where to start, by situation

| Situation | Start with |
|---|---|
| Nothing exists yet | `/start` |
| Concept is clear, want something playable | `/setup-engine` → `/brainstorm` → `/puzzle-mvp --mode demo` |
| MVP exists, want a market read | `/level-pipeline` → `/sdk-integrate consent` → `/puzzle-mvp --mode signal` |
| Not sure where the project stands | `/project-stage-detect` |
| Not sure what to do next | `/help` |

**Two artifacts gate the first line of gameplay code:** `technical-preferences.md` and
`design/gdd/game-concept.md`. The MVP phase then produces `production/mvp-report.md`,
which gates everything after it. Art bible, UX specs, per-system GDDs, and architecture
review are all real work — they are sequenced *after* the MVP verdict, because a mechanic
that does not work makes all of them wasted.

## Canonical references

| For | See |
|---|---|
| Which agent to use | `.claude/docs/agent-roster.md` — includes routing shortcuts |
| Which slash command to use | `.claude/docs/skills-reference.md` |
| The phase sequence and what each phase requires | `.claude/docs/workflow-catalog.yaml` |
| Which rule applies to a path | `.claude/docs/rules-reference.md` |
| Gate prompts and verdicts | `.claude/docs/director-gates.md` |
| Document templates | `.claude/docs/templates/` |
| Directory layout and assembly boundaries | `.claude/docs/directory-structure.md` |
| Engine and SDK capabilities | `docs/engine-reference/unity/VERSION.md` |
| Mobile budgets and platform gotchas | `docs/engine-reference/unity/MOBILE-BEST-PRACTICES.md` |

## Rules that are never negotiable

These are not style preferences. Each one exists because the failure it prevents was
observed in real shipped code — see the anti-pattern table in `puzzle-profile.md`.

- **Consent resolves before ads initialise.** A store gate. Nothing upstream enforces it.
- **Vendor SDK types stay inside adapter assemblies.** Enforced by assembly references, so
  a leak is a compile error.
- **Every feature flag read in code is declared in the registry.** An undeclared flag
  resolves to `false` on device silently.
- **Never fork a CuOCore package into the project.** Consume via UPM.
- **Puzzle rules are deterministic and testable with no scene loaded.**
- **One assembly per module, from the first commit.**

## Collaboration protocol

Every task follows **Question → Options → Decision → Draft → Approval**.

Agents ask "May I write this to [filepath]?" before writing. Multi-file changes need
approval for the full changeset. No commits without instruction.

## Version policy

This project records **capabilities**, not pinned versions. Read the Unity release from
`ProjectSettings/ProjectVersion.txt` and package versions from `Packages/manifest.json`
when they matter. Never state a version from memory, and never carry one from another
project.
