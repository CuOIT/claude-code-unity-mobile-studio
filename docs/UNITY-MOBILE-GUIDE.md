# Unity Mobile Edition — Working Guide

This guide explains how to work with this Unity 6 LTS / iOS / Android edition
effectively. Read it once before your first real session.

## What This Edition Is

Claude Code Unity Mobile Studio is the Claude Code Game Studios agent
architecture, narrowed to a single engine and platform target. The upstream
template supported three engines (Godot, Unity, Unreal) and any platform; this
edition pins **Unity 6.3 LTS** and **iOS + Android** so that every skill, rule,
and agent operates with mobile-specific knowledge instead of engine-agnostic
defaults.

The context savings matter: agents no longer carry Godot/Unreal agent sets,
multi-engine routing logic, or engine-comparison decision trees in their
instructions. Every path-scoped rule and code example is written in C# against
the Unity API (URP, UI Toolkit, Addressables, New Input System, Unity Test
Runner).

## Core Loop

1. Run `/start` for guided onboarding, or `/setup-engine` directly — the mobile
   profile writes iOS/Android defaults (ASTC textures, IL2CPP, quality tiers,
   frame budgets) into `.claude/docs/technical-preferences.md`.
2. Design phase (`/brainstorm` → `/map-systems` → `/design-system`) produces
   GDDs and ADRs like upstream.
3. Implementation (`/create-epics` → `/create-stories` → `/dev-story`) is where
   the mobile rules bite: `mobile-code.md` and `engine-code.md` forbid hot-path
   allocations, `Resources.Load`, and un-pooled instantiation.
4. Before any PR or release candidate, run `/mobile-build-check` — a static
   pre-flight that catches IL2CPP misconfiguration, Addressables handle leaks,
   oversized textures, unsafe-area violations, and mono-backend release builds
   **without a Unity editor**.
5. The definitive build runs in CI (`game-ci/unity-actions`) or your local
   editor. This template intentionally does not contain a Unity editor; the
   workflow covers design → code → QA, and CI covers binary → store.

## Files You Will Touch Most

| File | Purpose |
|------|---------|
| `.claude/docs/technical-preferences.md` | Mobile budgets and build settings; edit to override defaults |
| `docs/engine-reference/unity/VERSION.md` | Unity 6.3 LTS knowledge-gap warning and API timeline |
| `docs/engine-reference/unity/MOBILE-BEST-PRACTICES.md` | Per-platform budgets, URP mobile settings, GC hygiene |
| `.claude/rules/mobile-code.md` | Enforced standards for `assets/` and `src/` |
| `.claude/rules/engine-code.md` | Zero-alloc hot paths (C# examples) |

## Where the Upstream Logic Still Applies

Everything that is engine-agnostic — the studio hierarchy, director gates,
sprint workflow, QA skills, design processes, hooks — is unchanged and
identical to upstream. The differences are: fewer engine agents (39 vs 49),
one more skill (`/mobile-build-check`), one more rule (`mobile-code.md`), and
all code-facing content rewritten for Unity C# and mobile constraints.

## Known Limitations

The agent layer cannot execute the Unity editor, so it cannot compile IL2CPP,
measure real frame times, or run the Unity Test Runner directly. Device-level
verification (thermal throttling, low-end profiling on a Snapdragon 6xx-class
phone, TestFlight installs) remains manual. Treat `/mobile-build-check` as a
necessary pre-flight, not a substitute for on-device testing.
