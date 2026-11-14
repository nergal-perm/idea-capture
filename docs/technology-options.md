# Shared-core technology options

Research for [issue #10](https://github.com/nergal-perm/idea-capture/issues/10),
2026-11-14. These are candidate integration paths and engineering assessments,
not owner-approved stack choices or tested target-device results. Accepted
constraints are recorded in [technology boundaries](technology-boundaries.md).

This comparison is historical. The owner subsequently selected Kotlin/KMP,
ordinary JVM desktop/backend, Ktor, Compose and SQLite in the
[resolution of #10](https://github.com/nergal-perm/idea-capture/issues/10#issuecomment-6883781978).
The alternatives below are retained as comparison context, not current open
stack choices.

## Candidate paths

| Language family | Shared executable core and client integration | Backend path | Main questions |
| --- | --- | --- | --- |
| Kotlin Multiplatform | Android Kotlin directly; macOS Kotlin/Native framework called from Swift; Linux helper using shared module | Kotlin/Ktor | Cross-target dependency support, Apple bridge, Linux JVM versus Native packaging |
| Rust | Rust library with generated Kotlin/Swift bindings; Linux helper using the same crates | Rust/axum | FFI, build integration, async lifetimes and platform transport adapters |
| Go | Go packages with Android AAR and macOS Objective-C framework through gomobile; Linux helper | Go net/http | Restricted binding types, runtime integration, mobile lifecycle |
| C++ | C++ library with JNI and Apple bridges; QML integration or Linux helper | C++ HTTP library | Manual bridges, ABI/build complexity, Qt versus platform-specific UI |
| C#/.NET | Shared managed library with .NET for Android and macOS SDK bindings; Linux helper | ASP.NET Core | Packaging, native extension support, runtime lifecycle; MAUI is optional |
| Dart | Shared Dart package, Flutter add-to-app for native hosts; Linux CLI helper | Dart HTTP libraries | Engine embedding, macOS extensions and platform adapters; shared Flutter UI would require a separate UI decision |
| TypeScript | Shared package in React Native clients, macOS out-of-tree port; Node Linux helper | Node HTTP framework | Multiple platform runtimes, native modules and extension integration |
| Erlang/Elixir | Shared BEAM modules; mobile runtime packaging exists through elixir-desktop | Erlang/Elixir HTTP libraries | Embedded BEAM and host bridge, native Share/recording/background lifecycle |
| OCaml | Native core with C interface; Android cross-toolchain; Linux helper and native macOS host integration | OCaml web framework such as Dream | Cross-build dependency matrix, manual JNI/Apple wrappers, runtime ownership |
| Clojure family | ClojureScript with React Native/Node, or ClojureDart with Flutter/Dart; JVM desktop/server is another option | Depends on selected host | Select one coherent host strategy; sharing source across dialects does not make host-specific IO portable |

The table's paths are possibilities, not equivalent levels of integration
evidence. No candidate has yet demonstrated this project's complete capture,
queue, recovery, and delivery contract on the target devices.

## Primary sources

- Kotlin: [shared platform abstractions](https://kotlinlang.org/docs/multiplatform/multiplatform-expect-actual.html),
  [Apple framework interoperability](https://kotlinlang.org/docs/native-objc-interop.html),
  [target support](https://kotlinlang.org/docs/native-target-support.html),
  [Ktor client engines](https://ktor.io/docs/client-engines.html).
- Rust: [UniFFI](https://mozilla.github.io/uniffi-rs/latest/),
  [Android toolchain](https://doc.rust-lang.org/rustc/platform-support/android.html),
  [axum](https://docs.rs/axum/latest/axum/).
- Go: [gomobile](https://pkg.go.dev/golang.org/x/mobile/cmd/gomobile),
  [binding restrictions](https://pkg.go.dev/golang.org/x/mobile/cmd/gobind),
  [HTTP client and server](https://pkg.go.dev/net/http).
- C++: [QML integration](https://doc.qt.io/qt-6/qtqml-cppintegration-overview.html),
  [Android](https://doc.qt.io/qt-6/android.html),
  [macOS](https://doc.qt.io/qt-6/macos.html).
- .NET: [Android](https://learn.microsoft.com/en-us/dotnet/android/),
  [Apple SDK bindings](https://github.com/dotnet/macios),
  [ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/overview?view=aspnetcore-10.0).
- Dart: [Flutter add-to-app, including non-UI shared logic](https://docs.flutter.dev/add-to-app),
  [Dart server options](https://dart.dev/server).
- TypeScript: [React Native macOS](https://microsoft.github.io/react-native-macos/docs/intro).
- BEAM: [elixir-desktop](https://github.com/elixir-desktop/desktop),
  [mobile runtime packaging](https://github.com/elixir-desktop/runtimes).
- OCaml: [Android cross-toolchain](https://github.com/ocaml-cross/opam-cross-android),
  [C interface and runtime integration](https://ocaml.org/manual/5.4/intfc.html),
  [Dream](https://github.com/camlworks/dream).
- Clojure: [ClojureScript host differences](https://clojurescript.org/about/differences),
  [ClojureDart, including plain Dart CLI support](https://github.com/Tensegritics/ClojureDart).

## Common unresolved boundary

The owner has selected a broad shared client core: models, validation, durable
queue management, states, retry rules and delivery orchestration. Native Share
integration is a primary criterion for comparing the remaining candidates.
OS scheduling, Share payload access, permissions, recording and extension
lifetime remain platform responsibilities for every candidate. Native network
services may also require platform adapters even when the delivery policy is
shared. A shared language does not imply identical client and backend behavior
or a shared database.

Before locking in a candidate with unverified integration, validate a small
path exercising durable save, process restart, a file transfer, a lost
acknowledgement and status recovery. Binding and platform checks must establish
that the same core can actually be called from each required client; later
stage detail remains governed by the progressive-elaboration decision in #12.
