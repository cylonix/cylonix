#!/bin/zsh
# Copyright (c) EZBLOCK Inc & AUTHORS
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

PLIST_NAME="io.cylonix.sase.direct.daemon"
PLIST_SRC="$(cd "$(dirname "$0")" && pwd)/$PLIST_NAME.plist"
PLIST_DST="/Library/LaunchDaemons/$PLIST_NAME.plist"
APP_PATH="/Applications/Cylonix.app"
DAEMON_PATH="$APP_PATH/Contents/Resources/cylonixd"

action="${1:-install}"

install_daemon() {
  if [[ ! -f "$DAEMON_PATH" ]]; then
    echo "error: cylonixd not found at $DAEMON_PATH" >&2
    echo "install the app to /Applications first." >&2
    exit 1
  fi

  # Create required directories
  sudo mkdir -p /var/lib/cylonix
  sudo mkdir -p /var/run/cylonix
  sudo mkdir -p /var/log/cylonix

  # Stop existing daemon if running
  if sudo launchctl list "$PLIST_NAME" &>/dev/null; then
    echo "stopping existing daemon..."
    sudo launchctl unload "$PLIST_DST" 2>/dev/null || true
  fi

  # Install plist
  sudo cp "$PLIST_SRC" "$PLIST_DST"
  sudo chown root:wheel "$PLIST_DST"
  sudo chmod 644 "$PLIST_DST"

  # Load and start
  sudo launchctl load "$PLIST_DST"
  echo "daemon installed and started."
  echo "socket: /var/run/cylonix/cylonixd.sock"
}

uninstall_daemon() {
  if sudo launchctl list "$PLIST_NAME" &>/dev/null; then
    echo "stopping daemon..."
    sudo launchctl unload "$PLIST_DST" 2>/dev/null || true
  fi
  if [[ -f "$PLIST_DST" ]]; then
    sudo rm "$PLIST_DST"
    echo "daemon plist removed."
  fi
  echo "note: /var/lib/cylonix state files were preserved."
}

status_daemon() {
  if sudo launchctl list "$PLIST_NAME" &>/dev/null; then
    echo "daemon is running."
    sudo launchctl list "$PLIST_NAME"
  else
    echo "daemon is not running."
  fi
  if [[ -S /var/run/cylonix/cylonixd.sock ]]; then
    echo "socket: /var/run/cylonix/cylonixd.sock (exists)"
  else
    echo "socket: /var/run/cylonix/cylonixd.sock (missing)"
  fi
}

case "$action" in
  install)  install_daemon ;;
  uninstall) uninstall_daemon ;;
  status)   status_daemon ;;
  *)
    echo "usage: $0 [install|uninstall|status]" >&2
    exit 1
    ;;
esac
