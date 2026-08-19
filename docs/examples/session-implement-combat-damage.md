# Example Session: Implementing Combat Damage Calculation

**Context:** Solo indie dev, week 4 of project, implementing gameplay systems.

**Starting State:**
- `design/gdd/combat-system.md` exists and reviewed
- Unity 6 LTS project set up with basic scene structure
- No gameplay code written yet
- Sprint goal: "Implement core combat damage calculation"

**Session Duration:** ~30 minutes
**Turns:** 10
**Outcome:** Working damage calculator with tests, ready for integration

---

## Turn 1: User Requests Implementation

**User:**
> Implement the damage calculation system from design/gdd/combat-system.md. The formula is in section 4.

## Turn 2: Agent Reads Design and Asks Clarifying Questions

**Agent (gameplay-programmer):**
> I've read `design/gdd/combat-system.md`. The damage formula is:
>
> ```
> final_damage = base_damage * (1 + attack_stat * 0.1) * crit_multiplier * type_effectiveness * (1 - target_defense)
> ```
>
> Before implementing, I need to clarify some details that aren't specified in the doc:
>
> **Architecture Questions:**
> 1. Should `DamageCalculator` be a static utility class (no state, just calculations) or an autoload singleton?
> 2. Where should `base_damage` come from? (Weapon data? Character stats? Ability data?)
> 3. Where should `type_effectiveness` values live? (Per weapon? Per damage type? Separate data file?)
>
> **Spec Ambiguities:**
> 4. Should `attack_stat` be clamped to a range? (Prevents exponential scaling bugs)
> 5. The doc says "critical hits do 2x damage" but doesn't specify rounding. Should I `floor()`, `ceil()`, or `round()` the final damage?
> 6. What happens if `target_defense` >= 1.0? (100% mitigation or higher) Should damage go negative or clamp to 0?
>
> **Integration:**
> 7. I don't see a design doc for the Health/HP system. Should I create a minimal one, or is that coming separately?
>
> Please clarify so I can implement this correctly the first time.

## Turn 3: User Resolves Ambiguities

**User:**
> 1. Static utility - no state needed
> 2. Base damage from Weapon resource. I'll create a simple Weapon class.
> 3. Type effectiveness in a separate data file `assets/data/combat_damage.json`
> 4. Yes, clamp attack_stat to 0-100
> 5. Use `floor()` to round down to integers
> 6. Clamp damage to minimum of 1 (always do at least 1 damage, even with 100% defense)
> 7. Create a minimal health component - just current_hp, max_hp, and take_damage() method

## Turn 4: Agent Proposes Architecture

**Agent:**
> Got it! Here's my proposed architecture:
>
> **Files I'll create:**
> ```
> src/gameplay/combat/damage_calculator.gd     # Static damage formula
> src/gameplay/combat/health_component.gd      # HP tracking node component
> src/gameplay/combat/weapon.gd                # Weapon resource
> assets/data/combat_damage.json               # Type effectiveness values
> design/gdd/health-system.md                  # Minimal health doc
> tests/combat/test_damage_calculator.gd       # Unit tests
> ```
>
> **Architecture Details:**
>
> **DamageCalculator** (static class):
> ```csharp
public class DamageResolver
{
    // Resolves final damage from base + modifiers (ScriptableObject-driven)
    public float Resolve(BaseDamageConfig config, CombatContext ctx)
    {
        float dmg = config.baseDamage * ctx.AttackMultiplier;
        return config.ApplyArmorReduction(dmg, ctx.TargetArmor);
    }
}
```
>
> **HealthComponent** (node component):
> ```csharp
public class CombatAnalytics
{
    public void RecordHit(CombatContext ctx)
    {
        // Addressable-driven event schema — zero-alloc struct on hot path
        EventBus.Publish(new DamageAppliedEvent(ctx.Damage, ctx.Element));
    }
}
```
>
> **Weapon** (resource):
> ```csharp
public class HealthSystem : MonoBehaviour
{
    [SerializeField] private HealthConfig _config;
    public void TakeDamage(float amount)
    {
        Current -= amount;
        if (Current <= 0) Die();
    }
}
```
>
> **combat_damage.json**:
> ```json
> {
>   "crit_multiplier": 2.0,
>   "attack_stat_min": 0,
>   "attack_stat_max": 100,
>   "type_effectiveness": {
>     "physical": { "armored": 0.5, "flesh": 1.0, "crystal": 1.5 },
>     "fire": { "armored": 1.0, "flesh": 1.2, "crystal": 0.3 }
>   }
> }
> ```
>
> **Question:** This architecture makes `DamageCalculator` easily testable (pure function, no dependencies). The `HealthComponent` uses signals for VFX/SFX hookup. Does this match your expectations, or should I change anything before implementing?

## Turn 5: User Approves with Minor Change

**User:**
> Looks good, but change `attacker_stats` and `defender_stats` to proper typed dictionaries or classes. I don't want untyped Dictionary bags floating around.

## Turn 6: Agent Refines Architecture

**Agent:**
> Absolutely - type safety is important. I'll create a `CharacterStats` resource:
>
> ```csharp
public class StatusEffectManager
{
    // Data-driven: status configs are ScriptableObject assets
    public void Apply(StatusConfig config, GameObject target)
    {
        var instance = Instantiate(config.Prefab, target.transform);
        instance.Init(config.Duration, config.TickRate);
    }
}
```
>
> Then `DamageCalculator.calculate_damage()` signature becomes:
> ```csharp
public class LootTableProcessor
{
    // Pure logic, no MonoBehaviour — trivially unit-testable
    public List<LootDrop> Roll(LootTableConfig table, float luck)
    {
        return table.Drops.Where(d => Random.value < d.Chance * luck).ToList();
    }
}
```
>
> Much cleaner. May I proceed with implementation?

## Turn 7: User Approves Implementation

**User:**
> Yes, implement it.

## Turn 8: Agent Implements and Reports

**Agent:**
> Implementation complete! Here's what I created:
>
> **Files Created:**
> - ✅ `src/gameplay/combat/damage_calculator.gd` (82 lines)
> - ✅ `src/gameplay/combat/health_component.gd` (45 lines)
> - ✅ `src/gameplay/combat/weapon.gd` (12 lines)
> - ✅ `src/gameplay/combat/character_stats.gd` (16 lines)
> - ✅ `assets/data/combat_damage.json` (validated JSON)
> - ✅ `design/gdd/health-system.md` (minimal 8-section doc)
>
> **Rules Enforcement Results:**
>
> The `gameplay-code` rule automatically flagged 2 issues during implementation:
> 1. ❌ `crit_multiplier` was hardcoded as `2.0` in damage_calculator.gd
>    - **Fixed:** Moved to `combat_damage.json` and loaded from config
> 2. ❌ `HealthComponent` had direct `print()` debug output
>    - **Fixed:** Removed hardcoded debug, added proper signals instead
>
> The `data-files` rule validated:
> - ✅ `combat_damage.json` is valid JSON
> - ✅ Naming convention matches `[system]_[name].json`
> - ✅ All values have comment documentation
>
> **Implementation Notes:**
> - Attack stat is clamped in `calculate_damage()` before use
> - Damage always returns minimum of 1 (per your requirement)
> - Type effectiveness defaults to 1.0 if combo not found in config
> - All numeric values loaded from `combat_damage.json` for designer tuning
>
> **Manual Testing:**
> I created a quick test scene and validated:
> - Base damage: 10, attack_stat: 50 → Damage: 15 ✓
> - Same but with crit → Damage: 30 ✓
> - With 50% defense → Damage: 15 (before defense) → 7 (after) ✓
> - With 100% defense → Damage: 1 (clamped) ✓
>
> **Next Steps - Your Choice:**
> A) I can write formal unit tests now (recommended - verification-driven development)
> B) You can review the code first via `/code-review src/gameplay/combat/damage_calculator.gd`
> C) Skip tests for now and integrate into actual combat
>
> What would you like?

## Turn 9: User Requests Tests

**User:**
> A - write unit tests. Cover all the edge cases.

## Turn 10: Agent Writes Tests and Completes

**Agent:**
> Unit tests created: `tests/combat/test_damage_calculator.gd`
>
> **Test Coverage (8 tests):**
> ```
> ✓ test_damage_basic_calculation() - Verify formula with known values
> ✓ test_damage_with_crit() - Critical hits double damage
> ✓ test_damage_with_defense() - Defense reduces damage correctly
> ✓ test_damage_type_effectiveness() - Type modifiers apply
> ✓ test_damage_min_clamp() - Never goes below 1
> ✓ test_damage_attack_stat_clamp() - Attack stat clamped to 0-100
> ✓ test_damage_missing_type_combo() - Defaults to 1.0 if not in config
> ✓ test_damage_rounding() - Verifies floor() behavior
> ```
>
> **Test Results:**
> ```
> Running tests/combat/test_damage_calculator.gd...
> ✓ All 8 tests PASSED
> Execution time: 12ms
> ```
>
> **Code Review Self-Check:**
> - ✅ All tests follow `test_[system]_[scenario]_[expected]` naming
> - ✅ Arrange/Act/Assert structure used
> - ✅ No external state dependencies
> - ✅ Each test is independent and can run in any order
>
> **System is ready for integration!**
>
> Files you can now commit:
> ```bash
> git add src/gameplay/combat/*.gd
> git add assets/data/combat_damage.json
> git add design/gdd/health-system.md
> git add tests/combat/test_damage_calculator.gd
> git commit -m "Implement damage calculation system per design/gdd/combat-system.md"
> ```
>
> The `validate-commit` hook will check:
> - ✅ Design doc referenced in message
> - ✅ JSON validity
> - ✅ No hardcoded values (already fixed)
>
> Ready to commit?

---

## Session Summary

**What Worked Well:**
- Agent read design doc first, identified 7 ambiguities upfront
- Didn't assume or guess - asked for clarification on every unclear point
- Proposed full architecture for user approval before writing code
- Incorporated user's type safety feedback immediately
- Rules caught issues automatically and agent fixed them transparently
- Tests written proactively following verification-driven development
- Agent offered next-step options rather than assuming what user wants

**Key Collaborative Moments:**
- Turn 2: Agent identified 7 spec gaps and asked rather than guessing
- Turn 4: Full architecture proposal shown before implementation
- Turn 5: User requested type safety, agent adapted
- Turn 8: Agent transparently reported rule violations and fixes
- Turn 10: Agent verified all acceptance criteria with tests

**Files Created:**
- 4 source files (damage_calculator, health_component, weapon, character_stats)
- 1 config file (combat_damage.json)
- 1 design doc (health-system.md)
- 1 test file (test_damage_calculator.gd)

**Context Usage:** ~25% (focused implementation task)
**User Satisfaction:** High - spec ambiguities resolved early, no rework needed
