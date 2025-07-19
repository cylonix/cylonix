import 'package:flutter/material.dart';
import 'qr_code_image.dart';

class TVButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool filled;
  final bool autofocus;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const TVButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.filled = false,
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
    return Focus(
      focusNode: focusNode,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.filled
            ? FilledButton(
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
                  shape: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.focused)) {
                      return RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                        side: const BorderSide(
                          color: Colors.tealAccent,
                          width: 2,
                        ),
                      );
                    }
                    return null;
                  }),
                  padding: WidgetStateProperty.all(
                    widget.padding ??
                        const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                child: widget.child,
              )
            : OutlinedButton(
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
                  padding: WidgetStateProperty.all(
                    widget.padding ??
                        const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                child: widget.child,
              ),
      ),
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
