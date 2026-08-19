---
name: setup-engine
description: "Configure the Unity engine version for a mobile project. Pins Unity 6 LTS in CLAUDE.md, configures the scripting backend (IL2CPP vs Mono) and build targets (iOS/Android), detects knowledge gaps, and populates engine reference docs via WebSearch when the version is beyond the LLM's training data."
argument-hint: "[unity version] | refresh | upgrade [old-version] [new-version] | no args for guided setup"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, WebSearch, WebFetch, Task, AskUserQuestion
model: sonnet
---

When this skill is invoked:

## 1. Parse Arguments

Four modes:

This edition ships Unity only — the engine cannot be changed. Modes:

- **Full spec**: `/setup-engine unity 6.3` — version provided
- **No args**: `/setup-engine` — guided setup (platform, scripting backend, build targets)
- **Refresh**: `/setup-engine refresh` — update reference docs (see Section 10)
- **Upgrade**: `/setup-engine upgrade [old-version] [new-version]` — migrate to a new Unity version (see Section 11)

---

## 2. Guided Mode (No Arguments)

Run an interactive mobile project setup process:

### Check for existing game concept
- Read `design/gdd/game-concept.md` if it exists — extract genre, scope, platform
  targets, art style, and team size from `/brainstorm`
- If no concept exists, inform the user:
  > "No game concept found. Consider running `/brainstorm` first to discover what
  > you want to build. Or tell me about your game and we can set up the Unity
  > mobile stack directly."

### Guided questions (ask in order via `AskUserQuestion`)

1. **Target platform(s)**:
   - Options: `Android only` / `iOS only` / `Both iOS + Android` / `I'll decide later`
   - Default recommendation: `Both iOS + Android` — the Unity agent set and mobile
     rules in this edition are optimized for dual mobile targets.
2. **Minimum device tier** (determines performance budgets):
   - Options: `[A] Budget (low-end Android, 3-4 yr old devices)` / `[B] Mid-range (default)` / `[C] Flagship only`
   - Default: `[B]`. The budget-tier choice lowers draw call, texture, and
     triangle budgets (see `docs/engine-reference/unity/MOBILE-BEST-PRACTICES.md`).
3. **Scripting backend** (only for users who ask):
   - Options: `[A] IL2CPP (recommended for release — smaller, faster)` / `[B] Mono (recommended for development — faster iteration)`
   - Default: Mono for day-to-day development, IL2CPP for release builds.
     Record the choice in `technical-preferences.md`.
4. **Project scope hints**: 2D vs 3D, primary genre, expected asset size — these
   feed the render pipeline confirmation below (URP is the default for all mobile).

### Produce the configuration

Present a configuration summary table with the user's answers as rows, plus the
fixed stack of this edition (Unity 6 LTS, C# 9+, URP, New Input System, UI Toolkit,
Addressables), and confirm with `AskUserQuestion`:

> "Here is the proposed Unity mobile configuration. Any adjustments, or shall I
> write it to CLAUDE.md and technical-preferences.md?"

Never force a verdict — always let the user confirm the final values.

---

## 3. Look Up Current Version

- If version was provided, use it
- If no version provided, use WebSearch to find the latest Unity 6 LTS release:
  - Search: `"Unity 6 LTS latest release [current year]"`
  - Confirm with the user: "The latest Unity 6 LTS is [version]. Use this?"

---

## 4. Update CLAUDE.md Technology Stack

### Scripting Backend Selection

Before showing the proposed Technology Stack, confirm the scripting backend if
not already chosen in Section 2:

> "Which scripting backend should be configured for builds?
>
>   **A) IL2CPP** — smaller builds, faster execution, slower iteration. Required
>      for most app store distribution.
>   **B) Mono** — fastest script iteration for development. Larger builds.
>   **C) Both** — Mono for development builds, IL2CPP for release builds (recommended).
>
> Which configuration will this project use?"

Record the choice in `technical-preferences.md`. It determines the build
configuration guidance and test runner settings for the project.

---

Read `CLAUDE.md` and show the user the proposed Technology Stack changes.
Ask: "May I write these engine settings to `CLAUDE.md`?"

Wait for confirmation before making any edits.

Update the Technology Stack section with this template:

```markdown
- **Engine**: Unity [version] (LTS)
- **Language**: C# 9+ (.NET 8+)
- **Rendering**: Universal Render Pipeline (URP)
- **Scripting Backend**: [IL2CPP | Mono | Both]
- **Build System**: Unity Build Pipeline (IL2CPP for release)
- **Asset Pipeline**: Unity Asset Import Pipeline + Addressables
```

---

## 5. Populate Technical Preferences

After updating CLAUDE.md, create or update `.claude/docs/technical-preferences.md` with
engine-appropriate defaults. Read the existing template first, then fill in:

### Engine & Language Section
- Fill from the engine choice made in step 4

### Naming Conventions (engine defaults)

**For Unity (C#):**
- Classes: PascalCase (e.g., `PlayerController`)
- Public fields/properties: PascalCase (e.g., `MoveSpeed`)
- Private fields: _camelCase (e.g., `_moveSpeed`)
- Methods: PascalCase (e.g., `TakeDamage()`)
- Files: PascalCase matching class (e.g., `PlayerController.cs`)
- Constants: PascalCase or UPPER_SNAKE_CASE

### Input & Platform Section

Populate `## Input & Platform` using the answers gathered in Section 2 (or extracted
from the game concept). Derive the values using this mapping:

| Platform target | Gamepad Support | Touch Support |
|-----------------|-----------------|---------------|
| PC only | Partial (recommended) | None |
| Console | Full | None |
| Mobile | None | Full |
| PC + Console | Full | None |
| PC + Mobile | Partial | Full |
| Web | Partial | Partial |

For **Primary Input**, use the dominant input for the game genre:
- Action/RPG/platformer targeting console → Gamepad
- Strategy/point-and-click/RTS → Keyboard/Mouse
- Mobile game → Touch
- Cross-platform → ask the user

Present the derived values and ask the user to confirm or adjust before writing.

Example filled section:
```markdown
## Input & Platform
- **Target Platforms**: PC, Console
- **Input Methods**: Keyboard/Mouse, Gamepad
- **Primary Input**: Gamepad
- **Gamepad Support**: Full
- **Touch Support**: None
- **Platform Notes**: All UI must support d-pad navigation. No hover-only interactions.
```

### Remaining Sections
- **Performance Budgets**: Use `AskUserQuestion`:
  - Prompt: "Should I set default performance budgets now, or leave them for later?"
  - Options: `[A] Set defaults now (60fps, 16.6ms frame budget, engine-appropriate draw call limit)` / `[B] Leave as [TO BE CONFIGURED] — I'll set these when I know my target hardware`
  - If [A]: populate with the suggested defaults. If [B]: leave as placeholder.
- **Testing**: Suggest Unity Test Framework (NUnit-based, Edit Mode + Play Mode
runners) — ask before adding.
- **Forbidden Patterns**: Leave as placeholder — do NOT pre-populate.
- **Allowed Libraries**: Leave as placeholder — do NOT pre-populate dependencies the project does not currently need. Only add a library here when it is actively being integrated, not speculatively.

> **Guardrail**: Never add speculative dependencies to Allowed Libraries. For example,
> do NOT add Unity Ads or any third-party SDK unless that integration is actively
> beginning in this session. Post-launch integrations should be added to Allowed
> Libraries when that work begins, not during engine setup.

### Engine Specialists Routing

Also populate the `## Engine Specialists` section in `technical-preferences.md` with the correct routing for the chosen engine:

### Engine Specialists Routing (Unity set only)
```markdown
## Engine Specialists
- **Primary**: unity-specialist
- **Language/Code Specialist**: unity-specialist (C# review — primary covers it)
- **Shader Specialist**: unity-shader-specialist (Shader Graph, HLSL, URP/HDRP materials)
- **UI Specialist**: unity-ui-specialist (UI Toolkit UXML/USS, UGUI Canvas, runtime UI)
- **Additional Specialists**: unity-dots-specialist (ECS, Jobs system, Burst compiler), unity-addressables-specialist (asset loading, memory management, content catalogs)
- **Routing Notes**: Invoke primary for architecture and general C# code review. Invoke DOTS specialist for any ECS/Jobs/Burst code. Invoke shader specialist for rendering and visual effects. Invoke UI specialist for all interface implementation. Invoke Addressables specialist for asset management systems.

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.cs files) | unity-specialist |
| Shader / material files (.shader, .shadergraph, .mat) | unity-shader-specialist |
| UI / screen files (.uxml, .uss, Canvas prefabs) | unity-ui-specialist |
| Scene / prefab / level files (.unity, .prefab) | unity-specialist |
| Native extension / plugin files (.dll, native plugins) | unity-specialist |
| General architecture review | unity-specialist |
```

### Collaborative Step
Present the filled-in preferences to the user:
> "Here are the default technical preferences for Unity ([scripting backend]). The naming conventions and specialist routing are recorded above. Want to customize any of these, or shall I save the defaults?"

Wait for approval before writing the file.

---

## 6. Determine Knowledge Gap

Check whether the engine version is likely beyond the LLM's training data.

**Known approximate coverage** (update this as models change):
- LLM knowledge cutoff: **May 2025**
- Unity: training data likely covers up to ~2023.x / early 6000.x

Compare the user's chosen version against these baselines:

- **Within training data** → `LOW RISK` — reference docs optional but recommended
- **Near the edge** → `MEDIUM RISK` — reference docs recommended
- **Beyond training data** → `HIGH RISK` — reference docs required

For Unity 6.3 LTS, this is `HIGH RISK` — the shipped reference docs under
`docs/engine-reference/unity/` and `MOBILE-BEST-PRACTICES.md` already cover the
gap; use `refresh` to keep them current.

For Unity 6.3 LTS, this is `HIGH RISK` — the shipped reference docs under
`docs/engine-reference/unity/` and `MOBILE-BEST-PRACTICES.md` already cover the
gap; use `refresh` to keep them current.

Inform the user which category they're in and why.

---

## 7. Populate Engine Reference Docs

### If WITHIN training data (LOW RISK):

Create a minimal `docs/engine-reference/<engine>/VERSION.md`:

```markdown
# [Engine] — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | [version] |
| **Project Pinned** | [today's date] |
| **LLM Knowledge Cutoff** | May 2025 |
| **Risk Level** | LOW — version is within LLM training data |

## Note

This engine version is within the LLM's training data. Engine reference
docs are optional but can be added later if agents suggest incorrect APIs.

Run `/setup-engine refresh` to populate full reference docs at any time.
```

Do NOT create breaking-changes.md, deprecated-apis.md, etc. — they would
add context cost with minimal value.

### If BEYOND training data (MEDIUM or HIGH RISK):

Create the full reference doc set by searching the web:

1. **Search for the official migration/upgrade guide**:
   - `"[engine] [old version] to [new version] migration guide"`
   - `"[engine] [version] breaking changes"`
   - `"[engine] [version] changelog"`
   - `"[engine] [version] deprecated API"`

2. **Fetch and extract** from official documentation:
   - Breaking changes between each version from the training cutoff to current
   - Deprecated APIs with replacements
   - New features and best practices

Ask: "May I create the engine reference docs under `docs/engine-reference/<engine>/`?"

Wait for confirmation before writing any files.

3. **Create the full reference directory**:
   ```
   docs/engine-reference/<engine>/
   ├── VERSION.md              # Version pin + knowledge gap analysis
   ├── breaking-changes.md     # Version-by-version breaking changes
   ├── deprecated-apis.md      # "Don't use X → Use Y" tables
   ├── current-best-practices.md  # New practices since training cutoff
   └── modules/                # Per-subsystem references (create as needed)
   ```

4. **Populate each file** using real data from the web searches, following
   the format established in existing reference docs. Every file must have
   a "Last verified: [date]" header.

5. **For module files**: Only create modules for subsystems where significant
   changes occurred. Don't create empty or minimal module files.

---

## 8. Update CLAUDE.md Import

Ask: "May I update the `@` import in `CLAUDE.md` to point to the new engine reference?"

Wait for confirmation, then update the `@` import under "Engine Version Reference" to point to the
correct engine:

```markdown
## Engine Version Reference

@docs/engine-reference/<engine>/VERSION.md
```

If the previous import pointed to a different engine
(e.g., when migrating from an older Unity version), update it.

---

## 9. Update Agent Instructions

Ask: "May I add a Version Awareness section to the engine specialist agent files?" before making any edits.

For the chosen engine's specialist agents, verify they have a
"Version Awareness" section. If not, add one following the pattern in
the existing unity-specialist agent (Version Awareness section).

The section should instruct the agent to:
1. Read `docs/engine-reference/<engine>/VERSION.md`
2. Check deprecated APIs before suggesting code
3. Check breaking changes for relevant version transitions
4. Use WebSearch to verify uncertain APIs

---

## 10. Refresh Subcommand

If invoked as `/setup-engine refresh`:

1. Read the existing `docs/engine-reference/<engine>/VERSION.md` to get
   the current engine and version
2. Use WebSearch to check for:
   - New engine releases since last verification
   - Updated migration guides
   - Newly deprecated APIs
3. Update all reference docs with new findings
4. Update "Last verified" dates on all modified files
5. Report what changed

---

## 11. Upgrade Subcommand

If invoked as `/setup-engine upgrade [old-version] [new-version]`:

### Step 1 — Read Current Version State

Read `docs/engine-reference/<engine>/VERSION.md` to confirm the current pinned
version, risk level, and any migration note URLs already recorded. If
`old-version` was not provided as an argument, use the pinned version from this
file.

### Step 2 — Fetch Migration Guide

Use WebSearch and WebFetch to locate the official migration guide between
`old-version` and `new-version`:

- Search: `"[engine] [old-version] to [new-version] migration guide"`
- Search: `"[engine] [new-version] breaking changes changelog"`
- Fetch the migration guide URL from VERSION.md if one is already recorded,
  or use the URL found via search.

Extract: renamed APIs, removed APIs, changed defaults, behavior changes, and
any "must migrate" items.

### Step 3 — Pre-Upgrade Audit

Scan `src/` for code that uses APIs known to be deprecated or changed in the
target version:

- Use Grep to search for deprecated API names extracted from the migration
  guide (e.g., old function names, removed node types, changed property names)
- List each file that matches, with the specific API reference found

Present the audit results as a table:

```
Pre-Upgrade Audit: [engine] [old-version] → [new-version]
==========================================================

Files requiring changes:
  File                              | Deprecated API Found       | Effort
  --------------------------------- | -------------------------- | ------
  src/gameplay/player_movement.gd   | old_api_name               | Low
  src/ui/hud.gd                     | removed_node_type          | Medium

Breaking changes to watch for:
  - [change description from migration guide]
  - [change description from migration guide]

Recommended migration order (dependency-sorted):
  1. [system/layer with fewest dependencies first]
  2. [next system]
  ...
```

If no deprecated APIs are found in `src/`, report: "No deprecated API usage
found in src/ — upgrade may be low-risk."

### Step 4 — Confirm Before Updating

Ask the user before making any changes:

> "Pre-upgrade audit complete. Found [N] files using deprecated APIs.
> Proceed with upgrading VERSION.md to [new-version]?
> (This will update the pinned version and add migration notes — it does NOT
> change any source files. Source migration is done manually or via stories.)"

Wait for explicit confirmation before continuing.

### Step 5 — Update VERSION.md

After confirmation:

1. Update `docs/engine-reference/<engine>/VERSION.md`:
   - `Engine Version` → `[new-version]`
   - `Project Pinned` → today's date
   - `Last Docs Verified` → today's date
   - Re-evaluate and update the `Risk Level` and `Post-Cutoff Version Timeline`
     table if the new version falls beyond the LLM knowledge cutoff
   - Add a `## Migration Notes — [old-version] → [new-version]` section
     containing: migration guide URL, key breaking changes, deprecated APIs
     found in this project, and recommended migration order from the audit

2. If `breaking-changes.md` or `deprecated-apis.md` exist in the engine
   reference directory, append the new version's changes to those files.

### Step 6 — Post-Upgrade Reminder

After updating VERSION.md, output:

```
VERSION.md updated: [engine] [old-version] → [new-version]

Next steps:
1. Migrate deprecated API usages in the [N] files listed above
2. Run /setup-engine refresh after upgrading the actual engine binary to
   verify no new deprecations were missed
3. Run /architecture-review — the engine upgrade may invalidate ADRs that
   reference specific APIs or engine capabilities
4. If any ADRs are invalidated, run /propagate-design-change to update
   downstream stories
```

---

## 12. Output Summary

After setup is complete, output:

```
Engine Setup Complete
=====================
Engine:          Unity [version] LTS
Language:        C# 9+ (.NET 8+)
Knowledge Risk:  [LOW/MEDIUM/HIGH]
Reference Docs:  [created/skipped]
CLAUDE.md:       [updated]
Tech Prefs:      [created/updated]
Agent Config:    [verified]

Next Steps:
1. Review docs/engine-reference/<engine>/VERSION.md
2. [If from /brainstorm] Run /map-systems to decompose your concept into individual systems
3. [If from /brainstorm] Run /design-system to author per-system GDDs (guided, section-by-section)
4. [If from /brainstorm] Run /prototype [core-mechanic] to validate the core idea before writing GDDs
5. [If fresh start] Run /brainstorm to discover your game concept
6. Create your first milestone: /sprint-plan new
```

---

Verdict: **COMPLETE** — engine configured and reference docs populated.

## Guardrails

- NEVER guess an engine version — always verify via WebSearch or user confirmation
- NEVER overwrite existing reference docs without asking — append or update
- If reference docs already exist for a different engine, ask before replacing
- Always show the user what you're about to change before making CLAUDE.md edits
- If WebSearch returns ambiguous results, show the user and let them decide
- When configuring release builds, always recommend IL2CPP and the current app
  store SDK requirements (latest Android API level, minimum iOS version)
  verified via WebSearch

---

## Appendix A — Unity Mobile Build Configuration

Reference tables for mobile build decisions, used by Sections 4 and 5.

### A1. Android Build Essentials

| Setting | Recommended value | Notes |
|---------|-------------------|-------|
| Build system | Gradle with IL2CPP | Unity Gradle build; IL2CPP for release |
| Minimum API Level | 23+ | Google Play minimum — confirm latest via WebSearch |
| Target API Level | Latest stable | Must follow Google Play policy |
| Architecture | arm64-v8a | 64-bit required by Google Play |
| Keystore | Project keystore, never committed to repo | Sign release AAB |
| Distribution | Android App Bundle (AAB) | Google Play only accepts AAB |

### A2. iOS Build Essentials

| Setting | Recommended value | Notes |
|---------|-------------------|-------|
| Export | Build iOS project → archive in Xcode on a Mac | Or use Unity Cloud Build |
| Minimum iOS version | Latest 2 major versions | Confirm current App Store policy via WebSearch |
| Provisioning | Automatic signing with team ID | Requires Apple Developer Program account |
| Test builds | arm64 simulator builds | Faster UI iteration than device |

-
