// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
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
import 'utils/utils.dart';
import 'widgets/adaptive_widgets.dart';
import 'widgets/alert_dialog_widget.dart';
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
  final _messagesScrollController = ScrollController();
  final List<PeerMessagingAttachment> _pendingAttachments = [];
  bool _sending = false;
  int _lastRenderedMessageCount = 0;

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
    _messagesScrollController.dispose();
    super.dispose();
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
      p.join(sharedFolderPath, 'peer-messaging', 'attachments'),
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
          );
      _controller.clear();
      if (mounted) {
        setState(() {
          _pendingAttachments.clear();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(animated: true);
        });
      }
    } catch (e) {
      if (mounted) {
        await showAlertDialog(context, 'Send Failed', '$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
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

  Future<void> _saveAttachment(PeerMessagingAttachment attachment) async {
    try {
      final managedPath = await _resolveManagedAttachmentPath(attachment);
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
        final srcPath = managedPath ??
            ((waitingPath != null && await File(waitingPath).exists())
                ? waitingPath
                : null) ??
            await ref
                .read(ipnStateNotifierProvider.notifier)
                .getFilePath(sourceFileName);
        _logger.d(
          'macOS save source resolved: sourceFileName=$sourceFileName srcPath=$srcPath toPath=$toPath',
        );
        await File(srcPath).copy(toPath);
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

  Future<void> _openAttachment(PeerMessagingAttachment attachment) async {
    try {
      final resolvedPath = await _resolveAttachmentOpenPath(attachment);
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
    PeerMessagingAttachment attachment,
  ) async {
    final waitingFile = await _resolveCurrentWaitingFileForAttachment(
      attachment,
    );
    final sourcePath = await _resolveAttachmentSourcePath(
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
    PeerMessagingAttachment attachment, {
    AwaitingFile? waitingFile,
  }) async {
    final managedPath = await _resolveManagedAttachmentPath(attachment);
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
    PeerMessagingAttachment attachment,
  ) async {
    final attachmentPath = attachment.path;
    if ((attachmentPath ?? '').isNotEmpty &&
        await File(attachmentPath!).exists()) {
      _logger.d(
        'Using attachment.path as managed attachment path: ${attachment.path}',
      );
      return attachmentPath;
    }

    final transferId = attachment.transferId ?? attachment.id;
    if (transferId.isEmpty) {
      return null;
    }

    final remappedIosPath = await _resolveCurrentIosAttachmentPath(attachment);
    if ((remappedIosPath ?? '').isNotEmpty) {
      _logger.d(
        'Using current iOS Downloads attachment path: $remappedIosPath',
      );
      return remappedIosPath;
    }

    final attachmentsDir = await _managedAttachmentDirectory();
    final deterministicPath = p.join(
      attachmentsDir.path,
      '${transferId}_${attachment.name}',
    );
    if (await File(deterministicPath).exists()) {
      _logger.d(
        'Using deterministic managed attachment path: $deterministicPath',
      );
      return deterministicPath;
    }

    _logger.d(
      'No managed attachment path found for transferId=$transferId name=${attachment.name}; deterministicPath=$deterministicPath attachment.path=${attachment.path}',
    );
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
        _logger.d(
          'Recovered current iOS Downloads path for attachment: $candidatePath',
        );
        return candidatePath;
      }
    }
    return null;
  }

  Future<Directory> _managedAttachmentDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final attachmentsDir = Directory(
      p.join(supportDir.path, 'openclaw', 'attachments'),
    );
    await attachmentsDir.create(recursive: true);
    return attachmentsDir;
  }

  Future<String> _iosAttachmentSavePath(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(
      p.join(dir.path, 'downloads', 'peer-messaging'),
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

  Future<AwaitingFile?> _resolveCurrentWaitingFileForAttachment(
    PeerMessagingAttachment attachment,
  ) async {
    final notifier = ref.read(ipnStateNotifierProvider.notifier);
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

    return _matchWaitingFileForAttachment(
      attachment,
      ref.read(filesWaitingProvider),
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

  void _scheduleInitialOrNewMessageScroll(int messageCount) {
    if (_lastRenderedMessageCount == messageCount) {
      return;
    }
    _lastRenderedMessageCount = messageCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: false);
    });
  }

  void _scrollToBottom({required bool animated}) {
    if (!_messagesScrollController.hasClients) {
      return;
    }

    final position = _messagesScrollController.position.maxScrollExtent;
    if (animated) {
      _messagesScrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return;
    }
    _messagesScrollController.jumpTo(position);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(peerMessagingBootstrapProvider);
    final conversation =
        ref.watch(peerMessagingConversationProvider(widget.conversationId));
    final waitingFiles = ref.watch(filesWaitingProvider);
    final filesSaved = ref.watch(filesSavedProvider);
    if (conversation == null) {
      return AdaptiveScaffold(
        title: const Text('Peer Conversation'),
        onGoBack: widget.onNavigateBack,
        body: const Center(child: Text('Conversation not found')),
      );
    }

    _scheduleInitialOrNewMessageScroll(conversation.messages.length);

    return AdaptiveScaffold(
      title: Text(conversation.title),
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
                child: ListView.separated(
                  controller: _messagesScrollController,
                  reverse: false,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final message = conversation.messages[index];
                    final previous =
                        index > 0 ? conversation.messages[index - 1] : null;
                    final laterMessages = conversation.messages.sublist(
                      index + 1,
                    );
                    return _MessageBubble(
                      message: message,
                      previousMessage: previous,
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
                      onSaveAttachment: _saveAttachment,
                      onOpenAttachment: _openAttachment,
                      resolveAttachmentPath: _resolveAttachmentOpenPath,
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
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: conversation.messages.length,
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
                                        controller: _controller,
                                        minLines: 3,
                                        maxLines: 8,
                                        textInputAction:
                                            TextInputAction.newline,
                                        decoration: const InputDecoration(
                                          hintText: 'Reply…',
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
                            right: 56,
                            bottom: 8,
                            child: IconButton(
                              tooltip: 'Add attachment',
                              onPressed: _sending ? null : _pickAttachments,
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
                              onPressed: _sending
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
  final PeerMessagingMessage? previousMessage;
  final List<AwaitingFile> waitingFiles;
  final List<String> filesSaved;
  final bool hasLaterDeliveredMessage;
  final bool hasLaterSentMessage;
  final bool hasLaterPendingMessage;
  final bool hasLaterFailedMessage;
  final VoidCallback onDelete;
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
    required this.previousMessage,
    required this.waitingFiles,
    required this.filesSaved,
    required this.hasLaterDeliveredMessage,
    required this.hasLaterSentMessage,
    required this.hasLaterPendingMessage,
    required this.hasLaterFailedMessage,
    required this.onDelete,
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
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(22),
      topRight: const Radius.circular(22),
      bottomLeft: Radius.circular(isLocal ? 22 : 8),
      bottomRight: Radius.circular(isLocal ? 8 : 22),
    );
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
            padding: EdgeInsets.only(
              left: isLocal ? 0 : 4,
              right: isLocal ? 4 : 0,
              bottom: 6,
            ),
            child: Text(
              _headerText,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: isLocal ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
        Align(
          alignment: alignment,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: _supportsLongPressAction(context)
                ? () => _showMessageActions(context)
                : null,
            onSecondaryTapDown: _supportsSecondaryClickAction(context)
                ? (details) => _showMessageActions(
                      context,
                      globalPosition: details.globalPosition,
                    )
                : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: IntrinsicWidth(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        isMediaOnlyMessage ? Colors.transparent : bubbleColor,
                    borderRadius: isMediaOnlyMessage ? null : borderRadius,
                  ),
                  child: DefaultTextStyle.merge(
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: foregroundColor,
                          height: 1.35,
                        ) ??
                        TextStyle(color: foregroundColor, height: 1.35),
                    child: IconTheme.merge(
                      data: IconThemeData(color: foregroundColor),
                      child: Padding(
                        padding: isMediaOnlyMessage
                            ? EdgeInsets.zero
                            : const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.text.isNotEmpty) Text(message.text),
                            if (message.attachments.isNotEmpty) ...[
                              if (message.text.isNotEmpty)
                                const SizedBox(height: 10),
                              for (final attachment in message.attachments)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        attachment == message.attachments.last
                                            ? 0
                                            : 8,
                                  ),
                                  child: _AttachmentLine(
                                    attachment: attachment,
                                    isSaved: filesSaved.contains(
                                      attachment.name,
                                    ),
                                    onTap: () => onOpenAttachment(attachment),
                                    resolvePath: () =>
                                        resolveAttachmentPath(attachment),
                                    foregroundColor: foregroundColor,
                                    secondaryColor: secondaryForegroundColor,
                                  ),
                                ),
                            ],
                            if (message.kind ==
                                    PeerMessagingMessageKind.approvalRequest &&
                                message.deliveryStatus !=
                                    PeerMessagingDeliveryStatus.failed &&
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
                            if (message.kind ==
                                    PeerMessagingMessageKind.menuRequest &&
                                message.deliveryStatus !=
                                    PeerMessagingDeliveryStatus.failed &&
                                message.menuOptions.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final option in message.menuOptions)
                                    OutlinedButton(
                                      onPressed: () => onMenuSelection(
                                        option.action,
                                        option.title,
                                      ),
                                      style: actionStyle,
                                      child: Text(option.title),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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

  bool get _isLocal => !_isInbound(message);

  Widget? _buildStatusIndicator(ThemeData theme) {
    if (!_isLocal) {
      return null;
    }

    final defaultColor = theme.colorScheme.onSurfaceVariant;
    switch (message.deliveryStatus) {
      case PeerMessagingDeliveryStatus.pending:
        if (hasLaterPendingMessage) {
          return null;
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
          return const _DeliveryFailureIcon();
        }
        return _DeliveryStatusText(
          label: 'Not delivered',
          color: theme.colorScheme.error,
          isEmphasized: true,
        );
    }
  }

  bool get _shouldShowHeader {
    if (previousMessage == null) return true;
    final previousIsLocal = !_isInbound(previousMessage!);
    final senderChanged = previousIsLocal != _isLocal ||
        (!_isLocal && _senderName != _senderNameFor(previousMessage!));
    final gap = message.createdAt.difference(previousMessage!.createdAt);
    return senderChanged || gap.inSeconds > 5;
  }

  String get _headerText {
    final timestamp = _timestamp(message.createdAt);
    if (_isLocal) {
      return timestamp;
    }
    return '$_senderName · $timestamp';
  }

  String get _senderName =>
      (message.metadata['from_peer_name'] as String?) ?? 'Peer';

  String _senderNameFor(PeerMessagingMessage value) {
    return (value.metadata['from_peer_name'] as String?) ?? 'Peer';
  }

  bool _isInbound(PeerMessagingMessage value) {
    return value.metadata['is_inbound'] == true ||
        value.metadata['from_peer_id'] != null;
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

  const _AttachmentLine({
    required this.attachment,
    required this.isSaved,
    required this.onTap,
    required this.resolvePath,
    required this.foregroundColor,
    required this.secondaryColor,
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: secondaryColor,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
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
  final bool isEmphasized;

  const _DeliveryStatusText({
    required this.label,
    required this.color,
    this.isEmphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: isEmphasized ? FontWeight.w600 : FontWeight.w500,
          ),
    );
  }
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
    return Container(
      width: 180,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.14),
      ),
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
  const _DeliveryFailureIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.error,
      size: 16,
      color: Theme.of(context).colorScheme.error,
    );
  }
}
