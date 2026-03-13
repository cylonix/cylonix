// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'glass_switch.dart';

/// A native UISwitch on iOS and NSSwitch on macOS.
class NativeSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const NativeSwitch({super.key, required this.value, this.onChanged});

  @override
  State<NativeSwitch> createState() => _NativeSwitchState();
}

class _NativeSwitchState extends State<NativeSwitch> {
  MethodChannel? _channel;
  bool _isCurrent = true;
  Brightness? _brightness;
  // Sized from UISwitch.intrinsicContentSize reported by the native side.
  // Falls back to GlassSwitch dimensions until the native side reports.
  double _nativeW = GlassSwitch.trackW;
  double _nativeH = GlassSwitch.trackH;

  // When a modal covers this route, the iOS 26 liquid-glass UISwitch glow
  // renders above Flutter's overlay regardless of touch state — it cannot be
  // suppressed by any UIView overlay or CA manipulation. Instead, hide the
  // native switch (isHidden=true stops all UIKit glass rendering) and overlay
  // a Flutter-rendered CupertinoSwitch that composites correctly through the
  // modal scrim like every other Flutter widget.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Platform.isIOS) {
      final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
      if (_isCurrent != isCurrent) {
        setState(() => _isCurrent = isCurrent);
        _channel?.invokeMethod('setHidden', !isCurrent);
      }
    }
    final brightness = CupertinoTheme.brightnessOf(context);
    if (_brightness != brightness) {
      _brightness = brightness;
      _channel?.invokeMethod('setAppearance', brightness == Brightness.dark ? 'dark' : 'light');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fixed intrinsic size in points (UISwitch / NSSwitch)
    if (Platform.isIOS) {
      return SizedBox(
        width: _nativeW + 8,
        height: _nativeH,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Always keep UiKitView in the tree so the method channel stays
            // alive and layout space is preserved.
            UiKitView(
              viewType: 'io.cylonix/uiswitch',
              creationParams: {
                'value': widget.value,
                'enabled': widget.onChanged != null,
              },
              creationParamsCodec: const StandardMessageCodec(),
              onPlatformViewCreated: _onViewCreated,
            ),
            // Flutter-rendered glass fallback shown when the native switch is
            // hidden to prevent glow bleed-through. Composites correctly below
            // the modal scrim like every other Flutter widget.
            if (!_isCurrent)
              GlassSwitch(
                  value: widget.value, width: _nativeW, height: _nativeH),
          ],
        ),
      );
    }
    // macOS — AppKitView wraps the registered NSSwitch native view.
    return SizedBox(
      width: _nativeW,
      height: _nativeH,
      child: AppKitView(
        viewType: 'io.cylonix/uiswitch',
        creationParams: {
          'value': widget.value,
          'enabled': widget.onChanged != null,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onViewCreated,
      ),
    );
  }

  void _onViewCreated(int id) {
    _channel = MethodChannel('io.cylonix/uiswitch/$id');
    if (_brightness != null) {
      _channel!.invokeMethod('setAppearance', _brightness == Brightness.dark ? 'dark' : 'light');
    }
    _channel!.setMethodCallHandler((call) async {
      if (call.method == 'onChanged') {
        widget.onChanged?.call(call.arguments as bool);
      } else if (call.method == 'intrinsicSize') {
        final m = call.arguments as Map;
        final w = (m['width'] as num).toDouble() + 2;
        final h = (m['height'] as num).toDouble();
        print('NativeSwitch intrinsic size: $w x $h');
        if (w != _nativeW || h != _nativeH) {
          setState(() {
            _nativeW = w;
            _nativeH = h;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(NativeSwitch old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _channel?.invokeMethod('setValue', widget.value);
    }
    if ((old.onChanged == null) != (widget.onChanged == null)) {
      _channel?.invokeMethod('setEnabled', widget.onChanged != null);
    }
  }
}
