# Kotlin/JVM end-to-end capture and recovery probe

Research for [issue #13](https://github.com/nergal-perm/idea-capture/issues/13),
conducted on 2026-11-14 UTC / 2026-11-15 in the owner's timezone. This is a
throwaway research implementation, not the production application or an
approved stack decision.

## Verdict

**Suitable with stated conditions for the Kotlin/JVM service architecture.**
The tested route is a thin native macOS Share adapter handing data to a
queue-owning Kotlin/JVM process over IPC, and an Omarchy Quickshell adapter
invoking the same JVM distribution. The common Kotlin delivery logic reached
an actual Kotlin/Ktor HTTPS backend with SQLite state, original-file uploads,
status recovery, and a disposable Inbox. Two distinct publication/receipt
crash boundaries were exercised successfully.

This removes the need to prove App Group authorization or embed Kotlin/Native
inside Share for this candidate route. It does not establish every requirement
of #13 on every platform: the new dependency graph was not installed on
Android, the macOS source was a synthetic AppKit sharing host, and the probe
has no Compose UI, recording, release installation or production scheduler.
The earlier Android target-device evidence remains separate. Kotlin, Ktor,
client storage, and UI choices still require the owner's decision in #10.

**Research closure:** following the [independent closure audit](issue-13-closure-audit.md),
#13 was [resolved and closed](https://github.com/nergal-perm/idea-capture/issues/13#issuecomment-6883520262)
with this conditional verdict. Unperformed checks were assigned to
[#11](https://github.com/nergal-perm/idea-capture/issues/11#research-13-follow-through);
this report's evidence limits remain unchanged. #10 owns stack approval.

## Accepted architecture interpretation

The owner clarified that native integration means using platform mechanisms
for Share, permissions, file access and lifecycle. UI implementations may be
cross-platform, for example Compose Multiplatform. A native Share extension
may call a shared-core service through IPC rather than linking the core into
its process. Shared executable models, states, queue/retry behavior and
delivery orchestration remain required; a collection of equivalent rewrites
or shared schemas alone does not meet that requirement.

The experiment used:

```text
macOS synthetic sharing host
  -> sandboxed Swift Share extension
  -> loopback intake, including original bytes
  -> Kotlin service / SQLite queue and owned files
  -> common Kotlin delivery orchestration / Ktor CIO client
  -> HTTPS / Ktor Netty backend / SQLite / disposable Inbox

Omarchy Quickshell Process
  -> Kotlin helper / local SQLite queue
  -> the same common delivery orchestration and HTTPS backend
```

The service and backend were separate applications with separate stores.
Neither the production Omarchy plugin nor the owner's real Inbox was changed.
The [preceding service/UI experiment](issue-13-jvm-service-ui.md) independently
verified separate headless and graphical JVM lifetimes using Java/Swing. That
UI experiment must not be described as Kotlin/Compose evidence.

## Resolved build and runtime

| Component | Actual version / observation |
| --- | --- |
| Kotlin JVM and serialization compiler plugin | 2.4.21 |
| Gradle | 9.7.0 |
| Linux JVM | OpenJDK 21.0.13+9 |
| Mac JVM | OpenJDK 21.0.13+9-LTS |
| Ktor server Netty and client CIO | 3.6.1 |
| kotlinx.serialization JSON | 1.11.0 |
| SQLite JDBC | 3.54.1.0; JDBC engine queried as SQLite 3.54.1 |
| Swift build host | arm64 macOS 27.2, Xcode 27.2 |
| Linux host | x86_64 Omarchy, actual Quickshell Process execution |
| Client/backend state | SQLite, WAL, synchronous FULL; explicit owned-file writes and directory synchronization |

Exact Kotlin, Ktor, serialization and SQLite artifacts were checked in Maven
Central, resolved by Gradle, and compiled together. All runtime JAR names and
SHA-256 values were recorded locally. The complete JAR hash manifest matched
between the Linux and Mac distributions, including the following artifacts:

| Artifact | SHA-256 |
| --- | --- |
| Shared Kotlin core JAR | `f8c5f73fc6550032154744454bf9f00debd37dc06521a03f5ad2b332e0362408` |
| Kotlin service/backend/helper runner JAR | `c9879be6263747d6fbe2055c6649331e9e8a31749ceaebf307f8ebae552a1950` |

The core contains serializable capture/file descriptions, queue and transport
interfaces, delivery/status decisions, uncertain-outcome blocking, and
persistent transient-retry state with a capped increasing delay. The runner
supplies the shared desktop SQLite/file adapter, HTTP intake, HTTPS transport,
backend, and stdin/stdout helper. This is a narrow executable slice, not the
full production validation, state taxonomy, SQL schema or migration design.
The JDBC adapter is a desktop adapter; Android needs its own appropriate
storage adapter and dependency/bytecode verification.

## Native intake and ownership observations

A new native `.app` and Share extension were compiled, ad-hoc signed, and
verified with nested signature checks. The extension used App Sandbox,
outgoing-network permission, extension-safe compilation and an ATS local
networking setting. It had no App Group entitlement. The service ran outside
App Sandbox. No development certificate or profile was used.

The synthetic host invoked the registered extension through the actual
`NSSharingService` mechanism with multiline Unicode text and a real file.
The extension consumed the item-provider representation while access was valid,
read the original bytes, and sent a versioned capture description and original
bytes to local intake. Base64-in-JSON was used **only for this small local IPC
fixture**; it is not a selected production streaming protocol. Backend uploads
were separate requests carrying original bytes.

The Kotlin service verified size/hash, persisted an owned file and SQLite
capture, and only then acknowledged local save. The fixture was 51 bytes,
with SHA-256
`8827cac8019406be0d07a9d7b8ba408365219f68eb1a3ebb238bc92193af274d`.
The received source and the fixed, separately supplied test comment matched
exactly. The experiment did not include human entry in a production Share
form, source-metadata parsing, multiple files or large-file memory behavior.

After deleting only the synthetic original, terminating the entry point and
abruptly killing/restarting the Kotlin service, the same capture ID, source,
comment, file description and owned file remained. The service recovered its
SQLite queue and the file's bytes/hash still matched. This is process-death
recovery, not a power-loss durability test.

## Real HTTPS delivery and lost acknowledgment

The backend served actual HTTPS using Netty and an isolated test certificate
with localhost/IP SANs. Client trust was scoped to that certificate; no global
trust settings or trust-all verifier was installed. An independent TLS control
accepted the configured certificate and rejected it under the default trust
store. The Mac-to-Linux connection used HTTPS over a temporary SSH reverse
forward carried by the existing Tailscale/SSH connection. This validates real
HTTPS and Tailscale-carried transport, not direct Tailscale listener deployment,
production certificate provisioning or network authentication policy.

The client queried status, posted the immutable versioned JSON description,
uploaded the separately requested original file, and requested completion.
The backend verified size/hash, stored the original in its per-capture
attachment directory, published a note with separate source/comment and a
relative original-file link, and committed a minimal delivered receipt in
SQLite. Independent readback verified the note content, link and file hash.
After delivery the receipt retained identity/fingerprint and outcome metadata,
not the original capture description. Intermediate-file cleanup is not a
complete production implementation in this probe.

For lost acknowledgment, a one-shot fault abruptly terminated the **actual
backend JVM**, exit code 73, after note publication and the delivered receipt
commit but before the HTTP completion response. The client observed a failed
exchange, recorded a retry with its attempt and next-attempt timestamp, and
retained its complete capture. Its queue survived another client restart.

Only the synthetic delivered note was then deleted. After backend restart,
the client queried status, recovered `delivered` from SQLite, and removed its
local capture and owned file. The deleted note was not recreated. This is
real network/process failure evidence, distinct from prior filesystem-fake
transport tests. Relocating a note was not separately tested in this run.

## Publication before receipt is a different result

A second synthetic capture exercised abrupt backend exit code 74 **after note
publication but before the delivered receipt commit**. The backend had already
persisted a publishing intent and expected note fingerprint. Its test note was
then deleted before recovery.

On restart, the backend could not establish publication and returned
`uncertain`, rather than replaying publication. The same Kotlin delivery
orchestrator retained the client capture and marked manual verification as
required. A subsequent ordinary retry remained blocked and did not recreate
the note. Manual owner-resolution operations were not implemented; the probe
only verifies that automatic/ordinary retry does not bypass the required gate.

## Omarchy adapter and common execution

An isolated QML configuration used the installed Quickshell `Process`, wrote
one versioned JSON request to the JVM helper's stdin, collected its JSON
acknowledgment, and observed a successful exit. The helper called the same
queue implementation and common model as the Mac service. The fixture kept
Unicode source and authored comment separate.

A later invocation of the same distribution reopened that helper's saved
queue and used the same common delivery orchestrator to complete HTTPS
publication. SQLite receipt and Inbox readback passed; its local queue was
empty afterward. This was actual Quickshell adapter execution in the Omarchy
session, not merely a documented CLI proposal. It did not migrate or replace
the installed Omarchy plugin, verify its full UI, or install Linux scheduling.

## Result matrix and remaining conditions

| Check | Evidence |
| --- | --- |
| One consistent Kotlin/dependency build on desktop targets | Built on Linux; identical JAR distribution ran on Linux x86_64 and macOS arm64 |
| Actual sandboxed Share to Kotlin service | Passed with synthetic native AppKit text/file source |
| Original file ownership before local-save acknowledgment | Passed; size/hash and exact bytes checked |
| Source deletion and entry-point/service death | Same saved capture and file recovered |
| Real HTTPS/JSON/separate-file/status backend exchange | Passed |
| Note and linked-original readback | Passed |
| Lost response after durable receipt, backend/client restarts, note deletion | Receipt recovery and cleanup passed; no duplicate/recreated note |
| Publication before receipt followed by note deletion | Uncertain outcome retained; ordinary retry did not republish |
| Quickshell Process to the same helper/core | Passed; subsequent real HTTPS delivery passed |
| New Kotlin dependency graph on Android | Not built or installed in this follow-up; historical Android evidence is separate |
| Compose UI, GraalVM, recording | Not tested or selected |
| Production storage/error/retry/scheduling semantics | Only the narrow slice above, not full acceptance |
| Cleanup | Mac service/app/extension and temporary SSH forward stopped/removed; local backend stopped |

Before the Android stage, compile and exercise the selected core/dependency
versions with its actual Android SQLite, WorkManager and intake adapters.
Before the macOS stage, verify representative browsers/readers, real capture
form and recording lifetimes, final UI/packaging, release signing/notarization,
and service registration/approval/upgrades. Compose and GraalVM, if chosen,
need their own dependency and packaged-artifact checks. File streaming/limits,
permanent-error classification, automatic scheduling, concurrent intake,
migrations, disk-full behavior, and complete staging cleanup remain staged
implementation/acceptance work. This probe did not rebuild the Android APK
or alter its prior installation.

## Reproduction and retained evidence

Sources, Gradle build files, installed distribution, native build script,
Quickshell fixture, TLS fixture and raw assertions are retained under
`probe/e2e/` and `observations/e2e/` in the ignored persistent research
workspace. They are local-only assets: checking out the research branch alone
does not restore untracked files. No commits or pushes were made. The backend
Inbox was disposable and contained only test fixtures. The uncertain test
capture remains in the stopped, isolated research queue for evidence; it is
not a user capture or an active installed service.

The local probe README records build/run order and the tests' one-shot fault
flags. Runtime paths, live SSH routing, test key material and process IDs are
excluded from this public report.

## Primary sources supporting the implementation route

- [Kotlin/Gradle compatibility](https://kotlinlang.org/docs/gradle-configure-project.html): compiler/plugin and build-host constraints. Actual compatibility above is also backed by the recorded build.
- [Ktor 3.6.1 release](https://github.com/ktorio/ktor/releases/tag/3.6.1), [Ktor server SSL configuration](https://ktor.io/docs/server-ssl.html): the probe used the current `applicationEnvironment` and engine-configuration `sslConnector` API, not an older Ktor 2 environment example.
- [Ktor CIO TLS configuration](https://ktor.io/docs/client-ssl.html): scoped client trust configuration; the successful exchange does not specify a production PKI policy.
- [SQLite JDBC project](https://github.com/xerial/sqlite-jdbc): JDBC/native runtime route. The driver loaded and executed on both tested architectures.
- [Quickshell Process](https://quickshell.org/docs/v0.2.1/types/Quickshell.Io/Process/): child execution and stdin/stdout integration, independently exercised here.
- [Apple outgoing-network entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.network.client): sandboxed connections to services on the same machine.
- [Apple item-provider file lifetime](https://developer.apple.com/documentation/foundation/nsitemprovider/loadfilerepresentation%28fortypeidentifier%3Acompletionhandler%3A%29): temporary source representations require ownership before their access ends; the probe consumed its actual supplied file-URL representation while valid.

See also the [main KMP report](issue-13-kotlin-multiplatform.md),
[launch/handoff research](issue-13-macos-launch-handoff.md), and
[service/UI experiment](issue-13-jvm-service-ui.md). Their earlier observations
must be read with the later architecture clarification rather than treated as
a mandatory App Group queue design.
