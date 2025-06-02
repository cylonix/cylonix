import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'utils/logger.dart';

void main() async {
  await _loadEnv();
  runApp(
    const ProviderScope(child: App()),
  );
}

/// Load env setting.
Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: ".env.local", isOptional: true);
  } catch (e) {
    Logger(tag: "Main").e("Failed to load the optional env file: $e");
  }
}
