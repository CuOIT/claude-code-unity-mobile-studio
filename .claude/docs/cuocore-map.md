# CuOCore Capability Map

**Read this before proposing any service, manager, or infrastructure code.**
Most of what a mobile puzzle game needs already exists here as a tested contract.
Writing a parallel implementation is the single most likely way to waste effort on
this project.

- Repo: internal GitLab monorepo, **branch per package**, consumed via UPM.
- Local checkout paths are **machine-specific** and live in
  `.claude/docs/local-paths.md` (gitignored — copy `local-paths.template.md`).
  Expect an integration consumer plus, on some machines, per-branch checkouts.
- Resolved package sources sit under `<consumer>/Library/PackageCache/com.cuongbs.*`.
  If `local-paths.md` is absent, the suite is not checked out here: work from this
  document and say so, rather than guessing a path.
- **No versions in this document by design.** Read them from `Packages/manifest.json`
  when they matter. See `docs/engine-reference/unity/VERSION.md`.

---

## The one thing to understand first

> **CuOCore is contracts + Null/in-memory implementations. It contains no vendor SDK code.**

Every service interface exists, is tested, and ships with a Null or fake implementation
so the game runs with no SDKs at all. What does **not** exist is a single adapter to a
real vendor. That adapter layer is this project's work — see
`docs/registry/services.yaml` for status per contract.

Consequence for planning: **interfaces are done, adapters are not.**

---

## Package inventory

### Foundation

| Package | What it provides | Key contracts / types | Adapter needed? | Tests |
|---|---|---|---|---|
| `com.cuongbs.utilities` | **Service locator** (manual registration, lock-then-bootstrap) and **ScriptableObject event channels**. No DI container, no reflection, no auto-wiring. | `IServiceRegistry`, `IServiceResolver`, `ServiceRegistry`, static `Services` facade, `ServiceOwnership`; `IEventChannel<T>`, `ScriptableEventChannel<T>`, `IEventListener<T>`, `IEventSubscription`, `EventDispatchMode`, prebuilt `Bool`/`Int`/`String`/`Void` channels | No | EditMode ✅ |
| `com.cuongbs.pooling` | Object pooling with preload, max-size cap, async preload, `IPoolable` lifecycle hooks. Throws `PoolExhaustedException` on `Get()`, returns false on `TryGet`. | `IPoolService`, `IPrefabPool<T>`, `IPoolable`, `IPooledObjectFactory<T>`, `PoolOptions` | No | EditMode ✅ |

**Service registration is manual and ordered.** Pattern:
`ServiceRegistry.RegisterSingleton<T>(instance)` → … → `.Lock()` → `Services.Bootstrap(registry)`.
Resolving before bootstrap throws. There is no `Unregister` and no scoped lifetime.

**Event channels are payload-typed and wired by dragging assets into serialized fields.**
There is no `Publish<T>()`, no type-keyed bus, no queued dispatch. Each new payload type
means one channel class plus one asset. This is the project's chosen pattern — do not
add a message broker (see `.claude/rules/service-layer.md`).

### Monetisation & telemetry — all contract-only

| Package | What it provides | Key contracts | Adapter needed? | Tests |
|---|---|---|---|---|
| `com.cuongbs.ads` | Ad orchestration: format-agnostic show/load, cooldown + enabled policies, per-format provider routing, event sink fan-out, revenue metadata. **Vendor-agnostic — zero AppLovin/AdMob code.** | `IAdsService`, `IAdsProvider`, `IAdsShowPolicy`, `IAdsEventSink`, `IAdsConfigurationProvider`, `IAdsClock`; `AdsFormat {Rewarded, Interstitial, AppOpen, Banner, Mrec}`, `AdsShowRequest`, `AdsShowResult`, `AdsMetadata`; `NullAdsProvider`, `RoutingAdsProvider`, `AdsCallbackAdapter` | **YES** → `MediationManager` + `AppOpenAdManager` | EditMode ✅ |
| `com.cuongbs.iap` | Purchase flow: catalog, product content + rewards, receipt validation seam, grant processing, transaction idempotency, restore. **No Unity Purchasing reference.** | `IIapService`, `IIapStore`, `IIapReceiptValidator`, `IIapPurchaseProcessor`, `IIapTransactionStore`, `IIapContentProvider`; `IapCatalog`, `IapProductDefinition`, `IapRewardDefinition`, `TrustStoreReceiptValidator`, `PlayerPrefsIapTransactionStore` | **YES** → `PurchaseManager` | EditMode ✅ |
| `com.cuongbs.tracking` | Event tracking with provider multiplexing, optional catalog validation (warn/reject), queueing until provider ready, user-property caching. Domain helpers for ads, IAP, resources, boosters, features. **No Firebase/AppsFlyer/GameAnalytics code.** | `ITrackingService`, `ITrackingProvider`, `ITrackingCatalog`; `TrackingParameters`, `TrackingCatalog`, `CompositeTrackingProvider`, `NullTrackingProvider`, `DebugTrackingProvider`, `AdTrackingService`, `IapTrackingService`, `ResourceTrackingService`, `BoosterTrackingService`, `FeatureTrackingService` | **YES** → `FirebaseManager`, `SDKManager.PushAFEvent`, GameAnalytics. Register them into `CompositeTrackingProvider`. | EditMode ✅ |
| `com.cuongbs.liveops` | **This is the feature-flag system.** Per-flag SO definition, remote toggle/strategy resolution, cycle scheduling (weekly/monthly/seasonal/continuous), join tracking, payload persistence, deadline expiry. | `ILiveOpsManager`, `ILiveOpsRemoteConfig`, `ILiveOpsModule`, `ILiveOpsClock`, `ILiveOpsStorage`, `ILiveOpsSerializer`; `LiveOpsCatalog`, `LiveOpsDefinition`, `LiveOpsSnapshot`, `LiveOpsSchedule` subclasses, `NullLiveOpsRemoteConfig`, `InMemoryLiveOpsRemoteConfig`, `PlayerPrefsLiveOpsStorage` | **YES** → `BS_Data` (decided) | EditMode ✅ |
| `com.cuongbs.trustedtime` | Server-time sync to defeat device-clock tampering. Ships **no response parser** — the game injects one. | `ITrustedTimeService`, `ITrustedTimeSource`, `ITrustedTimeResponseParser`, `ITrustedTimeRuntime`, `HttpTrustedTimeSource` | **YES** → parser impl | EditMode ✅ |
| `com.cuongbs.trustedtime.liveops` | One class: feeds trusted time into LiveOps scheduling. | `TrustedTimeLiveOpsClock : ILiveOpsClock` | No | EditMode ✅ |

### State & persistence

| Package | What it provides | Key contracts | Adapter needed? | Tests |
|---|---|---|---|---|
| `com.cuongbs.resources` | ⚠️ **Not asset loading.** Currency/inventory quantities and cosmetic skin unlock state, enum-keyed, PlayerPrefs-backed. Types are in the **global namespace**. | `IInventoryService`, `IResourceQuantityService`, `IResourceSkinService`, `IResourceStorage`, `IResourceKeyBuilder`; `InventoryService`, `ResourceKeyRegistry`, `ConsumeItem<T>`, `SkinItem<T>`, `PlayerPrefsResourceStorage`, static `Inventory` facade | No | EditMode ✅ |
| `com.cuongbs.syncdata` | Cloud save: local snapshot build, conflict resolution, key registry, boot-apply gate, background sync. Firestore provider is define-gated. | `ICloudStorageProvider`, `IConflictResolver`, `ISyncableData`, `ISyncDataSource`, `ISyncDataApplyHandler`; `CloudSyncService`, `SyncKeyRegistry`, `LocalFileBackupProvider`, `FirestoreProvider` | Optional | EditMode ✅ |
| `com.cuongbs.resources.syncdata` | One class bridging inventory keys into the sync key registry. | `ResourceSyncKeyAdapter` | No | EditMode ✅ |

### Flow orchestration

| Package | What it provides | Key contracts | Adapter needed? | Tests |
|---|---|---|---|---|
| `com.cuongbs.sceneflow` | Async scene transition service + linear boot pipeline (steps then conditions, first failing condition short-circuits). Stateless — not a state machine. | `ISceneFlowService`, `ISceneLoader`, `ISceneTransitionPresenter`, `IBootStep`, `IBootCondition`, `BootPipeline`, `SceneManagerSceneLoader` | No | EditMode ✅ |
| `com.cuongbs.sceneflow.ui` | Loading-overlay lease coordinator + transition presenter bound to the CuOBS UI manager. | `ISceneLoadingPanel`, `ILoadingOverlayLease`, `ILoadingOverlayCoordinator`, `UIManagerSceneTransitionPresenter<T>` | No | EditMode ✅ + sample PlayMode |
| `com.cuongbs.gameplayflow` | **In-level state machine**: `Idle → Loading → Playing → Paused → ResolvingLose → ShowingResult → Exiting`, with pluggable lose/exit/post-win policies and SO event channels for won/lost/exit. | `IGameplayFlowService`, `IGameplaySession`, `IGameplayLoader`, `IGameplayLevelProvider`, `IGameplayFlowPresenter`, `IGameplayPausePresenter`, `IGameplayHomeNavigator`, `IGameplayExitPolicy`, `ILoseFlowPolicy`, `IPostWinDestinationResolver` | **YES** → `IGameplayLoader`, `IGameplaySession`, persistent `IGameplayLevelProvider` (the actual game) | EditMode ✅ |
| `com.cuongbs.gameplayflow.ui` | One presenter bridging gameplay flow to CuOBS UI panels (loading/win/lose/quit). | `UIManagerGameplayFlowPresenter<…>` | No | ⚠️ sample PlayMode only |
| `com.cuongbs.homeflow` | **Home-screen popup sequencing**: ordered SO step pipeline with priority categories, per-feature grouping, and show quotas. Types in the **global namespace**. | `IHomeFlowService`, `IHomeFlowQuotaPolicy`, `HomeFlowStepSO`, `HomeFlowProfile`, `HomeFlowQuotaConfigSO`, `HomeFlowCategory`, `HomeFlowTrigger`, `DefaultHomeFlowQuotaPolicy`, `HomeFlowManager` | **YES** → one `HomeFlowStepSO` subclass per popup | EditMode ✅ |

### Presentation & feel

| Package | What it provides | Key contracts | Adapter needed? | Tests |
|---|---|---|---|---|
| `com.cuobs.ui` | UGUI screen/popup manager. **Type-keyed lookup, not a stack** — no push/pop, no back-stack. Per-type instance pooling, `UIRegistry` asset drives load policy and source, z-order by `GetUIIndex()`. Types in the **global namespace**. | `IUIElement`, `IUIElement<D>`, `IAsync`, `IUILoader`, `IUIInputBlocker`; `UIManager`, `UIRegistry`, `UIRegistryEntry`, `UILoadPolicy`, `UILoadSource {Auto, Resources, Addressables}`, `ResourcesUILoader`, `AddressablesUILoader` (define-gated), `UIElement`/`PopUp` base classes | No | ⚠️ **ZERO tests** — 2231 lines untested |
| `com.cuongbs.audio` | Music + SFX service: catalog cues, buses, voice pooling, concurrency/steal policy, ducking tokens, volume persistence, mixer binding. | `IAudioService`, `IAudioCueProvider`, `IAudioMixerOutput`, `IAudioPlaybackHandle`, `IAudioDuckToken`, `IAudioSettingsStore`; `AudioCatalog`, `AudioBootstrap`, static `GameAudio` | No | EditMode ✅ |
| `com.cuongbs.haptics` | Haptic presets + custom amplitude/frequency, capability probing, enable persistence. Nice Vibrations binding exists **only as a sample**. | `IHapticService`, `IHapticProvider`, `IHapticSettingsStore`; `HapticType`, `HapticCapabilities`, `NullHapticProvider`, static `Haptics` | Optional | EditMode ✅ |
| `com.cuongbs.boosters` | Booster use pipeline: catalog, access policy (available/locked/hidden), resource consumption port, per-booster executors, cancellation, event channel. | `IBoosterUseService`, `IBoosterExecutor`, `IBoosterResourcePort`, `IBoosterAccessPolicy`, `IBoosterCatalog`; `BoosterCatalog`, `BoosterId`, `BoosterUseEventChannel` | **YES** → `IBoosterResourcePort` bridging to `InventoryService` | EditMode ✅ + PlayMode ✅ |

### The template

| Package | What it provides |
|---|---|
| `com.cuongbs.mobilepuzzle.template` | **Composes the flow packages into a working mobile-puzzle shell.** Largest package in the suite. |

What it gives for free:
- Boot → Home → Gameplay orchestration with an initial-route policy (skip Home for early levels)
- Heart-gated gameplay entry pipeline with a recovery hook
- Full revive / lose / win / retry / pause / quit flow already wired
- Interstitial insertion points (win, lose, retry, quit) behind `IInterstitialService`
- Scene transition with loading overlay and unused-asset cleanup
- Sample `SimpleMobilePuzzleFlow`: 3 scenes, 11 popup/panel prefabs, a `UIRegistry` asset,
  scene-builder + scene-validator editor menu items, and **one end-to-end PlayMode test**
  covering boot → home → gameplay → win → lose → retry
- Three optional adapter assemblies: `Adapters.Ads`, `Adapters.HomeFlow`, `Adapters.Resources`

Its contracts: `IInitialRoutePolicy`, `IHeartService`, `IHeartRecoveryHandler`,
`IGameplayEntryStep`, `IInterstitialService`, `IReviveHandler`, `ILoseConfirmation`,
`ISceneCleanupService`, `IMobilePuzzleSceneNavigator`, `IHomePanelPresenter`,
`IHomeEnteredHandler`.

Its entire config surface is four fields: `DirectGameplayLevelExclusive`,
`LoadingScene`, `HomeScene`, `GameplayScene`.

**What it does NOT give:**
- ❌ Any puzzle rules. A level is just an `int`. The sample "game" is two buttons: Win and Lose.
- ❌ Any level data model, level authoring pipeline, or level content.
- ❌ Level persistence — the sample level provider increments in memory, unbounded.
- ❌ Heart persistence — the sample heart service is in memory.

`/puzzle-mvp --mode signal` starts from this sample rather than building scenes from zero.

---

## Confirmed absent from the entire suite

Verified by grep across all packages. Do not go looking for these — they need creating.

| Missing | Note |
|---|---|
| **Consent / UMP / ATT / GDPR / IDFA** | Zero occurrences. `IAdsService.InitializeAsync` has no consent parameter. Highest-priority gap — blocks store submission. |
| **Feature-flag registry validation** | `LiveOpsCatalog.OnValidate()` silently deletes null / blank-id / duplicate-id definitions with no report. Copy the `UIRegistryValidator` + `IPreprocessBuildWithReport` pattern from `com.cuobs.ui`. |
| **Excel / CSV → ScriptableObject importer** | No Excel, NPOI, EPPlus, ClosedXML, or CSV reader anywhere. |
| **Any `EditorWindow`** | Zero across the whole suite. Every editor tool is a `CustomEditor` or a static `MenuItem`. Level-editor tooling is greenfield. |
| **Puzzle level data model / gameplay loop** | See template notes above. |
| **Difficulty tuning / solver / solvability validator** | Zero. |
| **Monetisation / economy / offer / shop package** | Must be assembled from `iap` + `resources` + `boosters` + `tracking`. |
| **Any concrete vendor adapter** | No ad provider, no tracking provider, no IAP store, no remote-config source, no time parser, no booster resource port. `FirestoreProvider` is the one vendor-touching file, define-gated. |
| **iOS build support in CI** | The CI runtime is Android-only. |
| Push notification, localization, save versioning/migration, FTUE, A/B assignment, crash reporting, anti-cheat, leaderboards, daily reward / quest / battle pass, rate-us | The homeflow `Feature` class lists 14 string constants naming such features, with zero implementations. |

---

## Known state worth knowing when reading the code

Not tasks — context, so you do not draw wrong conclusions from what you read.

| Observation | Why it matters |
|---|---|
| `HomeFlowTriggerAdapter` is currently excluded from the build by its `#if` guard | Home-flow is **not** wired into the template right now, despite the adapter existing |
| The consumer manifest resolves five packages from local paths | Resolves on this machine only; a different machine or CI will fail |
| Two package-integration tests assert git-based resolution | They fail because of the above configuration, not because of a code defect |
| `mobilepuzzle.template` exists in two working copies on different branches | Know which one you are reading before quoting it |
| `com.cuongbs.resources`, `com.cuongbs.homeflow`, `com.cuongbs.syncdata`, `com.cuobs.ui` declare no namespace | Type names can collide with game code |
| `com.cuobs.ui` has no test assembly | The riskiest place in the suite to change |
| `com.cuongbs.resources` is inventory, not asset loading | The name misleads on every first read |

---

## Rules that depend on this document

- `.claude/rules/service-layer.md` — adapter boundary, Null counterpart, consent-before-ads, SO event channels
- `.claude/rules/feature-flags.md` — catalog as single source, fail behaviours, kill-switch latency
- `.claude/rules/upm-consumption.md` — never fork a package into `Assets/`
- `docs/registry/services.yaml` — adapter status per contract
- `docs/registry/feature-flags.yaml` — flag inventory
