extension FileNameDateTime on DateTime {
  /// Replace '-, :, .' to '_' for filename usage.
  String toFilenameString() {
    var s = toIso8601String();
    return s.replaceAll(RegExp(r'[-:\\.]'), '_');
  }
}
