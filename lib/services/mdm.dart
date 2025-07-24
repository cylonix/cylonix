// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/services.dart';

class MDMSettingsService {
  static const _platform = MethodChannel('com.cylonix.sase/mdm');

  Future<bool> get forceEnabled async {
    try {
      final result = await _platform.invokeMethod<bool>('getForceEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> get loginURL async {
    try {
      return await _platform.invokeMethod<String>('getLoginURL');
    } catch (e) {
      return null;
    }
  }

  Future<String?> get exitNodeID async {
    try {
      return await _platform.invokeMethod<String>('getExitNodeID');
    } catch (e) {
      return null;
    }
  }

  Future<bool> get allowsExitNode async {
    try {
      final result = await _platform.invokeMethod<bool>('getAllowsExitNode');
      return result ?? true;
    } catch (e) {
      return true;
    }
  }

  bool get isManaged {
    return false;
  }
}
