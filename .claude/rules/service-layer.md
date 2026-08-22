---
paths:
  - "Assets/Scripts/Services/**"
  - "Assets/Scripts/Core/**"
---

# Service Layer Standards (`Assets/Scripts/Services/**`)

This project's services are **contracts from the CuOCore UPM suite plus adapters onto
real vendors**. Read `.claude/docs/cuocore-map.md` before writing anything here.

## Before writing a new interface — check whether it exists

CuOCore already defines contracts for ads, IAP, tracking, feature flags and live-ops,
trusted time, pooling, inventory, cloud save, audio, haptics, boosters, scene flow,
gameplay flow, home flow, and UI. **Writing a parallel interface is the most likely way
to waste effort on this project.**

Only create a new contract when the capability genuinely has none. When you do, put it
in `Assets/Scripts/Services/Abstractions/` and register it in `docs/registry/services.yaml`.

## The adapter boundary is a compile error, not a convention

- `Assets/Scripts/Services/Abstractions/` and `Assets/Scripts/Gameplay/**` MUST NOT reference any vendor SDK
  assembly. Enforce this through assembly-definition references, not review discipline.
- Vendor types — mediation SDK, analytics SDK, purchasing, attribution, telemetry —
  may appear **only** inside a designated adapter assembly.
- A vendor type crossing that boundary is an ERROR, caught by `/mobile-build-check`.
- Never leak a vendor enum, result type, or exception through a contract. Map it.

## Every adapter needs a Null counterpart

CuOCore ships Null and in-memory implementations so the game runs with no SDKs at all.
Preserve that property.

- For every real adapter, a Null or fake implementation must exist and be registered
  when SDKs are disabled.
- The composition root chooses which to register. **Do not scatter `#if` blocks through
  gameplay code** to achieve this — that is what the Null implementation is for.
- Both implementations must pass the same contract test suite.

## Composition root and bootstrap ordering

Service wiring happens in one place: `Assets/Scripts/Core/`. Registration is manual and ordered.

```
register adapters (real or Null, per build configuration)
  → lock the registry
  → bootstrap the service facade
  → load configuration
  → initialise tracking
  → load flag defaults, then fetch remote overrides
  → RESOLVE CONSENT
  → initialise ads          ← only after consent resolves
  → initialise purchasing
  → prewarm pools
  → enter the first scene
```

- Resolving a service before bootstrap throws. Do not work around it by caching a
  static reference at field-initialiser time.
- **Consent MUST resolve before ad initialisation.** This is a store-submission gate,
  not a preference. A shipped title in this studio has no consent path at all — do not
  repeat it.
- Order is explicit and readable in one file. Do not rely on `Awake` ordering, scene
  hierarchy order, or `RuntimeInitializeOnLoadMethod` side effects to sequence services.

## Cross-module communication: ScriptableObject event channels

- Cross-module events use `ScriptableEventChannel<T>` from CuOCore. Wire them by
  assigning the channel asset to a serialized field.
- Parent-child communication inside a single module uses `event Action` or `UnityAction`
  directly. Do not route a local notification through a global channel.
- **Do NOT add a message broker, a type-keyed event bus, or a static event hub.** One
  event mechanism per direction of coupling, chosen deliberately. Adding a second one
  means nobody can tell where an event comes from.
- Each new payload type is one channel class plus one asset. That cost is intentional —
  it keeps the dependency visible in the Inspector.

## Singletons

- Prefer the service registry. Budget: at most five singletons in the whole project,
  each justified in an ADR.
- A shipped title in this studio accumulated three singleton base classes and 38
  hand-rolled static instances. That is the failure mode this budget prevents.

## Testing

- Contract tests run against both the real adapter and its Null counterpart.
- An adapter that cannot be tested without a live SDK connection is too thick — move
  the untestable part into a thin seam and test around it.
- Never disable or skip a failing adapter test to make CI pass.
