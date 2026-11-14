# Issue #13 research closure audit

Audit date: 2026-11-15. Independent review of retained evidence and primary
documentation; no new experiment was run.

## Recommendation

**Close #13 as suitable with stated conditions for the Kotlin/JVM service
route, with the checks below carried into #11.** This completes a feasibility
investigation supporting the owner's stack decision in #10. It does not select
Kotlin, a UI framework or client database, approve a release, or establish one
identical artifact working on all three platforms.

This conclusion uses the accepted [technology boundaries](../technology-boundaries.md):
native Share adapters may hand work to a shared executable core through IPC;
UI may use Compose or platform toolkits. Consequently, unresolved App Group
authorization and Kotlin/Native dependency safety inside Share are not blockers
for this service route. They remain relevant if that alternative is revived.

## Facts established by the retained evidence

| Question | Evidence and limit |
| --- | --- |
| Is executable behavior shared on desktop? | The [Kotlin end-to-end report](issue-13-kotlin-e2e.md) records the same core/runner and full JAR distribution on macOS arm64 and Linux x86_64. The locally retained Linux/Mac runtime manifests and summary agree with those hashes. This establishes those two desktop runs only. |
| Can native Share reach the Kotlin owner? | Actual OS-dispatched sandboxed Swift Share intake sent text and original bytes to the Kotlin service. Owned file/SQLite state survived original deletion and service death. The macOS source host was synthetic; there was no production Share form or real browser/reader test. [Evidence](issue-13-kotlin-e2e.md) |
| Does real delivery exercise the difficult recovery boundaries? | Actual Ktor HTTPS/JSON/separate-file/status delivery published a note with its linked original. Backend death after receipt commit recovered through status after note deletion without republication; death before receipt commit produced an uncertain outcome that ordinary retry could not bypass. These are process-crash observations, not power-loss or complete publication-recovery coverage. [Evidence](issue-13-kotlin-e2e.md) |
| Can Omarchy invoke the implementation? | Actual Quickshell `Process` invoked the JVM helper and later delivered its saved capture through the common orchestrator. Production plugin migration and scheduling were not exercised. [Evidence](issue-13-kotlin-e2e.md) |
| Can service ownership outlive UI? | A separate Java/Swing experiment observed distinct UI/service JVMs, continued intake after UI exit, launchd restart and queue recovery. This is process-boundary evidence, not Kotlin/Compose UI or Kotlin delivery under launchd evidence. [Evidence](issue-13-jvm-service-ui.md) |
| What does Android prove? | Earlier target-device tests covered native text/file Share, original-file ownership, reopen recovery, an ordinary WorkManager opportunity and fake-receipt recovery. They did not run the latest dependency graph or real backend exchange. Earlier lost assets were reconstructed; no byte-identical three-platform run is established. [Evidence](issue-13-kotlin-multiplatform.md#follow-up-observed-android-target-device-results) |

The latest probe core is a Kotlin/JVM module targeting a JDK 21 toolchain,
with serialization models, queue/transport interfaces and delivery/retry
decisions. Its storage adapter is desktop JDBC. The raw summary and manifests
are retained in the ignored research workspace, as described in the end-to-end
report; they are supporting records, not experiments repeated by this audit.

## Primary-source cross-check and inference

Kotlin documents sharing business logic through common source sets, with
platform-specific APIs behind adapters. Google's KMP documentation confirms
business-logic sharing on Android. Neither promises that arbitrary desktop
dependencies work on Android. Android explicitly distinguishes its runtime
from a desktop JVM and limits available Java APIs; Ktor documents distinct
engine/platform requirements. **Inference:** reuse of the executable Kotlin
logic is credible, while Android must compile/package that logic with its own
storage, intake and scheduling adapters. Shipping the desktop JDK 21/JDBC
distribution unchanged is not the proposal.
[Kotlin sharing](https://kotlinlang.org/docs/multiplatform/multiplatform-share-on-platforms.html),
[Google KMP](https://developer.android.com/kotlin/multiplatform),
[Android Java versions](https://developer.android.com/build/jdks),
[Ktor engines](https://ktor.io/docs/client-engines.html)

Apple documents same-machine server connections under the outgoing-network
sandbox entitlement, and extension termination after request completion.
Together with observed intake, this supports a separate durable owner rather
than extension-owned background work. Apple's `SMAppService` documents bundled
agent registration subject to user approval; the temporary launchd experiment
does not prove shipped registration or upgrades.
[Network entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.network.client),
[Extension lifecycle](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionOverview.html),
[SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)

**Assessment:** the decisive architectural risks now have executable evidence:
native Share can transfer ownership into the common desktop implementation,
and that implementation performs real delivery with both receipt-recovery and
uncertainty blocking. Remaining gaps are explicit implementation acceptance
gates. Requiring the complete production UI, recording, migrations and release
installer to close a feasibility investigation would implement later stages
before the stack decision. Conditional closure is justified only while those
gates remain visible and can reopen the decision if they fail.

## Checks to carry into #11

1. **Shared-core/Android gate:** build and install the selected shared source
   and pinned dependency versions on the actual Android device with compatible
   bytecode/API settings and Android storage/HTTP adapters. Invoke the same
   executable transitions from Share and WorkManager; repeat original deletion,
   process recovery and real HTTPS/file/status/lost-response recovery. Record
   reboot, force-stop/reopen and battery restrictions. WorkManager's documented
   persistence is a mechanism, not a substitute for these device checks.
   [Android persistent work](https://developer.android.com/develop/background-work/background-tasks/persistent)
2. **First Omarchy/backend stage:** implement the approved text lifecycle,
   durable queue, retry/error classification and authenticated HTTPS over the
   intended Tailscale deployment. Verify restart recovery, lost acknowledgment,
   immutable-ID conflicts, publication uncertainty/manual resolution, concurrent
   intake and delivery cleanup against the project contracts.
3. **macOS stage:** test named real browsers/readers and the actual capture form;
   verify source/comment/context separation, file access and bounded streaming.
   Verify the chosen Kotlin UI/service package, headless initialization,
   service-unavailable save behavior, local IPC authorization, login approval,
   UI closure, sleep/restart and signed installation/upgrades on the target Mac.
4. **Attachments/voice stages:** exercise multiple and large original files,
   interrupted intake/upload, disk-full and permission failures, staging cleanup,
   migrations and the chosen durability guarantee. Test native recording
   permissions/lifetimes and finished-audio ownership; implement the agreed
   asynchronous backend transcription separately.
5. **UI/packaging decision gate:** verify Compose or GraalVM only if selected,
   using the actual dependency graph and packaged artifact. Failure of the
   Android shared-core build or required macOS integration must trigger a
   stack/boundary review before that platform stage proceeds.

These are carried obligations, not passed checks. Closure should retain this
conditional verdict, link the evidence and record the obligations in #11;
the owner still decides the production stack in #10.

## Closure recorded

The parent agent published the [final research resolution](https://github.com/nergal-perm/idea-capture/issues/13#issuecomment-6883520262),
then closed #13 as completed and moved its result into the map's Decisions so
far. Remaining checks are recorded in [#11](https://github.com/nergal-perm/idea-capture/issues/11#research-13-follow-through),
including an early Android compile/dependency/bytecode gate before stabilizing
the shared module, followed by full Android device acceptance at its stage.
The [stack decision #10](https://github.com/nergal-perm/idea-capture/issues/10)
remains open. No production technology or UI choice was made by closure.
