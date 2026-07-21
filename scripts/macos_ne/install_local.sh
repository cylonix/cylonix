#!/bin/zsh
# Copyright (c) EZBLOCK Inc & AUTHORS
# SPDX-License-Identifier: BSD-3-Clause

# Install a locally built network-extension (App-Store-style) Cylonix app
# into /Applications and leave LaunchServices, PlugInKit and Finder in a
# consistent state. Encodes the full dev-install routine so the NE flavor
# gets the same hygiene the direct PKG scripts already have:
#
#   1. Unregister the build-directory bundle from LaunchServices; otherwise
#      the network extension keeps loading from the build tree instead of
#      /Applications.
#   2. Re-register the installed bundle and its appexes with lsregister and
#      pluginkit.
#   3. Restart Finder — but only when the Cylonix share-extension identity
#      or path actually changed. ShareKit caches share-service identities
#      in-process with no API to flush them, so after flavor churn a stale
#      Finder share menu silently ignores clicks on Cylonix. Finder restores
#      its windows and desktop on relaunch; the restart is skipped entirely
#      on a same-identity reinstall so routine rebuilds never disturb it.
#
# Usage: install_local.sh [path-to-cylonix.app] [--bounce-finder]
#
#   path-to-cylonix.app  App bundle to install. Defaults to the release
#                        build at build/macos/Build/Products/Release.
#   --bounce-finder      Restart Finder even if the share-extension
#                        registration looks unchanged.
#
# The copy into /Applications uses OpenScope manage_apps when available
# (headless agents cannot pass the App Management TCC prompt); otherwise it
# copies directly, which needs the caller's terminal to hold App Management
# permission.

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h:h}"
DEST="/Applications/Cylonix.app"
STAGE_DIR="/private/tmp/cylonix-staged-apps"
LSREG="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

SRC="${REPO_ROOT}/build/macos/Build/Products/Release/cylonix.app"
BOUNCE_FINDER=0
for arg in "$@"; do
  case "$arg" in
    --bounce-finder) BOUNCE_FINDER=1 ;;
    *) SRC="${arg:A}" ;;
  esac
done

if [[ ! -d "$SRC" ]]; then
  echo "error: app bundle not found at $SRC (build it with 'flutter build macos')" >&2
  exit 1
fi
if ! /usr/bin/plutil -extract CFBundleIdentifier raw \
    "$SRC/Contents/Info.plist" 2>/dev/null | grep -qx "io.cylonix.sase"; then
  echo "error: $SRC is not the network-extension flavor (io.cylonix.sase)" >&2
  exit 1
fi

# The set of Cylonix share-extension identities before the install decides
# the Finder restart below. Identities only: ShareKit's in-process cache is
# keyed on the extension identity, while paths are resolved by pkd at launch
# (and flap harmlessly between the build dir and /Applications on every
# rebuild). UUIDs change on each re-registration; the election marker
# (+/-/!) would shift awk's fields — exclude both.
share_state() {
  pluginkit -m -v 2>/dev/null | grep -i "cylonix" | grep -i "share" \
    | sed -E 's/^[[:space:]!+-]+//' | awk '{print $1}' | sort -u
}
PRE_SHARE_STATE="$(share_state || true)"

echo "==> Staging ${SRC} ..."
mkdir -p "$STAGE_DIR"
rm -rf "${STAGE_DIR}/cylonix.app"
ditto "$SRC" "${STAGE_DIR}/cylonix.app"

echo "==> Installing to ${DEST} ..."
if command -v openscope >/dev/null 2>&1; then
  openscope system manage_apps --agent "${OPENSCOPE_AGENT:-claude-code}" \
    --op install --name Cylonix --source "${STAGE_DIR}/cylonix.app" >/dev/null
else
  rm -rf "$DEST"
  ditto "${STAGE_DIR}/cylonix.app" "$DEST"
fi
rm -rf "${STAGE_DIR}/cylonix.app"

echo "==> Fixing LaunchServices/PlugInKit registration ..."
"$LSREG" -u "$SRC" >/dev/null 2>&1 || true

# Replacing the bundle makes pkd tear the old registrations down
# asynchronously, which can race a register-then-verify sequence — retry
# until the network extension resolves to the installed path.
NE_PATH=""
for attempt in {1..5}; do
  "$LSREG" -f "$DEST" >/dev/null 2>&1
  for appex in "$DEST"/Contents/PlugIns/*.appex(N); do
    pluginkit -a "$appex" >/dev/null 2>&1 || true
  done
  NE_PATH="$(pluginkit -m -i io.cylonix.sase.network-extension -vvv 2>/dev/null \
    | sed -n 's/.*Path = //p' | head -1)"
  [[ "$NE_PATH" == "$DEST"* ]] && break
  sleep 1
done
if [[ "$NE_PATH" != "$DEST"* ]]; then
  echo "error: network extension resolves to '${NE_PATH:-<none>}', not ${DEST}" >&2
  exit 1
fi
echo "    network extension: ${NE_PATH}"

POST_SHARE_STATE="$(share_state || true)"
if [[ "$PRE_SHARE_STATE" != "$POST_SHARE_STATE" || $BOUNCE_FINDER -eq 1 ]]; then
  echo "==> Share-extension registration changed; restarting Finder ..."
  killall Finder 2>/dev/null || true
else
  echo "==> Share-extension registration unchanged; leaving Finder alone."
fi

echo "==> Installed. Launch the app to (re)create the VPN configuration."
