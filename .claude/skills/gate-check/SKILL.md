---
name: gate-check
description: "Validate readiness to advance between development phases. Produces a PASS/CONCERNS/FAIL verdict with specific blockers and required artifacts. Use when user says 'are we ready to move to X', 'can we advance to production', 'check if we can start the next phase', 'pass the gate'."
argument-hint: "[target-phase: mvp | systems-design | technical-setup | production | polish | release] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Task, AskUserQuestion
model: opus
---

# Phase Gate Validation

This skill validates whether the project is ready to advance to the next development
phase. It checks for required artifacts, quality standards, and blockers.

**Distinct from `/project-stage-detect`**: That skill is diagnostic ("where are we?").
This skill is prescriptive ("are we ready to advance?" with a formal verdict).

## Production Stages (7)

The project progresses through these stages:

1. **Concept** — Conventions configured, game concept document written
2. **MVP** — A playable build exists and has been judged. Level pipeline, adapters, and
   feature flags land here. **MVP code is kept** — Production continues from it.
3. **Systems Design** — GDDs for the systems the MVP proved, plus the meta it deferred
4. **Technical Setup** — Architecture documented, ADRs recorded
5. **Production** — Feature development (Epic/Feature/Task tracking active)
6. **Polish** — Performance, device testing, playtesting, bug fixing
7. **Release** — Store readiness, certification, launch

> Note: earlier template versions had a **Pre-Production** stage between Technical Setup
> and Production. It was replaced by the **MVP** stage, which now sits much earlier —
> before Systems Design rather than after Technical Setup. If `production/stage.txt`
> reads `Pre-Production`, it predates this profile: say so and ask which stage applies.

**When a gate passes**, write the new stage name to `production/stage.txt`
(single line, e.g. `Production`). This updates the status line immediately.
**When a gate passes**, write the new stage name to `production/stage.txt`
(single line, e.g. `Production`). This updates the status line immediately.

---

## 1. Parse Arguments

**Target phase:** `$ARGUMENTS[0]` (blank = auto-detect current stage, then validate next transition)

Also resolve the review mode (once, store for all gate spawns this run):
1. If `--review [full|lean|solo]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

Note: in `solo` mode, director spawns (CD-PHASE-GATE, TD-PHASE-GATE, PR-PHASE-GATE, AD-PHASE-GATE) are skipped — gate-check becomes artifact-existence checks only. In `lean` mode, all four directors still run (phase gates are the purpose of lean mode).

- **With argument**: `/gate-check production` — validate readiness for that specific phase
- **No argument**: Auto-detect current stage using the same heuristics as
  `/project-stage-detect`, then **confirm with the user before running**:

  Use `AskUserQuestion`:
  - Prompt: "Detected stage: **[current stage]**. Running gate for [Current] → [Next] transition. Is this correct?"
  - Options:
    - `[A] Yes — run this gate`
    - `[B] No — pick a different gate` (if selected, show a second widget listing all gate options: Concept → MVP, MVP → Systems Design, Systems Design → Technical Setup, Technical Setup → Production, Production → Polish, Polish → Release)
  
  Do not skip this confirmation step when no argument is provided.

---

## 2. Phase Gate Definitions

### Gate: Concept → MVP

**Required Artifacts:**
- [ ] `.claude/docs/technical-preferences.md` populated (no `TO BE CONFIGURED` left in
      Engine, Platform, or Performance Budgets)
- [ ] `design/gdd/game-concept.md` exists and names the core mechanic precisely enough
      that someone could build it without asking what the game is

**Quality Checks:**
- [ ] The concept states a core loop, not a genre and a mood
- [ ] Target platform and input method are recorded (touch, portrait or landscape)
- [ ] Scope tiers exist — what ships if time runs out

**Deliberately NOT required here:**
Art bible, UX specs, systems index, per-system GDDs, ADRs. Each of those is real work,
and each is cheaper to do after the mechanic has been judged. A mechanic that does not
work makes all of them wasted.

**Verdict guidance:** if the concept cannot answer "what does the player do, over and
over", return FAIL — the MVP has nothing to build.

---

### Gate: MVP → Systems Design

**Required Artifacts:**
- [ ] `production/mvp-report.md` exists with a recorded verdict
- [ ] The verdict is **PROCEED**. `PIVOT` means another MVP run, not advancement.
      `KILL` means returning to `/brainstorm` — record it and stop.
- [ ] The report's Verification table is filled: EditMode test count, PlayMode loop
      result, `/mobile-build-check` result. A PROCEED with an empty verification table
      is not evidence, and this gate must FAIL on it.
- [ ] Level pipeline ADR exists in `docs/architecture/` (from `/level-pipeline`)
- [ ] `docs/registry/services.yaml` shows `IGameplayLoader` and `IGameplaySession`
      no longer `missing`

**Required if the signal-mode run happened:**
- [ ] Consent adapter status is `exists` in `docs/registry/services.yaml`, and its
      `bootstrap_order` sorts before every ads entry — spawn **TD-CONSENT-GATE**
- [ ] `/feature-flag audit` returns CLEAN or DRIFT, never BROKEN — spawn **TD-FLAG-AUDIT**
- [ ] Ads and IAP each have a kill-switch flag

**Quality Checks:**
- [ ] The report's deliberate-debt table is filled in, not empty. Small scope is fine;
      undocumented shortcuts are not.
- [ ] Puzzle rules have EditMode tests that run with no scene loaded
- [ ] At least one assembly definition exists per module under `Assets/Scripts/`

**Gates to spawn:** **PR-MVP-VERDICT** (always — verifies the verdict follows from the
evidence rather than the effort spent).

---

### Gate: Systems Design → Technical Setup

**Required Artifacts:**
- [ ] Systems index exists at `design/gdd/systems-index.md` with at least MVP systems enumerated
- [ ] All MVP-tier GDDs exist in `design/gdd/` and individually pass `/design-review`
- [ ] A cross-GDD review report exists in `design/gdd/` (from `/review-all-gdds`)

**Quality Checks:**
- [ ] All MVP GDDs pass individual design review (8 required sections, no MAJOR REVISION NEEDED verdict)
- [ ] `/review-all-gdds` verdict is not FAIL (cross-GDD consistency and design theory checks pass)
- [ ] All cross-GDD consistency issues flagged by `/review-all-gdds` are resolved or explicitly accepted
- [ ] System dependencies are mapped in the systems index and are bidirectionally consistent
- [ ] MVP priority tier is defined
- [ ] No stale GDD references flagged (older GDDs updated to reflect decisions made in later GDDs)

---

### Gate: Technical Setup → Production

**Required Artifacts:**
- [ ] Master architecture document at `docs/architecture/architecture.md`
- [ ] At least 4 ADRs: adapter boundary, feature-flag mechanism (including kill-switch
      latency), level pipeline, and SO event channel strategy
- [ ] All Foundation and Core layer ADRs have status `Accepted`, not `Proposed` — stories
      cannot be unblocked until their governing ADR is accepted
- [ ] All MVP-tier GDDs from the systems index are complete
- [ ] Epics defined in `production/epics/` with at least Foundation and Core layers
      present (`/create-epics layer: foundation`, then `layer: core`, then
      `/create-stories [epic-slug]` for each)
- [ ] First sprint plan exists in `production/sprints/`
- [ ] Test framework initialised: EditMode and PlayMode directories exist under `Assets/Tests/`,
      with at least one passing test in each
- [ ] All ADRs agree on the same engine version — no stale version references

**Quality Checks:**
- [ ] Architecture matches what the MVP actually built. An architecture document that
      describes a different system than the one running is worse than none.
- [ ] No ADR contradicts another (check `docs/registry/architecture.yaml`)
- [ ] Every service contract in `docs/registry/services.yaml` is `exists` or has an
      explicit, dated reason for remaining `missing`
- [ ] Control manifest at `docs/architecture/control-manifest.md`, generated from
      Accepted ADRs — recommended, surface as CONCERNS if absent
- [ ] Art bible complete and signed off — required only if asset production is starting

**Gates to spawn:** TD-ARCHITECTURE, LP-FEASIBILITY, PR-EPIC, and **TD-ADAPTER-BOUNDARY**
for every adapter written since the MVP gate.

---
### Gate: Production → Polish

**Required Artifacts:**
- [ ] `Assets/Scripts/` has active code organized into subsystems
- [ ] All core mechanics from GDD are implemented (cross-reference `design/gdd/` with `Assets/Scripts/`)
- [ ] Main gameplay path is playable end-to-end
- [ ] Test files exist in `Assets/Tests/EditMode/` and `Assets/Tests/PlayMode/` covering Logic and Integration stories
- [ ] All Logic stories from this sprint have corresponding unit test files in `Assets/Tests/EditMode/`
- [ ] Smoke check has been run with a PASS or PASS WITH WARNINGS verdict — report exists in `production/qa/`
- [ ] QA plan exists in `production/qa/` (generated by `/qa-plan`) covering this sprint or final production sprint
- [ ] At least one QA plan exists in `production/qa/` covering this production phase — run `/qa-plan` if missing (CONCERNS — advisory, not blocking)
- [ ] QA sign-off report exists in `production/qa/` (generated by `/team-qa`) with verdict APPROVED or APPROVED WITH CONDITIONS
- [ ] At least 3 distinct playtest sessions documented in `production/playtests/`
- [ ] Playtest reports cover: new player experience, mid-game systems, and difficulty curve
- [ ] Fun hypothesis from Game Concept has been explicitly validated or revised

**Quality Checks:**
- [ ] Tests are passing (run test suite via Bash)
- [ ] No critical/blocker bugs in any bug tracker or known issues
- [ ] Core loop plays as designed (compare to GDD acceptance criteria)
- [ ] Performance is within budget (check technical-preferences.md targets)
- [ ] Playtest findings have been reviewed and critical fun issues addressed (not just documented)
- [ ] No "confusion loops" identified — no point in the game where >50% of playtesters got stuck without knowing why
- [ ] Difficulty curve matches the Difficulty Curve design doc (if one exists at `design/difficulty-curve.md`)
- [ ] All implemented screens have corresponding UX specs (no "designed in-code" screens)
- [ ] Interaction pattern library is up-to-date with all patterns used in implementation
- [ ] Accessibility compliance verified against committed tier in `design/accessibility-requirements.md`

---

### Gate: Polish → Release

**Required Artifacts:**
- [ ] All features from milestone plan are implemented
- [ ] Content is complete (all levels, assets, dialogue referenced in design docs exist)
- [ ] Localization strings are externalized (no hardcoded player-facing text in `Assets/Scripts/`)
- [ ] QA test plan exists (`/qa-plan` output in `production/qa/`)
- [ ] QA sign-off report exists (`/team-qa` output — APPROVED or APPROVED WITH CONDITIONS)
- [ ] All Must Have story test evidence is present (Logic/Integration: test files pass; Visual/Feel/UI: sign-off docs in `production/qa/evidence/`)
- [ ] Smoke check passes cleanly (PASS verdict) on the release candidate build
- [ ] No test regressions from previous sprint (test suite passes fully)
- [ ] Balance data has been reviewed (`/balance-check` run)
- [ ] Release checklist completed (`/release-checklist` run)
- [ ] Store metadata prepared (if applicable)
- [ ] Changelog / patch notes drafted

**Quality Checks:**
- [ ] Full QA pass signed off by `qa-lead`
- [ ] All tests passing
- [ ] Performance targets met across all target platforms
- [ ] No known critical, high, or medium-severity bugs
- [ ] Accessibility basics covered (remapping, text scaling if applicable)
- [ ] Localization verified for all target languages
- [ ] Legal requirements met (EULA, privacy policy, age ratings if applicable)
- [ ] Build compiles and packages cleanly

---

## 3. Run the Gate Check

**Before running artifact checks**, read `docs/consistency-failures.md` if it exists.
Extract entries whose Domain matches the target phase (e.g., if checking
Systems Design → Technical Setup, pull entries in Economy, Combat, or any GDD domain;
if checking Technical Setup → Production, pull entries in Architecture, Engine).
Carry these as context — recurring conflict patterns in the target domain warrant
increased scrutiny on those specific checks.

For each item in the target gate:

### Artifact Checks
- Use `Glob` and `Read` to verify files exist and have meaningful content
- Don't just check existence — verify the file has real content (not just a template header)
- For code checks, verify directory structure and file counts

**Systems Design → Technical Setup gate — cross-GDD review check**:
Use `Glob('design/gdd/gdd-cross-review-*.md')` to find the `/review-all-gdds` report.
If no file matches, mark the "cross-GDD review report exists" artifact as **FAIL** and
surface it prominently: "No `/review-all-gdds` report found in `design/gdd/`. Run
`/review-all-gdds` before advancing to Technical Setup."
If a file is found, read it and check the verdict line: a FAIL verdict means the
cross-GDD consistency check failed and must be resolved before advancing.

### Quality Checks
- For test checks: Run the test suite via `Bash` if a test runner is configured
- For design review checks: `Read` the GDD and check for the 8 required sections
- For performance checks: `Read` technical-preferences.md and compare against any
  profiling data in `tests/performance/` or recent `/perf-profile` output
- For localization checks: `Grep` for hardcoded strings in `Assets/Scripts/`

### Cross-Reference Checks
- Compare `design/gdd/` documents against `Assets/Scripts/` implementations
- Check that every system referenced in architecture docs has corresponding code
- Verify sprint plans reference real work items

---

## 4. Collaborative Assessment

For items that can't be automatically verified, **ask the user**:

- "I can't automatically verify that the core loop plays well. Has it been playtested?"
- "No playtest report found. Has informal testing been done?"
- "Performance profiling data isn't available. Would you like to run `/perf-profile`?"

**Never assume PASS for unverifiable items.** Mark them as MANUAL CHECK NEEDED.

---

## 4b. Director Panel Assessment

**Apply review mode before spawning any director:**
- `solo` → skip all four directors. Note in output: "Director Panel skipped — Solo mode. Gate verdict based on artifact and quality checks only." Proceed to Phase 5.
- `lean` → spawn all four directors (phase gates always run in lean mode — this is their purpose).
- `full` → spawn all four directors as normal.

(Review mode was resolved in Phase 1. Use that stored value here.)

Before generating the final verdict, spawn all four directors as **parallel subagents** via Task using the parallel gate protocol from `.claude/docs/director-gates.md`. Issue all four Task calls simultaneously — do not wait for one before starting the next.

**Spawn in parallel:**

1. **`creative-director`** — gate **CD-PHASE-GATE** (`.claude/docs/director-gates.md`)
2. **`technical-director`** — gate **TD-PHASE-GATE** (`.claude/docs/director-gates.md`)
3. **`producer`** — gate **PR-PHASE-GATE** (`.claude/docs/director-gates.md`)
4. **`art-director`** — gate **AD-PHASE-GATE** (`.claude/docs/director-gates.md`)

Pass to each: target phase name, list of artifacts present, and the context fields listed in that gate's definition.

**Collect all four responses, then present the Director Panel summary:**

```
## Director Panel Assessment

Creative Director:  [READY / CONCERNS / NOT READY]
  [feedback]

Technical Director: [READY / CONCERNS / NOT READY]
  [feedback]

Producer:           [READY / CONCERNS / NOT READY]
  [feedback]

Art Director:       [READY / CONCERNS / NOT READY]
  [feedback]
```

**Apply to the verdict:**
- Any director returns NOT READY → verdict is minimum FAIL (user may override with explicit acknowledgement)
- Any director returns CONCERNS → verdict is minimum CONCERNS
- All four READY → eligible for PASS (still subject to artifact and quality checks from Section 3)

---

## 5. Output the Verdict

```
## Gate Check: [Current Phase] → [Target Phase]

**Date**: [date]
**Checked by**: gate-check skill

### Required Artifacts: [X/Y present]
- [x] design/gdd/game-concept.md — exists, 2.4KB
- [ ] docs/architecture/ — MISSING (no ADRs found)
- [x] production/sprints/ — exists, 1 sprint plan

### Quality Checks: [X/Y passing]
- [x] GDD has 8/8 required sections
- [ ] Tests — FAILED (3 failures in Assets/Tests/EditMode/)
- [?] Core loop playtested — MANUAL CHECK NEEDED

### Blockers
1. **No Architecture Decision Records** — Run `/architecture-decision` to create one
   covering core system architecture before entering production.
2. **3 test failures** — Fix failing tests in Assets/Tests/EditMode/ before advancing.

### Recommendations
- [Priority actions to resolve blockers]
- [Optional improvements that aren't blocking]

### Verdict: [PASS / CONCERNS / FAIL]
- **PASS**: All required artifacts present, all quality checks passing
- **CONCERNS**: Minor gaps exist but can be addressed during the next phase
- **FAIL**: Critical blockers must be resolved before advancing
```

---

## 5a. Chain-of-Verification

After drafting the verdict in Phase 5, challenge it before finalising.

**Step 1 — Generate 5 challenge questions** designed to disprove the verdict:

> **Tool-action requirement**: At least 2 of the 5 challenge questions below must be answered by re-reading a specific file (Read tool) or re-running a specific check (Grep tool) — not by reflection alone. Mark these with [TOOL ACTION] to indicate a tool was used.

For a **PASS** draft:
- "Which quality checks did I verify by actually reading a file, vs. inferring they passed?"
- "Are there MANUAL CHECK NEEDED items I marked PASS without user confirmation? [TOOL ACTION] Re-scan the checklist for any [?] or MANUAL CHECK items."
- "Did I confirm all listed artifacts have real content, not just empty headers? [TOOL ACTION] Re-read the file and check it has non-placeholder content."
- "Could any blocker I dismissed as minor actually prevent the phase from succeeding?"
- "Which single check am I least confident in, and why?"

For a **CONCERNS** draft:
- "Could any listed CONCERN be elevated to a blocker given the project's current state?"
- "Is the concern resolvable within the next phase, or does it compound over time?"
- "Did I soften any FAIL condition into a CONCERN to avoid a harder verdict?"
- "Are there artifacts I didn't check that could reveal additional blockers?"
- "Do all the CONCERNS together create a blocking problem even if each is minor alone?"

For a **FAIL** draft:
- "Have I accurately separated hard blockers from strong recommendations?"
- "Are there any PASS items I was too lenient about?"
- "Am I missing any additional blockers the user should know about?"
- "Can I provide a minimal path to PASS — the specific 3 things that must change?"
- "Is the fail condition resolvable, or does it indicate a deeper design problem?"

**Step 2 — Answer each question** independently.
Do NOT reference the draft verdict text — re-check specific files or ask the user.

**Step 3 — Revise if needed:**
- If any answer reveals a missed blocker → upgrade verdict (PASS→CONCERNS or CONCERNS→FAIL)
- If any answer reveals an over-stated blocker → downgrade only if citing specific evidence
- If answers are consistent → confirm verdict unchanged

**Step 4 — Note the verification** in the final report output:
`Chain-of-Verification: [N] questions checked — verdict [unchanged | revised from X to Y]`

---

## 6. Update Stage on PASS

When the verdict is **PASS** and the user confirms they want to advance:

1. Write the new stage name to `production/stage.txt` (single line, no trailing newline)
2. This immediately updates the status line for all future sessions

Example: if passing the "Technical Setup → Production" gate:
```bash
echo -n "Production" > production/stage.txt
```

**Always ask before writing**: "Gate passed. May I update `production/stage.txt` to 'Production'?"

---

## 7. Closing Next-Step Widget

After the verdict is presented and any stage.txt update is complete, close with a structured next-step prompt using `AskUserQuestion`.

**Tailor the options to the gate that just ran:**

For **systems-design PASS**:
```
Gate passed. What would you like to do next?
[A] Run /create-architecture — produce your master architecture blueprint and ADR work plan (recommended next step)
[B] Design more GDDs first — return here when all MVP systems are complete
[C] Stop here for this session
```

> **Note for systems-design PASS**: `/create-architecture` is the required next step before writing any ADRs. It produces the master architecture document and a prioritized list of ADRs to write. Running `/architecture-decision` without this step means writing ADRs without a blueprint — skip it at your own risk.

For **technical-setup PASS**:
```
Gate passed. What would you like to do next?
[A] Run /create-control-manifest — generate the layer rules manifest from your Accepted ADRs (do this first)
[B] Run /puzzle-mvp --mode signal — build the Vertical Slice (do this before writing epics — validate fun first)
[C] Write more ADRs first — run /architecture-decision [next-system]
[D] Stop here for this session
```

> **Note for technical-setup PASS**: fun was already validated in the MVP phase, which
> sits much earlier in this profile. So the sequence after this gate is planning, not
> validation:
>
> 1. `/create-epics layer: foundation`, then `layer: core`
> 2. `/create-stories [epic-slug]` for each epic
> 3. `/sprint-plan` — first production sprint
> 4. `/create-control-manifest` — flat rules sheet from Accepted ADRs (recommended)
>
> If fun has *not* been validated — no `production/mvp-report.md` with a PROCEED verdict —
> this gate should not have passed. Return to `/puzzle-mvp` rather than planning on top of
> an unvalidated mechanic.
> 7. `/sprint-plan new`
>
> **Why prototype before epics?** If the prototype reveals the core loop needs to change,
> epics written before that discovery will be partially wrong. Validate fun cheaply first,
> then plan in detail. This is the #1 lesson from GDC postmortem data.

For all other gates, offer the two most logical next steps for that phase plus "Stop here".

---

## 8. Follow-Up Actions

Based on the verdict, suggest specific next steps:

- **No art bible?** → `/art-bible` to create the visual identity specification
- **Art bible exists but no asset specs?** → `/asset-spec system:[name]` to generate per-asset visual specs and generation prompts from approved GDDs
- **No game concept?** → `/brainstorm` to create one
- **No systems index?** → `/map-systems` to decompose the concept into systems
- **Missing design docs?** → `/design-system` or delegate to `game-designer`
- **Small design change needed?** → `/quick-design` for changes under ~4 hours (bypasses full GDD pipeline)
- **No UX specs?** → `/ux-design [screen name]` to author specs, or `/team-ui [feature]` for full pipeline
- **UX specs not reviewed?** → `/ux-review [file]` or `/ux-review all` to validate
- **No accessibility requirements doc?** → run `/ux-design` which creates both `design/accessibility-requirements.md` and `design/ux/interaction-patterns.md` in one step
- **No interaction pattern library?** → `/ux-design patterns` to initialize it
- **GDDs not cross-reviewed?** → `/review-all-gdds` (run after all MVP GDDs are individually approved)
- **Cross-GDD consistency issues?** → fix flagged GDDs, then re-run `/review-all-gdds`
- **No test framework?** → `/test-setup` to scaffold the framework for your engine
- **No QA plan for current sprint?** → `/qa-plan sprint` to generate one before implementation begins
- **Missing ADRs?** → `/architecture-decision` for individual decisions
- **No master architecture doc?** → `/create-architecture` for the full blueprint
- **ADRs missing engine compatibility sections?** → Re-run `/architecture-decision`
  or manually add Engine Compatibility sections to existing ADRs
- **Missing control manifest?** → `/create-control-manifest` (requires Accepted ADRs)
- **Missing epics?** → `/create-epics layer: foundation` then `/create-epics layer: core` (requires control manifest)
- **Missing stories for an epic?** → `/create-stories [epic-slug]` (run after each epic is created)
- **Stories not implementation-ready?** → `/story-readiness` to validate stories before developers pick them up
- **Tests failing?** → delegate to `lead-programmer` or `qa-tester`
- **No playtest data?** → `/playtest-report`
- **No playtest sessions beyond the minimum?** → Additional sessions give more reliable signal. 3+ total is recommended before committing the full team. Use `/playtest-report` to structure findings.
- **No Difficulty Curve doc?** → Create `design/difficulty-curve.md` from the template at `.claude/docs/templates/difficulty-curve.md` — or use `/quick-design "difficulty curve"` for a guided session.
- **No player journey map?** → Create `design/player-journey.md` from the template at `.claude/docs/templates/player-journey.md` — or author it collaboratively using `/ux-design` Phase 2b.
- **Need a quick sprint check?** → `/sprint-status` for current sprint progress snapshot
- **Performance unknown?** → `/perf-profile`
- **Not localized?** → `/localize`
- **Ready for release?** → `/release-checklist`

---

## Collaborative Protocol

This skill follows the collaborative design principle:

1. **Scan first**: Check all artifacts and quality gates
2. **Ask about unknowns**: Don't assume PASS for things you can't verify
3. **Present findings**: Show the full checklist with status
4. **User decides**: The verdict is a recommendation — the user makes the final call
5. **Get approval**: "May I write this gate check report to production/gate-checks/?"
6. **Never auto-fix**: If required artifacts are missing, report the FAIL verdict and
   name the skill to run (e.g. "run `/test-setup`"). Do NOT create missing files or
   re-run the gate automatically. Creating files to manufacture a PASS defeats the
   gate's purpose.

**Never** block a user from advancing — the verdict is advisory. Document the risks
and let the user decide whether to proceed despite concerns.
