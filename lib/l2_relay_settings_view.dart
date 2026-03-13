// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/ipn.dart';
import 'utils/utils.dart';
import 'viewmodels/state_notifier.dart';
import 'widgets/adaptive_widgets.dart';
import 'widgets/alert_dialog_widget.dart';

class L2RelaySettingsView extends ConsumerStatefulWidget {
  final VoidCallback onBackToSettings;

  const L2RelaySettingsView({
    super.key,
    required this.onBackToSettings,
  });

  @override
  ConsumerState<L2RelaySettingsView> createState() =>
      _L2RelaySettingsViewState();
}

class _L2RelaySettingsViewState extends ConsumerState<L2RelaySettingsView> {
  bool _isTogglingRelay = false;
  bool _isTogglingCapture = false;
  bool _isTogglingVerboseDebug = false;

  Future<bool> _showLocalDiscoveryPrePromptDialog() async {
    const title = 'Enable Local Discovery Relay?';
    const body =
        'Cylonix can relay local discovery traffic (AirPrint/Bonjour/game discovery) '
        'for trusted Tailnet peers.\n\n'
        'Before continuing:\n'
        '- iOS/macOS may show a Local Network permission prompt.\n'
        '- Discovery relay remains under your control and can be disabled anytime.';
    if (isApple()) {
      final action = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text(title),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(body),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      return action == true;
    }
    final action = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(title),
        content: const Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not Now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return action == true;
  }

  Future<void> _toggleLocalDiscoveryRelay(bool value) async {
    setState(() {
      _isTogglingRelay = true;
    });
    try {
      if (value && isApple()) {
        final shown = ref.read(localDiscoveryPrePromptShownProvider);
        if (!shown) {
          final proceed = await _showLocalDiscoveryPrePromptDialog();
          if (!proceed) {
            return;
          }
          await ref
              .read(localDiscoveryPrePromptShownProvider.notifier)
              .setValue(true);
        }

        final granted = await ref
            .read(ipnStateNotifierProvider.notifier)
            .requestLocalNetworkPermission();
        if (!granted) {
          if (mounted) {
            await showAlertDialog(
              context,
              "Local Network Permission Needed",
              "Cylonix couldn't access Local Network discovery. "
                  "Please allow Local Network access when prompted, then try again.",
            );
          }
          return;
        }
      }

      await ref
          .read(ipnStateNotifierProvider.notifier)
          .setLocalDiscoveryRelay(value);
      ref.read(localDiscoveryRelayProvider.notifier).setState(value);

      if (value && !ref.read(l2RelayCaptureProvider)) {
        await ref
            .read(ipnStateNotifierProvider.notifier)
            .setL2RelayCapture(true);
        await ref.read(l2RelayCaptureProvider.notifier).setValue(true);
      }
    } catch (e) {
      if (mounted) {
        await showAlertDialog(
          context,
          "Error",
          "Failed to set Local Discovery Relay to $value: $e",
        );
      }
    } finally {
      _isTogglingRelay = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _toggleCaptureAndForward(bool value) async {
    setState(() {
      _isTogglingCapture = true;
    });
    try {
      await ref
          .read(ipnStateNotifierProvider.notifier)
          .setL2RelayCapture(value);
      await ref.read(l2RelayCaptureProvider.notifier).setValue(value);
    } catch (e) {
      if (mounted) {
        await showAlertDialog(
          context,
          "Error",
          "Failed to set Capture and Forward Discovery to $value: $e",
        );
      }
    } finally {
      _isTogglingCapture = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _toggleVerboseDebug(bool value) async {
    setState(() {
      _isTogglingVerboseDebug = true;
    });
    try {
      await ref
          .read(ipnStateNotifierProvider.notifier)
          .setL2RelayVerboseDebug(value);
      await ref.read(l2RelayVerboseDebugProvider.notifier).setValue(value);
    } catch (e) {
      if (mounted) {
        await showAlertDialog(
          context,
          "Error",
          "Failed to set L2 Relay verbose debug to $value: $e",
        );
      }
    } finally {
      _isTogglingVerboseDebug = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final relayEnabled = ref.watch(localDiscoveryRelayProvider);
    final captureEnabled = ref.watch(l2RelayCaptureProvider);
    final verboseDebugEnabled = ref.watch(l2RelayVerboseDebugProvider);
    return AdaptiveScaffold(
      title: const Text('L2 Relay Settings'),
      onGoBack: widget.onBackToSettings,
      body: Container(
        alignment: Alignment.topCenter,
        child: Container(
          alignment: Alignment.topCenter,
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            children: [
              AdaptiveListSection.insetGrouped(
                header: const AdaptiveGroupedHeader('Local Discovery Relay'),
                children: [
                  AdaptiveListTile.notched(
                    leading:
                        relayEnabled ? AdaptiveHealthyIcon(size: 36) : null,
                    title: Text(relayEnabled
                        ? 'This Device Relays Local Discovery'
                        : "This Device Does Not Relay Local Discovery"),
                  ),
                  AdaptiveListTile.notched(
                    title: const Text('Enable Local Discovery Relay'),
                    subtitle: const Text(
                      'Relay printer, storage and game discovery et al '
                      'messages across your mesh network',
                      softWrap: true,
                      maxLines: 3,
                    ),
                    trailing: _isTogglingRelay
                        ? const CupertinoActivityIndicator()
                        : AdaptiveSwitch(
                            value: relayEnabled,
                            onChanged: _toggleLocalDiscoveryRelay,
                          ),
                  ),
                ],
              ),
              if (relayEnabled)
                AdaptiveListSection.insetGrouped(
                  children: [
                    AdaptiveListTile.notched(
                      title: const Text('Capture and Forward Discovery'),
                      subtitle: const Text(
                        'Start relay capture and forwarding on this device',
                        softWrap: true,
                        maxLines: 3,
                      ),
                      trailing: _isTogglingCapture
                          ? const CupertinoActivityIndicator()
                          : AdaptiveSwitch(
                              value: captureEnabled,
                              onChanged: _toggleCaptureAndForward,
                            ),
                    ),
                    AdaptiveListTile.notched(
                      title: const Text('Verbose L2 Relay Debug'),
                      subtitle: const Text(
                        'Toggle extra relay logging',
                        softWrap: true,
                        maxLines: 3,
                      ),
                      trailing: _isTogglingVerboseDebug
                          ? const CupertinoActivityIndicator()
                          : AdaptiveSwitch(
                              value: verboseDebugEnabled,
                              onChanged: _toggleVerboseDebug,
                            ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
