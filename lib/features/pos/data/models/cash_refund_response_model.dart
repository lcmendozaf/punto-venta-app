import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';

class CashRefundResponseModel {
  final String ticketId;
  final DateTime timestamp;
  final int cashierId;
  final Client? client;
  final int paymentMethodId;
  final List<PaymentMethod> paymentMethods;
  final double total;
  final int branchId;
  final double totalTax;
  final List<dynamic> items;
  final String saleType;
  final int? externalId;
  final String typeCode;
  final bool isAnnulled;
  final Map<String, dynamic> extraData;
  final String description;
  final String? refundReason;
  final String? cae;
  final String? caeDueDate;
  final String? caeQrCode;
  final bool detailedTaxes;

  const CashRefundResponseModel({
    required this.ticketId,
    required this.timestamp,
    required this.cashierId,
    this.client,
    required this.paymentMethodId,
    required this.paymentMethods,
    required this.total,
    required this.branchId,
    required this.totalTax,
    required this.items,
    required this.saleType,
    this.externalId,
    required this.typeCode,
    required this.isAnnulled,
    required this.extraData,
    required this.description,
    this.refundReason,
    this.cae,
    this.caeDueDate,
    this.caeQrCode,
    required this.detailedTaxes,
  });

  factory CashRefundResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parse paymentMethods
      final rawPaymentMethods = json['paymentMethods'] as List<dynamic>? ??
          json['payment_methods'] as List<dynamic>?;
      final parsedPaymentMethods = <PaymentMethod>[];
      if (rawPaymentMethods != null) {
        for (final pm in rawPaymentMethods) {
          parsedPaymentMethods.add(PaymentMethod(
            id: pm['id'] as int? ?? 1,
            description: 'Efectivo',
            shortDescription: 'EF',
            deleteAt: '',
            amount:
                pm['amount'] != null ? (pm['amount'] as num).toDouble() : null,
            receivedAmount:
                pm['amount'] != null ? (pm['amount'] as num).toDouble() : null,
          ));
        }
      }

      // Parse totalTax array
      double calculatedTotalTax = 0.0;
      final rawTotalTax = json['totalTax'] as List<dynamic>? ??
          json['total_tax'] as List<dynamic>?;
      if (rawTotalTax != null) {
        for (final tax in rawTotalTax) {
          if (tax['amount'] != null) {
            calculatedTotalTax += (tax['amount'] as num).toDouble();
          }
        }
      }

      // Parse client with safe business_name mapping
      Client? parsedClient;
      if (json['client'] != null) {
        final clientMap = Map<String, dynamic>.from(json['client'] as Map);
        if (clientMap['business_name'] == null && clientMap['name'] != null) {
          clientMap['business_name'] = clientMap['name'];
        }
        parsedClient = Client.fromJson(clientMap);
      }

      // Parse detailed taxes
      final rawDetailedTaxes = json['detailed_taxes'] ?? json['detailedTaxes'];
      bool detailedTaxes = false;
      if (rawDetailedTaxes is bool) {
        detailedTaxes = rawDetailedTaxes;
      } else if (rawDetailedTaxes is String) {
        detailedTaxes = rawDetailedTaxes.toLowerCase() == 'true';
      }

      return CashRefundResponseModel(
        ticketId:
            json['ticketId']?.toString() ?? json['ticket_id']?.toString() ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'].toString())
            : DateTime.now(),
        cashierId: json['cashier'] as int? ?? json['cashier_id'] as int? ?? 1,
        client: parsedClient,
        paymentMethodId: json['paymentMethod'] as int? ??
            json['payment_method'] as int? ??
            1,
        paymentMethods: parsedPaymentMethods,
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        branchId: json['branch_id'] as int? ?? json['branchId'] as int? ?? 1,
        totalTax: calculatedTotalTax,
        items: json['items'] as List<dynamic>? ?? const [],
        saleType: json['sale_type'] as String? ??
            json['saleType'] as String? ??
            'FAC',
        externalId: json['external_id'] as int? ?? json['externalId'] as int?,
        typeCode: json['type_code'] as String? ?? 'N.C',
        isAnnulled: json['is_annulled'] as bool? ??
            json['isAnnulled'] as bool? ??
            false,
        extraData: json['extra_data'] as Map<String, dynamic>? ??
            json['extraData'] as Map<String, dynamic>? ??
            const {},
        description: json['description'] as String? ?? '',
        refundReason: json['refund_reason'] as String?,
        cae: json['cae']?.toString(),
        caeDueDate: json['cae_due_date']?.toString(),
        caeQrCode: json['cae_qr_code']?.toString(),
        detailedTaxes: detailedTaxes,
      );
    } catch (e, stack) {
      print('❌ [CashRefundResponseModel.fromJson] Exception: $e');
      print('🥞 [CashRefundResponseModel.fromJson] StackTrace: $stack');
      rethrow;
    }
  }

  CompletedOrder toCompletedOrder() {
    try {
      return CompletedOrder(
        id: ticketId,
        orderNumber: description,
        items: const [],
        logs: const [],
        total: total,
        completedAt: timestamp,
        clientName: client?.name,
        client: client,
        cashierName: 'Cajero',
        cashierId: cashierId,
        paymentMethod: paymentMethods.isNotEmpty ? paymentMethods.first : null,
        paymentMethods: paymentMethods,
        totalTax: totalTax,
        totalItems: 0,
        typeCode: typeCode,
        description: description,
        cae: cae,
        caeDueDate: caeDueDate,
        caeQrCode: caeQrCode,
        isAnnulled: isAnnulled,
        branchId: branchId,
        showSubtotalAndTax: detailedTaxes,
        showPricesWithTax: detailedTaxes,
      );
    } catch (e, stack) {
      print('❌ [CashRefundResponseModel.toCompletedOrder] Exception: $e');
      print('🥞 [CashRefundResponseModel.toCompletedOrder] StackTrace: $stack');
      rethrow;
    }
  }
}
