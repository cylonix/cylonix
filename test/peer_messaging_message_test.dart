// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter_test/flutter_test.dart';

import 'package:cylonix/models/peer_messaging.dart';

void main() {
  test('PeerMessagingMessage preserves reply and failure fields in JSON', () {
    final message = PeerMessagingMessage(
      id: 'message-1',
      conversationId: 'peer-1',
      role: PeerMessagingMessageRole.user,
      kind: PeerMessagingMessageKind.text,
      deliveryStatus: PeerMessagingDeliveryStatus.failed,
      text: 'hello',
      createdAt: DateTime.parse('2026-03-28T10:00:00Z'),
      replyToMessageId: 'message-0',
      failureMessage: 'network timeout',
      metadata: const {
        'reply_to_message_id': 'message-0',
        'failure_message': 'network timeout',
      },
    );

    final decoded = PeerMessagingMessage.fromJson(message.toJson());

    expect(decoded.replyToMessageId, 'message-0');
    expect(decoded.failureMessage, 'network timeout');
    expect(decoded.deliveryStatus, PeerMessagingDeliveryStatus.failed);
  });

  test('PeerMessagingMessage reads reply and failure fields from metadata', () {
    final decoded = PeerMessagingMessage.fromJson({
      'id': 'message-2',
      'conversation_id': 'peer-2',
      'role': 'user',
      'kind': 'text',
      'delivery_status': 'failed',
      'text': 'retry me',
      'created_at': '2026-03-28T10:05:00Z',
      'metadata': {
        'reply_to_message_id': 'message-1',
        'failure_message': 'send failed',
      },
    });

    expect(decoded.replyToMessageId, 'message-1');
    expect(decoded.failureMessage, 'send failed');
  });
}
