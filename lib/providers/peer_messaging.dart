// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/peer_messaging.dart';
import '../services/peer_messaging_service.dart';
import 'ipn.dart';

final peerMessagingServiceProvider =
    StateNotifierProvider<PeerMessagingService, PeerMessagingState>((ref) {
  final service = PeerMessagingService(ref.watch(ipnServiceProvider));
  ref.onDispose(service.disposeService);
  return service;
});

final peerMessagingBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(peerMessagingServiceProvider.notifier).initialize();
});

final peerMessagingConversationsProvider =
    Provider<List<PeerMessagingConversation>>(
  (ref) => ref.watch(peerMessagingServiceProvider).conversations,
);

final peerMessagingUnreadCountProvider = Provider<int>((ref) {
  return ref
      .watch(peerMessagingConversationsProvider)
      .fold<int>(0, (sum, conversation) => sum + conversation.unreadCount);
});

final peerMessagingProxyProvider = Provider<PeerMessagingProxyInfo>(
  (ref) => ref.watch(peerMessagingServiceProvider).proxy,
);

final peerMessagingConversationProvider =
    Provider.family<PeerMessagingConversation?, String>((ref, conversationId) {
  for (final conversation in ref.watch(peerMessagingConversationsProvider)) {
    if (conversation.id == conversationId) {
      return conversation;
    }
  }
  return null;
});
