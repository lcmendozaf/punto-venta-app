import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/entities/printer_config.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/templates/base_ticket_template.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/ticket_template_builder.dart';
import 'package:image/image.dart' as img_lib;

const int maxImageWidth = 8 * 52; //576 = 8*72;

abstract class PrinterSocketDatasource {
  Future<bool> connect(PrinterConfig config);
  Future<bool> disconnect();
  Future<bool> printTicket(PrintJob printJob);
  Future<bool> printCommands(List<TicketCommand> commands);
  Future<bool> isConnected();
}

class PrinterSocketDatasourceImpl implements PrinterSocketDatasource {
  /// Cambia el tamaño del texto ESC/POS (1-8x)
  Future<bool> _setTextSize({int width = 1, int height = 1}) async {
    // width y height: 1 a 8
    int n = ((width - 1) << 4) | (height - 1);
    return await _sendData(Uint8List.fromList([0x1D, 0x21, n]));
  }

  Socket? _socket;
  bool _isConnected = false;

  // 58mm = 32 caracteres, 80mm = 48 caracteres
  static const int _lineWidth = 48;

  @override
  Future<bool> connect(PrinterConfig config) async {
    try {
      _socket = await Socket.connect(config.ip, config.port)
          .timeout(Duration(milliseconds: config.timeout));
      _isConnected = true;

      await _initPrinter();

      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  @override
  Future<bool> disconnect() async {
    try {
      await _socket?.close();
      _socket = null;
      _isConnected = false;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isConnected() async {
    return _isConnected && _socket != null;
  }

  @override
  Future<bool> printTicket(PrintJob printJob) async {
    if (!_isConnected || _socket == null) return false;

    try {
      // Generar los comandos del ticket usando el template
      final templateBuilder = TicketTemplateBuilder(
        printJob: printJob,
      );
      final commands = await templateBuilder.build();

      // Ejecutar cada comando
      for (final command in commands) {
        await _executeCommand(command);
      }

      return true;
    } catch (e) {
      print('❌ Error al imprimir: $e');
      return false;
    }
  }

  @override
  Future<bool> printCommands(List<TicketCommand> commands) async {
    if (!_isConnected || _socket == null) return false;

    try {
      for (final command in commands) {
        await _executeCommand(command);
      }
      return true;
    } catch (e) {
      print('❌ Error al imprimir comandos: $e');
      return false;
    }
  }

  /// Ejecuta un comando individual del ticket
  Future<void> _executeCommand(TicketCommand command) async {
    switch (command.type) {
      case TicketCommandType.image:
        PrintImageData printImageData = command.value as PrintImageData;
        await _printImage(printImageData.bytes,
            maxImageWidth: printImageData.imageSize);
        break;
      case TicketCommandType.textSize:
        final data = command.value as Map<String, dynamic>;
        await _setTextSize(
            width: data['width'] as int, height: data['height'] as int);
        break;
      case TicketCommandType.text:
        await _printText(command.value as String);
        break;
      case TicketCommandType.feedLine:
        await _printAndFeedLine();
        break;
      case TicketCommandType.alignment:
        final align = command.value as TicketAlignment;
        await _selectAlignment(align == TicketAlignment.left
            ? 0
            : align == TicketAlignment.center
                ? 1
                : 2);
        break;
      case TicketCommandType.bold:
        await _setBold(command.value as bool);
        break;
      case TicketCommandType.doubleHeight:
        await _setDoubleHeight(command.value as bool);
        break;
      case TicketCommandType.doubleWidth:
        await _setDoubleWidth(command.value as bool);
        break;
      case TicketCommandType.barcode:
        await _printBarcode(69, command.value as String);
        break;
      case TicketCommandType.barcodeWithType:
        final barcodeData = command.value as Map<String, dynamic>;
        await _printBarcode(
            barcodeData['type'] as int, barcodeData['code'] as String);
        break;
      case TicketCommandType.setBarcodeHeight:
        await _setBarcodeHeight(command.value as int);
        break;
      case TicketCommandType.setBarcodeWidth:
        await _setBarcodeWidth(command.value as int);
        break;
      case TicketCommandType.setBarcodeHRIPosition:
        await _selectHRICharacterPrintPosition(command.value as int);
        break;
      case TicketCommandType.cutPaper:
        await _selectCutPaperModeAndCutPaper(66, 1);
        break;
      case TicketCommandType.lineWithValue:
        final data = command.value as Map<String, String>;
        await _printLineWithValue(data['label']!, data['value']!);
        break;
    }
  }

  // === MÉTODOS AUXILIARES ===

  Future<void> _printImage(Uint8List imageBytes,
      {int maxImageWidth = maxImageWidth}) async {
    final decodedImage = img_lib.decodeImage(imageBytes);
    if (decodedImage == null) return;

    // Redimensionar si es necesario (ej. máximo ancho de la impresora)
    // Para 80mm suele ser 576 puntos
    img_lib.Image image = decodedImage;
    if (image.width > maxImageWidth) {
      image = img_lib.copyResize(image, width: maxImageWidth);
    }

    final width = image.width;
    final height = image.height;

    // El ancho debe ser múltiplo de 8 para el comando GS v 0
    final widthBytes = (width + 7) ~/ 8;

    final xL = widthBytes % 256;
    final xH = widthBytes ~/ 256;
    final yL = height % 256;
    final yH = height ~/ 256;

    // GS v 0 m xL xH yL yH d1...dk
    final header = Uint8List.fromList([0x1D, 0x76, 0x30, 0x00, xL, xH, yL, yH]);

    final pixels = Uint8List(widthBytes * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        // Calculamos luminancia básica: 0.299R + 0.587G + 0.114B
        // En image 4.x, pixel.r, pixel.g, pixel.b son accesibles
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        final luminance = (0.299 * r + 0.587 * g + 0.114 * b);

        if (luminance < 128) {
          final byteIndex = (y * widthBytes) + (x ~/ 8);
          final bitIndex = 7 - (x % 8);
          pixels[byteIndex] |= (1 << bitIndex);
        }
      }
    }

    await _sendData(header);
    await _sendData(pixels);
  }

  Future<void> _printLineWithValue(String label, String value) async {
    final totalSpaces = _lineWidth - label.length - value.length;
    final spacer = totalSpaces > 0 ? ' ' * totalSpaces : ' ';
    await _printText("$label$spacer$value");
    await _printAndFeedLine();
  }

  Future<bool> _initPrinter() async {
    try {
      await _sendData(Uint8List.fromList([0x1B, 0x40]));

      await _selectHRICharacterPrintPosition(2);
      await _setBarcodeWidth(3);
      await _setBarcodeHeight(162);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _sendData(Uint8List data) async {
    try {
      _socket?.add(data);
      await _socket?.flush();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _printText(String text) async {
    try {
      final data = utf8.encode(text);
      return await _sendData(Uint8List.fromList(data));
    } catch (e) {
      return false;
    }
  }

  Future<bool> _printAndFeedLine() async {
    return await _sendData(Uint8List.fromList([0x0A]));
  }

  Future<bool> _selectAlignment(int alignment) async {
    // 0 = Izquierda, 1 = Centro, 2 = Derecha
    return await _sendData(Uint8List.fromList([0x1B, 0x61, alignment]));
  }

  Future<bool> _setBold(bool enable) async {
    return await _sendData(Uint8List.fromList([0x1B, 0x45, enable ? 1 : 0]));
  }

  Future<bool> _setDoubleHeight(bool enable) async {
    return await _sendData(
        Uint8List.fromList([0x1B, 0x21, enable ? 0x10 : 0x00]));
  }

  Future<bool> _setDoubleWidth(bool enable) async {
    return await _sendData(
        Uint8List.fromList([0x1B, 0x21, enable ? 0x20 : 0x00]));
  }

  Future<bool> _setBarcodeWidth(int width) async {
    return await _sendData(Uint8List.fromList([0x1D, 0x77, width]));
  }

  Future<bool> _setBarcodeHeight(int height) async {
    return await _sendData(Uint8List.fromList([0x1D, 0x68, height]));
  }

  Future<bool> _selectHRICharacterPrintPosition(int code) async {
    return await _sendData(Uint8List.fromList([0x1D, 0x48, code]));
  }

  Future<bool> _printBarcode(int codeType, String codeToPrint) async {
    try {
      await _sendData(
          Uint8List.fromList([0x1D, 0x6B, codeType, codeToPrint.length]));
      return await _printText(codeToPrint);
    } catch (e) {
      return false;
    }
  }

  Future<bool> _selectCutPaperModeAndCutPaper(int m, int n) async {
    return await _sendData(Uint8List.fromList([0x1D, 0x56, m, n]));
  }
}
