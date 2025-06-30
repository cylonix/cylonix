import 'dart:io';
import 'package:flutter/foundation.dart';

@immutable
class SharedFile {
  final String path;
  final String name;
  final int size;

  const SharedFile({
    required this.path,
    required this.name,
    required this.size,
  });

  factory SharedFile.fromPath(String path) {
    final file = File(path);
    return SharedFile(
      path: path,
      name: file.uri.pathSegments.last,
      size: file.lengthSync(),
    );
  }
}

class ShareFileEvent {
  final String args;

  ShareFileEvent(this.args);

  @override
  String toString() {
    return 'ShareFileEvent(args: $args)';
  }
}
