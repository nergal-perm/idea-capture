# macOS Share extension launch and handoff research

Research date: 2026-11-14. Scope: primary Apple documentation and Apple Developer Technical Support (DTS) statements, followed by a narrow on-device launch/handoff experiment. The probe has narrower evidential scope than a deployment guarantee. This note leaves the process architecture open.

## What the sources establish

macOS has a public application-launch API and supported communication paths between a sandboxed extension and an application or user agent. A JVM receiver does not inherently require an always-running JVM. However, application launch, receiver readiness, durable acceptance, UI activation, and eventual delivery are separate events. The APIs below do not collapse those events into one reliable transaction.

The strongest platform-specific statement found is [DTS, March 2026](https://developer.apple.com/forums/thread/818192): in a macOS AUv3 extension discussion, Quinn says a sandboxed appex cannot spawn the containing app's executable as a child when that requires sandbox reinitialization; it should be able to launch the app using `NSWorkspace`, although sandboxed callers do not get every launch configuration honored. DTS also explicitly supports communication with a controlled app or `launchd` job on macOS, recommending a Unix domain socket in an App Group for an app, or an App Group-prefixed named XPC endpoint for a job. This is relevant evidence for macOS app extensions, but it is **not a tested Share-extension recipe** and does not establish App Review acceptance.

## Application launch and process detection

[`NSWorkspace.shared.openApplication(at:configuration:completionHandler:)`](https://developer.apple.com/documentation/appkit/nsworkspace/openapplication(at:configuration:completionhandler:)) is available from macOS 10.15. It accepts the **application bundle's file URL**, not a JAR or an arbitrary executable. Completion returns an `NSRunningApplication` or an error and runs on a concurrent queue. A Kotlin/JVM application therefore needs a proper macOS `.app` launch arrangement; the launcher can start a bundled runtime, but that packaging is a separate integration question. Neither Kotlin nor Graal changes the operating system's launch authorization.

[`NSWorkspace.OpenConfiguration`](https://developer.apple.com/documentation/appkit/nsworkspace/openconfiguration) has `activates`, `hides`, arguments, and other controls. [`createsNewApplicationInstance`](https://developer.apple.com/documentation/appkit/nsworkspace/openconfiguration/createsnewapplicationinstance) defaults to `false`, so an existing running instance is reused. Do not assume changing launch arguments delivers a second capture to an already-running process. A separate IPC request or application URL-open handler must handle warm launches. Do not promise invisible/background startup until the actual sandboxed Share-extension call has been tested: DTS explicitly warns that some configuration is ignored.

For an app-bundle receiver, [`NSRunningApplication.runningApplications(withBundleIdentifier:)`](https://developer.apple.com/documentation/appkit/nsrunningapplication) returns currently running instances. `bundleURL`, `processIdentifier`, `isTerminated`, and `isFinishedLaunching` help diagnostics. Apple documents races in time-varying properties. Process presence, including `isFinishedLaunching`, is not proof that the receiver's socket or durable queue is ready. A standalone Java agent may also not appear as the intended application bundle. Use a bounded protocol handshake for readiness; tolerate the process disappearing after any observation. Treat detection as an optimization or diagnostic, not a correctness boundary.

When handing a URL or document to a chosen app, [`NSWorkspace.open(_:withApplicationAt:configuration:completionHandler:)`](https://developer.apple.com/documentation/appkit/nsworkspace/open(_:withapplicationat:configuration:completionhandler:)) is the corresponding public API. A custom URL containing an opaque request identifier is a candidate wake-up signal, not durable storage for arbitrary text or files. Resolving the containing bundle rather than a hardcoded installation path avoids assuming the app lives in `/Applications`; duplicate installed copies still need an explicit test.

## Do not import iOS restrictions into macOS

[`NSExtensionContext.open(_:completionHandler:)`](https://developer.apple.com/documentation/foundation/nsextensioncontext/open(_:completionhandler:)) exists on macOS, but its contract delegates support to each extension point. Its current discussion explicitly names the Today and iMessage extension points **on iOS**; it does not promise support for macOS Share. The [archived extension overview](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionOverview.html) has older Today-only wording. Neither is a sound basis for assuming Share supports this call.

[DTS's 2025 containing-app answer](https://developer.apple.com/forums/thread/779644) rejects a `UIApplication` runtime trick and links an [iOS 18 Share-extension discussion](https://developer.apple.com/forums/thread/764570). These are UIKit/iOS evidence. They demonstrate that bypassing extension-unavailable APIs is unsupported; they do **not** negate the separate AppKit/macOS guidance above. Mac Catalyst and an iOS app running on Apple silicon must also be distinguished from a native AppKit macOS extension. A `Process`/shell workaround is not a substitute for Launch Services.

## Local handoff, sandbox, and durable acceptance

For TCP loopback, the extension needs [`com.apple.security.network.client`](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.network.client): Apple explicitly includes connecting to a server on the same machine. A sandboxed listening receiver needs [`com.apple.security.network.server`](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.network.server). For TCP these govern connection initiation, not response data flow; a client does not need server permission simply to receive a response. Bind a local service to loopback rather than all interfaces. Authentication and request identifiers remain necessary design work; a TCP port alone does not establish peer identity.

[`App Groups Entitlement`](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.application-groups) documents shared containers and IPC between sandboxed apps, and between sandboxed and nonsandboxed apps on macOS. A Unix socket must live inside the group container and fit the socket-path limit; a named Mach/XPC service must use the group identifier as its prefix. This can avoid TCP port allocation and HTTP/ATS concerns. App Group access must be configured on every participating executable; obtaining a plausible container URL alone is not an access test.

For new group setup, [DTS's updated App Groups guidance](https://developer.apple.com/forums/thread/721701) recommends registered `group.` identifiers and provisioning profiles authorizing them, including Developer ID distribution. Older macOS-style identifiers have historical differences. Verify the chosen signing/profile configuration in the distributed artifact, not only a local debug build.

If the extension uses `URLSession` for plain HTTP loopback, sandbox permission and ATS are separate layers. Apple's [`NSAllowsLocalNetworking`](https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity/nsallowslocalnetworking) documentation describes different behavior for numeric IP addresses from macOS 14. Test the actual hostname/IP form and targeted OS; do not add a broad arbitrary-load exception by assumption. A Unix socket does not use ATS.

An extension can end after completing its request; [Apple's extension scenarios](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html) requires coordination when sharing files with the containing app. Proposed acceptance semantics: copy transient provider material while access is valid, retain a request identifier across retries, and acknowledge Save only after the selected durable owner has committed all required data. A launch callback or IPC write is not that commit. If the owner commits but its acknowledgment is lost, retry must return the prior acceptance rather than duplicate the capture. App Group staging can protect transport across launch failures, but ownership of staged material and cleanup must be explicit. This is a reliability proposal, not an Apple API guarantee or a decision to persist unsaved drafts.

## An on-demand user agent is a third option

[`SMAppService`](https://developer.apple.com/documentation/servicemanagement/smappservice), available from macOS 13, registers bundled Login Items, LaunchAgents, and LaunchDaemons. `agent(plistName:)`, `register()`, `status`, and `unregister()` support a per-user service. Registration/authorization are different from whether its process is currently running. The user can disable background execution in System Settings. A login item begins immediately and at subsequent logins; a LaunchAgent can instead express on-demand criteria. This is installed service registration, not permission-free startup on the first share.

[Apple's helper migration guide](https://developer.apple.com/documentation/servicemanagement/updating-helper-executables-from-earlier-versions-of-macos) places agent property lists in `Contents/Library/LaunchAgents` and uses bundle-relative `BundleProgram`. [DTS's setup guide](https://developer.apple.com/forums/thread/802443) says a sandboxed app's agent must also be sandboxed; nonsandboxed app plus sandboxed agent is supported. A helper needing profile-authorized entitlements needs an app-like wrapper to carry its provisioning profile. A user-level capture service does not inherently need an administrator-authorized system LaunchDaemon.

[Apple's launchd guide](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html) documents launch on demand: launchd owns the advertised sockets and starts the job when traffic arrives. [`launch_activate_socket`](https://developer.apple.com/documentation/xpc/launch_activate_socket) retrieves the pre-created descriptors by the name in the job's `Sockets` dictionary. A conventional JVM HTTP server that simply binds its own port is not automatically socket activated. Descriptor adoption needs runtime/library support or a small native bridge. The same handoff and durable acknowledgment concerns remain, with a potentially cold JVM after activation. Named XPC activation is another native integration path; these mechanisms have not been tested for this project.

## Runtime choices left open

| Candidate | What it could accomplish | Evidence still needed |
| --- | --- | --- |
| App launched on demand, JVM owns queue and UI | No idle JVM when app exits; one queue owner | Cold/warm Share launch, runtime readiness, durable handoff, background delivery after UI closes |
| Graal Native Image app owns queue and UI | Ahead-of-time native receiver; no JVM process required | Actual compatible build, native API bridge, packaged startup and memory measurements |
| Lightweight resident native owner, JVM UI on demand | Queue/delivery can outlive UI without resident JVM | Service authorization, IPC, ownership and UI integration, idle memory |
| Socket/XPC-activated agent, UI separate | Registered service can be available while receiver process is absent | Activation bridge, startup latency, retry scheduling, disable/re-enable behavior |

Graal Native Image is an [ahead-of-time native executable](https://www.graalvm.org/latest/reference-manual/native-image/), rather than the JVM with a faster launch switch. Apple launch APIs address the app bundle and process contract independently of either runtime. The experiment below does not establish production startup or memory performance. For a JIT-based JVM under Hardened Runtime, [Apple's JIT guidance](https://developer.apple.com/documentation/apple-silicon/porting-just-in-time-compilers-to-apple-silicon) explains `allow-jit` and `MAP_JIT`; the actual runtime determines the necessary configuration. Do not copy every runtime exception into the app or extension. Direct distribution additionally needs the signing and notarization treatment described by [Apple](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

If the GUI is strictly a queue viewer, the service must also execute delivery, status checks, and retries for delivery to continue while the GUI is closed. A Swift-only service implementing those rules would undermine the accepted shared executable core. A headless Kotlin service reusing the core, possibly compiled with Native Image if its dependencies permit it, remains a candidate; neither its small memory footprint nor Native Image compatibility has been established. A native persistence-only ingress is another boundary, but its consumer still needs an execution/scheduling arrangement. Choosing IPC does not settle these ownership decisions.

## Observed Share-to-JVM launch experiment

On the owner's arm64 Mac running macOS 27.2, a new disposable app and Share extension were compiled using Xcode 27.2. The extension was built with `-application-extension`, signed ad hoc, sandboxed, and given only outgoing-network permission in addition to App Sandbox. It had no App Group entitlement. The containing app was nonsandboxed and ad-hoc signed. Both signatures passed nested verification. No development certificate, profile, login item, or LaunchAgent was used in this experiment.

A separate native synthetic source invoked the actual registered Share extension using `NSSharingService`. The extension loaded the supplied multiline Unicode text, enumerated the receiver's running bundle instances, and checked a loopback HTTP readiness endpoint. When absent, it used `NSWorkspace.openApplication` on its containing `.app`, with `createsNewApplicationInstance=false` and `activates=false`, then polled readiness before posting the text and a separate fixed test comment. The containing app used a small AppKit launcher to start an ordinary OpenJDK 21.0.13+9 Java receiver. The receiver bound only `127.0.0.1`, wrote the synthetic capture to a test file, forced the file and directory, and returned a save acknowledgment. The extension used `URLSession` and `NSAllowsLocalNetworking=true`.

| Observation | Cold receiver | Already-running receiver |
| --- | --- | --- |
| Bundle instances before handoff | 0 | 1 |
| Readiness before handoff | Unavailable | Ready |
| Extension's launch request | Succeeded | Not needed |
| Bundle instances after handoff | 1 | 1 |
| Save acknowledgment received | Yes | Yes |
| Recorded elapsed time inside extension | 0.345 s | 0.017 s |

Independent readback verified the exact source `Launch handoff 13\nТочная цитата` and separate comment. These are two functional observations, not benchmark samples: they exclude Share-menu discovery, human interaction, and extension startup. The probe did not include a Kotlin application, GraalVM, Compose, jpackage, attachments, concurrent submissions, crash recovery, lost acknowledgments, real delivery, or a production queue. Its single test file was overwritten by the next submission; it is not a queue implementation. The receiver's native launcher was registered as an application, so the observed instance counts must not be generalized to standalone Java processes. Focus behavior was not independently observed, despite requesting no activation and using an accessory receiver.

The new temporary app was unregistered and removed after the test, and its receiver and extension processes were stopped. No background startup configuration was installed. Sources and raw observations remain in the ignored local research workspace and the owner's research directory on the Mac, not in tracked project files. Sanitized artifact SHA-256 values:

| Artifact | SHA-256 |
| --- | --- |
| Native app launcher | `7e8561a5570ceebf10c8104646dddada12c889006a575710f047e8c454f2907a` |
| Sandboxed Share extension | `2a84245f4938da3aacaeef85c7f6a94ac61b8ef89ebfe1697fb06b1afcacfc43` |
| Java receiver class | `3589098aec1a2bf751c495182fd7d92ea08a1c3e22efc38b1ea0b0d6401c4a06` |

This establishes that a real sandboxed macOS Share extension can detect this app, cold-launch it through the public API, and hand test text to a JVM receiver over loopback in the tested configuration. A resident daemon is therefore not required merely to make cold launch possible. The service/GUI split remains a choice about background work, process lifetime, memory, packaging, and code reuse.

## Minimal proposed validation matrix

Use a real signed macOS Share extension with extension-safe API checks enabled, first on the minimum supported macOS and then the latest supported macOS. Run outside the debugger. Start with a tiny packaged receiver to isolate OS behavior, then repeat with the actual packaged JVM or Native Image receiver. Record exact OS, SDK, architecture, artifact hash, entitlements, profile, distribution mode, launch callback error, receiver readiness, and durable acknowledgment.

| Case | Required observation |
| --- | --- |
| Cold receiver; share text/URL from Safari and a native text app | Public launch succeeds; form and receiver become ready; Save commits before completion |
| Warm receiver, including hidden and minimized | Request reaches existing process; no duplicate instance or reliance on launch arguments |
| Two near-simultaneous shares; receiver starting | One owner, independent request IDs, no lost or merged captures |
| Receiver commits, then acknowledgment is interrupted | Retried request yields the original durable acceptance |
| Launch fails, receiver crashes, port is occupied, or protocol times out | Extension reports/retries failure without reporting a false save; staged data follows explicit ownership rules |
| Shared original file followed by host/provider cleanup | Receiver retains the complete original after extension/host exit |
| `activates=false`/`hides=true`, cold and warm | Observe actual focus/window behavior; log ignored options |
| Installed app moved or duplicated; fresh user/install | Correct app selected; first-run Gatekeeper and Share extension enablement handled |
| Agent unregistered, requires approval, disabled, reenabled; logout/login | User-visible state matches availability; activation never falsely claims a commit |
| On-demand agent absent versus resident owner idle | Activation works when absent; measure startup and idle memory independently |

Before external distribution, repeat the chosen flow with the release-signed/notarized artifact on a clean account. A locally successful experiment establishes behavior for that configuration, not universal macOS support or App Review approval.
