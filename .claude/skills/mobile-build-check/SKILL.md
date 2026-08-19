---
name: mobile-build-check
description: "Validates the Unity project against the mobile (iOS/Android) build-readiness checklist before CI — no Unity editor required. Flags IL2CPP config, Addressables leaks, texture issues, unsafe-area UI, and Resources.Load misuse."
argument-hint: "[--platform android|ios|all] [--strict]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion
model: sonnet
---
# Mobile Build Readiness Check
Validates the project's mobile build readiness **without a running Unity
editor** — static scans of ProjectSettings, scripts, assets metadata, and
configs. Run this before handing a branch to the build CI (`game-ci`).

## When to Use
- Before opening a PR targeting the `main` branch.
- Before tagging a release candidate for store submission.
- When review mode is `full` and the story touches `src/` or `assets/`.

## How to Run
```
/mobile-build-check [--platform android|ios|all] [--strict]
```
`--platform` defaults to `all`. `--strict` fails on WARNINGS, not just errors.

## Checklist (Execute Every Item)

### 1. Scripting Backend & Player Settings
Scan `ProjectSettings/ProjectSettings.asset`:
- `m_ScriptingBackend` MUST be `1` (IL2CPP) for release. Mono (`0`) → ERROR on
  release branches (allowed in dev only).
- `AndroidMinSdkVersion` >= 23 (Android 6.0). Lower → ERROR (Play Store
  requirement drift).
- `iOSBundleVersion` / `bundleVersion` incremented vs last tag → ERROR if
  unchanged.
- Texture compression preset set (ASTC default for both platforms).

### 2. Asset Hygiene
- Grep `Assets/` metadata (`*.meta` + `*.png` + `*.jpg` + `*.tga`): any texture
  > 2048² → WARNING (> 4096² → ERROR).
- Any UI sprite with `mipmapEnabled: 1` → WARNING.
- Any texture with `textureCompression` not matching ASTC (Android) or ASTC
  (iOS override via platform settings) → WARNING.
- Any `Resources/` folder containing runtime content beyond first-scene
  bootstrap → ERROR (`Resources.Load` is forbidden after launch).

### 3. Code-Level Scans
- `Grep` `Resources.Load` in `src/` → ERROR (use Addressables).
- `Grep` `new ` inside methods named `Update|FixedUpdate|LateUpdate|OnUpdate` →
  WARNING (GC allocation in hot path).
- `Grep` `Instantiate|Destroy` in files under `src/gameplay/` → WARNING (must
  use object pooling; verify a Pool exists via AskUserQuestion if found).
- `Grep` `Addressables.InstantiateAsync|LoadAssetAsync` — for each call site,
  verify a matching `ReleaseInstance` or handle `Release()` within the same
  file → ERROR if leaked.
- `Grep` `Screen.safeArea` absence in all HUD/canvas root scripts → WARNING
  (notch/punch-hole safe area).
- `Grep` `\bList<.*>\(\)` or `new Dictionary<|new HashSet<` inside hot-path
  classes (marked `[System.Serializable]` + `MonoBehaviour` with Update) →
  WARNING.

### 4. Build Config
- `EditorBuildSettings.asset`: scenes list includes a loading/entry scene as
  index 0 → ERROR if missing.
- `QualitySettings.asset`: at least 2 quality tiers exist (mid-range + premium)
  → WARNING if single tier.
- `.gitignore` includes `Library/`, `Temp/`, `Logs/`, `Obj/`, `*.csproj`,
  `*.sln`, `*.app`, `*.apk`, `*.aab` → ERROR if missing.
- `UserSettings/` and `Library/` not tracked in git → ERROR if tracked.

### 5. Platform-Specific (per `--platform`)
**android**:
- `Assets/Plugins/Android/AndroidManifest.xml` has `INTERNET` only if truly
  needed; no `WRITE_EXTERNAL_STORAGE` without feature-need → WARNING.
- IL2CPP `Architecture` includes ARM64 (`arm64-v8a`); x86 check-disabled →
  ERROR if missing ARM64.

**ios**:
- Bundle identifier reverse-DNS format → ERROR if malformed.
- MinimumOSVersion >= 13.0 → WARNING if lower (App Store guideline drift).

## Output
Write findings to `production/mobile-build-report.md` with sections:
`ERRORS / WARNINGS / PASSED`. Verdict: `READY` (0 errors, warnings OK unless
`--strict`), `BLOCKED` (≥ 1 error). Print the verdict and top 5 findings to
the session; ask the user how to resolve errors — never auto-fix project
settings without approval ("May I update [filepath]?").

## Known Limitations
- Cannot run the real Unity build (no editor in this environment). This is a
  **pre-flight static scan** — the definitive check is still the CI build
  (`game-ci/unity-actions`).
- IL2CPP build time and binary size can only be estimated, not measured.
- Device-level performance (thermal throttling, low-end profiling) requires a
  physical device and is out of scope here.
