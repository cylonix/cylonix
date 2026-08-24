// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:flutter/widgets.dart';

import '../services/ipn.dart';
import 'alert_dialog_widget.dart';

/// Explains why Cylonix needs the battery-optimization exemption and, if
/// the user agrees, opens the system request dialog.
///
/// OEM app freezers (MIUI "Greezer"/Millet observed 2026-08-24) suspend the
/// app process in the background despite the VPN foreground service, which
/// blackholes all device traffic until the app is reopened. The system
/// exemption is the opt-out those freezers honor.
///
/// Called at startup from HomePage (silent no-op once exempt) and from the
/// Settings "Background Running" row, which lets the user relaunch the
/// flow anytime — including after dismissing the startup prompt.
Future<void> showBatteryOptimizationDialog(
  BuildContext context,
  IpnService service, {
  bool fromSettings = false,
}) async {
  if (!Platform.isAndroid) {
    return;
  }
  final exempt = await service.isBatteryOptExempt();
  if (!context.mounted) {
    return;
  }
  if (exempt) {
    if (fromSettings) {
      await showAlertDialog(
        context,
        'Background Running',
        'Cylonix is already allowed to run without battery restrictions. '
            'The VPN will stay connected in the background.',
      );
    }
    return;
  }
  final ok = await showAlertDialog(
    context,
    'Keep VPN Running in Background',
    "Your device's battery optimization can freeze Cylonix in the "
        'background, which cuts off all network traffic until the app is '
        'reopened.\n\nAllow Cylonix to run without battery restrictions to '
        'keep the VPN connected.',
    okText: 'Continue',
    cancelText: 'Not Now',
    showCancel: true,
    defaultButton: 'Continue',
  );
  if (ok == true) {
    await service.requestBatteryOptExemption();
  }
}
