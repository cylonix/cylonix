// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';
import 'package:flutter/foundation.dart';

/// What a shared item originally was. The share extension writes text and
/// links to disk as .txt / .webloc so File Drop can push them; a peer
/// message sends their content as the message body instead.
enum SharedFileKind {
  file,
  text,
  url;

  static SharedFileKind fromString(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'text':
        return SharedFileKind.text;
      case 'url':
      case 'link':
        return SharedFileKind.url;
      default:
        return SharedFileKind.file;
    }
  }
}

@immutable
class SharedFile {
  final String path;
  final String name;
  final int size;
  final SharedFileKind kind;

  const SharedFile({
    required this.path,
    required this.name,
    required this.size,
    this.kind = SharedFileKind.file,
  });

  /// True for items that should travel as attachments; text and links are
  /// only files for the File Drop path.
  bool get isAttachment => kind == SharedFileKind.file;

  factory SharedFile.fromPath(String path) {
    final file = File(path);
    return SharedFile(
      path: path,
      name: file.uri.pathSegments.last,
      size: file.lengthSync(),
    );
  }

  /// Builds an entry from a share-request manifest. The manifest carries the
  /// original display name (the on-disk name may be a UUID) and the size; a
  /// missing size is read from disk.
  factory SharedFile.fromJson(Map<String, dynamic> json) {
    final path = (json['path'] as String?) ?? '';
    if (path.isEmpty) {
      throw const FormatException('shared file entry has no path');
    }
    final file = File(path);
    var name = (json['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) {
      name = file.uri.pathSegments.last;
    }
    var size = (json['size'] as num?)?.toInt() ?? 0;
    if (size <= 0 && file.existsSync()) {
      size = file.lengthSync();
    }
    return SharedFile(
      path: path,
      name: name,
      size: size,
      kind: SharedFileKind.fromString(json['kind'] as String?),
    );
  }
}

/// How the user wants shared files delivered.
enum ShareMode {
  /// Cylonix File Transfer (taildrop): pushed straight to a device.
  fileDrop,

  /// Attached to a peer message in an existing or new thread.
  peerMessage;

  static ShareMode fromString(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'peer-message':
      case 'peer_message':
      case 'peermessage':
      case 'message':
        return ShareMode.peerMessage;
      default:
        return ShareMode.fileDrop;
    }
  }
}

/// A share handed to the app by a platform share entry point (the Apple share
/// extension, the Windows share window forwarding to a running instance).
@immutable
class ShareRequest {
  final List<SharedFile> files;
  final ShareMode mode;

  /// The files are temporary copies made for this share (e.g. by the share
  /// extension into the app-group container). The app owns them and deletes
  /// them once every send that references them has finished.
  final bool ephemeral;

  /// Where the request came from, for logs only.
  final String source;

  /// Shared text and links, as the sender provided them. A peer message
  /// uses this as its body; File Drop uses the .txt/.webloc entries in
  /// [files] instead.
  final String text;

  const ShareRequest({
    required this.files,
    this.mode = ShareMode.fileDrop,
    this.ephemeral = false,
    this.source = 'unknown',
    this.text = '',
  });

  factory ShareRequest.fromJson(Map<String, dynamic> json) {
    final entries = (json['files'] as List<dynamic>?) ?? const [];
    final files = <SharedFile>[];
    for (final entry in entries) {
      if (entry is Map) {
        files.add(SharedFile.fromJson(Map<String, dynamic>.from(entry)));
      } else if (entry is String && entry.isNotEmpty) {
        files.add(SharedFile.fromPath(entry));
      }
    }
    return ShareRequest(
      files: files,
      mode: ShareMode.fromString(json['mode'] as String?),
      ephemeral: json['ephemeral'] as bool? ?? false,
      source: json['source'] as String? ?? 'unknown',
      text: (json['text'] as String?)?.trim() ?? '',
    );
  }

  List<String> get paths => files.map((f) => f.path).toList();

  @override
  String toString() =>
      'ShareRequest(mode: $mode, files: ${files.length}, text: ${text.length} chars, ephemeral: $ephemeral, source: $source)';
}

class ShareFileEvent {
  final String args;

  ShareFileEvent(this.args);

  @override
  String toString() {
    return 'ShareFileEvent(args: $args)';
  }
}
