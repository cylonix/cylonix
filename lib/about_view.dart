import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'utils/utils.dart';
import 'widgets/adaptive_widgets.dart';

const _cylonixIntro =
    'Cylonix provides open source secure access service edge solutions. '
    'It uses WireGuard® technology as the mesh service, leveraging the '
    'Tailscale® design. For edge WireGuard aggregation nodes, it offers '
    'Cilium® based firewall services and VPP-based software defined WAN '
    'routing. The platform includes a Kubernetes-based open source '
    'deployment system.';

class AboutView extends ConsumerWidget {
  final VoidCallback? onNavigateBack;
  const AboutView({super.key, this.onNavigateBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return isApple()
        ? _buildCupertinoView(context)
        : _buildMaterialView(context);
  }

  Widget _buildCupertinoView(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: appleScaffoldBackgroundColor(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        automaticBackgroundVisibility: false,
        automaticallyImplyLeading: false,
        leading: onNavigateBack != null
            ? AppleBackButton(
                onPressed: onNavigateBack,
              )
            : null,
        middle: const Text('About'),
      ),
      child: Container(
        alignment: Alignment.topCenter,
        child: _buildContent(context, true),
      ),
    );
  }

  Widget _buildMaterialView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: onNavigateBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onNavigateBack,
              )
            : null,
        automaticallyImplyLeading: false,
        title: const Text('About'),
      ),
      body: Container(
        alignment: Alignment.topCenter,
        child: _buildContent(context, false),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isCupertino) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 800,
          ),
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  color: isCupertino
                      ? CupertinoColors.systemGrey6
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(
                    'lib/assets/images/cylonix_128.png',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cylonix',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildVersionText(context, isCupertino),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _cylonixIntro,
                  style: TextStyle(
                    fontSize: 14,
                    color: isCupertino
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              _buildLinks(context, isCupertino),
              const SizedBox(height: 20),
              Text(
                'WireGuard is a registered trademark of Jason A. Donenfeld. '
                'Tailscale is a registered trademark of Tailscale Inc. '
                'Cilium is a registered trademark of Isovalent Inc. '
                'All other trademarks are property of their respective owners.',
                style: TextStyle(
                  fontSize: 12,
                  color: isCupertino
                      ? CupertinoColors.secondaryLabel.resolveFrom(context)
                      : Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionText(BuildContext context, bool isCupertino) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '';
        return GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: version));
            _showCopiedToast(context, isCupertino);
          },
          child: Text(
            'Version $version',
            style: TextStyle(
              fontSize: 16,
              color: isCupertino
                  ? CupertinoColors.secondaryLabel.resolveFrom(context)
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLinks(BuildContext context, bool isCupertino) {
    final links = [
      //('Acknowledgements', 'https://cylonix.com/licenses'),
      ('Privacy Policy', 'https://manage.cylonix.io/privacy-policy'),
      ('Terms of Service', 'https://manage.cylonix.io/terms-of-service'),
    ];

    return Column(
      children: links.map((link) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _buildLinkButton(
            context,
            link.$1,
            link.$2,
            isCupertino,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLinkButton(
    BuildContext context,
    String title,
    String url,
    bool isCupertino,
  ) {
    if (isCupertino) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _launchURL(url),
        child: Text(title),
      );
    }
    return TextButton(
      onPressed: () => _launchURL(url),
      child: Text(title),
    );
  }

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  void _showCopiedToast(BuildContext context, bool isCupertino) {
    showAdaptiveToast(
      context,
      'Version copied to clipboard',
    );
  }
}
