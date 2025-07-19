// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart' as qrf;

class QrCodeImage extends StatelessWidget {
  final String data;
  final Color backgroundColor;
  final Color qrBackgroundColor;
  final ImageProvider? image;
  final double qrImageSize;
  final double? height;
  const QrCodeImage(
    this.data, {
    super.key,
    this.backgroundColor = Colors.transparent,
    this.qrBackgroundColor = Colors.white,
    this.image,
    this.qrImageSize = 300,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? qrImageSize,
      width: qrImageSize,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: qrf.QrImageView(
        size: qrImageSize,
        data: data,
        embeddedImage: image,
        embeddedImageStyle: image != null
            ? const qrf.QrEmbeddedImageStyle(size: Size(48, 48))
            : null,
        backgroundColor: qrBackgroundColor,
      ),
    );
  }
}
