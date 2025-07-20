import 'package:flutter/material.dart';
import 'qr_code_image.dart';

class TVButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool filled;
  final bool iconButton;
  final bool autofocus;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const TVButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.filled = false,
    this.iconButton = false,
    this.autofocus = false,
    this.width,
    this.height,
    this.padding,
  });

  @override
  State<TVButton> createState() => _TVButtonState();
}

class _TVButtonState extends State<TVButton> {
  final focusNode = FocusNode();

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: widget.filled
          ? _filledButton
          : widget.iconButton
              ? _iconButton
              : _outlinedButton,
    );
  }

  WidgetStateProperty<OutlinedBorder?>? get _buttonShape {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        if (widget.iconButton) {
          return const CircleBorder(
            side: BorderSide(
              color: Colors.tealAccent,
              width: 2,
            ),
          );
        }
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: const BorderSide(
            color: Colors.tealAccent,
            width: 2,
          ),
        );
      }
      return null;
    });
  }

  Widget get _outlinedButton {
    return OutlinedButton(
      focusNode: focusNode,
      autofocus: widget.autofocus,
      onPressed: widget.onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.2);
          }
          return null;
        }),
        shape: _buttonShape,
        padding: WidgetStateProperty.all(
          widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      child: widget.child,
    );
  }

  Widget get _iconButton {
    return IconButton(
      focusNode: focusNode,
      autofocus: widget.autofocus,
      onPressed: widget.onPressed,
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.2);
          }
          return null;
        }),
        shape: _buttonShape,
      ),
      icon: widget.child,
    );
  }

  Widget get _filledButton {
    return FilledButton(
      focusNode: focusNode,
      autofocus: widget.autofocus,
      onPressed: widget.onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return Theme.of(context).colorScheme.primaryContainer;
          }
          return null; // Use default color when not focused
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return Theme.of(context).colorScheme.onPrimaryContainer;
          }
          return null; // Use default color when not focused
        }),
        shape: _buttonShape,
        padding: WidgetStateProperty.all(
          widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      child: widget.child,
    );
  }
}

Future<void> showQrCodeForURL(BuildContext context, String url) async {
  await showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text("View on your phone"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Text("Please scan the QR code with your phone to view $url"),
          QrCodeImage(url),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(c).pop(),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}
