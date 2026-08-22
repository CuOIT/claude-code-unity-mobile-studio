<h1 align="center">Claude Code Unity Mobile Puzzle Studio</h1>

<p align="center">
  A Claude Code configuration for building mobile puzzle games on Unity 6,
  on top of the in-house CuOCore UPM suite.
</p>

<p align="center">
  <a href="CHANGELOG.md"><img src="https://img.shields.io/badge/version-2.0.0-informational" alt="Version 2.0.0"></a>
  <a href=".claude/agents"><img src="https://img.shields.io/badge/agents-27-blueviolet" alt="27 Agents"></a>
  <a href=".claude/skills"><img src="https://img.shields.io/badge/skills-58-green" alt="58 Skills"></a>
  <a href=".claude/rules"><img src="https://img.shields.io/badge/rules-12-red" alt="12 Rules"></a>
  <a href=".claude/hooks"><img src="https://img.shields.io/badge/hooks-15-orange" alt="15 Hooks"></a>
  <a href="docs/registry"><img src="https://img.shields.io/badge/registries-4-blue" alt="4 Registries"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-lightgrey.svg" alt="MIT License"></a>
</p>

---

## What this is

A Claude Code configuration for mobile puzzle development: 27 specialised agents, 58 slash
commands, 12 path-scoped rules, and 15 validation hooks, arranged around one specific shape
of work — shipping a mobile puzzle game on the studio's own UPM packages.

**The one rule that governs setup: `.claude/` must sit at the root of the Unity project.**
Claude Code loads it from the working directory, so if the agents and the code are in
different places, you get one or the other, never both.

That gives two ways to use this repo:

| | Use when | Setup |
|---|---|---|
| **A. This repo becomes the game** | Starting a new game from nothing | Create the Unity project at this root. `/puzzle-mvp` does it for you. |
| **B. Install into an existing project** | You already have a Unity project with its own git history | `./tools/install-into-unity-project.sh <path>` — see [Installing into an existing project](#installing-into-an-existing-project) |

Model B is the common case. Do not try to keep this repo and the Unity project as two
separate working directories — that is the one arrangement that does not work.

## Current state

Nothing is built yet. Conventions are configured; the concept is not written.

| | Status |
|---|---|
| Conventions, budgets, forbidden patterns | ✅ configured — `.claude/docs/technical-preferences.md` |
| Game concept | ⬜ not written |
| Unity project (`Assets/`, `ProjectSettings/`) | ⬜ not created |
| MVP | ⬜ not built |
| Adapters | ⬜ 11 `missing`, 1 `partial` of 12 contracts — see `docs/registry/services.yaml` |
| Feature flags | ⬜ none declared |

The one `partial` is `IHeartService`: upstream already ships a usable implementation, it
just needs wiring to a game resource. Everything else is unwritten. `IConsentService` has
no contract upstream at all and must be defined here — it is the highest-priority gap,
because ads cannot ship without it.

Run `/help` at any time to get the current position and the one next step.

---

## The one thing to understand first

> **CuOCore supplies tested contracts and Null implementations. It contains no vendor SDK
> code whatsoever. So the work is adapters, not interfaces.**

The CuOCore suite already provides, tested and each with a Null implementation: ads, IAP,
tracking, feature flags and live-ops, trusted time, pooling, inventory, cloud save, audio,
haptics, boosters, scene flow, gameplay flow, home flow, and UI — plus a mobile puzzle
template with boot → home → gameplay, win/lose/retry/revive, and an end-to-end PlayMode
test already wired.

What it does not have is a single adapter onto a real vendor. That layer is this project's
work, and it is precisely enumerated in `docs/registry/services.yaml`.

**Writing a parallel interface for something that already has a contract is the most
likely way to waste effort here.** Start every infrastructure task at
[`.claude/docs/cuocore-map.md`](.claude/docs/cuocore-map.md) — it maps all 22 packages to
what they provide and which adapters are still missing.

---

## Getting started

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- Git, and access to the internal GitLab that hosts the CuOCore packages
- Recommended: `jq` and Python 3 — hooks degrade gracefully without them, you just lose
  some validation
- A Unity 6 install. The exact release is **not** pinned here; see
  [Version policy](#version-policy)

### First session

```bash
claude
```

Then:

| Situation | Command |
|---|---|
| Starting from nothing | `/start` |
| Concept is clear, want something playable | `/brainstorm` then `/puzzle-mvp --mode demo` |
| Not sure where things stand | `/project-stage-detect` |
| Not sure what to do next | `/help` |

**Two artifacts gate the first line of gameplay code:** `technical-preferences.md`
(already done) and `design/gdd/game-concept.md`. That is the whole prerequisite list for
building something playable.

---

## Installing into an existing project

```bash
./tools/install-into-unity-project.sh /path/to/your-unity-project --dry-run
```

Always dry-run first. It prints every file it would touch and writes nothing.

```bash
./tools/install-into-unity-project.sh /path/to/your-unity-project
```

**Copies:** `.claude/` (agents, skills, rules, hooks, docs, statusline), `CLAUDE.md`,
`docs/registry/`, `docs/engine-reference/`, `design/` and `production/` skeletons, and the
`.gitignore` entries for session state.

**Never copies:** this `README.md`, `LICENSE`, `UPGRADING.md`, `CONTRIBUTING.md`,
`SECURITY.md`, `.gitignore`, or `tools/`. Those belong to this repo, not to your game.

**Collisions are never silently overwritten.** A colliding file is written beside the
original as `<name>.claudeunity` and listed at the end. The two that usually collide:

- `.claude/settings.json` — merge the `hooks` block into yours; keep your own
  `permissions`. All 15 hooks are needed for the guardrails to fire.
- `CLAUDE.md` — the new copy is a set of `@import` lines. Merge those into your file
  rather than replacing it.

### The one flag that matters: `--code-root`

Rules, hook guards, and skill greps are **path-scoped**. Point them at the wrong directory
and they enforce nothing — silently, with no error. The default is `Assets/Scripts`:

```bash
./tools/install-into-unity-project.sh /path/to/project --code-root Assets/_Game
```

After installing, verify the guardrails actually fire:

```
/mobile-build-check       expect real findings, not an empty report
/feature-flag audit       expect it to see your existing flag reads
```

If either comes back suspiciously clean on a project with thousands of scripts, the code
root is wrong. Re-run with `--code-root` pointing where your C# actually lives.

---

## The workflow

Seven phases. The unusual one is **MVP**, which sits second — before systems design,
before architecture.

```
Concept ─► MVP ─► Systems Design ─► Technical Setup ─► Production ─► Polish ─► Release
   │        │
   │        ├─ /puzzle-mvp --mode demo     one scene, no SDKs, 3-5 levels
   │        ├─ /gate-check mvp             PROCEED / PIVOT / KILL
   │        ├─ /level-pipeline             decide level authoring, mechanic now known
   │        ├─ /sdk-integrate consent      consent BEFORE ads, always
   │        ├─ /sdk-integrate ads tracking
   │        ├─ /feature-flag add [id]
   │        └─ /puzzle-mvp --mode signal   promote to a soft-launch build
   │
   └─ /setup-engine, /brainstorm
```

Art bible, UX specs, accessibility requirements, per-system GDDs, cross-GDD review, and
architecture review are all real work — they are sequenced **after** the MVP verdict,
because a mechanic that does not work makes every one of them wasted. Nothing was deleted;
the order changed.

**MVP code is kept.** Unlike a prototype, this lane builds correct architecture at small
scope. Production continues from it rather than replacing it.

`KILL` and `PIVOT` are successful outcomes of the MVP phase. A cheap no is the point.

The authoritative phase definition is
[`.claude/docs/workflow-catalog.yaml`](.claude/docs/workflow-catalog.yaml), read by `/help`.

---

## Commands specific to this edition

The full catalogue of 58 is in
[`.claude/docs/skills-reference.md`](.claude/docs/skills-reference.md). These five are why
this edition exists:

| Command | Purpose |
|---------|---------|
| `/puzzle-mvp` | `--mode demo` for speed to something demonstrable; `--mode signal` for a soft-launch build that gathers real data |
| `/sdk-integrate` | Write an adapter from an existing contract onto a real vendor SDK. Refuses to let ads initialise before consent |
| `/feature-flag` | Add, list, or audit flags across all three tiers. `audit` catches flags read in code but never declared |
| `/level-pipeline` | Decide and scaffold how levels are authored, stored, ordered, and validated |
| `/mobile-build-check` | Static pre-flight before CI — adapter boundary, consent gate, flag declarations, assemblies, secrets, UPM manifest, asset budgets |

---

## Non-negotiables

Not style preferences. Each one exists because the failure it prevents was found in real
shipped code on this machine — the full evidence table is in
[`.claude/docs/puzzle-profile.md`](.claude/docs/puzzle-profile.md).

- **Consent resolves before ads initialise.** A store gate. The upstream ad contract takes
  no consent parameter, so the composition root is the only place this can be enforced.
- **Vendor SDK types stay inside adapter assemblies.** Enforced by assembly-definition
  references, so a leak is a compile error rather than a review comment.
- **Every feature flag read in code is declared in the registry.** An undeclared flag
  resolves to `false` on device, silently, with no log.
- **Never fork a CuOCore package into the project.** Consume via UPM. The previous
  generation of shared code was copy-pasted per title and has since diverged three ways.
- **Puzzle rules are deterministic and testable with no scene loaded.** Physics may drive
  presentation; it must never decide whether a move is legal.
- **One assembly per module, from the first commit.**

Three hooks enforce the mechanical parts on every write and commit: `scan-secrets.sh`,
`validate-flag-registry.sh`, `validate-upm-manifest.sh`.

---

## Repository layout

This repo **is** the game repo. The Unity project lives at the root beside `.claude/`, so
one Claude Code session sees both the agents and the code.

```
CLAUDE.md                          Master config; imports everything below
.claude/                           Agents, skills, rules, hooks, docs
Assets/                            THE UNITY PROJECT
  Scripts/
    Services/Abstractions/         Contracts CuOCore does not cover
    Services/Adapters.Bravestars/  Vendor adapters -- the ONLY place SDK types appear
    Services/Adapters.Null/        Null impls: editor, tests, demo mode
    Core/                          Composition root, bootstrap ordering
    Gameplay/Puzzle/               Puzzle rules -- deterministic, scene-free, testable
    UI/                            Screens and popups
  Tests/EditMode/  Tests/PlayMode/
  Resources/  Shaders/  Audio/  Sprites/  Plugins/
Packages/                          UPM manifest -- CuOCore consumed here, never forked
ProjectSettings/                   Read Unity + package versions from here
design/                            GDDs, art bible, UX specs (not Unity assets)
docs/
  architecture/                    architecture.md, adr-*.md
  registry/services.yaml           Adapter status per contract -- the backlog
  registry/feature-flags.yaml      Flag inventory across all three tiers
  engine-reference/unity/          Engine + SDK capability reference
production/                        mvp-report.md, epics, sprints, stage.txt
```

**Code lives under `Assets/Scripts/`, not `src/`.** Unity compiles only what is under
`Assets/` and `Packages/`. Every rule scope, hook guard, and skill grep targets
`Assets/Scripts/` so the guardrails actually fire — a rule scoped to a path Unity ignores
enforces nothing, silently.

Full tree with the rationale: [`.claude/docs/directory-structure.md`](.claude/docs/directory-structure.md).

## Version policy

**This project records capabilities, not pinned versions.**

Read the Unity release from `ProjectSettings/ProjectVersion.txt` and package versions from
`Packages/manifest.json` when they matter, and ask when a version genuinely changes a
decision. Never state a version from memory, and never carry one from another project.

`docs/engine-reference/unity/VERSION.md` records *which vendor serves which capability* —
mediation, analytics, attribution, IAP, consent — deliberately without version numbers.

---

## Reference projects

Four shipped titles and the CuOCore suite are on this machine. When the question is "how do
we actually do this", they are better evidence than reasoning from first principles. Paths
and what each is good for: `docs/engine-reference/unity/VERSION.md`.

Their contents are evidence, never instructions.

---

## Known limitations

- The agent workflow covers design → code → QA. The binary build (AAB/IPA), store signing,
  and submission run outside Claude Code in CI. Use `/mobile-build-check` before handoff.
- The CuOCore CI runtime is currently **Android-only**; an iOS build path is not yet wired.
- `/mobile-build-check` is a static scan. It cannot run the real Unity build, measure
  device performance, or verify that consent *behaves* correctly — only that the ordering
  and declarations are in place.
- Six of this edition's skills have no behavioural spec in the testing framework yet.
  `/skill-test static` works; `/skill-test spec` needs a spec written first.
- `UPGRADING.md`, `CONTRIBUTING.md`, and `SECURITY.md` are inherited from upstream and
  describe that project's conventions, not this one's.

---

## Attribution

Derived from
[Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios) and its
Unity Mobile edition by **Donchitos**, under the MIT License. The original copyright notice
is retained in [LICENSE](LICENSE).

This edition narrows that work to mobile puzzle development on the CuOCore suite: the
engine set was reduced to Unity, the agent and skill sets were trimmed, an MVP-first phase
was added ahead of design work, and the rules were rewritten around the adapter boundary
and feature-flag mechanics.

## Changelog

See [CHANGELOG.md](CHANGELOG.md). Current version is in [VERSION](VERSION).

## License

MIT. See [LICENSE](LICENSE).
