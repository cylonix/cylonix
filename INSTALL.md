# Cylonix Installation Guide

This document explains how to build and run the Cylonix client on all supported platforms using the top-level Makefile.

---

## Prerequisites

- Git  
- Go (version pinned in `tailscale/go.toolchain.rev`)  
- Flutter & Dart SDK  
- Xcode (for iOS/macOS)  
- Android SDK (for Android)  
- NSIS & SignTool (for Windows installer)  
- Docker (optional, for reproducible builds)

---

## Repository Setup

```bash
git clone https://github.com/cylonix/cylonix.git
cd cylonix
make app-icons       # generate launcher icons
make config          # create/update local .env
make models          # build codegen models
```

---

## Versioning

```bash
make subver
```

This prints the computed `SUB_VERSION` (based on git hash, branch, date, dirty flag).

---

## Development Run

```bash
# Desktop
make linux
make chrome
make windows
make macos

# Mobile devices
make android
make ios
make ios-release
```

Each target invokes `flutter run` with `--dart-define=BUILD_SUB_VERSION=${SUB_VERSION}`.

---

## Package Builds

### Android

```bash
make apk         # 64-bit split-ABI APK
make appbundle   # AAB package
```

Internally copies Tailscale AARs into `android/app/libs` before build.

### Debian (Linux)

```bash
make debian
```

- Cleans `build/`  
- `flutter build linux`  
- `make -C tailscale deb`  
- Runs the packaging script in `tools/packaging/linux`

### macOS & iOS

Use Xcode to open `ios/Runner.xcworkspace` and build the appropriate scheme.

### Windows

```bash
make build_windows    # Flutter desktop build
make pack_windows     # Package NSIS installer (64-bit)
make sign_windows     # Code-sign the installer
make install_windows  # Run the installer
```

#### CLI-Only

```bash
make pack_windows_cli   # 64-bit CLI
make pack_win32_cli     # 32-bit CLI
```

---

## Docker-Based Builds

```bash
make docker_deb          # Build Debian packages inside Docker
```

---
