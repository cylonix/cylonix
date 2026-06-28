// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

const cylonixURL = 'https://manage.cylonix.io';
const tailscaleURL = 'https://controlplane.tailscale.com';

/// Human-readable name for a control server URL: "Cylonix" for the default
/// Cylonix controller, "Tailscale" for the Tailscale controller, otherwise the
/// custom controller URL spelled out. Returns '' for a null/empty URL.
String controlServerDisplayName(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url == cylonixURL) return 'Cylonix';
  if (url == tailscaleURL) return 'Tailscale';
  return url;
}
