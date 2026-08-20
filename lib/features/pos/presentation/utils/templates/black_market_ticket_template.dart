import 'package:punto_venta_app/features/pos/presentation/utils/templates/base_ticket_template.dart';

/// Template para operaciones en NEGRO (sin factura fiscal)
/// Se usa cuando: branch.afip_available = false
/// Formato: precios con IVA incluido, sin desglose de impuestos
class BlackMarketTicketTemplate extends BaseTicketTemplate {
  BlackMarketTicketTemplate({required super.printJob});

  @override
  Future<List<TicketCommand>> build() async {
    final commands = <TicketCommand>[];

    // === ENCABEZADO ===
    commands.addAll(buildHeader(isValidInvoice: false));

    // === INFORMACIÓN DE LA ORDEN ===
    commands.addAll(buildOrderInfo());

    // === ITEMS ===
    // En blackMarket mostramos precios con IVA incluido para simplicidad
    commands.addAll(buildItemsDetailed(showPricesWithTax: false));

    // === TOTALES SIMPLIFICADOS ===
    commands.addAll(buildSimplifiedTotals());

    // === INFORMACIÓN ADICIONAL ===
    commands.addAll(buildAdditionalInfo());

    // // === CÓDIGO QR ===
    // commands.addAll(await buildQrCode());

    // === PIE DE PÁGINA ===
    commands.addAll(buildFooter());

    return commands;
  }
}
