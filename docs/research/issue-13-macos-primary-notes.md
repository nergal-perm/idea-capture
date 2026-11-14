# macOS Kotlin/Native Share probe: primary-source supplement

Research for issue #13, 2026-11-14. This supplement records documentation and
proposed experiments; it contains **no independently executed Mac results**.
Read it alongside [the main report](issue-13-kotlin-multiplatform.md) and the
accepted [technology boundaries](../technology-boundaries.md).

## What can be tested without a signing identity

Apple explicitly permits ad hoc signing when testing app extensions, provided
the containing application and all project targets use the same signing
approach. Its example test is a macOS Share extension invoked from Safari after
the user enables it. Apple also documents distributing macOS extensions outside
the Mac App Store; opening/approving the containing application precedes
extension availability. Thus a missing Developer ID certificate is **not by
itself a documented blocker to local Share intake and Kotlin runtime tests**.
This is distinct from proving shared-container access or release distribution.
[Apple extension creation/testing/distribution](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionCreation.html)

Modern macOS app-group authorization is a separate constraint:

- `group.<name>` requires the group entitlement to be authorized by the process's
  provisioning profile.
- `<TeamID>.<name>` needs no provisioning profile or website registration, but
  macOS checks its prefix against the developer team identifier used to sign
  the executable.
- Both app and extension need membership. Resolve the directory with
  `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)` and test
  actual write/read access from both processes.

Therefore “no provisioning profile required” does **not** establish that an
ad hoc signature with no authenticated Team ID can use that route. A directory
URL alone would not establish shared readable/writable storage. With no signing
identity, treat a successful app-group experiment as an OS/version-specific
observation requiring signature/entitlement inspection, not a supported release
identity model. Do not fabricate a Team ID.
[Apple macOS app-group authorization](https://developer.apple.com/documentation/xcode/accessing-app-group-containers),
[configuration and directory API](https://developer.apple.com/documentation/xcode/configuring-app-groups)

Apple now recommends the `group.` form on macOS too; Apple DTS says full support
across product types, including independent distribution, arrived in February
2025. The older rule “outside-store macOS must use TeamID-prefixed groups” is
outdated. Independent release signing uses Developer ID Application; local ad hoc
execution does not demonstrate that release/notarization path.
[Apple DTS app-group comparison](https://developer.apple.com/forums/thread/721701),
[Apple distribution signing](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac)

## Native framework build and extension safety

Kotlin's framework tutorial explicitly covers macOS frameworks consumed by
Swift/Objective-C. For an Apple Silicon Mac, a minimal Gradle target is
`macosArm64 { binaries.framework { baseName = "Core" } }`; run
`./gradlew linkDebugFrameworkMacosArm64` and inspect
`build/bin/macosArm64/debugFramework/Core.framework`. The common implementation
must be the same source used by the other client probes, rather than a new
macOS-only substitute.
[Kotlin Apple framework tutorial](https://kotlinlang.org/docs/apple-framework.html)

For direct CLI compilation, the compiler source defines `-target`,
`-produce framework`, `-output`, `-linker-option`, and `-linker-options`:

```sh
kotlinc-native Core.kt -target macos_arm64 -produce framework -output Core \
  -linker-option -application_extension
```

This is a proposed minimal command, **not an executed build**. Confirm spelling
and accepted arguments with the downloaded compiler's `-help`. The equivalent
framework DSL setting is `linkerOpts("-application_extension")`; inspect its
actual compiler invocation. No primary evidence was found for a Kotlin binary
option named `applicationExtensionApiOnly`.
[Kotlin compiler argument declarations](https://github.com/JetBrains/kotlin/blob/master/compiler/cli/cli-base/gen/org/jetbrains/kotlin/cli/common/arguments/K2NativeCompilerArguments.kt)

`-application_extension` is Apple's **linker** option. It declares extension use
and validates linked dynamic libraries for extension safety. It is not a
source-level audit of Kotlin cinterop calls, static dependencies, or the whole
runtime. Set the Swift extension's `APPLICATION_EXTENSION_API_ONLY=YES`
(direct Swift compilation: check `swiftc -help` for `-application-extension`)
and inspect link warnings and the framework's Mach-O flags/dependencies.
Do not suppress unsafe-link warnings to obtain a nominal pass.
[Apple linker manual source](https://github.com/apple-oss-distributions/ld64/blob/main/doc/man/man1/ld-classic.1),
[Apple shared-framework guidance](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html)

The toolchain documentation is not completely consistent about CLT-only hosts:
the Native getting-started page asks for Xcode Command Line Tools for macOS,
while the overview asks for Xcode and its tools. Record the selected compiler's
actual CLT-only build outcome and exact error before requiring full Xcode.
The compatibility table pairs Kotlin 2.4.20–2.4.21 with Xcode 26.4; this is a
documented compatibility pairing, not evidence about a newer SDK or CLT-only
execution.
[Kotlin Native setup](https://kotlinlang.org/docs/native-get-started.html),
[Native overview](https://kotlinlang.org/docs/native-overview.html),
[KMP compatibility table](https://kotlinlang.org/docs/multiplatform/multiplatform-compatibility-guide.html)

## Minimal macOS Share principal and activation

Use a native `NSViewController` for a custom macOS Share form. The extension
receives `NSExtensionItem` objects via `extensionContext.inputItems`; text and
attachments depend on the sending application.
[Apple Share guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Share.html)

A programmatic experiment can give its Swift class an explicit Objective-C
runtime name, then use that exact name in the plist:

```swift
@objc(ShareViewController)
final class ShareViewController: NSViewController {
    override func loadView() {
        // Construct the research UI and read extensionContext.inputItems.
    }
}
```

```xml
<key>NSExtension</key>
<dict>
  <key>NSExtensionPointIdentifier</key>
  <string>com.apple.share-services</string>
  <key>NSExtensionPrincipalClass</key>
  <string>ShareViewController</string>
  <key>NSExtensionAttributes</key>
  <dict>
    <key>NSExtensionActivationRule</key>
    <dict>
      <key>NSExtensionActivationSupportsText</key><true/>
      <key>NSExtensionActivationSupportsFileWithMaxCount</key><integer>10</integer>
    </dict>
  </dict>
</dict>
```

This is a **candidate configuration**, not runtime evidence. A Swift class
without an explicit `@objc` name may require a module-qualified runtime name;
verify rather than mixing the two conventions. Do not include both
`NSExtensionPrincipalClass` and `NSExtensionMainStoryboard`: Apple says that
combination prevents loading. Apple's key reference explicitly covers macOS
Share, the extension point, principal key, and activation dictionary. Its archived
Share guide's displayed storyboard example is explicitly an iOS example.
[Apple principal-class rule](https://developer.apple.com/documentation/BundleResources/Information-Property-List/NSExtension/NSExtensionPrincipalClass),
[extension plist key reference](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/AppExtensionKeys.html)

For a synthetic native host, enumerate
`NSSharingService.sharingServices(forItems:)`, identify the returned research
service, check `canPerform(withItems:)`, and invoke `perform(withItems:)` while
running the AppKit event loop. This tests OS extension dispatch and payload
handling. It does not establish Safari/reader selection behavior. A service
initializer accepting an arbitrary string is not documentation that a third-party
extension bundle ID is a valid service name; enumeration avoids that assumption.
[Apple sharing-service enumeration](https://developer.apple.com/documentation/appkit/nssharingservice/sharingservices(foritems:)),
[perform sharing](https://developer.apple.com/documentation/appkit/nssharingservice/perform(withitems:))

## Decisive evidence to record separately

1. Compiler/SDK/architecture, framework compile and Swift link result, extension
   safety diagnostics, nested signatures and actual entitlements.
2. Extension registration, user enabling, real process invocation, exact Unicode
   payload and original-file bytes/hash; distinguish synthetic AppKit host from
   named real source applications.
3. App-group URL plus real cross-process write/read. Keep extension-private
   storage evidence separate if group authorization fails.
4. Original-file durable ownership before completion, process termination and
   reopening, concurrent access, and queue recovery through the same shared core.

No compiler success, registration listing, synthetic send, or private-container
save alone proves the complete native Share/shared queue/delivery contract.
