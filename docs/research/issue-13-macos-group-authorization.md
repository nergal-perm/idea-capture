# macOS App Group authorization: local development options

Primary-source research for issue #13, 2026-11-14. This supplement adds no
independently executed Mac results. Read alongside the
[main report](issue-13-kotlin-multiplatform.md) and
[primary-source notes](issue-13-macos-primary-notes.md).

## Immediate conclusion

**A paid membership is not established as necessary for this local experiment.**
Apple's current macOS capability table marks **App groups supported** for ADP,
Developer ID, and **Apple Developer**, which Apple defines as its free account
tier. The page's HTML contains three `figure` elements with `alt="yes"` in the
App groups row; text-only extraction drops these checkmarks. This is macOS
guidance: do not substitute an iOS free-provisioning capability table.
[Apple supported capabilities (macOS)](https://developer.apple.com/help/account/reference/supported-capabilities-macos/)

Apple calls an unpaid account selected in Xcode a **Personal Team**, with
certificates and profiles managed by Xcode. Apple DTS has demonstrated a free
Personal Team signing and provisioning a native macOS app, including a profile
authorizing the Maps entitlement. That demonstration establishes the signing
route, not this project's App Group roundtrip.
[Apple account overview](https://developer.apple.com/help/account/basics/about-your-developer-account),
[Apple DTS macOS Personal Team demonstration](https://developer.apple.com/forums/thread/787500?answerId=861714022)

## Authorization routes

| Group identifier | Current macOS requirement | Consequence for this probe |
| --- | --- | --- |
| `group.<name>` | Matching group authorization in each process's provisioning profile | Identical ad hoc entitlements alone do not establish authorization |
| `<TeamID>.<name>` | Prefix matches the developer team identifier actually used to sign the executable; no profile or portal registration required | A real team signature is still required; inventing a prefix is not a replacement |

Apple recommends the first form. Its documented automatic path uses
“Automatically manage signing” and `REGISTER_APP_GROUPS=YES`; inspect the
resulting signatures and profiles rather than inferring success from settings.
Apple lists app extensions among eligible bundled executables and documents
`launchctl procinfo`'s `entitlements validated` flag as a runtime check.
[Apple accessing App Group containers](https://developer.apple.com/documentation/xcode/accessing-app-group-containers)

Developer ID distribution also supports provisioned `group.*` identifiers;
the enabling portal change occurred in February 2025. The older blanket rule
that independently distributed Mac apps must use TeamID-prefixed groups is
obsolete. Since macOS 15, container protection applies separately from App
Sandbox. If the documented automatic authorization criteria are absent, DTS
describes a consent prompt whose grant lasts only for that app instance.
Neither removing App Sandbox nor accepting transient consent supplies the
intended stable authorization model.
[Apple DTS App Group comparison and container protection](https://developer.apple.com/forums/thread/721701)

## What the failures establish

The ongoing experiment reports URL resolution but a real write failing with
Cocoa 513 / underlying POSIX `EPERM`; the extension cannot read the absent
marker. A separate directly launched helper succeeded. These are different
launch/process configurations, not a successful app-to-extension roundtrip.
URL resolution alone is insufficient evidence of readable/writable ownership.

Apple DTS distinguishes BSD/ACL `EACCES` from `EPERM` arising through other
protection mechanisms. `EPERM` alone does not distinguish App Sandbox, mandatory
access control, or Endpoint Security. MAC applies even without App Sandbox and
depends on responsible-code attribution. Ad hoc rebuilds lack a stable identity
for remembered privacy decisions. DTS also documents GUI-session restrictions
for **Files and Folders prompts**; that specific statement must not be promoted
to a universal rule for every App Data or group-container prompt.
[Apple DTS file-system permissions](https://developer.apple.com/forums/thread/678819)

**Inference:** attribution, identity continuity, and container protection are
plausible contributors to the observed difference. No retrieved Apple source
proves that SSH is the cause in this experiment. A helper pass must not be used
to dismiss the normally launched app's failure.

## Smallest supported next experiment

Use Xcode's free Personal Team and Apple Development signing for both targets.
First try the recommended provisioned `group.*` route; retain the actual Xcode
diagnostic if this account/toolchain cannot authorize it. The documented
TeamID-prefixed macOS route is an alternative using the same real signing team.
No account creation, terms acceptance, certificate changes, or signing experiment
was performed for this research note.

Keep one signed build unchanged: launch the containing app normally, write a
unique marker, invoke the Share extension through the OS, read that marker and
write a reply, then read the reply in the app. Record each process's actual
signature, Team ID, entitlements, embedded profile authorization, runtime
validation flag, underlying errors, and contemporaneous denial logs. Restart
both processes and repeat. This isolates authorization before returning to
queue recovery and delivery tests.

## XPC alternative: supported IPC, not a proven signing bypass

A native queue owner can keep its files private and accept captures over IPC,
acknowledging only after durable saving. Apple DTS explicitly supports macOS
app-extension communication with an owned app or `launchd` agent/daemon despite
sandboxing: for an app listener it recommends a Unix socket in an App Group
container; for a `launchd` job, an XPC endpoint prefixed by an App Group ID.
Thus the documented shared-service path can avoid **shared queue files**, but
still uses App Group IPC authorization. It is not evidence that no suitable
signing/team setup is needed.
[Apple DTS extension-to-service IPC](https://developer.apple.com/forums/thread/818192)

An embedded `.xpc` bundle is not automatically a shared queue server visible to
every contained extension: Apple describes embedded services as visible to
their containing app. A service topology, endpoint reachability from the actual
Share process, authorization and lifecycle would need a separate probe.
[Apple DTS embedded XPC visibility](https://developer.apple.com/forums/thread/757627)

No XPC implementation or successful alternative ownership/recovery contract is
claimed here. With no usable team signature, the supported local next step is
to establish Personal Team signing first, rather than declare XPC an entitlement
escape route.
