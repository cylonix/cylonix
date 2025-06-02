// You have generated a new plugin project without
// specifying the `--platforms` flag. A plugin project supports no platforms is generated.
// To add platforms, run `flutter create -t plugin --platforms <platforms> .` under the same
// directory. You can also find a detailed instruction on how to add platforms in the `pubspec.yaml` at https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'dart:async';

import 'package:flutter/services.dart';

class WindowToFront {
  static const MethodChannel _channel = const MethodChannel('window_to_front');

  static Future<void> activate() async {
    await _channel.invokeMethod('activate');
  }

  static Future<void> deactivate() async {
    await _channel.invokeMethod('deactivate');
  }
}
