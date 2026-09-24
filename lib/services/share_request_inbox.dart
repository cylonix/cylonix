// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import '../models/shared_file.dart';

/// Share requests handed to the app by a platform entry point (the Apple
/// share extension via the `shareRequest` method call, or the startup pull
/// of requests that arrived before the Flutter side was listening).
///
/// Requests are buffered rather than fired: a share can arrive before the
/// home page is mounted (cold launch from the share sheet) or while another
/// share sheet is open. The home page listens to [updates] and drains with
/// [take] whenever it is able to present a sheet.
class ShareRequestInbox {
  ShareRequestInbox._();

  static final _pending = <ShareRequest>[];
  static final _controller = StreamController<void>.broadcast();

  /// Fires whenever a request is queued. Payloads are read with [take].
  static Stream<void> get updates => _controller.stream;

  static bool get hasPending => _pending.isNotEmpty;

  static void push(ShareRequest request) {
    _pending.add(request);
    _controller.add(null);
  }

  /// Removes and returns the oldest queued request, or null when empty.
  /// One at a time: the home page presents a single sheet and drains again
  /// when it closes.
  static ShareRequest? takeFirst() {
    if (_pending.isEmpty) {
      return null;
    }
    return _pending.removeAt(0);
  }
}
