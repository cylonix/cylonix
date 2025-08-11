// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:downloadsfolder/downloadsfolder.dart' as dlf;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'providers/ipn.dart';
import 'utils/utils.dart';
import 'widgets/adaptive_widgets.dart';
import 'widgets/alert_dialog_widget.dart';

class FilesWaitingView extends ConsumerWidget {
  const FilesWaitingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(filesWaitingProvider);
    final filesSaved = ref.watch(filesSavedProvider);
    return Column(
      children: [
        AdaptiveListTile(
          leading: Icon(
            isApple() ? CupertinoIcons.doc : Icons.insert_drive_file_outlined,
          ),
          backgroundColor: Colors.transparent,
          title: const Text(
            'Files Waiting',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          trailing: AdaptiveButton(
            filled: true,
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ),
        Expanded(
          child: files.isEmpty
              ? const Center(child: Text('There is no file waiting'))
              : SingleChildScrollView(
                  child: AdaptiveListSection.insetGrouped(
                    footer: const AdaptiveGroupedFooter(
                      'Save or delete files as needed',
                    ),
                    children: files
                        .map(
                          (file) => _buildFileTile(
                            context,
                            file.name,
                            file.size,
                            filesSaved,
                            ref,
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFileTile(
    BuildContext context,
    String fileName,
    int fileSize,
    List<String> filesSaved,
    WidgetRef ref,
  ) {
    final saved = filesSaved.contains(fileName);
    return AdaptiveListTile.notched(
      leading: Icon(
        isApple() ? CupertinoIcons.doc : Icons.insert_drive_file_outlined,
      ),
      title: Text(fileName),
      subtitle: Text(formatBytes(fileSize)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (saved) AdaptiveSuccessIcon(),
          IconButton(
            icon: Icon(
                isApple() ? CupertinoIcons.download_circle : Icons.save_alt),
            tooltip: saved ? 'Save Again' : 'Save',
            onPressed: () => _saveFile(context, fileName, ref),
          ),
          IconButton(
            icon: Icon(isApple() ? CupertinoIcons.delete : Icons.delete),
            tooltip: 'Delete',
            onPressed: () => _deleteFile(context, fileName, ref),
          ),
        ],
      ),
    );
  }

  void _saveFile(BuildContext context, String fileName, WidgetRef ref) async {
    try {
      var showPath = fileName;
      if (Platform.isAndroid) {
        final srcPath = await ref
            .read(ipnStateNotifierProvider.notifier)
            .getFilePath(fileName);
        await dlf.copyFileIntoDownloadFolder(
          srcPath,
          fileName,
        );
        showPath = 'the "Download" folder';
      } else if (Platform.isMacOS) {
        final srcPath = await ref
            .read(ipnStateNotifierProvider.notifier)
            .getFilePath(fileName);
        final toPath = await FilePicker.platform.saveFile(
          dialogTitle: "Choose the file to be saved",
          fileName: fileName,
        );
        if (toPath == null) {
          return null; // User canceled the picker
        }
        await File(srcPath).copy(toPath);
        showPath = toPath;
      } else {
        final toPath = await FilePicker.platform.saveFile(
          dialogTitle: "Choose the file to be saved",
          fileName: fileName,
        );

        if (toPath == null) {
          return null; // User canceled the picker
        }
        await ref
            .read(ipnStateNotifierProvider.notifier)
            .saveFile(fileName, toPath);
        showPath = toPath;
      }
      ref.read(filesSavedProvider.notifier).addFile(fileName);
      if (context.mounted) {
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
              child: Text(
                'File deleted successfully: $fileName',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
      ref.read(filesSavedProvider.notifier).remove(fileName);
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
