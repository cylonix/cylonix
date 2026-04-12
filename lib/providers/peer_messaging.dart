// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ipn.dart';
import '../models/peer_messaging.dart';
import '../services/peer_messaging_service.dart';
import 'ipn.dart';

final peerMessagingServiceProvider =
    StateNotifierProvider<PeerMessagingService, PeerMessagingState>((ref) {
  final service = PeerMessagingService(ref.watch(ipnServiceProvider), ref);
  ref.listen<LoginProfile?>(currentLoginProfileProvider, (previous, next) {
    unawaited(service.onCurrentProfileChanged(next));
  });
  ref.onDispose(service.disposeService);
  return service;
});

final peerMessagingBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(peerMessagingServiceProvider.notifier).initialize();
});

final peerMessagingConversationsProvider =
    Provider<List<PeerMessagingConversation>>(
  (ref) {
    final currentProfileId = ref.watch(currentLoginProfileProvider)?.id ?? '';
    return ref
        .watch(peerMessagingServiceProvider)
        .conversationsForProfile(currentProfileId)
        .where((conversation) => !conversation.hidden)
        .toList();
  },
);

final peerMessagingAllConversationsProvider =
    Provider<List<PeerMessagingConversation>>(
  (ref) {
    final currentProfileId = ref.watch(currentLoginProfileProvider)?.id ?? '';
    return ref
        .watch(peerMessagingServiceProvider)
        .conversationsForProfile(currentProfileId);
  },
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
  for (final conversation in ref.watch(peerMessagingAllConversationsProvider)) {
    if (conversation.id == conversationId) {
      return conversation;
    }
  }
  return null;
});
