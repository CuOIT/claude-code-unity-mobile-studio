# Available Skills (Slash Commands)

58 slash commands, organised by workflow phase. Type `/` in Claude Code to access any.

Trimmed for **mobile puzzle** development. See the bottom of this file for what was
archived and where its capability went.

## Onboarding & Navigation

| Command | Purpose |
|---------|---------|
| `/start` | First-time onboarding — asks where you are, then routes you |
| `/help` | Context-aware "what do I do next?" — reads current stage and surfaces the next step |
| `/project-stage-detect` | Full project audit — detect phase, identify gaps, recommend next steps |
| `/setup-engine` | Configure engine and conventions. **Asks** for the version rather than pinning one |

## MVP — the fast lane

| Command | Purpose |
|---------|---------|
| `/puzzle-mvp` | **Build a playable MVP.** `--mode demo` for speed to something demonstrable; `--mode signal` for a soft-launch build that gathers real data. **This code is kept** — Production continues from it |
| `/level-pipeline` | Decide and scaffold how levels are authored, stored, ordered, and validated. Run once the mechanic is known |
| `/sdk-integrate` | Write an adapter from an existing contract onto a real vendor SDK. Enforces consent-before-ads |
| `/feature-flag` | Add, list, or audit feature flags across all three tiers. Catches flags read but never declared |
| `/prototype` | Throwaway spike for one narrow technical or design question (4-hour cap). Distinct from the MVP — spike code is discarded |

## Game Design

| Command | Purpose |
|---------|---------|
| `/brainstorm` | Guided ideation using studio methods (MDA, verb-first, player psychology) |
| `/map-systems` | Decompose the concept into systems, map dependencies, prioritise design order |
| `/design-system` | Guided section-by-section GDD authoring for one system |
| `/quick-design` | Lightweight spec for small changes — tuning, tweaks, minor additions |
| `/design-review` | Review one design document for completeness and implementability |
| `/review-all-gdds` | Holistic cross-GDD consistency and design-theory review |
| `/consistency-check` | Scan GDDs against the entity registry for contradictions |
| `/propagate-design-change` | When a GDD is revised, find the ADRs it may have invalidated |
| `/balance-check` | Analyse balance data, formulas, and curves — flag outliers |

## Art, Assets & UX

| Command | Purpose |
|---------|---------|
| `/art-bible` | Guided art bible authoring — visual identity before asset production |
| `/asset-spec` | Per-asset specifications and generation prompts |
| `/ux-design` | Guided UX spec authoring for a screen, flow, or HUD |
| `/ux-review` | Validate a UX spec for completeness, accessibility, and GDD alignment |
| `/localize` | Localisation pipeline: string extraction, validation, translation readiness |

## Architecture

| Command | Purpose |
|---------|---------|
| `/create-architecture` | Guided authoring of the master architecture document |
| `/architecture-decision` | Create an Architecture Decision Record |
| `/architecture-review` | Validate all ADRs for completeness, ordering, and GDD coverage |
| `/create-control-manifest` | Flat programmer rules sheet generated from accepted ADRs |

## Stories & Sprints

| Command | Purpose |
|---------|---------|
| `/create-epics` | Translate GDDs + architecture into epics, one per module |
| `/create-stories` | Break an epic into implementable story files |
| `/story-readiness` | Validate a story is implementation-ready (READY / NEEDS WORK / BLOCKED) |
| `/dev-story` | Read a story and implement it — routes to the right specialist |
| `/story-done` | Completion review; verifies acceptance criteria, closes the story |
| `/sprint-plan` | Generate or update a sprint plan |
| `/sprint-status` | Fast sprint snapshot |
| `/retrospective` | Structured sprint or milestone retrospective |

## Reviews & Analysis

| Command | Purpose |
|---------|---------|
| `/code-review` | Architectural code review — adapter boundary, assemblies, file-size ceilings |
| `/mobile-build-check` | **Static pre-flight before CI.** Adapter boundary, consent gate, flag declarations, assemblies, secrets, UPM manifest, asset budgets |
| `/perf-profile` | Structured performance profiling against mobile budgets |
| `/tech-debt` | Scan, track, prioritise, and report technical debt |
| `/gate-check` | Validate readiness to advance phases (PASS / CONCERNS / FAIL) |

## QA & Testing

| Command | Purpose |
|---------|---------|
| `/qa-plan` | QA test plan for a sprint or feature |
| `/smoke-check` | Critical-path smoke gate before QA hand-off |
| `/test-setup` | Scaffold the test framework and CI pipeline |
| `/playtest-report` | Structured playtest report, or analysis of existing notes |
| `/bug-report` | Structured bug report |
| `/bug-triage` | Re-evaluate the open bug backlog by priority vs severity |
| `/skill-test` | Validate skill files for structural compliance |

## Release

| Command | Purpose |
|---------|---------|
| `/release-checklist` | Pre-release validation across code, content, store, and legal |
| `/changelog` | Internal changelog from commits and sprint data |
| `/patch-notes` | Player-facing patch notes |
| `/hotfix` | Emergency fix workflow with an audit trail |

## Team Orchestration

Coordinate multiple agents on one feature area.

| Command | Coordinates |
|---------|-------------|
| `/team-puzzle-level` | puzzle-level-designer + systems-designer + art-director + qa-tester — a **batch** of levels |
| `/team-combat` | game-designer + gameplay-programmer + technical-artist + sound-designer + qa-tester |
| `/team-ui` | ux-designer + ui-programmer + art-director |
| `/team-qa` | qa-lead + qa-tester + gameplay-programmer + producer |
| `/team-polish` | performance-analyst + technical-artist + sound-designer + qa-tester |
| `/team-live-ops` | live-ops-designer + economy-designer + analytics-engineer + ux-designer |
| `/team-release` | release-manager + qa-lead + devops-engineer + producer |

---

## Archived

Moved to `.claude/skills/_archived/`. Not loaded. Restore if the need returns.

| Skill | Why | Capability now |
|---|---|---|
| `/vertical-slice` | Superseded — the MVP lane covers both a quick demo and a production-quality signal build | `/puzzle-mvp --mode signal` |
| `/adopt` | Overlapped the existence audit | `/project-stage-detect` |
| `/reverse-document` | Generating docs from code is not this project's shape | `/design-system`, `/create-architecture` |
| `/onboard` | The profile docs serve this | `.claude/docs/puzzle-profile.md` |
| `/estimate`, `/scope-check`, `/milestone-review` | Scope and timeline judgement belongs to a person, not a report | `producer` agent |
| `/content-audit`, `/asset-audit` | Asset and content checks folded into the build check | `/mobile-build-check` |
| `/security-audit` | Mobile security here is SDK, save, and privacy work | `mobile-sdk-engineer` + `/mobile-build-check` |
| `/soak-test` | Long-session testing folded into profiling | `/perf-profile` |
| `/regression-suite`, `/test-flakiness`, `/test-evidence-review` | Test planning consolidated | `/qa-plan` |
| `/launch-checklist` | Duplicated the release checklist | `/release-checklist` |
| `/day-one-patch` | Duplicated the hotfix flow | `/hotfix` |
| `/team-narrative`, `/team-audio` | No narrative deliverables; audio scope does not need orchestration | `sound-designer` directly |
| `/test-helpers` | Premature for a project with no test suite yet | `/test-setup` |
| `/skill-improve` | Framework self-maintenance, not game work | `/skill-test` |
