// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/ipn.dart';
import 'ping_view.dart';
import 'providers/ipn.dart';
import 'utils/utils.dart';
import 'viewmodels/peer_details.dart';
import 'widgets/adaptive_widgets.dart';

class PeerDetailsView extends ConsumerStatefulWidget {
  final int node;
  final VoidCallback? onNavigateBack;

  const PeerDetailsView({
    super.key,
    required this.node,
    this.onNavigateBack,
  });

  @override
  ConsumerState<PeerDetailsView> createState() => _PeerDetailsViewState();
}

class _PeerDetailsViewState extends ConsumerState<PeerDetailsView> {
  bool _showNodeJson = false;

  @override
  Widget build(BuildContext context) {
    final node = ref.watch(peerProvider(widget.node));
    final netmap = ref.watch(netmapProvider);
    final isPinging = ref.watch(isPingingProvider);

    if (node == null || netmap == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return isApple()
        ? _buildCupertinoScaffold(context, node, netmap, isPinging)
        : _buildMaterialScaffold(context, node, netmap, isPinging);
  }

  Widget _buildMaterialScaffold(
      BuildContext context, Node node, NetworkMap netmap, bool isPinging) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(node.displayName),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getConnectionColor(node, netmap),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getConnectionStatus(node, netmap),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (node.id != netmap.selfNode.id && (node.online ?? false))
            IconButton(
              icon: const Icon(Icons.timer),
              onPressed: () => _startPing(node),
              tooltip: 'Ping device',
            ),
        ],
        leading: widget.onNavigateBack != null
            ? BackButton(
                onPressed: () {
                  widget.onNavigateBack?.call();
                },
              )
            : null,
      ),
      body: _buildContent(context, node),
    );
  }

  Widget _buildCupertinoScaffold(
      BuildContext context, Node node, NetworkMap netmap, bool isPinging) {
    final title = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(node.displayName),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getConnectionColor(node, netmap),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getConnectionStatus(node, netmap),
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
    final leading = widget.onNavigateBack != null
        ? AppleBackButton(
            onPressed: () {
              widget.onNavigateBack?.call();
            },
          )
        : null;
    final trailing = (node.id != netmap.selfNode.id && (node.online ?? false))
        ? CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.timer),
            onPressed: () => _startPing(node),
          )
        : null;
    return CupertinoPageScaffold(
      backgroundColor: appleScaffoldBackgroundColor(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        automaticBackgroundVisibility: false,
        transitionBetweenRoutes: false,
        heroTag: "PeerDetails/${node.id}",
        middle: title,
        trailing: trailing,
        leading: leading,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _buildContent(context, node),
        ),
      ),
    );
  }

  Map<String, String> _getInfos(Node node) {
    final os = node.hostinfo?.os;
    final m = <String, String>{};
    if (os != null) m["os"] = os;
    m["Key expiry"] = node.keyDoesNotExpire
        ? "Key does not expire"
        : GoTimeUtil.keyExpiryFromGoTime(node.keyExpiry);
    m['Key base64'] = node.keyBase64;
    if (node.isJailed ?? false) {
      m['Jailed'] = 'Cannot initiate outbound connections';
    }
    if (node.isExitNode) {
      m['Exit Node'] = 'Capable of being an exit node';
    }
    return m;
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showAdaptiveToast(context, 'Address copied to clipboard');
  }

  Widget _buildAddressRow(BuildContext context, DisplayAddress address) {
    return AdaptiveListTile(
      leading: switch (address.type) {
        AddressType.v4 => const Icon(CupertinoIcons.globe),
        AddressType.v6 => const Icon(CupertinoIcons.globe),
        AddressType.magicDNS => const Icon(CupertinoIcons.doc_on_doc),
      },
      title: Text(
        address.typeString,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(address.address),
      trailing: _copyButton(address.address),
    );
  }

  Widget _copyButton(String text) {
    return AdaptiveButton(
      padding: EdgeInsets.zero,
      child: Icon(
        isApple() ? CupertinoIcons.doc_on_doc : Icons.copy,
        size: 20,
      ),
      onPressed: () => _copy(text),
    );
  }

  Widget _buildValue(BuildContext context, String label, String value) {
    return AdaptiveListTile(
      leading: switch (label) {
        'os' => const Icon(CupertinoIcons.device_desktop),
        'Key expiry' => const Icon(CupertinoIcons.clock),
        'Key base64' => const Icon(Icons.key_outlined),
        'Jailed' => const Icon(
            CupertinoIcons.lock_shield,
            color: CupertinoColors.systemRed,
          ),
        'Exit Node' => const Icon(CupertinoIcons.arrow_up_right_circle),
        _ => const Icon(CupertinoIcons.info),
      },
      title: Text(label),
      subtitle: Text(value, overflow: TextOverflow.ellipsis),
      trailing: switch (label) {
        'Key base64' => _copyButton(value),
        _ => null,
      },
    );
  }

  Widget _buildContent(BuildContext context, Node node) {
    final List<Widget> infos = [];
    _getInfos(node).forEach(
      (key, value) => infos.add(_buildValue(context, key, value)),
    );

    return ListView(
      children: [
        const SizedBox(height: 32),
        AdaptiveListSection.insetGrouped(
          header: _buildSectionHeader(context, 'Addresses'),
          children: [
            ...node.displayAddresses
                .map((addr) => _buildAddressRow(context, addr)),
          ],
        ),
        AdaptiveListSection.insetGrouped(
          children: infos,
        ),
        AdaptiveListSection.insetGrouped(
          header: _buildSectionHeader(context, 'Node Data'),
          footer: Text(
            "View Node Data in JSON format for troubleshooting.",
            style: adaptiveGroupedFooterStyle(context),
          ),
          children: [
            AdaptiveListTile(
              leading: const Icon(CupertinoIcons.info_circle),
              title: Text(
                _showNodeJson ? "Close" : "Open",
              ),
              trailing: Icon(
                _showNodeJson
                    ? CupertinoIcons.chevron_up
                    : CupertinoIcons.chevron_down,
              ),
              onTap: () => setState(
                () {
                  _showNodeJson = !_showNodeJson;
                },
              ),
            ),
            if (_showNodeJson) ...[
              _buildNodeJson(context, node),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildNodeJson(BuildContext context, Node node) {
    const encoder = JsonEncoder.withIndent('  ');
    final prettyJson = encoder.convert(node.toJson());

    return SelectableText(
      prettyJson,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return AdaptiveGroupedHeader(title);
  }

  void _startPing(Node node) async {
    ref.read(peerDetailsViewModelProvider.notifier).startPing(node);
    var height = MediaQuery.of(context).size.height * 0.7;
    if (height < 380) {
      height = 380;
    }
    await AdaptiveModalPopup(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: PingView(peer: node),
      ),
    ).show(context);
  }

  bool _isNodeOnline(Node node, Node selfNode) {
    final vpnState = ref.watch(ipnStateProvider)?.vpnState;
    return node.online == true ||
        (node.stableID == selfNode.stableID) && vpnState == VpnState.connected;
  }

  Color _getConnectionColor(Node node, NetworkMap netmap) {
    if (_isNodeOnline(node, netmap.selfNode)) {
      return isApple() ? CupertinoColors.systemGreen : Colors.green;
    }
    return isApple() ? CupertinoColors.systemGrey : Colors.grey;
  }

  String _getConnectionStatus(Node node, NetworkMap netmap) {
    return _isNodeOnline(node, netmap.selfNode) ? 'Connected' : 'Disconnected';
  }
}
