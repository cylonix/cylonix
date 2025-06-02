import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/utils.dart';

class DialogAction extends StatelessWidget {
  final Widget child;
  final Function() onPressed;
  const DialogAction({Key? key, required this.child, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isApple()
        ? CupertinoDialogAction(child: child, onPressed: onPressed)
        : TextButton(
            onPressed: onPressed,
            child: Container(
              constraints: const BoxConstraints(minWidth: 60),
              child: child,
            ),
          );
  }
}
