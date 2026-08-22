---
paths:
  - "Assets/Scripts/**"
  - "docs/registry/feature-flags.yaml"
---

# Feature Flag Standards

Every feature must be switchable without a code change. Three tiers, in order of
increasing reach and decreasing speed:

| Tier | Mechanism | Use it for |
|---|---|---|
| 1. Compile-time | Scripting define / assembly version define | Stripping an SDK out of the build entirely |
| 2. Local default | `LiveOpsDefinition` asset in the catalog | The default state; changing it in the Inspector needs no code change |
| 3. Remote override | Remote config, read through the flag adapter | Kill-switches and rollouts after the build is live |

The only API gameplay code uses is the flag service: `IsEnabled(eventId)` and
`GetMode(eventId)`. Never read remote config directly from gameplay.

## The catalog is the single source of truth

- Every flag read in code MUST have a `LiveOpsDefinition` in the catalog. No exceptions.
- Register the flag in `docs/registry/feature-flags.yaml` at the same time.
- Use `/feature-flag add <event-id>` so all three places stay in sync; `/feature-flag audit`
  finds drift.
- A shipped title in this studio reads a flag key that is absent from its registry.
  It silently returns `false` on Android, disabling the feature with no error and no log.
  That is the exact failure this rule prevents.

## Do not rely on `OnValidate` to keep the catalog clean

`LiveOpsCatalog.OnValidate()` **silently deletes** definitions that are null, have a
blank id, or duplicate an existing id. No log, no report, no list of what was removed.
A flag can disappear without a trace.

- Treat catalog integrity as something to *verify*, never something that self-heals.
- The project needs an explicit validator plus a build-time gate, following the
  `UIRegistryValidator` + `IPreprocessBuildWithReport` pattern that already exists in
  `com.cuobs.ui`.

## Three fail behaviours you must design around

1. **Unregistered id → fails CLOSED.** `IsEnabled` returns `false`, `GetMode` returns `0`.
   This is correct. Preserve it. A shipped title in this studio returns `true` for
   unrecognised ids, which lets an unfinished feature switch itself on — never do that.

2. **Registered flag, missing remote key → fails OPEN to the local default.** The null
   remote-config implementation returns the supplied fallback, so a flag with
   `EnabledByDefault = true` is ON with no remote config present. Choose local defaults
   with that in mind: **default to off for anything not yet proven.**

3. **Remote values are mirrored into PlayerPrefs, so they survive offline and rollback.**
   Once a flag has been fetched as ON, it stays ON until the next *successful* fetch —
   across app restarts, with no network, and after a server-side rollback.
   Consequences that must be designed for:
   - A kill-switch is not instant. It takes effect on the next successful fetch.
   - Never treat a kill-switch as a safety mechanism for something that must stop
     immediately. It is a rollout control.
   - Expose and use an explicit refresh; do not assume values are current.
   - Document the expected latency in the ADR for any ads or IAP kill-switch.

## Naming and lifecycle

- Ids are lowercase snake_case, stable forever. Renaming an id orphans every player who
  already has the old key mirrored locally.
- Retiring a flag: mark it retired in the registry and remove the code that reads it in
  the same change. A retired flag with live readers is worse than no flag.
- Ads and IAP MUST each have a kill-switch flag. Non-negotiable for a monetised build.

## What does not belong behind a remote flag

- Anything that would leave saved data in an unreadable state when switched off.
- Anything required for the app to start. Boot-critical behaviour is a compile-time
  decision, not a remote one.
