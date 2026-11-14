# Technology boundaries

Owner-approved decisions recorded during the design discussion for
[issue #10](https://github.com/nergal-perm/idea-capture/issues/10).
The owner confirmed the consolidated design and #10 was
[resolved and closed](https://github.com/nergal-perm/idea-capture/issues/10#issuecomment-6883781978).
Implementation and acceptance checks remain assigned to #11.

## Native clients

Use native operating-system mechanisms for Android, macOS,
and Omarchy/Quickshell. UI implementations may use platform toolkits or
cross-platform frameworks such as Compose Multiplatform; a platform-native UI
toolkit is not mandatory. Different implementation languages and separate client
UI implementations are acceptable. Native platform integration must coexist
with a shared executable functional core used by all clients. The owner selected
Kotlin for that core and the backend. The module boundaries below keep portable
logic separate from platform-specific capabilities.

A native Share adapter may invoke that core through a local service protocol;
the core need not be embedded in the extension process. Queue ownership and
save acknowledgment must remain explicit across the process boundary. A
headless queue/delivery service and a separately launched queue UI are the
selected desktop process boundary for macOS and Omarchy. The service owns the
queue and delivery; closing the UI does not stop it. Android retains its own
OS lifecycle/scheduling model, rather than assuming an always-running daemon.
Ordinary JVM is the selected baseline for desktop service/UI and backend.
Android compiles shared Kotlin logic for its own compatible runtime/APIs and
uses platform adapters; the desktop distribution is not an Android artifact.
GraalVM is an optional later optimization rather than a required baseline.
Compose is selected for Android and standalone desktop application windows.
Share Compose capture and queue screens between Android and standalone desktop
windows, adapting layout, keyboard/window behavior and OS integration per
platform. On macOS, Share retains a small Swift form inside the system Share
window; normal app entry opens Compose UI. The form delegates validation,
durable saving and delivery rules to the common-core service. Its recording
and permission/lifetime behavior still needs the assigned stage checks.
The Omarchy plugin becomes a thin entry point into the common Compose UI,
retaining shell/menu integration. Replace its old QML capture form and Python
direct-Inbox path when installing the working first stage; do not cut over the
current installation before the replacement works.

Desktop UI and the Swift form communicate with the client service using
HTTP/JSON over loopback, with separate streaming requests for original files.
The client service acknowledges local save only after the entire capture is durably
owned. Service discovery, access checks and failure details belong to the local
protocol contract; UI does not open the queue database directly.

Start only the headless service at user login and use OS supervision to restore
it: a user agent on macOS and a systemd user service on Omarchy. UI starts on
request. If service communication cannot be restored, keep the form in a
failure state without claiming a successful save. Login/service registration,
approval and recovery remain implementation acceptance checks.

## Shared core and backend alignment

Share executable client functionality, rather than only schemas and examples.
The owner selected Kotlin for shared client functionality and the backend so
the system is easier to understand and maintain. Use Kotlin Multiplatform with
shared code and Android/JVM adapters, and Ktor as the backend HTTP framework.
KMP organizes source/dependency boundaries; it does not require Kotlin/Native
inside the Swift Share extension or change the ordinary JVM desktop baseline.
Retaining Python business logic in the Omarchy
helper or choosing Python/FastAPI for the backend is not the selected direction.

The shared executable client core includes durable queue management, capture
states, retry rules, and delivery orchestration, in addition to models and
validation. Platform adapters supply operating-system capabilities; sharing
the core does not remove platform lifecycle or background-execution limits.

Native Share integration is a primary stack-selection criterion. Evaluate
receiving source text, available metadata and original files through platform
entry points, obtaining durable ownership before reporting local save, and
handing work to the shared queue across entry-point and application lifetimes.
This requirement does not assume that every OS has an identical Share surface
or that source applications supply complete identifying context.

SQLite is selected for durable backend state and all client queues. Clients
store capture descriptions, states and retry scheduling in SQLite, with
original attachments in separate owned files until confirmed delivery. Its
use does not by itself make
publishing an Inbox file and recording delivery one atomic transaction; the
existing uncertain-publication policy remains applicable. Client storage
shares its SQLite schema, queries and migrations, with platform-specific
drivers. Exact drivers, SQL tooling and versions are selected during the early
compatibility build. Client database/file consistency also requires an
explicit save/recovery protocol, rather than assuming a database transaction
covers external files.

## Repository boundary

Keep the shared core, all clients and the backend in this single repository,
separated into modules with their own application/package outputs:

| Boundary | Responsibility |
| --- | --- |
| Shared contracts | Versioned capture descriptions and exchange data |
| Client core | Validation, queue management, states, retries and delivery |
| Client storage | Shared client SQLite schema, queries and migrations, with platform drivers |
| Shared UI | Compose capture and queue screens |
| Applications and adapters | Android, desktop service/UI, Swift Share and Omarchy integration |
| Backend | Ktor, its own SQLite schema, note publication and persistent receipts |

The backend consumes shared contracts but does not reuse the client queue as
its processing store. Concrete module names and build wiring are implementation
details within these boundaries. See [the architecture decision](adr/0004-kotlin-core-and-desktop-service-boundary.md).

## Installation channels

Personal installation outside application stores is sufficient: an APK for
Android, an application distributed outside the Mac App Store for macOS, and
an Omarchy plugin installed from the repository. Store publication is not a
requirement. Desktop UI and service are delivered together with an application-
owned Java runtime, avoiding a separate Java installation requirement. Runtime
updates are part of application updates. The macOS package includes the Swift
extension/background component; the Omarchy distribution includes the app,
user-service definition and shell integration. Produce final packages on their
target platforms. Exact installer/signing commands remain implementation details;
validate packaging, service registration, permissions, updates and uninstall on
actual artifacts before accepting the affected stage.

## Remaining implementation and acceptance gates

Carry the checks from [research #13](https://github.com/nergal-perm/idea-capture/issues/13#issuecomment-6883520262)
into [roadmap #11](https://github.com/nergal-perm/idea-capture/issues/11#research-13-follow-through).
Before stabilizing shared modules, verify the selected Android bytecode/API and
dependency graph. Also verify the actual Compose dependency graph and packaging,
SQLite drivers/migrations, local protocol discovery/access/failure handling,
native recording, real source-app intake and production lifecycle/recovery.
These are not passed checks, even though the stack and boundaries are selected.
Revisit the affected decision if required compatibility or integration fails.
