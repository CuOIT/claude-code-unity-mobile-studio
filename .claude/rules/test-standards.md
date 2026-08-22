---
paths:
  - "Assets/Tests/**"
---

# Test Standards

- Test naming: `test_[system]_[scenario]_[expected_result]` pattern
- Every test must have a clear arrange/act/assert structure
- Unit tests must not depend on external state (filesystem, network, database)
- Integration tests must clean up after themselves
- Performance tests must specify acceptable thresholds and fail if exceeded
- Test data must be defined in the test or in dedicated fixtures, never shared mutable state
- Mock external dependencies — tests should be fast and deterministic
- Every bug fix must have a regression test that would have caught the original bug

## EditMode vs PlayMode — both are required

| Test type | Mode | Required for |
|---|---|---|
| Rule / formula | EditMode | Every puzzle rule, every formula, every state transition. No scene load. |
| Undo | EditMode | Apply N moves, undo N times, assert state equals initial state exactly |
| Level validity | EditMode | Every level parses, no orphan references, win condition reachable |
| Feature flag resolution | EditMode | Unregistered id fails closed; missing remote key falls back to local default |
| Adapter contract | EditMode | Each adapter and its Null counterpart pass the **same** suite |
| Full loop | **PlayMode** | boot → home → gameplay → win → lose → retry, end to end |

**PlayMode coverage is not optional.** All four shipped titles in this studio have zero
PlayMode tests — one has 86 EditMode test files and still no end-to-end coverage, so
every regression in the boot or scene-transition path was found by a player. The CuOCore
suite does have PlayMode tests; match that standard rather than the shipped titles'.

If a rule cannot be tested in EditMode with no scene loaded, it is in the wrong layer —
see `.claude/rules/puzzle-code.md`.

## Examples

**Correct** (proper naming + Arrange/Act/Assert):

```csharp
[Test]
public void HealthSystem_TakeDamage_ReducesHealth()
{
    // Arrange
    var health = new HealthComponent { MaxHealth = 100, CurrentHealth = 100 };
    // Act
    health.TakeDamage(25);
    // Assert
    Assert.That(health.CurrentHealth, Is.EqualTo(75));
}
```

**Incorrect**:

```csharp
[Test]
public void Test1() // VIOLATION: no descriptive name
{
    var h = new HealthComponent();
    h.TakeDamage(25); // VIOLATION: no arrange step, no clear assert
    Assert.That(h.CurrentHealth, Is.LessThan(100)); // VIOLATION: imprecise assertion
}
```
