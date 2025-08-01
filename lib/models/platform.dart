// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

bool isAndroidTV = false;

Future<void> setIsAndroidTV() async {
  if (!Platform.isAndroid) {
    return;
  }
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  isAndroidTV =
      androidInfo.systemFeatures.contains('android.software.leanback');
}

Future<void> initializePlatform() async {
  await setIsAndroidTV();
}