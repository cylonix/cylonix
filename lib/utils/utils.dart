// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/platform.dart';

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
  if (isNativeAndroidTV) {
    return false; // Don't use navigation rail on Android TV
  }
  return MediaQuery.of(context).size.width >= 900.0;
}

bool usingNavigationRail(BuildContext context) {
  return useNavigationRail(context) && isCurrentRouteHomePage(context);
}

bool isCurrentRouteHomePage(BuildContext context) {
  return (ModalRoute.of(context)?.settings.name ?? '/') == '/';
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
  if (isApple()) {
    // Use native platform channel to get system dark mode setting
    final window = WidgetsBinding.instance.platformDispatcher;
    if (window.platformBrightness == Brightness.dark) {
      return true;
    }
  }
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

String formatBytes(int bytes, [int decimals = 2]) {
  if (bytes <= 0) return "";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (log(bytes) / log(1024)).floor();
  return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + ' ' + suffixes[i];
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String _format12HourTime(DateTime local) {
  final hour = local.hour == 0
      ? 12
      : local.hour > 12
          ? local.hour - 12
          : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

/// Returns null for today, otherwise 'Yesterday', a weekday name for the
/// past week, or a date such as 'Jun 11' ('Jun 11, 2025' if another year).
String? _messageDateLabel(DateTime local) {
  final now = DateTime.now();
  // Construct as UTC so the difference is an exact number of days even
  // across DST transitions.
  final today = DateTime.utc(now.year, now.month, now.day);
  final day = DateTime.utc(local.year, local.month, local.day);
  final days = today.difference(day).inDays;
  if (days <= 0) return null;
  if (days == 1) return 'Yesterday';
  if (days < 7) return _weekdayNames[local.weekday - 1];
  final date = '${_monthNames[local.month - 1]} ${local.day}';
  return local.year == now.year ? date : '$date, ${local.year}';
}

/// Timestamp for a message header: time only for today, otherwise the date
/// followed by the time, e.g. 'Yesterday 3:45 PM' or 'Jun 11 3:45 PM'.
String formatMessageTimestamp(DateTime value) {
  final local = value.toLocal();
  final time = _format12HourTime(local);
  final label = _messageDateLabel(local);
  return label == null ? time : '$label $time';
}

/// Compact timestamp for a conversation list: time for today, otherwise
/// 'Yesterday', a weekday name, or a date without the time.
String formatConversationTimestamp(DateTime value) {
  final local = value.toLocal();
  return _messageDateLabel(local) ?? _format12HourTime(local);
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
    return "${this[0].toUpperCase()}${substring(1)}";
  }

  /// Returns a substring with protocol prefix like 'https://' removed.
  protocolPrefixRemoved() {
    return replaceFirst(RegExp('^.*://'), '');
  }
}
