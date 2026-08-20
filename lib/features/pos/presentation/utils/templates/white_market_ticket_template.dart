import 'package:punto_venta_app/features/pos/presentation/utils/templates/base_ticket_template.dart';

/// Template para operaciones en BLANCO (con factura fiscal)
/// Se usa cuando: branch.afip_available = true
/// - Si client.vat_category.tax_details = true: muestra desglose completo, precios sin IVA
/// - Si client.vat_category.tax_details = false: sin desglose, precios con IVA
class WhiteMarketTicketTemplate extends BaseTicketTemplate {
  WhiteMarketTicketTemplate({required super.printJob});

  @override
  Future<List<TicketCommand>> build() async {
    final commands = <TicketCommand>[];

    // === ENCABEZADO ===
    commands.addAll(buildHeader(isValidInvoice: true));

    // === INFORMACIÓN DE LA ORDEN ===
    commands.addAll(buildOrderInfo());

    // === ITEMS ===
    // Precios según showPricesWithTax (controlado por tax_details)
    commands.addAll(
        buildItemsDetailed(showPricesWithTax: printJob.showPricesWithTax));

    // === TOTALES ===
    // Si showSubtotalAndTax=true (tax_details=true) → desglose completo
    // Si showSubtotalAndTax=false (tax_details=false) → sin desglose
    if (printJob.showSubtotalAndTax) {
      commands.addAll(buildDetailedTotals());
    } else {
      commands.addAll(buildSimplifiedTotals());
    }

    // === INFORMACIÓN ADICIONAL ===
    commands.addAll(buildAdditionalInfo());

    // === CÓDIGO QR ===
    commands.addAll(await buildQrCode());

    // === PIE DE PÁGINA ===
    commands.addAll(buildFooter());

    return commands;
  }
}
