# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cylonix is a cross-platform Flutter client app for the Cylonix SASE (Secure Access Service Edge) service, built on a modified Tailscale/WireGuard mesh VPN. It targets iOS, macOS, Android, Linux, Windows, and Web.

## Build Commands

### Initial Setup
```bash
git submodule update --init --recursive
make config        # creates .env.local and generates local config
```

### Code Generation (run after changing model files)
```bash
make models        # runs: dart run build_runner build --delete-conflicting-outputs
```

### Development Run
```bash
make macos         # flutter run for macOS
make linux         # flutter run for Linux
make ios           # flutter run for iOS device
make android       # flutter run for Android device
make chrome        # flutter run for web (Chrome)
make windows       # flutter run for Windows
```

### Package Builds
```bash
make apk           # Android APK (arm64, split-ABI)
make aab           # Android App Bundle
make deb           # Debian package (Linux)
# macOS/iOS: use Xcode with ios/Runner.xcworkspace or macos/Runner.xcworkspace
# Windows: make windows_cylonixd (in WSL), then make build_windows + make pack_windows (in PowerShell)
```

### Lint and Tests
```bash
flutter analyze    # static analysis
flutter test       # run all tests
flutter test test/widget_test.dart  # run a single test file
```

### Android AAR Dependencies
```bash
make ipn_aar       # build tailscale Android AARs from submodule
make copy_ipn_aar  # copy pre-built AARs to android/app/libs/
```

## Architecture

### Flutter Layer (`lib/`)

State management uses **Riverpod** throughout. The core data flow is:

1. **`IpnService`** (`lib/services/ipn.dart`) — singleton that owns the `MethodChannel('io.cylonix.sase/wg')` connection to the native backend. Exposes a `notificationStream` of `IpnNotification` events and calls LocalAPI endpoints on desktop/Android via HTTP over Unix socket (`local-tailscaled.sock`).

2. **`IpnStateNotifier`** (`lib/viewmodels/ipn_state_notifier.dart`) — `StateNotifier<AsyncValue<IpnState>>` that subscribes to `IpnService.notificationStream` and processes notifications into the app's unified `IpnState`. On Apple platforms, waits for VPN permission before initializing.

3. **Providers** (`lib/providers/ipn.dart`) — Riverpod providers that derive slices of `IpnState` (peers, prefs, netmap, health, etc.) for widgets to consume.

4. **Models** (`lib/models/ipn.dart`) — Core data types (`IpnState`, `Node`, `NetworkMap`, `IpnPrefs`, etc.) defined with `freezed` for immutability. Generated files are `ipn.freezed.dart` and `ipn.g.dart` — never edit these manually.

5. **Views/Widgets** — `App` (`lib/app.dart`) sets up routing; `HomePage` is the shell; platform-adaptive UI (Cupertino on Apple, Material elsewhere).

### Native Backends

- **iOS/macOS**: Swift `AppDelegate` (`ios/Runner/AppDelegate.swift`, shared via `apple/Sources/`) implements `FlutterMethodChannel`. Uses the `wireguard-apple` submodule (WireGuard network extension) and communicates via `TunnelsManager`.

- **Android**: Kotlin `MainActivity` (`android/app/src/main/kotlin/io/cylonix/sase/`) implements the method channel. The VPN engine comes from the `tailscale-android` submodule, compiled into `ipn_app.aar` / `libtailscale.aar` and copied to `android/app/libs/`.

- **Linux/Windows**: The `tailscale` submodule (Go) provides `tailscaled`/`cylonixd` as a local daemon; Flutter communicates via HTTP LocalAPI.

### Key Submodules

- `tailscale/` — Modified Tailscale Go backend (control client, DERP, WireGuard, LocalAPI)
- `tailscale-android/` — Android AAR packaging of the Go backend via gomobile
- `wireguard-apple/` — WireGuard Swift/Go library for iOS/macOS network extension

### Configuration

- `.env.local` — local environment overrides (gitignored, created by `make config`)
- `scripts/config.defaults.sh` — default values for `APP_NAME`, `OFFICIAL_WEBSITE`, `CONTACT_EMAIL`
- `lib/assets/config.template.yaml` — config template expanded from env vars

### Tailscale Submodule Modification Markers

When modifying files inside the `tailscale/` submodule, mark every Cylonix change so it is easy to identify during upstream merges. The rule depends on whether the file was created by Cylonix:

- **Cylonix-owned files** (copyright header says `EZBLOCK Inc`): no markers needed.
- **Upstream Tailscale files**: apply the following markers —

| Situation | Marker |
|---|---|
| Block of added lines | `// __BEGIN_CYLONIX_ADD__` … `// __END_CYLONIX_ADD__` |
| Block of modified lines | `// __BEGIN_CYLONIX_MOD__` … `// __END_CYLONIX_MOD__` |
| Single added line | `// __CYLONIX_ADD__` (end of line) |
| Single modified line | `// __CYLONIX_MOD__` (end of line) |

### Code Generation Pattern

Models using `freezed` follow this pattern:
```dart
part 'foo.freezed.dart';  // immutable data class generated code
part 'foo.g.dart';        // JSON serialization generated code
```
Always run `make models` after modifying any file with `@freezed` annotations.
