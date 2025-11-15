// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'qr_code_image.dart';

class TVButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool filled;
  final bool textButton;
  final bool iconButton;
  final bool autofocus;
  final double? width;
  final double? height;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? padding;

  const TVButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.filled = false,
    this.textButton = false,
    this.iconButton = false,
    this.autofocus = false,
    this.width,
    this.height,
    this.focusNode,
    this.padding,
  });

  @override
  State<TVButton> createState() => _TVButtonState();
}

class _TVButtonState extends State<TVButton> {
  late final FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      focusNode.dispose();
    }
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
              : widget.textButton
                  ? _textButton
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

  Widget get _textButton {
    return TextButton(
      focusNode: focusNode,
      autofocus: widget.autofocus,
      onPressed: widget.onPressed,
      style: ButtonStyle(
        shape: _buttonShape,
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
class ScrollableTextTV extends StatefulWidget {
  final String longText;

  const ScrollableTextTV({Key? key, required this.longText}) : super(key: key);

  @override
  _ScrollableTextTVState createState() => _ScrollableTextTVState();
}

class _ScrollableTextTVState extends State<ScrollableTextTV> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Handle D-pad key events
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _scrollController.animateTo(
          _scrollController.offset + 50.0, // Scroll down by a fixed amount
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _scrollController.animateTo(
          _scrollController.offset - 50.0, // Scroll up by a fixed amount
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.longText,
            style: const TextStyle(fontSize: 18.0),
          ),
        ),
      ),
    );
  }
}

class TVSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveThumbColor;
  final Color? inactiveTrackColor;
  final bool autofocus;

  const TVSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.autofocus = false,
  });

  @override
  State<TVSwitch> createState() => _TVSwitchState();
}

class _TVSwitchState extends State<TVSwitch> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        // Handle Enter/Select key to toggle switch
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          if (widget.onChanged != null) {
            widget.onChanged!(!widget.value);
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        decoration: BoxDecoration(
          border: _isFocused
              ? Border.all(
                  color: Colors.tealAccent,
                  width: 2,
                )
              : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Switch(
            value: widget.value,
            onChanged: widget.onChanged,
            activeColor: widget.activeColor,
            inactiveThumbColor: widget.inactiveThumbColor,
            inactiveTrackColor: widget.inactiveTrackColor,
          ),
        ),
      ),
    );
  }
}

class TVTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final String? labelText;
  final String? hintText;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final int? minLines;
  final bool obscureText;
  final TextStyle? style;

  const TVTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.nextFocusNode,
    this.labelText,
    this.hintText,
    this.initialValue,
    this.validator,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.autofocus = false,
    this.onFieldSubmitted,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.style,
  });

  @override
  State<TVTextFormField> createState() => _TVTextFormFieldState();
}

class _TVTextFormFieldState extends State<TVTextFormField> {
  late final FocusNode _internalFocusNode;
  late final TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(_onFocusChange);
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void didUpdateWidget(TVTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      _internalFocusNode.removeListener(_onFocusChange);
      if (widget.focusNode != null && oldWidget.focusNode == null) {
        _internalFocusNode.dispose();
        _internalFocusNode = widget.focusNode!;
      }
      if (widget.focusNode != null) {
        widget.focusNode!.addListener(_onFocusChange);
      }
    }
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
    }
  }

  @override
  void dispose() {
    _internalFocusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _internalFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        // Handle back button when text field is focused
        if (event is KeyUpEvent &&
            event.logicalKey == LogicalKeyboardKey.goBack &&
            _isFocused) {
          if (!(_internalFocusNode.nextFocus())) {
            _internalFocusNode.unfocus();
          }

          // If nextFocusNode is provided, focus it
          if (widget.nextFocusNode != null) {
            widget.nextFocusNode!.requestFocus();
          }

          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: _textField,
          ),
          if (!_isFocused) ...[
            if (_controller.text.isNotEmpty)
              TVButton(
                iconButton: true,
                child: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _controller.clear();
                  });
                },
              ),
            TVButton(
              iconButton: true,
              child: const Icon(Icons.edit),
              onPressed: () {
                _internalFocusNode.requestFocus();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget get _textField {
    // Create the focus border
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: Colors.tealAccent,
        width: 2,
      ),
    );

    // Merge with existing decoration
    final decoration = widget.decoration ??
        InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          border: const OutlineInputBorder(),
        );

    final mergedDecoration = decoration.copyWith(
      focusedBorder: _isFocused ? focusBorder : decoration.focusedBorder,
      enabledBorder: _isFocused ? focusBorder : decoration.enabledBorder,
    );
    return TextFormField(
      controller: widget.controller,
      focusNode: _internalFocusNode,
      autofocus: widget.autofocus,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      style: widget.style,
      decoration: mergedDecoration,
      onFieldSubmitted: widget.onFieldSubmitted,
      onChanged: widget.onChanged,
      validator: widget.validator,
      initialValue: widget.initialValue,
    );
  }
}
