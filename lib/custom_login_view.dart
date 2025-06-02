import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/alert.dart';
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
          ? 'Enter your auth key to connect to your tailnet'
          : 'Choose a control server provider or select the "Custom" '
              'option to enter your custom control server URL',
      inputTitle: widget.isAuthKey ? 'Auth Key' : 'Control URL',
      placeholder: widget.isAuthKey
          ? 'tskey-xxxxxx-xxxxxxxxxxxxxxx'
          : 'https://controlplane.tailscale.com',
      submitLabel: widget.isAuthKey ? "Add Account" : "Set Custom Control URL",
    );

    return isApple()
        ? _buildCupertinoView(context, strings)
        : _buildMaterialView(context, strings);
  }

  Widget _buildCupertinoView(BuildContext context, LoginViewStrings strings) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
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
      body: Center(
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
        if (isCupertino)
          _buildCupertinoSection(strings)
        else
          _buildMaterialSection(strings),
        const SizedBox(height: 16),
        if (_showSubmitButton)
          isCupertino
              ? CupertinoButton.filled(
                  onPressed: _handleSubmit,
                  child: Text(strings.submitLabel),
                )
              : ElevatedButton(
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
      await ref.read(loginViewModelProvider.notifier).setControlURL(
        url,
        onSuccess: () async {
          _logger.d("Control URL set to $url");
          if (mounted) {
            await showAlertDialog(
              context,
              "Success",
              "Control URL set to $url. It will be used for the next login.",
            );
          }
          widget.onNavigateToHome();
        },
      );
      ref.read(controlURLProvider.notifier).setValue(url);
      setState(() {
        _textController.text = url;
      });
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
            CupertinoIcons.checkmark_circle_fill,
            color: CupertinoColors.activeBlue,
          )
        : null;
  }

  static const _cylonixURL = 'https://manage.cylonix.io';
  static const _tailscaleURL = 'https://controlplane.tailscale.com';

  Widget _buildCupertinoSection(LoginViewStrings strings) {
    final controlURL = ref.watch(controlURLProvider);

    return Column(
      children: [
        if (!widget.isAuthKey) ...[
          AdaptiveListSection.insetGrouped(
            header: const Text('CONTROL SERVER'),
            footer: Text(strings.explanation),
            children: [
              AdaptiveListTile.notched(
                title: const Text('Default (Cylonix)'),
                subtitle: const Text(_cylonixURL),
                leading: const Icon(
                  CupertinoIcons.cloud,
                  color: CupertinoColors.activeBlue,
                ),
                trailing: _appleControlURLTrailing(_cylonixURL, controlURL),
                onTap: () {
                  setState(() {
                    _customURL = false;
                  });
                  _setController(_cylonixURL);
                },
              ),
              AdaptiveListTile.notched(
                title: const Text('Tailscale'),
                subtitle: const Text(_tailscaleURL),
                leading: const Icon(
                  CupertinoIcons.cloud_fill,
                  color: CupertinoColors.activeBlue,
                ),
                trailing: _appleControlURLTrailing(_tailscaleURL, controlURL),
                onTap: () {
                  setState(() {
                    _customURL = false;
                  });
                  _setController(_tailscaleURL);
                },
              ),
              AdaptiveListTile.notched(
                title: const Text('Custom'),
                subtitle: const Text('Enter your own control server URL'),
                leading: const Icon(
                  CupertinoIcons.gear,
                  color: CupertinoColors.activeBlue,
                ),
                trailing:
                    controlURL != _cylonixURL && controlURL != _tailscaleURL
                        ? const Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: CupertinoColors.activeBlue,
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
              header: const Text('CUSTOM URL'),
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

  Widget _buildMaterialSection(LoginViewStrings strings) {
    if (widget.isAuthKey) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              strings.explanation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: strings.inputTitle,
                hintText: strings.placeholder,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      );
    }

    final controlURL = ref.watch(controlURLProvider);
    final selectedIndex = _customURL
        ? 2
        : controlURL == _cylonixURL
            ? 0
            : controlURL == _tailscaleURL
                ? 1
                : 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              RadioListTile(
                value: 0,
                groupValue: selectedIndex,
                title: const Text('Default (Cylonix)'),
                subtitle: const Text(_cylonixURL),
                secondary: Icon(
                  Icons.cloud,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onChanged: (value) {
                  _setController(_cylonixURL);
                },
              ),
              const Divider(height: 1),
              RadioListTile(
                value: 1,
                groupValue: selectedIndex,
                title: const Text('Tailscale'),
                subtitle: const Text(_tailscaleURL),
                secondary: Icon(
                  Icons.cloud_queue,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onChanged: (value) {
                  _setController(_tailscaleURL);
                },
              ),
              const Divider(height: 1),
              RadioListTile(
                value: 2,
                groupValue: selectedIndex,
                title: const Text('Custom'),
                subtitle: const Text('Enter your own control server URL'),
                secondary: Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onChanged: (value) {
                  setState(() {
                    _customURL = true;
                    _textController.text = '';
                  });
                },
              ),
            ],
          ),
        ),
        if (_customURL) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Custom URL',
                hintText: strings.placeholder,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            strings.explanation,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.7),
                ),
          ),
        ),
      ],
    );
  }

  void _handleSubmit() async {
    final value = _textController.text.trim();
    if (value.isEmpty) return;
    if (widget.isAuthKey) {
      ref.read(loginViewModelProvider.notifier).loginWithAuthKey(
            value,
            onSuccess: widget.onNavigateToHome,
          );
      return;
    }
    await _setController(value);
  }
}
