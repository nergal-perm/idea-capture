# JVM service and separate UI on macOS

Research date: 2026-11-14. Scope: primary-source review supporting a narrow
on-device experiment. Runtime observations are recorded below; this note does not
choose the production stack or installation mechanism.

## Process boundary and shared code

The Java launcher starts a JVM and invokes the selected main method; arguments
after the JAR name reach that method. Thus one artifact can implement
`--service` and `--ui` dispatch and be launched twice. These are application
arguments, not built-in Java modes. Two launches provide separate JVM
lifetimes while allowing shared compiled classes. This is an architectural
inference from the [Java launcher contract](https://docs.oracle.com/en/java/javase/25/docs/specs/man/java.html),
not a claim that the proposed artifact has already run successfully.

For the service launch, set `-Djava.awt.headless=true` before JVM startup.
[`Toolkit.getDefaultToolkit`](https://docs.oracle.com/en/java/javase/25/docs/api/java.desktop/java/awt/Toolkit.html#getDefaultToolkit())
uses its headless implementation when that property is true.
[`GraphicsEnvironment.isHeadless`](https://docs.oracle.com/en/java/javase/25/docs/api/java.desktop/java/awt/GraphicsEnvironment.html#isHeadless())
reports whether display, keyboard, and mouse can be supported; dependent AWT
operations may throw `HeadlessException`. Headless mode is not a sandbox or
a general prohibition on native libraries. Keep service initialization free
of UI toolkit initialization; dependencies require their own verification.

The proposed ownership boundary is a design requirement: the headless service
alone owns durable captures, attachment copies, delivery, status, and retry.
The UI obtains state and submits operations through local IPC. It does not
open queue files or implement another delivery worker. Swift Share intake
uses the same acceptance protocol, acknowledging save only after service
commit. A same-JAR demonstration can test this boundary with Java/Swing; it
cannot establish Kotlin/Compose initialization, packaging, memory costs,
GraalVM Native Image compatibility, or release signing. Those require the
actual dependency graph and release artifact.

## Window close and service lifetime

[`JFrame.setDefaultCloseOperation`](https://docs.oracle.com/en/java/javase/25/docs/api/java.desktop/javax/swing/JFrame.html#setDefaultCloseOperation(int))
distinguishes hiding a window, disposing it, and `EXIT_ON_CLOSE`, which calls
`System.exit`. Disposing the final displayable window may allow its JVM to
terminate; disposal alone does not guarantee immediate process exit.
[`System.exit`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/System.html#exit(int))
initiates shutdown of the current JVM. Therefore closing or exiting the UI
JVM need not stop a separately supervised service JVM. The experiment must
observe distinct process IDs and continued service work after UI closure;
window disappearance alone is insufficient evidence.

## Per-user supervision

Apple describes a user agent as a background process for a logged-in user,
running only while that user is logged in. This matches after-login service
availability; it does not provide operation while logged out or while the
machine is asleep. See [Creating Launch Daemons and Agents](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html).

Apple's published [`launchd.plist` manual source](https://github.com/apple-oss-distributions/launchd/blob/main/man/launchd.plist.5)
defines `RunAtLoad=true` as starting once when loaded, and
`KeepAlive=true` as keeping the process continuously running. Rapid repeated
exits may be throttled. The flags do not implement queue recovery or retry
correctness. That published source is historical: verify the installed
Mac's `launchd.plist(5)` and `launchctl(1)` before using exact commands.

For the disposable test, load a uniquely named job into the current user's
GUI domain using `launchctl bootstrap`, then remove it using `bootout`.
The concrete domain syntax and cleanup result belong in the experiment
record, checked against that Mac's installed manual. Do not install a
permanent login item merely to test supervision. Apple identifies
[`launchctl`](https://support.apple.com/guide/terminal/script-management-with-launchd-apdc6c1077b-5d5d-4d35-9c19-60f2397b2369/mac)
as the tool for loading and unloading jobs.

This is a per-user test using user-owned files and an unprivileged loopback
port; the proposed architecture requires no root process or system daemon.
Normal sandbox, file access, and user approval rules still apply. For a
shipped app on macOS 13 or later,
[`SMAppService`](https://developer.apple.com/documentation/servicemanagement/smappservice)
is Apple's API for registering bundled login items, agents, and daemons; its
agent registration replaces installing standalone LaunchAgent plists.
Temporary `bootstrap` success does not establish production registration,
approval, signing, or update behavior.

## Observed on-device experiment

The probe ran on the owner's arm64 Mac, macOS 27.2, using OpenJDK
21.0.13+9 and Xcode 27.2. The source references above describe API contracts;
the observations here come from this specific configuration.

One Java entry point was compiled into one JAR, dispatching `--service` and
`--ui`. A temporary per-user LaunchAgent launched the JAR with
`-Djava.awt.headless=true`, `RunAtLoad=true`, and `KeepAlive=true`. A small
Swift launcher in a regular `.app` launched the same JAR with `--ui` and
headless mode disabled. The UI was a real Swing frame containing a queue
table; it refreshed from the service's HTTP endpoint bound to loopback.
It showed capture IDs and queued states, rather than a content editor.

The containing `.app` and its sandboxed Swift Share extension were signed
ad hoc and passed nested signature verification. The extension was built
with `-application-extension`, App Sandbox and outgoing-network entitlements,
and a local-networking ATS setting. No App Group, development certificate,
or provisioning profile was used. The service and UI were nonsandboxed.
A separate native synthetic sharing host invoked the registered extension
through `NSSharingService`; this was actual extension dispatch, not a direct
HTTP call masquerading as a share.

Only the service read or wrote queue files. It held an exclusive owner lock,
wrote each synthetic capture to a temporary file, forced its contents,
atomically renamed it to its capture ID, forced the queue directory, and
then acknowledged acceptance. Each entry contained the supplied source text
and a separate fixed comment. The UI read queue IDs/states through IPC and
wrote only its own test diagnostics. The endpoint and test protocol were
not authenticated; production local authorization remains open.

| Check | Observation |
| --- | --- |
| Same artifact dispatched as service and UI with distinct PIDs | Passed: initial service and two successive UI processes had different PIDs |
| Service reports headless mode; UI reports graphical mode | Passed: service asserted headless mode; UI log reported graphical mode and visible Swing frame |
| Sandboxed Swift Share intake reaches loopback acceptance endpoint | Passed for three synthetic text shares |
| Source text and comment survive service readback unchanged | Passed: all three queue files independently decoded and compared |
| UI reads queue exclusively over IPC | Passed by implementation inspection and observed table updates; UI did not open queue files |
| Closing and reopening UI leaves service available | Passed: both windows closed, their JVMs exited, and the service continued accepting/querying captures |
| Intake progresses while no UI process exists | Passed: first share before UI launch and second share after UI JVM exit |
| Abruptly terminated service is restarted by temporary per-user job | Passed: service was sent SIGKILL; launchd started a new service PID |
| Saved synthetic data survives service restart | Passed: both existing captures recovered; reopened UI showed two entries |
| Live UI refresh while new share arrives | Passed: reopened frame changed from two to three entries |
| Another service attempts to own the same queue | Passed: second owner rejected by exclusive file lock; existing service remained available |
| Temporary job removed; all probe processes stopped | Passed: launchd job absent, service endpoint stopped, temporary app unregistered and removed |

The UI test exercised the normal window-closing event after a short timer,
then independently checked process exit. Frame visibility was checked using
Swing `isShowing`; visual quality and focus were not inspected by the owner
or through screenshots. Service restart recovered the saved queue after
SIGKILL, not a power-loss test. No delivery worker or backend was implemented:
the observed progress without UI was local capture acceptance only.

The job plist stayed inside the isolated research directory; it was loaded
into the existing GUI session with `launchctl bootstrap`, not installed
in a persistent LaunchAgents directory. The installed `launchctl(1)` manual
confirmed bootstrap/bootout service syntax. Removal used `bootout` and
waited for asynchronous teardown before confirming absence. No logout/login
cycle or `SMAppService` registration/approval was tested.

| Artifact | SHA-256 |
| --- | --- |
| Shared service/UI JAR | `41e853898085d6047a8ff3c5bbd46eb5d71c43d56e25eb3913229c4467b45d4c` |
| Sandboxed Share extension | `a8440c5574ed56dad89ba892ed316f3dbb7a56b3eb4bf3731ed7dc397d463ff0` |

Sources and raw observations are retained in the ignored local research
workspace and the owner's isolated research directory on the Mac. Runtime
paths, live job configuration, and raw process diagnostics are not copied
into tracked documentation.

This successful probe establishes the tested process, IPC, and
supervision properties. It does not establish a production durable queue,
attachments, real delivery, lost-acknowledgment handling, login persistence,
or performance.
