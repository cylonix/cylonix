// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'applog.dart';
import '../services/ipn.dart';

class Logger {
  final String tag;
  final bool defaultSendToIpn;
  final _logger = AppLog.logger;
  Logger({required this.tag, this.defaultSendToIpn = true});
  void d(String log, {bool? sendToIpn}) {
    _logger.d("$tag: $log");
    if (sendToIpn ?? defaultSendToIpn) {
      IpnService.sendLog("[APP] [DEBUG] [$tag] $log");
    }
  }

  void w(String log, {bool? sendToIpn}) {
    _logger.w("$tag: $log");
    if (sendToIpn ?? defaultSendToIpn) {
      IpnService.sendLog("[APP] [WARNING] [$tag] $log", priority: true);
    }
  }

  void i(String log, {bool? sendToIpn}) {
    _logger.i("$tag: $log");
    if (sendToIpn ?? defaultSendToIpn) {
      IpnService.sendLog("[APP] [INFO] [$tag] $log");
    }
  }

  void e(String log, {bool? sendToIpn}) {
    _logger.e("$tag: $log");
    if (sendToIpn ?? defaultSendToIpn) {
      IpnService.sendLog("[APP] [ERROR] [$tag] $log", priority: true);
    }
  }
}
