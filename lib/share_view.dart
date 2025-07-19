import 'dart:io';
import 'package:cylonix/widgets/alert_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'models/shared_file.dart';
import 'models/ipn.dart';
import 'models/peer_transfer_state.dart';
import 'providers/share_file.dart';
import 'services/ipn.dart';
import 'utils/logger.dart';

class ShareView extends ConsumerStatefulWidget {
  final List<String> paths;
  final VoidCallback onCancel;

  const ShareView({
    super.key,
    required this.paths,
    required this.onCancel,
  });

  @override
  ConsumerState<ShareView> createState() => _ShareViewState();
}

class _ShareViewState extends ConsumerState<ShareView> {
  final _searchController = TextEditingController();
  bool _showOnlineOnly = false;
  final _ipn = IpnService();
  var _sharedFiles = <SharedFile>[];
  static final _logger = Logger(tag: 'ShareView');

  @override
  void initState() {
    super.initState();
    shareFileEventBus.on<ShareFileEvent>().listen((event) {
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
      _sharedFiles = widget.paths.map((path) {
        _logger.i("Adding shared file: $path");
        return SharedFile.fromPath(path);
      }).toList();
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
  Widget build(BuildContext context) {
    final filters =
        (onlineOnly: _showOnlineOnly, searchQuery: _searchController.text);
    final peers = ref.watch(filteredPeersProvider(filters));
    final transfers = ref.watch(transfersProvider);

    return Scaffold(
      appBar: _buildHeader(),
      body: Column(
        children: [
          if (_sharedFiles.isEmpty)
            const Expanded(
              child: Center(child: Text('No files selected for sending')),
            )
          else ...[
            _FileHeaderView(files: _sharedFiles),
            _buildSearchFilter(),
            Expanded(
              child: _buildPeersList(peers, transfers),
            ),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildHeader() {
    return AppBar(
      leadingWidth: 48,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Image.asset(
          'lib/assets/images/cylonix_128.png',
          width: 24,
          height: 24,
        ),
      ),
      title: const Text('Send Files'),
      actions: [
        FilledButton(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          onPressed: widget.onCancel,
          child: const Text('Done'),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildSearchFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search name or OS…',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              Checkbox(
                value: _showOnlineOnly,
                onChanged: (value) =>
                    setState(() => _showOnlineOnly = value ?? false),
              ),
              const Text('Online Only'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeersList(
      List<Node> peers, Map<String, PeerTransferState> transfers) {
    if (peers.isEmpty) {
      return const Center(
        child: Text('No devices available to share with'),
      );
    }

    return ListView.builder(
      itemCount: peers.length,
      itemBuilder: (context, index) {
        final peer = peers[index];
        return _PeerRow(
          peer: peer,
          transfer: transfers[peer.stableID],
          onSend: () => _sendFiles(peer),
          onRetry: () => _sendFiles(peer),
        );
      },
    );
  }

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
}

class _FileHeaderView extends StatelessWidget {
  final List<SharedFile> files;

  const _FileHeaderView({required this.files});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Show thumbnail or icon
          if (files.length == 1 && _isImageFile(files.first.path))
            Image.file(
              File(files.first.path),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            )
          else
            Icon(
              files.length == 1
                  ? Icons.insert_drive_file_outlined
                  : Icons.file_copy_outlined,
              size: 32,
            ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                files.length == 1 ? files.first.name : '${files.length} files',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                _formatFileSize(files.fold(0, (sum, f) => sum + f.size)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
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

class _PeerRow extends StatelessWidget {
  final Node peer;
  final PeerTransferState? transfer;
  final VoidCallback onSend;
  final VoidCallback onRetry;

  const _PeerRow({
    required this.peer,
    this.transfer,
    required this.onSend,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 4,
        backgroundColor: peer.online ?? false ? Colors.green : Colors.grey,
      ),
      title: Text(
        peer.displayName.split('.').first,
        style: TextStyle(
          fontWeight:
              peer.online ?? false ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(_getOSIcon(peer.hostinfo?.os), size: 16),
          const SizedBox(width: 4),
          if (peer.hostinfo?.os != null) Text(peer.hostinfo!.os!),
        ],
      ),
      trailing: _buildTrailing(context),
    );
  }

  IconData _getOSIcon(String? os) {
    if (os == null) return Icons.devices;
    final osLower = os.toLowerCase();
    if (osLower.contains('mac')) return Icons.desktop_mac_outlined;
    if (osLower.contains('windows')) return Icons.desktop_windows;
    if (osLower.contains('linux')) return Icons.computer;
    if (osLower.contains('ios')) return Icons.phone_iphone;
    if (osLower.contains('android')) return Icons.phone_android;
    return Icons.devices;
  }

  Widget? _buildTrailing(BuildContext context) {
    if (transfer == null) {
      if (!(peer.online ?? false)) {
        return null;
      }
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onPressed: peer.online ?? false ? onSend : null,
        child: const Text('Send'),
      );
    }

    switch (transfer!.status) {
      case TransferStatus.sending:
        return SizedBox(
          width: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: transfer!.progress),
              Text('${(transfer!.progress * 100).round()}%'),
            ],
          ),
        );

      case TransferStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () => showAlertDialog(
                context,
                'Transfer Error',
                transfer!.errorMessage ?? 'Unknown error occurred',
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
}
