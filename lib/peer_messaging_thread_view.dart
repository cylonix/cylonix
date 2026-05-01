// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:downloadsfolder/downloadsfolder.dart' as dlf;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import 'models/ipn.dart';
import 'models/peer_messaging.dart';
import 'providers/ipn.dart';
import 'providers/peer_messaging.dart';
import 'services/ipn.dart';
import 'utils/utils.dart';
import 'widgets/adaptive_widgets.dart';
import 'widgets/alert_dialog_widget.dart';
import 'widgets/link_preview.dart';
import 'utils/logger.dart';

class PeerMessagingThreadView extends ConsumerStatefulWidget {
  final String conversationId;
  final VoidCallback? onNavigateBack;

  const PeerMessagingThreadView({
    super.key,
    required this.conversationId,
    this.onNavigateBack,
  });

  @override
  ConsumerState<PeerMessagingThreadView> createState() =>
      _PeerMessagingThreadViewState();
}

class _PeerMessagingThreadViewState
    extends ConsumerState<PeerMessagingThreadView> {
  static final _logger = Logger(tag: 'PeerMessageThread');
  final _controller = TextEditingController();
  final _composerFocusNode = FocusNode();
  final _messagesScrollController = ScrollController();
  final List<PeerMessagingAttachment> _pendingAttachments = [];
  final Map<String, GlobalKey> _messageKeys = {};
  final Map<String, String> _resolvedAttachmentPaths = {};
  final Set<String> _persistingResolvedAttachmentPaths = {};
  PeerMessagingMessage? _replyToMessage;
  bool _sending = false;
  int _lastRenderedMessageCount = 0;
  int _scrollToBottomRequest = 0;
  PeerMessagingConversation? _lastSeenConversation;

  bool get _useDesktopEnterToSend =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(peerMessagingServiceProvider.notifier)
          .markConversationRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _composerFocusNode.dispose();
    _messagesScrollController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    _composerFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  bool _isConnected() {
    return ref.read(vpnStateProvider) == VpnState.connected;
  }

  Future<void> _pickAttachments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: false,
      );
      if (result == null || !mounted) {
        return;
      }

      final existingKeys = _pendingAttachments
          .map((item) => '${item.name}:${item.size}')
          .toSet();
      final pickedAttachments = <PeerMessagingAttachment>[];

      for (final file in result.files) {
        final sourcePath = file.path;
        if ((sourcePath ?? '').isEmpty) {
          continue;
        }
        final attachmentId = const Uuid().v4();
        final key = '${file.name}:${file.size}';
        if (existingKeys.contains(key)) {
          continue;
        }
        final preparedPath = await _prepareAttachmentPath(
          sourcePath!,
          file.name,
          attachmentId,
        );
        pickedAttachments.add(
          PeerMessagingAttachment(
            id: attachmentId,
            transferId: null,
            name: file.name,
            size: file.size,
            mimeType: file.extension,
            path: preparedPath,
          ),
        );
        existingKeys.add(key);
      }

      if (!mounted || pickedAttachments.isEmpty) {
        return;
      }

      setState(() {
        _pendingAttachments.addAll(pickedAttachments);
      });
    } catch (e) {
      if (mounted) {
        await showAlertDialog(context, 'Attachment Failed', '$e');
      }
    }
  }

  Future<String> _prepareAttachmentPath(
    String sourcePath,
    String fileName,
    String attachmentId,
  ) async {
    final managedPath = await _storeAttachmentCopy(
      sourcePath: sourcePath,
      fileName: fileName,
      attachmentId: attachmentId,
    );

    if (!(Platform.isIOS || Platform.isMacOS)) {
      return managedPath;
    }

    final sharedFolderPath =
        await ref.read(ipnServiceProvider).getSharedFolderPath();
    if (sharedFolderPath == null || sharedFolderPath.isEmpty) {
      return managedPath;
    }

    final attachmentsDir = Directory(
      p.join(
        sharedFolderPath,
        'peer-messaging',
        'attachments',
        _attachmentScopeFolderName(),
      ),
    );
    await attachmentsDir.create(recursive: true);

    final extension = p.extension(fileName);
    final baseName = p.basenameWithoutExtension(fileName);
    final stagedName = '${baseName}_$attachmentId$extension';
    final stagedPath = p.join(attachmentsDir.path, stagedName);
    await File(managedPath).copy(stagedPath);
    return stagedPath;
  }

  Future<String> _storeAttachmentCopy({
    required String sourcePath,
    required String fileName,
    required String attachmentId,
  }) async {
    final attachmentsDir = await _managedAttachmentDirectory();
    final managedPath =
        p.join(attachmentsDir.path, '${attachmentId}_$fileName');
    final source = File(sourcePath);
    final destination = File(managedPath);
    if (await destination.exists()) {
      await destination.delete();
    }
    await source.copy(destination.path);
    return destination.path;
  }

  Future<void> _sendMessage(PeerMessagingConversation conversation) async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) {
      return;
    }
    if (!_isConnected()) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Cannot send: not connected'),
        ),
      );
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await ref.read(peerMessagingServiceProvider.notifier).sendTextMessage(
            conversation.id,
            text,
            conversationTitle: conversation.title,
            attachments:
                List<PeerMessagingAttachment>.from(_pendingAttachments),
            replyToMessageId: _replyToMessage?.id,
          );
      _controller.clear();
      if (mounted) {
        setState(() {
          _pendingAttachments.clear();
          _replyToMessage = null;
        });
        _scrollToBottomWhenReady(animated: true);
      }
    } catch (e) {
      _logger.w('Send failed and was stored on the message: $e');
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _showFailedMessageDialog(PeerMessagingMessage message) async {
    final failureMessage = message.failureMessage ??
        message.metadata['failure_message'] as String? ??
        'This message could not be delivered.';
    if (!mounted) {
      return;
    }

    final shouldRetry = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog.adaptive(
            title: const Text('Message Not Delivered'),
            content: Text(failureMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Send Again'),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldRetry) {
      return;
    }
    await _retryMessage(message);
  }

  Future<void> _retryMessage(PeerMessagingMessage message) async {
    try {
      await ref.read(peerMessagingServiceProvider.notifier).resendFailedMessage(
            conversationId: widget.conversationId,
            messageId: message.id,
          );
    } catch (e) {
      if (mounted) {
        await showAlertDialog(context, 'Retry Failed', '$e');
      }
    }
  }

  void _beginReply(PeerMessagingMessage message) {
    setState(() {
      _replyToMessage = message;
    });
  }

  void _clearReply() {
    if (_replyToMessage == null) {
      return;
    }
    setState(() {
      _replyToMessage = null;
    });
  }

  GlobalKey _messageKeyFor(String messageId) {
    return _messageKeys.putIfAbsent(
      messageId,
      () => GlobalObjectKey('peer-message-$messageId'),
    );
  }

  Future<void> _deleteMessage(PeerMessagingMessage message) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog.adaptive(
            title: const Text('Delete Message'),
            content: const Text(
              'Delete this message from this device?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    await ref.read(peerMessagingServiceProvider.notifier).deleteMessage(
          conversationId: widget.conversationId,
          messageId: message.id,
        );
    if (mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Message deleted')),
      );
    }
  }

  String _attachmentCacheKey(
      String messageId, PeerMessagingAttachment attachment) {
    return '$messageId:${attachment.id}';
  }

  Future<void> _persistResolvedAttachmentPath({
    required String messageId,
    required PeerMessagingAttachment attachment,
    required String resolvedPath,
  }) async {
    if (resolvedPath.isEmpty) {
      return;
    }
    final cacheKey = _attachmentCacheKey(messageId, attachment);
    _resolvedAttachmentPaths[cacheKey] = resolvedPath;
    if (attachment.path == resolvedPath ||
        _persistingResolvedAttachmentPaths.contains(cacheKey)) {
      return;
    }

    _persistingResolvedAttachmentPaths.add(cacheKey);
    try {
      await ref
          .read(peerMessagingServiceProvider.notifier)
          .updateAttachmentPath(
            conversationId: widget.conversationId,
            messageId: messageId,
            attachmentId: attachment.id,
            resolvedPath: resolvedPath,
          );
    } finally {
      _persistingResolvedAttachmentPaths.remove(cacheKey);
    }
  }

  Future<void> _saveAttachment(
    String messageId,
    PeerMessagingAttachment attachment,
  ) async {
    try {
      final managedPath = await _resolveManagedAttachmentPath(
        messageId,
        attachment,
      );
      final waitingFile = await _resolveCurrentWaitingFileForAttachment(
        attachment,
      );
      final sourceFileName = waitingFile?.name ?? attachment.name;
      _logger.d(
        'Save attachment requested: conversation=${widget.conversationId} transferId=${attachment.transferId ?? attachment.id} name=${attachment.name} storedPath=${attachment.path} managedPath=$managedPath waitingFile=${waitingFile?.name} waitingPath=${waitingFile?.path}',
      );
      var showPath = attachment.name;
      if (Platform.isAndroid) {
        final srcPath = await ref
            .read(ipnStateNotifierProvider.notifier)
            .getFilePath(sourceFileName);
        await dlf.copyFileIntoDownloadFolder(srcPath, sourceFileName);
        showPath = 'the "Download" folder';
      } else if (Platform.isMacOS) {
        final toPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Choose the file to be saved',
          fileName: sourceFileName,
        );
        if (toPath == null) return;
        final waitingPath = waitingFile?.path;
        String? srcPath = managedPath ??
            ((waitingPath != null && await File(waitingPath).exists())
                ? waitingPath
                : null);
        if (srcPath == null) {
          if (IpnService.isDirectDistribution && waitingFile != null) {
            // Download from daemon via HTTP local API directly to target
            await ref.read(ipnServiceProvider).saveFile(sourceFileName, toPath);
            srcPath = toPath;
          } else {
            srcPath = await ref
                .read(ipnStateNotifierProvider.notifier)
                .getFilePath(sourceFileName);
          }
        }
        _logger.d(
          'macOS save source resolved: sourceFileName=$sourceFileName srcPath=$srcPath toPath=$toPath',
        );
        if (srcPath != toPath) {
          await File(srcPath).copy(toPath);
        }
        showPath = toPath;
      } else if (Platform.isIOS) {
        final srcPath = managedPath ??
            ((attachment.path ?? '').isNotEmpty &&
                    await File(attachment.path!).exists()
                ? attachment.path
                : null) ??
            (waitingFile?.path != null &&
                    await File(waitingFile!.path!).exists()
                ? waitingFile.path
                : null);
        if (srcPath == null || srcPath.isEmpty) {
          throw Exception(
            'Attachment file is not available yet on this device',
          );
        }
        final toPath = await _iosAttachmentSavePath(sourceFileName);
        await File(srcPath).copy(toPath);
        showPath = toPath;
      } else {
        final toPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Choose the file to be saved',
          fileName: sourceFileName,
        );
        if (toPath == null) return;
        await ref.read(ipnStateNotifierProvider.notifier).saveFile(
              sourceFileName,
              toPath,
            );
        showPath = toPath;
      }
      ref.read(filesSavedProvider.notifier).addFile(attachment.name);
      if (mounted) {
        showTopSnackBar(
          context,
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'File saved successfully to $showPath',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          displayDuration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      if (mounted) {
        await showAlertDialog(context, 'Error', 'Failed to save file: $e');
      }
    }
  }

  Future<void> _openAttachment(
    String messageId,
    PeerMessagingAttachment attachment,
  ) async {
    try {
      final resolvedPath = await _resolveAttachmentOpenPath(
        messageId,
        attachment,
        refreshWaitingFiles: true,
      );
      if (resolvedPath == null || resolvedPath.isEmpty) {
        throw Exception('Attachment file is not available yet on this device');
      }

      if (!mounted) {
        return;
      }

      if (_isPreviewableImage(attachment, resolvedPath)) {
        await showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            clipBehavior: Clip.antiAlias,
            insetPadding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 920,
                maxHeight: 720,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            attachment.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Open externally',
                          onPressed: () => _launchAttachmentExternally(
                            resolvedPath,
                          ),
                          icon: Icon(
                            isApple()
                                ? CupertinoIcons.arrow_up_right_square
                                : Icons.open_in_new,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            isApple() ? CupertinoIcons.xmark : Icons.close,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4,
                      child: Center(
                        child: Image.file(
                          File(resolvedPath),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Unable to preview this image.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }

      await _launchAttachmentExternally(resolvedPath);
    } catch (e) {
      if (mounted) {
        await showAlertDialog(context, 'Open Attachment Failed', '$e');
      }
    }
  }

  Future<String?> _resolveAttachmentOpenPath(
    String messageId,
    PeerMessagingAttachment attachment, {
    bool refreshWaitingFiles = false,
  }) async {
    final cacheKey = _attachmentCacheKey(messageId, attachment);
    final cachedPath = _resolvedAttachmentPaths[cacheKey];
    if ((cachedPath ?? '').isNotEmpty && await File(cachedPath!).exists()) {
      return cachedPath;
    }

    final waitingFile = await _resolveCurrentWaitingFileForAttachment(
      attachment,
      refreshWaitingFiles: refreshWaitingFiles,
    );
    final sourcePath = await _resolveAttachmentSourcePath(
      messageId,
      attachment,
      waitingFile: waitingFile,
    );
    if ((sourcePath ?? '').isNotEmpty) {
      return sourcePath;
    }

    if (!kIsWeb &&
        !(Platform.isIOS || Platform.isMacOS) &&
        attachment.name.isNotEmpty) {
      try {
        return await ref
            .read(ipnStateNotifierProvider.notifier)
            .getFilePath(waitingFile?.name ?? attachment.name);
      } catch (_) {}
    }

    return null;
  }

  Future<String?> _resolveAttachmentSourcePath(
    String messageId,
    PeerMessagingAttachment attachment, {
    AwaitingFile? waitingFile,
  }) async {
    final managedPath = await _resolveManagedAttachmentPath(
      messageId,
      attachment,
    );
    if ((managedPath ?? '').isNotEmpty) {
      return managedPath;
    }

    if ((attachment.path ?? '').isNotEmpty &&
        await File(attachment.path!).exists()) {
      return attachment.path;
    }

    if ((waitingFile?.path ?? '').isNotEmpty &&
        await File(waitingFile!.path!).exists()) {
      return waitingFile.path;
    }

    return null;
  }

  bool _isPreviewableImage(
    PeerMessagingAttachment attachment,
    String path,
  ) {
    final lowerMime = (attachment.mimeType ?? '').toLowerCase();
    if (lowerMime.startsWith('image/')) {
      return true;
    }

    final extension = p.extension(path).toLowerCase();
    return {
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.webp',
      '.bmp',
      '.heic',
      '.heif',
    }.contains(extension);
  }

  Future<void> _launchAttachmentExternally(String path) async {
    if (Platform.isIOS) {
      await ref.read(ipnServiceProvider).previewLocalFile(path);
      return;
    }
    final launched = await launchUrl(
      Uri.file(path),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw Exception('No application was available to open this attachment');
    }
  }

  Future<String?> _resolveManagedAttachmentPath(
    String messageId,
    PeerMessagingAttachment attachment,
  ) async {
    final cacheKey = _attachmentCacheKey(messageId, attachment);
    final cachedPath = _resolvedAttachmentPaths[cacheKey];
    if ((cachedPath ?? '').isNotEmpty && await File(cachedPath!).exists()) {
      return cachedPath;
    }

    final attachmentPath = attachment.path;
    if ((attachmentPath ?? '').isNotEmpty &&
        await File(attachmentPath!).exists()) {
      _resolvedAttachmentPaths[cacheKey] = attachmentPath;
      return attachmentPath;
    }

    final transferId = attachment.transferId ?? attachment.id;
    if (transferId.isEmpty) {
      return null;
    }

    final remappedIosPath = await _resolveCurrentIosAttachmentPath(attachment);
    if ((remappedIosPath ?? '').isNotEmpty) {
      await _persistResolvedAttachmentPath(
        messageId: messageId,
        attachment: attachment,
        resolvedPath: remappedIosPath!,
      );
      return remappedIosPath;
    }

    final attachmentsDir = await _managedAttachmentDirectory();
    final deterministicPath = p.join(
      attachmentsDir.path,
      '${transferId}_${attachment.name}',
    );
    if (await File(deterministicPath).exists()) {
      await _persistResolvedAttachmentPath(
        messageId: messageId,
        attachment: attachment,
        resolvedPath: deterministicPath,
      );
      return deterministicPath;
    }

    return null;
  }

  Future<String?> _resolveCurrentIosAttachmentPath(
    PeerMessagingAttachment attachment,
  ) async {
    if (!Platform.isIOS) {
      return null;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(p.join(docsDir.path, 'Downloads'));
    if (!await downloadsDir.exists()) {
      return null;
    }

    final candidates = <String>{};
    final storedBaseName = p.basename(attachment.path ?? '');
    if (storedBaseName.isNotEmpty && storedBaseName != '.') {
      candidates.add(storedBaseName);
    }
    if (attachment.name.isNotEmpty) {
      candidates.add(attachment.name);
    }

    for (final fileName in candidates) {
      final candidatePath = p.join(downloadsDir.path, fileName);
      if (await File(candidatePath).exists()) {
        return candidatePath;
      }
    }
    return null;
  }

  Future<Directory> _managedAttachmentDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final attachmentsDir = Directory(
      p.join(
        supportDir.path,
        'openclaw',
        'attachments',
        _attachmentScopeFolderName(),
      ),
    );
    await attachmentsDir.create(recursive: true);
    return attachmentsDir;
  }

  Future<String> _iosAttachmentSavePath(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(
      p.join(
        dir.path,
        'downloads',
        'peer-messaging',
        _attachmentScopeFolderName(),
      ),
    );
    await attachmentsDir.create(recursive: true);

    final candidate = File(p.join(attachmentsDir.path, fileName));
    if (!await candidate.exists()) {
      return candidate.path;
    }

    final extension = p.extension(fileName);
    final baseName = p.basenameWithoutExtension(fileName);
    for (var i = 1; i <= 100; i++) {
      final path = p.join(attachmentsDir.path, '$baseName ($i)$extension');
      if (!await File(path).exists()) {
        return path;
      }
    }
    return p.join(
      attachmentsDir.path,
      '${baseName}_${DateTime.now().millisecondsSinceEpoch}$extension',
    );
  }

  String _attachmentScopeFolderName() {
    final profileId = ref.read(currentLoginProfileProvider)?.id ?? 'default';
    return profileId.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  Future<AwaitingFile?> _resolveCurrentWaitingFileForAttachment(
      PeerMessagingAttachment attachment,
      {bool refreshWaitingFiles = false}) async {
    final notifier = ref.read(ipnStateNotifierProvider.notifier);
    if (refreshWaitingFiles) {
      try {
        final refreshedWaitingFiles = await notifier.getWaitingFiles(
          timeoutMilliseconds: 1000,
          ignoreErrors: true,
        );
        final refreshedMatch = _matchWaitingFileForAttachment(
          attachment,
          refreshedWaitingFiles ?? const [],
        );
        if (refreshedMatch != null) {
          return refreshedMatch;
        }
      } catch (_) {}
    }

    return _matchWaitingFileForAttachment(
      attachment,
      ref.read(filesWaitingProvider),
    );
  }

  Future<String?> _resolveAttachmentPreviewPath(
    String messageId,
    PeerMessagingAttachment attachment,
  ) async {
    final cacheKey = _attachmentCacheKey(messageId, attachment);
    final cachedPath = _resolvedAttachmentPaths[cacheKey];
    if ((cachedPath ?? '').isNotEmpty && await File(cachedPath!).exists()) {
      return cachedPath;
    }

    final waitingFile = _matchWaitingFileForAttachment(
      attachment,
      ref.read(filesWaitingProvider),
    );

    return _resolveAttachmentSourcePath(
      messageId,
      attachment,
      waitingFile: waitingFile,
    );
  }

  AwaitingFile? _matchWaitingFileForAttachment(
    PeerMessagingAttachment attachment,
    List<AwaitingFile> waitingFiles,
  ) {
    final transferId = attachment.transferId ?? attachment.id;
    final transferIdMatch = waitingFiles.firstWhereOrNull(
      (file) => file.id == transferId,
    );
    if (transferIdMatch != null) {
      return transferIdMatch;
    }

    final exactMatch = waitingFiles.firstWhereOrNull(
      (file) => file.name == attachment.name,
    );
    if (exactMatch != null) {
      return exactMatch;
    }

    final normalizedAttachmentName = _normalizeWaitingFileName(attachment.name);
    final normalizedNameMatches = waitingFiles
        .where(
          (file) =>
              _normalizeWaitingFileName(file.name) == normalizedAttachmentName,
        )
        .toList();
    if (normalizedNameMatches.length == 1) {
      return normalizedNameMatches.first;
    }

    final sizeMatches =
        waitingFiles.where((file) => file.size == attachment.size).toList();
    if (sizeMatches.length == 1) {
      return sizeMatches.first;
    }

    final normalizedNameAndSizeMatches = waitingFiles
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

  static bool _isLocalMessage(PeerMessagingMessage value) {
    return !(value.metadata['is_inbound'] == true ||
        value.metadata['from_peer_id'] != null);
  }

  static bool _messagesBelongToSameRun(
    PeerMessagingMessage first,
    PeerMessagingMessage second,
  ) {
    final firstIsLocal = _isLocalMessage(first);
    final secondIsLocal = _isLocalMessage(second);
    if (firstIsLocal != secondIsLocal) {
      return false;
    }
    if (!firstIsLocal &&
        (first.metadata['from_peer_name'] as String? ?? 'Peer') !=
            (second.metadata['from_peer_name'] as String? ?? 'Peer')) {
      return false;
    }
    final gap = second.createdAt.difference(first.createdAt).inSeconds.abs();
    return gap <= 300;
  }

  void _scheduleInitialOrNewMessageScroll(int messageCount) {
    final isFirstLayout = _lastRenderedMessageCount == 0 && messageCount > 0;
    final isNewMessage = messageCount > _lastRenderedMessageCount;
    _lastRenderedMessageCount = messageCount;
    if (isFirstLayout) {
      return;
    }
    if (isNewMessage && _isNearNewestMessage()) {
      _scrollToBottomWhenReady(animated: true);
    }
  }

  bool _isNearNewestMessage() {
    if (!_messagesScrollController.hasClients) {
      return true;
    }
    final position = _messagesScrollController.position;
    return (position.pixels - position.minScrollExtent).abs() <= 120;
  }

  void _prefetchLinkPreviews(PeerMessagingConversation conversation) {
    // Walk the most-recent messages (reverse-chronological) and queue their
    // URLs into the cache; the cache caps concurrent fetches so a long
    // history doesn't blast dozens of parallel HTTP requests on open.
    const maxScan = 40;
    final messages = conversation.messages;
    final start =
        messages.length > maxScan ? messages.length - maxScan : 0;
    for (var i = messages.length - 1; i >= start; i--) {
      final message = messages[i];
      if (message.text.isEmpty) continue;
      final url = _firstHttpUrl(message.text);
      if (url == null) continue;
      if (LinkPreviewCache.isCachedOrInFlight(url)) continue;
      LinkPreviewCache.fetch(url);
    }
  }

  void _scrollToBottomWhenReady({required bool animated}) {
    final request = ++_scrollToBottomRequest;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          request != _scrollToBottomRequest ||
          !_messagesScrollController.hasClients) {
        return;
      }
      final position = _messagesScrollController.position;
      final target = position.minScrollExtent;
      if (animated) {
        _messagesScrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      } else {
        _messagesScrollController.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(peerMessagingBootstrapProvider);
    final liveConversation =
        ref.watch(peerMessagingConversationProvider(widget.conversationId));
    final waitingFiles = ref.watch(filesWaitingProvider);
    final filesSaved = ref.watch(filesSavedProvider);
    final vpnState = ref.watch(vpnStateProvider);
    final isConnected = vpnState == VpnState.connected;
    // Cache the most recent non-null conversation so transient disconnects
    // (which can clear the active profile id and the conversation list) do
    // not blank out an open thread the user is reading.
    if (liveConversation != null) {
      _lastSeenConversation = liveConversation;
    }
    final conversation = liveConversation ?? _lastSeenConversation;
    if (conversation == null) {
      return AdaptiveScaffold(
        title: const Text('Peer Conversation'),
        onGoBack: widget.onNavigateBack,
        body: const Center(child: Text('Conversation not found')),
      );
    }

    _scheduleInitialOrNewMessageScroll(conversation.messages.length);
    _prefetchLinkPreviews(conversation);
    final renderedMessages = conversation.messages.reversed.toList(
      growable: false,
    );
    final messagesById = {
      for (final message in conversation.messages) message.id: message,
    };
    final outgoingFiles =
        ref.watch(ipnStateProvider)?.outgoingFiles ?? const [];

    return AdaptiveScaffold(
      title: _ThreadTitle(
        title: conversation.title,
        vpnState: vpnState,
      ),
      onGoBack: widget.onNavigateBack,
      body: Column(
        children: [
          if (Platform.isIOS || Platform.isMacOS) ...[
            SizedBox(height: Platform.isIOS ? 96 : 64),
          ],
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _dismissKeyboard,
                  child: ListView.separated(
                    controller: _messagesScrollController,
                    reverse: true,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final message = renderedMessages[index];
                      final previous = index + 1 < renderedMessages.length
                          ? renderedMessages[index + 1]
                          : null;
                      final next =
                          index > 0 ? renderedMessages[index - 1] : null;
                      final laterMessages = renderedMessages.take(index);
                      return KeyedSubtree(
                        key: _messageKeyFor(message.id),
                        child: _MessageBubble(
                          message: message,
                          outgoingFiles: outgoingFiles,
                          previousMessage: previous,
                          nextMessage: next,
                          replyTarget: message.replyToMessageId == null
                              ? null
                              : messagesById[message.replyToMessageId!],
                          waitingFiles: waitingFiles,
                          filesSaved: filesSaved,
                          hasLaterDeliveredMessage: laterMessages.any(
                            (item) =>
                                _isLocalMessage(item) &&
                                item.deliveryStatus ==
                                    PeerMessagingDeliveryStatus.delivered,
                          ),
                          hasLaterSentMessage: laterMessages.any(
                            (item) =>
                                _isLocalMessage(item) &&
                                item.deliveryStatus ==
                                    PeerMessagingDeliveryStatus.sent,
                          ),
                          hasLaterPendingMessage: laterMessages.any(
                            (item) =>
                                _isLocalMessage(item) &&
                                item.deliveryStatus ==
                                    PeerMessagingDeliveryStatus.pending,
                          ),
                          hasLaterFailedMessage: laterMessages.any(
                            (item) =>
                                _isLocalMessage(item) &&
                                item.deliveryStatus ==
                                    PeerMessagingDeliveryStatus.failed,
                          ),
                          onDelete: () => _deleteMessage(message),
                          onReply: () => _beginReply(message),
                          onSendAgain: _isLocalMessage(message) &&
                                  message.deliveryStatus ==
                                      PeerMessagingDeliveryStatus.failed
                              ? () => _retryMessage(message)
                              : null,
                          onShowFailureDetails: _isLocalMessage(message) &&
                                  message.deliveryStatus ==
                                      PeerMessagingDeliveryStatus.failed
                              ? () => _showFailedMessageDialog(message)
                              : null,
                          onSaveAttachment: (attachment) =>
                              _saveAttachment(message.id, attachment),
                          onOpenAttachment: (attachment) =>
                              _openAttachment(message.id, attachment),
                          resolveAttachmentPath: (attachment) =>
                              _resolveAttachmentPreviewPath(
                            message.id,
                            attachment,
                          ),
                          onApproval: (approved) async {
                            await ref
                                .read(peerMessagingServiceProvider.notifier)
                                .submitApproval(
                                  conversationId: conversation.id,
                                  approvalId: message.approvalId ?? '',
                                  approved: approved,
                                );
                          },
                          onMenuSelection: (action, title) async {
                            await ref
                                .read(peerMessagingServiceProvider.notifier)
                                .submitMenuSelection(
                                  conversationId: conversation.id,
                                  messageId: message.id,
                                  action: action,
                                  title: title,
                                );
                          },
                        ),
                      );
                    },
                    separatorBuilder: (_, index) {
                      final newer = renderedMessages[index];
                      final older = renderedMessages[index + 1];
                      final sameRun = _messagesBelongToSameRun(older, newer);
                      return SizedBox(height: sameRun ? 3 : 14);
                    },
                    itemCount: renderedMessages.length,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: Focus(
                              onKeyEvent: _useDesktopEnterToSend
                                  ? (node, event) {
                                      if (event is! KeyDownEvent) {
                                        return KeyEventResult.ignored;
                                      }
                                      final isEnter = event.logicalKey ==
                                              LogicalKeyboardKey.enter ||
                                          event.logicalKey ==
                                              LogicalKeyboardKey.numpadEnter;
                                      if (!isEnter ||
                                          HardwareKeyboard
                                              .instance.isShiftPressed) {
                                        return KeyEventResult.ignored;
                                      }
                                      _sendMessage(conversation);
                                      return KeyEventResult.handled;
                                    }
                                  : null,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    isApple() ? 20 : 12,
                                  ),
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  color: isApple()
                                      ? CupertinoColors
                                          .secondarySystemGroupedBackground
                                          .resolveFrom(context)
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    64,
                                    18,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_replyToMessage != null) ...[
                                        _ReplyComposerPreview(
                                          message: _replyToMessage!,
                                          resolveAttachmentPath: (attachment) =>
                                              _resolveAttachmentPreviewPath(
                                            _replyToMessage!.id,
                                            attachment,
                                          ),
                                          onCancel: _clearReply,
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      if (_pendingAttachments.isNotEmpty) ...[
                                        Text(
                                          _pendingAttachments.length == 1
                                              ? '1 attachment will be sent with this message'
                                              : '${_pendingAttachments.length} attachments will be sent with this message',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            for (final attachment
                                                in _pendingAttachments)
                                              InputChip(
                                                label: Text(
                                                  attachment.name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                deleteIcon: const Icon(
                                                  Icons.close,
                                                  size: 18,
                                                ),
                                                onDeleted: () {
                                                  setState(() {
                                                    _pendingAttachments
                                                        .removeWhere(
                                                      (item) =>
                                                          item.id ==
                                                          attachment.id,
                                                    );
                                                  });
                                                },
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      TextField(
                                        focusNode: _composerFocusNode,
                                        controller: _controller,
                                        minLines: 3,
                                        maxLines: 8,
                                        textInputAction:
                                            TextInputAction.newline,
                                        onTapOutside: (_) => _dismissKeyboard(),
                                        decoration: InputDecoration(
                                          hintText: isConnected
                                              ? 'Reply…'
                                              : 'Reply… (disconnected)',
                                          alignLabelWithHint: true,
                                          isCollapsed: true,
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 96,
                            bottom: 8,
                            child: ListenableBuilder(
                              listenable: _controller,
                              builder: (context, _) {
                                if (_controller.text.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return IconButton(
                                  tooltip: 'Clear',
                                  onPressed: _sending
                                      ? null
                                      : () {
                                          _controller.clear();
                                        },
                                  icon: Icon(
                                    isApple()
                                        ? CupertinoIcons.clear_circled_solid
                                        : Icons.cancel,
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            right: 56,
                            bottom: 8,
                            child: IconButton(
                              tooltip: isConnected
                                  ? 'Add attachment'
                                  : 'Disconnected',
                              onPressed: (_sending || !isConnected)
                                  ? null
                                  : _pickAttachments,
                              icon: Icon(
                                isApple()
                                    ? CupertinoIcons.paperclip
                                    : Icons.attach_file,
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(right: 10, bottom: 10),
                            child: FilledButton(
                              onPressed: (_sending || !isConnected)
                                  ? null
                                  : () => _sendMessage(conversation),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(40, 40),
                                maximumSize: const Size(40, 40),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    isApple() ? 18 : 12,
                                  ),
                                ),
                              ),
                              child: Icon(
                                isApple()
                                    ? CupertinoIcons.arrow_up
                                    : Icons.arrow_upward,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final PeerMessagingMessage message;
  final List<OutgoingFile> outgoingFiles;
  final PeerMessagingMessage? previousMessage;
  final PeerMessagingMessage? nextMessage;
  final PeerMessagingMessage? replyTarget;
  final List<AwaitingFile> waitingFiles;
  final List<String> filesSaved;
  final bool hasLaterDeliveredMessage;
  final bool hasLaterSentMessage;
  final bool hasLaterPendingMessage;
  final bool hasLaterFailedMessage;
  final VoidCallback onDelete;
  final VoidCallback onReply;
  final VoidCallback? onSendAgain;
  final VoidCallback? onShowFailureDetails;
  final Future<void> Function(PeerMessagingAttachment attachment)
      onSaveAttachment;
  final Future<void> Function(PeerMessagingAttachment attachment)
      onOpenAttachment;
  final Future<String?> Function(PeerMessagingAttachment attachment)
      resolveAttachmentPath;
  final Future<void> Function(bool approved) onApproval;
  final Future<void> Function(String action, String title) onMenuSelection;

  const _MessageBubble({
    required this.message,
    required this.outgoingFiles,
    required this.previousMessage,
    required this.nextMessage,
    required this.replyTarget,
    required this.waitingFiles,
    required this.filesSaved,
    required this.hasLaterDeliveredMessage,
    required this.hasLaterSentMessage,
    required this.hasLaterPendingMessage,
    required this.hasLaterFailedMessage,
    required this.onDelete,
    required this.onReply,
    required this.onSendAgain,
    required this.onShowFailureDetails,
    required this.onSaveAttachment,
    required this.onOpenAttachment,
    required this.resolveAttachmentPath,
    required this.onApproval,
    required this.onMenuSelection,
  });

  @override
  Widget build(BuildContext context) {
    final isLocal = _isLocal;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bubbleColor = isLocal
        ? (isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF))
        : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE9E9EB));
    final foregroundColor =
        isLocal ? Colors.white : theme.colorScheme.onSurface;
    final secondaryForegroundColor = isLocal
        ? Colors.white.withValues(alpha: 0.8)
        : theme.colorScheme.onSurfaceVariant;
    final borderRadius = _bubbleBorderRadius(isLocal);
    final replyTargetIsLocal =
        replyTarget != null ? !_isInbound(replyTarget!) : false;
    final showReplyLink =
        message.replyToMessageId != null && replyTarget != null;
    final isMediaOnlyMessage = message.text.isEmpty &&
        message.attachments.isNotEmpty &&
        message.attachments.every(_attachmentHasStandalonePreview) &&
        message.kind != PeerMessagingMessageKind.approvalRequest &&
        message.kind != PeerMessagingMessageKind.menuRequest;
    final align = isLocal ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final alignment = isLocal ? Alignment.centerRight : Alignment.centerLeft;
    final actionStyle = OutlinedButton.styleFrom(
      foregroundColor: foregroundColor,
      side: BorderSide(
        color: isLocal
            ? Colors.white.withValues(alpha: 0.28)
            : theme.colorScheme.outlineVariant,
      ),
      backgroundColor: isLocal
          ? Colors.white.withValues(alpha: 0.12)
          : theme.colorScheme.surface.withValues(alpha: 0.72),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );

    return Column(
      crossAxisAlignment: align,
      children: [
        if (_shouldShowHeader) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 2),
            child: Center(
              child: Text(
                _headerText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
        Align(
          alignment: alignment,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCrossSideReply =
                  showReplyLink && replyTargetIsLocal != isLocal;
              final availableWidth = constraints.maxWidth;
              const defaultMaxBubbleWidth = 460.0;
              double bubbleMaxWidth = defaultMaxBubbleWidth;
              if (isCrossSideReply) {
                // The reply line anchors at 1/8 from the screen edge, so the
                // bubble can extend almost the full opposite side. Cap at
                // 3/4 of the available width.
                const elbowRoom = 24.0; // cornerRadius + margin
                final anchor = isLocal
                    ? availableWidth / 8
                    : availableWidth - availableWidth / 8;
                final maxFromAnchor = isLocal
                    ? availableWidth - anchor - elbowRoom
                    : anchor - elbowRoom;
                final crossReplyCap = availableWidth * 0.75;
                bubbleMaxWidth = maxFromAnchor.clamp(120.0, crossReplyCap);
              }
              return Column(
                crossAxisAlignment: align,
                children: [
                  if (showReplyLink) ...[
                    _ReplyLinkTrail(
                      message: replyTarget!,
                      targetMessage: message,
                      isLocal: isLocal,
                      replyTargetIsLocal: replyTargetIsLocal,
                      resolveAttachmentPath: resolveAttachmentPath,
                      maxBubbleWidth: bubbleMaxWidth,
                    ),
                  ],
                  _buildBubble(
                    context,
                    isLocal: isLocal,
                    isMediaOnlyMessage: isMediaOnlyMessage,
                    bubbleColor: bubbleColor,
                    borderRadius: borderRadius,
                    foregroundColor: foregroundColor,
                    secondaryForegroundColor: secondaryForegroundColor,
                    theme: theme,
                    actionStyle: actionStyle,
                    bubbleMaxWidth: bubbleMaxWidth,
                  ),
                ],
              );
            },
          ),
        ),
        if (_buildStatusIndicator(theme) case final statusIndicator?) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: statusIndicator,
          ),
        ],
      ],
    );
  }

  Widget _buildBubble(
    BuildContext context, {
    required bool isLocal,
    required bool isMediaOnlyMessage,
    required Color bubbleColor,
    required BorderRadius borderRadius,
    required Color foregroundColor,
    required Color secondaryForegroundColor,
    required ThemeData theme,
    required ButtonStyle actionStyle,
    required double bubbleMaxWidth,
  }) {
    final hasLinkPreview = _firstHttpUrl(message.text) != null;
    // Fire the long-press / right-click sheet for media-only bubbles and for
    // bubbles that carry a link preview (so the padding around the preview
    // is also actionable). Text-only bubbles still rely on the SelectableText
    // context menu so long-press doesn't fight with the native text-selection
    // gesture; on text bubbles with a preview, SelectableText still wins on
    // the text region, and the bubble handler covers the rest.
    final showsBubbleActionMenu = message.text.isEmpty || hasLinkPreview;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: _supportsLongPressAction(context) && showsBubbleActionMenu
          ? () => _showMessageActions(context)
          : null,
      onSecondaryTapDown:
          _supportsSecondaryClickAction(context) && showsBubbleActionMenu
              ? (details) => _showMessageActions(
                    context,
                    globalPosition: details.globalPosition,
                  )
              : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
        child: IntrinsicWidth(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: isMediaOnlyMessage ? Colors.transparent : bubbleColor,
                  borderRadius: isMediaOnlyMessage ? null : borderRadius,
                ),
                child: DefaultTextStyle.merge(
                  style: theme.textTheme.bodyMedium?.copyWith(
                        color: foregroundColor,
                        height: 1.24,
                        fontSize: 16,
                        letterSpacing: -0.15,
                      ) ??
                      TextStyle(
                        color: foregroundColor,
                        height: 1.24,
                        fontSize: 16,
                      ),
                  child: IconTheme.merge(
                    data: IconThemeData(color: foregroundColor),
                    child: Padding(
                      padding: isMediaOnlyMessage
                          ? EdgeInsets.zero
                          : message.attachments.isNotEmpty
                              ? const EdgeInsetsGeometry.only(
                                  top: 8,
                                  left: 2,
                                  right: 2,
                                  bottom: 2,
                                )
                              : const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                      child: _buildBubbleContent(
                        context,
                        isLocal: isLocal,
                        isMediaOnlyMessage: isMediaOnlyMessage,
                        foregroundColor: foregroundColor,
                        secondaryForegroundColor: secondaryForegroundColor,
                        actionStyle: actionStyle,
                      ),
                    ),
                  ),
                ),
              ),
              if (_showsTail && !isMediaOnlyMessage)
                Positioned(
                  bottom: -6,
                  right: isLocal ? -2 : null,
                  left: isLocal ? null : -2,
                  child: _BubbleTail(
                    color: bubbleColor,
                    isLocal: isLocal,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubbleContent(
    BuildContext context, {
    required bool isLocal,
    required bool isMediaOnlyMessage,
    required Color foregroundColor,
    required Color secondaryForegroundColor,
    required ButtonStyle actionStyle,
  }) {
    final theme = Theme.of(context);
    final previewUrl = _firstHttpUrl(message.text);
    final previewBorderColor = isLocal
        ? Colors.white.withValues(alpha: 0.28)
        : theme.colorScheme.outlineVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text.isNotEmpty)
          Padding(
            padding: message.attachments.isNotEmpty
                ? const EdgeInsets.symmetric(horizontal: 14)
                : EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  selectionColor: isLocal
                      ? Colors.white.withValues(alpha: 0.35)
                      : Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.28),
                ),
              ),
              // Use SelectableText on every platform so the platform's
              // text-selection menu is our menu. Reply/Quote sits at the top
              // so the user doesn't need a long-press → bottom sheet detour,
              // which was fighting with the native text selection gesture on
              // mobile.
              child: SelectableText.rich(
                _buildLinkedTextSpan(
                  message.text,
                  linkColor: isLocal
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
                contextMenuBuilder: (menuContext, editableTextState) {
                  final platformExtras =
                      editableTextState.contextMenuButtonItems
                          .where(
                            (item) =>
                                item.type != ContextMenuButtonType.copy &&
                                item.type != ContextMenuButtonType.selectAll &&
                                item.type != ContextMenuButtonType.cut &&
                                item.type != ContextMenuButtonType.paste,
                          )
                          .toList();
                  return AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: editableTextState.contextMenuAnchors,
                    buttonItems: [
                      ContextMenuButtonItem(
                        label: 'Reply/Quote',
                        onPressed: () {
                          ContextMenuController.removeAny();
                          onReply();
                        },
                      ),
                      ContextMenuButtonItem(
                        label: editableTextState
                                .textEditingValue.selection.isCollapsed
                            ? 'Copy Text'
                            : 'Copy',
                        onPressed: () {
                          ContextMenuController.removeAny();
                          final sel =
                              editableTextState.textEditingValue.selection;
                          final text = sel.isCollapsed
                              ? message.text
                              : editableTextState.textEditingValue.text
                                  .substring(sel.start, sel.end);
                          Clipboard.setData(ClipboardData(text: text));
                        },
                      ),
                      ContextMenuButtonItem(
                        label: 'Select All',
                        onPressed: () {
                          editableTextState.selectAll(
                            SelectionChangedCause.toolbar,
                          );
                        },
                      ),
                      if (onSendAgain != null)
                        ContextMenuButtonItem(
                          label: 'Send Again',
                          onPressed: () {
                            ContextMenuController.removeAny();
                            onSendAgain!();
                          },
                        ),
                      for (final attachment in message.attachments)
                        ContextMenuButtonItem(
                          label: filesSaved.contains(attachment.name)
                              ? 'Save Again'
                              : 'Save',
                          onPressed: () {
                            ContextMenuController.removeAny();
                            onSaveAttachment(attachment);
                          },
                        ),
                      for (final item in platformExtras)
                        ContextMenuButtonItem(
                          label: item.label ?? _platformItemLabel(item.type),
                          onPressed: item.onPressed,
                        ),
                      ContextMenuButtonItem(
                        label: 'Delete Message',
                        onPressed: () {
                          ContextMenuController.removeAny();
                          onDelete();
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        if (previewUrl != null)
          Padding(
            padding: message.attachments.isNotEmpty
                ? const EdgeInsets.symmetric(horizontal: 14)
                : EdgeInsets.zero,
            child: LinkPreview(
              key: ValueKey('link-preview-${message.id}-$previewUrl'),
              url: previewUrl,
              foregroundColor: foregroundColor,
              secondaryColor: secondaryForegroundColor,
              borderColor: previewBorderColor,
              onLongPress: _supportsLongPressAction(context)
                  ? () => _showMessageActions(context)
                  : null,
              onSecondaryTapDown: _supportsSecondaryClickAction(context)
                  ? (globalPosition) => _showMessageActions(
                        context,
                        globalPosition: globalPosition,
                      )
                  : null,
            ),
          ),
        if (message.attachments.isNotEmpty) ...[
          if (message.text.isNotEmpty) const SizedBox(height: 8),
          for (final attachment in message.attachments)
            Padding(
              padding: EdgeInsets.only(
                bottom: attachment == message.attachments.last ? 0 : 8,
              ),
              child: _AttachmentLine(
                attachment: attachment,
                isSaved: filesSaved.contains(attachment.name),
                onTap: () => onOpenAttachment(attachment),
                resolvePath: () => resolveAttachmentPath(attachment),
                foregroundColor: foregroundColor,
                secondaryColor: secondaryForegroundColor,
                isLocal: isLocal,
              ),
            ),
        ],
        if (message.kind == PeerMessagingMessageKind.approvalRequest &&
            message.deliveryStatus != PeerMessagingDeliveryStatus.failed &&
            message.approvalId != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => onApproval(true),
                style: actionStyle,
                child: const Text('Approve'),
              ),
              OutlinedButton(
                onPressed: () => onApproval(false),
                style: actionStyle,
                child: const Text('Reject'),
              ),
            ],
          ),
        ],
        if (message.kind == PeerMessagingMessageKind.menuRequest &&
            message.deliveryStatus != PeerMessagingDeliveryStatus.failed &&
            message.menuOptions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in message.menuOptions)
                OutlinedButton(
                  onPressed: () => onMenuSelection(option.action, option.title),
                  style: actionStyle,
                  child: Text(option.title),
                ),
            ],
          ),
        ],
      ],
    );
  }

  bool get _isLocal => !_isInbound(message);

  bool get _showsTail =>
      _groupPosition == _BubbleGroupPosition.single ||
      _groupPosition == _BubbleGroupPosition.bottom;

  BorderRadius _bubbleBorderRadius(bool isLocal) {
    const outer = Radius.circular(19);
    const inner = Radius.circular(5);
    // iMessage-style: the tail-side bottom corner stays fully rounded;
    // the painted tail overlaps the rounded corner instead of replacing it.
    const tailCorner = outer;
    final position = _groupPosition;
    final hasTail = position == _BubbleGroupPosition.single ||
        position == _BubbleGroupPosition.bottom;
    if (isLocal) {
      switch (position) {
        case _BubbleGroupPosition.single:
        case _BubbleGroupPosition.top:
          return BorderRadius.only(
            topLeft: outer,
            topRight: outer,
            bottomLeft: outer,
            bottomRight: hasTail ? tailCorner : inner,
          );
        case _BubbleGroupPosition.middle:
        case _BubbleGroupPosition.bottom:
          return BorderRadius.only(
            topLeft: outer,
            topRight: inner,
            bottomLeft: outer,
            bottomRight: hasTail ? tailCorner : inner,
          );
      }
    }
    switch (position) {
      case _BubbleGroupPosition.single:
      case _BubbleGroupPosition.top:
        return BorderRadius.only(
          topLeft: outer,
          topRight: outer,
          bottomLeft: hasTail ? tailCorner : inner,
          bottomRight: outer,
        );
      case _BubbleGroupPosition.middle:
      case _BubbleGroupPosition.bottom:
        return BorderRadius.only(
          topLeft: inner,
          topRight: outer,
          bottomLeft: hasTail ? tailCorner : inner,
          bottomRight: outer,
        );
    }
  }

  Widget? _buildStatusIndicator(ThemeData theme) {
    if (!_isLocal) {
      return null;
    }

    final defaultColor = theme.colorScheme.onSurfaceVariant;
    final attachmentTransfer = _attachmentTransferProgress;
    switch (message.deliveryStatus) {
      case PeerMessagingDeliveryStatus.pending:
        if (hasLaterPendingMessage) {
          return null;
        }
        if (attachmentTransfer != null) {
          return _DeliveryProgressIndicator(
            progress: attachmentTransfer.progress,
            color: defaultColor,
          );
        }
        return _DeliveryStatusText(
          label: 'Sending',
          color: defaultColor,
        );
      case PeerMessagingDeliveryStatus.sent:
        if (hasLaterSentMessage || hasLaterDeliveredMessage) {
          return null;
        }
        return _DeliveryStatusText(
          label: 'Processing',
          color: defaultColor,
        );
      case PeerMessagingDeliveryStatus.delivered:
        if (hasLaterDeliveredMessage) {
          return null;
        }
        return _DeliveryStatusText(
          label: 'Delivered',
          color: defaultColor,
        );
      case PeerMessagingDeliveryStatus.failed:
        if (hasLaterFailedMessage) {
          return _DeliveryFailureIcon(onTap: onShowFailureDetails);
        }
        return _DeliveryFailureSummary(
          color: theme.colorScheme.error,
          onTap: onShowFailureDetails,
        );
    }
  }

  _AttachmentTransferProgress? get _attachmentTransferProgress {
    if (message.attachments.isNotEmpty) {
      final matched = <OutgoingFile>[];
      for (final attachment in message.attachments) {
        final transferId = attachment.transferId ?? attachment.id;
        final file =
            outgoingFiles.firstWhereOrNull((item) => item.id == transferId);
        if (file != null) {
          matched.add(file);
        }
      }
      if (matched.isNotEmpty) {
        final totalSize =
            matched.fold<int>(0, (sum, file) => sum + file.declaredSize);
        final totalSent = matched.fold<int>(0, (sum, file) => sum + file.sent);
        final progress = totalSize > 0 ? totalSent / totalSize : 0.0;
        return _AttachmentTransferProgress(
          progress: progress.clamp(0.0, 1.0),
        );
      }
    }

    final cachedProgress =
        (message.metadata['transfer_progress'] as num?)?.toDouble();
    if (cachedProgress == null || cachedProgress <= 0) {
      return null;
    }
    return _AttachmentTransferProgress(
      progress: cachedProgress.clamp(0.0, 1.0),
    );
  }

  bool get _shouldShowHeader {
    if (previousMessage == null) return true;
    return !_belongsToSameRun(previousMessage!, message);
  }

  String get _headerText {
    return _timestamp(message.createdAt);
  }

  String _senderNameFor(PeerMessagingMessage value) {
    return (value.metadata['from_peer_name'] as String?) ?? 'Peer';
  }

  bool _isInbound(PeerMessagingMessage value) {
    return value.metadata['is_inbound'] == true ||
        value.metadata['from_peer_id'] != null;
  }

  bool _belongsToSameRun(
    PeerMessagingMessage first,
    PeerMessagingMessage second,
  ) {
    final firstIsLocal = !_isInbound(first);
    final secondIsLocal = !_isInbound(second);
    if (firstIsLocal != secondIsLocal) {
      return false;
    }
    if (!firstIsLocal && _senderNameFor(first) != _senderNameFor(second)) {
      return false;
    }
    final gap = second.createdAt.difference(first.createdAt).inSeconds.abs();
    return gap <= 300;
  }

  _BubbleGroupPosition get _groupPosition {
    final hasPrevious =
        previousMessage != null && _belongsToSameRun(previousMessage!, message);
    final hasNext =
        nextMessage != null && _belongsToSameRun(message, nextMessage!);
    if (hasPrevious && hasNext) {
      return _BubbleGroupPosition.middle;
    }
    if (hasPrevious) {
      return _BubbleGroupPosition.bottom;
    }
    if (hasNext) {
      return _BubbleGroupPosition.top;
    }
    return _BubbleGroupPosition.single;
  }

  bool _attachmentHasStandalonePreview(PeerMessagingAttachment attachment) {
    final lowerMime = (attachment.mimeType ?? '').toLowerCase();
    final extension =
        p.extension(attachment.path ?? attachment.name).toLowerCase();
    return lowerMime.startsWith('image/') ||
        lowerMime.startsWith('video/') ||
        lowerMime.startsWith('audio/') ||
        {
          '.png',
          '.jpg',
          '.jpeg',
          '.gif',
          '.webp',
          '.bmp',
          '.heic',
          '.heif',
          '.mp4',
          '.mov',
          '.m4v',
          '.avi',
          '.mkv',
          '.webm',
          '.mp3',
          '.wav',
          '.m4a',
          '.aac',
          '.ogg',
          '.flac',
        }.contains(extension);
  }

  bool _supportsLongPressAction(BuildContext context) =>
      Platform.isAndroid || Platform.isIOS;

  bool _supportsSecondaryClickAction(BuildContext context) =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  Future<void> _showMessageActions(
    BuildContext context, {
    Offset? globalPosition,
  }) async {
    final savableAttachments = message.attachments;
    final selected = _supportsSecondaryClickAction(context) &&
            globalPosition != null
        ? await showMenu<String>(
            context: context,
            position: RelativeRect.fromLTRB(
              globalPosition.dx,
              globalPosition.dy,
              globalPosition.dx,
              globalPosition.dy,
            ),
            items: [
              const PopupMenuItem<String>(
                value: 'reply',
                child: Text('Reply/Quote'),
              ),
              if (message.text.isNotEmpty)
                const PopupMenuItem<String>(
                  value: 'copy_text',
                  child: Text('Copy Text'),
                ),
              if (onSendAgain != null)
                const PopupMenuItem<String>(
                  value: 'send_again',
                  child: Text('Send Again'),
                ),
              if (savableAttachments.isNotEmpty) const PopupMenuDivider(),
              for (final attachment in savableAttachments)
                PopupMenuItem<String>(
                  value: 'save:${attachment.id}',
                  child: Text(
                    filesSaved.contains(attachment.name)
                        ? 'Save Again'
                        : 'Save',
                  ),
                ),
              if (savableAttachments.isNotEmpty) const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text(
                  'Delete Message',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          )
        : await showModalBottomSheet<String>(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(
                      isApple() ? CupertinoIcons.reply : Icons.reply_outlined,
                    ),
                    title: const Text('Reply/Quote'),
                    onTap: () => Navigator.pop(context, 'reply'),
                  ),
                  if (message.text.isNotEmpty)
                    ListTile(
                      leading: Icon(
                        isApple()
                            ? CupertinoIcons.doc_on_clipboard
                            : Icons.copy_outlined,
                      ),
                      title: const Text('Copy Text'),
                      onTap: () => Navigator.pop(context, 'copy_text'),
                    ),
                  if (onSendAgain != null)
                    ListTile(
                      leading: Icon(
                        isApple() ? CupertinoIcons.refresh : Icons.refresh,
                      ),
                      title: const Text('Send Again'),
                      onTap: () => Navigator.pop(context, 'send_again'),
                    ),
                  for (final attachment in savableAttachments)
                    ListTile(
                      leading: Icon(
                        isApple()
                            ? CupertinoIcons.download_circle
                            : Icons.download_outlined,
                      ),
                      title: Text(
                        filesSaved.contains(attachment.name)
                            ? 'Save Again'
                            : 'Save',
                      ),
                      onTap: () =>
                          Navigator.pop(context, 'save:${attachment.id}'),
                    ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    iconColor: Theme.of(context).colorScheme.error,
                    textColor: Theme.of(context).colorScheme.error,
                    title: const Text('Delete Message'),
                    onTap: () => Navigator.pop(context, 'delete'),
                  ),
                ],
              ),
            ),
          );
    if (selected == null) {
      return;
    }
    if (selected == 'reply') {
      onReply();
      return;
    }
    if (selected == 'copy_text') {
      await Clipboard.setData(ClipboardData(text: message.text));
      return;
    }
    if (selected == 'send_again') {
      onSendAgain?.call();
      return;
    }
    if (selected == 'delete') {
      onDelete();
      return;
    }
    if (selected.startsWith('save:')) {
      final attachmentId = selected.substring('save:'.length);
      final attachment = message.attachments.firstWhere(
        (value) => value.id == attachmentId,
      );
      await onSaveAttachment(attachment);
    }
  }

  String _timestamp(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
            ? local.hour - 12
            : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _AttachmentLine extends StatelessWidget {
  final PeerMessagingAttachment attachment;
  final bool isSaved;
  final VoidCallback onTap;
  final Future<String?> Function() resolvePath;
  final Color foregroundColor;
  final Color secondaryColor;
  final bool isLocal;

  const _AttachmentLine({
    required this.attachment,
    required this.isSaved,
    required this.onTap,
    required this.resolvePath,
    required this.foregroundColor,
    required this.secondaryColor,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context) {
    if (_hasThumbnail) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: _AttachmentThumbnail(
            attachment: attachment,
            resolvePath: resolvePath,
            secondaryColor: secondaryColor,
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(
                _leadingIcon,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: foregroundColor),
                    ),
                    Text(
                      isSaved
                          ? '${formatBytes(attachment.size)} · Saved'
                          : formatBytes(attachment.size),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: secondaryColor,
                            height: 1.15,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _leadingIcon {
    if (_isImage) {
      return isApple() ? CupertinoIcons.photo : Icons.photo_outlined;
    }
    if (_isVideo) {
      return isApple() ? CupertinoIcons.video_camera : Icons.videocam_outlined;
    }
    if (_isAudio) {
      return isApple() ? CupertinoIcons.music_note : Icons.audiotrack_outlined;
    }
    return isApple() ? CupertinoIcons.doc : Icons.insert_drive_file_outlined;
  }

  bool get _isImage {
    final lowerMime = (attachment.mimeType ?? '').toLowerCase();
    final extension =
        p.extension(attachment.path ?? attachment.name).toLowerCase();
    return lowerMime.startsWith('image/') ||
        {
          '.png',
          '.jpg',
          '.jpeg',
          '.gif',
          '.webp',
          '.bmp',
          '.heic',
          '.heif',
        }.contains(extension);
  }

  bool get _isVideo {
    final lowerMime = (attachment.mimeType ?? '').toLowerCase();
    final extension =
        p.extension(attachment.path ?? attachment.name).toLowerCase();
    return lowerMime.startsWith('video/') ||
        {
          '.mp4',
          '.mov',
          '.m4v',
          '.avi',
          '.mkv',
          '.webm',
        }.contains(extension);
  }

  bool get _isAudio {
    final lowerMime = (attachment.mimeType ?? '').toLowerCase();
    final extension =
        p.extension(attachment.path ?? attachment.name).toLowerCase();
    return lowerMime.startsWith('audio/') ||
        {
          '.mp3',
          '.wav',
          '.m4a',
          '.aac',
          '.ogg',
          '.flac',
        }.contains(extension);
  }

  bool get _hasThumbnail => _isImage || _isVideo || _isAudio;
}

class _DeliveryStatusText extends StatelessWidget {
  final String label;
  final Color color;

  const _DeliveryStatusText({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
    );
  }
}

class _DeliveryProgressIndicator extends StatelessWidget {
  final double progress;
  final Color color;

  const _DeliveryProgressIndicator({
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: 104,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: clamped,
            minHeight: 4,
            backgroundColor: color.withValues(alpha: 0.18),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 4),
          Text(
            'Sending ${(clamped * 100).round()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentTransferProgress {
  final double progress;

  const _AttachmentTransferProgress({
    required this.progress,
  });
}

class _AttachmentThumbnail extends StatelessWidget {
  final PeerMessagingAttachment attachment;
  final Future<String?> Function() resolvePath;
  final Color secondaryColor;

  const _AttachmentThumbnail({
    required this.attachment,
    required this.resolvePath,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final lowerMime = (attachment.mimeType ?? '').toLowerCase();
    final extension =
        p.extension(attachment.path ?? attachment.name).toLowerCase();
    final isImage = lowerMime.startsWith('image/') ||
        {
          '.png',
          '.jpg',
          '.jpeg',
          '.gif',
          '.webp',
          '.bmp',
          '.heic',
          '.heif',
        }.contains(extension);
    final isVideo = lowerMime.startsWith('video/') ||
        {
          '.mp4',
          '.mov',
          '.m4v',
          '.avi',
          '.mkv',
          '.webm',
        }.contains(extension);
    final isAudio = lowerMime.startsWith('audio/') ||
        {
          '.mp3',
          '.wav',
          '.m4a',
          '.aac',
          '.ogg',
          '.flac',
        }.contains(extension);

    if (isImage) {
      return FutureBuilder<String?>(
        future: resolvePath(),
        builder: (context, snapshot) {
          final path = snapshot.data;
          if ((path ?? '').isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 220,
                  maxHeight: 180,
                  minWidth: 120,
                  minHeight: 84,
                ),
                child: Image.file(
                  File(path!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _MediaPlaceholder(
                      icon: isApple()
                          ? CupertinoIcons.photo
                          : Icons.photo_outlined,
                      label: 'Image',
                      color: secondaryColor,
                    );
                  },
                ),
              ),
            );
          }
          return _MediaPlaceholder(
            icon: isApple() ? CupertinoIcons.photo : Icons.photo_outlined,
            label: 'Image',
            color: secondaryColor,
          );
        },
      );
    }

    if (isVideo) {
      return _MediaPlaceholder(
        icon: isApple() ? CupertinoIcons.video_camera : Icons.videocam_outlined,
        label: 'Video',
        color: secondaryColor,
      );
    }

    if (isAudio) {
      return _MediaPlaceholder(
        icon: isApple() ? CupertinoIcons.music_note : Icons.audiotrack_outlined,
        label: 'Audio',
        color: secondaryColor,
      );
    }

    return const SizedBox.shrink();
  }
}

class _MediaPlaceholder extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MediaPlaceholder({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryFailureIcon extends StatelessWidget {
  final VoidCallback? onTap;

  const _DeliveryFailureIcon({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        Icons.error,
        size: 16,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _DeliveryFailureSummary extends StatelessWidget {
  final Color color;
  final VoidCallback? onTap;

  const _DeliveryFailureSummary({
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            'Not delivered',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _BubbleTail extends StatelessWidget {
  final Color color;
  final bool isLocal;

  const _BubbleTail({
    required this.color,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(10, 11),
      painter: _BubbleTailPainter(
        color: color,
        isLocal: isLocal,
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final bool isLocal;

  const _BubbleTailPainter({
    required this.color,
    required this.isLocal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (!isLocal) {
      canvas.save();
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    // iMessage-style comma tail: top-left blends into the bubble's rounded
    // corner; the path bulges out to a rounded tip at the bottom-right and
    // curves back along the underside of the bubble.
    final w = size.width;
    final h = size.height;
    path
      ..moveTo(w * 0.8, -10)
      ..cubicTo(w * 0.30, h * 0.05, w * 0.55, h * 0.5, w, h)
      ..cubicTo(w * 0.55, h * 0.85, -w * 0.45, h * 0.45, -w * 0.6, 4)
      ..close();
    canvas.drawPath(path, paint);
    if (!isLocal) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isLocal != isLocal;
  }
}

enum _BubbleGroupPosition { single, top, middle, bottom }

String _platformItemLabel(ContextMenuButtonType type) {
  switch (type) {
    case ContextMenuButtonType.lookUp:
      return 'Look Up';
    case ContextMenuButtonType.searchWeb:
      return 'Search Web';
    case ContextMenuButtonType.share:
      return 'Share';
    default:
      return 'More';
  }
}

final _urlRegExp = RegExp(
  r'https?://[^\s<>\[\]()]+',
  caseSensitive: false,
);

String? _firstHttpUrl(String text) {
  if (text.isEmpty) return null;
  final match = _urlRegExp.firstMatch(text);
  if (match == null) return null;
  // Trim common trailing punctuation that the regex can swallow.
  var url = match.group(0)!;
  while (url.isNotEmpty &&
      (url.endsWith('.') ||
          url.endsWith(',') ||
          url.endsWith(';') ||
          url.endsWith(':') ||
          url.endsWith('!') ||
          url.endsWith('?'))) {
    url = url.substring(0, url.length - 1);
  }
  return url.isEmpty ? null : url;
}

TextSpan _buildLinkedTextSpan(String text, {required Color linkColor}) {
  final matches = _urlRegExp.allMatches(text).toList();
  if (matches.isEmpty) {
    return TextSpan(text: text);
  }
  final spans = <InlineSpan>[];
  var lastEnd = 0;
  for (final match in matches) {
    if (match.start > lastEnd) {
      spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
    }
    final url = match.group(0)!;
    spans.add(
      TextSpan(
        text: url,
        style: TextStyle(
          color: linkColor,
          decoration: TextDecoration.underline,
          decorationColor: linkColor.withValues(alpha: 0.5),
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          },
      ),
    );
    lastEnd = match.end;
  }
  if (lastEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastEnd)));
  }
  return TextSpan(children: spans);
}

class _ReplyLinkTrail extends StatelessWidget {
  final PeerMessagingMessage message;
  final PeerMessagingMessage targetMessage;
  final bool isLocal;
  final bool replyTargetIsLocal;
  final Future<String?> Function(PeerMessagingAttachment attachment)
      resolveAttachmentPath;
  final double maxBubbleWidth;

  const _ReplyLinkTrail({
    required this.message,
    required this.targetMessage,
    required this.isLocal,
    required this.replyTargetIsLocal,
    required this.resolveAttachmentPath,
    required this.maxBubbleWidth,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.28);
    final mediaOnlyPreview =
        message.attachments.isNotEmpty && message.text.isEmpty;
    final textOnly = message.attachments.isEmpty;
    final previewWidth = mediaOnlyPreview ? 88.0 : 246.0;
    final previewHeight = mediaOnlyPreview
        ? 88.0
        : textOnly
            ? 40.0
            : 96.0;
    const trailHeight = 32.0;

    return SizedBox(
      width: double.infinity,
      height: previewHeight + trailHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ReplyLinkIndicatorPainter(
                color: color,
                sourceOnRight: replyTargetIsLocal,
                targetOnRight: isLocal,
                targetBubbleWidth: _estimatedReplyBubbleWidth(targetMessage)
                    .clamp(0.0, maxBubbleWidth),
                targetBubbleHeight: _estimatedReplyBubbleHeight(targetMessage),
                previewWidth: previewWidth,
                previewHeight: previewHeight,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: replyTargetIsLocal ? null : 0,
            right: replyTargetIsLocal ? 0 : null,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: previewWidth,
                minWidth: previewWidth * 0.5,
              ),
              child: _ReplyTrailPreviewCard(
                message: message,
                resolveAttachmentPath: resolveAttachmentPath,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyTrailPreviewCard extends StatelessWidget {
  final PeerMessagingMessage message;
  final Future<String?> Function(PeerMessagingAttachment attachment)
      resolveAttachmentPath;

  const _ReplyTrailPreviewCard({
    required this.message,
    required this.resolveAttachmentPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaOnly = message.attachments.isNotEmpty && message.text.isEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 1.0),
        borderRadius: BorderRadius.circular(mediaOnly ? 18 : 14),
      ),
      child: Padding(
        padding: mediaOnly
            ? const EdgeInsets.all(8)
            : const EdgeInsets.fromLTRB(10, 9, 10, 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.attachments.isNotEmpty) ...[
              _ReplyAttachmentThumbnail(
                attachment: message.attachments.first,
                resolvePath: () =>
                    resolveAttachmentPath(message.attachments.first),
                size: mediaOnly ? 72 : 36,
                borderRadius: mediaOnly ? 14 : 10,
                iconSize: mediaOnly ? 22 : 16,
              ),
              if (message.text.isNotEmpty) const SizedBox(width: 9),
            ],
            if (message.text.isNotEmpty || message.attachments.isEmpty)
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _replyTitle(message),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _replySnippet(message),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReplyLinkIndicatorPainter extends CustomPainter {
  final Color color;
  final bool sourceOnRight;
  final bool targetOnRight;
  final double targetBubbleWidth;
  final double targetBubbleHeight;
  final double previewWidth;
  final double previewHeight;

  const _ReplyLinkIndicatorPainter({
    required this.color,
    required this.sourceOnRight,
    required this.targetOnRight,
    required this.targetBubbleWidth,
    required this.targetBubbleHeight,
    required this.previewWidth,
    required this.previewHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.square;

    final previewLeft = sourceOnRight ? size.width - previewWidth : 0.0;
    final previewRight = previewLeft + previewWidth;
    const cornerRadius = 12.0;
    final path = Path();
    final targetLeft = targetOnRight ? size.width - targetBubbleWidth : 0.0;
    final targetRight = targetLeft + targetBubbleWidth;
    final targetCenterY = size.height + (targetBubbleHeight * 0.5);

    if (!sourceOnRight && !targetOnRight) {
      final startX = previewRight * 0.1;
      final startY = previewHeight * 0.5;
      final endX = targetRight * 0.1;
      final endY = targetCenterY;
      final laneX =
          (previewRight > targetRight ? previewRight : targetRight) + 18.0;
      path
        ..moveTo(startX, startY)
        ..lineTo(laneX - cornerRadius, startY)
        ..arcToPoint(
          Offset(laneX, startY + cornerRadius),
          radius: const Radius.circular(cornerRadius),
          clockwise: true,
        )
        ..lineTo(laneX, endY - cornerRadius)
        ..arcToPoint(
          Offset(laneX - cornerRadius, endY),
          radius: const Radius.circular(cornerRadius),
          clockwise: true,
        )
        ..lineTo(endX, endY);
    } else if (sourceOnRight && targetOnRight) {
      final startX = size.width - 10;
      final startY = previewHeight * 0.5;
      final endX = size.width - 10;
      final endY = targetCenterY;
      final laneX =
          (previewLeft < targetLeft ? previewLeft : targetLeft) - 18.0;
      path
        ..moveTo(startX, startY)
        ..lineTo(laneX + cornerRadius, startY)
        ..arcToPoint(
          Offset(laneX, startY + cornerRadius),
          radius: const Radius.circular(cornerRadius),
          clockwise: false,
        )
        ..lineTo(laneX, endY - cornerRadius)
        ..arcToPoint(
          Offset(laneX + cornerRadius, endY),
          radius: const Radius.circular(cornerRadius),
          clockwise: false,
        )
        ..lineTo(endX, endY);
    } else if (!sourceOnRight && targetOnRight) {
      // Local replying to peer: elbow turns right, needs startX < endX.
      // Anchor the line ~1/8 from the left edge of the canvas, instead of at
      // the center of the (wide) preview card, so the elbow drops cleanly
      // off the left side of the layout.
      final idealStartX = size.width / 8;
      final idealEndX = size.width - 10;
      final startY = previewHeight * 0.1;
      final endY = targetCenterY;
      final gap = idealEndX - idealStartX;
      const needed = 2 * cornerRadius;
      double startX = idealStartX;
      double endX = idealEndX;
      if (gap < needed) {
        // Split the deficit: move startX left and endX right equally.
        final deficit = needed - gap;
        final halfDeficit = deficit / 2;
        startX = (idealStartX - halfDeficit).clamp(0.0, size.width);
        endX = (idealEndX + halfDeficit).clamp(0.0, size.width);
      }
      final turnY = endY - cornerRadius;
      path
        ..moveTo(startX, startY)
        ..lineTo(startX, turnY)
        ..arcToPoint(
          Offset(startX + cornerRadius, endY),
          radius: const Radius.circular(cornerRadius),
          clockwise: false,
        )
        ..lineTo(endX, endY);
    } else {
      // Peer replying to local: elbow turns left, needs startX > endX.
      // Anchor the line ~1/8 from the right edge of the canvas.
      final idealStartX = size.width - size.width / 8;
      const idealEndX = 10.0;
      final startY = previewHeight * 0.1;
      final endY = targetCenterY;
      final gap = idealStartX - idealEndX;
      const needed = 2 * cornerRadius;
      double startX = idealStartX;
      double endX = idealEndX;
      if (gap < needed) {
        // Split the deficit: move startX right and endX left equally.
        final deficit = needed - gap;
        final halfDeficit = deficit / 2;
        startX = (idealStartX + halfDeficit).clamp(0.0, size.width);
        endX = (idealEndX - halfDeficit).clamp(0.0, size.width);
      }
      final turnY = endY - cornerRadius;
      path
        ..moveTo(startX, startY)
        ..lineTo(startX, turnY)
        ..arcToPoint(
          Offset(startX - cornerRadius, endY),
          radius: const Radius.circular(cornerRadius),
          clockwise: true,
        )
        ..lineTo(endX, endY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ReplyLinkIndicatorPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.sourceOnRight != sourceOnRight ||
        oldDelegate.targetOnRight != targetOnRight ||
        oldDelegate.targetBubbleWidth != targetBubbleWidth ||
        oldDelegate.targetBubbleHeight != targetBubbleHeight ||
        oldDelegate.previewWidth != previewWidth ||
        oldDelegate.previewHeight != previewHeight;
  }
}

class _ReplyComposerPreview extends StatelessWidget {
  final PeerMessagingMessage message;
  final Future<String?> Function(PeerMessagingAttachment attachment)
      resolveAttachmentPath;
  final VoidCallback onCancel;

  const _ReplyComposerPreview({
    required this.message,
    required this.resolveAttachmentPath,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _replyTitle(message);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _ReplyPreviewBody(
                  message: message,
                  resolveAttachmentPath: resolveAttachmentPath,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cancel reply',
            onPressed: onCancel,
            icon: Icon(
              isApple() ? CupertinoIcons.xmark : Icons.close,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyPreviewBody extends StatelessWidget {
  final PeerMessagingMessage? message;
  final Future<String?> Function(PeerMessagingAttachment attachment)?
      resolveAttachmentPath;
  final int maxLines;

  const _ReplyPreviewBody({
    required this.message,
    required this.resolveAttachmentPath,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    if (message == null) {
      return Text(
        'Original message unavailable',
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.18),
      );
    }

    final firstAttachment =
        message!.attachments.isNotEmpty ? message!.attachments.first : null;
    if (firstAttachment == null) {
      return Text(
        _replySnippet(message!),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.18),
      );
    }

    final previewText = _replySnippet(message!);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ReplyAttachmentThumbnail(
          attachment: firstAttachment,
          resolvePath: resolveAttachmentPath == null
              ? null
              : () => resolveAttachmentPath!(firstAttachment),
        ),
        if (previewText.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              previewText,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.18,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ReplyAttachmentThumbnail extends StatelessWidget {
  final PeerMessagingAttachment attachment;
  final Future<String?> Function()? resolvePath;
  final double size;
  final double borderRadius;
  final double iconSize;

  const _ReplyAttachmentThumbnail({
    required this.attachment,
    this.resolvePath,
    this.size = 36,
    this.borderRadius = 8,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final extension =
        p.extension(attachment.path ?? attachment.name).toLowerCase();
    final lowerMime = (attachment.mimeType ?? '').toLowerCase();
    final isImage = lowerMime.startsWith('image/') ||
        {
          '.png',
          '.jpg',
          '.jpeg',
          '.gif',
          '.webp',
          '.bmp',
          '.heic',
          '.heif',
        }.contains(extension);
    final isVideo = lowerMime.startsWith('video/') ||
        {
          '.mp4',
          '.mov',
          '.m4v',
          '.avi',
          '.mkv',
          '.webm',
        }.contains(extension);
    final isAudio = lowerMime.startsWith('audio/') ||
        {
          '.mp3',
          '.wav',
          '.m4a',
          '.aac',
          '.ogg',
          '.flac',
        }.contains(extension);

    if (isImage && resolvePath != null) {
      return FutureBuilder<String?>(
        future: resolvePath!(),
        builder: (context, snapshot) {
          final path = snapshot.data;
          if ((path ?? '').isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image.file(
                File(path!),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _ReplyAttachmentPlaceholder(
                  icon: isApple() ? CupertinoIcons.photo : Icons.photo_outlined,
                  size: size,
                  borderRadius: borderRadius,
                  iconSize: iconSize,
                ),
              ),
            );
          }
          return _ReplyAttachmentPlaceholder(
            icon: isApple() ? CupertinoIcons.photo : Icons.photo_outlined,
            size: size,
            borderRadius: borderRadius,
            iconSize: iconSize,
          );
        },
      );
    }

    return _ReplyAttachmentPlaceholder(
      icon: isImage
          ? (isApple() ? CupertinoIcons.photo : Icons.photo_outlined)
          : isVideo
              ? (isApple()
                  ? CupertinoIcons.video_camera
                  : Icons.videocam_outlined)
              : isAudio
                  ? (isApple()
                      ? CupertinoIcons.music_note
                      : Icons.audiotrack_outlined)
                  : (isApple()
                      ? CupertinoIcons.doc
                      : Icons.insert_drive_file_outlined),
      size: size,
      borderRadius: borderRadius,
      iconSize: iconSize,
    );
  }
}

class _ReplyAttachmentPlaceholder extends StatelessWidget {
  final IconData icon;
  final double size;
  final double borderRadius;
  final double iconSize;

  const _ReplyAttachmentPlaceholder({
    required this.icon,
    required this.size,
    required this.borderRadius,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

double _estimatedReplyBubbleWidth(PeerMessagingMessage message) {
  final mediaOnly =
      message.text.trim().isEmpty && message.attachments.isNotEmpty;
  if (mediaOnly) {
    return 108.0;
  }
  if (message.attachments.isNotEmpty) {
    return 220.0;
  }
  final estimated = (message.text.trim().length * 7.2) + 28.0;
  return estimated.clamp(64.0, 420.0);
}

double _estimatedReplyBubbleHeight(PeerMessagingMessage message) {
  final mediaOnly =
      message.text.trim().isEmpty && message.attachments.isNotEmpty;
  if (mediaOnly) {
    return 96.0;
  }
  if (message.attachments.isNotEmpty) {
    return 72.0;
  }
  final lines = (message.text.trim().length / 28.0).ceil().clamp(1, 6);
  return (lines * 22.0) + 18.0;
}

String _replyTitle(PeerMessagingMessage message) {
  final isInbound = message.metadata['is_inbound'] == true ||
      message.metadata['from_peer_id'] != null;
  if (!isInbound) {
    return 'You';
  }
  return (message.metadata['from_peer_name'] as String?) ?? 'Peer';
}

String _replySnippet(PeerMessagingMessage message) {
  final text = message.text.trim();
  if (text.isNotEmpty) {
    return text;
  }
  if (message.attachments.isNotEmpty) {
    final attachment = message.attachments.first;
    final extension =
        p.extension(attachment.path ?? attachment.name).toLowerCase();
    final lowerMime = (attachment.mimeType ?? '').toLowerCase();
    final isImage = lowerMime.startsWith('image/') ||
        {
          '.png',
          '.jpg',
          '.jpeg',
          '.gif',
          '.webp',
          '.bmp',
          '.heic',
          '.heif',
        }.contains(extension);
    final isVideo = lowerMime.startsWith('video/') ||
        {
          '.mp4',
          '.mov',
          '.m4v',
          '.avi',
          '.mkv',
          '.webm',
        }.contains(extension);
    final isAudio = lowerMime.startsWith('audio/') ||
        {
          '.mp3',
          '.wav',
          '.m4a',
          '.aac',
          '.ogg',
          '.flac',
        }.contains(extension);
    if (message.attachments.length == 1 && text.isEmpty) {
      if (isImage) {
        return '';
      }
      if (isVideo) {
        return 'Video';
      }
      if (isAudio) {
        return 'Audio';
      }
      return 'Document';
    }
    return '${message.attachments.length} attachments';
  }
  return 'Message';
}

class _ThreadTitle extends StatelessWidget {
  final String title;
  final VpnState vpnState;

  const _ThreadTitle({
    required this.title,
    required this.vpnState,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = _statusSubtitle(vpnState);
    final titleStyle = isApple()
        ? CupertinoTheme.of(context).textTheme.navTitleTextStyle
        : Theme.of(context).textTheme.titleLarge;
    if (subtitle == null) {
      return Text(
        title,
        style: titleStyle,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }
    final subtitleColor = vpnState == VpnState.error
        ? Theme.of(context).colorScheme.error
        : (isApple()
            ? CupertinoColors.secondaryLabel.resolveFrom(context)
            : Theme.of(context).colorScheme.onSurfaceVariant);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: titleStyle,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 1),
        Text(
          subtitle,
          style: TextStyle(
            color: subtitleColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String? _statusSubtitle(VpnState state) {
    switch (state) {
      case VpnState.connected:
        return null;
      case VpnState.connecting:
        return 'Connecting…';
      case VpnState.disconnecting:
        return 'Disconnecting…';
      case VpnState.disconnected:
        return 'Disconnected';
      case VpnState.error:
        return 'Connection error';
    }
  }
}
