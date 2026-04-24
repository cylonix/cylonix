#!/bin/zsh
# Copyright (c) EZBLOCK Inc & AUTHORS
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PROJECT_DIR="$ROOT_DIR/macos-direct"
WORKSPACE_PATH="$PROJECT_DIR/Runner.xcworkspace"
SCHEME="Runner"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/cylonix-direct-derived}"
ARCHIVE_PATH="${ARCHIVE_PATH:-/tmp/cylonix-direct.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-/tmp/cylonix-direct-export}"
DMG_STAGING_DIR="${DMG_STAGING_DIR:-/tmp/cylonix-direct-dmg}"
DMG_PATH="${DMG_PATH:-/tmp/Cylonix.dmg}"
PKG_STAGING_DIR="${PKG_STAGING_DIR:-/tmp/cylonix-direct-pkg}"
PKG_PATH="${PKG_PATH:-/tmp/Cylonix.pkg}"
PKG_SCRIPTS_DIR="$ROOT_DIR/scripts/macos_direct/pkg"
PKG_IDENTIFIER="io.cylonix.sase.direct.installer"
TUN_MODE="${TUN_MODE:-utun}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-$PROJECT_DIR/ExportOption.plist}"
APP_NAME="${APP_NAME:-Cylonix.app}"
NOTARY_PROFILE="${NOTARY_PROFILE:-${APPLE_NOTARY_PROFILE:-}}"
SIGNING_CONFIG="${SIGNING_CONFIG:-$PROJECT_DIR/Runner/Configs/Signing.xcconfig}"

step="${1:-all}"

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required tool: $1" >&2
    exit 1
  fi
}

require_signing_values() {
  if [[ ! -f "$SIGNING_CONFIG" ]]; then
    echo "missing signing config: $SIGNING_CONFIG" >&2
    exit 1
  fi

  local missing=0
  for key in DIRECT_APP_PROFILE_SPECIFIER DIRECT_SHARE_EXTENSION_PROFILE_SPECIFIER; do
    local value
    value="$(awk -F' *= *' -v key="$key" '$1 == key {print $2}' "$SIGNING_CONFIG" | tail -n 1)"
    if [[ -z "${value// }" ]]; then
      echo "signing config is missing $key in $SIGNING_CONFIG" >&2
      missing=1
    fi
  done

  if [[ "$missing" -ne 0 ]]; then
    exit 1
  fi
}

build_daemon() {
  echo "==> Building cylonixd daemon (universal)..."
  cd "$ROOT_DIR/tailscale"
  GOOS=darwin GOARCH=arm64 ./build_dist.sh tailscale.com/cmd/tailscaled
  mv tailscaled tailscaled-arm64
  GOOS=darwin GOARCH=amd64 ./build_dist.sh tailscale.com/cmd/tailscaled
  mv tailscaled tailscaled-amd64
  lipo -create -output tailscaled tailscaled-arm64 tailscaled-amd64
  rm tailscaled-arm64 tailscaled-amd64

  echo "==> Building cylonix CLI (universal)..."
  GOOS=darwin GOARCH=arm64 ./build_dist.sh tailscale.com/cmd/tailscale
  mv tailscale tailscale-arm64
  GOOS=darwin GOARCH=amd64 ./build_dist.sh tailscale.com/cmd/tailscale
  mv tailscale tailscale-amd64
  lipo -create -output tailscale tailscale-arm64 tailscale-amd64
  rm tailscale-arm64 tailscale-amd64
  cd "$ROOT_DIR"
}

prepare_flutter() {
  echo "==> Preparing Flutter ephemeral files for macos-direct..."
  cd "$ROOT_DIR"

  # Run flutter build to generate ephemeral files (xcconfig, podspec, etc.)
  flutter build macos --release --dart-define=DISTRIBUTION_MODE=direct

  # Unregister the build directory app so LaunchServices doesn't prefer it
  local lsregister="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
  "$lsregister" -u "$ROOT_DIR/build/macos/Build/Products/Release/cylonix.app" 2>/dev/null || true

  # Copy ephemeral directory to macos-direct
  local src="$ROOT_DIR/macos/Flutter/ephemeral"
  local dst="$PROJECT_DIR/Flutter/ephemeral"
  rm -rf "$dst"
  cp -R "$src" "$dst"

  # Ensure DISTRIBUTION_MODE=direct is in DART_DEFINES in the copied xcconfig
  local define_b64
  define_b64="$(echo -n 'DISTRIBUTION_MODE=direct' | base64)"
  local xcconfig="$dst/Flutter-Generated.xcconfig"
  if ! grep -q "$define_b64" "$xcconfig"; then
    if grep -q "^DART_DEFINES=" "$xcconfig"; then
      sed -i '' "s/^DART_DEFINES=\(.*\)/DART_DEFINES=\1,${define_b64}/" "$xcconfig"
    else
      echo "DART_DEFINES=${define_b64}" >> "$xcconfig"
    fi
  fi

  # Run pod install for macos-direct
  echo "==> Running pod install for macos-direct..."
  cd "$PROJECT_DIR"
  pod install
  cd "$ROOT_DIR"

  echo "==> Flutter ephemeral files prepared."
}

build_archive() {
  require_tool xcodebuild
  require_signing_values
  rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
  mkdir -p "$DERIVED_DATA_PATH"

  xcodebuild \
    -workspace "$WORKSPACE_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -archivePath "$ARCHIVE_PATH" \
    archive

  # Bundle cylonixd and cylonix CLI into the archived app
  local app_resources="$ARCHIVE_PATH/Products/Applications/$APP_NAME/Contents/Resources"
  echo "==> Bundling cylonixd into archive..."
  cp "$ROOT_DIR/tailscale/tailscaled" "$app_resources/cylonixd"
  cp "$ROOT_DIR/tailscale/tailscale" "$app_resources/cylonix"
  chmod 755 "$app_resources/cylonixd" "$app_resources/cylonix"

  # Note: downloadsfolder.framework must stay — the Runner binary is dynamically
  # linked against it, so removing it causes a dyld crash at launch.

  # Sign the daemon binaries with the same identity
  local signing_identity="Developer ID Application"
  echo "==> Signing daemon binaries..."
  codesign --force --options runtime --sign "$signing_identity" "$app_resources/cylonixd"
  codesign --force --options runtime --sign "$signing_identity" "$app_resources/cylonix"

  # Re-sign the app bundle (without --deep to preserve extension entitlements)
  echo "==> Re-signing app bundle..."
  local app_bundle="$ARCHIVE_PATH/Products/Applications/$APP_NAME"
  local share_ext="$app_bundle/Contents/PlugIns/ShareExtension.appex"
  local share_entitlements="$PROJECT_DIR/ShareExtension/ShareExtensionRelease.entitlements"

  # Re-sign the share extension with its entitlements (it was already signed by Xcode,
  # but re-sign to ensure consistency after we modified the bundle)
  if [[ -d "$share_ext" ]]; then
    echo "==> Re-signing share extension with entitlements..."
    codesign --force --options runtime --sign "$signing_identity" \
      --entitlements "$share_entitlements" "$share_ext"
  fi

  # Re-sign the main app bundle with its entitlements (not deep — only the top-level signature)
  local app_entitlements="$PROJECT_DIR/Runner/Release.entitlements"
  codesign --force --options runtime --sign "$signing_identity" \
    --entitlements "$app_entitlements" "$app_bundle"

  # Unregister the intermediate build app from LaunchServices so its share
  # extension doesn't appear alongside the real installed app's extension.
  local lsregister="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
  "$lsregister" -u "$DERIVED_DATA_PATH/Build/Intermediates.noindex/ArchiveIntermediates/Runner/InstallationBuildProductsLocation/Applications/$APP_NAME" 2>/dev/null || true
}

export_archive() {
  require_tool xcodebuild
  xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"
}

build_dmg() {
  require_tool hdiutil
  local app_path="$EXPORT_PATH/$APP_NAME"
  if [[ ! -d "$app_path" ]]; then
    echo "expected exported app at $app_path" >&2
    exit 1
  fi

  rm -rf "$DMG_STAGING_DIR" "$DMG_PATH"
  mkdir -p "$DMG_STAGING_DIR"
  cp -R "$app_path" "$DMG_STAGING_DIR/"
  ln -s /Applications "$DMG_STAGING_DIR/Applications"

  hdiutil create \
    -volname "Cylonix Direct" \
    -srcfolder "$DMG_STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"
}

build_pkg() {
  require_tool pkgbuild
  require_tool productbuild
  local app_path="$EXPORT_PATH/$APP_NAME"
  if [[ ! -d "$app_path" ]]; then
    echo "expected exported app at $app_path" >&2
    exit 1
  fi

  rm -rf "$PKG_STAGING_DIR" "$PKG_PATH"
  mkdir -p "$PKG_STAGING_DIR/payload/Applications"
  mkdir -p "$PKG_STAGING_DIR/scripts"

  # Copy app to payload
  cp -R "$app_path" "$PKG_STAGING_DIR/payload/Applications/"

  # Prepare pkg scripts with the configured TUN_MODE
  cp "$PKG_SCRIPTS_DIR/preinstall" "$PKG_STAGING_DIR/scripts/"
  sed "s|<string>utun</string>|<string>$TUN_MODE</string>|" \
    "$PKG_SCRIPTS_DIR/postinstall" > "$PKG_STAGING_DIR/scripts/postinstall"
  chmod +x "$PKG_STAGING_DIR/scripts/preinstall" "$PKG_STAGING_DIR/scripts/postinstall"

  # Read version from the app's Info.plist
  local app_version
  app_version="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
    "$app_path/Contents/Info.plist" 2>/dev/null || echo "1.0.0")"

  # Build component package with relocation disabled
  echo "==> Building component package..."
  pkgbuild \
    --root "$PKG_STAGING_DIR/payload" \
    --component-plist "$PKG_SCRIPTS_DIR/component.plist" \
    --scripts "$PKG_STAGING_DIR/scripts" \
    --identifier "$PKG_IDENTIFIER" \
    --version "$app_version" \
    --install-location "/" \
    "$PKG_STAGING_DIR/component.pkg"

  # Build distribution XML for a nicer installer UI
  # Prepare resources directory for installer
  local pkg_resources="$PKG_STAGING_DIR/resources"
  mkdir -p "$pkg_resources"
  cp "$PKG_SCRIPTS_DIR/background.png" "$pkg_resources/background.png"

  local installer_title="Cylonix"
  if [[ "$TUN_MODE" == "userspace-networking" ]]; then
    installer_title="Cylonix Mesh"
    cat > "$pkg_resources/welcome.html" <<'WELCOMEHTML'
<!DOCTYPE html>
<html>
<head>
<style>
body {
    font-family: -apple-system, Helvetica Neue, sans-serif;
    margin: 24px;
    margin-top: 24px;
}
h1 { font-size: 20px; font-weight: 600; margin: 0 0 16px 0; text-align: center; }
p { font-size: 13px; line-height: 1.6; }
</style>
</head>
<body>
<h1>Cylonix Mesh</h1>
<p>This installer will install Cylonix in <b>Mesh Mode</b> and set up the background daemon.</p>
<p>Mesh Mode provides direct peer-to-peer connectivity without creating a system tunnel device. This avoids conflicts with other VPN software.</p>
<p>Mesh Mode does not support exit nodes or subnet routing. MagicDNS and peer-to-peer connections work normally.</p>
</body>
</html>
WELCOMEHTML
  else
    cp "$PKG_SCRIPTS_DIR/welcome.html" "$pkg_resources/welcome.html"
  fi

  cat > "$PKG_STAGING_DIR/distribution.xml" <<DISTXML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>$installer_title</title>
    <background file="background.png" alignment="bottomleft" scaling="none" mime-type="image/png"/>
    <background-darkAqua file="background.png" alignment="bottomleft" scaling="none" mime-type="image/png"/>
    <welcome file="welcome.html" mime-type="text/html"/>
    <options customize="never" require-scripts="false" hostArchitectures="arm64"/>
    <domains enable_anywhere="false" enable_currentUserHome="false" enable_localSystem="true"/>
    <choices-outline>
        <line choice="default">
            <line choice="io.cylonix.sase.direct.installer"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="io.cylonix.sase.direct.installer" visible="false">
        <pkg-ref id="io.cylonix.sase.direct.installer"/>
    </choice>
    <pkg-ref id="io.cylonix.sase.direct.installer" version="$app_version" onConclusion="none">component.pkg</pkg-ref>
</installer-gui-script>
DISTXML

  # Build signed product archive
  echo "==> Building signed installer package..."
  productbuild \
    --distribution "$PKG_STAGING_DIR/distribution.xml" \
    --package-path "$PKG_STAGING_DIR" \
    --resources "$PKG_STAGING_DIR/resources" \
    --sign "Developer ID Installer" \
    "$PKG_PATH"

  # Set Cylonix icon on the .pkg file in Finder
  echo "==> Setting package icon..."
  local app_icns="$EXPORT_PATH/$APP_NAME/Contents/Resources/AppIcon.icns"
  if [[ -f "$app_icns" ]]; then
    osascript -e "
      use framework \"AppKit\"
      set iconImage to current application's NSImage's alloc()'s initWithContentsOfFile:\"$app_icns\"
      set ws to current application's NSWorkspace's sharedWorkspace()
      ws's setIcon:iconImage forFile:\"$PKG_PATH\" options:0
    " 2>/dev/null || true
  fi

  echo "==> Package built: $PKG_PATH"
}

notarize() {
  require_tool xcrun
  if [[ -z "$NOTARY_PROFILE" ]]; then
    echo "set NOTARY_PROFILE or APPLE_NOTARY_PROFILE before notarizing" >&2
    exit 1
  fi

  local target="${1:-pkg}"
  case "$target" in
    dmg)
      xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
      xcrun stapler staple "$EXPORT_PATH/$APP_NAME"
      xcrun stapler staple "$DMG_PATH"
      ;;
    pkg)
      xcrun notarytool submit "$PKG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
      xcrun stapler staple "$PKG_PATH"
      ;;
    *)
      echo "usage: notarize [dmg|pkg]" >&2
      exit 1
      ;;
  esac
}

verify_distribution() {
  require_tool codesign
  require_tool spctl
  codesign --verify --deep --strict "$EXPORT_PATH/$APP_NAME"
  spctl --assess --type execute "$EXPORT_PATH/$APP_NAME"
}

case "$step" in
  daemon)
    build_daemon
    ;;
  flutter)
    prepare_flutter
    ;;
  archive)
    build_archive
    ;;
  export)
    export_archive
    ;;
  dmg)
    build_dmg
    ;;
  pkg)
    build_pkg
    ;;
  notarize)
    notarize "${2:-pkg}"
    ;;
  verify)
    verify_distribution
    ;;
  mesh-pkg)
    TUN_MODE="userspace-networking"
    PKG_PATH="${PKG_PATH%.pkg}-Mesh.pkg"
    build_pkg
    ;;
  all)
    build_daemon
    prepare_flutter
    build_archive
    export_archive
    build_pkg
    notarize pkg
    verify_distribution
    ;;
  *)
    echo "usage: $0 [daemon|flutter|archive|export|dmg|pkg|mesh-pkg|notarize|verify|all]" >&2
    exit 1
    ;;
esac
