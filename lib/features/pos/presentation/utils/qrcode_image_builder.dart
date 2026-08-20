import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:barcode/barcode.dart';

class QrCodeImageBuilder {
  static Future<Uint8List> buildQrCodeImage({
    required String qrData,
    required List<String> textLines,
    double width = 576,
    double qrSize = 330,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Margenes compactos para permitir un QR de mayor tamaño
    const double leftMargin = 5.0;
    const double topBottomMargin = 10.0;
    const double spacing = 15.0;

    final qr = Barcode.qrCode();
    final List<BarcodeElement> rawElements = [];
    try {
      rawElements.addAll(qr.make(qrData, width: 1.0, height: 1.0));
    } catch (e) {
      debugPrint('Error generating QR elements: $e');
    }

    double unitSize = 0.016; // default fallback
    int N = 61; // default fallback
    int M = (qrSize / N).round();
    double actualQrSize = qrSize;

    if (rawElements.isNotEmpty) {
      final firstBar = rawElements.firstWhere((e) => e is BarcodeBar, orElse: () => rawElements.first);
      unitSize = firstBar.height;
      N = (1.0 / unitSize).round();
      M = (qrSize / N).round();
      if (M < 1) M = 1;
      actualQrSize = (N * M).toDouble();
    }

    final double height = actualQrSize + (topBottomMargin * 2);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );

    // 1. Dibujar QR Code en el lado izquierdo
    final double qrX = leftMargin;
    final double qrY = topBottomMargin;

    try {
      final paint = Paint()
        ..color = Colors.black
        ..isAntiAlias = false; // Desactivar anti-alias para bordes 100% nítidos en impresión térmica

      for (var element in rawElements) {
        if (element is BarcodeBar && element.black) {
          final row = (element.top / unitSize).round();
          final col = (element.left / unitSize).round();
          final colWidth = (element.width / unitSize).round();

          canvas.drawRect(
            Rect.fromLTWH(
              qrX + (col * M),
              qrY + (row * M),
              (colWidth * M).toDouble(),
              M.toDouble(),
            ),
            paint,
          );
        }
      }
    } catch (e) {
      debugPrint('Error al dibujar código QR: $e');
    }

    // 2. Dibujar texto en el lado derecho
    final double textX = qrX + actualQrSize + spacing;
    double currentY = topBottomMargin + 5;

    for (final line in textLines) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: line,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'monospace',
            fontWeight: FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: width - textX - 10);
      textPainter.paint(canvas, Offset(textX, currentY));
      currentY += textPainter.height + 6; // 6px de espacio entre líneas
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());

    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pngBytes!.buffer.asUint8List();
  }
}
