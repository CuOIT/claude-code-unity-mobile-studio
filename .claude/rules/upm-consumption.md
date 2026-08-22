---
paths:
  - "Packages/**"
---

# UPM Consumption Standards (`Packages/**`)

The CuOCore suite is consumed as UPM packages. How it is consumed determines whether
improvements flow between projects or rot in place.

## Never fork a package into the project

- **Do NOT copy a CuOCore package into `Assets/` or `Assets/Scripts/`.** Consume it via UPM.
- If a package needs a change, change it in the package and consume the new version.
  A local copy is a permanent fork the moment anyone edits it.
- Reference: the previous generation of this studio's shared code was copy-pasted into
  each title. Three shipped games now carry three divergent copies of the same SDK and
  kit layer. A fix in one reaches none of the others. That divergence is the single
  largest source of duplicated effort across those projects.
- If a package is genuinely wrong for this project, write an adapter around it — do not
  fork it.

## Local path references do not belong in shared branches

- A `file:` dependency resolves only on the machine that has that directory. On any other
  machine, and in CI, resolution fails.
- Local references are acceptable **only** while actively developing a package locally,
  on a branch that is never shared.
- Reference: the CuOCore consumer manifest currently resolves five packages from local
  paths, which contradicts that repository's own dependency policy and makes two of its
  integration tests unpassable.
- `validate-upm-manifest.sh` flags these on write.

## An excluded assembly must fail loudly

- When a package's assembly is gated by a version define or scripting define, a mismatch
  must be visible. Silently compiling the assembly out removes a capability with no signal.
- Reference: an adapter in the CuOCore template is excluded right now by its own guard.
  There is no error and no warning; the feature simply is not present.
- Where a capability is optional, ship a Null implementation and log which implementation
  is active at startup. Never let "missing" and "disabled" look identical.

## Adding a dependency

- Every new package needs a reason recorded — an ADR or an entry in the allowed-libraries
  list in `.claude/docs/technical-preferences.md`.
- Do not add a package speculatively. An installed-but-unused package still costs build
  time, app size, and a catalog to maintain. Addressables is installed and unused in
  three of the reference titles; in two of them it has zero call sites.
- Prefer a package the studio already ships with over a new third-party one.

## Secrets never enter a manifest

- No access tokens, keys, or credentials in `manifest.json`, lock files, or any tracked
  project settings file. Use the CI secret store.
- Reference: one shipped title has a live Git access token committed across three
  manifest files. Rotating it breaks builds; leaving it is a live credential leak.
- `scan-secrets.sh` blocks commits containing credential patterns.

## Version policy

**Deferred.** This project records capabilities, not pinned versions — see
`docs/engine-reference/unity/VERSION.md`. Read versions from the project on disk when
they matter, and ask the user when a version genuinely changes a decision. Revisit the
pinning strategy when the project is closer to a shippable build.
