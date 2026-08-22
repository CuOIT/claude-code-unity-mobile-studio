# Claude Code Unity Mobile Puzzle Studio

Mobile puzzle game development on Unity, built on the in-house **CuOCore** UPM suite,
managed through coordinated Claude Code subagents. Each agent owns a specific domain,
enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: Unity 6 — exact release read from the project, never assumed
- **Language**: C# 9+
- **Rendering**: Universal Render Pipeline (URP)
- **Target Platforms**: iOS / Android
- **Input**: Touch (New Input System)
- **Architecture layer**: CuOCore UPM suite (`com.cuongbs.*`, `com.cuobs.ui`)
- **Async**: UniTask
- **Version Control**: Git with trunk-based development
- **Asset Pipeline**: Resources by default; Addressables only when remote content exists

> **Version policy**: this project records **capabilities**, not pinned versions.
> Read versions from `ProjectSettings/ProjectVersion.txt` and `Packages/manifest.json`
> when they matter, and ask when a version genuinely changes a decision. Never state a
> version from memory.

> **Before proposing any service, manager, or infrastructure code**, read
> `.claude/docs/cuocore-map.md`. Most of it already exists as a tested contract.

## Active Profile

@.claude/docs/puzzle-profile.md

## CuOCore Capability Map

@.claude/docs/cuocore-map.md

## Project Structure

@.claude/docs/directory-structure.md

## Engine Capability Reference

@docs/engine-reference/unity/VERSION.md

@docs/engine-reference/unity/MOBILE-BEST-PRACTICES.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** Run `/start` for guided onboarding, or `/puzzle-mvp --mode demo`
> if the concept is already clear and you want something playable first.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md
