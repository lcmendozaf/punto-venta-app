import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/templates/base_ticket_template.dart';

/// Template estándar para tickets (implementación original)
/// Usado para reimprimir tickets guardados
class StandardTicketTemplate extends BaseTicketTemplate {
  StandardTicketTemplate({required super.printJob});

  @override
  Future<List<TicketCommand>> build() async {
    final commands = <TicketCommand>[];

    // === ENCABEZADO ===
    commands.addAll(buildHeader(isValidInvoice: false));

    // === INFORMACIÓN DE LA ORDEN ===
    commands.addAll(buildOrderInfo());

    // === ITEMS ===
    commands.addAll(_buildItems());

    // === TOTALES ===
    commands.addAll(_buildTotals());

    // === INFORMACIÓN ADICIONAL ===
    commands.addAll(buildAdditionalInfo());

    // === CÓDIGO DE BARRAS ===
    commands.addAll(buildBarcode());

    // === PIE DE PÁGINA ===
    commands.addAll(buildFooter());

    return commands;
  }

  /// Construye la lista de items (implementación original del template standard)
  List<TicketCommand> _buildItems() {
    final commands = <TicketCommand>[
      TicketCommand.alignment(TicketAlignment.left),
    ];

    for (final item in printJob.items) {
      commands.add(TicketCommand.text(item.product.description));
      commands.add(TicketCommand.feedLine());

      if (item.isWeighted == true) {
        final weightKg = (item.weightKg ?? 0.0);
        final pricePerKg = (item.pricePerKg ?? item.product.price ?? 0.0);

        // Calcular precio con o sin IVA según configuración
        final displayPrice = getDisplayUnitPrice(item, pricePerKg, showPricesWithTax: printJob.showPricesWithTax);

        final subtotal = weightKg * displayPrice;

        final subtotalValue = subtotal.formatToCurrency();
        final weightLabel = "$weightKg kg";
        final priceLabel = displayPrice.formatToCurrency();

        final lineLeft = "  $weightLabel x $priceLabel";
        final totalSpacesLeft =
            BaseTicketTemplate.lineWidth - lineLeft.length - subtotalValue.length;
        final spacerLeft = totalSpacesLeft > 0 ? ' ' * totalSpacesLeft : ' ';

        commands.add(TicketCommand.text("$lineLeft$spacerLeft$subtotalValue"));
        commands.add(TicketCommand.feedLine());
      } else {
        final basePrice = (item.pricePerKg ?? item.product.price ?? 0.0);

        // Calcular precio con o sin IVA según configuración
        final displayPrice = getDisplayUnitPrice(item, basePrice, showPricesWithTax: printJob.showPricesWithTax);

        final unitPrice = displayPrice.formatToCurrency();
        final subtotalValue = (item.quantity * displayPrice).formatToCurrency();
        final line = "  ${item.quantity} x $unitPrice";

        final totalSpaces = BaseTicketTemplate.lineWidth - line.length - subtotalValue.length;
        final spacer = totalSpaces > 0 ? ' ' * totalSpaces : ' ';

        commands.add(TicketCommand.text("$line$spacer$subtotalValue"));
        commands.add(TicketCommand.feedLine());
      }
    }

    commands.add(TicketCommand.text(buildSeparator('-')));
    commands.add(TicketCommand.feedLine());

    return commands;
  }

  /// Construye los totales (implementación original del template standard)
  List<TicketCommand> _buildTotals() {
    final commands = <TicketCommand>[];

    // Calcular subtotal restando todos los impuestos
    final subtotalAmount = (printJob.total - 
        printJob.totalTax - 
        printJob.iibbTax - 
        printJob.vatPerception -
        printJob.internalTax).formatToCurrency();

    // Subtotal siempre se muestra
    commands.add(TicketCommand.lineWithValue("Subtotal:", subtotalAmount));

    // IVA si es mayor a 0
    if (printJob.totalTax > 0) {
      final taxAmount = printJob.totalTax.formatToCurrency();
      commands.add(TicketCommand.lineWithValue("IVA:", taxAmount));
    }

    // Percepción IIBB si es mayor a 0
    if (printJob.iibbTax > 0) {
      final iibbAmount = printJob.iibbTax.formatToCurrency();
      final iibbLabel = printJob.iibbTaxPercentage != null
          ? "Percep. IIBB (${printJob.iibbTaxPercentage}%):"
          : "Percep. IIBB:";
      commands.add(TicketCommand.lineWithValue(iibbLabel, iibbAmount));
    }

    // Percepción IVA si es mayor a 0
    if (printJob.vatPerception > 0) {
      final vatPercepAmount = printJob.vatPerception.formatToCurrency();
      commands.add(TicketCommand.lineWithValue("Percep. IVA:", vatPercepAmount));
    }

    // Impuesto Interno si es mayor a 0
    if (printJob.internalTax > 0) {
      final internalTaxAmount = printJob.internalTax.formatToCurrency();
      final internalTaxLabel = printJob.internalTaxRate != null && printJob.internalTaxRate! > 0
          ? "Imp. Interno (${printJob.internalTaxRate}%):"
          : "Imp. Interno:";
      commands.add(TicketCommand.lineWithValue(internalTaxLabel, internalTaxAmount));
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

    return commands;
  }
}
