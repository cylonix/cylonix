class WebAuthCanceledException implements Exception {
  final String message;
  WebAuthCanceledException(
      [this.message = "Web authentication was canceled by the user."]);

  @override
  String toString() => "WebAuthCanceledException: $message";
}
