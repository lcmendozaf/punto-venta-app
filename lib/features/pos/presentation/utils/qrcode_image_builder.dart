import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:barcode/barcode.dart';

class QrCodeImageBuilder {
  static Future<Uint8List> buildQrCodeImage({
    required String qrData,
    required List<String> textLines,
    double width = 576,
    double qrSize = 280,
    double qrMargin = 20.0,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Márgenes y espaciados
    const double topBottomMargin = 20.0;
    const double spacing = 15.0;
    final double fontSize = width > 500 ? 16.0 : 14.0;

    final qr = Barcode.qrCode();
    final List<BarcodeElement> rawElements = [];
    try {
      rawElements.addAll(qr.make(qrData, width: 1.0, height: 1.0));
    } catch (e) {
      debugPrint('Error generating QR elements: $e');
    }

    double unitSize = 0.010; // default fallback
    int N = 61; // default fallback
    int M = (qrSize / N).round();
    double actualQrSize = qrSize;

    if (rawElements.isNotEmpty) {
      final firstBar = rawElements.firstWhere((e) => e is BarcodeBar,
          orElse: () => rawElements.first);
      unitSize = firstBar.height;
      N = (1.0 / unitSize).round();

      // Maximizar el tamaño del módulo M según el ancho del papel para evitar distorsiones térmicas
      final double maxAllowedQrSize =
          width - qrMargin; // Margen total en los lados
      M = (maxAllowedQrSize / N).floor();
      if (M < 3) M = 3;
      actualQrSize = (N * M).toDouble();
    }

    // Calcular la altura dinámica: margen superior + QR + espaciado + texto + margen inferior
    final List<TextPainter> textPainters = [];
    double totalTextHeight = 0.0;

    for (final line in textLines) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: line,
          style: TextStyle(
            color: Colors.black,
            fontSize: fontSize,
            fontFamily: 'monospace',
            fontWeight: FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: width - 20.0);
      textPainters.add(textPainter);
      totalTextHeight += textPainter.height + 6.0;
    }

    final double height = topBottomMargin +
        actualQrSize +
        spacing +
        totalTextHeight +
        topBottomMargin;

    // Fondo blanco
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );

    // 1. Dibujar QR Code Centrado horizontalmente en la parte superior
    final double qrX = (width - actualQrSize) / 2.0;
    const double qrY = topBottomMargin;

    try {
      final paint = Paint()
        ..color = Colors.black
        ..isAntiAlias =
            false; // Desactivar anti-alias para bordes 100% nítidos en impresión térmica

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

    // 2. Dibujar líneas de texto centradas debajo del QR
    double currentY = qrY + actualQrSize + spacing;

    for (final textPainter in textPainters) {
      final double textX = (width - textPainter.width) / 2.0;
      textPainter.paint(canvas, Offset(textX, currentY));
      currentY += textPainter.height + 6.0; // 6px de espacio entre líneas
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());

    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = pngBytes!.buffer.asUint8List();

    try {
      final file = File('/Users/brayan/Desktop/last_qr_code.png');
      await file.writeAsBytes(uint8List);
      debugPrint('QR image saved locally to macOS Desktop: ${file.path}');
    } catch (e) {
      debugPrint(
          'Could not save to Desktop, saving to application documents directory: $e');
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/last_qr_code.png');
        await file.writeAsBytes(uint8List);
        debugPrint('QR image saved locally to: ${file.path}');
      } catch (innerE) {
        debugPrint('Error saving QR image locally: $innerE');
      }
    }

    return uint8List;
  }
}
