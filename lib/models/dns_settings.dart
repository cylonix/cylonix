// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/utils.dart';

enum DNSEnablementState {
  enabled,
  disabled,
  partial,
  notRunning;

  String get title {
    switch (this) {
      case DNSEnablementState.enabled:
        return 'Using Cylonix DNS';
      case DNSEnablementState.disabled:
        return 'Cylonix DNS Disabled';
      case DNSEnablementState.partial:
        return 'Cylonix DNS Partially Enabled';
      case DNSEnablementState.notRunning:
        return 'Not Running';
    }
  }

  String get caption {
    switch (this) {
      case DNSEnablementState.enabled:
        return 'This device is using Cylonix to resolve DNS names';
      case DNSEnablementState.disabled:
        return 'This device is using the default system DNS resolver';
      case DNSEnablementState.partial:
        return 'This device is using Cylonix to resolve DNS names but only '
            'some DNS features are enabled';
      case DNSEnablementState.notRunning:
        return 'Cylonix is not running. This device is using the '
            'system\'s DNS resolver';
    }
  }

  Color get tint {
    switch (this) {
      case DNSEnablementState.enabled:
        return Colors.green;
      case DNSEnablementState.disabled:
        return Colors.red;
      case DNSEnablementState.notRunning:
        return Colors.grey;
      case DNSEnablementState.partial:
        return Colors.orange;
    }
  }

  IconData get icon {
    switch (this) {
      case DNSEnablementState.enabled:
        return isApple()
            ? CupertinoIcons.check_mark_circled
            : Icons.check_circle_outlined;
      case DNSEnablementState.notRunning:
      case DNSEnablementState.disabled:
      case DNSEnablementState.partial:
        return isApple() ? CupertinoIcons.xmark_circle : Icons.cancel_outlined;
    }
  }
}
