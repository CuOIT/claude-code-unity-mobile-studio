# Claude Code Unity Mobile Studio -- Game Studio Agent Architecture

Mobile-first indie game development on Unity, managed through coordinated
Claude Code subagents. Each agent owns a specific domain, enforcing separation
of concerns and quality.

## Technology Stack

- **Engine**: Unity 6 LTS
- **Language**: C# 9+ (.NET 8+)
- **Rendering**: Universal Render Pipeline (URP)
- **Target Platforms**: iOS / Android
- **Input**: Touch (New Input System)
- **Version Control**: Git with trunk-based development
- **Build System**: Unity Cloud Build or GitHub Actions + game-ci/unity-actions
- **Asset Pipeline**: Addressables for async loading and content updates

> **Note**: This edition ships only the Unity agent set (unity-specialist plus
> four sub-specialists). Godot and Unreal agent sets were removed to reduce
> context and stay focused on mobile development.

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

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

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md
