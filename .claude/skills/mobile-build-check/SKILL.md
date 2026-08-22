---
name: mobile-build-check
description: "Static pre-flight scan before handing a branch to CI — no Unity editor required. Checks the adapter boundary, consent-before-ads ordering, feature-flag declarations, assembly structure, secrets, UPM manifest health, and mobile asset budgets."
argument-hint: "[--platform android|ios|all] [--strict]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, AskUserQuestion
model: sonnet
---

# Mobile Build Readiness Check

Validates build readiness **without a running Unity editor** — static scans of project
settings, scripts, asset metadata, registries, and manifests. Run before opening a PR or
tagging a release candidate.

Every check below exists because the failure it catches was observed in real code on this
machine. Where that is the case, it is noted.

## How to Run
```
/mobile-build-check [--platform android|ios|all] [--strict]
```
`--platform` defaults to `all`. `--strict` fails on WARNINGS as well as ERRORS.

---

## 1. Architecture Boundary

The boundary that makes SDK swapping cheap. If it leaks, it stops being a boundary.

- **Vendor type outside an adapter assembly → ERROR.** Grep `Assets/Scripts/` for vendor namespaces
  and types (mediation SDK, analytics, purchasing, attribution, telemetry). Any hit
  outside `Assets/Scripts/Services/Adapters.*` is a violation. Report file and line.
- **`abstractions` or `gameplay` referencing a vendor assembly → ERROR.** Read the
  `.asmdef` files and check their `references` arrays directly — this is the mechanism
  that makes the boundary a compile error rather than a convention.
- **No first-party `.asmdef` under `Assets/Scripts/` → ERROR.** One assembly per module. Two
  reference titles have zero and consequently cannot enforce any boundary at all; the
  largest compiles 1199 scripts into one assembly.
- **A CuOCore package copied into `Assets/` or `Assets/Scripts/` → ERROR.** Look for package
  directory names or `package.json` under those trees. The previous generation of this
  studio's shared code was copy-pasted per title and has since diverged three ways.

## 2. Consent & Ads Ordering

A store gate, not a preference. Nothing upstream enforces it.

- Read `docs/registry/services.yaml`. **If any ads adapter is `exists` while the consent
  adapter is not → ERROR.**
- **If the consent entry's `bootstrap_order` is not lower than every ads entry's → ERROR.**
- Grep the composition root for the registration sequence and confirm it matches the
  registry order. A registry that says the right thing while the code does another is
  worse than neither.
- **iOS**: tracking-usage description present in project settings, and an `iPhone`
  scripting-define entry exists → ERROR if either is missing. One reference title ships
  with no ATT prompt, no usage description, and no iOS define entry at all.

## 3. Feature Flags

- **Flag read in `Assets/Scripts/` with no registry entry → ERROR.** Extract ids from flag reads and
  cross-check `docs/registry/feature-flags.yaml`. An undeclared flag resolves to `false`
  on device with no error — a reference title ships this bug today.
- **Registry entry whose `definition_asset` is missing or absent on disk → ERROR.** Tier 2
  does not exist, so the flag has no local default.
- **Registry entry with no matching element in the catalog asset → ERROR.**
  `LiveOpsCatalog.OnValidate()` silently deletes null, blank-id, and duplicate-id
  definitions with no log. This check is the only way to notice.
- **Ads or IAP flag with `kill_switch: false` → ERROR.** A monetised build that cannot be
  switched off after release.
- **Bare string literal at a flag read site → WARNING.** Use an id constant; literals are
  how typos become silent `false`.

Delegate to `/feature-flag audit` for the full report; summarise its verdict here.

## 4. Code Health

- **File over 1000 lines under `Assets/Scripts/` → ERROR**; over 600 → WARNING. Observed shipped
  files: 4693, 2805, 1856, 1496 lines.
- **`.cs` file with no `namespace` declaration → WARNING.** Four CuOCore packages already
  put types in the global namespace; do not add to that surface.
- **Folder under `Assets/Scripts/` named after a person → WARNING.** Compare against contributor
  names from `git log --format=%an | sort -u`. One reference title has five.
- **Singleton count over five → WARNING.** Count `static.*Instance` properties and
  singleton base-class derivations. One reference title has three base classes plus 38
  hand-rolled instances.
- **Commented-out code block over 20 lines → WARNING.** Observed: a 522-line fully
  commented-out purchase manager beside the live one.

## 5. Silent Exclusions

Missing and disabled must not look identical.

- **`#if` guard around a whole file or class whose symbol is not defined anywhere → ERROR.**
  Cross-check guard symbols against project settings and `versionDefines` in `.asmdef`
  files. A CuOCore template adapter is excluded right now with no error and no warning —
  the capability simply is not there.
- **Scripting define symbol not matching the canonical spelling in
  `docs/registry/services.yaml` → WARNING.** The same misspelled define appears in three
  reference titles.
- **Define symbol referenced in code but defined nowhere → WARNING.** Dead branch.

## 6. UPM Manifest

- `Packages/manifest.json` is valid JSON → ERROR if not.
- **`file:` dependency → ERROR** on a shared branch. Resolves on one machine only.
- **Credential in a dependency URL → ERROR.**
- **Duplicate package key → ERROR.** The last occurrence silently wins.
- **Addressables declared with zero call sites in `Assets/Scripts/` → WARNING.** Two reference
  titles carry it unused.
- **No `testables` array → WARNING.** Package tests will not run.

## 7. Secrets

- Grep tracked files for credential patterns: personal access tokens, cloud API keys,
  private key blocks, URLs with embedded credentials, keystore passwords. **Any hit → ERROR.**
- Check `.gitignore` covers `Library/`, `Temp/`, `Logs/`, `Obj/`, `*.csproj`, `*.sln`,
  `*.apk`, `*.aab`, `*.app`, and keystore files → ERROR if missing.
- **`Library/` or `UserSettings/` tracked in git → ERROR.**

## 8. Tests

- **Runtime assembly with no corresponding test assembly → WARNING.** Name the assemblies.
  In CuOCore, the UI package has 2231 lines and zero tests — the riskiest place in the suite.
- **No PlayMode test covering the full loop → WARNING** (ERROR with `--strict`). All four
  reference titles have zero PlayMode tests; one has 86 EditMode files and still no
  end-to-end coverage.

## 9. Player Settings & Assets

- Scripting backend is IL2CPP for release → ERROR if Mono on a release branch.
- ARM64 included in target architectures → ERROR if missing.
- Bundle version incremented since the last tag → ERROR if unchanged.
- Texture over 2048² → WARNING; over 4096² → ERROR.
- UI sprite with mipmaps enabled → WARNING.
- Texture compression not ASTC for the target platform → WARNING.
- `Resources/` tree size — report total. WARNING if it grew more than 20% since the last
  tag, since everything under it is in the build and scanned at startup.
- Entry scene present at build index 0 → ERROR if missing.
- At least two quality tiers defined → WARNING if a single tier.

## 10. Platform Specific (per `--platform`)

**android**: no `WRITE_EXTERNAL_STORAGE` without a stated feature need → WARNING.
`INTERNET` present only if actually used → WARNING.

**ios**: bundle identifier in reverse-DNS form → ERROR if malformed. Tracking-usage
description present when any tracking or ads adapter exists → ERROR if missing.

---

## Output

Write findings to `production/mobile-build-report.md` with sections `ERRORS`, `WARNINGS`,
`PASSED`. Print the verdict and the top five findings to the session.

| Verdict | Condition |
|---|---|
| **READY** | Zero errors (warnings allowed unless `--strict`) |
| **BLOCKED** | One or more errors |

Never auto-fix project settings, manifests, or registries. Report, then ask:
"May I update [filepath]?"

## Known Limitations

- This cannot run the real Unity build. It is a **static pre-flight** — the definitive
  check is the CI build.
- IL2CPP build time and binary size can only be estimated.
- Device performance, thermal throttling, and low-end profiling need real hardware and
  are out of scope. So is anything that requires the editor to resolve assets.
- Consent *behaviour* cannot be verified statically — only that the ordering and the
  declarations are in place.
