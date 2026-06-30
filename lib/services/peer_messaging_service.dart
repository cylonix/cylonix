// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/ipn.dart';
import '../models/peer_messaging.dart';
import '../providers/ipn.dart';
import '../utils/logger.dart';
import 'desktop_notifications.dart';
import 'ipn.dart';

class PeerMessagingService extends StateNotifier<PeerMessagingState> {
  PeerMessagingService(this._ipnService, this._ref)
      : super(PeerMessagingState.initial());

  static const _protocolVersion = 'v1';
  static const _preferredListenPort = 50321;
  static const _storageFolderName = 'peer_messaging';
  static const _legacyStorageFolderName = 'openclaw';
  static const _storageFileName = 'state.json';
  static const _authTokenKey = 'peer_messaging_proxy_auth_token';
  static const _legacyAuthTokenKey = 'openclaw_proxy_auth_token';
  static final _logger = Logger(tag: 'PeerMessaging');

  final IpnService _ipnService;
  final Ref _ref;
  final _clients = <WebSocket>{};
  final _handledBridgeEventKeys = <String>{};

  StreamSubscription<PeerMessagingEvent>? _bridgeSubscription;
  StreamSubscription<IpnNotification>? _notificationSubscription;
  HttpServer? _server;
  File? _stateFile;
  bool _initialized = false;
  String _activeProfileId = '';
  List<AwaitingFile> _lastWaitingFiles = const [];
  final Map<String, String> _pendingAutoSavedPaths = {};

  // Active-thread tracking: while one or more peer-message threads are visible
  // in the UI, we tell the daemon to keep their network paths warm so the next
  // outbound message doesn't pay XRay+DERP+WG+TCP+HTTP cold-start latency.
  // Multiple windows / split-screen support is handled by counting registrations.
  final Map<String, int> _activeThreadRefs = {};
  Timer? _activePeersHeartbeatTimer;
  static const _activePeersHeartbeatInterval = Duration(seconds: 60);

  // Per-peer warm status reported by the daemon (warm_status events). UI
  // widgets read this via warmStatusProvider; the service is the source of
  // truth and emits a stream when entries change.
  final Map<String, PeerMessagingWarmStatus> _warmStatus = {};
  final _warmStatusController =
      StreamController<Map<String, PeerMessagingWarmStatus>>.broadcast();
  Map<String, PeerMessagingWarmStatus> get warmStatusSnapshot =>
      Map.unmodifiable(_warmStatus);
  Stream<Map<String, PeerMessagingWarmStatus>> get warmStatusStream =>
      _warmStatusController.stream;

  // Tracks the previously-seen IPN state so we can detect the
  // disconnected-then-Running transition and re-push the active-peer set
  // immediately, without waiting up to 60s for the heartbeat.
  int? _lastSeenIpnState;

  bool get _supportsLocalProxy =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final storedState = await _loadState();
    _activeProfileId = await _resolveCurrentProfileId();
    final migratedState = _adoptLegacyConversations(
      _rewriteLegacyAttachmentPaths(storedState),
      profileId: _activeProfileId,
    );
    final normalizedState = _mergeDuplicateConversations(migratedState);
    final authToken = await _loadOrCreateAuthToken();
    state = normalizedState.copyWith(
      initialized: true,
      proxy: normalizedState.proxy.copyWith(
        authToken: authToken,
        url: _proxyUrl,
      ),
    );

    _bridgeSubscription = _ipnService.peerMessagingEventStream
        .listen(_handleBridgeEventFromStream);
    _notificationSubscription =
        _ipnService.notificationStream.listen(_handleIpnNotification);

    for (final event in _ipnService.takePendingPeerMessagingEvents()) {
      await _handleBridgeEventFromStream(event);
    }

    await _ipnService.replayPendingPeerMessageEvents();

    await _consumeAutoSavedAttachmentPaths();
    await _startProxyServer();
    await _persistState();
  }

  Future<void> onCurrentProfileChanged(LoginProfile? profile) async {
    final nextProfileId = profile?.id ?? '';
    if (nextProfileId == _activeProfileId) {
      return;
    }
    _activeProfileId = nextProfileId;
    final migratedState = _mergeDuplicateConversations(
      _adoptLegacyConversations(state, profileId: nextProfileId),
    );
    if (!identical(migratedState, state)) {
      state = migratedState;
      await _persistState();
    }
    await _broadcast(_syncSnapshotEvent());
  }

  Future<void> replayPendingMessages() async {
    if (!_initialized) {
      return;
    }
    await _ipnService.replayPendingPeerMessageEvents();
  }

  Future<void> disposeService() async {
    await _bridgeSubscription?.cancel();
    await _notificationSubscription?.cancel();
    _activePeersHeartbeatTimer?.cancel();
    _activePeersHeartbeatTimer = null;
    _activeThreadRefs.clear();
    _warmStatus.clear();
    await _warmStatusController.close();
    try {
      await _ipnService.clearActivePeers();
    } catch (_) {
      // Best effort — daemon will time out the global session anyway.
    }
    for (final client in _clients.toList()) {
      await client.close();
    }
    _clients.clear();
    await _server?.close(force: true);
  }

  // registerActiveThread is called by a thread view when it becomes visible.
  // Refcounted so multiple simultaneous opens of the same conversation (e.g.
  // re-opens during navigation transitions) don't drop the warm state.
  Future<void> registerActiveThread(String peerRef) async {
    if (peerRef.isEmpty) return;
    final wasEmpty = _activeThreadRefs.isEmpty;
    _activeThreadRefs.update(peerRef, (n) => n + 1, ifAbsent: () => 1);
    try {
      await _ipnService.setActivePeers(_activeThreadRefs.keys.toList());
    } catch (e) {
      _logger.w('setActivePeers failed: $e');
    }
    if (wasEmpty && _activeThreadRefs.isNotEmpty) {
      _activePeersHeartbeatTimer ??=
          Timer.periodic(_activePeersHeartbeatInterval, (_) {
        try {
          // For HTTP-LocalAPI platforms this is a cheap heartbeat frame.
          // For method-channel platforms _ipnService re-asserts the set so
          // the daemon's idle watchdog doesn't expire.
          _ipnService.sendActivePeersHeartbeat();
          _ipnService.setActivePeers(_activeThreadRefs.keys.toList());
        } catch (e) {
          _logger.d('active-peers heartbeat failed: $e');
        }
      });
    }
  }

  Future<void> unregisterActiveThread(String peerRef) async {
    if (peerRef.isEmpty) return;
    final n = _activeThreadRefs[peerRef];
    if (n == null) return;
    if (n > 1) {
      _activeThreadRefs[peerRef] = n - 1;
      return;
    }
    _activeThreadRefs.remove(peerRef);
    // Drop stale warm-status entry; the daemon stops emitting events for
    // peers we no longer claim, so it would otherwise stay forever.
    if (_warmStatus.remove(peerRef) != null) {
      _warmStatusController.add(warmStatusSnapshot);
    }
    if (_activeThreadRefs.isEmpty) {
      _activePeersHeartbeatTimer?.cancel();
      _activePeersHeartbeatTimer = null;
      try {
        await _ipnService.clearActivePeers();
      } catch (e) {
        _logger.d('clearActivePeers failed: $e');
      }
    } else {
      try {
        await _ipnService.setActivePeers(_activeThreadRefs.keys.toList());
      } catch (e) {
        _logger.d('setActivePeers (after unregister) failed: $e');
      }
    }
  }

  // Called from the app lifecycle observer when the app goes to background.
  // Drops the active-peer set so we don't burn battery on warm pings while the
  // user isn't looking. The thread views remain in the widget tree so we keep
  // the refcount; suspendActivePeers/resumeActivePeers only touch the daemon.
  Future<void> suspendActivePeers() async {
    _activePeersHeartbeatTimer?.cancel();
    _activePeersHeartbeatTimer = null;
    try {
      await _ipnService.clearActivePeers();
    } catch (_) {}
  }

  // _reassertActivePeers is called when the IPN backend transitions back into
  // Running after a disconnect. The daemon's previous active-peer set was
  // discarded with the LocalBackend, so push the current claim immediately
  // instead of waiting up to 60s for the next heartbeat.
  Future<void> _reassertActivePeers() async {
    if (_activeThreadRefs.isEmpty) return;
    try {
      await _ipnService.setActivePeers(_activeThreadRefs.keys.toList());
    } catch (e) {
      _logger.d('reassertActivePeers failed: $e');
    }
  }

  Future<void> resumeActivePeers() async {
    if (_activeThreadRefs.isEmpty) return;
    try {
      await _ipnService.setActivePeers(_activeThreadRefs.keys.toList());
    } catch (e) {
      _logger.d('resumeActivePeers failed: $e');
      return;
    }
    _activePeersHeartbeatTimer ??=
        Timer.periodic(_activePeersHeartbeatInterval, (_) {
      try {
        _ipnService.sendActivePeersHeartbeat();
        _ipnService.setActivePeers(_activeThreadRefs.keys.toList());
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    disposeService();
    super.dispose();
  }

  Future<void> markConversationRead(String conversationId) async {
    final profileId = await _requireCurrentProfileId();
    final updated = state.conversations.map((conversation) {
      if (!_matchesConversation(
        conversation,
        conversationId: conversationId,
        profileId: profileId,
      )) {
        return conversation;
      }
      return conversation.copyWith(unreadCount: 0);
    }).toList();
    state = state.copyWith(conversations: _sortConversations(updated));
    await _persistState();
  }

  Future<void> sendTextMessage(
    String conversationId,
    String text, {
    String? conversationTitle,
    String? deliveryPolicy,
    List<PeerMessagingMenuOption> menuOptions = const [],
    List<PeerMessagingAttachment> attachments = const [],
    String? replyToMessageId,
  }) async {
    final profileId = await _requireCurrentProfileId();
    conversationId = _canonicalConversationId(conversationId);
    final now = DateTime.now().toUtc();
    final messageId = const Uuid().v4();
    final normalizedText = text.trim();
    final messageAttachments = attachments
        .map(
          (item) => PeerMessagingAttachment(
            id: item.id,
            transferId: item.transferId ?? item.id,
            name: item.name,
            size: item.size,
            mimeType: item.mimeType,
          ),
        )
        .toList();
    final attachmentMetadata =
        messageAttachments.map((item) => item.toJson()).toList();
    final message = PeerMessagingMessage(
      id: messageId,
      conversationId: conversationId,
      role: PeerMessagingMessageRole.user,
      kind: menuOptions.isNotEmpty
          ? PeerMessagingMessageKind.menuRequest
          : messageAttachments.isNotEmpty && normalizedText.isEmpty
              ? PeerMessagingMessageKind.file
              : PeerMessagingMessageKind.text,
      deliveryStatus: PeerMessagingDeliveryStatus.pending,
      text: normalizedText,
      createdAt: now,
      replyToMessageId: replyToMessageId,
      menuOptions: menuOptions,
      attachments: messageAttachments,
      metadata: {
        if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
        if (attachmentMetadata.isNotEmpty) 'attachments': attachmentMetadata,
      },
    );
    _upsertConversationMessage(
      profileId,
      conversationId,
      message,
      title: conversationTitle ?? 'Peer Conversation',
      incrementUnread: false,
    );

    final payload = {
      'peer_id': conversationId,
      'conversation_id': conversationId,
      'message': message.toJson(),
      if (conversationTitle != null) 'conversation_title': conversationTitle,
      if ((deliveryPolicy ?? '').trim().isNotEmpty)
        'delivery_policy': deliveryPolicy!.trim(),
    };

    await _sendOutgoingMessage(
      profileId: profileId,
      conversationId: conversationId,
      messageId: messageId,
      payload: payload,
      attachments: attachments,
    );
  }

  Future<void> resendFailedMessage({
    required String conversationId,
    required String messageId,
  }) async {
    final profileId = await _requireCurrentProfileId();
    conversationId = _canonicalConversationId(conversationId);
    final existingMessage = _findMessage(
      profileId: profileId,
      conversationId: conversationId,
      messageId: messageId,
    );
    if (existingMessage == null) {
      throw Exception('Message not found');
    }
    if (existingMessage.deliveryStatus != PeerMessagingDeliveryStatus.failed) {
      throw Exception('Only failed messages can be sent again');
    }
    if (existingMessage.role != PeerMessagingMessageRole.user) {
      throw Exception('Only outgoing messages can be sent again');
    }

    await _updateMessage(
      profileId: profileId,
      conversationId: conversationId,
      messageId: messageId,
      transform: (current) => current.copyWith(
        deliveryStatus: PeerMessagingDeliveryStatus.pending,
        failureMessage: null,
        metadata: {...current.metadata}..remove('failure_message'),
      ),
    );

    final retryMessage = _findMessage(
      profileId: profileId,
      conversationId: conversationId,
      messageId: messageId,
    );
    if (retryMessage == null) {
      throw Exception('Message not found after retry reset');
    }

    final payload = {
      'peer_id': conversationId,
      'conversation_id': conversationId,
      'message': retryMessage.toJson(),
      if ((_findConversationTitle(
                profileId: profileId,
                conversationId: conversationId,
              ) ??
              '')
          .isNotEmpty)
        'conversation_title': _findConversationTitle(
          profileId: profileId,
          conversationId: conversationId,
        ),
    };

    await _sendOutgoingMessage(
      profileId: profileId,
      conversationId: conversationId,
      messageId: messageId,
      payload: payload,
      attachments: retryMessage.attachments,
    );
  }

  /// Re-sends the content of an existing outgoing message as a brand-new
  /// message. Unlike [resendFailedMessage] (which retries a failed message in
  /// place), this works for any already-sent message and leaves the original
  /// in the thread.
  Future<void> sendMessageAgain({
    required String conversationId,
    required String messageId,
  }) async {
    final profileId = await _requireCurrentProfileId();
    conversationId = _canonicalConversationId(conversationId);
    final existing = _findMessage(
      profileId: profileId,
      conversationId: conversationId,
      messageId: messageId,
    );
    if (existing == null) {
      throw Exception('Message not found');
    }
    if (existing.role != PeerMessagingMessageRole.user) {
      throw Exception('Only outgoing messages can be sent again');
    }
    await sendTextMessage(
      conversationId,
      existing.text,
      conversationTitle: _findConversationTitle(
        profileId: profileId,
        conversationId: conversationId,
      ),
      attachments: existing.attachments,
    );
  }

  Future<void> updateAttachmentPath({
    required String conversationId,
    required String messageId,
    required String attachmentId,
    required String resolvedPath,
  }) async {
    final profileId = await _requireCurrentProfileId();
    conversationId = _canonicalConversationId(conversationId);
    if (resolvedPath.isEmpty) {
      return;
    }

    await _updateMessage(
      profileId: profileId,
      conversationId: conversationId,
      messageId: messageId,
      transform: (current) {
        var changed = false;
        final attachments = current.attachments.map((attachment) {
          if (attachment.id != attachmentId) {
            return attachment;
          }
          if (attachment.path == resolvedPath) {
            return attachment;
          }
          changed = true;
          return attachment.copyWith(path: resolvedPath);
        }).toList();
        if (!changed) {
          return current;
        }
        return current.copyWith(
          attachments: attachments,
          metadata: {
            ...current.metadata,
            'attachments': attachments.map((item) => item.toJson()).toList(),
          },
        );
      },
    );
  }

  Future<void> ensureConversation({
    required String conversationId,
    required String title,
    String subtitle = '',
  }) async {
    final profileId = await _requireCurrentProfileId();
    conversationId = _canonicalConversationId(conversationId);
    _upsertConversation(
      profileId,
      conversationId,
      title: title,
      subtitle: subtitle,
      updatedAt: DateTime.now().toUtc(),
    );
    await _persistState();
  }

  Future<void> hideConversation(String conversationId) async {
    final profileId = await _requireCurrentProfileId();
    conversationId = _canonicalConversationId(conversationId);
    final nextConversations = state.conversations.map((conversation) {
      if (!_matchesConversation(
        conversation,
        conversationId: conversationId,
        profileId: profileId,
      )) {
        return conversation;
      }
      return conversation.copyWith(hidden: true);
    }).toList();
    state =
        state.copyWith(conversations: _sortConversations(nextConversations));
    await _persistState();
  }

  Future<void> deleteConversation(
    String conversationId, {
    bool broadcast = true,
  }) async {
    final profileId = await _requireCurrentProfileId();
    conversationId = _canonicalConversationId(conversationId);
    await _deleteConversationForProfile(
      profileId: profileId,
      conversationId: conversationId,
      broadcast: broadcast,
    );
  }

  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
    bool broadcast = true,
  }) async {
    final profileId = await _requireCurrentProfileId();
    conversationId = _canonicalConversationId(conversationId);
    await _deleteMessageForProfile(
      profileId: profileId,
      conversationId: conversationId,
      messageId: messageId,
      broadcast: broadcast,
    );
  }

  Future<void> _deleteMessageForProfile({
    required String profileId,
    required String conversationId,
    required String messageId,
    required bool broadcast,
  }) async {
    final conversations = state.conversations.map((conversation) {
      if (!_matchesConversation(
        conversation,
        conversationId: conversationId,
        profileId: profileId,
      )) {
        return conversation;
      }

      final messages = conversation.messages
          .where((message) => message.id != messageId)
          .toList();
      final updatedAt = messages.isNotEmpty
          ? messages.last.createdAt
          : conversation.updatedAt;
      final nextUnread = conversation.unreadCount > messages.length
          ? messages.length
          : conversation.unreadCount;
      return conversation.copyWith(
        messages: messages,
        updatedAt: updatedAt,
        unreadCount: nextUnread,
      );
    }).toList();

    state = state.copyWith(conversations: _sortConversations(conversations));
    await _persistState();
    if (broadcast) {
      await _broadcast(
        PeerMessagingEvent(
          version: _protocolVersion,
          type: PeerMessagingEventType.messageDeleted,
          conversationId: conversationId,
          messageId: messageId,
          timestamp: DateTime.now().toUtc(),
          payload: {
            'message_id': messageId,
            'profile_id': profileId,
          },
        ),
      );
    }
  }

  Future<void> submitApproval({
    required String conversationId,
    required String approvalId,
    required bool approved,
    String? note,
  }) async {
    final profileId = await _requireCurrentProfileId();
    conversationId = _canonicalConversationId(conversationId);
    final action = PeerMessagingApprovalAction(
      id: const Uuid().v4(),
      title: approved ? 'Approved' : 'Rejected',
      approved: approved,
      note: note,
    );
    final message = PeerMessagingMessage(
      id: const Uuid().v4(),
      conversationId: conversationId,
      role: PeerMessagingMessageRole.user,
      kind: PeerMessagingMessageKind.approvalResponse,
      deliveryStatus: PeerMessagingDeliveryStatus.pending,
      text: approved ? 'Approved' : 'Rejected',
      createdAt: DateTime.now().toUtc(),
      approvalId: approvalId,
      approvalActions: [action],
      metadata: {
        'approved': approved,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    _upsertConversationMessage(
      profileId,
      conversationId,
      message,
      title: 'Peer Conversation',
      incrementUnread: false,
    );

    final payload = {
      'peer_id': conversationId,
      'conversation_id': conversationId,
      'message': message.toJson(),
      'approval_id': approvalId,
      'approved': approved,
      if (note != null && note.isNotEmpty) 'note': note,
    };

    try {
      final sendResult = await _ipnService.sendPeerMessagingMessage(payload);
      await _applyDeliveryStatus(
        conversationId,
        message.id,
        sendResult.queued
            ? PeerMessagingDeliveryStatus.pending
            : PeerMessagingDeliveryStatus.delivered,
        profileId: profileId,
      );
    } catch (e) {
      await _applyDeliveryStatus(
        conversationId,
        message.id,
        PeerMessagingDeliveryStatus.failed,
        profileId: profileId,
      );
      rethrow;
    }
  }

  Future<void> submitMenuSelection({
    required String conversationId,
    required String messageId,
    required String action,
    String? title,
  }) async {
    final profileId = await _requireCurrentProfileId();
    conversationId = _canonicalConversationId(conversationId);
    final now = DateTime.now().toUtc();
    final message = PeerMessagingMessage(
      id: const Uuid().v4(),
      conversationId: conversationId,
      role: PeerMessagingMessageRole.user,
      kind: PeerMessagingMessageKind.menuResponse,
      deliveryStatus: PeerMessagingDeliveryStatus.pending,
      text: title?.isNotEmpty == true ? title! : action,
      createdAt: now,
      metadata: {
        'reply_to_message_id': messageId,
        'selected_action': action,
        if (title != null && title.isNotEmpty) 'selected_title': title,
      },
    );
    _upsertConversationMessage(
      profileId,
      conversationId,
      message,
      title: 'Peer Conversation',
      incrementUnread: false,
    );

    final payload = {
      'peer_id': conversationId,
      'conversation_id': conversationId,
      'message': message.toJson(),
      'message_id': messageId,
      'action': action,
      if (title != null && title.isNotEmpty) 'title': title,
    };

    try {
      final sendResult = await _ipnService.sendPeerMessagingMessage(payload);
      await _applyDeliveryStatus(
        conversationId,
        message.id,
        sendResult.queued
            ? PeerMessagingDeliveryStatus.pending
            : PeerMessagingDeliveryStatus.delivered,
        profileId: profileId,
      );
    } catch (e) {
      await _applyDeliveryStatus(
        conversationId,
        message.id,
        PeerMessagingDeliveryStatus.failed,
        profileId: profileId,
      );
      rethrow;
    }
  }

  Future<void> handleBridgeEvent(PeerMessagingEvent event) async {
    final eventProfileId = await _resolveProfileIdFromEvent(event);
    final profileId = eventProfileId ?? await _resolveCurrentProfileId();
    _logger.i(
      'handleBridgeEvent: type=${event.type.value} conversation=${event.conversationId} profileId=$profileId messageId=${event.messageId ?? ''} payloadKeys=${event.payload.keys.toList()}',
    );
    switch (event.type) {
      case PeerMessagingEventType.conversationUpsert:
        final conversationId = _canonicalConversationId(event.conversationId);
        _upsertConversation(
          profileId,
          conversationId,
          title: event.payload['title'] as String? ?? 'Peer Conversation',
          subtitle: event.payload['subtitle'] as String? ?? '',
          updatedAt: event.timestamp,
        );
        break;
      case PeerMessagingEventType.conversationDeleted:
        await _deleteConversationForProfile(
          profileId: profileId,
          conversationId: _canonicalConversationId(event.conversationId),
          broadcast: false,
        );
        break;
      case PeerMessagingEventType.messageReceived:
      case PeerMessagingEventType.approvalRequested:
      case PeerMessagingEventType.messageSent:
      case PeerMessagingEventType.messageDeleted:
      case PeerMessagingEventType.approvalSubmitted:
      case PeerMessagingEventType.menuRequested:
      case PeerMessagingEventType.menuSubmitted:
        if (event.type == PeerMessagingEventType.messageDeleted) {
          final targetMessageId =
              event.messageId ?? event.payload['message_id'] as String?;
          if (targetMessageId != null && targetMessageId.isNotEmpty) {
            await _deleteMessageForProfile(
              profileId: profileId,
              conversationId: _canonicalConversationId(event.conversationId),
              messageId: targetMessageId,
              broadcast: false,
            );
          }
          break;
        }
        final messageJson =
            Map<String, dynamic>.from(event.payload['message'] as Map? ?? {});
        if (messageJson.isNotEmpty) {
          final isInboundEvent =
              event.type == PeerMessagingEventType.messageReceived ||
                  event.type == PeerMessagingEventType.approvalRequested ||
                  event.type == PeerMessagingEventType.menuRequested;
          final rawFromPeerId = event.payload['from_peer_id'] as String?;
          final selfPeerId = _ref.read(selfNodeProvider)?.stableID ?? '';
          final messageId = messageJson['id'] as String? ?? '';
          // The backend echoes our own peer messages back via messageReceived
          // (so the local app can re-broadcast them to proxy clients like
          // openclaw via the WebSocket bus). The stableID check below catches
          // the common case, but selfNode can be null/empty at echo time and
          // some platforms route the event before from_peer_id is populated;
          // as a backup, if we already have this message ID in any local
          // conversation for this profile, the event must be an echo of
          // something we sent (UUID v4 collisions are not a concern).
          var alreadyKnownLocally = false;
          if (messageId.isNotEmpty) {
            for (final conv in state.conversations) {
              if (conv.profileId != profileId) continue;
              if (conv.messages.any((m) => m.id == messageId)) {
                alreadyKnownLocally = true;
                break;
              }
            }
          }
          final isFromSelf = isInboundEvent &&
              (alreadyKnownLocally ||
                  ((rawFromPeerId ?? '').isNotEmpty &&
                      rawFromPeerId == selfPeerId));
          // Backend echoes our own peer messages back via messageReceived. Treat
          // them as local so they render as our own and don't bump unread.
          final isRealInbound = isInboundEvent && !isFromSelf;
          final inboundPeerId = isInboundEvent ? rawFromPeerId : null;
          final localConversationId = inboundPeerId?.isNotEmpty == true
              ? _canonicalConversationId(inboundPeerId!)
              : _canonicalConversationId(event.conversationId);
          final mergedMetadata = <String, dynamic>{
            ...Map<String, dynamic>.from(
              messageJson['metadata'] as Map? ?? const {},
            ),
            if (isRealInbound) 'is_inbound': true,
            if (isRealInbound && event.payload['from_peer_id'] != null)
              'from_peer_id': event.payload['from_peer_id'],
            if (isRealInbound && event.payload['from_peer_name'] != null)
              'from_peer_name': event.payload['from_peer_name'],
          };
          final message = PeerMessagingMessage.fromJson({
            ...messageJson,
            'conversation_id': localConversationId,
            if (mergedMetadata.isNotEmpty) 'metadata': mergedMetadata,
          });
          final incomingPeerName =
              isRealInbound ? event.payload['from_peer_name'] as String? : null;
          final conversationTitle = incomingPeerName?.isNotEmpty == true
              ? incomingPeerName!
              : event.payload['conversation_title'] as String? ??
                  'Peer Conversation';
          _logger.i(
            'handleBridgeEvent: applying message id=${message.id} localConversation=$localConversationId inbound=$isRealInbound fromSelf=$isFromSelf attachments=${message.attachments.length} isDirectDistribution=${IpnService.isDirectDistribution}',
          );
          _upsertConversationMessage(
            profileId,
            localConversationId,
            message,
            title: conversationTitle,
            subtitle: event.payload['subtitle'] as String? ?? '',
            incrementUnread: isRealInbound,
          );
          if ((Platform.isMacOS || Platform.isIOS) &&
              message.attachments.isNotEmpty) {
            if (IpnService.isDirectDistribution && isRealInbound) {
              // Direct/PKG distribution: download attachments from daemon
              // via HTTP and save to Downloads, then update attachment paths.
              for (var attempt = 0; attempt < 5; attempt++) {
                if (attempt > 0) {
                  await Future<void>.delayed(
                    const Duration(seconds: 2),
                  );
                }
                final resolved = await _consumeDirectModeAttachmentFiles(
                  conversationId: localConversationId,
                  messageId: message.id,
                );
                if (resolved) break;
              }
            } else {
              // App Store distribution: system extension auto-saves files
              // and records transferId→path mapping.
              await _consumeAutoSavedAttachmentPaths();
              await _applyPendingAutoSavedPaths(
                conversationId: localConversationId,
                messageId: message.id,
              );
            }
          }
          if (Platform.isIOS &&
              isRealInbound &&
              message.attachments.isNotEmpty) {
            await _consumePendingAttachmentFiles();
          }
        }
        break;
      case PeerMessagingEventType.messageDeliveryUpdate:
        final status = PeerMessagingDeliveryStatus.fromValue(
          event.payload['delivery_status'] as String?,
        );
        final targetConversationId = event.conversationId.isNotEmpty
            ? _canonicalConversationId(event.conversationId)
            : _canonicalConversationId(
                event.payload['conversation_id'] as String? ?? '',
              );
        final targetMessageId = event.messageId ??
            event.payload['message_id'] as String? ??
            (event.payload['message'] as Map?)?['id'] as String?;
        if ((targetMessageId ?? '').isNotEmpty) {
          await _applyDeliveryStatus(
            targetConversationId,
            targetMessageId!,
            status,
            profileId: profileId,
          );
        }
        break;
      case PeerMessagingEventType.syncSnapshot:
        final snapshot = PeerMessagingState.fromJson(
          Map<String, dynamic>.from(event.payload['state'] as Map? ?? {}),
        );
        state = _mergeDuplicateConversations(
          _adoptLegacyConversations(snapshot, profileId: profileId),
        ).copyWith(
          initialized: true,
          proxy: state.proxy,
        );
        break;
      case PeerMessagingEventType.warmStatus:
        final ref = (event.payload['peer_ref'] as String? ?? '').trim();
        if (ref.isNotEmpty) {
          final status = PeerMessagingWarmStatus.fromValue(
              event.payload['status'] as String?);
          final prev = _warmStatus[ref];
          if (prev != status) {
            _warmStatus[ref] = status;
            _warmStatusController.add(warmStatusSnapshot);
          }
        }
        // Don't fall through to _persistState / broadcast — warm status is
        // ephemeral runtime state, not part of the conversation snapshot.
        return;
      case PeerMessagingEventType.authenticated:
      case PeerMessagingEventType.error:
        break;
    }

    await _persistState();
    await _consumeAutoSavedAttachmentPaths();
    if (_shouldBroadcastEvent(event)) {
      await _broadcast(event);
    }
  }

  Future<void> _handleBridgeEventFromStream(PeerMessagingEvent event) async {
    final eventKey = _eventDedupKey(event);
    if (_handledBridgeEventKeys.contains(eventKey)) {
      _logger.d('Skipping duplicate peer messaging event: $eventKey');
      return;
    }
    _handledBridgeEventKeys.add(eventKey);
    if (_handledBridgeEventKeys.length > 500) {
      _handledBridgeEventKeys.remove(_handledBridgeEventKeys.first);
    }
    await handleBridgeEvent(event);
  }

  String _eventDedupKey(PeerMessagingEvent event) {
    return [
      event.type.value,
      event.conversationId,
      event.messageId ?? '',
      event.timestamp.toIso8601String(),
    ].join('|');
  }

  Future<void> _handleIpnNotification(IpnNotification notification) async {
    // Detect transition into Running so we can re-push the active-peer set
    // immediately after a tunnel reconnect — the daemon's session was wiped
    // when the LocalBackend went down, and the user might try to send a
    // message before the next 60s heartbeat fires.
    final newState = notification.state;
    if (newState != null && newState != _lastSeenIpnState) {
      final wasNotRunning =
          _lastSeenIpnState != BackendState.running.value;
      _lastSeenIpnState = newState;
      if (wasNotRunning &&
          newState == BackendState.running.value &&
          _activeThreadRefs.isNotEmpty) {
        unawaited(_reassertActivePeers());
      }
    }
    if (notification.netMap != null) {
      final mergedState = _mergeDuplicateConversations(state);
      if (!identical(mergedState, state)) {
        state = mergedState;
        await _persistState();
        await _broadcast(_syncSnapshotEvent());
      }
    }
    if (notification.outgoingFiles != null &&
        notification.outgoingFiles!.isNotEmpty) {
      await _consumeOutgoingAttachmentProgress(notification.outgoingFiles!);
    }
    if (notification.cylonixDirectFileReceived != null) {
      await _handleDirectModeFileReceived(
          notification.cylonixDirectFileReceived!);
    }
    if (!(Platform.isIOS || Platform.isMacOS) ||
        notification.filesWaiting == null) {
      return;
    }
    _lastWaitingFiles = _parseAwaitingFiles(notification.filesWaiting!);
    if (Platform.isMacOS || Platform.isIOS) {
      await _consumeAutoSavedAttachmentPaths();
    }
    if (Platform.isIOS) {
      await _consumePendingAttachmentFiles();
    }
  }

  /// Handle a Notify.CylonixDirectFileReceived event. In direct mode the
  /// file has already landed at its final Path so the only thing left to
  /// do is correlate to a pending peer-message attachment via the
  /// transfer ID, or surface a "File Received" desktop notification for
  /// regular Taildrop arrivals. This piggybacks on the same
  /// _pendingAutoSavedPaths mechanism BackgroundTaskManager uses on iOS,
  /// so the existing _consumeAutoSavedAttachmentPaths flow takes care of
  /// updating the message UI when there is a matching peer message.
  Future<void> _handleDirectModeFileReceived(
      Map<String, dynamic> payload) async {
    final transferId = payload['transfer_id'] as String? ?? '';
    final path = payload['path'] as String? ?? '';
    final name = payload['name'] as String? ?? '';
    if (path.isEmpty) {
      return;
    }
    if (transferId.isNotEmpty) {
      var localPath = path;
      if (Platform.isAndroid && path.startsWith('content://')) {
        // Android saves taildrop arrivals through MediaStore, so the
        // reported path is a content:// URI dart:io cannot read. Mirror
        // the attachment into the managed attachment store and reference
        // that copy from the chat bubble; the Downloads/Cylonix copy
        // stays for user visibility.
        final copied = await _copyContentUriToAttachmentStore(
          uri: path,
          transferId: transferId,
          name: name,
        );
        if (copied != null) {
          localPath = copied;
        }
      }
      _pendingAutoSavedPaths[transferId] = localPath;
      await _consumeAutoSavedAttachmentPaths();
      // Peer messaging UI shows the message in the chat thread; suppress
      // a redundant system notification (matches iOS BackgroundTaskManager).
      return;
    }
    // On macOS direct distribution the CylonixNotifier LaunchAgent
    // (installed by postinstall) surfaces "File Received" banners
    // regardless of whether Cylonix.app is running, so we don't post one
    // from here to avoid duplicate notifications.
    if (IpnService.isDirectDistribution) {
      return;
    }
    await _showFileReceivedNotification(name: name, path: path);
  }

  static const _notificationsChannel =
      MethodChannel('io.cylonix.sase/notifications');

  Future<void> _showFileReceivedNotification({
    required String name,
    required String path,
  }) async {
    // Windows/Linux have no native notification channel, so post a desktop
    // toast via local_notifier. (Matches the OS file-received notifications
    // Android/macOS/iOS already show.)
    if (Platform.isWindows || Platform.isLinux) {
      await DesktopNotifications.showFileReceived(name: name, path: path);
      return;
    }
    // Only the macOS direct PKG drives this method channel — App Store
    // / iOS posts the notification from WireGuardAdapter::handleFilesWaiting
    // inside the Network Extension, and the channel handler is only
    // registered in macos-direct/Runner. Calling it elsewhere would hit
    // MissingPluginException.
    if (!IpnService.isDirectDistribution) {
      return;
    }
    try {
      await _notificationsChannel.invokeMethod('showFileReceived', {
        'name': name,
        'path': path,
      });
    } catch (e) {
      _logger.w('showFileReceived method channel failed: $e');
    }
  }

  Future<void> _consumeOutgoingAttachmentProgress(
    List<OutgoingFile> outgoingFiles,
  ) async {
    final filesById = {
      for (final file in outgoingFiles)
        if (file.id.isNotEmpty) file.id: file,
    };
    if (filesById.isEmpty) {
      return;
    }

    var changed = false;
    final conversations = <PeerMessagingConversation>[];
    for (final conversation in state.conversations) {
      final messages = <PeerMessagingMessage>[];
      for (final message in conversation.messages) {
        if (message.role != PeerMessagingMessageRole.user ||
            message.deliveryStatus != PeerMessagingDeliveryStatus.pending ||
            message.attachments.isEmpty) {
          messages.add(message);
          continue;
        }

        final matched = <OutgoingFile>[];
        for (final attachment in message.attachments) {
          final transferId = attachment.transferId ?? attachment.id;
          final file = filesById[transferId];
          if (file != null) {
            matched.add(file);
          }
        }
        if (matched.isEmpty) {
          messages.add(message);
          continue;
        }

        final totalSize =
            matched.fold<int>(0, (sum, file) => sum + file.declaredSize);
        final totalSent = matched.fold<int>(0, (sum, file) => sum + file.sent);
        final progress = totalSize > 0 ? totalSent / totalSize : 0.0;
        final normalizedProgress = progress.clamp(0.0, 1.0);
        final existingProgress =
            (message.metadata['transfer_progress'] as num?)?.toDouble();
        if (existingProgress != null &&
            (existingProgress - normalizedProgress).abs() < 0.001) {
          messages.add(message);
          continue;
        }

        changed = true;
        messages.add(
          message.copyWith(
            metadata: {
              ...message.metadata,
              'transfer_progress': normalizedProgress,
            },
          ),
        );
      }
      conversations.add(conversation.copyWith(messages: messages));
    }

    if (!changed) {
      return;
    }
    state = state.copyWith(conversations: _sortConversations(conversations));
    await _persistState();
  }

  Future<void> _consumeAutoSavedAttachmentPaths() async {
    // The native auto-saved-path map only exists on Apple platforms
    // (staged by the Network Extension). On desktop/Android, inbound
    // taildrop arrives in DirectFileMode and is recorded into
    // _pendingAutoSavedPaths by _handleDirectModeFileReceived, so we still
    // need to run the consumption below to attach those paths to messages.
    final autoSavedPaths = (Platform.isMacOS || Platform.isIOS)
        ? await _ipnService.consumeAutoSavedFilePaths()
        : const <String, String>{};
    if (autoSavedPaths.isNotEmpty) {
      // macOS NE: BackgroundTaskManager stages peer-message attachments in an
      // app inbox (deliberately kept out of the user's Downloads). Relocate
      // each into the profile-scoped managed attachment store so the chat
      // bubbles can read them.
      if (Platform.isMacOS && !IpnService.isDirectDistribution) {
        for (final entry in autoSavedPaths.entries) {
          final managed = await _relocateInboxAttachmentToStore(entry.value);
          _pendingAutoSavedPaths[entry.key] = managed ?? entry.value;
        }
      } else {
        _pendingAutoSavedPaths.addAll(autoSavedPaths);
      }
      _logger.d(
        'Merged auto-saved attachment paths into pending cache: $_pendingAutoSavedPaths',
      );
    }
    if (_pendingAutoSavedPaths.isEmpty) {
      _logger.d('No auto-saved attachment paths available to consume');
      return;
    }
    _logger.d(
      'Consuming auto-saved attachment paths from pending cache: $_pendingAutoSavedPaths',
    );

    var changed = false;
    final consumedTransferIds = <String>{};
    final conversations = <PeerMessagingConversation>[];
    for (final conversation in state.conversations) {
      final messages = <PeerMessagingMessage>[];
      for (final message in conversation.messages) {
        if (message.attachments.isEmpty) {
          messages.add(message);
          continue;
        }

        var messageChanged = false;
        final nextAttachments = <PeerMessagingAttachment>[];
        for (final attachment in message.attachments) {
          final transferId = attachment.transferId ?? attachment.id;
          final autoSavedPath = _pendingAutoSavedPaths[transferId];
          if (autoSavedPath == null || autoSavedPath.isEmpty) {
            nextAttachments.add(attachment);
            continue;
          }
          _logger.d(
            'Matched attachment to auto-saved path: conversation=${conversation.id} message=${message.id} transferId=$transferId name=${attachment.name} path=$autoSavedPath',
          );

          final existingPath = attachment.path;
          if ((existingPath ?? '').isNotEmpty &&
              existingPath == autoSavedPath) {
            nextAttachments.add(attachment);
            continue;
          }

          nextAttachments.add(
            PeerMessagingAttachment(
              id: attachment.id,
              transferId: attachment.transferId,
              name: attachment.name,
              size: attachment.size,
              mimeType: attachment.mimeType,
              path: autoSavedPath,
            ),
          );
          consumedTransferIds.add(transferId);
          messageChanged = true;
        }

        if (messageChanged) {
          changed = true;
          messages.add(message.copyWith(attachments: nextAttachments));
        } else {
          messages.add(message);
        }
      }
      conversations.add(conversation.copyWith(messages: messages));
    }

    if (!changed) {
      _logger.d(
        'Auto-saved attachment paths were available but no message attachments were updated; keeping pending cache for direct message insertion matching: $_pendingAutoSavedPaths',
      );
      return;
    }

    for (final transferId in consumedTransferIds) {
      _pendingAutoSavedPaths.remove(transferId);
    }
    _logger.d(
      'Consumed auto-saved attachment paths for transfer IDs: $consumedTransferIds; remaining pending cache: $_pendingAutoSavedPaths',
    );
    state = state.copyWith(conversations: _sortConversations(conversations));
    _logger.d(
        'Persisting updated message attachment paths after auto-save consume');
    await _persistState();
  }

  Future<void> _applyPendingAutoSavedPaths({
    required String conversationId,
    required String messageId,
  }) async {
    if (!Platform.isMacOS || _pendingAutoSavedPaths.isEmpty) {
      return;
    }

    var changed = false;
    final consumedTransferIds = <String>{};
    final conversations = <PeerMessagingConversation>[];
    for (final conversation in state.conversations) {
      if (conversation.id != conversationId) {
        conversations.add(conversation);
        continue;
      }

      final messages = <PeerMessagingMessage>[];
      for (final message in conversation.messages) {
        if (message.id != messageId || message.attachments.isEmpty) {
          messages.add(message);
          continue;
        }

        var messageChanged = false;
        final nextAttachments = <PeerMessagingAttachment>[];
        for (final attachment in message.attachments) {
          final transferId = attachment.transferId ?? attachment.id;
          final resolvedPath = _pendingAutoSavedPaths[transferId];
          if ((resolvedPath ?? '').isEmpty) {
            nextAttachments.add(attachment);
            continue;
          }
          consumedTransferIds.add(transferId);
          messageChanged = true;
          changed = true;
          _logger.d(
            'Applied pending auto-saved path directly during message insert: conversation=$conversationId message=$messageId transferId=$transferId path=$resolvedPath',
          );
          nextAttachments.add(
            PeerMessagingAttachment(
              id: attachment.id,
              transferId: attachment.transferId,
              name: attachment.name,
              size: attachment.size,
              mimeType: attachment.mimeType,
              path: resolvedPath,
            ),
          );
        }

        if (!messageChanged) {
          messages.add(message);
          continue;
        }
        messages.add(message.copyWith(attachments: nextAttachments));
      }

      conversations.add(conversation.copyWith(messages: messages));
    }

    if (!changed) {
      return;
    }

    for (final transferId in consumedTransferIds) {
      _pendingAutoSavedPaths.remove(transferId);
    }
    state = state.copyWith(conversations: _sortConversations(conversations));
    await _persistState();
  }

  List<AwaitingFile> _parseAwaitingFiles(Map<String, dynamic> filesWaiting) {
    final dir = filesWaiting['Dir'] as String? ?? '';
    final files = (filesWaiting['Files'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(
          (file) => AwaitingFile(
            id: file['ID'] as String?,
            name: file['Name'] as String? ?? '',
            size: (file['Size'] as num?)?.toInt() ?? 0,
            path:
                dir.isEmpty ? null : p.join(dir, file['Name'] as String? ?? ''),
          ),
        )
        .where((file) => file.name.isNotEmpty)
        .toList();
    return files;
  }

  Future<void> _consumePendingAttachmentFiles() async {
    if (_lastWaitingFiles.isEmpty) {
      return;
    }

    var changed = false;
    final consumedFileNames = <String>{};
    final conversations = <PeerMessagingConversation>[];
    final attachmentsDir = await _attachmentStorageDir();

    for (final conversation in state.conversations) {
      final messages = <PeerMessagingMessage>[];
      for (final message in conversation.messages) {
        if (message.attachments.isEmpty) {
          messages.add(message);
          continue;
        }

        var messageChanged = false;
        final nextAttachments = <PeerMessagingAttachment>[];
        for (final attachment in message.attachments) {
          if ((attachment.path ?? '').isNotEmpty &&
              await File(attachment.path!).exists()) {
            nextAttachments.add(attachment);
            continue;
          }

          final waitingFile = _matchWaitingFileForAttachment(
            attachment,
            excludeNames: consumedFileNames,
          );
          if (waitingFile == null) {
            nextAttachments.add(attachment);
            continue;
          }

          final transferId = attachment.transferId ?? attachment.id;
          final destinationPath = p.join(
            attachmentsDir.path,
            '${transferId}_${attachment.name}',
          );
          final sourcePath = waitingFile.path;
          if (sourcePath == null || sourcePath.isEmpty) {
            nextAttachments.add(attachment);
            continue;
          }

          try {
            await File(sourcePath).copy(destinationPath);
            await _ipnService.deleteFile(waitingFile.name);
            consumedFileNames.add(waitingFile.name);
            nextAttachments.add(
              PeerMessagingAttachment(
                id: attachment.id,
                transferId: transferId,
                name: attachment.name,
                size: attachment.size,
                mimeType: attachment.mimeType,
                path: destinationPath,
              ),
            );
            messageChanged = true;
          } catch (e) {
            _logger.e(
              'Failed to consume waiting attachment ${waitingFile.name}: $e',
            );
            nextAttachments.add(attachment);
          }
        }

        if (messageChanged) {
          changed = true;
          messages.add(message.copyWith(attachments: nextAttachments));
        } else {
          messages.add(message);
        }
      }
      conversations.add(conversation.copyWith(messages: messages));
    }

    if (!changed) {
      return;
    }

    _lastWaitingFiles = _lastWaitingFiles
        .where((file) => !consumedFileNames.contains(file.name))
        .toList();
    state = state.copyWith(conversations: _sortConversations(conversations));
    await _persistState();
  }

  /// Downloads attachments from the daemon via HTTP for direct (non-App Store)
  /// macOS distribution. Mirrors what [_consumeAutoSavedAttachmentPaths] does
  /// for the App Store version, but uses the HTTP local API to fetch the file
  /// content since the daemon stores files in its own file system.
  /// Returns `true` if all attachments for the target message were resolved.
  Future<bool> _consumeDirectModeAttachmentFiles({
    required String conversationId,
    required String messageId,
  }) async {
    List<AwaitingFile> waitingFiles;
    try {
      waitingFiles = await _ipnService.getWaitingFiles(
            timeoutMilliseconds: 3000,
          ) ??
          [];
    } catch (e) {
      _logger.e('Direct mode: failed to fetch waiting files: $e');
      return false;
    }
    if (waitingFiles.isEmpty) {
      _logger.d('Direct mode: no waiting files available for attachment match');
      return false;
    }
    _logger.d(
      'Direct mode: fetched ${waitingFiles.length} waiting files for attachment matching',
    );

    // Temporarily update _lastWaitingFiles so _matchWaitingFileForAttachment works
    final previousWaitingFiles = _lastWaitingFiles;
    _lastWaitingFiles = waitingFiles;

    // Save to Downloads, matching App Store auto-save behavior
    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir == null) {
      _logger.e('Direct mode: could not resolve Downloads directory');
      return false;
    }
    var changed = false;
    final consumedFileNames = <String>{};
    final conversations = <PeerMessagingConversation>[];

    for (final conversation in state.conversations) {
      if (conversation.id != conversationId) {
        conversations.add(conversation);
        continue;
      }

      final messages = <PeerMessagingMessage>[];
      for (final message in conversation.messages) {
        if (message.id != messageId || message.attachments.isEmpty) {
          messages.add(message);
          continue;
        }

        var messageChanged = false;
        final nextAttachments = <PeerMessagingAttachment>[];
        for (final attachment in message.attachments) {
          if ((attachment.path ?? '').isNotEmpty &&
              await File(attachment.path!).exists()) {
            nextAttachments.add(attachment);
            continue;
          }

          final waitingFile = _matchWaitingFileForAttachment(
            attachment,
            excludeNames: consumedFileNames,
          );
          if (waitingFile == null) {
            _logger.d(
              'Direct mode: no waiting file match for attachment ${attachment.name}',
            );
            nextAttachments.add(attachment);
            continue;
          }

          final destinationPath =
              _uniqueFilePath(downloadsDir.path, attachment.name);

          try {
            // Download file content from daemon via HTTP saveFile API
            await _ipnService.saveFile(waitingFile.name, destinationPath);
            if (!await File(destinationPath).exists()) {
              _logger.e(
                'Direct mode: saveFile completed but file not found at $destinationPath',
              );
              nextAttachments.add(attachment);
              continue;
            }
            _logger.d(
              'Direct mode: downloaded attachment ${attachment.name} to $destinationPath',
            );
            // Remove from daemon's waiting queue
            try {
              await _ipnService.deleteFile(waitingFile.name);
            } catch (e) {
              _logger.e(
                'Direct mode: failed to delete waiting file ${waitingFile.name}: $e',
              );
            }
            consumedFileNames.add(waitingFile.name);
            nextAttachments.add(
              PeerMessagingAttachment(
                id: attachment.id,
                transferId: attachment.transferId,
                name: attachment.name,
                size: attachment.size,
                mimeType: attachment.mimeType,
                path: destinationPath,
              ),
            );
            messageChanged = true;
          } catch (e) {
            _logger.e(
              'Direct mode: failed to download attachment ${waitingFile.name}: $e',
            );
            nextAttachments.add(attachment);
          }
        }

        if (messageChanged) {
          changed = true;
          messages.add(message.copyWith(attachments: nextAttachments));
        } else {
          messages.add(message);
        }
      }
      conversations.add(conversation.copyWith(messages: messages));
    }

    // Restore _lastWaitingFiles, removing consumed entries
    _lastWaitingFiles = previousWaitingFiles
        .where((file) => !consumedFileNames.contains(file.name))
        .toList();

    if (!changed) {
      _logger.d(
        'Direct mode: no attachment paths were updated for message $messageId',
      );
      return false;
    }

    state = state.copyWith(conversations: _sortConversations(conversations));
    _logger.d(
      'Direct mode: persisting updated attachment paths for message $messageId (resolved ${consumedFileNames.length} attachments)',
    );
    await _persistState();
    return true;
  }

  AwaitingFile? _matchWaitingFileForAttachment(
    PeerMessagingAttachment attachment, {
    Set<String> excludeNames = const {},
  }) {
    final candidates = _lastWaitingFiles
        .where((file) => !excludeNames.contains(file.name))
        .toList();
    final transferId = attachment.transferId ?? attachment.id;
    final transferIdMatch = candidates.firstWhere(
      (file) => file.id == transferId,
      orElse: () => const AwaitingFile(name: '', size: 0),
    );
    if (transferIdMatch.name.isNotEmpty) {
      return transferIdMatch;
    }

    final exactMatch = candidates.firstWhere(
      (file) => file.name == attachment.name,
      orElse: () => const AwaitingFile(name: '', size: 0),
    );
    if (exactMatch.name.isNotEmpty) {
      return exactMatch;
    }

    final normalizedAttachmentName = _normalizeWaitingFileName(attachment.name);
    final normalizedNameMatches = candidates
        .where(
          (file) =>
              _normalizeWaitingFileName(file.name) == normalizedAttachmentName,
        )
        .toList();
    if (normalizedNameMatches.length == 1) {
      return normalizedNameMatches.first;
    }

    final sizeMatches =
        candidates.where((file) => file.size == attachment.size).toList();
    if (sizeMatches.length == 1) {
      return sizeMatches.first;
    }

    final normalizedNameAndSizeMatches = candidates
        .where(
          (file) =>
              file.size == attachment.size &&
              _normalizeWaitingFileName(file.name) == normalizedAttachmentName,
        )
        .toList();
    if (normalizedNameAndSizeMatches.isNotEmpty) {
      return normalizedNameAndSizeMatches.first;
    }
    return null;
  }

  String _normalizeWaitingFileName(String value) {
    final extension = p.extension(value);
    final baseName = p.basenameWithoutExtension(value);
    final normalizedBaseName = baseName.replaceFirst(RegExp(r' \(\d+\)$'), '');
    return '$normalizedBaseName$extension';
  }

  /// Returns a unique file path in [directory] for [fileName], appending
  /// " (N)" before the extension if needed — matching the App Store auto-save
  /// behavior in BackgroundTaskManager.getUniqueFileName.
  String _uniqueFilePath(String directory, String fileName) {
    var candidate = p.join(directory, fileName);
    if (!File(candidate).existsSync()) return candidate;
    final ext = p.extension(fileName);
    final base = p.basenameWithoutExtension(fileName);
    for (var i = 1; i < 1000; i++) {
      candidate = p.join(directory, '$base ($i)$ext');
      if (!File(candidate).existsSync()) return candidate;
    }
    return candidate;
  }

  /// Copies an Android MediaStore content:// URI into the managed
  /// attachment store so chat bubbles can resolve a real file path.
  /// Returns null when the copy fails; callers fall back to the content
  /// URI (which keeps today's degraded behavior instead of dropping the
  /// reference entirely).
  Future<String?> _copyContentUriToAttachmentStore({
    required String uri,
    required String transferId,
    required String name,
  }) async {
    try {
      final dir = await _attachmentStorageDir();
      final fileName = name.isNotEmpty ? name : transferId;
      final destPath = p.join(dir.path, '${transferId}_$fileName');
      final destFile = File(destPath);
      if (await destFile.exists()) {
        return destPath;
      }
      await _ipnService.copyContentUriToFile(uri, destPath);
      if (await destFile.exists()) {
        _logger.d(
          'Mirrored attachment content URI into managed store: '
          'transferId=$transferId path=$destPath',
        );
        return destPath;
      }
    } catch (e) {
      _logger.w('Failed to mirror attachment content URI $uri: $e');
    }
    return null;
  }

  Future<Directory> _attachmentStorageDir() async {
    final supportDir = await getApplicationSupportDirectory();
    final profileScope = _attachmentScopeFolderName(_currentProfileIdOrEmpty());
    final attachmentsDir = Directory(
      p.join(supportDir.path, _storageFolderName, 'attachments', profileScope),
    );
    await attachmentsDir.create(recursive: true);
    return attachmentsDir;
  }

  /// macOS NE only: move a peer attachment that `BackgroundTaskManager` staged
  /// in the app inbox (`<AppSupport>/peer_messaging/incoming`) into the
  /// profile-scoped managed attachment store, returning the managed path. The
  /// inbox copy is removed so peer attachments never linger outside the managed
  /// store (and never in the user's Downloads). Returns null on any error, in
  /// which case the caller keeps the original inbox path.
  Future<String?> _relocateInboxAttachmentToStore(String inboxPath) async {
    try {
      final source = File(inboxPath);
      if (!await source.exists()) {
        return null;
      }
      final dir = await _attachmentStorageDir();
      final destPath = p.join(dir.path, p.basename(inboxPath));
      final dest = File(destPath);
      if (await dest.exists()) {
        await dest.delete();
      }
      await source.copy(destPath);
      try {
        await source.delete();
      } catch (_) {}
      _logger.d(
        'Relocated peer attachment into managed store: $inboxPath -> $destPath',
      );
      return destPath;
    } catch (e) {
      _logger.w('Failed to relocate inbox attachment $inboxPath: $e');
      return null;
    }
  }

  /// On iOS/macOS the network extension lives in a separate sandbox and can
  /// only read files placed inside the app-group container. If a message's
  /// attachment path is in the main app's container (e.g. a retry of a send
  /// that originally happened before the shared folder was available), copy
  /// it into the shared folder and return updated attachments. No-op on other
  /// platforms or when the shared folder is unavailable.
  Future<List<PeerMessagingAttachment>> _ensureAttachmentsStaged(
      List<PeerMessagingAttachment> attachments) async {
    if (attachments.isEmpty) return attachments;
    if (!(Platform.isIOS || Platform.isMacOS)) return attachments;
    final sharedFolder = await _ipnService.getSharedFolderPath();
    if (sharedFolder == null || sharedFolder.isEmpty) return attachments;
    final scopedDir = Directory(
      p.join(
        sharedFolder,
        'peer-messaging',
        'attachments',
        _attachmentScopeFolderName(_currentProfileIdOrEmpty()),
      ),
    );
    await scopedDir.create(recursive: true);

    final result = <PeerMessagingAttachment>[];
    for (final attachment in attachments) {
      final path = attachment.path ?? '';
      if (path.isEmpty || path.startsWith(sharedFolder)) {
        result.add(attachment);
        continue;
      }
      final source = File(path);
      if (!await source.exists()) {
        result.add(attachment);
        continue;
      }
      final extension = p.extension(attachment.name);
      final baseName = p.basenameWithoutExtension(attachment.name);
      final stagedPath =
          p.join(scopedDir.path, '${baseName}_${attachment.id}$extension');
      try {
        if (!await File(stagedPath).exists()) {
          await source.copy(stagedPath);
        }
        result.add(attachment.copyWith(path: stagedPath));
      } catch (e) {
        _logger.w('Failed to stage attachment ${attachment.id} for send: $e');
        result.add(attachment);
      }
    }
    return result;
  }

  bool _attachmentPathsMatch(
    List<PeerMessagingAttachment> a,
    List<PeerMessagingAttachment> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].path != b[i].path) return false;
    }
    return true;
  }

  bool _shouldBroadcastEvent(PeerMessagingEvent event) {
    switch (event.type) {
      case PeerMessagingEventType.messageSent:
      case PeerMessagingEventType.approvalSubmitted:
      case PeerMessagingEventType.menuSubmitted:
        return false;
      case PeerMessagingEventType.messageReceived:
      case PeerMessagingEventType.approvalRequested:
      case PeerMessagingEventType.menuRequested:
        return true;
      default:
        return true;
    }
  }

  Future<void> _startProxyServer() async {
    if (!_supportsLocalProxy) {
      state = state.copyWith(
        proxy: state.proxy.copyWith(
          isRunning: false,
          error: 'Local peer messaging proxy is desktop-only.',
        ),
      );
      return;
    }

    try {
      _server = await _bindProxyServer();
      state = state.copyWith(
        proxy: state.proxy.copyWith(
          isRunning: true,
          url: _proxyUrl,
          error: null,
        ),
      );
      unawaited(_server!.forEach(_handleHttpRequest));
      _logger.i('Peer messaging WebSocket proxy listening at $_proxyUrl');
    } catch (e) {
      _logger.e('Failed to start peer messaging proxy: $e');
      state = state.copyWith(
        proxy: state.proxy.copyWith(
          isRunning: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<HttpServer> _bindProxyServer() async {
    try {
      return await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        _preferredListenPort,
        shared: true,
      );
    } on SocketException catch (e) {
      if (!_isBindConflict(e)) {
        rethrow;
      }
      _logger.w(
        'Preferred peer messaging proxy port $_preferredListenPort unavailable; using an ephemeral loopback port instead: $e',
      );
      return HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
        shared: true,
      );
    }
  }

  bool _isBindConflict(SocketException error) {
    final message = error.message.toLowerCase();
    return message.contains('address already in use') ||
        message.contains('cannot assign requested address') ||
        message.contains('failed to create server socket') ||
        message.contains('listen failed') ||
        error.osError?.errorCode == 48 ||
        error.osError?.errorCode == 98 ||
        error.osError?.errorCode == 10048;
  }

  Future<void> _handleHttpRequest(HttpRequest request) async {
    if (request.uri.path != '/peer-messaging/v1' &&
        request.uri.path != '/openclaw/v1') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    WebSocket socket;
    try {
      socket = await WebSocketTransformer.upgrade(request);
    } catch (e) {
      _logger.e('Failed to upgrade peer messaging socket: $e');
      return;
    }

    _clients.add(socket);
    bool authenticated = false;
    Timer? authTimeout;

    authTimeout = Timer(const Duration(seconds: 5), () async {
      if (!authenticated) {
        socket.add(jsonEncode({
          'type': PeerMessagingEventType.error.value,
          'payload': {'message': 'Authentication timeout'},
        }));
        await socket.close(WebSocketStatus.policyViolation, 'auth-timeout');
      }
    });

    socket.listen((message) async {
      try {
        final json = jsonDecode(message as String) as Map<String, dynamic>;
        final action =
            json['type'] as String? ?? json['action'] as String? ?? '';
        final payload =
            Map<String, dynamic>.from(json['payload'] as Map? ?? const {});

        if (!authenticated) {
          if (action != 'authenticate' ||
              payload['token'] != state.proxy.authToken) {
            socket.add(jsonEncode({
              'type': PeerMessagingEventType.error.value,
              'payload': {'message': 'Authentication failed'},
            }));
            await socket.close(
              WebSocketStatus.policyViolation,
              'auth-failed',
            );
            return;
          }
          authenticated = true;
          authTimeout?.cancel();
          socket.add(jsonEncode({
            'version': _protocolVersion,
            'type': PeerMessagingEventType.authenticated.value,
            'conversation_id': '',
            'timestamp': DateTime.now().toUtc().toIso8601String(),
            'payload': {'url': _proxyUrl},
          }));
          socket.add(jsonEncode(_syncSnapshotEvent().toJson()));
          return;
        }

        switch (action) {
          case 'send_message':
            final menuOptions =
                ((payload['menu_options'] as List<dynamic>?) ?? const [])
                    .whereType<Map<String, dynamic>>()
                    .map(PeerMessagingMenuOption.fromJson)
                    .toList();
            await sendTextMessage(
              payload['conversation_id'] as String? ?? '',
              payload['text'] as String? ?? '',
              conversationTitle: payload['conversation_title'] as String?,
              deliveryPolicy: payload['delivery_policy'] as String?,
              menuOptions: menuOptions,
              replyToMessageId: payload['reply_to_message_id'] as String? ??
                  (payload['message'] as Map?)?['reply_to_message_id']
                      as String?,
            );
            break;
          case 'submit_approval':
            await submitApproval(
              conversationId: payload['conversation_id'] as String? ?? '',
              approvalId: payload['approval_id'] as String? ?? '',
              approved: payload['approved'] as bool? ?? false,
              note: payload['note'] as String?,
            );
            break;
          case 'submit_menu_selection':
            await submitMenuSelection(
              conversationId: payload['conversation_id'] as String? ?? '',
              messageId: payload['message_id'] as String? ?? '',
              action: payload['action'] as String? ?? '',
              title: payload['title'] as String?,
            );
            break;
          case 'mark_read':
            await markConversationRead(
                payload['conversation_id'] as String? ?? '');
            break;
          case 'delete_message':
            await deleteMessage(
              conversationId: payload['conversation_id'] as String? ?? '',
              messageId: payload['message_id'] as String? ?? '',
              broadcast: false,
            );
            break;
          case 'delete_conversation':
            await deleteConversation(
              payload['conversation_id'] as String? ?? '',
              broadcast: false,
            );
            break;
          default:
            socket.add(jsonEncode({
              'version': _protocolVersion,
              'type': PeerMessagingEventType.error.value,
              'conversation_id': payload['conversation_id'] as String? ?? '',
              'timestamp': DateTime.now().toUtc().toIso8601String(),
              'payload': {'message': 'Unknown action: $action'},
            }));
        }
      } catch (e) {
        socket.add(jsonEncode({
          'version': _protocolVersion,
          'type': PeerMessagingEventType.error.value,
          'conversation_id': '',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'payload': {'message': e.toString()},
        }));
      }
    }, onDone: () {
      authTimeout?.cancel();
      _clients.remove(socket);
    }, onError: (Object error, StackTrace stackTrace) {
      authTimeout?.cancel();
      _clients.remove(socket);
      _logger.e('Peer messaging socket error: $error');
    });
  }

  Future<void> _broadcast(PeerMessagingEvent event) async {
    if (_clients.isEmpty) return;
    final eventProfileId = event.payload['profile_id'] as String? ?? '';
    final currentProfileId = _currentProfileIdOrEmpty();
    if (event.type != PeerMessagingEventType.syncSnapshot &&
        eventProfileId.isNotEmpty &&
        currentProfileId.isNotEmpty &&
        eventProfileId != currentProfileId) {
      return;
    }
    final encoded = jsonEncode(event.toJson());
    final staleClients = <WebSocket>[];
    for (final client in _clients) {
      try {
        client.add(encoded);
      } catch (_) {
        staleClients.add(client);
      }
    }
    for (final client in staleClients) {
      _clients.remove(client);
      await client.close();
    }
  }

  PeerMessagingEvent _syncSnapshotEvent() {
    final profileId = _currentProfileIdOrEmpty();
    return PeerMessagingEvent(
      version: _protocolVersion,
      type: PeerMessagingEventType.syncSnapshot,
      conversationId: '',
      timestamp: DateTime.now().toUtc(),
      payload: {
        'profile_id': profileId,
        'state': state.forProfile(profileId).toJson(),
      },
    );
  }

  void _upsertConversation(
    String profileId,
    String conversationId, {
    required String title,
    String subtitle = '',
    DateTime? updatedAt,
  }) {
    conversationId = _canonicalConversationId(conversationId);
    final existingIndex = state.conversations.indexWhere(
      (c) => _matchesConversation(
        c,
        conversationId: conversationId,
        profileId: profileId,
      ),
    );
    final nextConversation = existingIndex >= 0
        ? state.conversations[existingIndex].copyWith(
            profileId: profileId,
            title: title.isEmpty
                ? state.conversations[existingIndex].title
                : title,
            subtitle: subtitle.isEmpty
                ? state.conversations[existingIndex].subtitle
                : subtitle,
            hidden: false,
            updatedAt: updatedAt ?? DateTime.now().toUtc(),
          )
        : PeerMessagingConversation(
            id: conversationId,
            profileId: profileId,
            title: title,
            subtitle: subtitle,
            updatedAt: updatedAt ?? DateTime.now().toUtc(),
            unreadCount: 0,
            hidden: false,
            messages: const [],
          );

    final conversations = [...state.conversations];
    if (existingIndex >= 0) {
      conversations[existingIndex] = nextConversation;
    } else {
      conversations.add(nextConversation);
    }
    state = state.copyWith(conversations: _sortConversations(conversations));
  }

  void _upsertConversationMessage(
    String profileId,
    String conversationId,
    PeerMessagingMessage message, {
    required String title,
    String subtitle = '',
    required bool incrementUnread,
  }) {
    conversationId = _canonicalConversationId(conversationId);
    if (message.conversationId != conversationId) {
      message = message.copyWith(conversationId: conversationId);
    }
    final conversations = [...state.conversations];
    final index = conversations.indexWhere(
      (c) => _matchesConversation(
        c,
        conversationId: conversationId,
        profileId: profileId,
      ),
    );
    PeerMessagingConversation conversation;
    if (index >= 0) {
      conversation = conversations[index];
    } else {
      conversation = PeerMessagingConversation(
        id: conversationId,
        profileId: profileId,
        title: title,
        subtitle: subtitle,
        updatedAt: message.createdAt,
        unreadCount: 0,
        hidden: false,
        messages: const [],
      );
    }

    final messages = [...conversation.messages];
    final existingMessageIndex = messages.indexWhere((m) => m.id == message.id);
    if (existingMessageIndex >= 0) {
      messages[existingMessageIndex] = _mergeMessageUpdate(
        messages[existingMessageIndex],
        message,
      );
    } else {
      messages.add(message);
    }
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final nextConversation = conversation.copyWith(
      profileId: profileId,
      title: title.isEmpty ? conversation.title : title,
      subtitle: subtitle.isEmpty ? conversation.subtitle : subtitle,
      updatedAt: message.createdAt,
      hidden: false,
      unreadCount: incrementUnread
          ? conversation.unreadCount + (existingMessageIndex >= 0 ? 0 : 1)
          : conversation.unreadCount,
      messages: messages,
    );

    if (index >= 0) {
      conversations[index] = nextConversation;
    } else {
      conversations.add(nextConversation);
    }
    state = state.copyWith(conversations: _sortConversations(conversations));
    unawaited(_persistState());
  }

  PeerMessagingMessage _mergeMessageUpdate(
    PeerMessagingMessage existing,
    PeerMessagingMessage incoming,
  ) {
    final attachmentsById = {
      for (final attachment in existing.attachments) attachment.id: attachment,
    };
    for (final attachment in incoming.attachments) {
      final previous = attachmentsById[attachment.id];
      attachmentsById[attachment.id] = previous == null
          ? attachment
          : attachment.copyWith(
              transferId: attachment.transferId ?? previous.transferId,
              path: (attachment.path ?? '').isNotEmpty
                  ? attachment.path
                  : previous.path,
            );
    }
    final attachments = attachmentsById.values.toList();
    final deliveryStatus =
        incoming.deliveryStatus == PeerMessagingDeliveryStatus.pending &&
                existing.deliveryStatus != PeerMessagingDeliveryStatus.pending
            ? existing.deliveryStatus
            : incoming.deliveryStatus;
    final failureMessage = incoming.failureMessage ?? existing.failureMessage;
    final metadata = <String, dynamic>{
      ...existing.metadata,
      ...incoming.metadata,
      if (attachments.isNotEmpty)
        'attachments': attachments.map((item) => item.toJson()).toList(),
      if (failureMessage != null) 'failure_message': failureMessage,
    };
    return incoming.copyWith(
      deliveryStatus: deliveryStatus,
      failureMessage: failureMessage,
      attachments: attachments,
      metadata: metadata,
    );
  }

  Future<void> _applyDeliveryStatus(
    String conversationId,
    String messageId,
    PeerMessagingDeliveryStatus deliveryStatus, {
    required String profileId,
  }) async {
    conversationId = _canonicalConversationId(conversationId);
    var changed = false;
    final conversations = state.conversations.map((conversation) {
      if (conversation.profileId != profileId) {
        return conversation;
      }
      final messages = conversation.messages.map((message) {
        if (message.id != messageId) return message;
        if (conversationId.isNotEmpty && conversation.id != conversationId) {
          return message;
        }
        changed = true;
        return message.copyWith(deliveryStatus: deliveryStatus);
      }).toList();
      return conversation.copyWith(messages: messages);
    }).toList();
    if (!changed) {
      _logger.w(
        'Delivery status update did not match any message: conversationId=$conversationId messageId=$messageId status=${deliveryStatus.value}',
      );
      return;
    }
    state = state.copyWith(conversations: _sortConversations(conversations));
    await _persistState();
  }

  Future<void> _sendOutgoingMessage({
    required String profileId,
    required String conversationId,
    required String messageId,
    required Map<String, dynamic> payload,
    required List<PeerMessagingAttachment> attachments,
  }) async {
    conversationId = _canonicalConversationId(conversationId);
    try {
      final stagedAttachments = await _ensureAttachmentsStaged(attachments);
      var outgoingPayload = payload;
      if (!_attachmentPathsMatch(attachments, stagedAttachments)) {
        await _updateMessage(
          profileId: profileId,
          conversationId: conversationId,
          messageId: messageId,
          transform: (current) =>
              current.copyWith(attachments: stagedAttachments),
        );
        // Update the outgoing payload's serialized message so the wire copy
        // also carries the corrected paths.
        final updatedMessage = _findMessage(
          profileId: profileId,
          conversationId: conversationId,
          messageId: messageId,
        );
        if (updatedMessage != null) {
          outgoingPayload = {
            ...payload,
            'message': updatedMessage.toJson(),
          };
        }
      }
      final filePayloads = stagedAttachments
          .where((item) => (item.path ?? '').isNotEmpty)
          .map(
            (item) => OutgoingFile(
              id: item.transferId ?? item.id,
              name: item.name,
              peerID: conversationId,
              declaredSize: item.size,
              path: item.path,
              cylonixPeerMessage: true,
            ),
          )
          .toList();
      if (filePayloads.isNotEmpty) {
        await _ipnService.sendPeerFiles(conversationId, filePayloads);
      }
      final sendResult =
          await _ipnService.sendPeerMessagingMessage(outgoingPayload);
      await _updateMessage(
        profileId: profileId,
        conversationId: conversationId,
        messageId: messageId,
        transform: (current) => current.copyWith(
          deliveryStatus: sendResult.queued
              ? PeerMessagingDeliveryStatus.pending
              : PeerMessagingDeliveryStatus.delivered,
          failureMessage: null,
          metadata: {
            ...current.metadata,
            if (sendResult.queued) 'delivery_policy': 'queue',
            if (sendResult.queued) 'queued': true,
          }..remove('failure_message'),
        ),
      );
      final updatedMessage = _findMessage(
        profileId: profileId,
        conversationId: conversationId,
        messageId: messageId,
      );
      if (updatedMessage != null) {
        await _broadcast(
          PeerMessagingEvent(
            version: _protocolVersion,
            type: PeerMessagingEventType.messageSent,
            conversationId: conversationId,
            messageId: messageId,
            timestamp: DateTime.now().toUtc(),
            payload: {
              'conversation_id': conversationId,
              'profile_id': profileId,
              'message': updatedMessage.toJson(),
              'queued': sendResult.queued,
            },
          ),
        );
      }
    } catch (e) {
      await _updateMessage(
        profileId: profileId,
        conversationId: conversationId,
        messageId: messageId,
        transform: (current) => current.copyWith(
          deliveryStatus: PeerMessagingDeliveryStatus.failed,
          failureMessage: e.toString(),
          metadata: {
            ...current.metadata,
            'failure_message': e.toString(),
          },
        ),
      );
      await _broadcast(
        PeerMessagingEvent(
          version: _protocolVersion,
          type: PeerMessagingEventType.error,
          conversationId: conversationId,
          messageId: messageId,
          timestamp: DateTime.now().toUtc(),
          payload: {
            'message': e.toString(),
            'profile_id': profileId,
          },
        ),
      );
      rethrow;
    }
  }

  PeerMessagingMessage? _findMessage({
    required String profileId,
    required String conversationId,
    required String messageId,
  }) {
    conversationId = _canonicalConversationId(conversationId);
    for (final conversation in state.conversations) {
      if (!_matchesConversation(
        conversation,
        conversationId: conversationId,
        profileId: profileId,
      )) {
        continue;
      }
      for (final message in conversation.messages) {
        if (message.id == messageId) {
          return message;
        }
      }
    }
    return null;
  }

  String? _findConversationTitle({
    required String profileId,
    required String conversationId,
  }) {
    conversationId = _canonicalConversationId(conversationId);
    for (final conversation in state.conversations) {
      if (_matchesConversation(
        conversation,
        conversationId: conversationId,
        profileId: profileId,
      )) {
        return conversation.title;
      }
    }
    return null;
  }

  Future<void> _updateMessage({
    required String profileId,
    required String conversationId,
    required String messageId,
    required PeerMessagingMessage Function(PeerMessagingMessage current)
        transform,
  }) async {
    conversationId = _canonicalConversationId(conversationId);
    var changed = false;
    final conversations = state.conversations.map((conversation) {
      if (!_matchesConversation(
        conversation,
        conversationId: conversationId,
        profileId: profileId,
      )) {
        return conversation;
      }
      final messages = conversation.messages.map((message) {
        if (message.id != messageId) {
          return message;
        }
        changed = true;
        return transform(message);
      }).toList();
      return conversation.copyWith(messages: messages);
    }).toList();
    if (!changed) {
      return;
    }
    state = state.copyWith(conversations: _sortConversations(conversations));
    await _persistState();
  }

  List<PeerMessagingConversation> _sortConversations(
    List<PeerMessagingConversation> conversations,
  ) {
    conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return conversations;
  }

  bool _matchesConversation(
    PeerMessagingConversation conversation, {
    required String conversationId,
    required String profileId,
  }) {
    return conversation.id == _canonicalConversationId(conversationId) &&
        conversation.profileId == profileId;
  }

  String _canonicalConversationId(String value) {
    final normalizedRef = _normalizePeerRef(value);
    if (normalizedRef.isEmpty) {
      return value;
    }
    final netmap = _ref.read(netmapProvider);
    final nodes = <Node>[
      if (netmap?.selfNode != null) netmap!.selfNode,
      ...?netmap?.peers,
    ];
    for (final node in nodes) {
      if (_nodeMatchesPeerRef(node, normalizedRef)) {
        return node.stableID;
      }
    }
    return value.trim();
  }

  bool _nodeMatchesPeerRef(Node node, String normalizedRef) {
    return _normalizePeerRef(node.stableID) == normalizedRef ||
        _normalizePeerRef(node.name) == normalizedRef ||
        _normalizePeerRef(node.computedName ?? '') == normalizedRef ||
        _normalizePeerRef(node.computedNameWithHost ?? '') == normalizedRef ||
        _normalizePeerRef(node.displayName) == normalizedRef;
  }

  String _normalizePeerRef(String value) {
    return value.trim().toLowerCase().replaceFirst(RegExp(r'\.$'), '');
  }

  String _attachmentScopeFolderName(String profileId) {
    if (profileId.isEmpty) {
      return 'default';
    }
    return profileId.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  String _currentProfileIdOrEmpty() {
    final providerProfileId = _ref.read(currentLoginProfileProvider)?.id ?? '';
    if (providerProfileId.isNotEmpty) {
      _activeProfileId = providerProfileId;
      return providerProfileId;
    }
    return _activeProfileId;
  }

  Future<String> _resolveCurrentProfileId() async {
    final providerProfileId = _currentProfileIdOrEmpty();
    if (providerProfileId.isNotEmpty) {
      return providerProfileId;
    }
    try {
      final profile = await _ipnService.currentProfile(fast: true);
      if (profile.id.isNotEmpty) {
        _activeProfileId = profile.id;
      }
      return _activeProfileId;
    } catch (_) {
      return _activeProfileId;
    }
  }

  Future<String> _requireCurrentProfileId() async {
    final profileId = await _resolveCurrentProfileId();
    if (profileId.isEmpty) {
      throw Exception('No active login profile available for peer messaging');
    }
    return profileId;
  }

  Future<String?> _resolveProfileIdFromEvent(PeerMessagingEvent event) async {
    final payloadProfileId = event.payload['profile_id'] as String?;
    if ((payloadProfileId ?? '').isNotEmpty) {
      return payloadProfileId;
    }

    final conversationId = _canonicalConversationId(event.conversationId);
    for (final conversation in state.conversations) {
      if ((conversationId.isNotEmpty && conversation.id == conversationId) ||
          ((event.messageId ?? '').isNotEmpty &&
              conversation.messages.any(
                (message) => message.id == event.messageId,
              ))) {
        if (conversation.profileId.isNotEmpty) {
          return conversation.profileId;
        }
      }
    }
    return null;
  }

  PeerMessagingState _adoptLegacyConversations(
    PeerMessagingState source, {
    required String profileId,
  }) {
    if (profileId.isEmpty ||
        !source.conversations.any((item) => item.profileId.isEmpty)) {
      return source;
    }

    return source.copyWith(
      conversations: source.conversations
          .map(
            (conversation) => conversation.profileId.isNotEmpty
                ? conversation
                : conversation.copyWith(profileId: profileId),
          )
          .toList(),
    );
  }

  PeerMessagingState _rewriteLegacyAttachmentPaths(PeerMessagingState source) {
    const legacyMarker = '/$_legacyStorageFolderName/';
    const newMarker = '/$_storageFolderName/';
    var anyChanged = false;
    final conversations =
        source.conversations.map((conversation) {
      var convChanged = false;
      final messages = conversation.messages.map((message) {
        if (message.attachments.isEmpty) return message;
        var msgChanged = false;
        final attachments = message.attachments.map((attachment) {
          final path = attachment.path ?? '';
          if (!path.contains(legacyMarker)) return attachment;
          msgChanged = true;
          return attachment.copyWith(
            path: path.replaceAll(legacyMarker, newMarker),
          );
        }).toList();
        if (!msgChanged) return message;
        convChanged = true;
        return message.copyWith(attachments: attachments);
      }).toList();
      if (!convChanged) return conversation;
      anyChanged = true;
      return conversation.copyWith(messages: messages);
    }).toList();
    if (!anyChanged) return source;
    return source.copyWith(conversations: conversations);
  }

  PeerMessagingState _mergeDuplicateConversations(PeerMessagingState source) {
    final merged = <String, PeerMessagingConversation>{};
    var changed = false;
    for (final conversation in source.conversations) {
      final canonicalId = _canonicalConversationId(conversation.id);
      if (canonicalId != conversation.id) {
        changed = true;
      }
      final key = '${conversation.profileId}|$canonicalId';
      final normalizedMessages = conversation.messages.map(
        (message) {
          if (message.conversationId == canonicalId) {
            return message;
          }
          changed = true;
          return message.copyWith(conversationId: canonicalId);
        },
      ).toList();
      final normalized = PeerMessagingConversation(
        id: canonicalId,
        profileId: conversation.profileId,
        title: conversation.title,
        subtitle: conversation.subtitle,
        updatedAt: conversation.updatedAt,
        unreadCount: conversation.unreadCount,
        hidden: conversation.hidden,
        messages: normalizedMessages,
      );
      final existing = merged[key];
      if (existing == null) {
        merged[key] = normalized;
        continue;
      }

      changed = true;
      final messagesById = {
        for (final message in existing.messages) message.id: message,
      };
      for (final message in normalized.messages) {
        final previous = messagesById[message.id];
        if (previous == null) {
          messagesById[message.id] = message;
          continue;
        }
        messagesById[message.id] = _mergeMessageUpdate(previous, message);
      }
      final messages = messagesById.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final newer = normalized.updatedAt.isAfter(existing.updatedAt)
          ? normalized
          : existing;
      merged[key] = PeerMessagingConversation(
        id: canonicalId,
        profileId: existing.profileId,
        title: newer.title,
        subtitle: newer.subtitle,
        updatedAt: newer.updatedAt,
        unreadCount: existing.unreadCount + normalized.unreadCount,
        hidden: existing.hidden && normalized.hidden,
        messages: messages,
      );
    }
    if (!changed) {
      return source;
    }
    return source.copyWith(
      conversations: _sortConversations(merged.values.toList()),
    );
  }

  Future<void> _deleteConversationForProfile({
    required String profileId,
    required String conversationId,
    required bool broadcast,
  }) async {
    conversationId = _canonicalConversationId(conversationId);
    final nextConversations = state.conversations
        .where(
          (conversation) => !_matchesConversation(
            conversation,
            conversationId: conversationId,
            profileId: profileId,
          ),
        )
        .toList();
    state =
        state.copyWith(conversations: _sortConversations(nextConversations));
    await _persistState();
    if (broadcast) {
      await _broadcast(
        PeerMessagingEvent(
          version: _protocolVersion,
          type: PeerMessagingEventType.conversationDeleted,
          conversationId: conversationId,
          timestamp: DateTime.now().toUtc(),
          payload: {'profile_id': profileId},
        ),
      );
    }
  }

  Future<PeerMessagingState> _loadState() async {
    try {
      final file = await _ensureStateFile();
      final json = await file.readAsString();
      if (json.trim().isEmpty) {
        return PeerMessagingState.initial();
      }
      return PeerMessagingState.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (e) {
      _logger.w('Failed to load peer messaging state: $e');
      return PeerMessagingState.initial();
    }
  }

  Future<void> _persistState() async {
    try {
      final file = await _ensureStateFile();
      await file.writeAsString(jsonEncode(state.toJson()));
    } catch (e) {
      _logger.e('Failed to persist peer messaging state: $e');
    }
  }

  Future<File> _ensureStateFile() async {
    if (_stateFile != null) {
      return _stateFile!;
    }
    final appSupport = await getApplicationSupportDirectory();
    final folder = Directory(p.join(appSupport.path, _storageFolderName));
    if (!await folder.exists()) {
      final legacy = Directory(p.join(appSupport.path, _legacyStorageFolderName));
      if (await legacy.exists()) {
        try {
          await legacy.rename(folder.path);
        } catch (e) {
          _logger.w(
              'Failed to rename legacy $_legacyStorageFolderName folder: $e');
          await folder.create(recursive: true);
        }
      } else {
        await folder.create(recursive: true);
      }
    }
    final file = File(p.join(folder.path, _storageFileName));
    if (!await file.exists()) {
      await file.writeAsString('{}');
    }
    _stateFile = file;
    return file;
  }

  Future<String> _loadOrCreateAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_authTokenKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final legacy = prefs.getString(_legacyAuthTokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      await prefs.setString(_authTokenKey, legacy);
      await prefs.remove(_legacyAuthTokenKey);
      return legacy;
    }
    final token = const Uuid().v4();
    await prefs.setString(_authTokenKey, token);
    return token;
  }

  String get _proxyUrl =>
      'ws://127.0.0.1:${_server?.port ?? _preferredListenPort}/peer-messaging/v1';
}
