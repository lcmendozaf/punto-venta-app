import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/core/constants/ticket_template_types.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import 'cart_item.dart';

class CompletedOrder extends Equatable {
  final String id;
  final String orderNumber;
  final List<CartItem> items;
  final List<CartLogEntry> logs;
  final double total;
  final DateTime completedAt;
  final String? clientName;
  final Client? client;
  final String cashierName;
  final int? cashierId;
  final PaymentMethod? paymentMethod;
  final List<PaymentMethod>? paymentMethods;
  final double totalTax;
  final int totalItems;
  final bool showSubtotalAndTax;
  final bool showPricesWithTax;
  final double? receivedAmount;
  final double? change;
  final String? typeCode;
  final String? description;
  final TicketTemplateType templateType;
  final double iibbTax;
  final double? iibbTaxPercentage;
  final double vatPerception;
  final Map<String, double>? vatPerceptionByRate;
  final double internalTax;
  final double? internalTaxRate;
  final int? priceListId;
  final String? branchNumber;
  final int? branchId;
  final int? externalId;
  final bool isAnnulled;
  final String? cae;
  final String? caeDueDate;
  final String? caeQrCode;

  const CompletedOrder({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.logs,
    required this.total,
    required this.completedAt,
    this.clientName,
    this.client,
    required this.cashierName,
    this.cashierId,
    required this.paymentMethod,
    this.paymentMethods,
    required this.totalTax,
    required this.totalItems,
    this.showSubtotalAndTax = false,
    this.showPricesWithTax = true,
    this.receivedAmount,
    this.change,
    this.typeCode,
    this.description,
    this.templateType = TicketTemplateType.standard,
    this.iibbTax = 0.0,
    this.iibbTaxPercentage,
    this.vatPerception = 0.0,
    this.vatPerceptionByRate,
    this.internalTax = 0.0,
    this.internalTaxRate,
    this.priceListId,
    this.branchNumber,
    this.branchId,
    this.externalId,
    this.isAnnulled = false,
    this.cae,
    this.caeDueDate,
    this.caeQrCode,
  });

  CompletedOrder copyWith({
    String? id,
    String? orderNumber,
    List<CartItem>? items,
    List<CartLogEntry>? logs,
    double? total,
    DateTime? completedAt,
    String? clientName,
    Client? client,
    String? cashierName,
    int? cashierId,
    PaymentMethod? paymentMethod,
    List<PaymentMethod>? paymentMethods,
    double? totalTax,
    int? totalItems,
    bool? showSubtotalAndTax,
    bool? showPricesWithTax,
    double? receivedAmount,
    double? change,
    String? typeCode,
    String? description,
    TicketTemplateType? templateType,
    double? iibbTax,
    double? iibbTaxPercentage,
    double? vatPerception,
    Map<String, double>? vatPerceptionByRate,
    double? internalTax,
    double? internalTaxRate,
    int? priceListId,
    String? branchNumber,
    int? branchId,
    int? externalId,
    bool? isAnnulled,
    String? cae,
    String? caeDueDate,
    String? caeQrCode,
  }) {
    return CompletedOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? this.items,
      logs: logs ?? this.logs,
      total: total ?? this.total,
      completedAt: completedAt ?? this.completedAt,
      clientName: clientName ?? this.clientName,
      client: client ?? this.client,
      cashierName: cashierName ?? this.cashierName,
      cashierId: cashierId ?? this.cashierId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      totalTax: totalTax ?? this.totalTax,
      totalItems: totalItems ?? this.totalItems,
      showSubtotalAndTax: showSubtotalAndTax ?? this.showSubtotalAndTax,
      showPricesWithTax: showPricesWithTax ?? this.showPricesWithTax,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      change: change ?? this.change,
      typeCode: typeCode ?? this.typeCode,
      description: description ?? this.description,
      templateType: templateType ?? this.templateType,
      iibbTax: iibbTax ?? this.iibbTax,
      iibbTaxPercentage: iibbTaxPercentage ?? this.iibbTaxPercentage,
      vatPerception: vatPerception ?? this.vatPerception,
      vatPerceptionByRate: vatPerceptionByRate ?? this.vatPerceptionByRate,
      internalTax: internalTax ?? this.internalTax,
      internalTaxRate: internalTaxRate ?? this.internalTaxRate,
      priceListId: priceListId ?? this.priceListId,
      branchNumber: branchNumber ?? this.branchNumber,
      branchId: branchId ?? this.branchId,
      externalId: externalId ?? this.externalId,
      isAnnulled: isAnnulled ?? this.isAnnulled,
      cae: cae ?? this.cae,
      caeDueDate: caeDueDate ?? this.caeDueDate,
      caeQrCode: caeQrCode ?? this.caeQrCode,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        items,
        logs,
        total,
        completedAt,
        clientName,
        client,
        cashierName,
        cashierId,
        paymentMethod,
        paymentMethods,
        totalTax,
        totalItems,
        showSubtotalAndTax,
        showPricesWithTax,
        receivedAmount,
        change,
        typeCode,
        description,
        templateType,
        iibbTax,
        iibbTaxPercentage,
        vatPerception,
        vatPerceptionByRate,
        internalTax,
        internalTaxRate,
        priceListId,
        branchNumber,
        branchId,
        externalId,
        isAnnulled,
        cae,
        caeDueDate,
        caeQrCode,
      ];
}
