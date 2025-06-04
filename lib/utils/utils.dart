import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

const double baseHeight = 480;
const double baseWidth = 1080;

double screenAwareSize(double size, BuildContext context) {
  return size * MediaQuery.of(context).size.height / baseHeight;
}

double screenAwareSizeWidth(double size, BuildContext context) {
  return size * MediaQuery.of(context).size.width / baseWidth;
}

bool isXLargeScreen(BuildContext context) {
  return MediaQuery.of(context).size.width > 1920.0;
}

bool isLargeScreen(BuildContext context) {
  return MediaQuery.of(context).size.width >= 960.0;
}

bool isMediumScreen(BuildContext context) {
  return MediaQuery.of(context).size.width >= 640.0;
}

bool useNavigationRail(BuildContext context) {
  return MediaQuery.of(context).size.width >= 800.0;
}

bool isInPortraitMode(BuildContext context) {
  return MediaQuery.of(context).orientation == Orientation.portrait;
}

bool useTopNavigationRail(BuildContext context) {
  return false;
}

bool preferOutlinedMenuAnchorButton() {
  return !enableMaterial3(); // || !(Pst.enableTV ?? false);
}

bool preferOnOffButtonOverSwitch() {
  return false;
}

/// MenuAnchor still has issues on not being able to auto-focus when open in TV
/// mode. Prefer popup menu instead for now.
bool preferPopupMenuButton() {
  return false;
}

/// Prefer full width popup menu entry due to inability to detect tap down
/// positions.
bool preferPopupMenuItemExpanded() {
  return false;
}

bool preferNamespaceTabBarInAppBar() {
  return false;
}

Offset getPopupMenuOffset() {
  return const Offset(0, -100);
}

bool isDarkMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

Color focusColor(BuildContext context) {
  return Theme.of(context).colorScheme.inversePrimary;
}

TextStyle? smallTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w300,
      );
}

TextStyle? titleLargeTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleLarge?.apply(
        color: Theme.of(context).colorScheme.secondary,
        fontWeightDelta: 3,
      );
}

TextStyle? titleMediumTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleMedium?.apply(
        color: Theme.of(context).colorScheme.secondary,
        fontWeightDelta: 3,
      );
}

bool enableMaterial3() {
  // Support material3 can be a per-platform choice.
  // Enable for all platforms for now and can be reverted back if necessary.
  return true;
}

bool isMobile() {
  return Platform.isAndroid || Platform.isIOS;
}

bool isApple() {
  return Platform.isMacOS || Platform.isIOS;
}

bool isDesktop() {
  return !isMobile();
}

String formatBytes(int bytes, int decimals) {
  if (bytes <= 0) return "";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (log(bytes) / log(1024)).floor();
  return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + ' ' + suffixes[i];
}

/// ShowBySide base on the screen size
bool showSideBySide(BuildContext context) {
  final screenSize = MediaQuery.of(context).size;
  return (screenSize.width > 2400);
}

extension DateTimePlus on DateTime {
  static get zero {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

extension StringPlus on String {
  /// Returns a substring with a max size that can be larger than length.
  shortString(int max, {int start = 0}) {
    if (start >= length) {
      return "";
    }
    if (start + max >= length) {
      return substring(start);
    }
    return substring(start, start + max);
  }

  /// Short string that can handle multi-byte codes.
  shortRunes(int max, {int start = 0}) {
    if (runes.length >= max + start) {
      return this;
    }
    return String.fromCharCodes(runes.toList().sublist(start, max));
  }

  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }

  /// Returns a substring with protocol prefix like 'https://' removed.
  protocolPrefixRemoved() {
    return replaceFirst(RegExp('^.*://'), '');
  }
}
