---
name: feature-flag
description: "Manage the three-tier feature flag system: add a flag across all three places it must exist, list the current inventory, or audit for drift between code and registry. Catches flags read but never declared — the failure that silently disables a feature on device."
argument-hint: "[add|list|audit] [event-id]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion
model: sonnet
---

# Feature Flag Management

Every feature in this project must be switchable without a code change. This skill keeps
the three tiers consistent and catches the drift that makes flags fail silently.

Read `.claude/rules/feature-flags.md` before running any mode. It defines the three fail
behaviours you must design around, including kill-switch latency.

## The three tiers

| Tier | Mechanism | Changed by | Takes effect |
|---|---|---|---|
| Compile-time | Scripting define / version define | Rebuilding | Next build |
| Local default | `LiveOpsDefinition` asset in the catalog | Inspector edit | Next build |
| Remote override | Remote key read through the flag adapter | Console change | Next **successful** fetch |

A flag must exist in **three places** to work. All three, or it fails silently:

1. `docs/registry/feature-flags.yaml` — the reviewable, greppable record
2. A `LiveOpsDefinition` asset registered in the `LiveOpsCatalog`
3. A stable id constant the code reads (never a bare string literal at the call site)

## How to Run

```
/feature-flag add <event-id>      # create the flag in all three places
/feature-flag list                # current inventory, grouped by tier
/feature-flag audit               # find drift between code and registry
```

No arguments → run `audit`, then offer `add` if gaps are found.

---

## Mode: `add`

### 1. Validate the id

- Lowercase snake_case, no spaces, no leading digit.
- Grep `docs/registry/feature-flags.yaml` for the id. If it exists and is `active`, stop
  and report — do not create a duplicate. If it exists as `retired`, **refuse**: ids are
  never reused, because players may still have the old key mirrored locally.

### 2. Gather the flag's shape via `AskUserQuestion`

Ask only what you cannot infer:

- **Tier** — remote (changeable after release) / local SO only / compile-time define
- **Value type** — toggle (bool) or strategy (int mode, where 0 means off)
- **Default state** — recommend **off** for anything not yet proven, and say why:
  a registered flag with no remote value present falls back to its local default, so a
  default of `true` ships enabled
- **Kill-switch** — required (`true`) if this flag gates ads or IAP. Do not ask; state it.
- **Owner** — which agent owns this flag (`mobile-sdk-engineer`, `live-ops-designer`, …)

### 3. Write the registry entry

Append to the `flags:` list in `docs/registry/feature-flags.yaml`, following the example
block already in that file. Set `added:` to today's date. Ask before writing:
"May I add `<event-id>` to docs/registry/feature-flags.yaml?"

For a compile-time flag, append to `define_symbols:` instead, and record what happens
when the symbol is absent — that is the Null-implementation path.

### 4. Specify the catalog asset and the id constant

This skill does not run Unity, so it cannot create the `.asset`. Produce an exact,
actionable spec instead:

- Asset path and the field values to set on the `LiveOpsDefinition`
- The id constant to add, and which file it belongs in
- The one-line read site pattern, using the flag service — never remote config directly

Record the intended asset path in the registry entry's `definition_asset` field so
`audit` can later verify it exists.

### 5. Remind about the ADR

If this is the project's first remote flag, or if `kill_switch: true`, state plainly that
the kill-switch latency must be recorded in an ADR: the switch takes effect on the next
successful fetch, not immediately. Offer to run `/architecture-decision`.

---

## Mode: `list`

Read `docs/registry/feature-flags.yaml` and print a compact table grouped by tier:

```
REMOTE (n)
  event_id                default   kill?   owner              readers
LOCAL SO (n)
COMPILE-TIME (n)
RETIRED (n)
```

Flag anything anomalous inline:
- `default_enabled: true` on a flag that is not yet proven
- an ads or IAP flag with `kill_switch: false` → **ERROR**
- an entry with an empty `read_by` list → the flag exists but nothing reads it
- an entry with an empty `definition_asset` → tier 2 was never created

---

## Mode: `audit`

Six checks. Report each as PASS, WARNING, or ERROR, then a verdict.

### 1. Read but not declared — ERROR

Grep `Assets/Scripts/` for flag reads (`IsEnabled(`, `GetMode(`) and extract each id. Any id absent
from the registry is an ERROR.

This is the check that matters most. A shipped title in this studio reads a flag key that
is absent from its registry: it returns `false` on Android with no error and no log, so
the feature is simply off and nobody knows why.

### 2. Declared but not read — WARNING

Registry entries with no matching read site in `Assets/Scripts/`. Either the feature was never wired
or it was removed without retiring the flag. Propose retirement.

### 3. Missing catalog asset — ERROR

Any `active` entry whose `definition_asset` is empty, or whose named path does not exist
on disk. Tier 2 is missing, so the flag has no local default.

### 4. Silent catalog deletion — ERROR

`LiveOpsCatalog.OnValidate()` **silently drops** definitions that are null, have a blank
id, or duplicate an existing id — no log, no report. Cross-check every registry entry
against the catalog asset's serialized list. Any registry entry with no corresponding
catalog element has been silently deleted.

Report these individually. This is a data-loss bug, not a style issue.

### 5. Missing kill-switch — ERROR

Any flag whose capability mentions ads or IAP and has `kill_switch: false`.

### 6. Bare string literals at read sites — WARNING

A read site passing a string literal rather than an id constant. String literals are how
typos become silent `false` returns.

### Verdict

- **CLEAN** — no errors
- **DRIFT** — warnings only; safe to ship, worth fixing
- **BROKEN** — one or more errors; at least one flag does not work as intended

Write the report to `production/flag-audit-[date].md` only if the user asks. Print the
verdict and every ERROR to the session regardless.

---

## Constraints

- Never create a flag that bypasses the catalog. If code needs a switch the catalog
  cannot express, that is an architecture question — escalate, do not work around it.
- Never mark a flag retired while readers remain. Retiring means deleting the readers in
  the same change.
- Never rename an `event_id`. Create a new one and retire the old.
- Do not read remote config directly from gameplay code. The flag service is the only API.
- Boot-critical behaviour is a compile-time decision, never a remote one — an app that
  cannot start also cannot fetch the flag that would fix it.
