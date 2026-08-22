---
name: sdk-integrate
description: "Wire a service capability by writing an adapter from an existing CuOCore contract onto a real vendor SDK. Checks the registry first so no parallel interface gets written, enforces the consent-before-ads ordering, and requires a Null counterpart for every adapter."
argument-hint: "[ads|iap|tracking|liveops|consent|all] [--dry-run]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Task
model: sonnet
---

# SDK Integration

**The contracts already exist. The work is adapters.**

The CuOCore suite defines and tests every service contract this game needs, and ships a
Null or in-memory implementation of each so the game runs with no SDKs at all. What it
contains is zero vendor code. This skill writes the layer between the two.

Before anything else, read:
- `.claude/docs/cuocore-map.md` — what exists upstream
- `docs/registry/services.yaml` — adapter status per contract
- `.claude/rules/service-layer.md` — the boundary rules

## How to Run

```
/sdk-integrate ads          # one capability
/sdk-integrate consent      # the highest-priority gap
/sdk-integrate all          # every missing P0 adapter, in bootstrap order
/sdk-integrate ads --dry-run # plan only, write nothing
```

No arguments → read the registry, report what is missing in priority order, and ask which
to do first.

---

## Phase 1: Check the registry before writing anything

Read `docs/registry/services.yaml`. For the requested capability:

- `adapter_status: exists` → **stop**. Report that it is done and where its tests are.
  Do not rewrite it.
- `adapter_status: partial` → report what is incomplete and proceed only on that part.
- `adapter_status: missing` or `planned` → proceed.
- Capability not in the registry at all → **stop and escalate.** Either it is satisfied
  upstream (check the `satisfied_upstream:` list) or the registry is out of date. Do not
  invent a new contract to fill a gap you have not confirmed is real.

**Never write a new interface for a capability that already has a contract.** Writing a
parallel interface is the single most likely way to waste effort on this project. If the
contract genuinely does not exist upstream — currently only consent — say so explicitly
and register the new contract in the registry as part of this run.

## Phase 2: Read the two sides

**The contract side.** Read the actual interface from the resolved package under
`Library/PackageCache/`. Note exactly: method signatures, the result and status types you
must map onto, the event or callback surface, and the Null implementation's behaviour —
your adapter must be substitutable for it.

**The vendor side.** Read the in-house wrapper named in the registry's `adapter_target`.
Note its initialisation requirements, its callback shape, and its threading assumptions.

Do not guess either side's API. If you cannot read it, say so and stop.

## Phase 3: Plan the mapping, then get approval

Present a mapping table before writing code:

| Contract member | Vendor call | Notes |
|---|---|---|

Call out explicitly:
- **Every vendor type that must be mapped.** A vendor enum, result type, or exception
  crossing the contract boundary is a rule violation. Map it, do not pass it through.
- **Every place the vendor API is async or callback-based but the contract is not**, or
  vice versa. This is where adapters usually go wrong.
- **What the adapter does when the SDK is absent or uninitialised.** It must not throw
  into gameplay.

Ask: "Does this mapping match your expectations? Any changes before I write it?"

## Phase 4: Consent ordering — check before ads, always

If the capability is `ads` (or `all`), verify first that a consent adapter exists.

**If consent is missing, stop and do consent first.** Ads must not initialise before
consent resolves. This is a store-submission gate, not a preference:

- A shipped title in this studio has no consent path at all — no tracking-transparency
  prompt, no usage description, no iOS define set. That is a rejection risk.
- The upstream ad contract takes no consent parameter, so nothing enforces this for you.
  The composition root is the only place it can be enforced.

Confirm the registry's `bootstrap_order` sorts consent before ads, and that
`gates_ads: true` is set on the consent entry.

## Phase 5: Write the adapter

Three files per capability, in this order:

1. **The adapter** in `Assets/Scripts/Services/Adapters.Bravestars/` (or `adapters.kit/`). This
   assembly is the **only** place vendor types may appear.
2. **The Null counterpart** in `Assets/Scripts/Services/Adapters.Null/`, if upstream does not
   already ship one. Check first — most contracts do.
3. **Registration** in the composition root at `Assets/Scripts/Core/`, at the `bootstrap_order`
   position from the registry.

Assembly rules, enforced by assembly-definition references rather than review:
- The adapter assembly references the contract package and the vendor assembly.
- `abstractions` and `gameplay` reference **neither** vendor assembly.
- The Null assembly references the contract only.

Ask before each write: "May I write this to [filepath]?"

Do not scatter `#if` blocks through gameplay to handle SDK absence. That is what the Null
implementation is for — the composition root picks which to register.

## Phase 6: Tests

- The adapter and its Null counterpart run against the **same** contract test suite.
  Substitutability is the property being tested.
- An adapter that cannot be tested without a live SDK connection is too thick. Move the
  untestable part into a thin seam.
- Add the test assembly name to the registry entry.

## Phase 7: Update the registry and produce the bootstrap checklist

Update the entry: `adapter_status`, `adapter_target`, `null_impl`, `test_assembly`,
`define_symbol` (canonical spelling — shipped titles carry a misspelled define across
three projects), and `revised:`.

Then print the current full bootstrap order from the registry, sorted, so the composition
root can be read against it:

```
20 trusted time      → …
30 tracking          → …
40 flag defaults + remote fetch
50 CONSENT           ← gates ads
60 ads
70 purchasing
```

Flag any entry whose order would put ads before consent as an ERROR.

## Phase 8: ADR

An adapter fixes a boundary, so it needs a record. Offer `/architecture-decision` for:
- the adapter boundary itself, if this is the first adapter
- any consent-flow decision (what happens when consent is declined)
- any kill-switch latency implication, for flag-backed capabilities

---

## Constraints

- **Never write a contract that already exists.** Check the registry first, every run.
- **Never let a vendor type cross the adapter boundary.** Not in a parameter, a return
  value, an event payload, or an exception.
- **Never initialise ads before consent resolves.**
- **Never skip the Null counterpart.** The game must run with no SDKs — that property is
  what makes `demo` mode and the entire test suite possible.
- Do not add a vendor SDK package speculatively. An installed-but-unused SDK still costs
  build time, app size, and a privacy declaration.
- Do not record vendor versions in the registry. This project records capabilities; read
  versions from the project when they matter.
