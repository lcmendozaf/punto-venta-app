import 'dart:typed_data';

import 'package:punto_venta_app/core/constants/ticket_template_types.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/core/utils/utils.dart' as utils;
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/qrcode_image_builder.dart';

/// Clase base
abstract class BaseTicketTemplate {
  static const int lineWidth = 48;

  final PrintJob printJob;

  BaseTicketTemplate({required this.printJob});

  /// Método principal que construye el ticket completo
  Future<List<TicketCommand>> build();

  // === MÉTODOS COMUNES PARA TODOS LOS TEMPLATES ===

  /// Construye el encabezado del ticket
  /// Si isValidInvoice=true e incluye datos fiscales, muestra información fiscal completa
  List<TicketCommand> buildHeader({bool isValidInvoice = false}) {
    final commands = <TicketCommand>[];

    commands.add(TicketCommand.alignment(TicketAlignment.center));

    // Si es factura válida y tenemos datos fiscales, mostrar encabezado fiscal
    if (isValidInvoice && printJob.fiscalIssuerData != null) {
      final fiscalData = printJob.fiscalIssuerData!;

      // Nombre fiscal
      if (fiscalData.fiscalName != null) {
        commands.add(TicketCommand.bold(true));
        commands.add(TicketCommand.text(fiscalData.fiscalName!));
        commands.add(TicketCommand.bold(false));
        commands.add(TicketCommand.feedLine());
      }

      // CUIT
      if (fiscalData.cuit != null) {
        commands.add(TicketCommand.text("C.U.I.T. Nro.: ${fiscalData.cuit!}"));
        commands.add(TicketCommand.feedLine());
      }

      // Ingresos Brutos
      if (fiscalData.iibbCuit != null) {
        commands
            .add(TicketCommand.text("Ing. Brutos: ${fiscalData.iibbCuit!}"));
        commands.add(TicketCommand.feedLine());
      }

      // Dirección
      if (fiscalData.address != null) {
        commands.add(TicketCommand.text("Domicilio: ${fiscalData.address!}"));
        commands.add(TicketCommand.feedLine());
      }

      // Código Postal
      if (fiscalData.postalCode != null) {
        commands.add(TicketCommand.text(fiscalData.postalCode!));
        commands.add(TicketCommand.feedLine());
      }

      // Inicio de actividades
      if (fiscalData.activityStartDate != null) {
        commands.add(TicketCommand.text(
            "Inicio de Actividades: ${fiscalData.activityStartDate!}"));
        commands.add(TicketCommand.feedLine());
      }

      // Condición IVA
      if (fiscalData.vatCondition != null) {
        commands.add(TicketCommand.text(fiscalData.vatCondition!));
        commands.add(TicketCommand.feedLine());
      }

      // Separador
      commands.add(TicketCommand.feedLine());
      commands.add(TicketCommand.text(buildSeparator('=')));
      commands.add(TicketCommand.feedLine());

      // Documento válido como factura o COPIA
      commands.add(TicketCommand.bold(true));
      if (printJob.isCreditNote) {
        if (printJob.isCopy) {
          commands.add(TicketCommand.text("COPIA"));
          commands.add(TicketCommand.feedLine());
        }
        commands.add(TicketCommand.text("NOTA DE CREDITO"));
      } else {
        if (printJob.isCopy) {
          commands.add(TicketCommand.text("COPIA"));
          commands.add(TicketCommand.feedLine());
          commands.add(TicketCommand.text("NO VALIDA COMO FACTURA"));
        } else {
          commands.add(TicketCommand.text("DOCUMENTO VALIDO COMO FACTURA"));
        }
      }
      commands.add(TicketCommand.bold(false));
      commands.add(TicketCommand.feedLine());
      commands.add(TicketCommand.text(buildSeparator('=')));
    } else {
      // Encabezado simple (para templates standard y blackMarket)
      commands.add(TicketCommand.bold(true));
      commands.add(TicketCommand.text("${printJob.enterprise?.name}"));
      commands.add(TicketCommand.bold(false));
      commands.add(TicketCommand.feedLine());

      if (!isValidInvoice) {
        // Para operaciones en negro (blackMarket), mostrar mensaje más prominente
        commands.add(TicketCommand.feedLine());
        commands.add(TicketCommand.text(buildSeparator('=')));
        commands.add(TicketCommand.feedLine());
        commands.add(TicketCommand.bold(true));
        if (printJob.isCreditNote) {
          commands.add(TicketCommand.text("NOTA DE CREDITO"));
        } else {
          commands.add(TicketCommand.text("DOCUMENTO NO VALIDO"));
          commands.add(TicketCommand.feedLine());
          commands.add(TicketCommand.text("COMO FACTURA"));
        }
        commands.add(TicketCommand.bold(false));
        commands.add(TicketCommand.feedLine());
        commands.add(TicketCommand.text(buildSeparator('=')));
      } else {
        // Para factura En blanco sin datos fiscales detallados
        commands.add(TicketCommand.text("Sistema de Punto de Venta"));
        //// COPIA
        if (printJob.isCopy) {
          // Separador
          commands.add(TicketCommand.feedLine());
          commands.add(TicketCommand.text(buildSeparator('=')));
          commands.add(TicketCommand.feedLine());

          // Documento válido como factura o COPIA
          commands.add(TicketCommand.bold(true));
          if (printJob.isCreditNote) {
            commands.add(TicketCommand.text("COPIA"));
            commands.add(TicketCommand.feedLine());
            commands.add(TicketCommand.text("NOTA DE CREDITO"));
          } else {
            commands.add(TicketCommand.text("COPIA"));
            commands.add(TicketCommand.feedLine());
            commands.add(TicketCommand.text("NO VALIDA COMO FACTURA"));
          }
          commands.add(TicketCommand.bold(false));
          commands.add(TicketCommand.feedLine());
          commands.add(TicketCommand.text(buildSeparator('=')));
        }
        commands.add(TicketCommand.feedLine());
        commands.add(
            TicketCommand.text(printJob.isCreditNote ? "Nota de Credito" : ""));
        commands.add(TicketCommand.feedLine());
        commands.add(TicketCommand.feedLine());
        commands.add(TicketCommand.text(buildSeparator('_')));
      }
    }

    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.feedLine());

    return commands;
  }

  /// Construye la información de la orden
  List<TicketCommand> buildOrderInfo() {
    final commands = <TicketCommand>[
      TicketCommand.alignment(TicketAlignment.left),
      TicketCommand.text("${printJob.description}"),
      TicketCommand.feedLine(),
    ];

    // // Mostrar descripción solo para tickets en blanco (whiteMarket)
    // if (printJob.templateType == TicketTemplateType.whiteMarket &&
    //     printJob.description != null &&
    //     printJob.description!.isNotEmpty) {
    //   commands.add(TicketCommand.text(printJob.description!));
    //   commands.add(TicketCommand.feedLine());
    // }

    commands.addAll([
      TicketCommand.lineWithValue("Fecha: ${formatDate(printJob.timestamp)}",
          "Hora: ${formatTime(printJob.timestamp)}"),
      TicketCommand.text("Cajero: ${printJob.cashierName}"),
      TicketCommand.feedLine(),
    ]);

    if (printJob.clientName != null && printJob.clientName!.isNotEmpty) {
      commands.add(TicketCommand.text("Cliente: ${printJob.clientName}"));
      commands.add(TicketCommand.feedLine());

      // Mostrar documento del cliente si está disponible
      if (printJob.client != null) {
        String? documentLabel;
        String? documentValue;

        // Priorizar CUIT, luego DNI, luego document
        if (printJob.client!.cuit != null &&
            printJob.client!.cuit!.isNotEmpty) {
          documentLabel = "CUIT";
          documentValue = printJob.client!.cuit;
        } else if (printJob.client!.dni != null &&
            printJob.client!.dni!.isNotEmpty) {
          documentLabel = "DNI";
          documentValue = printJob.client!.dni;
        } else if (printJob.client!.document != null &&
            printJob.client!.document!.isNotEmpty) {
          documentLabel = "Doc";
          documentValue = printJob.client!.document;
        }

        if (documentLabel != null && documentValue != null) {
          commands.add(TicketCommand.text("$documentLabel: $documentValue"));
          commands.add(TicketCommand.feedLine());
        }
      }
    }

    commands.add(TicketCommand.text(buildSeparator('_')));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.feedLine());

    return commands;
  }

  /// Construye la sección de ítems con control sobre mostrar precios con o sin IVA
  List<TicketCommand> buildItemsDetailed({required bool showPricesWithTax}) {
    final commands = <TicketCommand>[];

    for (var item in printJob.items) {
      final productName = item.product.name.length > lineWidth - 2
          ? item.product.name.substring(0, lineWidth - 5) + "..."
          : item.product.name;

      commands.add(TicketCommand.text(productName));
      commands.add(TicketCommand.feedLine());

      final basePrice = item.product.price ?? 0;

      if (item.isWeighted == true) {
        final weightKg = item.weightKg ?? 0.0;
        final unitPrice = getDisplayUnitPrice(item, basePrice,
            showPricesWithTax: showPricesWithTax);
        final subtotalValue = (weightKg * unitPrice).formatToCurrency();
        final line =
            "  ${weightKg.toStringAsFixed(3)} kg x ${unitPrice.formatToCurrency()}";

        final totalSpaces = lineWidth - line.length - subtotalValue.length;
        final spacer = totalSpaces > 0 ? ' ' * totalSpaces : ' ';

        commands.add(TicketCommand.text("$line$spacer$subtotalValue"));
        commands.add(TicketCommand.feedLine());
      } else {
        // no es peso

        //precio a mostrar
        final displayPrice = getDisplayUnitPrice(item, basePrice,
            showPricesWithTax: showPricesWithTax);

        final unitPrice = displayPrice.formatToCurrency();
        final subtotalValue = (item.quantity * displayPrice).formatToCurrency();

        final line = "  ${item.quantity} x $unitPrice";

        final totalSpaces = lineWidth - line.length - subtotalValue.length;
        final spacer = totalSpaces > 0 ? ' ' * totalSpaces : ' ';

        commands.add(TicketCommand.text("$line$spacer$subtotalValue"));
        commands.add(TicketCommand.feedLine());
      }
    }

    commands.add(TicketCommand.text(buildSeparator('-')));
    commands.add(TicketCommand.feedLine());

    return commands;
  }

  /// Construye totales con desglose completo de impuestos
  List<TicketCommand> buildDetailedTotals() {
    final commands = <TicketCommand>[];

    // Calcular subtotal restando todos los impuestos
    final subtotalAmount = (printJob.total -
            printJob.totalTax -
            printJob.iibbTax -
            printJob.vatPerception -
            printJob.internalTax)
        .formatToCurrency();

    if (printJob.showSubtotalAndTax == true) {
      commands.add(TicketCommand.lineWithValue("Subtotal:", subtotalAmount));
    }

    // Percepción IIBB si es mayor a 0
    if (printJob.iibbTax > 0) {
      final iibbAmount = printJob.iibbTax.formatToCurrency();
      final iibbLabel = "Percep. IIBB:";
      commands.add(TicketCommand.lineWithValue(iibbLabel, iibbAmount));
    }

    // Percepción IVA si es mayor a 0
    if (printJob.vatPerception > 0) {
      final vatPercepAmount = printJob.vatPerception.formatToCurrency();
      commands
          .add(TicketCommand.lineWithValue("Percep. IVA:", vatPercepAmount));
    }

    // Impuesto Interno si es mayor a 0
    if (printJob.internalTax > 0) {
      final internalTaxAmount = printJob.internalTax.formatToCurrency();
      final internalTaxLabel = "Imp. Interno:";
      commands.add(
          TicketCommand.lineWithValue(internalTaxLabel, internalTaxAmount));
    }

    commands.add(TicketCommand.text(buildSeparator('_')));
    commands.add(TicketCommand.feedLine());

    if (printJob.receivedAmount != null && printJob.change != null) {
      final receivedAmount = printJob.receivedAmount!.formatToCurrency();
      final changeAmount = printJob.change!.formatToCurrency();

      commands.add(TicketCommand.feedLine());
      commands.add(TicketCommand.lineWithValue("Recibido:", receivedAmount));
      commands.add(TicketCommand.lineWithValue("Cambio:", changeAmount));
    }

    // Total siempre se muestra
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.bold(true));
    commands.add(TicketCommand.doubleHeight(true));
    commands.add(TicketCommand.lineWithValue(
        "TOTAL:", printJob.total.formatToCurrency()));
    commands.add(TicketCommand.doubleHeight(false));
    commands.add(TicketCommand.bold(false));
    commands.add(TicketCommand.text(buildSeparator('_')));
    commands.add(TicketCommand.feedLine());

    // Siempre mostrar IVA aunque sea 0
    final taxAmount = printJob.totalTax.formatToCurrency();
    commands.add(TicketCommand.feedLine());
    commands.add(
        TicketCommand.text("Regimen de transparencia fiscal al consumidor"));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.text("(LEY 22743)"));
    commands.add(TicketCommand.feedLine());

    commands.add(TicketCommand.lineWithValue("IVA CONTENIDO:", taxAmount));

    return commands;
  }

  /// Construye totales simplificados sin desglose de impuestos
  List<TicketCommand> buildSimplifiedTotals() {
    final commands = <TicketCommand>[];

    if (printJob.receivedAmount != null && printJob.change != null) {
      final receivedAmount = printJob.receivedAmount!.formatToCurrency();
      final changeAmount = printJob.change!.formatToCurrency();

      commands.add(TicketCommand.lineWithValue("Recibido:", receivedAmount));
      commands.add(TicketCommand.lineWithValue("Cambio:", changeAmount));
      commands.add(TicketCommand.feedLine());
    }

    // Total destacado
    commands.add(TicketCommand.bold(true));
    commands.add(TicketCommand.doubleHeight(true));
    commands.add(TicketCommand.lineWithValue(
        "TOTAL:", printJob.total.formatToCurrency()));
    commands.add(TicketCommand.doubleHeight(false));
    commands.add(TicketCommand.bold(false));
    commands.add(TicketCommand.text(buildSeparator('_')));
    commands.add(TicketCommand.feedLine());

    if (printJob.templateType == TicketTemplateType.whiteMarket) {
      // Siempre mostrar IVA aunque sea 0
      final taxAmount = printJob.totalTax.formatToCurrency();
      commands.add(TicketCommand.feedLine());
      commands.add(
          TicketCommand.text("Regimen de transparencia fiscal al consumidor"));
      commands.add(TicketCommand.feedLine());
      commands.add(TicketCommand.text("(LEY 22743)"));
      commands.add(TicketCommand.feedLine());

      commands.add(TicketCommand.lineWithValue("IVA CONTENIDO:", taxAmount));
    }

    return commands;
  }

  /// Construye la información adicional del ticket
  List<TicketCommand> buildAdditionalInfo() {
    final totalItems =
        printJob.items.fold(0, (sum, item) => sum + item.quantity);

    final commands = <TicketCommand>[
      TicketCommand.feedLine(),
    ];

    if (!printJob.isCreditNote) {
      if (printJob.paymentMethods != null &&
          printJob.paymentMethods!.isNotEmpty) {
        commands.add(TicketCommand.text("Metodos de pago:"));
        commands.add(TicketCommand.feedLine());
        for (final pm in printJob.paymentMethods!) {
          final amountStr = pm.amount!.formatToCurrency();
          commands.add(TicketCommand.text("  - ${pm.description}: $amountStr"));
          commands.add(TicketCommand.feedLine());
        }
      } else {
        commands.add(TicketCommand.text(
            "Metodo de pago: ${printJob.paymentMethod?.description ?? 'Efectivo'}"));
        commands.add(TicketCommand.feedLine());
      }
    }

    commands.addAll([
      TicketCommand.text("Total de articulos: $totalItems"),
      TicketCommand.feedLine(),
      TicketCommand.feedLine(),
    ]);
    return commands;
  }

  /// Construye el código de barras
  List<TicketCommand> buildBarcode() {
    final barcodeValue = printJob.ticketId?.padLeft(8, '0') ?? '00000000';

    return [
      TicketCommand.alignment(TicketAlignment.center),
      TicketCommand.barcode(barcodeValue),
      TicketCommand.feedLine(),
      TicketCommand.feedLine(),
    ];
  }

  /// Construye Imagen de codigo qr
  Future<List<TicketCommand>> buildQrCode() async {
    try {
      final qrUrl = printJob.caeQrCode ?? printJob.cae;

      final List<String> textLines = [];

      if (printJob.cae != null && printJob.cae!.isNotEmpty) {
        textLines.add("CAE: ${printJob.cae}");
      }
      if (printJob.caeDueDate != null && printJob.caeDueDate!.isNotEmpty) {
        textLines.add(
            "Vto. CAE: ${utils.formatDate(printJob.caeDueDate!, fromDateFormat: 'yyyy-MM-dd', toDateFormat: 'dd/MM/yyyy')}");
      }

      if (printJob.templateType == TicketTemplateType.whiteMarket) {
        textLines.add("Orientacion al Consumidor ");
        textLines.add("Provincia de Buenos Aires ");
        textLines.add("0800-222-9042 (Ley 13133) ");
      }

      final qrImageBytes = await QrCodeImageBuilder.buildQrCodeImage(
        qrData: qrUrl ?? '',
        textLines: textLines,
        width: 416,
        qrSize: 250,
      );

      return [
        TicketCommand.alignment(TicketAlignment.center),
        TicketCommand.image(qrImageBytes, 416),
        TicketCommand.feedLine(),
      ];
    } catch (e) {
      print('❌ Error al generar imagen de código QR: $e');
      return [
        TicketCommand.alignment(TicketAlignment.center),
        TicketCommand.text("CAE: ${printJob.cae ?? 'N/A'}"),
        TicketCommand.feedLine(),
        TicketCommand.text("Vto. CAE: ${printJob.caeDueDate ?? 'N/A'}"),
        TicketCommand.feedLine(),
      ];
    }
  }

  /// Construye el pie de página
  List<TicketCommand> buildFooter() {
    return [
      TicketCommand.text("Gracias por su compra!"),
      TicketCommand.feedLine(),
      TicketCommand.feedLine(),
      TicketCommand.feedLine(),
      TicketCommand.cutPaper(),
    ];
  }

  // === UTILIDADES ===

  String buildSeparator(String char) {
    return char * lineWidth;
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
  }

  double calculatePriceWithTax(double price, double? taxPercentage) {
    final tax = (taxPercentage ?? 0.0) / 100;
    return price * (1 + tax);
  }

  double getDisplayUnitPrice(dynamic item, double basePrice,
      {required bool showPricesWithTax}) {
    // si showPricesWithTax es false, mostramos el precio con impuestos
    // si showPricesWithTax es true, mostramos el precio sin impuestos

    if (showPricesWithTax) {
      return basePrice;
    }

    double priceWithTax = calculatePriceWithTax(basePrice, item.product.vat);

    if (item.product.internalTax > 0) {
      final fractional = item.product.fractional ?? 1;
      priceWithTax += item.product.internalTax * fractional;
    }
    return priceWithTax;
  }
}

// === COMANDOS DEL TICKET ===

enum TicketAlignment { left, center, right }

class PrintImageData {
  Uint8List bytes;
  int imageSize;
  PrintImageData(this.bytes, this.imageSize);
}

class TicketCommand {
  factory TicketCommand.textSize({int width = 1, int height = 1}) =>
      TicketCommand._(
          TicketCommandType.textSize, {'width': width, 'height': height});
  final TicketCommandType type;
  final dynamic value;

  TicketCommand._(this.type, [this.value]);

  factory TicketCommand.image(Uint8List bytes, int imageSize) =>
      TicketCommand._(
          TicketCommandType.image, PrintImageData(bytes, imageSize));

  factory TicketCommand.text(String text) =>
      TicketCommand._(TicketCommandType.text, text);
  factory TicketCommand.feedLine() =>
      TicketCommand._(TicketCommandType.feedLine);
  factory TicketCommand.alignment(TicketAlignment align) =>
      TicketCommand._(TicketCommandType.alignment, align);
  factory TicketCommand.bold(bool enable) =>
      TicketCommand._(TicketCommandType.bold, enable);
  factory TicketCommand.doubleHeight(bool enable) =>
      TicketCommand._(TicketCommandType.doubleHeight, enable);
  factory TicketCommand.doubleWidth(bool enable) =>
      TicketCommand._(TicketCommandType.doubleWidth, enable);
  factory TicketCommand.barcode(String code) =>
      TicketCommand._(TicketCommandType.barcode, code);
  factory TicketCommand.barcodeWithType(String code, int barcodeType) =>
      TicketCommand._(TicketCommandType.barcodeWithType,
          {'code': code, 'type': barcodeType});
  factory TicketCommand.setBarcodeHeight(int height) =>
      TicketCommand._(TicketCommandType.setBarcodeHeight, height);
  factory TicketCommand.setBarcodeWidth(int width) =>
      TicketCommand._(TicketCommandType.setBarcodeWidth, width);
  factory TicketCommand.setBarcodeHRIPosition(int position) =>
      TicketCommand._(TicketCommandType.setBarcodeHRIPosition, position);
  factory TicketCommand.cutPaper() =>
      TicketCommand._(TicketCommandType.cutPaper);
  factory TicketCommand.lineWithValue(String label, String value) =>
      TicketCommand._(
          TicketCommandType.lineWithValue, {'label': label, 'value': value});
}

enum TicketCommandType {
  image,
  textSize,
  text,
  feedLine,
  alignment,
  bold,
  doubleHeight,
  doubleWidth,
  barcode,
  barcodeWithType,
  setBarcodeHeight,
  setBarcodeWidth,
  setBarcodeHRIPosition,
  cutPaper,
  lineWithValue,
}
