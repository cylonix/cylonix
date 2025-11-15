// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/ipn.dart';
import 'providers/settings.dart';
import 'utils/utils.dart';
import 'viewmodels/settings.dart';
import 'widgets/adaptive_widgets.dart';

class DNSSettingsView extends ConsumerWidget {
  final VoidCallback onBackToSettings;

  const DNSSettingsView({
    super.key,
    required this.onBackToSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isApple()) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('DNS Settings'),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.back),
            onPressed: onBackToSettings,
          ),
        ),
        child: _buildContext(context, ref),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('DNS Settings'),
        leading: AdaptiveButton(
          iconButton: true,
          child: const Icon(Icons.arrow_back),
          onPressed: onBackToSettings,
        ),
      ),
      body: _buildContext(context, ref),
    );
  }

  Widget _buildContext(BuildContext context, WidgetRef ref) {
    final dnsSettings = ref.watch(dnsSettingsProvider);
    final isLoading = ref.watch(dnsSettingsLoadingProvider);
    final resolvers = dnsSettings.dnsConfig?.resolvers ?? [];
    final domains = dnsSettings.dnsConfig?.domains ?? [];
    final routes = dnsSettings.dnsConfig?.routes ?? {};
    final corpDNS = ref.watch(corpDNSEnabledProvider);
    return LoadingIndicator(
      isLoading: isLoading,
      child: Container(
        alignment: Alignment.topCenter,
        child: Container(
          alignment: Alignment.topCenter,
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            children: [
              _buildStateSection(context, dnsSettings, ref),
              if (corpDNS && resolvers.isNotEmpty)
                _buildResolversSection(resolvers),
              if (corpDNS && domains.isNotEmpty) _buildDomainsSection(domains),
              if (corpDNS && routes.isNotEmpty) _buildRouteSection(routes),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateSection(
      BuildContext context, DNSSettings settings, WidgetRef ref) {
    return AdaptiveListSection.insetGrouped(
      children: [
        AdaptiveListTile(
          leading: Icon(
            settings.enablementState.icon,
            color: settings.enablementState.tint,
            size: 36,
          ),
          title: Text(
            settings.enablementState.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(settings.enablementState.caption),
        ),
        if (!settings.isDNSSettingsHidden) ...[
          AdaptiveSwitchListTile(
            title: const Text('Use Cylonix DNS'),
            value: settings.useCorpDNS,
            onChanged: (value) async {
              await ref.read(dnsSettingsProvider.notifier).toggleCorpDNS();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildResolversSection(List<Resolver> resolvers) {
    return AdaptiveListSection.insetGrouped(
      header: const AdaptiveGroupedHeader('Resolvers'),
      children: resolvers
          .map((resolver) => ClipboardValueTile(value: resolver.addr ?? ''))
          .toList(),
    );
  }

  Widget _buildDomainsSection(List<String> domains) {
    return AdaptiveListSection.insetGrouped(
      header: const AdaptiveGroupedHeader('Search Domains'),
      children:
          domains.map((domain) => ClipboardValueTile(value: domain)).toList(),
    );
  }

  Widget _buildRouteSection(Map<String, List<Resolver>?> routes) {
    final children = routes.entries
        .map((entry) {
          final name = entry.key;
          final resolvers = entry.value;
          if (resolvers == null || resolvers.isEmpty) {
            return null;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...resolvers.map(
                (resolver) => ClipboardValueTile(value: resolver.addr ?? ''),
              ),
            ],
          );
        })
        .nonNulls
        .toList();
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return AdaptiveListSection.insetGrouped(
      header: const AdaptiveGroupedHeader('Routes'),
      children: children,
    );
  }
}

class ClipboardValueTile extends StatelessWidget {
  final String value;

  const ClipboardValueTile({
    super.key,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveListTile(
      title: Text(value),
      trailing: AdaptiveButton(
        iconButton: true,
        child: const Icon(Icons.copy),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Copied to clipboard')),
          );
        },
      ),
    );
  }
}
