// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ipn.dart';
import '../providers/share_file.dart' as share_file;
import '../viewmodels/state_notifier.dart';

class SharePeerDeviceList extends ConsumerStatefulWidget {
  final String emptyMessage;
  final String searchHintText;
  final String androidTvTitle;
  final Widget Function(BuildContext context, Node peer)? trailingBuilder;
  final VoidCallback Function(Node peer)? onPeerTap;

  const SharePeerDeviceList({
    super.key,
    required this.emptyMessage,
    required this.searchHintText,
    required this.androidTvTitle,
    this.trailingBuilder,
    this.onPeerTap,
  });

  @override
  ConsumerState<SharePeerDeviceList> createState() =>
      _SharePeerDeviceListState();
}

class _SharePeerDeviceListState extends ConsumerState<SharePeerDeviceList> {
  final _searchController = TextEditingController();
  bool _showOnlineOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAndroidTV = ref.watch(isAndroidTVProvider);
    final filters = (
      onlineOnly: _showOnlineOnly,
      searchQuery: _searchController.text,
    );
    final peers = ref.watch(share_file.filteredPeersProvider(filters));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: isAndroidTV
                    ? Text(widget.androidTvTitle)
                    : TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: widget.searchHintText,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Checkbox(
                    value: _showOnlineOnly,
                    onChanged: (value) =>
                        setState(() => _showOnlineOnly = value ?? false),
                  ),
                  const Text('Online Only'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: peers.isEmpty
              ? Center(child: Text(widget.emptyMessage))
              : ListView.builder(
                  itemCount: peers.length,
                  itemBuilder: (context, index) {
                    final peer = peers[index];
                    return _SharePeerRow(
                      peer: peer,
                      trailing: widget.trailingBuilder?.call(context, peer),
                      onTap: widget.onPeerTap != null
                          ? widget.onPeerTap!(peer)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SharePeerRow extends StatelessWidget {
  final Node peer;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SharePeerRow({
    required this.peer,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 4,
        backgroundColor: peer.online ?? false ? Colors.green : Colors.grey,
      ),
      title: Text(
        peer.displayName.split('.').first,
        style: TextStyle(
          fontWeight:
              peer.online ?? false ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(_getOSIcon(peer.hostinfo?.os), size: 16),
          const SizedBox(width: 4),
          if (peer.hostinfo?.os != null) Text(peer.hostinfo!.os!),
        ],
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  IconData _getOSIcon(String? os) {
    if (os == null) return Icons.devices;
    final osLower = os.toLowerCase();
    if (osLower.contains('mac')) return Icons.desktop_mac_outlined;
    if (osLower.contains('windows')) return Icons.desktop_windows;
    if (osLower.contains('linux')) return Icons.computer;
    if (osLower.contains('ios')) return Icons.phone_iphone;
    if (osLower.contains('android')) return Icons.phone_android;
    return Icons.devices;
  }
}
