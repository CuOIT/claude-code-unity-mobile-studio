# Changelog

Versions describe **this configuration**, not any game built with it.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning is [semantic](https://semver.org/) with respect to the workflow contract: a
major bump means existing phase names, path scopes, or command names changed in a way that
breaks a project already using the previous version.

---

## [2.0.0] — 2026-08-21

Re-profiled from a general Unity mobile game-studio template into a **mobile puzzle**
configuration built on the in-house CuOCore UPM suite.

**Breaking.** Phase names changed, path scopes moved, and 34 commands were archived. A
project already running v1.x will not work against this without the migration below.

### Added

- **`/puzzle-mvp`** — the MVP fast lane, with two modes. `--mode demo` for speed to
  something demonstrable; `--mode signal` for a soft-launch build. MVP code is **kept**;
  Production continues from it rather than replacing it.
- **`/sdk-integrate`** — writes an adapter from an existing CuOCore contract onto a real
  vendor SDK. Checks the registry first so no parallel interface gets written, and refuses
  to let ads initialise before consent resolves.
- **`/feature-flag`** — add, list, or audit flags across all three tiers. `audit` catches
  flags read in code but never declared.
- **`/level-pipeline`** — decide and scaffold how levels are authored, stored, ordered,
  and validated. Presents the three approaches proven in this studio's shipped titles.
- **New phase: `mvp`**, sitting second — before systems design, before architecture.
- **`docs/registry/services.yaml`** — adapter status per contract. 12 contracts tracked.
- **`docs/registry/feature-flags.yaml`** — flag inventory across all three tiers.
- **`.claude/docs/cuocore-map.md`** — maps all 22 CuOCore packages to what they provide
  and which adapters are missing. The document every infrastructure task starts at.
- **`.claude/docs/puzzle-profile.md`** — the active profile, plus an anti-pattern table
  where every row cites a specific failure observed in real shipped code on this machine.
- **Agents**: `mobile-sdk-engineer` (owns the whole service layer — nobody owned it
  before), `puzzle-level-designer` (replaces the 3D-spatial `level-designer`).
- **Rules**: `service-layer.md`, `feature-flags.md`, `puzzle-code.md`, `code-health.md`,
  `upm-consumption.md`.
- **Hooks**: `scan-secrets.sh` (blocks commits containing credential patterns),
  `validate-flag-registry.sh` (flags undeclared feature-flag reads),
  `validate-upm-manifest.sh` (local `file:` refs, embedded credentials, duplicate keys).
- **Gates**: `TD-ADAPTER-BOUNDARY`, `TD-CONSENT-GATE`, `TD-FLAG-AUDIT`, `PR-MVP-VERDICT`.
  The first two ignore review mode — they guard store submission, not review quality.
- **`tools/install-into-unity-project.sh`** — installs this config into an existing Unity
  project. Dry-run by default, never silently overwrites, rewrites path scopes via
  `--code-root`.
- **`/mobile-build-check`** extended from 5 to 10 check groups: adapter boundary, consent
  ordering, flag declarations, silent `#if` exclusions, UPM manifest health, secrets,
  test coverage, code health.

### Changed

- **BREAKING — path scopes moved from `src/**` to `Assets/Scripts/**`.** Unity compiles
  only what is under `Assets/` and `Packages/`. Six rules, one hook, and four skills were
  scoped to a directory Unity ignores, so they enforced nothing — silently. All rule
  scopes, hook guards, and skill greps now target the Unity layout.
- **BREAKING — phase order.** `Pre-Production` was removed; `MVP` was added second.
  New chain: `Concept → MVP → Systems Design → Technical Setup → Production → Polish →
  Release`. `/gate-check` now has six gates matching it.
- **BREAKING — required artifacts before the first line of gameplay code: 17 → 2**
  (`technical-preferences.md`, `game-concept.md`). Art bible, UX specs, accessibility
  requirements, control manifest, per-system GDDs, cross-GDD review, and architecture
  review are all still here — sequenced after the MVP verdict, because a mechanic that
  does not work makes every one of them wasted.
- **Asset-loading stance corrected.** The previous rule forbade `Resources.Load` outright
  and mandated Addressables. All five reference codebases on this machine ship on
  Resources — three carry Addressables installed with zero or near-zero call sites. The
  rule is now a matrix by asset category and MVP mode, and Addressables is not installed
  until there is genuine remote content to update.
- **Version policy: capabilities, not pins.** `docs/engine-reference/unity/VERSION.md`
  records which vendor serves which capability, deliberately without version numbers.
  Unity and package versions are read from the project on disk at the moment of use.
  `/setup-engine` now asks rather than pinning.
- **`mobile-code.md` fixed** — it shipped without YAML frontmatter, so it never scoped to
  anything and had no effect since the day it was added.
- `/prototype` retargeted to spikes only. Concept prototyping moved to `/puzzle-mvp`.
- `/team-level` → `/team-puzzle-level`, rewritten for level batches: teaching order, rule
  coverage, board readability, solvability.
- `README.md` rewritten for this edition. Upstream sponsor and community links removed;
  MIT attribution retained.

### Removed

Archived under `_archived/`, not deleted. Restore if the project's shape changes.

- **12 agents** — narrative (`narrative-director`, `writer`, `world-builder`), systems
  absent from a puzzle game (`network-programmer`, `ai-programmer`,
  `unity-dots-specialist`), and roles folded into survivors (`engine-programmer`,
  `accessibility-specialist`, `security-engineer`, `localization-lead`, `prototyper`,
  `audio-director`, `community-manager`). Zero of four reference titles use DOTS.
- **`level-designer`** — replaced by `puzzle-level-designer`.
- **20 skills** — including `/vertical-slice` (superseded by `/puzzle-mvp --mode signal`),
  `/adopt`, `/reverse-document`, `/onboard`, `/estimate`, `/scope-check`,
  `/milestone-review`, `/security-audit`, `/soak-test`, `/team-narrative`, `/team-audio`.
- **5 rules** — `ai-code.md`, `network-code.md`, `narrative.md`, `prototype-code.md`, and
  `engine-code.md` (merged into `code-health.md`).
- **6 templates** tied to archived skills.

Eight skills initially archived were **restored**: `smoke-check`, `architecture-review`,
`create-control-manifest`, `consistency-check`, `ux-review`, `patch-notes`,
`quick-design`, `propagate-design-change`. Each is called by four or more surviving
skills — merging them would have meant rewriting those callers, not renaming a file.

### Counts

| | v1.x | 2.0.0 |
|---|---|---|
| Agents | 39 | 27 |
| Skills | 74 | 58 |
| Rules | 12 | 12 (5 out, 5 new, 2 rewritten) |
| Hooks | 12 | 15 |
| Registries | 2 | 4 |
| Phases | 7 | 7 (one replaced) |

### Migration from v1.x

1. **Move path scopes.** If your code is not at `Assets/Scripts/`, re-run
   `tools/install-into-unity-project.sh --code-root <your path>`, or edit the `paths:`
   frontmatter in `.claude/rules/*.md` by hand. **A rule scoped to the wrong directory
   enforces nothing and reports nothing** — verify with `/mobile-build-check` and
   `/feature-flag audit`, both of which should return real findings.
2. **Update `production/stage.txt`.** `Pre-Production` no longer exists. `/gate-check`
   and `/help` will say so rather than guessing, but they cannot pick for you.
3. **Replace archived commands** in any script or habit. `.claude/docs/skills-reference.md`
   lists what each archived skill's capability moved to.
4. **Register the hooks.** Merge the `hooks` block from `.claude/settings.json` if you
   maintain your own. All 15 are needed for the guardrails to fire.

---

## [1.0.0] — upstream

Released as
[Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios) and its
Unity Mobile edition by Donchitos. See `UPGRADING.md` for that project's own version
history. MIT, attribution retained in `LICENSE`.
