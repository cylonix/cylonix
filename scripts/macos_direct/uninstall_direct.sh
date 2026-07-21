#!/bin/zsh
# Copyright (c) EZBLOCK Inc & AUTHORS
# SPDX-License-Identifier: BSD-3-Clause

# Uninstall the direct-distribution flavor (app, daemon, notifier,
# CLI symlink, pkg receipt) so another flavor — e.g. the network
# extension build — can be installed and tested without interference.
#
# Usage: uninstall_direct.sh [services|app|all] [--purge-state]
#
#   services  Stop and remove the background service, notifier, CLI symlink
#             and installer receipt, then print a human-readable status. Also
#             sweeps orphaned duplicate installs from
#             /Applications/Cylonix*.localized (they break the Share menu).
#             Does NOT delete the app bundle or quit the running app.
#   app       Delete /Applications/Cylonix.app and terminate the running app —
#             only when the bundle there is actually the direct flavor; a
#             network-extension build occupying the path is left alone.
#   all       services followed by app (default; used for standalone CLI use).
#
# The in-app "Uninstall" button runs `services` first so it can show what was
# removed, then `app` after the user confirms deletion. Node state in
# /var/lib/cylonix is preserved unless --purge-state is given.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "error: run with sudo: sudo $0 [services|app|all] [--purge-state]" >&2
  exit 1
fi

MODE="all"
PURGE_STATE=0
NO_KILL=0
for arg in "$@"; do
  case "$arg" in
    --purge-state) PURGE_STATE=1 ;;
    --no-kill) NO_KILL=1 ;;
    services|app|all) MODE="$arg" ;;
    *) echo "error: unknown argument: $arg" >&2; exit 2 ;;
  esac
done

PLIST_NAME="io.cylonix.sase.direct.daemon"
PLIST_DST="/Library/LaunchDaemons/$PLIST_NAME.plist"
NOTIFIER_PLIST_NAME="io.cylonix.sase.direct.notifier"
NOTIFIER_PLIST_DST="/Library/LaunchAgents/$NOTIFIER_PLIST_NAME.plist"
APP_PATH="/Applications/Cylonix.app"
DIRECT_BUNDLE_ID="io.cylonix.sase.direct"
PKG_ID="io.cylonix.sase.direct.installer"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

# ---------------------------------------------------------------------------
# Flavor/orphan hygiene (keep in sync across pkg/preinstall, pkg/postinstall
# and uninstall_direct.sh). Installing the direct PKG while the
# network-extension flavor (io.cylonix.sase) occupied /Applications/Cylonix.app
# made Installer dodge the destination (BundleHasStrictIdentifier) into
# "/Applications/Cylonix*.localized/Cylonix.app". Each orphan keeps a second
# share extension registered under the same visible name "Cylonix"; ShareKit
# then launches one extension but connects to the other's service name
# (NSCocoaError 4099) and the share sheet silently never appears.
# ---------------------------------------------------------------------------
cylonix_bundle_id() {
  /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' \
    "$1/Contents/Info.plist" 2>/dev/null || true
}

# Unregister one Cylonix app bundle (pluginkit's DB is per-user — run it as
# the GUI user) and delete it.
remove_cylonix_bundle() {
  local app="$1" gui_user
  gui_user="$(stat -f '%Su' /dev/console 2>/dev/null || true)"
  if [[ -n "${gui_user:-}" && "$gui_user" != "root" && "$gui_user" != "_"* \
        && -d "$app/Contents/PlugIns/ShareExtension.appex" ]]; then
    sudo -u "$gui_user" pluginkit -r \
      "$app/Contents/PlugIns/ShareExtension.appex" 2>/dev/null || true
  fi
  "$LSREGISTER" -u "$app" 2>/dev/null || true
  rm -rf "$app"
}

# Delete every orphaned Cylonix flavor under /Applications/Cylonix*.localized.
# Returns 0 if anything was removed (caller then restarts Finder so ShareKit
# drops the poisoned service identity it may have cached from an orphan).
remove_cylonix_orphans() {
  local removed=1 dir app id
  for dir in /Applications/Cylonix*.localized(N); do
    app="$dir/Cylonix.app"
    id="$(cylonix_bundle_id "$app")"
    if [[ ! -d "$app" || -z "$id" || "$id" == io.cylonix.sase* ]]; then
      if [[ -d "$app" ]]; then
        remove_cylonix_bundle "$app"
      fi
      rm -rf "$dir"
      removed=0
    fi
  done
  return $removed
}

# Restart the GUI user's Finder so ShareKit drops its cached share-service
# identities. A plain `killall Finder` is silently ineffective from the
# PackageKit script sandbox (the signal never lands and stderr is
# discarded), so go through launchd — kickstart -k restarts the
# com.apple.Finder agent — keeping killall as a fallback for contexts
# without a GUI session.
bounce_finder() {
  local gui_user gui_uid
  gui_user="$(stat -f '%Su' /dev/console 2>/dev/null || true)"
  if [[ -n "${gui_user:-}" && "$gui_user" != "root" && "$gui_user" != "_"* ]]; then
    gui_uid="$(id -u "$gui_user" 2>/dev/null || true)"
    if [[ -n "${gui_uid:-}" ]] \
        && launchctl kickstart -k "gui/${gui_uid}/com.apple.Finder" 2>/dev/null; then
      return 0
    fi
  fi
  killall Finder 2>/dev/null || true
}

do_services() {
  # Boot out the notifier LaunchAgent from the active GUI session, then
  # remove its plist.
  local gui_user gui_uid
  gui_user="$(stat -f '%Su' /dev/console 2>/dev/null || true)"
  if [[ -n "${gui_user:-}" && "$gui_user" != "root" && "$gui_user" != "_"* ]]; then
    gui_uid="$(id -u "$gui_user" 2>/dev/null || true)"
    if [[ -n "${gui_uid:-}" ]]; then
      launchctl bootout "gui/$gui_uid/$NOTIFIER_PLIST_NAME" 2>/dev/null || true
    fi
  fi
  rm -f "$NOTIFIER_PLIST_DST"
  echo "• Notifier agent: removed"

  # Stop and remove the background daemon. bootout is asynchronous for a
  # KeepAlive job, so WAIT for launchd to actually drop the label before removing
  # the plist. Deleting the plist while the label is still registered leaves
  # launchd with a dangling job that makes the NEXT install's bootstrap fail with
  # EIO ("already loaded") — the uninstall→reinstall daemon-won't-start bug.
  launchctl bootout "system/$PLIST_NAME" 2>/dev/null || true
  i=0; while launchctl print "system/$PLIST_NAME" >/dev/null 2>&1 && [ "$i" -lt 100 ]; do
    i=$((i + 1)); sleep 0.1
  done
  rm -f "$PLIST_DST"
  echo "• Background service (cylonixd): stopped and removed"

  # Unregister the share extension and the app from LaunchServices (quiet) —
  # but only when the canonical path holds the direct flavor (or nothing).
  # When the network-extension flavor owns it, its registrations must
  # survive this uninstall.
  local app_id need_finder_restart=0
  app_id="$(cylonix_bundle_id "$APP_PATH")"
  if [[ ! -d "$APP_PATH" || -z "$app_id" || "$app_id" == "$DIRECT_BUNDLE_ID" ]]; then
    if [[ -n "${gui_user:-}" && -d "$APP_PATH/Contents/PlugIns/ShareExtension.appex" ]]; then
      sudo -u "$gui_user" pluginkit -r \
        "$APP_PATH/Contents/PlugIns/ShareExtension.appex" >/dev/null 2>&1 || true
    fi
    "$LSREGISTER" -u "$APP_PATH" >/dev/null 2>&1 || true
    echo "• Share extension: unregistered"
    # Finder's ShareKit caches the share-service identity in-process. Having
    # just unregistered io.cylonix.sase.direct.share-extension, a still-running
    # Finder keeps that dead identity cached and maps a later "Cylonix" menu
    # pick (e.g. after the network-extension app is installed at the same path)
    # to it, so the sheet never launches. Always bounce Finder here so the
    # cache is dropped, not only when an orphan was swept below.
    need_finder_restart=1
  else
    echo "• Share extension: left registered ($app_id owns $APP_PATH)"
  fi

  # Orphaned duplicate installs poison the Share menu (see hygiene note at
  # the top); always sweep them, and bounce Finder so ShareKit re-resolves.
  if remove_cylonix_orphans; then
    need_finder_restart=1
    echo "• Orphaned duplicate installs (Cylonix*.localized): removed"
  fi
  if [[ $need_finder_restart -eq 1 ]]; then
    bounce_finder
  fi

  # Command-line tool symlink and installer receipt.
  rm -f /usr/local/bin/cylonix
  echo "• Command-line tool (cylonix): removed"
  pkgutil --forget "$PKG_ID" >/dev/null 2>&1 || true
  echo "• Installer receipt: forgotten"

  # Runtime socket dir is always safe to remove.
  rm -rf /var/run/cylonix

  if [[ $PURGE_STATE -eq 1 ]]; then
    rm -rf /var/lib/cylonix /var/log/cylonix
    echo "• Node state: erased"
  else
    echo "• Node state: preserved (reinstall keeps this device's identity)"
  fi

  # Legacy leftovers from the pre-"direct" install layout.
  if [[ -f /Library/LaunchDaemons/io.cylonix.daemon.plist ]]; then
    launchctl bootout system/io.cylonix.daemon 2>/dev/null || true
    rm -f /Library/LaunchDaemons/io.cylonix.daemon.plist
    rm -rf /Library/Services/cylonixd
    echo "• Legacy daemon (io.cylonix.daemon): removed"
  fi
}

do_app() {
  # Delete the app bundle and terminate the running app. Removing the bundle
  # of a running app is allowed on macOS; the process keeps its mapped image
  # until it is killed on the next line. Never delete a different flavor
  # occupying the canonical path (e.g. the network-extension build installed
  # over the direct one) — that app is not ours to remove or to quit.
  local app_id
  app_id="$(cylonix_bundle_id "$APP_PATH")"
  if [[ ! -d "$APP_PATH" ]]; then
    echo "• Application: already absent"
  elif [[ -n "$app_id" && "$app_id" != "$DIRECT_BUNDLE_ID" ]]; then
    echo "• Application: left in place ($APP_PATH is $app_id, not $DIRECT_BUNDLE_ID)"
  else
    rm -rf "$APP_PATH"
    # --no-kill: leave the running app alive so the caller can show the result
    # first, then quit itself. The app keeps its mapped image until it exits.
    if [[ $NO_KILL -ne 1 ]]; then
      killall Cylonix 2>/dev/null || true
      killall "cylonix-direct" 2>/dev/null || true
    fi
    echo "• Application: deleted"
  fi
}

case "$MODE" in
  services) do_services ;;
  app)      do_app ;;
  all)      do_services; do_app ;;
esac
