// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/ipn.dart';
import 'models/peer_messaging.dart';
import 'providers/ipn.dart';
import 'providers/peer_messaging.dart';
import 'utils/utils.dart';
import 'widgets/adaptive_widgets.dart';
import 'widgets/share_peer_device_list.dart';

class PeerMessagingInboxView extends ConsumerWidget {
  final VoidCallback onNavigateBack;

  const PeerMessagingInboxView({
    super.key,
    required this.onNavigateBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(peerMessagingBootstrapProvider);
    final conversations = ref.watch(peerMessagingConversationsProvider);
    final proxy = ref.watch(peerMessagingProxyProvider);

    return AdaptiveScaffold(
      title: const Text('Peer Messages'),
      heroTag: 'peer-messaging-inbox',
      onGoBack: onNavigateBack,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            children: [
              const SizedBox(height: 32),
              const _ComposeCard(),
              if (isDesktop()) ...[
                const SizedBox(height: 16),
                _ProxyCard(proxy: proxy),
              ],
              const SizedBox(height: 16),
              if (conversations.isEmpty)
                const _EmptyState()
              else
                ...conversations.map(
                  (conversation) =>
                      _ConversationTile(conversation: conversation),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposeCard extends ConsumerWidget {
  const _ComposeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peers = ref.watch(peersProvider);
    final conversations = ref.watch(peerMessagingAllConversationsProvider);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start a new message',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    peers.isEmpty
                        ? 'Connect to your tailnet to message a peer.'
                        : 'Choose a peer and jump into an existing thread or create a new one.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: peers.isEmpty
                  ? null
                  : () => _showPeerPicker(
                        context,
                        ref,
                        conversations,
                      ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('New Message'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPeerPicker(
    BuildContext context,
    WidgetRef ref,
    List<PeerMessagingConversation> conversations,
  ) async {
    final selectedPeer = await showModalBottomSheet<Node>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: SizedBox(
            height: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Choose a peer',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        isApple() ? CupertinoIcons.xmark : Icons.close,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SharePeerDeviceList(
                    emptyMessage: 'No devices available to message',
                    searchHintText: 'Search name or OS…',
                    androidTvTitle: 'Select a device to start messaging',
                    onPeerTap: (peer) => () => Navigator.pop(context, peer),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (selectedPeer == null || !context.mounted) {
      return;
    }

    final existingConversation =
        conversations.cast<PeerMessagingConversation?>().firstWhere(
              (conversation) => conversation?.id == selectedPeer.stableID,
              orElse: () => null,
            );
    await ref.read(peerMessagingServiceProvider.notifier).ensureConversation(
          conversationId: selectedPeer.stableID,
          title: existingConversation?.title ?? selectedPeer.displayName,
          subtitle: existingConversation?.subtitle ??
              (selectedPeer.addresses.isNotEmpty
                  ? selectedPeer.addresses.first
                  : null) ??
              '',
        );
    if (context.mounted) {
      Navigator.pushNamed(
        context,
        '/peer-messaging/thread',
        arguments: {'conversationId': selectedPeer.stableID},
      );
    }
  }
}

class _ProxyCard extends StatefulWidget {
  final PeerMessagingProxyInfo proxy;

  const _ProxyCard({required this.proxy});

  @override
  State<_ProxyCard> createState() => _ProxyCardState();
}

class _ProxyCardState extends State<_ProxyCard> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final proxy = widget.proxy;
    return AdaptiveListSection.insetGrouped(
      header: const AdaptiveGroupedHeader("Local Proxy Status"),
      children: [
        AdaptiveListTile.notched(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          leading: Icon(
            proxy.isRunning ? Icons.cloud_done_outlined : Icons.cloud_off,
            color: proxy.isRunning ? Colors.green : Colors.orange,
          ),
          title: Text(
            proxy.isRunning
                ? 'Local peer messaging proxy is running'
                : 'Local peer messaging proxy is unavailable',
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            tooltip:
                _showDetails ? 'Hide connection info' : 'Show connection info',
            onPressed: () {
              setState(() {
                _showDetails = !_showDetails;
              });
            },
            icon: Icon(
              _showDetails ? Icons.info_outline : Icons.info_outline_rounded,
            ),
          ),
          subtitle: Text(
            'The Cylonix app must stay open for the peer messaging plugin to connect.',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_showDetails) ...[
          AdaptiveListTile(
              title: const Text('WebSocket'), subtitle: Text(proxy.url)),
          AdaptiveListTile(
            title: const Text('Auth token'),
            subtitle: Text(proxy.authToken),
            trailing: TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: proxy.authToken));
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  const SnackBar(
                    content: Text('Peer messaging auth token copied'),
                  ),
                );
              },
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Copy Token'),
            ),
          ),
        ],
        if (proxy.error != null) ...[
          AdaptiveListTile(
            title: const Text('Error'),
            subtitle: Text(
              proxy.error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final PeerMessagingConversation conversation;

  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tile = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: _supportsLongPressMenu
          ? (details) => _showConversationActions(
                context,
                ref,
                globalPosition: details.globalPosition,
              )
          : null,
      onSecondaryTapDown: _supportsSecondaryClickMenu
          ? (details) => _showConversationActions(
                context,
                ref,
                globalPosition: details.globalPosition,
              )
          : null,
      child: AdaptiveListTile.notched(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: const CircleAvatar(
          child: Icon(Icons.smart_toy_outlined),
        ),
        title: Text(conversation.title),
        subtitle: Text(
          conversation.preview.isEmpty
              ? 'No messages yet'
              : conversation.preview,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: conversation.unreadCount > 0
            ? CircleAvatar(
                radius: 12,
                child: Text(
                  '${conversation.unreadCount}',
                  style: const TextStyle(fontSize: 12),
                ),
              )
            : Text(
                _formatTimestamp(conversation.updatedAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/peer-messaging/thread',
            arguments: {'conversationId': conversation.id},
          );
        },
      ),
    );

    final content = _supportsSwipeActions
        ? Dismissible(
            key: ValueKey('conversation-${conversation.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              await _showConversationActions(context, ref);
              return false;
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.more_horiz),
            ),
            child: tile,
          )
        : tile;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
      child: content,
    );
  }

  bool get _supportsSecondaryClickMenu =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  bool get _supportsLongPressMenu => Platform.isAndroid || Platform.isIOS;

  bool get _supportsSwipeActions => Platform.isAndroid || Platform.isIOS;

  Future<void> _showConversationActions(BuildContext context, WidgetRef ref,
      {Offset? globalPosition}) async {
    final selected = _supportsSecondaryClickMenu && globalPosition != null
        ? await _showDesktopActionMenu(context, globalPosition)
        : await _showMobileActionSheet(context);

    if (selected == null || !context.mounted) {
      return;
    }

    if (selected == 'hide') {
      await ref
          .read(peerMessagingServiceProvider.notifier)
          .hideConversation(conversation.id);
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Hidden thread "${conversation.title}"')),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog.adaptive(
            title: const Text('Delete Local History'),
            content: Text(
              'Delete "${conversation.title}" and remove all messages stored in this thread on this device?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete History'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await ref
        .read(peerMessagingServiceProvider.notifier)
        .deleteConversation(conversation.id);
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
            content: Text('Deleted local history for "${conversation.title}"')),
      );
    }
  }

  Future<String?> _showDesktopActionMenu(
    BuildContext context,
    Offset globalPosition,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    return showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'hide',
          child: Text('Hide Thread'),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Text(
            'Delete Local History',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }

  Future<String?> _showMobileActionSheet(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Hide Thread'),
              onTap: () => Navigator.pop(context, 'hide'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              iconColor: Theme.of(context).colorScheme.error,
              textColor: Theme.of(context).colorScheme.error,
              title: const Text('Delete Local History'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
            ? local.hour - 12
            : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.mark_chat_unread_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              'No peer conversations yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Inbound peer messages and approval requests will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
