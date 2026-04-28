// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:convert';

enum PeerMessagingEventType {
  conversationUpsert('conversation_upsert'),
  conversationDeleted('conversation_deleted'),
  messageReceived('message_received'),
  messageSent('message_sent'),
  messageDeliveryUpdate('message_delivery_update'),
  messageDeleted('message_deleted'),
  approvalRequested('approval_requested'),
  approvalSubmitted('approval_submitted'),
  menuRequested('menu_requested'),
  menuSubmitted('menu_submitted'),
  syncSnapshot('sync_snapshot'),
  authenticated('authenticated'),
  error('error');

  const PeerMessagingEventType(this.value);
  final String value;

  static PeerMessagingEventType fromValue(String value) {
    return PeerMessagingEventType.values.firstWhere(
      (event) => event.value == value,
      orElse: () => PeerMessagingEventType.error,
    );
  }
}

enum PeerMessagingMessageRole {
  agent('agent'),
  user('user'),
  system('system');

  const PeerMessagingMessageRole(this.value);
  final String value;

  static PeerMessagingMessageRole fromValue(String? value) {
    return PeerMessagingMessageRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => PeerMessagingMessageRole.system,
    );
  }
}

enum PeerMessagingMessageKind {
  text('text'),
  file('file'),
  taskSummary('task_summary'),
  approvalRequest('approval_request'),
  approvalResponse('approval_response'),
  menuRequest('menu_request'),
  menuResponse('menu_response');

  const PeerMessagingMessageKind(this.value);
  final String value;

  static PeerMessagingMessageKind fromValue(String? value) {
    return PeerMessagingMessageKind.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => PeerMessagingMessageKind.text,
    );
  }
}

enum PeerMessagingDeliveryStatus {
  pending('pending'),
  sent('sent'),
  delivered('delivered'),
  failed('failed');

  const PeerMessagingDeliveryStatus(this.value);
  final String value;

  static PeerMessagingDeliveryStatus fromValue(String? value) {
    return PeerMessagingDeliveryStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PeerMessagingDeliveryStatus.pending,
    );
  }
}

class PeerMessagingSendResult {
  final bool accepted;
  final bool queued;
  final PeerMessagingDeliveryStatus deliveryStatus;
  final String? messageId;

  const PeerMessagingSendResult({
    required this.accepted,
    required this.queued,
    required this.deliveryStatus,
    this.messageId,
  });

  factory PeerMessagingSendResult.fromJson(Map<String, dynamic> json) {
    return PeerMessagingSendResult(
      accepted: json['accepted'] as bool? ?? false,
      queued: json['queued'] as bool? ?? false,
      deliveryStatus: PeerMessagingDeliveryStatus.fromValue(
        json['delivery_status'] as String?,
      ),
      messageId: json['message_id'] as String?,
    );
  }
}

class PeerMessagingApprovalAction {
  final String id;
  final String title;
  final bool approved;
  final String? note;

  const PeerMessagingApprovalAction({
    required this.id,
    required this.title,
    required this.approved,
    this.note,
  });

  factory PeerMessagingApprovalAction.fromJson(Map<String, dynamic> json) {
    return PeerMessagingApprovalAction(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      approved: json['approved'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'approved': approved,
      if (note != null) 'note': note,
    };
  }
}

class PeerMessagingMenuOption {
  final String id;
  final String title;
  final String action;

  const PeerMessagingMenuOption({
    required this.id,
    required this.title,
    required this.action,
  });

  factory PeerMessagingMenuOption.fromJson(Map<String, dynamic> json) {
    return PeerMessagingMenuOption(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      action: json['action'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'action': action,
    };
  }
}

class PeerMessagingAttachment {
  final String id;
  final String? transferId;
  final String name;
  final int size;
  final String? mimeType;
  final String? path;

  const PeerMessagingAttachment({
    required this.id,
    this.transferId,
    required this.name,
    required this.size,
    this.mimeType,
    this.path,
  });

  factory PeerMessagingAttachment.fromJson(Map<String, dynamic> json) {
    return PeerMessagingAttachment(
      id: json['id'] as String? ?? '',
      transferId: json['transfer_id'] as String?,
      name: json['name'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      mimeType: json['mime_type'] as String?,
      path: json['path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (transferId != null) 'transfer_id': transferId,
      'name': name,
      'size': size,
      if (mimeType != null) 'mime_type': mimeType,
      if (path != null) 'path': path,
    };
  }

  PeerMessagingAttachment copyWith({
    String? transferId,
    String? name,
    int? size,
    String? mimeType,
    String? path,
  }) {
    return PeerMessagingAttachment(
      id: id,
      transferId: transferId ?? this.transferId,
      name: name ?? this.name,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      path: path ?? this.path,
    );
  }
}

class PeerMessagingMessage {
  final String id;
  final String conversationId;
  final PeerMessagingMessageRole role;
  final PeerMessagingMessageKind kind;
  final PeerMessagingDeliveryStatus deliveryStatus;
  final String text;
  final DateTime createdAt;
  final String? approvalId;
  final String? replyToMessageId;
  final String? failureMessage;
  final List<PeerMessagingApprovalAction> approvalActions;
  final List<PeerMessagingMenuOption> menuOptions;
  final List<PeerMessagingAttachment> attachments;
  final Map<String, dynamic> metadata;

  const PeerMessagingMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.kind,
    required this.deliveryStatus,
    required this.text,
    required this.createdAt,
    this.approvalId,
    this.replyToMessageId,
    this.failureMessage,
    this.approvalActions = const [],
    this.menuOptions = const [],
    this.attachments = const [],
    this.metadata = const {},
  });

  factory PeerMessagingMessage.fromJson(Map<String, dynamic> json) {
    final metadata = Map<String, dynamic>.from(
      (json['metadata'] as Map<dynamic, dynamic>?) ?? const {},
    );
    final attachmentJson = ((json['attachments'] as List<dynamic>?) ??
            (metadata['attachments'] as List<dynamic>?) ??
            const [])
        .whereType<Map<String, dynamic>>();
    return PeerMessagingMessage(
      id: json['id'] as String? ?? '',
      conversationId: json['conversation_id'] as String? ?? '',
      role: PeerMessagingMessageRole.fromValue(json['role'] as String?),
      kind: PeerMessagingMessageKind.fromValue(json['kind'] as String?),
      deliveryStatus: PeerMessagingDeliveryStatus.fromValue(
        json['delivery_status'] as String?,
      ),
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      approvalId: json['approval_id'] as String?,
      replyToMessageId: json['reply_to_message_id'] as String? ??
          metadata['reply_to_message_id'] as String?,
      failureMessage: json['failure_message'] as String? ??
          metadata['failure_message'] as String?,
      approvalActions: ((json['approval_actions'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PeerMessagingApprovalAction.fromJson)
          .toList(),
      menuOptions: ((json['menu_options'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PeerMessagingMenuOption.fromJson)
          .toList(),
      attachments:
          attachmentJson.map(PeerMessagingAttachment.fromJson).toList(),
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'role': role.value,
      'kind': kind.value,
      'delivery_status': deliveryStatus.value,
      'text': text,
      'created_at': createdAt.toIso8601String(),
      if (approvalId != null) 'approval_id': approvalId,
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      if (failureMessage != null) 'failure_message': failureMessage,
      if (approvalActions.isNotEmpty)
        'approval_actions': approvalActions.map((e) => e.toJson()).toList(),
      if (menuOptions.isNotEmpty)
        'menu_options': menuOptions.map((e) => e.toJson()).toList(),
      if (attachments.isNotEmpty)
        'attachments': attachments.map((e) => e.toJson()).toList(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  PeerMessagingMessage copyWith({
    String? conversationId,
    PeerMessagingDeliveryStatus? deliveryStatus,
    String? text,
    String? replyToMessageId,
    String? failureMessage,
    List<PeerMessagingApprovalAction>? approvalActions,
    List<PeerMessagingMenuOption>? menuOptions,
    List<PeerMessagingAttachment>? attachments,
    Map<String, dynamic>? metadata,
  }) {
    return PeerMessagingMessage(
      id: id,
      conversationId: conversationId ?? this.conversationId,
      role: role,
      kind: kind,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      text: text ?? this.text,
      createdAt: createdAt,
      approvalId: approvalId,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      failureMessage: failureMessage ?? this.failureMessage,
      approvalActions: approvalActions ?? this.approvalActions,
      menuOptions: menuOptions ?? this.menuOptions,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get hasAttachments => attachments.isNotEmpty;

  bool get isFileMessage =>
      kind == PeerMessagingMessageKind.file || attachments.isNotEmpty;
}

class PeerMessagingConversation {
  final String id;
  final String profileId;
  final String title;
  final String subtitle;
  final DateTime updatedAt;
  final int unreadCount;
  final bool hidden;
  final List<PeerMessagingMessage> messages;

  const PeerMessagingConversation({
    required this.id,
    required this.profileId,
    required this.title,
    required this.subtitle,
    required this.updatedAt,
    required this.unreadCount,
    this.hidden = false,
    required this.messages,
  });

  factory PeerMessagingConversation.fromJson(Map<String, dynamic> json) {
    final messages = ((json['messages'] as List<dynamic>?) ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PeerMessagingMessage.fromJson)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return PeerMessagingConversation(
      id: json['id'] as String? ?? '',
      profileId: json['profile_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Peer Messaging',
      subtitle: json['subtitle'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          (messages.isNotEmpty ? messages.last.createdAt : DateTime.now()),
      unreadCount: json['unread_count'] as int? ?? 0,
      hidden: json['hidden'] as bool? ?? false,
      messages: messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (profileId.isNotEmpty) 'profile_id': profileId,
      'title': title,
      'subtitle': subtitle,
      'updated_at': updatedAt.toIso8601String(),
      'unread_count': unreadCount,
      'hidden': hidden,
      'messages': messages.map((e) => e.toJson()).toList(),
    };
  }

  String get preview {
    if (messages.isEmpty) return subtitle;
    final last = messages.last;
    if (last.text.isNotEmpty) return last.text;
    if (last.attachments.isNotEmpty) {
      if (last.attachments.length == 1) {
        return 'Attachment: ${last.attachments.first.name}';
      }
      return '${last.attachments.length} attachments';
    }
    return subtitle;
  }

  PeerMessagingConversation copyWith({
    String? profileId,
    String? title,
    String? subtitle,
    DateTime? updatedAt,
    int? unreadCount,
    bool? hidden,
    List<PeerMessagingMessage>? messages,
  }) {
    return PeerMessagingConversation(
      id: id,
      profileId: profileId ?? this.profileId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      hidden: hidden ?? this.hidden,
      messages: messages ?? this.messages,
    );
  }
}

class PeerMessagingEvent {
  final String version;
  final PeerMessagingEventType type;
  final String conversationId;
  final String? messageId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  const PeerMessagingEvent({
    required this.version,
    required this.type,
    required this.conversationId,
    required this.timestamp,
    required this.payload,
    this.messageId,
  });

  factory PeerMessagingEvent.fromJson(Map<String, dynamic> json) {
    return PeerMessagingEvent(
      version: json['version'] as String? ?? 'v1',
      type: PeerMessagingEventType.fromValue(json['type'] as String? ?? ''),
      conversationId: json['conversation_id'] as String? ?? '',
      messageId: json['message_id'] as String?,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      payload: Map<String, dynamic>.from(
        (json['payload'] as Map<dynamic, dynamic>?) ?? const {},
      ),
    );
  }

  factory PeerMessagingEvent.fromEncodedJson(String encoded) {
    return PeerMessagingEvent.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'type': type.value,
      'conversation_id': conversationId,
      if (messageId != null) 'message_id': messageId,
      'timestamp': timestamp.toIso8601String(),
      'payload': payload,
    };
  }

  String encode() => jsonEncode(toJson());
}

class PeerMessagingProxyInfo {
  final bool isRunning;
  final String url;
  final String authToken;
  final String? error;

  const PeerMessagingProxyInfo({
    required this.isRunning,
    required this.url,
    required this.authToken,
    this.error,
  });

  factory PeerMessagingProxyInfo.fromJson(Map<String, dynamic> json) {
    return PeerMessagingProxyInfo(
      isRunning: json['is_running'] as bool? ?? false,
      url: json['url'] as String? ?? '',
      authToken: json['auth_token'] as String? ?? '',
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_running': isRunning,
      'url': url,
      'auth_token': authToken,
      if (error != null) 'error': error,
    };
  }

  PeerMessagingProxyInfo copyWith({
    bool? isRunning,
    String? url,
    String? authToken,
    String? error,
  }) {
    return PeerMessagingProxyInfo(
      isRunning: isRunning ?? this.isRunning,
      url: url ?? this.url,
      authToken: authToken ?? this.authToken,
      error: error,
    );
  }
}

class PeerMessagingState {
  final bool initialized;
  final List<PeerMessagingConversation> conversations;
  final PeerMessagingProxyInfo proxy;

  const PeerMessagingState({
    required this.initialized,
    required this.conversations,
    required this.proxy,
  });

  factory PeerMessagingState.initial() {
    return const PeerMessagingState(
      initialized: false,
      conversations: [],
      proxy: PeerMessagingProxyInfo(
        isRunning: false,
        url: '',
        authToken: '',
      ),
    );
  }

  factory PeerMessagingState.fromJson(Map<String, dynamic> json) {
    final conversations = ((json['conversations'] as List<dynamic>?) ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PeerMessagingConversation.fromJson)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return PeerMessagingState(
      initialized: json['initialized'] as bool? ?? true,
      conversations: conversations,
      proxy: PeerMessagingProxyInfo.fromJson(
        Map<String, dynamic>.from(
          (json['proxy'] as Map<dynamic, dynamic>?) ?? const {},
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'initialized': initialized,
      'conversations': conversations.map((e) => e.toJson()).toList(),
      'proxy': proxy.toJson(),
    };
  }

  PeerMessagingState copyWith({
    bool? initialized,
    List<PeerMessagingConversation>? conversations,
    PeerMessagingProxyInfo? proxy,
  }) {
    return PeerMessagingState(
      initialized: initialized ?? this.initialized,
      conversations: conversations ?? this.conversations,
      proxy: proxy ?? this.proxy,
    );
  }

  List<PeerMessagingConversation> conversationsForProfile(String profileId) {
    return conversations
        .where((conversation) => conversation.profileId == profileId)
        .toList();
  }

  PeerMessagingState forProfile(String profileId) {
    return copyWith(conversations: conversationsForProfile(profileId));
  }
}

class PeerMessagingBridgeEvent {
  final PeerMessagingEvent event;

  const PeerMessagingBridgeEvent(this.event);
}
