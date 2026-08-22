# Agent Roster

27 agents, each with a definition file in `.claude/agents/`. Use the agent best suited to
the task. When a task spans domains, the coordinating agent (usually `producer`, or the
domain lead) delegates to specialists.

This roster is trimmed for **mobile puzzle** development. Agents for narrative,
multiplayer, and 3D spatial level design were archived — see the bottom of this file.

## Tier 1 — Leadership (Opus)

| Agent | Domain | When to Use |
|-------|--------|-------------|
| `creative-director` | High-level vision | Major creative decisions, pillar conflicts, tone |
| `technical-director` | Technical vision | Architecture decisions, adapter boundaries, performance strategy |
| `producer` | Production management | Sprint planning, milestone tracking, scope negotiation, risk |

## Tier 2 — Department Leads (Sonnet)

| Agent | Domain | When to Use |
|-------|--------|-------------|
| `game-designer` | Game design | Mechanics, systems, progression, economy, balancing |
| `lead-programmer` | Code architecture | System design, code review, API design, refactoring |
| `art-director` | Visual direction | Style guides, art bible, asset standards, board readability |
| `ux-designer` | UX & interface | User flows, interaction design, accessibility, localisation-readiness, player-facing copy |
| `qa-lead` | Quality assurance | Test strategy, bug triage, release readiness |
| `release-manager` | Release pipeline | Store submission, certification, versioning, changelogs, rollbacks |

## Tier 3 — Specialists (Sonnet / Haiku)

| Agent | Domain | Model | When to Use |
|-------|--------|-------|-------------|
| `mobile-sdk-engineer` | **Adapters & monetisation plumbing** | Sonnet | **Anything under `Assets/Scripts/Services/`** — ads, IAP, analytics, attribution, remote config, consent/ATT, feature-flag mechanics, store privacy |
| `puzzle-level-designer` | Puzzle levels | Sonnet | Level authoring, teaching order, difficulty curve, solvability, tutorial, level-set A/B |
| `systems-designer` | Systems design | Sonnet | Rule specification, formula design, interaction matrices |
| `economy-designer` | Economy & balance | Sonnet | Currencies, offers, sinks and faucets, progression curves |
| `live-ops-designer` | Live operations | Sonnet | Seasons, events, retention mechanics, live economy, event copy |
| `gameplay-programmer` | Gameplay code | Sonnet | Puzzle rules, feature implementation, gameplay systems |
| `ui-programmer` | UI implementation | Sonnet | Screens, popups, widgets, data binding |
| `tools-programmer` | Dev tools | Sonnet | Editor extensions, **level-authoring tooling**, pipeline automation, debug utilities |
| `technical-artist` | Tech art (2D/UI) | Sonnet | Shaders, VFX, sprite/atlas pipeline, skeletal animation, visual optimisation |
| `sound-designer` | Audio | Sonnet | Audio direction, SFX specs, event lists, mixing notes |
| `performance-analyst` | Performance | Sonnet | Device profiling, memory analysis, budget enforcement |
| `analytics-engineer` | Telemetry | Sonnet | Event taxonomy, dashboards, A/B test design |
| `devops-engineer` | Build & deploy | Haiku | CI configuration, build scripts, version control workflow |
| `qa-tester` | Test execution | Haiku | Test cases, bug reports, solvability verification, checklists |

## Unity Engine Specialists

| Agent | Subsystem | Model | When to Use |
| ---- | ---- | ---- | ---- |
| `unity-specialist` | Unity 6 (authority) | Sonnet | MonoBehaviour patterns, Unity subsystems, mobile profiling, core/engine-level work |
| `unity-ui-specialist` | UI Toolkit / UGUI | Sonnet | UGUI canvas work, data binding, runtime UI performance, cross-device UI adaptation |
| `unity-shader-specialist` | Shaders / VFX | Sonnet | Shader Graph, URP customisation, post-processing, VFX optimisation |
| `unity-addressables-specialist` | Asset loading | Sonnet | Resources vs Addressables strategy, memory, content delivery, UPM manifest health |

## Routing shortcuts

| If the work is about… | Start with |
|---|---|
| An SDK, a flag, consent, or anything in `Assets/Scripts/Services/` | `mobile-sdk-engineer` |
| Puzzle rules or a formula | `systems-designer` → `gameplay-programmer` |
| Level content or the difficulty curve | `puzzle-level-designer` |
| A level-authoring tool or editor window | `tools-programmer` |
| Whether a Unity API is safe to use | `unity-specialist` |
| Asset loading strategy | `unity-addressables-specialist` |
| Player-facing text or copy | `ux-designer` |
| Scope, timeline, or cutting features | `producer` |

## Archived

Moved to `.claude/agents/_archived/`. Not loaded. Restore if the project's shape changes.

| Agent | Why archived | Capability now owned by |
|---|---|---|
| `narrative-director`, `writer`, `world-builder` | No narrative deliverables in a puzzle game; neither reference puzzle title has any | `ux-designer` (copy), `live-ops-designer` (event framing) |
| `network-programmer` | No multiplayer | — |
| `ai-programmer` | No behaviour trees or pathfinding | `gameplay-programmer` |
| `unity-dots-specialist` | Zero of four reference titles use DOTS — no call sites at all | `unity-specialist` |
| `engine-programmer` | Overlaps the Unity specialist on a project this size | `unity-specialist` |
| `accessibility-specialist` | Folded into UX rather than separated | `ux-designer` |
| `security-engineer` | Mobile security here is SDK, save, and privacy work | `mobile-sdk-engineer` + rules |
| `localization-lead` | Needed as a rule, not a standing agent | `ux-designer` + `localize` skill |
| `prototyper` | Superseded by the MVP lane, whose code is kept | `/puzzle-mvp` + `gameplay-programmer` |
| `audio-director` | Audio scope in a puzzle game does not warrant a separate director | `sound-designer` |
| `community-manager` | Not needed before launch | `live-ops-designer` |
| `level-designer` | Replaced by a puzzle-specific version | `puzzle-level-designer` |

## Model Tier Assignment

| Tier | When to use |
|------|-------------|
| **Haiku** | Read-only status checks, formatting, simple lookups — no creative judgement |
| **Sonnet** | Implementation, design authoring, single-system analysis — the default |
| **Opus** | Multi-document synthesis, high-stakes phase gates, cross-system holistic review |
