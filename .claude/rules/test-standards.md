---
paths:
  - "tests/**"
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
