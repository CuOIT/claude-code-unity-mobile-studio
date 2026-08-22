# Directory Structure

`.claude/` sits at the root of the Unity project — that is the only arrangement that
works, because Claude Code loads it from the working directory.

Reached either way: by creating the Unity project at this repo's root (greenfield), or by
running `tools/install-into-unity-project.sh` to copy the config into a project that
already has its own git history. The resulting layout is the same.

```text
/
├── CLAUDE.md                       # Master configuration
├── .claude/                        # Agents, skills, hooks, rules, docs
│
├── Assets/                         # ── THE UNITY PROJECT ──
│   ├── Scripts/                    # All first-party C#. Rules scope here.
│   │   ├── Services/
│   │   │   ├── Abstractions/       # Contracts NOT covered by CuOCore (e.g. IConsentService)
│   │   │   ├── Adapters.Bravestars/# Vendor adapters — the ONLY place SDK types may appear
│   │   │   ├── Adapters.Kit/       # Adapters onto the in-house kit layer
│   │   │   └── Adapters.Null/      # Null/fake impls for editor, tests, demo mode
│   │   ├── Core/                   # Composition root, bootstrap ordering
│   │   ├── Gameplay/
│   │   │   └── Puzzle/             # Puzzle rules — deterministic, scene-free, testable
│   │   └── UI/                     # Screen and popup implementations
│   ├── Tests/
│   │   ├── EditMode/               # Rules, formulas, flags, adapter contracts
│   │   └── PlayMode/               # End-to-end: boot → gameplay → win/lose → retry
│   ├── Resources/                  # SO configs, level prefabs, UI panels (see loading matrix)
│   ├── Shaders/                    # Shader graphs and HLSL
│   ├── Audio/                      # Music, SFX, VO
│   ├── Sprites/  Textures/  Spine/ # Art
│   └── Plugins/                    # Third-party native and SDK drops
│
├── Packages/                       # UPM manifest — CuOCore consumed here, never forked
├── ProjectSettings/                # Unity project settings (read versions from here)
│
├── design/                         # Design documents — NOT Unity assets
│   ├── gdd/                        # game-concept.md, per-system GDDs, systems-index.md
│   ├── art/                        # art-bible.md
│   ├── ux/                         # per-screen specs, hud.md
│   └── registry/entities.yaml      # Cross-document game facts
│
├── docs/
│   ├── architecture/               # architecture.md, adr-*.md, control-manifest.md
│   ├── registry/
│   │   ├── services.yaml           # Adapter status per contract
│   │   └── feature-flags.yaml      # Flag inventory across all three tiers
│   └── engine-reference/unity/     # Engine + SDK capability reference
│
└── production/
    ├── mvp-report.md               # The MVP verdict — gates everything after it
    ├── epics/  sprints/  playtests/
    ├── stage.txt                   # Current phase (written by /gate-check)
    ├── review-mode.txt             # full | lean | solo
    ├── session-state/active.md     # Ephemeral session checkpoint (gitignored)
    └── session-logs/               # Session audit trail (gitignored)
```

## Why code lives under `Assets/Scripts/`, not `src/`

Unity only compiles code under `Assets/` and `Packages/`. A `src/` directory at the root
is invisible to the compiler — and, more dangerously, invisible to every path-scoped rule
and hook, which would then silently enforce nothing.

All four reference titles on this machine put first-party code under `Assets/`. This
project follows that, and every rule scope, hook guard, and skill grep targets
`Assets/Scripts/` to match.

## Assembly boundaries

One assembly definition per module under `Assets/Scripts/`. The critical constraint:

- `Services/Abstractions/` and `Gameplay/` must reference **no** vendor SDK assembly
- only `Services/Adapters.*` may

This makes the adapter boundary a compile error rather than a convention.
`/mobile-build-check` verifies it by reading the `.asmdef` reference arrays directly.

## What is not here

CuOCore packages are consumed via UPM under `Packages/`. Never copy one into `Assets/` —
see `.claude/rules/upm-consumption.md`. That copy-paste is what caused the previous
generation of shared code to diverge three ways across shipped titles.
