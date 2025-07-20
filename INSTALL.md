# Cylonix Installation Guide

This document explains how to build and run the Cylonix client on all supported platforms using the top-level Makefile.

---

## Prerequisites

- Git
- Go (version pinned in `tailscale/go.toolchain.rev`)
- Flutter & Dart SDK
- Xcode (for iOS/macOS)
- Android SDK (for Android)
- Wix tools & SignTool (for Windows installer)
- Docker (optional, for reproducible builds)

---

## Repository Setup

- Setup before building app

```bash
git clone https://github.com/cylonix/cylonix.git
cd cylonix
git submodule update --init --recursive
make config
```

- For android, please generate your release app signing key first

```bash
# Generate a keystore file
keytool -genkey -v -keystore ~/cylonix.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias cylonix

# Create key.properties file
cat << EOF > android/key.properties
storePassword=<password from previous step>
keyPassword=<password from previous step>
keyAlias=cylonix
storeFile=${HOME}/cylonix.keystore
EOF

# Secure the key.properties file
chmod 600 android/key.properties
```

```text
    Note:
    - Replace `<password>` with the password you entered during keystore generation
    - Keep your keystore file and passwords secure - they're required to publish app updates
    - The keystore file path can be changed but must match in key.properties
```

- To update app icons

```bash
make app-icons       # generate app icons
```

- To update models after changing the model files

```bash
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
make apk   # 64-bit split-ABI APK
make aab   # AAB package
```

Internally copies Tailscale AARs into `android/app/libs` before build.

### Debian (Linux)

```bash
make deb
```

- Cleans `build/`
- `flutter build linux`
- `make -C tailscale deb`
- Runs the packaging script in `tools/packaging/linux`

### macOS & iOS

Use Xcode to open `ios/Runner.xcworkspace` and build the appropriate scheme.

### Windows

On WSL ubuntu terminal side execute the following command to build the local
tailscale backend first.

```bash
make windows_cylonixd
```

Then in the powershell terminal:

```bash
make build_windows    # Flutter desktop build
make pack_windows     # Package installer
```

---
