// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

/// A frosted-glass container for iOS. On other platforms, renders the child
/// without any glass effect.
///
/// Uses [BackdropFilter] to blur Flutter-rendered content beneath it —
/// correct for Flutter's rendering pipeline (unlike UIVisualEffectView,
/// which only blurs UIKit content behind the Metal layer).
class GlassContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final double blurSigma;
  final Color? tintColor;
  final EdgeInsetsGeometry? padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.blurSigma = 20,
    this.tintColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) return child;
    final isDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final tint = tintColor ??
        (isDark
            ? Colors.black.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.35));
    final border = borderRadius ?? BorderRadius.circular(16);
    return ClipRRect(
      borderRadius: border,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: tint,
            borderRadius: border,
            border: Border.all(
              color: Colors.white
                  .withValues(alpha: isDark ? 0.15 : 0.4),
              width: 0.5,
            ),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
