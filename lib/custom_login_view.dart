// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/alert.dart';
import 'models/const.dart';
import 'utils/logger.dart';
import 'utils/utils.dart';
import 'viewmodels/login_view.dart';
import 'viewmodels/state_notifier.dart';
import 'widgets/adaptive_widgets.dart';
import 'widgets/alert_chip.dart';
import 'widgets/alert_dialog_widget.dart';

class LoginViewStrings {
  final String title;
  final String explanation;
  final String inputTitle;
  final String placeholder;
  final String submitLabel;

  const LoginViewStrings({
    required this.title,
    required this.explanation,
    required this.inputTitle,
    required this.placeholder,
    required this.submitLabel,
  });
}

class CustomLoginView extends ConsumerStatefulWidget {
  const CustomLoginView({
    super.key,
    required this.onNavigateToHome,
    this.onNavigateBackToSettings,
    this.isAuthKey = false,
  });

  final VoidCallback onNavigateToHome;
  final VoidCallback? onNavigateBackToSettings;
  final bool isAuthKey;

  @override
  ConsumerState<CustomLoginView> createState() => _CustomLoginViewState();
}

class _CustomLoginViewState extends ConsumerState<CustomLoginView> {
  static final _logger = Logger(tag: 'CustomLoginView');
  final _textController = TextEditingController();
  bool _customURL = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LoginViewStrings(
      title: widget.isAuthKey ? 'Auth Key' : 'Custom Control',
      explanation: widget.isAuthKey
          ? 'Enter your auth key to connect to your mesh network'
          : 'Choose a control server provider or select the "Custom" '
              'option to enter your custom control server URL',
      inputTitle: widget.isAuthKey ? 'Auth Key' : 'Control URL',
      placeholder: widget.isAuthKey
          ? 'cy-auth-xxxxxx-xxxxxxxxxxxxxxx'
          : 'https://manage.cylonix.io',
      submitLabel: widget.isAuthKey ? "Add Account" : "Set Custom Control URL",
    );

    return isApple()
        ? _buildCupertinoView(context, strings)
        : _buildMaterialView(context, strings);
  }

  Widget _buildCupertinoView(BuildContext context, LoginViewStrings strings) {
    return CupertinoPageScaffold(
      backgroundColor: appleScaffoldBackgroundColor(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        middle: Text(strings.title),
        leading: widget.onNavigateBackToSettings == null
            ? null
            : AppleBackButton(
                onPressed: widget.onNavigateBackToSettings,
              ),
      ),
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _buildContent(context, strings, true),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialView(BuildContext context, LoginViewStrings strings) {
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.title),
        leading: widget.onNavigateBackToSettings == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onNavigateBackToSettings,
              ),
      ),
      body: Container(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _buildContent(context, strings, false),
        ),
      ),
    );
  }

  bool get _showSubmitButton {
    return widget.isAuthKey || (_customURL && _textController.text.isNotEmpty);
  }

  Widget _buildContent(
      BuildContext context, LoginViewStrings strings, bool isCupertino) {
    final loginViewState = ref.watch(loginViewModelProvider);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildSection(strings),
        const SizedBox(height: 16),
        if (_showSubmitButton)
          AdaptiveButton(
            filled: true,
            onPressed: _handleSubmit,
            child: Text(strings.submitLabel),
          ),
      ],
    );

    return loginViewState.when(
      data: (_) => isCupertino
          ? content
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: content,
            ),
      loading: () => const Center(child: AdaptiveLoadingWidget()),
      error: (error, stackTrace) {
        final target = widget.isAuthKey ? 'auth key' : 'control URL';
        final msg = "Failed to set $target: $error";
        _logger.e("$msg\n$stackTrace");
        return Center(
          child: AlertChip(Alert(msg)),
        );
      },
    );
  }

  Future<void> _setController(String url) async {
    try {
      final current = ref.read(controlURLProvider);
      if (url == current) {
        _logger.d("Control URL is already set to $url");
        return;
      }
      await ref.read(controlURLProvider.notifier).setValue(url);
      if (mounted) {
        await showAlertDialog(
          context,
          "Success",
          "Control URL has been set to '$url'. "
              "It will be used for the next login.",
        );
      }
      if (mounted) {
        setState(() {
          _textController.text = url;
        });
      }
    } catch (e) {
      _logger.e('Failed to set control URL: $e');
      if (mounted) {
        await showAlertDialog(
          context,
          "Error",
          'Failed to set control URL to $url: $e',
        );
      }
    }
  }

  Widget? _appleControlURLTrailing(String url, String current) {
    return url == current && !_customURL
        ? const Icon(
            CupertinoIcons.checkmark_circle,
            color: CupertinoColors.activeBlue,
          )
        : null;
  }

  Widget _buildSection(LoginViewStrings strings) {
    final controlURL = ref.watch(controlURLProvider);

    return Column(
      children: [
        if (!widget.isAuthKey) ...[
          AdaptiveListSection.insetGrouped(
            header: const AdaptiveGroupedHeader(
              'CONTROL SERVER',
            ),
            footer: Text(
              strings.explanation,
              style: adaptiveGroupedFooterStyle(context),
            ),
            children: [
              AdaptiveListTile.notched(
                title: const Text('Default (Cylonix)'),
                subtitle: const Text(cylonixURL),
                leading: Icon(
                  CupertinoIcons.cloud,
                  color: CupertinoColors.activeBlue.resolveFrom(context),
                ),
                trailing: _appleControlURLTrailing(cylonixURL, controlURL),
                onTap: () {
                  setState(() {
                    _customURL = false;
                  });
                  _setController(cylonixURL);
                },
              ),
              AdaptiveListTile.notched(
                title: const Text('Tailscale'),
                subtitle: const Text(tailscaleURL),
                leading: Icon(
                  CupertinoIcons.cloud_fill,
                  color: CupertinoColors.activeBlue.resolveFrom(context),
                ),
                trailing: _appleControlURLTrailing(tailscaleURL, controlURL),
                onTap: () {
                  setState(() {
                    _customURL = false;
                  });
                  _setController(tailscaleURL);
                },
              ),
              AdaptiveListTile.notched(
                title: const Text('Custom'),
                subtitle: const Text('Enter your own control server URL'),
                leading: Icon(
                  CupertinoIcons.gear,
                  color: CupertinoColors.activeBlue.resolveFrom(context),
                ),
                trailing: controlURL != cylonixURL && controlURL != tailscaleURL
                    ? Icon(
                        CupertinoIcons.checkmark_circle,
                        color: CupertinoColors.activeBlue.resolveFrom(context),
                      )
                    : null,
                onTap: () {
                  setState(() {
                    _customURL = true;
                  });
                },
              ),
            ],
          ),
          if (_customURL)
            AdaptiveListSection.insetGrouped(
              header: const AdaptiveGroupedHeader('CUSTOM URL'),
              children: [
                AdaptiveListTile(
                  title: CupertinoTextField.borderless(
                    controller: _textController,
                    placeholder: strings.placeholder,
                    clearButtonMode: OverlayVisibilityMode.editing,
                    keyboardType: TextInputType.url,
                    onSubmitted: (value) {
                      _setController(value);
                    },
                  ),
                ),
              ],
            ),
        ] else ...[
          AdaptiveListSection.insetGrouped(
            header: Text(strings.title),
            footer: Text(strings.explanation),
            children: [
              AdaptiveListTile(
                title: CupertinoTextField.borderless(
                  controller: _textController,
                  placeholder: strings.placeholder,
                  clearButtonMode: OverlayVisibilityMode.editing,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _handleSubmit() async {
    final value = _textController.text.trim();
    if (value.isEmpty) return;
    if (widget.isAuthKey) {
      try {
        await ref.read(loginViewModelProvider.notifier).loginWithAuthKey(
              value,
              onSuccess: widget.onNavigateToHome,
            );
        widget.onNavigateToHome();
      } catch (e) {
        _logger.e('Failed to login with auth key: $e');
        if (mounted) {
          await showAlertDialog(
            context,
            "Error",
            'Failed to login with auth key: $e',
          );
        }
      }
      return;
    }
    await _setController(value);
  }
}
