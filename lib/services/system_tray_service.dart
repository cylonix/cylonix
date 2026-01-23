import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:system_tray/system_tray.dart';
import 'package:image/image.dart' as img;
import '../utils/logger.dart';

class SystemTrayService {
  static final _logger = Logger(tag: "SystemTray");
  static final SystemTray _systemTray = SystemTray();
  static final AppWindow _appWindow = AppWindow();
  static bool _isInitialized = false;
  static bool _isConnected = false;
  static bool _isUpdatingMenu = false;

  // Callbacks
  static Future<void> Function()? _onConnect;
  static Future<void> Function()? _onDisconnect;

  // Icon paths (asset paths for bundled icons)
  // Windows uses .ico files, macOS uses .png files
  static String get _iconConnected => Platform.isWindows
      ? 'lib/assets/images/cylonix_connected.ico'
      : 'lib/assets/images/cylonix_32_gray.png';
  static String get _iconDisconnected => Platform.isWindows
      ? 'lib/assets/images/cylonix_disconnected.ico'
      : 'lib/assets/images/cylonix_disconnected_32_gray.png';
  static String get _iconDefault => Platform.isWindows
      ? 'lib/assets/images/cylonix.ico'
      : 'lib/assets/images/cylonix_32_gray.png';

  // Cache directory for generated icons (user-writable)
  static String? _cacheDir;

  // Current state info
  static String _displayName = '';
  static String _deviceName = '';
  static String _email = '';
  static String? _avatarUrl;
  static String? _cachedAvatarPath; // Now stores full path, not asset path

  static void setCallbacks({
    Future<void> Function()? onConnect,
    Future<void> Function()? onDisconnect,
  }) {
    _onConnect = onConnect;
    _onDisconnect = onDisconnect;
  }

  static Future<void> init({
    Future<void> Function()? onConnect,
    Future<void> Function()? onDisconnect,
  }) async {
    if (!Platform.isWindows && !Platform.isMacOS) return;
    if (_isInitialized) return;

    _onConnect = onConnect;
    _onDisconnect = onDisconnect;

    try {
      await _systemTray.initSystemTray(
        title: Platform.isMacOS ? "" : "Cylonix",
        iconPath: _iconDefault,
        toolTip: "Cylonix - Disconnected",
      );

      await _updateContextMenu();

      _systemTray.registerSystemTrayEventHandler((eventName) {
        _logger.d("System tray event: $eventName");
        if (eventName == kSystemTrayEventClick) {
          _handleClick();
        } else if (eventName == kSystemTrayEventRightClick) {
          _systemTray.popUpContextMenu();
        }
      });

      _isInitialized = true;
      _logger.i("System tray initialized");
    } catch (e) {
      _logger.e("Failed to initialize system tray: $e");
    }
  }

  static void _handleClick() {
    if (_isConnected) {
      // If connected, show context menu
      _systemTray.popUpContextMenu();
    } else {
      // If disconnected, connect
      _onConnect?.call();
    }
  }

  /// Get user-writable cache directory for generated icons
  static Future<String> _getIconCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;

    final appDir = await (Platform.isWindows
        ? getApplicationSupportDirectory()
        : getTemporaryDirectory());
    _cacheDir = p.join(appDir.path, 'tray_icons');

    // Ensure directory exists
    final dir = Directory(_cacheDir!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return _cacheDir!;
  }

  /// Generate an icon with the user's initial
  static Future<String?> _generateInitialIcon() async {
    if (_displayName.isEmpty) return null;

    try {
      final initial = _displayName[0].toUpperCase();
      final cacheDir = await _getIconCacheDir();
      final extension = Platform.isWindows ? 'bmp' : 'png';
      final fullPath = p.join(cacheDir, 'cylonix_initial_$initial.$extension');
      _logger.d("Initial icon path: $fullPath");

      // Check if we already generated this initial
      final iconFile = File(fullPath);
      if (await iconFile.exists()) {
        _logger.d("Using cached initial icon: $fullPath");
        return fullPath;
      }

      // Create icon using dart:ui
      await _createInitialIcon(fullPath, initial);
      _logger.d("Generated initial icon at $fullPath");
      return fullPath;
    } catch (e) {
      _logger.e("Failed to generate initial icon: $e");
      return null;
    }
  }

  /// Create a Windows-compatible BMP file or a PNG file with an initial letter
  static Future<void> _createInitialIcon(String path, String initial) async {
    const size = 32;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Fill with menu background color (light gray, similar to Windows menu)
    // Or transparent for macOS to blend with the menu bar
    if (Platform.isWindows) {
      final bgPaint = ui.Paint()
        ..color = const ui.Color(0xFFF0F0F0) // Light gray background
        ..style = ui.PaintingStyle.fill;
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 32.0, 32.0),
        bgPaint,
      );
    }

    // Draw blue circle
    final circlePaint = ui.Paint()
      ..color = const ui.Color(0xFF4A90D9)
      ..style = ui.PaintingStyle.fill;
    canvas.drawCircle(
      const ui.Offset(size / 2, size / 2),
      size / 2 - 1, // Slightly smaller to show background
      circlePaint,
    );

    // Draw the initial letter
    final textStyle = ui.TextStyle(
      color: const ui.Color(0xFFFFFFFF),
      fontSize: 18,
      fontWeight: ui.FontWeight.bold,
    );

    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: ui.TextAlign.center,
    ))
      ..pushStyle(textStyle)
      ..addText(initial);

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: size.toDouble()));

    final textY = (size - paragraph.height) / 2;
    canvas.drawParagraph(paragraph, ui.Offset(0, textY));

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    // On Windows we need a BMP; on macOS write PNG bytes directly (preserves alpha).
    if (Platform.isWindows) {
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) throw Exception('Failed to convert image to bytes');
      final rgbaBytes = byteData.buffer.asUint8List();
      final bmpBytes = _createWindows24BitBmp(rgbaBytes, size, size);
      await File(path).writeAsBytes(bmpBytes);
      _logger.d(
          "Created Windows BMP file at $path, size: ${bmpBytes.length} bytes");
    } else {
      final pngData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (pngData == null) {
        throw Exception('Failed to convert image to PNG bytes');
      }
      await File(path).writeAsBytes(pngData.buffer.asUint8List());
      _logger
          .d("Created PNG file at $path, size: ${pngData.lengthInBytes} bytes");
    }
  }

  /// Download avatar from URL and cache it locally
  static Future<String?> _getAvatarIconPath() async {
    if (_avatarUrl == null || _avatarUrl!.isEmpty) {
      _logger.d("avatar icon path is empty. Generating initial icon");
      return await _generateInitialIcon();
    }

    try {
      // Check if we already have a cached avatar
      if (_cachedAvatarPath != null) {
        if (await File(_cachedAvatarPath!).exists()) {
          return _cachedAvatarPath!;
        }
      }

      // Download avatar
      final response = await http.get(Uri.parse(_avatarUrl!));
      if (response.statusCode != 200) {
        _logger.e("Failed to download avatar: ${response.statusCode}");
        return await _generateInitialIcon();
      }

      // Decode the image using image package
      final originalImage = img.decodeImage(response.bodyBytes);
      if (originalImage == null) {
        _logger.e("Failed to decode avatar image");
        return await _generateInitialIcon();
      }

      // Resize to 32x32 for menu icon
      final resized = img.copyResize(originalImage, width: 32, height: 32);

      // Apply circular mask with light gray (Windows) or transparent (macOS)
      final circularAvatar = _applyCircularMask(resized);

      // Get cache directory and full path
      final cacheDir = await _getIconCacheDir();
      final extension = Platform.isWindows ? 'bmp' : 'png';
      final fullPath = p.join(cacheDir, 'cylonix_avatar.$extension');

      // Create platform-appropriate icon format
      if (Platform.isWindows) {
        // Convert to RGBA bytes and create BMP for Windows
        final rgbaBytes = _imageToRgba(circularAvatar);
        final bmpBytes = _createWindows24BitBmp(rgbaBytes, 32, 32);
        await File(fullPath).writeAsBytes(bmpBytes);
      } else {
        // macOS: encode the processed img.Image directly to PNG to preserve alpha
        final pngBytes = Uint8List.fromList(img.encodePng(circularAvatar));
        await File(fullPath).writeAsBytes(pngBytes);
      }

      _cachedAvatarPath = fullPath;
      _logger.d("Avatar saved to: $fullPath");
      return fullPath;
    } catch (e) {
      _logger.e("Failed to get avatar: $e");
      return await _generateInitialIcon();
    }
  }

  /// Apply circular mask to an image.
  ///
  /// On Windows we use a light gray background to match menu styling.
  /// On macOS we use a fully transparent background so the avatar blends
  /// with the menu bar/tray.
  static img.Image _applyCircularMask(img.Image source) {
    final size = source.width; // Assume square image
    final result = img.Image(width: size, height: size, numChannels: 4);
    final center = size / 2;
    final radius = size / 2 - 1; // Slightly smaller to show background edge

    // Background color: light gray for Windows, transparent elsewhere
    final bgColor = Platform.isWindows
        ? img.ColorRgba8(0xF0, 0xF0, 0xF0, 0xFF)
        : img.ColorRgba8(0x00, 0x00, 0x00, 0x00);

    img.Image rgbaImage = source;
    if (source.numChannels == 3) {
      rgbaImage = source.convert(numChannels: 4);
    }

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        // Calculate distance from center
        final dx = x - center + 0.5;
        final dy = y - center + 0.5;
        final distance = (dx * dx + dy * dy);

        if (distance <= radius * radius) {
          // Inside circle - use source pixel
          result.setPixel(x, y, rgbaImage.getPixel(x, y));
        } else {
          // Outside circle - use background color
          result.setPixel(x, y, bgColor);
        }
      }
    }

    return result;
  }

  /// Convert an img.Image to RGBA bytes
  static Uint8List _imageToRgba(img.Image image) {
    final width = image.width;
    final height = image.height;
    final rgba = Uint8List(width * height * 4);

    int offset = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        rgba[offset++] = pixel.r.toInt();
        rgba[offset++] = pixel.g.toInt();
        rgba[offset++] = pixel.b.toInt();
        rgba[offset++] = pixel.a.toInt();
      }
    }

    return rgba;
  }

  /// Create a Windows-compatible 24-bit BMP from RGBA pixel data
  /// Replaces transparent pixels with light gray background
  static Uint8List _createWindows24BitBmp(
      Uint8List rgbaPixels, int width, int height) {
    // BMP files store rows bottom-to-top and use BGR order (not RGB)
    // 24-bit BMP has maximum compatibility with Windows LoadImage

    final rowSize =
        ((width * 3 + 3) ~/ 4) * 4; // Each row must be 4-byte aligned
    final pixelDataSize = rowSize * height;
    final fileSize =
        54 + pixelDataSize; // 14 (file header) + 40 (info header) + pixel data

    final bmp = ByteData(fileSize);
    int offset = 0;

    // === BMP File Header (14 bytes) ===
    bmp.setUint8(offset++, 0x42); // 'B'
    bmp.setUint8(offset++, 0x4D); // 'M'
    bmp.setUint32(offset, fileSize, Endian.little);
    offset += 4;
    bmp.setUint16(offset, 0, Endian.little);
    offset += 2;
    bmp.setUint16(offset, 0, Endian.little);
    offset += 2;
    bmp.setUint32(offset, 54, Endian.little);
    offset += 4;

    // === BITMAPINFOHEADER (40 bytes) ===
    bmp.setUint32(offset, 40, Endian.little);
    offset += 4;
    bmp.setInt32(offset, width, Endian.little);
    offset += 4;
    bmp.setInt32(offset, height, Endian.little);
    offset += 4;
    bmp.setUint16(offset, 1, Endian.little);
    offset += 2;
    bmp.setUint16(offset, 24, Endian.little);
    offset += 2;
    bmp.setUint32(offset, 0, Endian.little);
    offset += 4;
    bmp.setUint32(offset, pixelDataSize, Endian.little);
    offset += 4;
    bmp.setInt32(offset, 2835, Endian.little);
    offset += 4;
    bmp.setInt32(offset, 2835, Endian.little);
    offset += 4;
    bmp.setUint32(offset, 0, Endian.little);
    offset += 4;
    bmp.setUint32(offset, 0, Endian.little);
    offset += 4;

    // Background color for transparent pixels (light gray)
    const bgR = 0xF0;
    const bgG = 0xF0;
    const bgB = 0xF0;

    // === Pixel data (bottom-to-top, BGR order) ===
    for (int y = height - 1; y >= 0; y--) {
      for (int x = 0; x < width; x++) {
        final srcOffset = (y * width + x) * 4; // RGBA source
        final r = rgbaPixels[srcOffset];
        final g = rgbaPixels[srcOffset + 1];
        final b = rgbaPixels[srcOffset + 2];
        final a = rgbaPixels[srcOffset + 3];

        // Alpha blending with background
        int finalR, finalG, finalB;
        if (a == 255) {
          finalR = r;
          finalG = g;
          finalB = b;
        } else if (a == 0) {
          finalR = bgR;
          finalG = bgG;
          finalB = bgB;
        } else {
          // Blend with background
          final alpha = a / 255.0;
          finalR = (r * alpha + bgR * (1 - alpha)).round();
          finalG = (g * alpha + bgG * (1 - alpha)).round();
          finalB = (b * alpha + bgB * (1 - alpha)).round();
        }

        bmp.setUint8(offset++, finalB); // Blue first
        bmp.setUint8(offset++, finalG); // Green
        bmp.setUint8(offset++, finalR); // Red
      }
      // Row padding to 4-byte boundary
      final padding = rowSize - width * 3;
      for (int p = 0; p < padding; p++) {
        bmp.setUint8(offset++, 0);
      }
    }

    return bmp.buffer.asUint8List();
  }

  static Future<void> _updateContextMenu() async {
    // Prevent concurrent menu updates
    if (_isUpdatingMenu) {
      _logger.d("Menu update already in progress, waiting...");
      for (int i = 0; i < 5; i++) {
        if (!_isUpdatingMenu) break;
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (_isUpdatingMenu) {
        _logger
            .d("Menu update still in progress after waiting, skipping update");
        return;
      }
    }
    _isUpdatingMenu = true;

    try {
      final menu = Menu();

      final menuItems = <MenuItemBase>[
        // Connection status with checkmark if connected
        MenuItemCheckbox(
          label: _isConnected
              ? 'Cylonix is connected. Click to disconnect'
              : 'Cylonix is disconnected. Click to connect.',
          checked: _isConnected,
          onClicked: (menuItem) async {
            if (_isConnected) {
              await _onDisconnect?.call();
            } else {
              await _onConnect?.call();
            }
          },
        ),
        MenuSeparator(),
      ];

      // Account information (if available)
      if (_displayName.isNotEmpty) {
        final avatarPath = await _getAvatarIconPath();

        menuItems.add(
          MenuItemLabel(
            label: _displayName,
            image: avatarPath, // Now returns full path directly
            onClicked: (menuItem) => _appWindow.show(),
          ),
        );
      }
      if (_email.isNotEmpty) {
        menuItems.add(
          MenuItemLabel(
            label: 'Email: $_email',
            onClicked: (menuItem) => _appWindow.show(),
          ),
        );
      }

      // Device name (if available)
      if (_deviceName.isNotEmpty) {
        menuItems.add(
          MenuItemLabel(
            label: 'Device: $_deviceName',
            onClicked: (menuItem) => _appWindow.show(),
          ),
        );
      }

      // Add divider and exit
      menuItems.addAll([
        MenuSeparator(),
        MenuItemLabel(
          label: 'Show Cylonix',
          onClicked: (menuItem) => _appWindow.show(),
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: 'Exit',
          onClicked: (menuItem) => exit(0),
        ),
      ]);

      _logger.d("Building menu with ${menuItems.length} items");
      await menu.buildFrom(menuItems);
      await _systemTray.setContextMenu(menu);
      _logger.d("Context menu updated");
    } finally {
      _isUpdatingMenu = false;
    }
  }

  /// Update tray icon and tooltip based on connection state
  static Future<void> setConnectionState({
    required bool isConnected,
    String? tooltip,
    String? displayName,
    String? deviceName,
    String? email,
    String? avatarUrl,
  }) async {
    if (!_isInitialized) return;
    if (!Platform.isWindows && !Platform.isMacOS) return;

    // Check if anything changed to avoid unnecessary updates
    final bool stateChanged = _isConnected != isConnected ||
        (displayName != null && _displayName != displayName) ||
        (deviceName != null && _deviceName != deviceName) ||
        (email != null && _email != email) ||
        (avatarUrl != null && _avatarUrl != avatarUrl);

    if (!stateChanged) {
      return; // No changes, skip update
    }
    _logger.d("Updating tray state: isConnected=$isConnected "
        " displayName=$displayName deviceName=$deviceName avatarUrl=$avatarUrl");

    _isConnected = isConnected;
    if (displayName != null) _displayName = displayName;
    if (deviceName != null) _deviceName = deviceName;
    if (email != null) _email = email;

    // Clear cached avatar if URL changed
    if (avatarUrl != null && avatarUrl != _avatarUrl) {
      _avatarUrl = avatarUrl;
      _cachedAvatarPath = null;
    }

    try {
      final iconPath = isConnected ? _iconConnected : _iconDisconnected;
      await _systemTray.setImage(iconPath);

      final tip = tooltip ??
          (isConnected
              ? 'Cylonix - Connected'
              : 'Cylonix - Disconnected. Click to connect.');
      await _systemTray.setToolTip(tip);

      // Update context menu with new state
      await _updateContextMenu();
    } catch (e) {
      _logger.e("Failed to update tray state: $e");
    }
  }

  static Future<void> show() async {
    if (!_isInitialized) return;
    await _appWindow.show();
  }

  static Future<void> hide() async {
    if (!_isInitialized) return;
    await _appWindow.hide();
  }

  static Future<void> destroy() async {
    if (!_isInitialized) return;
    await _systemTray.destroy();
    _isInitialized = false;
  }
}
