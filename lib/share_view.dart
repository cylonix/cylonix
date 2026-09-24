// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';
import 'dart:io';
import 'package:cylonix/widgets/alert_dialog_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'models/ipn.dart';
import 'models/peer_messaging.dart';
import 'models/peer_transfer_state.dart';
import 'models/shared_file.dart';
import 'providers/ipn.dart';
import 'providers/peer_messaging.dart';
import 'providers/share_file.dart';
import 'services/ipn.dart';
import 'utils/logger.dart';
import 'utils/peer_message_attachments.dart';
import 'utils/utils.dart';
import 'widgets/adaptive_widgets.dart';
import 'widgets/peer_device_avatar.dart';
import 'widgets/share_peer_device_list.dart';

/// The send-files sheet. Offers two delivery paths for the same files:
///
/// * **File Drop** — Cylonix File Transfer straight to a device that is
///   online now (the original behaviour).
/// * **Peer Message** — the files become attachments on a peer message in an
///   existing thread or a new one. Messages go through the daemon's outbound
///   queue, so the peer does not have to be online at send time.
class ShareView extends ConsumerStatefulWidget {
  /// Files to send, by path. The display name is the path's basename; when
  /// the on-disk name is not the user-facing one (share-extension temp copies
  /// are named by UUID without an extension), pass [files] instead.
  final List<String> paths;

  /// Files to send with their user-facing names and sizes; takes precedence
  /// over [paths] when given.
  final List<SharedFile>? files;

  /// Shared text or links. In Peer Message mode this is the message body
  /// (editable), and text/link entries in [files] are not attached; File
  /// Drop sends those entries as files.
  final String initialText;
  final VoidCallback onCancel;

  /// Which delivery path is selected when the sheet opens. A share handed
  /// over by the platform share sheet with "Peer Message" chosen lands here
  /// directly.
  final ShareMode initialMode;

  /// The files are temporary copies made for this share (e.g. by the share
  /// extension). The sheet deletes them on Done once nothing references them
  /// any more.
  final bool ephemeral;

  /// Running as the standalone share window (Windows `--share` process).
  /// Peer messages live in the main app's message store, which a second
  /// process must not write to, so only File Drop is offered there.
  final bool standalone;

  const ShareView({
    super.key,
    this.paths = const [],
    this.files,
    this.initialText = '',
    required this.onCancel,
    this.initialMode = ShareMode.fileDrop,
    this.ephemeral = false,
    this.standalone = false,
  });

  @override
  ConsumerState<ShareView> createState() => _ShareViewState();
}

enum _MessageSendStatus { sending, sent, failed }

class _MessageSendState {
  final _MessageSendStatus status;
  final String? error;

  const _MessageSendState(this.status, [this.error]);
}

class _ShareViewState extends ConsumerState<ShareView> {
  final _ipn = IpnService();
  var _sharedFiles = <SharedFile>[];
  late ShareMode _mode;
  final _captionController = TextEditingController();

  /// Peer-message send state per conversation id.
  final _messageSends = <String, _MessageSendState>{};

  /// File-drop transfer ids created for each source path, so ephemeral
  /// cleanup can tell whether a transfer still reads the file.
  final _fileDropIds = <String, Set<String>>{};
  StreamSubscription<ShareFileEvent>? _shareEventSub;
  static final _logger = Logger(tag: 'ShareView');

  /// Entries that go out as attachments in Peer Message mode.
  List<SharedFile> get _attachmentFiles =>
      _sharedFiles.where((f) => f.isAttachment).toList();

  bool get _hasText => _captionController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _mode = widget.standalone ? ShareMode.fileDrop : widget.initialMode;
    _captionController.text = widget.initialText;
    _shareEventSub = shareFileEventBus.on<ShareFileEvent>().listen((event) {
      _logger.i("Received share event: ${event.args}");
      var path = event.args.replaceFirst("--share", "").trim();
      if (path.startsWith('"') && path.endsWith('"')) {
        path = path.substring(1, path.length - 1);
      }
      if (path.isEmpty) {
        _logger.w("No files provided in share event: $path");
        if (!mounted) return;
        showAlertDialog(
          context,
          "Error",
          "No valid files provided for sharing: $path",
        );
        return;
      }
      try {
        _sharedFiles.add(
          SharedFile.fromPath(path),
        );
        _logger.i("Added shared file: $path");
        if (!mounted) return;
        setState(() {});
      } catch (e) {
        _logger.e("Error adding shared files: $e");
        if (!mounted) return;
        showAlertDialog(
          context,
          "Error",
          "Failed to parse shared files: $e. path=$path",
        );
        return;
      }
    });
    try {
      final files = widget.files;
      if (files != null) {
        for (final file in files) {
          _logger.i("Adding shared file: ${file.name} (${file.path})");
        }
        _sharedFiles = List<SharedFile>.of(files);
      } else {
        _sharedFiles = widget.paths.map((path) {
          _logger.i("Adding shared file: $path");
          return SharedFile.fromPath(path);
        }).toList();
      }
    } catch (e) {
      _sharedFiles = [];
      _logger.e("Error initializing shared files: $e");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showAlertDialog(
          context,
          "Error",
          "Failed to parse the shared files: $e",
        );
      });
    }
  }

  @override
  void dispose() {
    _shareEventSub?.cancel();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transfers = ref.watch(transfersProvider);

    // Text-only shares have nothing File Drop could send except the
    // synthetic .txt, so they stay in Peer Message mode.
    final textOnly = _sharedFiles.isEmpty && widget.initialText.isNotEmpty;
    if (textOnly && _mode != ShareMode.peerMessage && !widget.standalone) {
      _mode = ShareMode.peerMessage;
    }
    final empty = _sharedFiles.isEmpty && widget.initialText.isEmpty;

    return Scaffold(
      appBar: _buildHeader(),
      body: Column(
        children: [
          if (empty)
            const Expanded(
              child: Center(child: Text('Nothing selected for sending')),
            )
          else ...[
            _mode == ShareMode.peerMessage
                ? _ShareHeaderView(
                    files: _attachmentFiles,
                    text: widget.initialText,
                  )
                : _ShareHeaderView(files: _sharedFiles),
            if (!widget.standalone && !textOnly) _buildModeSelector(context),
            Expanded(
              child: _mode == ShareMode.peerMessage
                  ? _buildPeerMessageBody(context)
                  : SharePeerDeviceList(
                      emptyMessage: 'No devices available to share with',
                      searchHintText: 'Search name or OS…',
                      androidTvTitle: 'Select a device to send files to',
                      trailingBuilder: (context, peer) => _buildPeerTrailing(
                          context, peer, transfers[peer.stableID]),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildHeader() {
    return AppBar(
      forceMaterialTransparency: true,
      leadingWidth: 48,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Image.asset(
          'lib/assets/images/cylonix_128.png',
          width: 24,
          height: 24,
        ),
      ),
      title: Text(
        _mode == ShareMode.peerMessage ? 'Send as Message' : 'Send Files',
      ),
      actions: [
        AdaptiveButton(
          filled: true,
          onPressed: _finish,
          child: const Text('Done'),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Future<void> _finish() async {
    if (widget.ephemeral) {
      await _cleanupEphemeralFiles();
    }
    widget.onCancel();
  }

  // MARK: - Delivery mode

  Widget _buildModeSelector(BuildContext context) {
    final hint = _mode == ShareMode.peerMessage
        ? 'Text and links become the message; files are attached. Queued if the peer is offline.'
        : 'Sent straight to a device that is online now.';
    final Widget selector;
    if (isApple()) {
      // Fixed, equal segment widths: the sliding control sizes segments to
      // their intrinsic width and draws the selected label bold, so without
      // this the whole control changed width and shifted on every selection.
      Widget segment(String label) => SizedBox(
            width: 132,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Center(child: Text(label)),
            ),
          );
      selector = CupertinoSlidingSegmentedControl<ShareMode>(
        groupValue: _mode,
        children: {
          ShareMode.fileDrop: segment('File Drop'),
          ShareMode.peerMessage: segment('Peer Message'),
        },
        onValueChanged: (value) {
          if (value != null) setState(() => _mode = value);
        },
      );
    } else {
      selector = SegmentedButton<ShareMode>(
        segments: const [
          ButtonSegment(
            value: ShareMode.fileDrop,
            label: Text('File Drop'),
            icon: Icon(Icons.devices_outlined),
          ),
          ButtonSegment(
            value: ShareMode.peerMessage,
            label: Text('Peer Message'),
            icon: Icon(Icons.chat_bubble_outline),
          ),
        ],
        selected: {_mode},
        showSelectedIcon: false,
        onSelectionChanged: (selection) =>
            setState(() => _mode = selection.first),
      );
    }
    // Centered with a stable width, so switching modes never moves it.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: selector),
          const SizedBox(height: 6),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // MARK: - File drop

  Future<void> _sendFiles(Node peer) async {
    final outgoingFiles = _sharedFiles
        .map((f) => OutgoingFile(
              id: const Uuid().v4(),
              name: f.name,
              declaredSize: f.size,
              path: f.path,
              peerID: peer.stableID,
            ))
        .toList();
    for (final file in outgoingFiles) {
      (_fileDropIds[file.path ?? ''] ??= <String>{}).add(file.id);
    }
    try {
      ref.read(transfersProvider.notifier).initializeTransfer(
            peer.stableID,
            outgoingFiles,
          );
      await _ipn.sendPeerFiles(peer.stableID, outgoingFiles);
    } catch (e) {
      ref.read(transfersProvider.notifier).updateTransfer(
            peer.stableID,
            PeerTransferState(
              peerID: peer.stableID,
              files: outgoingFiles,
              progress: 0,
              status: TransferStatus.failed,
              errorMessage: e.toString(),
            ),
          );
    }
  }

  Widget _buildPeerTrailing(
    BuildContext context,
    Node peer,
    PeerTransferState? transfer,
  ) {
    if (transfer == null) {
      if (!(peer.online ?? false)) {
        return const SizedBox.shrink();
      }
      return AdaptiveButton(
        onPressed: () => _sendFiles(peer),
        child: const Text('Send'),
      );
    }

    switch (transfer.status) {
      case TransferStatus.sending:
        return SizedBox(
          width: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: transfer.progress),
              Text('${(transfer.progress * 100).round()}%'),
            ],
          ),
        );

      case TransferStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _sendFiles(peer),
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () => showAlertDialog(
                context,
                'Transfer Error',
                transfer.errorMessage ?? 'Unknown error occurred',
              ),
              child: const Text('View Error'),
            ),
            const Icon(Icons.error, color: Colors.red),
          ],
        );

      case TransferStatus.complete:
        return const Icon(Icons.check_circle, color: Colors.green);
    }
  }

  // MARK: - Peer message

  Widget _buildPeerMessageBody(BuildContext context) {
    final conversations =
        List<PeerMessagingConversation>.of(ref.watch(peerMessagingConversationsProvider))
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _captionController,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: _attachmentFiles.isEmpty
                  ? 'Message'
                  : 'Add a message (optional)',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.edit_outlined),
                ),
                title: const Text('New message'),
                subtitle: const Text('Choose a device to start a thread'),
                trailing: const AdaptiveListTileChevron(),
                onTap: _startNewThread,
              ),
              if (conversations.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'Conversations',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              for (final conversation in conversations)
                _buildConversationTile(context, conversation),
              if (conversations.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No conversations yet. Start a new message above.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    PeerMessagingConversation conversation,
  ) {
    final send = _messageSends[conversation.id];
    return ListTile(
      leading: PeerDeviceAvatar(
        peerRef: conversation.id,
        showAgentBadge: conversation.hasAgentActivity,
      ),
      title: Text(
        conversation.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        conversation.preview.isEmpty
            ? 'No messages yet'
            : conversation.preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _buildMessageTrailing(context, conversation, send),
      onTap: send == null
          ? () => _sendAsMessage(conversation.id, conversation.title)
          : null,
    );
  }

  Widget _buildMessageTrailing(
    BuildContext context,
    PeerMessagingConversation conversation,
    _MessageSendState? send,
  ) {
    if (send == null) {
      return AdaptiveButton(
        onPressed: () => _sendAsMessage(conversation.id, conversation.title),
        child: const Text('Send'),
      );
    }
    switch (send.status) {
      case _MessageSendStatus.sending:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
        );
      case _MessageSendStatus.sent:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            if (!widget.standalone)
              TextButton(
                onPressed: () => _openThread(conversation.id),
                child: const Text('Open'),
              ),
          ],
        );
      case _MessageSendStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () =>
                  _sendAsMessage(conversation.id, conversation.title),
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () => showAlertDialog(
                context,
                'Message Not Sent',
                send.error ?? 'Unknown error occurred',
              ),
              child: const Text('View Error'),
            ),
            const Icon(Icons.error, color: Colors.red),
          ],
        );
    }
  }

  bool _isConnected() {
    final state = ref.read(vpnStateProvider);
    return state == VpnState.connected || state == VpnState.connecting;
  }

  /// Stages the shared files as attachments and queues one message carrying
  /// them (plus the optional caption) in [conversationId]. The daemon's
  /// outbound queue owns delivery from here; the thread view shows progress.
  /// Returns true once the message is queued.
  Future<bool> _sendAsMessage(String conversationId, String title) async {
    final files = _attachmentFiles;
    if (files.isEmpty && !_hasText) {
      setState(() {
        _messageSends[conversationId] = const _MessageSendState(
          _MessageSendStatus.failed,
          'Nothing to send: add a message or share a file.',
        );
      });
      return false;
    }
    if (!_isConnected()) {
      setState(() {
        _messageSends[conversationId] = const _MessageSendState(
          _MessageSendStatus.failed,
          'Cannot send: not connected to Cylonix.',
        );
      });
      return false;
    }
    setState(() {
      _messageSends[conversationId] =
          const _MessageSendState(_MessageSendStatus.sending);
    });
    try {
      final profileId = ref.read(currentLoginProfileProvider)?.id ?? '';
      final ipn = ref.read(ipnServiceProvider);
      final attachments = <PeerMessagingAttachment>[];
      for (final file in files) {
        attachments.add(await stageOutgoingAttachment(
          ipn: ipn,
          profileId: profileId,
          sourcePath: file.path,
          fileName: file.name,
          size: file.size,
        ));
      }
      await ref.read(peerMessagingServiceProvider.notifier).sendTextMessage(
            conversationId,
            _captionController.text,
            conversationTitle: title,
            attachments: attachments,
          );
      _logger.i(
        'Queued peer message to $conversationId: ${attachments.length} attachment(s), text=${_captionController.text.trim().length} chars',
      );
      if (!mounted) return true;
      setState(() {
        _messageSends[conversationId] =
            const _MessageSendState(_MessageSendStatus.sent);
      });
      return true;
    } catch (e) {
      _logger.e('Failed to send shared files as a peer message: $e');
      if (!mounted) return false;
      setState(() {
        _messageSends[conversationId] =
            _MessageSendState(_MessageSendStatus.failed, e.toString());
      });
      return false;
    }
  }

  Future<void> _startNewThread() async {
    final peer = await _pickPeer();
    if (peer == null || !mounted) {
      return;
    }
    final existing = ref
        .read(peerMessagingAllConversationsProvider)
        .cast<PeerMessagingConversation?>()
        .firstWhere((c) => c?.id == peer.stableID, orElse: () => null);
    final title = existing?.title ?? peer.displayName;
    try {
      await ref.read(peerMessagingServiceProvider.notifier).ensureConversation(
            conversationId: peer.stableID,
            title: title,
            subtitle: existing?.subtitle ??
                (peer.addresses.isNotEmpty ? peer.addresses.first : ''),
          );
    } catch (e) {
      _logger.e('Failed to create conversation for ${peer.stableID}: $e');
      if (mounted) {
        await showAlertDialog(context, 'Message Not Sent', '$e');
      }
      return;
    }
    if (!mounted) return;
    // A new thread is a single destination: send and land in the chat so
    // the user sees the message go out. (Existing threads stay in the list,
    // where the same files can be sent to several of them.) On failure the
    // row stays here with Retry and the error.
    final queued = await _sendAsMessage(peer.stableID, title);
    if (queued && mounted && !widget.standalone) {
      await _openThread(peer.stableID);
    }
  }

  Future<Node?> _pickPeer() {
    return showModalBottomSheet<Node>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: SizedBox(
            height: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Choose a peer',
                        style: Theme.of(context).textTheme.titleMedium,
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
                const SizedBox(height: 12),
                Expanded(
                  child: SharePeerDeviceList(
                    emptyMessage: 'No devices available to message',
                    searchHintText: 'Search name or OS…',
                    androidTvTitle: 'Select a device to start messaging',
                    onPeerTap: (peer) => () => Navigator.pop(context, peer),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Closes the sheet and opens the thread so the user can watch delivery.
  Future<void> _openThread(String conversationId) async {
    // Captured first: the sheet's context is gone once it has been popped.
    final navigator = Navigator.of(context, rootNavigator: true);
    await _finish();
    navigator.pushNamed(
      '/peer-messaging/thread',
      arguments: {'conversationId': conversationId},
    );
  }

  // MARK: - Ephemeral cleanup

  /// Deletes temp copies handed over by the share extension, except those a
  /// file-drop transfer is still reading (the daemon streams them from disk)
  /// or a message send is still staging.
  Future<void> _cleanupEphemeralFiles() async {
    final transfers = ref.read(transfersProvider);
    final unfinished = <String>{
      for (final transfer in transfers.values)
        for (final file in transfer.files)
          if (!file.finished) file.id,
    };
    final staging = _messageSends.values
        .any((send) => send.status == _MessageSendStatus.sending);
    for (final file in _sharedFiles) {
      final ids = _fileDropIds[file.path] ?? const <String>{};
      if (staging || ids.any(unfinished.contains)) {
        _logger.d('Keeping shared temp file still in use: ${file.path}');
        continue;
      }
      try {
        final f = File(file.path);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (e) {
        _logger.w('Failed to delete shared temp file ${file.path}: $e');
      }
    }
  }
}

class _ShareHeaderView extends StatelessWidget {
  final List<SharedFile> files;

  /// Shared text or link shown when it is part of what gets sent (Peer
  /// Message mode); null for File Drop, where text is already a file.
  final String? text;

  const _ShareHeaderView({required this.files, this.text});

  bool get _hasText => (text ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    final Widget leading;
    final String title;
    final String subtitle;

    if (files.isEmpty && _hasText) {
      final value = text!.trim();
      final isLink = _looksLikeLink(value);
      leading = Icon(isLink ? Icons.link : Icons.notes, size: 32);
      title = value.split('\n').first;
      subtitle = isLink ? 'Link' : 'Text';
    } else {
      if (files.length == 1 && _isImageFile(files.first.name)) {
        leading = Image.file(
          File(files.first.path),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        );
      } else {
        leading = Icon(
          files.length == 1
              ? Icons.insert_drive_file_outlined
              : Icons.file_copy_outlined,
          size: 32,
        );
      }
      title = files.length == 1 ? files.first.name : '${files.length} files';
      final size = _formatFileSize(files.fold(0, (sum, f) => sum + f.size));
      subtitle = _hasText ? '$size · with message text' : size;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(subtitle, style: textStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _looksLikeLink(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasScheme &&
        !value.contains('\n') &&
        !value.contains(' ');
  }

  bool _isImageFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.gif');
  }

  String _formatFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
