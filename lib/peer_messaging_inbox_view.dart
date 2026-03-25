// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/peer_messaging.dart';
import 'providers/peer_messaging.dart';
import 'widgets/adaptive_widgets.dart';

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
      onGoBack: onNavigateBack,
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _ProxyCard(proxy: proxy),
          const SizedBox(height: 16),
          if (conversations.isEmpty)
            const _EmptyState()
          else
            ...conversations.map(
              (conversation) => _ConversationTile(conversation: conversation),
            ),
        ],
      ),
    );
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
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: AdaptiveListTile(
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
