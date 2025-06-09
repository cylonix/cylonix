import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dialog_action.dart';
import '../utils/utils.dart';

/// A dialog that returns a bool result
class AlertDialogWidget extends StatelessWidget {
  final String title;
  final String? content;
  final String? additionalAskTitle;
  final String? successSubtitle;
  final String? successMsg;
  final String? failureSubtitle;
  final String? failureMsg;
  final Widget? otherActions;
  final String? okText;
  final String? cancelText;
  final void Function()? onAdditionalAskPressed;
  final void Function()? onCancel;
  final void Function()? onOK;
  final bool showOK;

  const AlertDialogWidget({
    required this.title,
    this.content,
    Key? key,
    this.additionalAskTitle,
    this.otherActions,
    this.successSubtitle,
    this.successMsg,
    this.failureSubtitle,
    this.failureMsg,
    this.cancelText,
    this.okText,
    this.onAdditionalAskPressed,
    this.onCancel,
    this.onOK,
    this.showOK = true,
  }) : super(key: key);

  Future<bool?> show(BuildContext context) async {
    return showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => this,
    );
  }

  Widget _action({required Widget child, required void Function() onPressed}) {
    return DialogAction(child: child, onPressed: onPressed);
  }

  @override
  Widget build(BuildContext context) {
    final red = TextStyle(
        color: isApple()
            ? CupertinoColors.systemRed.resolveFrom(context)
            : Colors.red);
    final green = TextStyle(
        color: isApple()
            ? CupertinoColors.systemGreen.resolveFrom(context)
            : Colors.green);
    final textStyle = isApple()
        ? TextStyle(
            fontSize: 12, color: CupertinoColors.label.resolveFrom(context))
        : Theme.of(context).textTheme.bodyMedium;
    final subtitleStyle = isApple()
        ? TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label.resolveFrom(context))
        : Theme.of(context).textTheme.titleSmall;

    return AlertDialog.adaptive(
      key: key,
      title: Text(title, textAlign: TextAlign.center),
      contentPadding: const EdgeInsets.only(bottom: 8),
      content: Material(
        type: MaterialType.transparency,
        child: SingleChildScrollView(
          controller: ScrollController(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (!isApple()) const Divider(height: 1),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (content != null)
                      Text(
                        content!,
                        textAlign: TextAlign.center,
                        style: textStyle,
                      ),
                    if (successMsg != null) ...[
                      const SizedBox(height: 8),
                      if (successSubtitle != null)
                        Text(
                          successSubtitle!,
                          style: subtitleStyle,
                          textAlign: TextAlign.center,
                        ),
                      Text(
                        successMsg!,
                        style: green,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (failureMsg != null) ...[
                      const SizedBox(height: 8),
                      if (failureSubtitle != null)
                        Text(
                          failureSubtitle!,
                          style: subtitleStyle,
                          textAlign: TextAlign.center,
                        ),
                      Text(
                        failureMsg!,
                        style: red,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (otherActions != null) ...[
                      const SizedBox(height: 8),
                      otherActions!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        if (additionalAskTitle != null)
          _action(
            child: Text(additionalAskTitle!, textAlign: TextAlign.center),
            onPressed: () {
              onAdditionalAskPressed?.call();
              Navigator.of(context).pop(true);
            },
          ),
        if (onCancel != null)
          _action(
            child: Text(
              cancelText ?? 'Cancel',
              textAlign: TextAlign.center,
            ),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        if (showOK)
          _action(
            //autofocus: true,
            child: Text(okText ?? 'OK', textAlign: TextAlign.center),
            onPressed: () {
              Navigator.of(context).pop(true);
              onOK?.call();
            },
          ),
      ],
      shape: isApple()
          ? null
          : const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
      actionsAlignment: isApple() ? null : MainAxisAlignment.center,
    );
  }
}

Future<bool?> showAlertDialog(
  BuildContext context,
  String title,
  String? content, {
  String? additionalAskTitle,
  String? successSubtitle,
  String? successMsg,
  String? failureSubtitle,
  String? failureMsg,
  String? okText,
  String? cancelText,
  Widget? otherActions,
  bool showCancel = false,
  void Function()? onPressOK,
  void Function()? onAdditionalAskedPressed,
}) {
  return AlertDialogWidget(
    title: title,
    content: content,
    additionalAskTitle: additionalAskTitle,
    successSubtitle: successSubtitle,
    successMsg: successMsg,
    failureSubtitle: failureSubtitle,
    failureMsg: failureMsg,
    cancelText: cancelText,
    okText: okText,
    otherActions: otherActions,
    onCancel: showCancel ? () => {} : null,
    onOK: onPressOK,
    onAdditionalAskPressed: onAdditionalAskedPressed,
  ).show(context);
}
