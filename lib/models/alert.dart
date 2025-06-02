import 'package:flutter/material.dart';

enum AlertVariant {
  success,
  error,
  warning,
  info,
}

class Alert {
  final AlertVariant variant;
  final String text;
  const Alert(this.text, {this.variant = AlertVariant.error});
  Color? get color {
    switch (variant) {
      case (AlertVariant.success):
        return Colors.green;
      case (AlertVariant.error):
        return Colors.red;
      case (AlertVariant.warning):
        return Colors.yellow;
      default:
        return null;
    }
  }
}
