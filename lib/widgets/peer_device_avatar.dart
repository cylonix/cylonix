// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/peer_status.dart';
import '../utils/utils.dart';
import 'adaptive_widgets.dart';
import 'peer_status_dot.dart';

/// Avatar for a peer-messaging thread. A thread is addressed to a *device*
/// (its conversation id is a StableNodeID or device name), so the avatar
/// shows that device's OS icon — the same glyph the peer list uses — with an
/// online-presence dot. When an agent has spoken in the thread, a small
/// sparkle badge is overlaid; the badge is a property of the traffic, not
/// of the device, so it never replaces the device icon.
///
/// Falls back to a generic device glyph (never a bot) when the peer cannot
/// be resolved in the current netmap.
class PeerDeviceAvatar extends ConsumerWidget {
  final String peerRef;
  final double radius;
  final bool showAgentBadge;
  final bool showPresence;

  const PeerDeviceAvatar({
    super.key,
    required this.peerRef,
    this.radius = 20,
    this.showAgentBadge = false,
    this.showPresence = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = ref.watch(peerForRefProvider(peerRef));
    final apple = isApple();
    final os = node?.hostinfo?.os ?? '';
    final icon = node == null
        ? (apple
            ? CupertinoIcons.device_phone_portrait
            : Icons.devices_outlined)
        : osIcon(os);
    final presence = ref.watch(peerPresenceStatusProvider(peerRef));
    final size = radius * 2;
    // Badges scale with the avatar but stay legible on the smallest sizes.
    final badgeSize = (radius * 0.7).clamp(12.0, 16.0);
    // Ring that separates overlays from the avatar; matches the tile ground.
    final ringColor = apple
        ? CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(context)
        : Theme.of(context).colorScheme.surface;
    final accent = apple
        ? CupertinoTheme.of(context).primaryColor
        : Theme.of(context).colorScheme.primary;

    final label = StringBuffer(node?.displayName ?? 'Unknown device');
    if (showPresence && node != null) {
      label.write(', ${presence.label}');
    }
    if (showAgentBadge) label.write(', agent activity');

    return Semantics(
      label: label.toString(),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: radius,
              child: Icon(icon, size: radius * 1.1),
            ),
            if (showPresence && node != null)
              Positioned(
                right: -1,
                bottom: -1,
                // No tooltip on the badge: the list tile already carries the
                // label in its semantics, and a tooltip's long-press would
                // fight the tile's own gestures.
                child: PeerStatusDot(
                  status: presence,
                  size: badgeSize * 0.75,
                  ringColor: ringColor,
                  tooltip: false,
                ),
              ),
            if (showAgentBadge)
              Positioned(
                right: -3,
                top: -3,
                child: Tooltip(
                  message: 'An agent has messaged in this thread',
                  child: Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                      border: Border.all(color: ringColor, width: 1.5),
                    ),
                    child: Icon(
                      apple ? CupertinoIcons.sparkles : Icons.auto_awesome,
                      size: badgeSize * 0.6,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
