import 'package:punto_venta_app/core/constants/ticket_template_types.dart';
import 'package:punto_venta_app/features/auth/data/models/enterprise_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/domain/entities/fiscal_issuer_data.dart';

class PrintJob {
  final String? ticketId;
  final List<CartItem> items;
  final List<CartLogEntry> logItems;
  final double total;
  final double totalTax;
  final double iibbTax;
  final double? iibbTaxPercentage;
  final double vatPerception;
  final Map<String, double>? vatPerceptionByRate;
  final double internalTax;
  final double? internalTaxRate;
  final String? clientName;
  final Client? client;
  final int? priceListId;
  // TODO: Cambiar a que el metodo de pago pueda ser un array para soportar múltiples métodos de pago
  final PaymentMethod? paymentMethod;
  final List<PaymentMethod>? paymentMethods;
  final String? cashierName;
  final int? cashierId;
  final DateTime timestamp;
  final EnterpriseModel? enterprise;
  final FiscalIssuerData? fiscalIssuerData;
  final bool showSubtotalAndTax;
  final bool showPricesWithTax;
  final double? receivedAmount;
  final double? change;
  final String branchNumber;
  final int? branchId;
  final String? description;
  final TicketTemplateType templateType;
  final bool isCopy;
  final bool isCreditNote;
  final String? cae;
  final String? caeDueDate;
  final String? caeQrCode;

  const PrintJob({
    required this.items,
    required this.logItems,
    required this.total,
    required this.totalTax,
    this.iibbTax = 0.0,
    this.iibbTaxPercentage,
    this.vatPerception = 0.0,
    this.vatPerceptionByRate,
    this.internalTax = 0.0,
    this.internalTaxRate,
    this.client,
    this.clientName,
    this.priceListId,
    this.paymentMethod,
    this.paymentMethods,
    required this.cashierName,
    this.cashierId,
    required this.timestamp,
    this.ticketId,
    this.showSubtotalAndTax = true,
    this.showPricesWithTax = false,
    this.enterprise,
    this.fiscalIssuerData,
    this.receivedAmount,
    this.change,
    required this.branchNumber,
    this.branchId,
    this.description,
    this.templateType = TicketTemplateType.standard,
    this.isCopy = false,
    this.isCreditNote = false,
    this.cae,
    this.caeDueDate,
    this.caeQrCode,
  });
}
