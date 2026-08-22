---
name: start
description: "First-time onboarding — asks where you are, then guides you to the right workflow. No assumptions."
argument-hint: "[no arguments]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion
model: sonnet
---

# Guided Onboarding

This skill writes one file: `production/review-mode.txt` (review mode config set in Phase 3b).

This skill is the entry point for new users. It does NOT assume you have a game idea, an engine preference, or any prior experience. It asks first, then routes you to the right workflow.

---

## Phase 1: Detect Project State

Before asking anything, silently gather context so you can tailor your guidance. Do NOT show these results unprompted — they inform your recommendations, not the conversation opener.

Check:
- **Engine configured?** Read `.claude/docs/technical-preferences.md`. If the Engine field contains `[TO BE CONFIGURED]`, the engine is not set.
- **Game concept exists?** Check for `design/gdd/game-concept.md`.
- **Source code exists?** Glob for source files in `Assets/Scripts/` (`*.gd`, `*.cs`, `*.cpp`, `*.h`, `*.rs`, `*.py`, `*.js`, `*.ts`).
- **Prototypes exist?** Check for subdirectories in `prototypes/`.
- **Design docs exist?** Count markdown files in `design/gdd/`.
- **Production artifacts?** Check for files in `production/sprints/` or `production/milestones/`.

Store these findings internally to validate the user's self-assessment and tailor recommendations.

---

## Phase 2: Ask Where the User Is

This is the first thing the user sees. Use `AskUserQuestion` with these exact options so the user can click rather than type:

- **Prompt**: "Welcome to Claude Code Game Studios! Before I suggest anything, I'd like to understand where you're starting from. Where are you at with your game idea right now?"
- **Options**:
  - `A) No idea yet` — I don't have a game concept at all. I want to explore and figure out what to make.
  - `B) Vague idea` — I have a rough theme, feeling, or genre in mind (e.g., "something with space" or "a cozy farming game") but nothing concrete.
  - `C) Clear concept` — I know the core idea — genre, basic mechanics, maybe a pitch sentence — but haven't formalized it into documents yet.
  - `D) Existing work` — I already have design docs, prototypes, code, or significant planning done. I want to organize or continue the work.

Wait for the user's selection. Do not proceed until they respond.

---

## Phase 3: Route Based on Answer

#### If A: No idea yet

The user needs creative exploration before anything else.

1. Acknowledge that starting from zero is completely fine
2. Briefly explain what `/brainstorm` does (guided ideation using professional frameworks — MDA, player psychology, verb-first design). Mention that it has two modes: `/brainstorm open` for fully open exploration, or `/brainstorm [hint]` if they have even a vague theme (e.g., "space", "cozy", "horror").
3. Recommend running `/brainstorm open` as the next step, but invite them to use a hint if something comes to mind
4. Show the recommended path:
   **Concept phase** — two artifacts, then you build:
   - `/setup-engine` — record conventions, platform, and budgets
   - `/brainstorm open` — discover the concept and write `design/gdd/game-concept.md`

   **MVP phase** — this is where a playable build appears:
   - `/puzzle-mvp --mode demo` — one scene, no SDKs, 3–5 hand-built levels.
     Answers "is this mechanic worth building?" Ends in PROCEED / PIVOT / KILL.
   - `/gate-check mvp` — the verdict gate. KILL and PIVOT are successful outcomes here.
   - `/level-pipeline` — now that the mechanic is known, decide how levels are authored
   - `/sdk-integrate consent` then `ads tracking` — adapters, consent first
   - `/feature-flag add [id]` — one per switchable feature
   - `/puzzle-mvp --mode signal` — promote to a soft-launch build (optional but recommended)

   **Systems Design phase** — document what the MVP proved:
   - `/design-system` — a GDD per MVP-tier system
   - `/review-all-gdds` — cross-system consistency check

   **Technical Setup phase:**
   - `/create-architecture` — document the architecture as built
   - `/architecture-decision (×4+)` — adapter boundary, flag mechanism, level pipeline, event channels
   - `/test-setup` — formalise the test structure the MVP started

   **Production phase:**
   - `/create-epics` then `/create-stories` — the MVP report's deferred-scope list is the backlog
   - `/sprint-plan` — plan the first sprint
   - `/dev-story` — pick up stories
   - `/ux-design` — document and refine the screens the MVP already built

   > Art bible, UX specs, and accessibility requirements are all real work — they are
   > sequenced after the MVP verdict because a mechanic that does not work makes them
   > wasted. Run `/art-bible` whenever asset production is about to start.

#### If B: Vague idea

1. Ask them to share their vague idea — even a few words is enough
2. Validate the idea as a starting point (don't judge or redirect)
3. Recommend running `/brainstorm [their hint]` to develop it
4. Show the recommended path:
   **Concept phase:**
   - `/brainstorm [hint]` — develop the idea into a full concept
   - `/setup-engine` — configure the engine
   **MVP phase** — this is where a playable build appears:
   - `/puzzle-mvp --mode demo` — one scene, no SDKs, 3–5 hand-built levels.
     Answers "is this mechanic worth building?" Ends in PROCEED / PIVOT / KILL.
   - `/gate-check mvp` — the verdict gate. KILL and PIVOT are successful outcomes here.
   - `/level-pipeline` — now that the mechanic is known, decide how levels are authored
   - `/sdk-integrate consent` then `ads tracking` — adapters, consent first
   - `/feature-flag add [id]` — one per switchable feature
   - `/puzzle-mvp --mode signal` — promote to a soft-launch build (optional but recommended)

   **Systems Design phase** — document what the MVP proved:
   - `/design-system` — a GDD per MVP-tier system
   - `/review-all-gdds` — cross-system consistency check

   **Technical Setup phase:**
   - `/create-architecture` — document the architecture as built
   - `/architecture-decision (×4+)` — adapter boundary, flag mechanism, level pipeline, event channels
   - `/test-setup` — formalise the test structure the MVP started

   **Production phase:**
   - `/create-epics` then `/create-stories` — the MVP report's deferred-scope list is the backlog
   - `/sprint-plan` — plan the first sprint
   - `/dev-story` — pick up stories
   - `/ux-design` — document and refine the screens the MVP already built

   > Art bible, UX specs, and accessibility requirements are all real work — they are
   > sequenced after the MVP verdict because a mechanic that does not work makes them
   > wasted. Run `/art-bible` whenever asset production is about to start.

#### If C: Clear concept

1. Ask them to describe their concept in one sentence — genre and core mechanic. Use plain text, not AskUserQuestion (it's an open response).
2. Acknowledge the concept, then use `AskUserQuestion` to offer two paths:
   - **Prompt**: "How would you like to proceed?"
   - **Options**:
     - `Formalize it first` — Run `/brainstorm [concept]` to structure it into a proper game concept document
     - `Jump straight in` — Go to `/setup-engine` now and write the GDD manually afterward
3. Show the recommended path:
   **Concept phase:**
   - `/brainstorm` or `/setup-engine` — (their pick from step 2)
   **MVP phase** — this is where a playable build appears:
   - `/puzzle-mvp --mode demo` — one scene, no SDKs, 3–5 hand-built levels.
     Answers "is this mechanic worth building?" Ends in PROCEED / PIVOT / KILL.
   - `/gate-check mvp` — the verdict gate. KILL and PIVOT are successful outcomes here.
   - `/level-pipeline` — now that the mechanic is known, decide how levels are authored
   - `/sdk-integrate consent` then `ads tracking` — adapters, consent first
   - `/feature-flag add [id]` — one per switchable feature
   - `/puzzle-mvp --mode signal` — promote to a soft-launch build (optional but recommended)

   **Systems Design phase** — document what the MVP proved:
   - `/design-system` — a GDD per MVP-tier system
   - `/review-all-gdds` — cross-system consistency check

   **Technical Setup phase:**
   - `/create-architecture` — document the architecture as built
   - `/architecture-decision (×4+)` — adapter boundary, flag mechanism, level pipeline, event channels
   - `/test-setup` — formalise the test structure the MVP started

   **Production phase:**
   - `/create-epics` then `/create-stories` — the MVP report's deferred-scope list is the backlog
   - `/sprint-plan` — plan the first sprint
   - `/dev-story` — pick up stories
   - `/ux-design` — document and refine the screens the MVP already built

   > Art bible, UX specs, and accessibility requirements are all real work — they are
   > sequenced after the MVP verdict because a mechanic that does not work makes them
   > wasted. Run `/art-bible` whenever asset production is about to start.

#### If D: Existing work

1. Share what you found in Phase 1:
   - "I can see you have [X source files / Y design docs / Z prototypes]..."
   - "Your engine is [configured as X / not yet configured]..."

2. **Sub-case D1 — Early stage** (engine not configured or only a game concept exists):
   - Recommend `/setup-engine` first if engine not configured
   - Then `/project-stage-detect` for a gap inventory

   **Sub-case D2 — GDDs, ADRs, or stories already exist:**
   - Explain: "Having files isn't the same as the template's skills being able to use them. GDDs might be missing required sections. `/project-stage-detect` checks this specifically."
   - Recommend:
     1. `/project-stage-detect` — understand what phase and what's missing entirely
     2. `/project-stage-detect` — audit what exists and what is missing

3. Show the recommended path for D2:
   - `/project-stage-detect` — phase detection + existence gaps
   - `/project-stage-detect` — full project audit + recommended next steps
   - `/setup-engine` — if engine not configured
   - `/design-system retrofit [path]` — fill missing GDD sections
   - `/architecture-decision retrofit [path]` — add missing ADR sections
   - `/architecture-review` — bootstrap the TR requirement registry
   - `/gate-check` — validate readiness for next phase

---

## Phase 3c: Write Initial Stage File

After confirming the starting path (and before asking about review mode), write the initial stage to `production/stage.txt`. Create the `production/` directory if it does not exist.

Stage mapping:
- **Path A, B, or C (starting from scratch)**: write `Concept`
- **Path D, existing project, engine not configured or only a game concept exists**: write `Concept`
- **Path D, existing project with GDDs but no architecture documents**: write `Systems Design`
- **Path D, existing project with full architecture (ADRs, architecture doc)**: write `Technical Setup`

Do this silently — no "May I write?" needed for this single-line file.

Say: "I've set `production/stage.txt` to `[stage]` — this anchors your status line and stage detection."

---

## Phase 3b: Set Review Mode

Check if `production/review-mode.txt` already exists.

**If it exists**: Read it and show the current mode — "Review mode is set to `[current]`." — then proceed to Phase 4. Do not ask again.

**If it does not exist**: Use `AskUserQuestion`:

- **Prompt**: "One setup choice: how much design review would you want as you work through the workflow?"
- **Options**:
  - `Full` — Director specialists review at each key workflow step. Best for teams, learning the workflow, or when you want thorough feedback on every decision.
  - `Lean (recommended)` — Directors only at phase gate transitions (/gate-check). Skips per-skill reviews. Balanced approach for solo devs and small teams.
  - `Solo` — No director reviews at all. Maximum speed. Best for game jams, prototypes, or if the reviews feel like overhead.

Write the choice to `production/review-mode.txt` immediately after the user
selects — no separate "May I write?" needed, as the write is a direct
consequence of the selection:
- `Full` → write `full`
- `Lean (recommended)` → write `lean`
- `Solo` → write `solo`

Create the `production/` directory if it does not exist.

---

## Phase 4: Confirm Before Proceeding

After presenting the recommended path, use `AskUserQuestion` to ask the user which step they'd like to take first. Never auto-run the next skill.

- **Prompt**: "Would you like to start with [recommended first step]?"
- **Options**:
  - `Yes, let's start with [recommended first step]`
  - `I'd like to do something else first`

---

## Phase 5: Hand Off

When the user confirms their next step, respond with a single short line: "Type `[skill command]` to begin." Nothing else. Do not re-explain the skill or add encouragement. The `/start` skill's job is done.

Verdict: **COMPLETE** — user oriented and handed off to next step.

---

## Edge Cases

- **User picks D but project is empty**: Gently redirect — "It looks like the project is a fresh template with no artifacts yet. Would Path A or B be a better fit?"
- **User picks A but project has code**: Mention what you found — "I noticed there's already code in `Assets/Scripts/`. Did you mean to pick D (existing work)?"
- **User is returning (engine configured, concept exists)**: Skip onboarding entirely — "It looks like you're already set up! Your engine is [X] and you have a game concept at `design/gdd/game-concept.md`. Review mode: `[read from production/review-mode.txt, or 'lean (default)' if missing]`. Want to pick up where you left off? Try `/sprint-plan` or just tell me what you'd like to work on."
- **User doesn't fit any option**: Let them describe their situation in their own words and adapt.

---

## Collaborative Protocol

1. **Ask first** — never assume the user's state or intent
2. **Present options** — give clear paths, not mandates
3. **User decides** — they pick the direction
4. **No auto-execution** — recommend the next skill, don't run it without asking
5. **Adapt** — if the user's situation doesn't fit a template, listen and adjust
