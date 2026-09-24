// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/peer_messaging.dart';
import '../services/ipn.dart';

/// Staging of outgoing peer-message attachments, shared by the thread
/// composer and the share sheet.
///
/// An attachment is first copied into the app's managed attachment store
/// (application support), which is what the thread view reads back when it
/// renders or saves the message. On iOS/macOS a second copy is staged into
/// the shared app-group folder, because the daemon (network extension or
/// cylonixd) pushes attachments from disk itself and cannot read the app's
/// private container.

/// Sanitised per-profile folder name; attachments are scoped by login
/// profile so switching accounts never mixes stores.
String attachmentScopeFolderName(String profileId) {
  if (profileId.isEmpty) {
    return 'default';
  }
  return profileId.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
}

Future<Directory> managedAttachmentDirectory(String profileId) async {
  final supportDir = await getApplicationSupportDirectory();
  final attachmentsDir = Directory(
    p.join(
      supportDir.path,
      'peer_messaging',
      'attachments',
      attachmentScopeFolderName(profileId),
    ),
  );
  await attachmentsDir.create(recursive: true);
  return attachmentsDir;
}

/// Copies [sourcePath] into the managed store (and the shared staging folder
/// on Apple platforms) and returns the path the message should carry.
Future<String> prepareOutgoingAttachmentPath({
  required IpnService ipn,
  required String profileId,
  required String sourcePath,
  required String fileName,
  required String attachmentId,
}) async {
  final attachmentsDir = await managedAttachmentDirectory(profileId);
  final managedPath = p.join(attachmentsDir.path, '${attachmentId}_$fileName');
  final destination = File(managedPath);
  if (await destination.exists()) {
    await destination.delete();
  }
  await File(sourcePath).copy(destination.path);

  if (!(Platform.isIOS || Platform.isMacOS)) {
    return managedPath;
  }

  final sharedFolderPath = await ipn.getSharedFolderPath();
  if (sharedFolderPath == null || sharedFolderPath.isEmpty) {
    return managedPath;
  }

  final stagingDir = Directory(
    p.join(
      sharedFolderPath,
      'peer-messaging',
      'attachments',
      attachmentScopeFolderName(profileId),
    ),
  );
  await stagingDir.create(recursive: true);

  final extension = p.extension(fileName);
  final baseName = p.basenameWithoutExtension(fileName);
  final stagedPath =
      p.join(stagingDir.path, '${baseName}_$attachmentId$extension');
  await File(managedPath).copy(stagedPath);
  return stagedPath;
}

/// Builds a ready-to-send attachment for [sourcePath], staging a copy so the
/// caller may delete or move the original afterwards.
Future<PeerMessagingAttachment> stageOutgoingAttachment({
  required IpnService ipn,
  required String profileId,
  required String sourcePath,
  required String fileName,
  int? size,
  String? mimeType,
}) async {
  final attachmentId = const Uuid().v4();
  final resolvedSize = size ?? await File(sourcePath).length();
  final preparedPath = await prepareOutgoingAttachmentPath(
    ipn: ipn,
    profileId: profileId,
    sourcePath: sourcePath,
    fileName: fileName,
    attachmentId: attachmentId,
  );
  return PeerMessagingAttachment(
    id: attachmentId,
    transferId: null,
    name: fileName,
    size: resolvedSize,
    mimeType: mimeType ?? p.extension(fileName).replaceFirst('.', ''),
    path: preparedPath,
  );
}
