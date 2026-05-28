// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helpers for the Cylonix Android Taildrop notification channel.
///
/// Cylonix posts file-received notifications to a HIGH-importance channel
/// (`cylonix-taildrop-files`). On stock Android this triggers a heads-up
/// banner automatically. MIUI (and a few other OEM skins) suppress
/// heads-up by default until the user toggles "Floating notification"
/// per-channel; there is no API to flip that flag from the app. This
/// helper detects affected devices and opens the channel detail page so
/// the user can enable it themselves.
class AndroidTaildropNotifications {
  static const _channel = MethodChannel('io.cylonix.sase/wg');
  static const _prefDismissedKey = 'taildrop_miui_tip_dismissed';

  /// OEM brand names that ship a notification UX requiring an additional
  /// per-channel "floating notification" / "show as banner" opt-in beyond
  /// stock Android's IMPORTANCE_HIGH channel importance. Kept conservative
  /// — we only nag users on devices we know are affected.
  static const _affectedManufacturers = {
    'xiaomi',
    'redmi',
    'poco',
    'blackshark',
  };

  /// Returns the device manufacturer lowercased, or an empty string on
  /// non-Android platforms or if the platform call fails.
  static Future<String> deviceManufacturer() async {
    if (!Platform.isAndroid) return '';
    try {
      final result =
          await _channel.invokeMethod<String>('getDeviceManufacturer');
      return result?.toLowerCase() ?? '';
    } on PlatformException {
      return '';
    }
  }

  /// Whether the current device is one we expect to suppress heads-up
  /// banners by default (e.g. MIUI on Xiaomi). Returns false on non-Android.
  static Future<bool> isAffectedByHeadsUpSuppression() async {
    final mfr = await deviceManufacturer();
    return _affectedManufacturers.contains(mfr);
  }

  /// Opens the system Settings page for the Cylonix Taildrop notification
  /// channel so the user can toggle "Floating notification" / "Show as
  /// banner". Returns true if the intent was dispatched.
  static Future<bool> openTaildropChannelSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final ok =
          await _channel.invokeMethod<bool>('openTaildropChannelSettings');
      return ok ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> hasDismissedTip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefDismissedKey) ?? false;
  }

  static Future<void> markTipDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDismissedKey, true);
  }
}
