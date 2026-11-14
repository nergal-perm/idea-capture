# Use Kotlin shared logic and separate desktop service/UI in one repository

Owner-confirmed [resolution of #10](https://github.com/nergal-perm/idea-capture/issues/10#issuecomment-6883781978).

The owner selected Kotlin for the shared executable client core and backend
after research #13 established a suitable route with stated conditions. Keep
core, clients and backend in one repository with module boundaries, allowing
coordinated changes while retaining separate application and installation
outputs.

On macOS and Omarchy, a background client service owns capture intake, the local
queue and delivery; a separately launched UI shows state and submits commands.
Closing the UI must not stop that work. This trades a local process protocol
and service lifecycle management for independence from UI lifetime; the client
service remains distinct from the shared backend. Android uses its native
lifecycle and background opportunities instead of inheriting a desktop daemon
assumption.

Use ordinary JVM as the desktop service/UI and backend baseline; Android
compiles shared Kotlin logic with its own compatible APIs and adapters.
GraalVM remains an optional measured optimization, avoiding a mandatory
Native Image compatibility constraint on the initial UI and dependency choices.

Use Kotlin Multiplatform source sets with Android/JVM adapters for the shared
core, Ktor for the backend HTTP framework, and Compose for Android and
standalone desktop windows. KMP adds build configuration but makes common
versus platform dependencies explicit; it does not require a Native framework
inside Share. Ktor follows the successful end-to-end research route. Compose
permits UI reuse while retaining platform-specific intake and lifecycle work;
its actual dependency graph and distributable artifacts still need validation.

Share Compose capture and queue screens across Android and standalone desktop
windows, with platform-specific layout and integration. Keep the macOS Share
form in Swift inside the system Share window, avoiding an application switch
for that entry point at the cost of a separate form presentation. Validation,
save and delivery behavior remain common; native recording and permission
lifetimes still require verification.

Keep the Omarchy plugin as a thin shell/menu entry point that opens Compose UI;
replace its QML form and Python direct-Inbox writer at the working first-stage
cutover. Desktop UI and native Share use loopback HTTP/JSON to the client owner,
with separate streaming original-file requests and a durable-save acknowledgment.
Local discovery/access/failure details remain part of the protocol contract.

Start the headless service at login, supervised as a macOS user agent or Omarchy
systemd user service. Start UI only on request. An unavailable service leaves
the capture form in an error state rather than producing a false save result.

Separate shared contracts, client core, client storage and UI from applications
and platform adapters. The backend consumes common contracts but owns its own
schema, processing/publication and receipt store. Client storage shares its
schema, queries and migrations with platform drivers. Keep these boundaries
within the single repository; exact module names/build wiring remain details.

Distribute desktop UI and service together with an application-owned Java
runtime, so the owner need not install Java separately. Runtime updates become
part of application updates. Include Swift Share/background integration on
macOS and user-service/shell integration on Omarchy; validate platform-built
packages and lifecycle on the actual targets.

Storage drivers, SQL tooling, local protocol details and exact installer/signing
commands still need to be specified at their implementation gates. Preserve
the early Android compatibility gate and other checks carried from #13 into
#11. These decisions do not require Kotlin/Native or GraalVM. This planning
resolution does not authorize production implementation or deployment; the
detailed roadmap and acceptance gates remain the next planning task in #11.
