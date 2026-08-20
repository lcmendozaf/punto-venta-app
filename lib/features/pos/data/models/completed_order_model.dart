import 'package:json_annotation/json_annotation.dart';
import 'package:punto_venta_app/core/constants/ticket_template_types.dart';
import 'package:punto_venta_app/features/pos/data/models/cart_log_entry_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import 'cart_item_model.dart';

part 'completed_order_model.g.dart';

@JsonSerializable()
class CompletedOrderModel {
  final String id;
  @JsonKey(name: 'order_number')
  final String orderNumber;
  final List<CartItemModel> items;
  final List<CartLogEntryModel> logs;
  final double total;
  @JsonKey(name: 'completed_at')
  final DateTime completedAt;
  @JsonKey(name: 'client_name')
  final String? clientName;
  @JsonKey(
    name: 'client',
    fromJson: _clientFromJson,
    toJson: _clientToJson,
  )
  final Client? client;
  @JsonKey(name: 'cashier_name')
  final String cashierName;
  @JsonKey(name: 'cashier_id')
  final int? cashierId;
  @JsonKey(
    name: 'payment_method',
    fromJson: _paymentMethodFromJson,
    toJson: _paymentMethodToJson,
  )
  final PaymentMethod? paymentMethod;
  @JsonKey(
    name: 'payment_methods',
    fromJson: _paymentMethodsFromJson,
    toJson: _paymentMethodsToJson,
  )
  final List<PaymentMethod>? paymentMethods;
  @JsonKey(name: 'total_tax')
  final double totalTax;
  @JsonKey(name: 'total_items')
  final int totalItems;
  @JsonKey(name: 'show_subtotal_and_tax')
  final bool showSubtotalAndTax;
  @JsonKey(name: 'show_prices_with_tax')
  final bool showPricesWithTax;
  @JsonKey(name: 'received_amount')
  final double? receivedAmount;
  @JsonKey(name: 'change')
  final double? change;
  @JsonKey(name: 'type_code')
  final String? typeCode;
  @JsonKey(name: 'description')
  final String? description;
  @JsonKey(
    name: 'template_type',
    fromJson: _templateTypeFromJson,
    toJson: _templateTypeToJson,
  )
  final TicketTemplateType templateType;
  @JsonKey(name: 'iibb_tax')
  final double iibbTax;
  @JsonKey(name: 'iibb_tax_percentage')
  final double? iibbTaxPercentage;
  @JsonKey(name: 'vat_perception')
  final double vatPerception;
  @JsonKey(name: 'vat_perception_by_rate')
  final Map<String, double>? vatPerceptionByRate;
  @JsonKey(name: 'internal_tax')
  final double internalTax;
  @JsonKey(name: 'internal_tax_rate')
  final double? internalTaxRate;
  @JsonKey(name: 'price_list_id')
  final int? priceListId;
  @JsonKey(name: 'branch_number')
  final String? branchNumber;
  @JsonKey(name: 'branch_id')
  final int? branchId;
  @JsonKey(name: 'external_id')
  final int? externalId;
  @JsonKey(name: 'is_annulled')
  final bool isAnnulled;
  final String? cae;
  @JsonKey(name: 'cae_due_date')
  final String? caeDueDate;
  @JsonKey(name: 'cae_qr_code')
  final String? caeQrCode;

  const CompletedOrderModel({
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
    this.paymentMethod,
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

  factory CompletedOrderModel.fromJson(Map<String, dynamic> json) =>
      _$CompletedOrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$CompletedOrderModelToJson(this);

  CompletedOrder toEntity() {
    return CompletedOrder(
      id: id,
      orderNumber: orderNumber,
      items: items.map((item) => item.toEntity()).toList(),
      logs: logs.map((log) => log.toEntity()).toList(),
      total: total,
      completedAt: completedAt,
      clientName: clientName,
      client: client,
      cashierName: cashierName,
      cashierId: cashierId,
      paymentMethod: paymentMethod,
      paymentMethods: paymentMethods,
      totalTax: totalTax,
      totalItems: totalItems,
      showSubtotalAndTax: showSubtotalAndTax,
      showPricesWithTax: showPricesWithTax,
      receivedAmount: receivedAmount,
      change: change,
      typeCode: typeCode,
      description: description,
      templateType: templateType,
      iibbTax: iibbTax,
      iibbTaxPercentage: iibbTaxPercentage,
      vatPerception: vatPerception,
      vatPerceptionByRate: vatPerceptionByRate,
      internalTax: internalTax,
      internalTaxRate: internalTaxRate,
      priceListId: priceListId,
      branchNumber: branchNumber,
      branchId: branchId,
      externalId: externalId,
      isAnnulled: isAnnulled,
      cae: cae,
      caeDueDate: caeDueDate,
      caeQrCode: caeQrCode,
    );
  }

  factory CompletedOrderModel.fromEntity(CompletedOrder order) {
    return CompletedOrderModel(
      id: order.id,
      orderNumber: order.orderNumber,
      items: order.items.map((item) => CartItemModel.fromEntity(item)).toList(),
      logs: order.logs.map((log) => CartLogEntryModel.fromEntity(log)).toList(),
      total: order.total,
      completedAt: order.completedAt,
      clientName: order.clientName,
      client: order.client,
      cashierName: order.cashierName,
      cashierId: order.cashierId,
      paymentMethod: order.paymentMethod,
      paymentMethods: order.paymentMethods,
      totalTax: order.totalTax,
      totalItems: order.totalItems,
      showSubtotalAndTax: order.showSubtotalAndTax,
      showPricesWithTax: order.showPricesWithTax,
      receivedAmount: order.receivedAmount,
      change: order.change,
      typeCode: order.typeCode,
      description: order.description,
      templateType: order.templateType,
      iibbTax: order.iibbTax,
      iibbTaxPercentage: order.iibbTaxPercentage,
      vatPerception: order.vatPerception,
      vatPerceptionByRate: order.vatPerceptionByRate,
      internalTax: order.internalTax,
      internalTaxRate: order.internalTaxRate,
      priceListId: order.priceListId,
      branchNumber: order.branchNumber,
      branchId: order.branchId,
      externalId: order.externalId,
      isAnnulled: order.isAnnulled,
      cae: order.cae,
      caeDueDate: order.caeDueDate,
      caeQrCode: order.caeQrCode,
    );
  }
}

PaymentMethod? _paymentMethodFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  return PaymentMethod(
    id: json['id'] as int,
    description: json['description'] as String,
    shortDescription: json['short_description'] as String,
    deleteAt: json['delete_at'] as String,
    amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
    receivedAmount: json['received_amount'] != null
        ? (json['received_amount'] as num).toDouble()
        : null,
    details: json['details'] != null
        ? PaymentMethodDetails.fromJson(json['details'] as Map<String, dynamic>)
        : null,
  );
}

Map<String, dynamic>? _paymentMethodToJson(PaymentMethod? paymentMethod) {
  if (paymentMethod == null) return null;
  return {
    'id': paymentMethod.id,
    'description': paymentMethod.description,
    'short_description': paymentMethod.shortDescription,
    'delete_at': paymentMethod.deleteAt,
    if (paymentMethod.amount != null) 'amount': paymentMethod.amount,
    if (paymentMethod.receivedAmount != null)
      'received_amount': paymentMethod.receivedAmount,
    if (paymentMethod.details != null)
      'details': paymentMethod.details!.toJson(),
  };
}

List<PaymentMethod>? _paymentMethodsFromJson(List<dynamic>? json) {
  if (json == null) return null;
  return json
      .map((item) => PaymentMethod(
            id: item['id'] as int,
            description: item['description'] as String,
            shortDescription: item['short_description'] as String,
            deleteAt: item['delete_at'] as String,
            amount: item['amount'] != null
                ? (item['amount'] as num).toDouble()
                : null,
            receivedAmount: item['received_amount'] != null
                ? (item['received_amount'] as num).toDouble()
                : null,
            details: item['details'] != null
                ? PaymentMethodDetails.fromJson(
                    item['details'] as Map<String, dynamic>)
                : null,
          ))
      .toList();
}

List<Map<String, dynamic>>? _paymentMethodsToJson(
    List<PaymentMethod>? paymentMethods) {
  if (paymentMethods == null) return null;
  return paymentMethods
      .map((pm) => {
            'id': pm.id,
            'description': pm.description,
            'short_description': pm.shortDescription,
            'delete_at': pm.deleteAt,
            if (pm.amount != null) 'amount': pm.amount,
            if (pm.receivedAmount != null) 'received_amount': pm.receivedAmount,
            if (pm.details != null) 'details': pm.details!.toJson(),
          })
      .toList();
}

Client? _clientFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  return Client.fromJson(json);
}

Map<String, dynamic>? _clientToJson(Client? client) {
  if (client == null) return null;
  return client.toJson();
}

TicketTemplateType _templateTypeFromJson(String? json) {
  if (json == null) return TicketTemplateType.standard;
  switch (json) {
    case 'standard':
      return TicketTemplateType.standard;
    case 'blackMarket':
      return TicketTemplateType.blackMarket;
    case 'whiteMarket':
      return TicketTemplateType.whiteMarket;
    default:
      return TicketTemplateType.standard;
  }
}

String _templateTypeToJson(TicketTemplateType templateType) {
  switch (templateType) {
    case TicketTemplateType.standard:
      return 'standard';
    case TicketTemplateType.blackMarket:
      return 'blackMarket';
    case TicketTemplateType.whiteMarket:
      return 'whiteMarket';
  }
}
