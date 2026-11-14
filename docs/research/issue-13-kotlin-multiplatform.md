# Kotlin Multiplatform shared core and native Share integration

Research for [issue #13](https://github.com/nergal-perm/idea-capture/issues/13),
2026-11-14. This report informs #10; it does not select a production stack.

**Current status:** [#13 is closed with a conditional suitability verdict](https://github.com/nergal-perm/idea-capture/issues/13#issuecomment-6883520262)
for the later Kotlin/JVM service route. See the [end-to-end follow-up](issue-13-kotlin-e2e.md)
and [closure audit](issue-13-closure-audit.md). Earlier inconclusive results and
next-step descriptions below are historical; remaining stage gates are in #11.

## Verdict and evidence boundary

**Historical KMP/Native assessment; see the later JVM follow-up below.** The documented
integration routes make Kotlin Multiplatform (KMP) a credible candidate for the
required executable core. They do not demonstrate this project's native Share,
durable ownership, cross-process queue, or delivery contract in full. Limited
Android and macOS target-device follow-ups are recorded separately below.
After installing full Xcode, the Kotlin framework built and its narrow common
logic ran from both the native macOS app and Share extension. Shared app/extension
queue authorization remains unresolved; these observations must not be promoted
to evidence that the complete shared-core delivery implementation works.

The target Mac was subsequently observed to be Apple Silicon (`arm64`), running
macOS 27.2. Current Kotlin documentation lists `macosArm64` as
Tier 1 and `macosX64` as **deprecated since Kotlin 2.3.20**. Kotlin/Native's default
minimum macOS deployment version is 12.0 in this compiler documentation. Linux cannot build
final Apple binaries. Any additional Intel Mac would need an explicit toolchain and
support-horizon decision; it is not interchangeable with Apple Silicon in this
assessment. [Kotlin target support](https://kotlinlang.org/docs/native-target-support.html)

The accepted requirements remain [technology boundaries](../technology-boundaries.md),
[lifecycle](../capture-lifecycle.md), [delivery](../delivery.md),
[attachments](../attachments.md), [interaction](../capture-interaction.md), and
[speech](../speech.md). In particular, SQLite is approved for backend state;
client SQLite and KMP/Ktor remain candidates. An attachment reference is not a
saved attachment, server acceptance is not delivery, and note publication plus
a SQLite transaction is not one atomic operation.

## Concrete target and toolchain matrix

The following is a **candidate build matrix**, not a verified lockfile. Versions
shown in current docs must be resolved together and recorded from the actual
build before reproducing the experiment. Current Kotlin's compatibility table
lists Kotlin/KMP 2.4.21 with Gradle 7.6.3–9.7.0, AGP 8.5.2–9.3.1, and Xcode 26.4.
For a deliberately older experiment, its table lists Kotlin 2.2.21 with Gradle
7.6.3–8.14, AGP 7.3.1–8.11.1 and Xcode 26.0. These are compatibility ranges, not
instructions to select arbitrary combinations. Current Kotlin also directs new
Android KMP integration toward Google's `com.android.kotlin.multiplatform.library`
plugin rather than assuming the old `androidTarget` setup remains the preferred
path. [KMP compatibility guide](https://kotlinlang.org/docs/multiplatform/multiplatform-compatibility-guide.html)

| Surface | Candidate compiled artifact / host | Concrete integration | Status |
| --- | --- | --- | --- |
| Android | Android Kotlin/JVM library in a native application APK; Android SDK/AGP plus JDK/Gradle | Share Activity and Worker call common queue/delivery code directly | Limited Android target-device results below; complete dependency graph remains unverified |
| macOS Apple Silicon | `macosArm64` framework; macOS/Xcode build host | Swift/AppKit app and Share controller link one common framework | Built/run with Kotlin 2.4.21 and Xcode 27.2; narrow bridge tests passed; shared App Group queue still unverified |
| macOS Intel | `macosX64` framework if available in the deliberately pinned compiler | Same native host architecture, with a separate deprecation/support risk | Not the tested Mac; current compiler target deprecated; no build |
| Omarchy | JVM helper using the shared KMP JVM target; JRE required | QML `Quickshell.Io.Process` exchanges framed JSON over stdin/stdout | Proposed simplest dependency route; helper/native UI integration unrun |
| Omarchy alternative | `linuxX64` executable (or `linuxArm64` if required) | Same common module, Native storage/transport implementations | Compiler target documented; dependency and packaging path unbuilt |
| Backend | Kotlin/JVM application, Ktor Netty or CIO, SQLite driver | HTTPS API, durable work and delivery records; separate filesystem publisher | Framework route documented; no claim of contract implementation |

Kotlin supports Objective-C framework interoperability from Swift; its bridge
has type and concurrency differences, so use a small Swift-facing API rather
than exposing arbitrary Kotlin implementation types. A callback or explicit
completion wrapper around suspend work is a proposed bridge, not evidence that
Swift structured cancellation has been solved. Framework and XCFramework
artifacts are supported build outputs. [Apple interoperability](https://kotlinlang.org/docs/native-objc-interop.html),
[native binary packaging](https://kotlinlang.org/docs/multiplatform/multiplatform-build-native-binaries.html)

Quickshell documents starting a command, reading output, writing stdin and
process exit notifications. This supports a helper boundary without embedding a
JVM in QML. **Inference:** a process protocol carrying capture commands and queue
snapshots is viable; this does not supply selection capture, durable scheduling,
or automatic source metadata. Those remain desktop adapter responsibilities.
[Quickshell Process](https://quickshell.org/docs/v0.2.1/types/Quickshell.Io/Process/)

Ktor currently documents 3.6.1. JVM Netty/CIO is an aligned backend candidate;
using Kotlin on both sides does not make backend publication and client queue
logic identical. Keep separate applications and stores. [Ktor releases](https://github.com/ktorio/ktor-documentation/blob/main/topics/releases.md),
[server engines](https://ktor.io/docs/server-engines.html)

## Dependency matrix and unproved compatibility

| Capability | Concrete candidate | Documented scope / outstanding check |
| --- | --- | --- |
| Queue SQL and generated queries | SQLDelight Gradle plugin/runtime 2.1.0 | Common schema/query API; compile with chosen Kotlin/AGP, migrations and extension target still required |
| Android queue | `app.cash.sqldelight:android-driver:2.1.0` | Native Android driver behind a platform factory |
| Apple queue | `app.cash.sqldelight:native-driver:2.1.0` | `NativeSqliteDriver`; explicitly resolve app-group database directory, not the example default name/location |
| Linux JVM / backend | `app.cash.sqldelight:sqlite-driver:2.1.0` | `JdbcSqliteDriver`; record transitive SQLite/JDBC binary versions and packaged architectures |
| Common byte/file operations | `org.jetbrains.kotlinx:kotlinx-io-core:0.9.3` | Candidate experimental API; OS grants and durability sync remain adapters |
| HTTP while process runs | `io.ktor:ktor-client-core:3.6.1` and explicit OkHttp / Darwin / CIO engines | Android/JVM, Apple, JVM respectively; Native Linux Curl alternative needs its own packaging check |
| JSON / asynchronous code | `kotlinx.serialization`, `kotlinx.coroutines` | Resolve and lock compatible versions with the chosen Ktor/compiler; no version or cross-target run is asserted here |

SQLDelight's maintained 2.1.0 documentation shows all three driver factories
above and generated queries from a shared schema. Its driver APIs establish a
plausible executable shared persistence layer; they do not prove multi-process
migration coordination or app-extension safety. [Multiplatform SQLite](https://sqldelight.github.io/sqldelight/2.1.0/multiplatform_sqlite/),
[Native driver](https://sqldelight.github.io/sqldelight/2.1.0/native_sqlite/),
[JVM driver](https://sqldelight.github.io/sqldelight/2.1.0/jvm_sqlite/)

The kotlinx-io repository specifies 0.9.3 and describes common IO primitives and
experimental filesystem support. Its filesystem API documentation currently
renders 0.9.2, explicitly says the API is unstable, requires additional
synchronization unless stated otherwise, and offers atomic rename. **Do not
infer durable fsync semantics or cross-process exclusion from `atomicMove` or
`close`.** Keep an explicit durable-file adapter and verify the selected
version's APIs/source before adopting it. The repository says Android 5.0+ is
compatible but not regularly tested. [kotlinx-io project](https://github.com/Kotlin/kotlinx-io),
[FileSystem API](https://kotlinlang.org/api/kotlinx-io/kotlinx-io-core/kotlinx.io.files/-file-system/)

Ktor provides per-platform engines. Darwin uses `NSURLSession`; Android can use
OkHttp, JVM CIO, and Native Linux Curl. An engine's use of an OS API alone is
not proof of persistent background-transfer ownership, callback reattachment,
or process-death recovery. This report does not claim an extension-safe audit
of Ktor, SQLDelight, Kotlin runtime, or their transitive libraries.
[Client engines](https://ktor.io/docs/client-engines.html)

## Native intake and durable ownership

Android's Sharesheet can start an exported Activity matching `ACTION_SEND` or
`ACTION_SEND_MULTIPLE` and MIME types. Read received text/streams from the
actual Intent; do not turn arbitrary `content:` URIs into filesystem paths.
Preserve supplied source text separately from authored comment and metadata.
The sending app constructs this payload; this mechanism promises neither
current selection nor a document title, canonical URL, book identity, or
reliable originating application identity. Test a selection and whole-document
share separately. [Receiving shared data](https://developer.android.com/training/sharing/receive),
[EXTRA_TEXT](https://developer.android.com/reference/android/content/Intent#EXTRA_TEXT)

Temporary Android FileProvider URI permissions can last only while the
receiving Activity stack is active. **Design consequence:** copy every stream
into client-owned durable files while access exists; reject a failed copy or
limit violation before confirming local save. Persistable document access must
not be assumed for an arbitrary Share Intent.
[FileProvider grants](https://developer.android.com/reference/androidx/core/content/FileProvider)

Apple documents macOS Share entry through a Share button or contextual menu,
custom UI based on `NSViewController`, and an extension context containing text
and attachments. That is a native Swift/AppKit host for the core, not a need to
adopt Compose UI. It still depends on what each host supplies; selection and
document share are distinct test cases. Available title/link/provider filename
may be absent, and a filename is not an inferred book title.
[Apple Share extension](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Share.html)

`NSItemProvider.loadFileRepresentation` writes a temporary copy that the system
deletes when its completion handler returns. Therefore complete the durable
copy inside the callback's access lifetime; if using another representation,
verify its access/security-scope rules explicitly. Never enqueue only that
temporary URL or promise later access after completing the Share request.
[Provider file lifetime](https://developer.apple.com/documentation/foundation/nsitemprovider/loadfilerepresentation%28fortypeidentifier%3Acompletionhandler%3A%29)

Proposed shared save protocol, constrained by the repository contracts:

1. Native adapter supplies unmodified received text, separately tagged received
   and user-entered context, and readable attachment streams. Drafts stay in
   memory. Do not normalize source text or extract text from files.
2. Core validates limits, copies streams into a staging area through a durable
   file adapter, records sizes/checksums, and assigns permanent capture identity,
   immutable description/version and originating local timestamp/offset.
3. Publish owned file paths and queue row only after all copies succeed. Define
   filesystem sync/rename and SQLite commit order explicitly. A database commit
   does not atomically commit external attachment files.
4. Show local-save success only after that protocol completes; then native UI
   may close. Interrupted staging never counts as a saved capture. Recovery
   must distinguish live staging from abandoned files before garbage collection.

This is an engineering proposal requiring crash injection; it is not a
demonstrated durability implementation. Exercise each copy, rename, database
commit and acknowledgement boundary, including full storage and revoked access.

## macOS extension safety, shared storage and concurrency

Apple permits shared embedded code but requires app-extension-safe APIs.
Configure the extension's `APPLICATION_EXTENSION_API_ONLY` requirement and
inspect the produced framework and transitive link dependencies; also verify
the Kotlin compiler's extension-related binary options against the pinned
compiler. Do not link app lifecycle, UI, recording or scheduler capabilities
into a common API that invokes unavailable APIs in the extension. **Unresolved:**
this exact Kotlin runtime + persistence + transport graph has not been compiled,
linked or run as an extension.
[Apple shared-framework requirements](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html)

Extension and containing app are separate processes/containers. Extensions
typically terminate soon after completing a request; an in-memory coroutine is
not the durable owner of pending work. Use an app-group container for the
candidate queue/files. Modern Apple documentation distinguishes macOS group
identifiers using `<Developer team identifier>.<group name>` and says those do
not require a provisioning profile; verify entitlements and signature identity
in both app and extension rather than copying iOS setup blindly.
[Extension lifecycle](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionOverview.html),
[macOS group-container access](https://developer.apple.com/documentation/xcode/accessing-app-group-containers),
[app-group configuration](https://developer.apple.com/documentation/xcode/configuring-app-groups)

Apple requires synchronization for shared-container access and identifies
SQLite/POSIX locks among the mechanisms. **Proposed protocol:** short SQLite
transactions, bounded busy handling, a database-enforced delivery claim/lease,
and serialized schema migrations shared by extension and application. A Kotlin
mutex protects only its process. Ensure one process cannot delete files while
another saves, hashes or uploads them. App-group directory resolution belongs
to Swift/Foundation; pass an explicit path to the driver.
[Shared-container coordination](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html)

SQLite WAL supports concurrent readers and a writer but still has one writer
at a time, requires all participating processes on one host, and uses sidecar
files. WAL with `synchronous=NORMAL` can lose committed work on power loss;
evaluate FULL plus file durability for the intended save guarantee. WAL is a
candidate setting, not an automatic correctness solution. Recover abandoned
delivery claims and reconcile completed native transfers on restart, without
equating an expired lease to failed delivery.
[SQLite WAL](https://www.sqlite.org/wal.html),
[SQLite isolation](https://sqlite.org/isolation.html)

## Delivery core, native transport and recovery contract

The proposed executable common module owns capture validation, SQL queue
transitions, immutable retry identity, retry classification/backoff timestamps,
per-capture orchestration and cleanup decisions. Native adapters own incoming
payload access, storage root/sync primitives, permissions, recording,
scheduling and transfer/task lifetimes. Keeping orchestration common requires
more than a portable model library: the same saved state and transition code
must resume from every adapter after process recreation.

Common transport operations should express description submission, status query,
verified file upload and transfer reconciliation. When an OS owns an asynchronous
transfer, persist the association between its task identifier and capture/file;
feed completion facts into the same common state machine. Do not require every
operation to remain suspended in one Kotlin coroutine until completion.

Ktor can supply ordinary requests while an owning process runs. Apple background
URLSession needs native configuration, shared files and reattachment policy;
Ktor Darwin's use of URLSession does not establish those properties. Apple
documents `sessionSendsLaunchEvents` and app-delegate background relaunch in
**iOS** terms. This must not be reported as a macOS containing-app relaunch
guarantee. Determine and test the actual macOS background owner: containing app
running after UI closure and/or an approved login/helper mechanism, plus
on-opening reconciliation. No fixed delivery deadline is promised.
[URLSession launch events](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/sessionsendslaunchevents),
[background session configuration](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/background%28withidentifier%3A%29)

Android WorkManager persists scheduled work across app restarts/reboots and
respects OS constraints. A Worker can reopen the durable queue and invoke common
delivery logic; do not encode capture contents solely in a worker's input or
let scheduler retry counts expire captures. Force-stop and device-specific
background restrictions require device checks and documented user action.
Opening the app must resume pending work.
[Android persistent work](https://developer.android.com/topic/libraries/architecture/workmanager)

The required status protocol is already settled at the product level in
[delivery.md](../delivery.md); exact endpoints remain open. A minimal experiment
must prove these distinctions rather than treating HTTP success as delivery:

| Observed fact | Common-core action required by existing contract |
| --- | --- |
| Server durably accepted description/files | Retain complete local capture; poll/query processing status |
| Upload interrupted | Keep local original; retry file from beginning; reuse verified completed files |
| Delivery reply lost | Query status first with same capture ID and unchanged manifest |
| Delivered record exists after note moved/deleted | Return prior confirmation; never recreate note/files |
| Same ID, changed manifest | Conflict; preserve local capture and show intervention reason |
| Crash after Inbox publication before delivery-record commit | Enter uncertain outcome if publication cannot be established; no automatic republish or acknowledgement |
| Confirmed complete delivery | Remove queue row/local data with restart-safe cleanup; no delivered history/success notification |

Backend SQLite transactions can coordinate durable identity, processing and
delivery records, but ordinary filesystem note publication lies outside that
transaction. The approved uncertain-outcome/manual-resolution policy is a
required implementation boundary, not a flaw that changing the client language
eliminates. [SQLite atomic commit scope](https://www.sqlite.org/atomiccommit.html),
[project publication policy](../adr/0003-persistent-delivery-records-and-uncertain-outcomes.md)

## Recording and personal distribution

The proposed boundary leaves recording native and passes a finished owned audio
file into the same save/transfer path. Backend transcription is a separately
durable task after initial note delivery; no client speech SDK is required by
this proposal. The five-minute limit, Russian/English/mixed recognition and
audio preservation remain [speech requirements](../speech.md), not findings
about codec/provider support.

Do not transfer an iOS restriction to macOS without checking it: Apple's archived
extension overview specifically labels microphone/camera prohibition as an
**iOS-device** restriction. This does not prove macOS Share-extension recording
works with the current SDK, privacy usage description, entitlements and host
lifecycle. Test that exact experience before promising one capture form with
recording inside the extension. A containing-app-only recording workaround must
be reviewed against the accepted interaction contract.
[Apple extension API restrictions](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionOverview.html)

Outside-store macOS distribution is an official route using Developer ID and
notarization. It does not remove nested-code signing, shared-container identity,
extension registration/enabling or upgrade testing. Validate the signed release
bundle, install it outside Xcode, confirm its Share action appears, then upgrade
while queued captures exist. Release signing costs/identity remain unresolved; the later follow-up
records the actual Mac OS/CPU. Android APK and repository Omarchy installation likewise need real
install/upgrade checks; no store publication is required.
[macOS distribution](https://developer.apple.com/macos/distribution/)

## Executed evidence

The local throwaway probe built a **JVM artifact only** using Gradle 9.7.0,
Kotlin Gradle plugin 2.4.21 and OpenJDK 21.0.13 on Linux amd64. The successful
`jvmJar` build took 43 seconds. `commonMain/Delivery.kt` contains queue,
orchestration and adapter interfaces; compilation for JVM proves executable
common-source logic on that target, not Native compilation or a cross-platform
dependency graph.

`run_probe.py` then ran four separate JVM processes:

- Save and hard halt (exit 71), followed by restart recovering exact Unicode
  source text and separately stored authored comment.
- Stub ACCEPTED and UNCERTAIN statuses retained the local capture.
- Deliver and hard halt (exit 73) after a fake note and durable receipt existed,
  before the client processed acknowledgement.
- Delete the fake note, restart, query the receipt and clean the client queue
  without recreating the note.

All assertions passed. The file-backed JVM queue uses temporary-file writes,
file force, atomic rename and directory force on the tested local filesystem.
The transport is a filesystem-backed fake, not Ktor or HTTP. Its receipt test
addresses a lost client acknowledgement **after** receipt persistence; it does
not test the uncertain interval between actual note publication and recording
delivery. It supplies ACCEPTED/UNCERTAIN responses rather than implementing
backend processing/recovery.

At the time of the JVM experiment, assets were untracked in a temporary research
worktree on branch `research/issue-13-kmp`, under `spike/`:
Gradle settings/build files, `src/commonMain/kotlin/Delivery.kt`,
`src/jvmMain/kotlin/Probe.kt`, `run_probe.py`, and `README.md`. No production
implementation or deployment was made. During the subsequent macOS session,
that temporary directory was found to have expired. Checking out the branch
cannot restore those untracked files. The historical reproduction command was,
from its `spike` directory with Gradle 9.7.0 and JDK 21 installed:

```sh
gradle --no-daemon jvmJar
KOTLIN_STDLIB=/path/to/kotlin-stdlib-2.4.21.jar python3 run_probe.py
```

The original probe README/runner are no longer retained. This did not test
attachments, SQLite, JSON, HTTPS/Tailscale, simultaneous processes, power loss,
OS scheduling or native Share. Do not interpret a source-supported row below
as a compiled artifact.

| Critical path | Documentation | Compiled | Emulator/simulator | Target device |
| --- | --- | --- | --- | --- |
| Common code through Android Share Activity | Supported route | APK and common Android library built | Not run | Android 15/API 35: synthetic Intent and actual Chrome selected-text intake passed; source/comment survived restart |
| Common framework through macOS extension and app | Supported route with safety caveats | Kotlin framework + native app/extension built after full Xcode setup | Not run | Kotlin model roundtrip, Kotlin-to-Swift callbacks and narrow delivery decisions passed in both processes |
| Quickshell invoking common JVM helper | Supported process boundary | Not established here | N/A | Not run |
| Shared app-group SQL/files with concurrent processes | Coordination mechanisms documented | Swift file-marker probes built; shared SQL unbuilt | Not run | Same-bundle write/read processes passed; actual extension read app marker was denied; shared queue not validated |
| Real selected text + original file, then entry-point death | Sender-dependent | Android receiving APK built | Not run | Chrome selection survived restart; original from Files survived source deletion and force-stop/reopen |
| HTTPS/file/status recovery after lost acknowledgement | Required by project contract | Not established here | Not run | Not run |
| Narrow common-source JVM queue/restart/fake-receipt probe | Local experiment above | JVM artifact built and assertions passed | N/A | Linux process assertions passed; separate Android fake-receipt checks below |

### Follow-up: Android APK build evidence before device tests

The owner authorized preparing a disposable APK and attempting remote Android
testing. That now-expired temporary worktree also contained `android-probe/`.
Its KMP core module includes the **same source directory** used by the JVM
probe, and both Android and JVM artifacts compiled. The APK contains a native
Share Activity, an Android SQLite queue adapter, original-stream copying with
size/count checks and SHA-256 verification, and an isolated local fake-delivery
probe callable directly or through WorkManager. It does not implement a real
HTTPS backend or the complete intended shared state/retry/validation core.

Build: Kotlin Multiplatform 2.4.21, Android Gradle plugin 9.3.1, Gradle 9.7.0,
OpenJDK 21.0.13, compile/target SDK 36, minimum SDK 26, build-tools 36.0.0,
WorkManager 2.11.1. `:app:assembleDebug`, `:core:jvmJar`, and `:app:lintDebug`
passed; Lint reported zero errors and 21 warnings (including experimental UI
localization/deprecated APIs and newer available dependency/SDK versions).
APK v2 signature verification passed. Artifact SHA-256:
`9f54853c4d093f92ad11694678a82230b32cca41a3461f6daa0e414972113358`.
Application ID: `org.ideacapture.research`, version `13.1-research`, label
**Capture Research 13**. Its manifest requests no INTERNET or broad file-access
permission. Queue storage is local to this debug application.

The Android probe README contains reproducible build and manual test steps.
SDK, signing keys, device addresses and raw observations remain outside tracked
documentation. A successful build is not target-device runtime evidence:
build results must be read alongside the distinct runtime observations below.

## Remaining decisive experiment and consequences for #10

1. Target Mac architecture/OS and Android device/API have now been observed.
   Install/initialize full Xcode and pin one complete toolchain and dependency
   graph, including transitive SQLite binaries; build all required variants.
   Any additional Intel target must address current KMP target deprecation.
2. Build a disposable native Android Share Activity, macOS Swift/AppKit app plus
   Share extension, and Omarchy QML-to-helper adapter using **the same common
   queue and transition source**. Link with extension safety enabled. Record
   architecture, runtime size/startup, signing and installed artifacts.
3. From named representative source apps on both mobile/desktop, share an exact
   multiline Unicode selection and then an original file/whole document. Record
   sanitized actual payload types, received exact text, optional metadata and
   missing fields. Verify attachment bytes/hash, multiple equal filenames,
   source access expiry and rejected oversized/inaccessible files.
4. Kill entry-point processes immediately after save, restart and recover the
   same immutable capture. Run concurrent app/extension saves and delivery,
   database-busy/migration cases, partial copy and storage-full failures.
5. Deliver through disposable HTTPS/JSON/file/status backend/Inbox; lose the
   acknowledgement, move/delete the note, restart both sides, then query/retry.
   Assert one publication; inject every publication/record boundary and verify
   uncertain-outcome blocking and explicit resolution.
6. Demonstrate OS-owned opportunities invoking/resuming common delivery,
   including macOS UI closure/quit, Android reboot/force-stop and offline/sleep
   recovery. Record restrictions and required user actions, not timing promises.
7. Check native recording permission/lifetime in the actual Share form and a
   finished audio file entering the durable pipeline. Full transcription remains
   a later-stage implementation.

If these pass, a plausible repository layout is a shared KMP core, native
Android application, native Swift/AppKit application/extension, JVM Omarchy
helper and Kotlin/JVM Ktor backend. This is a proposed layout only. Costs include
Gradle plus Xcode builds, Apple framework packaging/signing, OS adapters and
cross-process migrations; KMP does not remove them. If extension safety,
Intel support, native recording, or process-lifetime delivery cannot satisfy
the contracts at acceptable complexity, reconsider the candidate before #10 is
closed. Documentation alone provides no reason to declare the complete spike
successful or to reject all alternatives.

## Follow-up: observed Android target-device results

On a OnePlus 12R running Android 15/API 35, ADB pairing and connection over
Tailscale succeeded, and the debug APK installed. Initially the confirmed
connection port refused TCP on both Tailscale and local Wi-Fi. One off/on
cycle of Wireless debugging exposed a new advertised connection port, which
accepted the paired host. This is an observed troubleshooting outcome, not a
general claim about its cause or an Android requirement to restart debugging.
Device addresses, pairing codes and ADB keys are not research artifacts.

The following target-device assertions passed:

- A synthetic ACTION_SEND Intent delivered multiline Unicode source text;
  a separate comment was entered through the native UI, and both were saved
  unchanged in the queue. This checks the receiving Activity and shared
  module, but is not evidence of a real browser/reader's selection payload.
- Force-stop followed by reopening retained the same capture ID and text.
  This is a process/reopen test, not a reboot or power-loss test, and does
  not establish automatic background delivery after Android force-stop.
- The isolated fake-delivery test retained its pending capture after losing
  a synthetic acknowledgement. After force-stop/reopen, recovery used its
  durable fake receipt after deleting the fake note, emptied its test queue
  and did not recreate the note. Its SQL queue was inspected separately from
  the user-shared capture queue. No real backend exchange occurred.
- A WorkManager task scheduled from the app ran after returning to Home. Its
  recorded result passed both fake-delivery phases without reopening the UI.
  This demonstrates one ordinary background opportunity on this device, not
  sleep/reboot/battery-restriction/force-stop coverage or a delivery deadline.
- The owner shared a 132-byte synthetic original file from the Files app through
  Android Share. The capture's stored size/hash matched the host fixture.
  After deleting only that synthetic original from Downloads, force-stopping
  the app and reopening it, the same capture ID and internal copy remained.
  Direct byte hashing and the app's verification both passed. This demonstrates
  durable ownership beyond the original file/reference for this source-app case;
  it does not cover arbitrary providers, multiple files or interrupted intake.

Reboot recovery, HTTPS/file/status exchange, and macOS/native-extension
compatibility are still pending. Issue #13 remains
open and the stack choice remains unapproved.

### Actual Chrome selection and Firefox Focus observation

The owner selected only the synthetic sentence in the browser fixture and
shared it from **Chrome 157.0.8103.50**. The receiving Activity got ACTION_SEND,
MIME `text/plain`. The source field contained the selected sentence wrapped in
quotes, a newline, and the source URL with a `#:~:text=` fragment. The separate
comment was `Browser comment 13`. Assertions confirmed the expected sentence,
absence of the fixture's outside paragraph, a separate comment, and an unchanged
capture/metadata after force-stop/reopen. This is actual source-app evidence,
distinct from the earlier ADB-generated Intent.

Raw `title` and `subject` both contained `Including link: <source origin>`;
neither was the fixture document's actual title. **Implementation consequence:**
do not blindly promote either extra to a trusted document title. Preserve raw
received material and distinguish the quotation, supplied source identity, and
authored comment when defining the production source model. The prototype
retains the complete received text unchanged; it does not prove a general
quotation/URL parsing algorithm for arbitrary senders.

The owner also reported that **Firefox Focus 159.0.1** offered no Share action
for selected text in the tested scenario. Package Manager confirmed the installed
version; the agent did not independently inspect that browser's selection menu.
Record this as an owner-observed source-app compatibility limitation, not an
Android/KMP limitation or a universal statement about Firefox. Whole-page URL
sharing is not evidence that the selected-passage requirement works. A fallback
such as explicit copy/paste or a text-selection action requires its own UX and
source-context check before it can be claimed as supported. Android documents
`ACTION_PROCESS_TEXT`, but availability in this Firefox Focus menu was not
established. [Android text-processing intent](https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT)


## macOS target-device follow-up

### Host and actual compiler result

SSH/Tailscale access reached the owner's Apple Silicon Mac: `arm64`, macOS
27.2 (build 26B123), Swift 6.4.2, macOS SDK 27.2, Command Line Tools
27.2.0.0.1792721180. The selected developer directory was Command Line Tools;
no full Xcode installation was found by the targeted bundle lookup. No valid
code-signing identities were listed. This resolved the earlier unknown target
architecture without introducing an Intel requirement.

Isolated official distributions provided JDK 21.0.13+9-LTS and Kotlin/Native
2.4.21. The compiler started and downloaded its native dependencies. The actual
framework build requested `macos_arm64`, `-produce framework`, and forwarded
`-application_extension` to the linker. It **failed** at:

```text
Failed command: /usr/bin/xcrun xcodebuild -version
xcrun: error: unable to find utility "xcodebuild", not a developer tool or in PATH
```

Therefore no Kotlin framework, Swift bridge, or Kotlin runtime in a macOS Share
extension was demonstrated. CLT-only Swift success below must not be promoted
to that result. No fake version utility, compatibility-check bypass, global
Xcode selection change or system-tool replacement was used. Full Xcode is a
concrete prerequisite on this tested configuration. The documented Kotlin
2.4.21 compatibility pairing is Xcode 26.4; the observed CLT/SDK 27.2 is not
that pairing. Record and test the selected full Xcode version explicitly.

### Independent native Share experiment

Using the available Swift compiler, a separate Swift/AppKit app and Share
`NSViewController` extension were built, ad-hoc signed, verified and registered.
The extension used App Sandbox and `-application-extension`; the containing
app was not sandboxed. An AppKit synthetic source enumerated sharing services,
found the research extension, obtained `canPerform == true` and dispatched a
Unicode string plus one file through `NSSharingService.perform`.

The OS actually launched the extension. Its private-container report confirmed
exact multiline Unicode source text and a 51-byte original file. The supplied
`public.file-url` representation was `NSConcreteData`, rather than an already
bridged URL; the adapter handled it with Foundation's URL data-representation
initializer. This is an observed representation to support in the adapter,
not permission to assume all providers use it.

The copied file's SHA-256 matched the synthetic original. After deleting only
that original and terminating the extension process, the extension-owned copy
still matched. The comment was a fixed separate synthetic fixture, not a
human-entered Share-form/recording test. File copying occurred while the
provider callback/access was valid and before request completion. This is
ordinary process-lifetime ownership evidence, not full power-loss durability
or the complete immutable-queue protocol.

This was a synthetic native AppKit source, **not** Safari, a reader, or an
actual user-selected passage from those apps. No Kotlin was linked. It proves
that local ad-hoc native Share intake is testable on this Mac; it does not prove
the intended common core, complete interaction, or release distribution.

### App Group experiment and its limits

A properly bundled, sandboxed ad-hoc helper passed its startup control and
wrote/read a synthetic marker from two separate processes using the same
`group.` entitlement. Thus lack of a signing certificate was not, by itself,
a demonstrated blocker to that narrow local experiment on macOS 27.2.

The containing app and Share extension were then signed with the same
research group entitlement. The app resolved the group and wrote a marker.
The actual extension also resolved the group URL, but opening that app-written
marker failed with NSCocoaErrorDomain 257 / NSPOSIXErrorDomain 1,
**Operation not permitted**. The two-way app/extension marker assertion did
not pass. Targeted TCC diagnostics included code-requirement mismatches after
ad-hoc re-signing. The precise authorization/identity cause remains unresolved;
this is neither a demonstrated working shared queue nor proof that a supported
release signing configuration cannot work.

A resolved group URL, two processes with one identity, and actual app/extension
read/write are distinct evidence levels. Proper identity/entitlement setup,
upgrade behavior, shared SQLite access, migrations and concurrent delivery
claims still require verification. See the [primary-source supplement](issue-13-macos-primary-notes.md)
for Apple's local ad-hoc testing allowance and separate supported app-group
and distribution requirements.

### Retained assets, cleanup and next decisive step

The installed temporary app and its Share extension were terminated,
unregistered and removed after the experiment. Isolated downloaded tools,
sources and own-test observations remain in a dedicated user research directory
on the Mac. New local sources and observations are retained in a **persistent
ignored research worktree** on `research/issue-13-macos`, under `probe/` and
`observations/`; they remain untracked and checking out the branch alone cannot
restore them. No commits or pushes were made.

The earlier JVM/Android untracked assets in temporary storage were found to
have expired. This session reconstructed only the narrow Kotlin interfaces and
orchestrator from the recorded experiment; byte identity with the lost files
cannot be verified. This is explicitly not a new same-artifact cross-platform
run. The new worktree's README records build/run steps and distribution URLs;
private addresses, raw machine paths, SSH keys and credentials are not in this
report.

Next: install and initialize a full Xcode, select its developer directory for
the experiment, rebuild the common framework, and actually link/run it from
both native entry points. Resolve the observed app/extension group denial and
repeat durable file/queue recovery across processes with stable identity.
Then test named representative source apps, recording permission/lifetime,
background ownership, real HTTPS/file/status delivery, lost acknowledgements
and publication/receipt crash boundaries. The current verdict remains
**inconclusive for the complete requirement**, not rejected: native Swift
Share intake works, but the Kotlin bridge and shared executable queue remain
unproved on the Mac.


## Follow-up after full Xcode initialization

The owner installed and initialized **Xcode 27.2, build 27B52**. With its
per-command developer directory, Kotlin/Native **2.4.21**, JDK
**21.0.13+9-LTS**, and the existing ARM64 source, the framework build succeeded.
The prior missing-`xcodebuild` blocker is resolved. The compiler emitted a
bundle-ID inference warning but no build error. This demonstrates the selected
experiment on the newer Xcode; it does not rewrite Kotlin's documented
compatibility table or establish compatibility for every dependency.

### Actual Kotlin execution in both native entry points

A new disposable native app and Share extension used the **same embedded
Core.framework**, exported through its Objective-C-compatible Swift interface.
The generated header was inspected before writing protocol adapters. Both
components were sandboxed and ad-hoc signed; nested signature verification
passed. Mach-O inspection showed **APP_EXTENSION_SAFE** on the framework, and
the Swift extension compiled with `-application-extension`. That flag is not a
complete audit of every runtime/transitive API.

Both the app and OS-dispatched Share extension reported passing assertions for:

- Kotlin capture model construction and exact Unicode source/comment roundtrip.
- Kotlin invoking Swift implementations of the queue and transport protocols.
- Accepted and uncertain outcomes retaining a saved capture.
- Delivered status triggering removal, without resubmission when status already
  establishes the outcome.

The Share extension also received the synthetic AppKit source's actual text
and 55-byte original file, copied it, and saved a capture using the Kotlin model
and a Swift file-backed queue adapter. After deleting only the synthetic source
and terminating the extension, a new native verification process reconstructed
its saved capture through the Kotlin bridge, verified original-file hashes,
and resumed common delivery logic with an accepted outcome while retaining it.
This helper's SSH access to the extension's private directory is diagnostic
access, not a demonstrated shared app/extension storage architecture.

An additional four-process native executable test passed abrupt save/exit,
queue reconstruction, abrupt exit after a local fake note/receipt but before
client acknowledgement, then receipt recovery after deleting the fake note.
The same Kotlin orchestrator did not recreate it and cleaned its local test
queue. The transport was a filesystem fake, with no HTTPS backend and no test
of the publication-before-receipt uncertainty boundary.

### Shared queue remains a separate authorization gate

The new build used a fresh research bundle/group identity and sandboxed both
components. The normally launched containing app resolved the group URL but
its write failed with Cocoa 513 / underlying POSIX 1, Operation not permitted.
The extension's group URL resolved, but the host marker was absent. Therefore
no app/extension shared-queue roundtrip is claimed. Changing both sandbox mode
and identifiers does not isolate the cause of the earlier denial; no causal
claim is made from these variations.

No valid signing identities were present after Xcode initialization. The owner
was asked to establish Apple Development signing in Xcode. Current Apple macOS
capability documentation includes App Groups for the free Apple Developer tier;
a paid membership is not established as necessary for this local experiment.
See [the signing/authorization research](issue-13-macos-group-authorization.md).
The next supported check uses actual authenticated signing identity and the
corresponding group authorization, rather than ad-hoc entitlements alone. No
account credentials, fake Team ID or broad privacy-access grant is used.

### Scope and retained assets

New persistent research sources are under `probe/kmp/` in the ignored worktree
on `research/issue-13-macos`: native app/extension sources, shared Swift adapters,
framework build integration, restart verifier and native fake-delivery probe.
Ad-hoc observations were copied to `observations/kmp-adhoc/`. They are untracked
local assets and are not restored merely by checking out that branch.

This is meaningful new evidence for KMP suitability: a framework call alone was
extended to callbacks, persistence/reconstruction and delivery decisions inside
an actual Share process. It still uses a deliberately narrow reconstructed core,
not the full intended shared validation/state/retry/SQLite implementation.
Recording, representative macOS source apps, stable signed app/extension shared
storage, concurrency/migrations, real HTTPS delivery and wider lifecycle checks
remain open. Issue #13 remains open; no production stack has been selected.

## Alternative process ownership: JVM service and separate UI

The owner paused the App Group/signing path to reconsider process ownership.
The signing check described above is therefore not the currently selected
next step. Shared executable code does not require a shared app/extension
filesystem queue.

Subsequent narrow macOS experiments established two alternatives in the
tested local configuration:

- A sandboxed Share extension can cold-launch a containing app through
  `NSWorkspace` and send synthetic text to an ordinary JVM receiver over
  loopback. See [launch and handoff research](issue-13-macos-launch-handoff.md).
- One JAR can run as a headless queue-owning user agent and as a separate
  graphical queue client. Actual Swift Share intake continued after UI JVM
  exit; launchd restarted the killed service and it recovered saved test
  captures. See [service/UI experiment](issue-13-jvm-service-ui.md).

These alternatives did not use App Groups or Kotlin/Native in the extension.
The second probe used Java/Swing, not Kotlin/Compose or GraalVM, and tested
local acceptance rather than backend delivery. It establishes a viable JVM
process boundary, not the complete shared-core implementation or a stack
decision. Production registration/signing and the chosen Kotlin dependency
graph still need their own validation.

## End-to-end Kotlin/JVM follow-up

The owner clarified that UI may use cross-platform frameworks, including
Compose, and that native Share integration may hand work to a common-core
service through IPC. A new consistent Kotlin 2.4.21 / Ktor 3.6.1 / SQLite JDBC
distribution then ran on macOS arm64 and Linux x86_64 with matching JAR hashes.
The actual Swift Share adapter handed text and an original file to its Kotlin
queue owner; source deletion and service death/restart retained them. Real
HTTPS delivery, backend receipt recovery after lost acknowledgment and note
deletion, and blocked uncertain-publication recovery passed. An actual
Quickshell Process adapter invoked and delivered through the same core.

See the [full end-to-end report](issue-13-kotlin-e2e.md) for versions, fault
boundaries, observations, cleanup and remaining conditions. The result supports
**suitable with stated conditions for the Kotlin/JVM service route**; it does
not establish the full production core or the latest dependency graph on
Android, Compose/GraalVM compatibility, recording, or release installation.
Earlier Xcode/App Group blockers must not be treated as mandatory prerequisites
for this different IPC/service architecture. The owner still selects the stack
in #10.
