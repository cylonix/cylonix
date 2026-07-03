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
#             and installer receipt, then print a human-readable status. Does
#             NOT delete the app bundle or quit the running app.
#   app       Delete /Applications/Cylonix.app and terminate the running app.
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
for arg in "$@"; do
  case "$arg" in
    --purge-state) PURGE_STATE=1 ;;
    services|app|all) MODE="$arg" ;;
    *) echo "error: unknown argument: $arg" >&2; exit 2 ;;
  esac
done

PLIST_NAME="io.cylonix.sase.direct.daemon"
PLIST_DST="/Library/LaunchDaemons/$PLIST_NAME.plist"
NOTIFIER_PLIST_NAME="io.cylonix.sase.direct.notifier"
NOTIFIER_PLIST_DST="/Library/LaunchAgents/$NOTIFIER_PLIST_NAME.plist"
APP_PATH="/Applications/Cylonix.app"
PKG_ID="io.cylonix.sase.direct.installer"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

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

  # Unregister the share extension and the app from LaunchServices (quiet).
  if [[ -n "${gui_user:-}" && -d "$APP_PATH/Contents/PlugIns/ShareExtension.appex" ]]; then
    sudo -u "$gui_user" pluginkit -r \
      "$APP_PATH/Contents/PlugIns/ShareExtension.appex" >/dev/null 2>&1 || true
  fi
  "$LSREGISTER" -u "$APP_PATH" >/dev/null 2>&1 || true
  echo "• Share extension: unregistered"

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
  # until it is killed on the next line.
  rm -rf "$APP_PATH"
  killall Cylonix 2>/dev/null || true
  killall "cylonix-direct" 2>/dev/null || true
  echo "• Application: deleted"
}

case "$MODE" in
  services) do_services ;;
  app)      do_app ;;
  all)      do_services; do_app ;;
esac
