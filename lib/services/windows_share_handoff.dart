// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../models/shared_file.dart';
import '../utils/logger.dart';

/// Hands a share from the Windows share window (the `--share` process that
/// Explorer's "Share with Cylonix" launches) over to the main app.
///
/// File Drop is handled in the share window itself. A peer message needs the
/// app's message store and outbound queue, which a second process must not
/// write to, so that path mirrors the Apple share extension: the share window
/// writes a request manifest and starts `cylonix.exe --share-request <path>`.
/// The runner forwards the path to a main window that is already up
/// (WM_COPYDATA, delivered to Dart as `onShareRequest` on the share channel)
/// or, when none is, becomes the main app and Dart reads the argument at
/// startup. Either way the request lands in [ShareRequestInbox] and the home
/// page presents the send sheet in Peer Message mode.
class WindowsShareHandoff {
  WindowsShareHandoff._();

  static final _logger = Logger(tag: 'WindowsShareHandoff');

  /// Command-line flag carrying a manifest path to the main app.
  static const argument = '--share-request';

  /// Folder the share window drops manifests into. Per user, so both
  /// processes (same user) can reach it.
  static Directory get _requestDir {
    final base = Platform.environment['LOCALAPPDATA'] ??
        Platform.environment['TEMP'] ??
        Directory.systemTemp.path;
    return Directory('$base\\Cylonix\\share-requests');
  }

  /// Writes the manifest for [files] and returns its path.
  static Future<String> writeManifest(
    List<SharedFile> files, {
    ShareMode mode = ShareMode.peerMessage,
    String text = '',
  }) async {
    final dir = _requestDir;
    await dir.create(recursive: true);
    final path = '${dir.path}\\${const Uuid().v4()}.json';
    final manifest = <String, dynamic>{
      'files': [
        for (final file in files)
          {
            'path': file.path,
            'name': file.name,
            'size': file.size,
            'kind': file.kind.name,
          },
      ],
      'mode': mode == ShareMode.peerMessage ? 'peer-message' : 'file-drop',
      // The share window is given the user's own files, not temp copies.
      'ephemeral': false,
      'source': 'windows-share',
      'text': text,
    };
    await File(path).writeAsString(jsonEncode(manifest), flush: true);
    return path;
  }

  /// Writes the manifest and starts the main app (or the forwarding process
  /// when the app is already running) with it.
  static Future<HandoffResult> handOffToApp(
    List<SharedFile> files, {
    String text = '',
  }) async {
    final String path;
    try {
      path = await writeManifest(files, text: text);
    } catch (e) {
      _logger.e('Failed to write share request manifest: $e');
      return HandoffResult.notWritten;
    }
    try {
      final process = await Process.start(
        Platform.resolvedExecutable,
        [argument, path],
        mode: ProcessStartMode.detached,
      );
      _logger.i(
        'Handed share request to the app: manifest=$path pid=${process.pid}',
      );
      return HandoffResult.started;
    } catch (e) {
      _logger.e('Failed to start the app for the share request: $e');
      return HandoffResult.notStarted;
    }
  }

  /// Manifest paths this process has already turned into requests, so
  /// [drainPending] does not queue the one passed on the command line a
  /// second time.
  static final _claimed = <String>{};

  /// Reads a manifest written by [writeManifest]. The file stays on disk
  /// until [consume] runs for the presented request, so a process that dies
  /// before then leaves it for the next launch to recover. Returns null when
  /// the file is missing, unreadable, or has nothing to send.
  static Future<ShareRequest?> loadManifest(String path) async {
    final file = File(path);
    String contents;
    try {
      contents = await file.readAsString();
    } catch (e) {
      _logger.e('Failed to read share request manifest $path: $e');
      return null;
    }
    _claimed.add(path);
    try {
      final json = Map<String, dynamic>.from(jsonDecode(contents) as Map);
      final request = ShareRequest.fromJson(json).withManifestPath(path);
      if (request.files.isEmpty && request.text.isEmpty) {
        _logger.w('Share request manifest $path has nothing to send');
        await consume(request);
        return null;
      }
      return request;
    } catch (e) {
      _logger.e('Failed to parse share request manifest $path: $e');
      await _delete(path);
      return null;
    }
  }

  /// Removes the manifest behind [request] once it has been presented. A
  /// no-op for requests that did not come from a manifest.
  static Future<void> consume(ShareRequest request) async {
    final path = request.manifestPath;
    if (path == null) {
      return;
    }
    await _delete(path);
  }

  static Future<void> _delete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      _logger.w('Failed to delete share request manifest $path: $e');
    }
  }

  /// Manifests a hand-off left behind: the app failed to start, or the
  /// process that read them died before the home page could present them.
  /// Oldest first; skips manifests this process has already loaded.
  static Future<List<ShareRequest>> drainPending() async {
    final dir = _requestDir;
    if (!await dir.exists()) {
      return const [];
    }
    final manifests = <File>[];
    await for (final entry in dir.list()) {
      if (entry is File &&
          entry.path.toLowerCase().endsWith('.json') &&
          !_claimed.contains(entry.path)) {
        manifests.add(entry);
      }
    }
    manifests.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
    final requests = <ShareRequest>[];
    for (final manifest in manifests) {
      final request = await loadManifest(manifest.path);
      if (request != null) {
        requests.add(request);
      }
    }
    return requests;
  }
}

/// Outcome of [WindowsShareHandoff.handOffToApp].
enum HandoffResult {
  /// The app (or the forwarder to a running app) was started with the
  /// manifest.
  started,

  /// The manifest is on disk but no process could be started; the app picks
  /// it up on its next launch.
  notStarted,

  /// The manifest could not be written; nothing is queued anywhere.
  notWritten,
}
