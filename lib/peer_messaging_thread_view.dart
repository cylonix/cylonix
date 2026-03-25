// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/peer_messaging.dart';
import 'providers/peer_messaging.dart';
import 'utils/utils.dart';
import 'widgets/adaptive_widgets.dart';

class PeerMessagingThreadView extends ConsumerStatefulWidget {
  final String conversationId;
  final VoidCallback? onNavigateBack;

  const PeerMessagingThreadView({
    super.key,
    required this.conversationId,
    this.onNavigateBack,
  });

  @override
  ConsumerState<PeerMessagingThreadView> createState() =>
      _PeerMessagingThreadViewState();
}

class _PeerMessagingThreadViewState
    extends ConsumerState<PeerMessagingThreadView> {
  final _controller = TextEditingController();

  InputBorder get _inputBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(isApple() ? 20 : 12),
        borderSide: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(peerMessagingServiceProvider.notifier)
          .markConversationRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(peerMessagingBootstrapProvider);
    final conversation =
        ref.watch(peerMessagingConversationProvider(widget.conversationId));
    if (conversation == null) {
      return AdaptiveScaffold(
        title: const Text('Peer Conversation'),
        onGoBack: widget.onNavigateBack,
        body: const Center(child: Text('Conversation not found')),
      );
    }

    return AdaptiveScaffold(
      title: Text(conversation.title),
      onGoBack: widget.onNavigateBack,
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              reverse: false,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) => _MessageBubble(
                message: conversation.messages[index],
                onApproval: (approved) async {
                  await ref
                      .read(peerMessagingServiceProvider.notifier)
                      .submitApproval(
                        conversationId: conversation.id,
                        approvalId:
                            conversation.messages[index].approvalId ?? '',
                        approved: approved,
                      );
                },
                onMenuSelection: (action, title) async {
                  await ref
                      .read(peerMessagingServiceProvider.notifier)
                      .submitMenuSelection(
                        conversationId: conversation.id,
                        messageId: conversation.messages[index].id,
                        action: action,
                        title: title,
                      );
                },
              ),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: conversation.messages.length,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: TextField(
                              controller: _controller,
                              minLines: 3,
                              maxLines: 8,
                              textInputAction: TextInputAction.newline,
                              decoration: InputDecoration(
                                hintText: 'Reply…',
                                alignLabelWithHint: true,
                                contentPadding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  64,
                                  18,
                                ),
                                border: _inputBorder,
                                enabledBorder: _inputBorder,
                                focusedBorder: _inputBorder.copyWith(
                                  borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 1.4,
                                  ),
                                ),
                                filled: true,
                                fillColor: isApple()
                                    ? CupertinoColors
                                        .secondarySystemGroupedBackground
                                        .resolveFrom(context)
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(right: 10, bottom: 10),
                            child: FilledButton(
                              onPressed: () async {
                                final text = _controller.text.trim();
                                if (text.isEmpty) return;
                                await ref
                                    .read(peerMessagingServiceProvider.notifier)
                                    .sendTextMessage(
                                      conversation.id,
                                      text,
                                      conversationTitle: conversation.title,
                                    );
                                _controller.clear();
                              },
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(40, 40),
                                maximumSize: const Size(40, 40),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    isApple() ? 18 : 12,
                                  ),
                                ),
                              ),
                              child: Icon(
                                isApple()
                                    ? CupertinoIcons.arrow_up
                                    : Icons.arrow_upward,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final PeerMessagingMessage message;
  final Future<void> Function(bool approved) onApproval;
  final Future<void> Function(String action, String title) onMenuSelection;

  const _MessageBubble({
    required this.message,
    required this.onApproval,
    required this.onMenuSelection,
  });

  @override
  Widget build(BuildContext context) {
    final isLocal = message.metadata['from_peer_id'] == null &&
        (message.role == PeerMessagingMessageRole.user ||
            message.role == PeerMessagingMessageRole.system);
    final bubbleColor = isLocal
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.secondaryContainer;
    final align = isLocal ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: align,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(message.text),
                  if (message.kind ==
                          PeerMessagingMessageKind.approvalRequest &&
                      message.deliveryStatus !=
                          PeerMessagingDeliveryStatus.failed &&
                      message.approvalId != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => onApproval(true),
                          child: const Text('Approve'),
                        ),
                        OutlinedButton(
                          onPressed: () => onApproval(false),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  ],
                  if (message.kind == PeerMessagingMessageKind.menuRequest &&
                      message.deliveryStatus !=
                          PeerMessagingDeliveryStatus.failed &&
                      message.menuOptions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in message.menuOptions)
                          OutlinedButton(
                            onPressed: () =>
                                onMenuSelection(option.action, option.title),
                            child: Text(option.title),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${_timestamp(message.createdAt)} · ${message.deliveryStatus.value}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String get _label {
    switch (message.kind) {
      case PeerMessagingMessageKind.taskSummary:
        return 'Task Summary';
      case PeerMessagingMessageKind.approvalRequest:
        return 'Approval Requested';
      case PeerMessagingMessageKind.approvalResponse:
        return 'Approval Response';
      case PeerMessagingMessageKind.menuRequest:
        return 'Menu Options';
      case PeerMessagingMessageKind.menuResponse:
        return (message.metadata['selected_title'] as String?) ??
            (message.metadata['selected_action'] as String?) ??
            'Menu Selection';
      case PeerMessagingMessageKind.text:
        if (message.metadata['from_peer_id'] != null) {
          return (message.metadata['from_peer_name'] as String?) ?? 'Peer';
        }
        return 'You';
    }
  }

  String _timestamp(DateTime value) {
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
