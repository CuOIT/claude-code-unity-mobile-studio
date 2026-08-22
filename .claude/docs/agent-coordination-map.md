# Agent Coordination Map

How the 27 agents relate to each other. Full roster with per-agent detail:
`.claude/docs/agent-roster.md`. Coordination principles: `.claude/docs/coordination-rules.md`.

## Delegation structure

```
                    ┌─────────────────┐
                    │    producer     │  scope · timeline · coordination
                    └────────┬────────┘
        ┌────────────────────┼────────────────────┐
        │                    │                    │
┌───────▼────────┐  ┌────────▼─────────┐  ┌───────▼────────┐
│creative-director│  │technical-director│  │   qa-lead      │
│ vision · pillars│  │ architecture     │  │ test strategy  │
└───────┬────────┘  └────────┬─────────┘  └───────┬────────┘
        │                    │                    │
   ┌────┴────┐        ┌──────┴──────┐             │
   │         │        │             │             │
game-      art-    lead-       unity-        qa-tester
designer  director programmer  specialist
   │         │        │             │
   │         │        │             └─ unity-ui-specialist
   │         │        │                unity-shader-specialist
   │         │        │                unity-addressables-specialist
   │         │        │
   │         │        ├─ gameplay-programmer      ← puzzle rules
   │         │        ├─ ui-programmer
   │         │        ├─ tools-programmer         ← level tooling
   │         │        └─ mobile-sdk-engineer      ← Assets/Scripts/Services/**
   │         │
   │         └─ technical-artist
   │
   ├─ systems-designer          ← rules, formulas
   ├─ puzzle-level-designer     ← levels, curve, tutorial
   ├─ economy-designer          ← currencies, offers, sinks
   └─ live-ops-designer         ← seasons, events, retention

Independent leads:  ux-designer · release-manager
Independent specialists:  sound-designer · performance-analyst
                          analytics-engineer · devops-engineer
```

## Ownership boundaries that matter most

| Boundary | Who owns it | Why it is drawn here |
|---|---|---|
| `Assets/Scripts/Services/**` | `mobile-sdk-engineer`, exclusively | Adapters, consent, remote config, flags. Money and store compliance live here; a single owner prevents the boundary from eroding |
| Puzzle rules | `systems-designer` designs, `gameplay-programmer` implements | Rules must be deterministic and testable. Splitting design from implementation keeps the rule layer honest |
| Level content | `puzzle-level-designer` | Content, not rules. A level that needs a new rule is escalated, not worked around |
| Level tooling | `tools-programmer` | The suite has no editor windows at all, so tooling is real engineering, not a designer side task |
| Asset loading strategy | `unity-addressables-specialist` | Resources vs Addressables is a project-wide decision, not per-feature |
| Player-facing copy | `ux-designer` | No narrative agents in this profile; copy is a UX concern |

## Common collaboration paths

| Task | Sequence |
|---|---|
| New puzzle mechanic | `game-designer` → `systems-designer` (rules + formulas) → `gameplay-programmer` (implementation) → `qa-tester` (rule tests) |
| A batch of levels | `/team-puzzle-level`: `puzzle-level-designer` + `systems-designer` in parallel → `art-director` (readability) → `qa-tester` (solvability) |
| Wiring an SDK | `mobile-sdk-engineer` → `technical-director` (TD-ADAPTER-BOUNDARY gate) → `qa-tester` (contract tests) |
| A new feature flag | `mobile-sdk-engineer` (mechanics) + whoever owns the feature (default state, kill-switch need) |
| A screen | `ux-designer` (spec) → `art-director` (visual) → `ui-programmer` (implementation) → `unity-ui-specialist` (performance review) |
| Frame-rate problem | `performance-analyst` (profile on device) → `technical-artist` or `gameplay-programmer` depending on where the cost is |
| A live event | `/team-live-ops`: `live-ops-designer` + `economy-designer` + `analytics-engineer` + `ux-designer` |
| Release | `/team-release`: `release-manager` + `qa-lead` + `devops-engineer` + `producer`, plus `mobile-sdk-engineer` for consent and privacy declarations |

## Conflict resolution

1. **Same tier disagreement** → escalate to the shared parent.
2. **Design conflict with no shared parent** → `creative-director`.
3. **Technical conflict with no shared parent** → `technical-director`.
4. **Scope or timeline conflict** → `producer`. Scope decisions are the user's; the
   producer frames the trade-off rather than deciding it.
5. **Cross-department change** → `producer` coordinates the propagation.

Two conflicts have a predetermined answer, because they are compliance rather than
judgement:

- **Ads versus consent ordering** → consent wins, always. No escalation needed.
- **A feature flag versus a hardcoded switch** → the flag wins. Every feature must be
  switchable.

## Where escalation goes when the owner was archived

Thirteen agents were archived for this profile. If a task genuinely needs one of them, the
project's shape has changed — say so rather than improvising:

| Archived need | Escalate to | Note |
|---|---|---|
| Narrative, lore, dialogue | `creative-director` | If the game genuinely needs narrative, restore the narrative agents rather than stretching UX |
| Multiplayer or netcode | `technical-director` | Nothing in this profile anticipates it |
| Behaviour trees or pathfinding | `gameplay-programmer` | Puzzle AI, if any, is a rule not an agent system |
| DOTS or ECS | `unity-specialist` | Zero of four reference titles use it |
| Deep security work beyond SDK and save | `technical-director` | Then restore `security-engineer` |
| Community management | `live-ops-designer` | Needed post-launch, not before |

See the Archived table in `.claude/docs/agent-roster.md` for the full mapping.
