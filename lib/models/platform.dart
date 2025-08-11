// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

bool isNativeAndroidTV = false;

Future<void> setIsAndroidTV() async {
  if (!Platform.isAndroid) {
    return;
  }
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  isNativeAndroidTV =
      androidInfo.systemFeatures.contains('android.software.leanback');
}

Future<void> initializePlatform() async {
  await setIsAndroidTV();
}