// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../providers/peer_status.dart';
import '../utils/utils.dart';

/// The status dot: colour from [PeerStatusInfo.kind], an optional ring so it can
/// sit on an avatar, and (optionally) a tooltip carrying the label. The colour
/// mapping lives here and nowhere else.
class PeerStatusDot extends StatelessWidget {
  final PeerStatusInfo status;
  final double size;
  final Color? ringColor;
  final bool tooltip;

  const PeerStatusDot({
    super.key,
    required this.status,
    this.size = 8,
    this.ringColor,
    this.tooltip = true,
  });

  static Color colorFor(BuildContext context, PeerStatusKind kind) {
    final apple = isApple();
    switch (kind) {
      case PeerStatusKind.online:
      case PeerStatusKind.ready:
        return apple
            ? CupertinoColors.systemGreen.resolveFrom(context)
            : Colors.green.shade600;
      case PeerStatusKind.connecting:
        return apple
            ? CupertinoColors.systemOrange.resolveFrom(context)
            : Colors.orange.shade600;
      case PeerStatusKind.unreachable:
        return apple
            ? CupertinoColors.systemRed.resolveFrom(context)
            : Colors.red.shade600;
      case PeerStatusKind.disconnected:
      case PeerStatusKind.unavailable:
      case PeerStatusKind.offline:
        return apple
            ? CupertinoColors.systemGrey.resolveFrom(context)
            : Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorFor(context, status.kind),
        border: ringColor == null
            ? null
            : Border.all(color: ringColor!, width: 1.5),
      ),
    );
    if (!tooltip) {
      return dot;
    }
    return Tooltip(message: status.label, child: dot);
  }
}
