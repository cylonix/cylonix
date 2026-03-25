// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:convert';

enum PeerMessagingEventType {
  conversationUpsert('conversation_upsert'),
  messageReceived('message_received'),
  messageSent('message_sent'),
  messageDeliveryUpdate('message_delivery_update'),
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

class PeerMessagingMessage {
  final String id;
  final String conversationId;
  final PeerMessagingMessageRole role;
  final PeerMessagingMessageKind kind;
  final PeerMessagingDeliveryStatus deliveryStatus;
  final String text;
  final DateTime createdAt;
  final String? approvalId;
  final List<PeerMessagingApprovalAction> approvalActions;
  final List<PeerMessagingMenuOption> menuOptions;
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
    this.approvalActions = const [],
    this.menuOptions = const [],
    this.metadata = const {},
  });

  factory PeerMessagingMessage.fromJson(Map<String, dynamic> json) {
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
      approvalActions: ((json['approval_actions'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PeerMessagingApprovalAction.fromJson)
          .toList(),
      menuOptions: ((json['menu_options'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PeerMessagingMenuOption.fromJson)
          .toList(),
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map<dynamic, dynamic>?) ?? const {},
      ),
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
      if (approvalActions.isNotEmpty)
        'approval_actions': approvalActions.map((e) => e.toJson()).toList(),
      if (menuOptions.isNotEmpty)
        'menu_options': menuOptions.map((e) => e.toJson()).toList(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  PeerMessagingMessage copyWith({
    PeerMessagingDeliveryStatus? deliveryStatus,
    String? text,
    List<PeerMessagingApprovalAction>? approvalActions,
    List<PeerMessagingMenuOption>? menuOptions,
    Map<String, dynamic>? metadata,
  }) {
    return PeerMessagingMessage(
      id: id,
      conversationId: conversationId,
      role: role,
      kind: kind,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      text: text ?? this.text,
      createdAt: createdAt,
      approvalId: approvalId,
      approvalActions: approvalActions ?? this.approvalActions,
      menuOptions: menuOptions ?? this.menuOptions,
      metadata: metadata ?? this.metadata,
    );
  }
}

class PeerMessagingConversation {
  final String id;
  final String title;
  final String subtitle;
  final DateTime updatedAt;
  final int unreadCount;
  final List<PeerMessagingMessage> messages;

  const PeerMessagingConversation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.updatedAt,
    required this.unreadCount,
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
      title: json['title'] as String? ?? 'Peer Messaging',
      subtitle: json['subtitle'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          (messages.isNotEmpty ? messages.last.createdAt : DateTime.now()),
      unreadCount: json['unread_count'] as int? ?? 0,
      messages: messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'updated_at': updatedAt.toIso8601String(),
      'unread_count': unreadCount,
      'messages': messages.map((e) => e.toJson()).toList(),
    };
  }

  String get preview {
    if (messages.isEmpty) return subtitle;
    return messages.last.text;
  }

  PeerMessagingConversation copyWith({
    String? title,
    String? subtitle,
    DateTime? updatedAt,
    int? unreadCount,
    List<PeerMessagingMessage>? messages,
  }) {
    return PeerMessagingConversation(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
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
}

class PeerMessagingBridgeEvent {
  final PeerMessagingEvent event;

  const PeerMessagingBridgeEvent(this.event);
}
