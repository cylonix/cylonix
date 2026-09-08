// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/utils.dart';

/// Asks for a new thread title. Resolves with the entered text, or null when
/// cancelled. Callers trim the result and ignore an empty one.
Future<String?> showRenameConversationDialog(
  BuildContext context, {
  required String currentTitle,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _RenameConversationDialog(currentTitle: currentTitle),
  );
}

class _RenameConversationDialog extends StatefulWidget {
  final String currentTitle;

  const _RenameConversationDialog({required this.currentTitle});

  @override
  State<_RenameConversationDialog> createState() =>
      _RenameConversationDialogState();
}

class _RenameConversationDialogState extends State<_RenameConversationDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.currentTitle);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    final field = isApple()
        ? CupertinoTextField(
            controller: _controller,
            autofocus: true,
            placeholder: 'Thread name',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          )
        : TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Thread name'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          );
    return AlertDialog.adaptive(
      title: const Text('Rename Thread'),
      content: Padding(
        padding: EdgeInsets.only(top: isApple() ? 12 : 4),
        child: field,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
