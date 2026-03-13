// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

/// A Flutter-rendered approximation of the iOS 26 liquid-glass UISwitch.
///
/// Built from two round-bordered containers stacked in a [Stack]:
///   1. Outer pill track — top-lit glass gradient + hairline border.
///   2. Inner thumb — rounded-rectangle (NOT a circle) + shadow + hairline border.
///
/// [width] and [height] should match the native UISwitch.intrinsicContentSize
/// reported by the Swift side so the Flutter overlay is pixel-exact.
class GlassSwitch extends StatelessWidget {
  final bool value;
  final double width;
  final double height;

  // Standard UISwitch intrinsic size — used as fallback until the native side
  // reports the actual value via the intrinsicSize method channel message.
  static const double trackW = 61;
  static const double trackH = 28;

  const GlassSwitch({
    super.key,
    required this.value,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    final trackRadius = height / 2; // full pill

    // Thumb is a smaller horizontal pill — same shape as the track.
    // Height fills the track minus 2 pt padding top and bottom.
    // Width is wider than height so the radius (= thumbH/2) forms a pill
    // rather than a circle, closely mirroring the outer pill proportion.
    const pad = 2.0;
    final thumbH = height - pad * 2; // e.g. 27 for a 31 pt track
    final thumbW = width * 0.66 - pad * 2; // e.g.  — wider than thumbH
    final thumbRadius = thumbH / 2; // full pill radius, matches track shape

    // iOS system green (on) / system gray (off).
    final baseColor = value
        ? const Color(0xFF34C759)
        : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA));

    // Top-lit glass sheen.
    final topColor = Color.lerp(baseColor, Colors.white, isDark ? 0.08 : 0.22)!
        .withValues(alpha: 0.92);
    final bottomColor = baseColor.withValues(alpha: 0.86);

    final thumbLeft = value ? width - thumbW - pad : pad;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // ── Container 1: outer pill track ─────────────────────────────────
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topColor, bottomColor],
              ),
              borderRadius: BorderRadius.circular(trackRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.45),
                width: 0.7,
              ),
            ),
          ),
          // ── Container 2: inner thumb — horizontal pill matching track shape
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            left: thumbLeft,
            top: pad,
            child: Container(
              width: thumbW,
              height: thumbH,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(thumbRadius),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.06),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
