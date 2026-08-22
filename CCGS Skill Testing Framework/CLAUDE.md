# CCGS Skill Testing Framework — Claude Instructions

This folder is the quality assurance layer for the Claude Code Game Studios skill/agent
framework. It is self-contained and separate from any game project.

## Key files

| File | Purpose |
|------|---------|
| `catalog.yaml` | Master registry for all 58 skills and 27 agents. Contains category, spec path, and last-test tracking fields. Always read this first when running any test command. |
| `quality-rubric.md` | Category-specific pass/fail metrics. Read the matching `###` section for the skill's category when running `/skill-test category`. |
| `skills/[category]/[name].md` | Behavioral spec for a skill — 5 test cases + protocol compliance assertions. |
| `agents/[tier]/[name].md` | Behavioral spec for an agent — 5 test cases + protocol compliance assertions. |
| `templates/skill-test-spec.md` | Template for writing new skill spec files. |
| `templates/agent-test-spec.md` | Template for writing new agent spec files. |
| `results/` | Written by `/skill-test spec` when results are saved. Gitignored. |

## Path conventions

- Skill specs: `CCGS Skill Testing Framework/skills/[category]/[name].md`
- Agent specs: `CCGS Skill Testing Framework/agents/[tier]/[name].md`
- Catalog: `CCGS Skill Testing Framework/catalog.yaml`
- Rubric: `CCGS Skill Testing Framework/quality-rubric.md`

The `spec:` field in `catalog.yaml` is the authoritative path for each skill/agent spec.
Always read it rather than guessing the path.

## Skill categories

```
gate → gate-check
review → design-review, architecture-review, review-all-gdds
authoring → design-system, quick-design, architecture-decision, art-bible,
 create-architecture, ux-design, ux-review
readiness → story-readiness, story-done
pipeline → create-epics, create-stories, dev-story, create-control-manifest,
 propagate-design-change, map-systems
analysis → consistency-check, balance-check, code-review,
 tech-debt, perf-profile
team → team-combat, team-level, team-ui,
 team-qa, team-release, team-polish, team-live-ops
sprint → sprint-plan, sprint-status, retrospective,
 changelog, patch-notes
utility → all remaining skills
```

## Agent tiers

```
directors → creative-director, technical-director, producer, art-director
leads → lead-programmer, ux-designer,
 qa-lead, release-manager
specialists → gameplay-programmer, ui-programmer,
 tools-programmer, sound-designer, technical-artist
unity → unity-specialist, unity-ui-specialist, unity-shader-specialist, unity-addressables-specialist
operations → devops-engineer, performance-analyst,
 analytics-engineer
creative → game-designer, economy-designer,
 systems-designer
```

## Workflow for testing a skill

1. Read `catalog.yaml` to get the skill's `spec:` path and `category:`
2. Read the skill at `.claude/skills/[name]/SKILL.md`
3. Read the spec at the `spec:` path
4. Evaluate assertions case by case
5. Offer to write results to `results/` and update `catalog.yaml`

## Workflow for improving a skill

Use `/ [name]`. It handles the full loop:
test → diagnose → propose fix → rewrite → retest → keep or revert.

## Spec validity note

Specs in this folder describe **current behavior**, not ideal behavior. They were
written by reading the skills, so they may encode bugs. When a skill misbehaves in
practice, correct the skill first, then update the spec to match the fixed behavior.
Treat spec failures as "this needs investigation," not "the skill is definitively wrong."

## This folder is deletable

Nothing in `.claude/` imports from here. Deleting this folder has no effect on the
CCGS skills or agents themselves. `/skill-test` and `/` will report that
`catalog.yaml` is missing and guide the user to initialize it.
