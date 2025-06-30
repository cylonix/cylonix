import 'package:cylonix/widgets/alert_dialog_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'providers/ipn.dart';
import 'utils/utils.dart';
import 'widgets/adaptive_widgets.dart';

class FilesWaitingView extends ConsumerWidget {
  const FilesWaitingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(filesWaitingProvider);
    return Column(
      children: [
        AdaptiveListTile(
          title: const Text(''),
          trailing: AdaptiveButton(
            filled: true,
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ),
        files.isEmpty
            ? const Center(child: Text('No files waiting.'))
            : SingleChildScrollView(
                child: AdaptiveListSection.insetGrouped(
                  header: const AdaptiveGroupedHeader("Files Waiting"),
                  footer: const AdaptiveGroupedFooter(
                      'Save or delete files as needed.'),
                  children: files.map((file) {
                    return AdaptiveListTile.notched(
                      leading: Icon(
                        isApple()
                            ? CupertinoIcons.doc
                            : Icons.insert_drive_file_outlined,
                      ),
                      title: Text(file.name),
                      subtitle: Text(formatBytes(file.size)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(isApple()
                                ? CupertinoIcons.download_circle
                                : Icons.save_alt),
                            tooltip: 'Save',
                            onPressed: () => _saveFile(context, file.name, ref),
                          ),
                          IconButton(
                            icon: Icon(isApple()
                                ? CupertinoIcons.delete
                                : Icons.delete),
                            tooltip: 'Delete',
                            onPressed: () =>
                                _deleteFile(context, file.name, ref),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
      ],
    );
  }

  void _saveFile(BuildContext context, String fileName, WidgetRef ref) async {
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: "Choose the file to be saved",
        fileName: fileName,
      );

      if (path == null) {
        return null; // User canceled the picker
      }
      await ref
          .read(ipnStateNotifierProvider.notifier)
          .saveFile(fileName, path);
      if (context.mounted) {
        showTopSnackBar(
          context,
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('File saved successfully to: $path'),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        await showAlertDialog(
          context,
          'Error',
          'Failed to save file: $e',
        );
      }
    }
  }

  void _deleteFile(
    BuildContext context,
    String fileName,
    WidgetRef ref,
  ) async {
    try {
      await ref.read(ipnStateNotifierProvider.notifier).deleteFile(fileName);
      if (context.mounted) {
        showTopSnackBar(
          context,
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('File deleted successfully: $fileName'),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        await showAlertDialog(
          context,
          'Error',
          'Failed to delete file: $e',
        );
      }
    }
  }
}
