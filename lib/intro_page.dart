// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'utils/logger.dart';
import 'utils/utils.dart';
import 'viewmodels/state_notifier.dart';
import 'widgets/adaptive_widgets.dart';
import 'widgets/alert_dialog_widget.dart';
import 'widgets/tv_widgets.dart';

class IntroPage extends ConsumerStatefulWidget {
  const IntroPage({Key? key}) : super(key: key);

  @override
  ConsumerState<IntroPage> createState() => _State();
}

class _State extends ConsumerState<IntroPage> {
  static final _logger = Logger(tag: "IntroPage");
  final _key = GlobalKey<IntroductionScreenState>();
  int _index = 0;
  bool _privacyAgreed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => FocusScope.of(context).requestFocus());
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      globalBackgroundColor: isApple()
          ? CupertinoColors.secondarySystemFill.resolveFrom(context)
          : Theme.of(context).scaffoldBackgroundColor,
      key: _key,
      initialPage: _index,
      pages: _pages,
      isProgress: true,
      showBackButton: true,
      showNextButton: true,
      showDoneButton: false,
      back: Icon(
        isApple() ? CupertinoIcons.chevron_left : Icons.arrow_back_rounded,
      ),
      next: Icon(
        isApple() ? CupertinoIcons.chevron_right : Icons.arrow_forward_rounded,
      ),
      onChange: (v) => setState(() {
        _index = v;
      }),
    );
  }

  void _previousPage() {
    if (_index > 0) {
      _key.currentState?.previous();
    } else {
      _logger.w("Already at the first page, cannot go back.");
    }
  }

  void _nextPage() {
    if (_index < _pages.length - 1) {
      _key.currentState?.next();
    } else {
      _logger.w("Already at the last page, cannot go next.");
    }
  }

  double get _topImageHeight {
    return 80;
  }

  TextStyle? get _textStyle {
    return isApple()
        ? TextStyle(
            fontSize: 16,
            color: CupertinoColors.label.resolveFrom(context),
          )
        : Theme.of(context).textTheme.bodyLarge;
  }

  Widget get _doneButton {
    return AdaptiveButton(
      autofocus: true,
      filled: true,
      onPressed: _handleIntroDone,
      child: const Text("Setup Cylonix"),
    );
  }

  void _handleIntroDone() async {
    if (!_privacyAgreed) {
      await showAlertDialog(
        context,
        "Agreement Required",
        "Please agree to the User Agreement and Privacy Policy to continue.",
      );
      _previousPage();
      return;
    }
    _logger.d("Intro done. Calling completion and switch back to home page");
    await _disableIntroPage();
  }

  void _openWebsite() {
    _launchURL('https://cylonix.io');
  }

  void _launchURL(String url) async {
    final isAndroidTV = ref.watch(isAndroidTVProvider);
    if (isAndroidTV) {
      await showQrCodeForURL(context, url);
      return;
    }
    try {
      if (!await launchUrl(Uri.parse(url))) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      _logger.e("Failed to open website: $e");
      if (mounted) {
        await showAlertDialog(
          context,
          "Error",
          "Failed to open the website: $e",
        );
      }
    }
  }

  Future<void> _disableIntroPage() async {
    await ref.read(introViewedProvider.notifier).setValue(true);
  }

  Widget _topImage(Widget child) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget get _policyInfoIcon {
    return Icon(
      isApple()
          ? CupertinoIcons.exclamationmark_shield
          : Icons.privacy_tip_outlined,
      size: _topImageHeight,
    );
  }

  Widget get _permissionsIcon {
    return Icon(
      isApple() ? CupertinoIcons.shield : Icons.shield_outlined,
      size: _topImageHeight,
    );
  }

  PageViewModel get _introPage {
    return _getPage(
      _logo,
      "Welcome to Cylonix",
      Text(
        "Cylonix connects your team's devices securely and privately. "
        "It is not the legacy VPN, but a complete solution for secure "
        "network access. It is designed to be easy to use and "
        "is fully open source.",
        textAlign: TextAlign.justify,
        style: _textStyle,
      ),
      Column(
        spacing: 16,
        children: [
          AdaptiveButton(
            autofocus: true,
            filled: true,
            onPressed: _nextPage,
            child: const Text("Get Started"),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "New to Cylonix?",
                style: _smallStyle,
              ),
              AdaptiveButton(
                padding: const EdgeInsets.only(left: 8),
                textButton: true,
                onPressed: _openWebsite,
                child: Text(
                  "Learn more",
                  style: _smallLinkStyle,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  TextStyle get _smallStyle {
    return TextStyle(
      fontSize: 12,
      color: isApple() ? CupertinoColors.label.resolveFrom(context) : null,
    );
  }

  TextStyle get _smallLinkStyle {
    return TextStyle(
      fontSize: 12,
      color: isApple() ? CupertinoColors.systemBlue.resolveFrom(context) : null,
    );
  }

  PageViewModel get _privacyPage {
    return _getPage(
      _policyInfoIcon,
      "Privacy",
      Text(
        "Cylonix collects your IP address, device name and model, "
        "OS version, your email address, name, and profile picture URL, "
        "log when you log in and out, and optionally the diagnostic "
        "information to help us diagnose issues. Your traffic is "
        "encrypted and routed through the Cylonix network, but we do not "
        "collect or store your traffic data. We do not sell your data to "
        "third parties. For more information, please read our "
        "Privacy Policy.",
        textAlign: TextAlign.justify,
        style: _textStyle,
      ),
      Column(
        children: [
          AdaptiveButton(
            autofocus: true,
            filled: true,
            onPressed: () {
              _privacyAgreed = true;
              _nextPage();
            },
            child: const Text("I Agree"),
          ),
          const SizedBox(height: 16),
          Text(
            "By using Cylonix, you agree to our",
            style: _smallStyle,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AdaptiveButton(
                padding: const EdgeInsets.all(0),
                textButton: true,
                onPressed: () {
                  _launchURL('https://manage.cylonix.io/terms-of-service');
                },
                child: Text(
                  "User Agreement",
                  style: _smallLinkStyle,
                ),
              ),
              Text(" and ", style: _smallStyle),
              AdaptiveButton(
                padding: const EdgeInsets.all(0),
                textButton: true,
                onPressed: () {
                  _launchURL('https://manage.cylonix.io/privacy-policy');
                },
                child: Text(
                  "Privacy Policy",
                  style: _smallLinkStyle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget get _logo {
    const logo = "lib/assets/images/cylonix_128.png";
    return Image.asset(logo, height: _topImageHeight, width: _topImageHeight);
  }

  PageViewModel get _donePage {
    return _getPage(
      _permissionsIcon,
      "Permissions",
      Column(
        spacing: 16,
        children: [
          Text(
            "Cylonix requires VPN permission to connect the devices and route "
            "the traffic to other devices in the virtual private network.",
            textAlign: TextAlign.justify,
            style: _textStyle,
          ),
          Text(
            "Cylonix also requests optional notification permission to "
            "notify you when receiving files or other events.",
            textAlign: TextAlign.justify,
            style: _textStyle,
          ),
        ],
      ),
      _doneButton,
    );
  }

  PageViewModel _getPage(
    Widget top,
    String title,
    Widget topBody,
    Widget bottomBody,
  ) {
    final isLongScreen = MediaQuery.of(context).size.height > 800;
    return PageViewModel(
      image: _topImage(top),
      title: title,
      decoration: PageDecoration(
        imageFlex: 1,
        bodyFlex: 3,
        titleTextStyle: isApple()
            ? TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.label.resolveFrom(context),
              )
            : const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
        titlePadding: EdgeInsets.only(
          top: isLongScreen ? 32 : 16,
        ),
      ),
      useRowInLandscape: true,
      bodyWidget: Container(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          margin: EdgeInsets.only(
            top: isLongScreen ? 64 : 16,
            left: 20,
            right: 20,
          ),
          child: Column(
            spacing: isLongScreen ? 32 : 16,
            children: [
              topBody,
              bottomBody,
              SizedBox(height: isLongScreen ? 64 : 32),
            ],
          ),
        ),
      ),
    );
  }

  List<PageViewModel> get _pages {
    return [
      _introPage,
      _privacyPage,
      _donePage,
    ];
  }
}
