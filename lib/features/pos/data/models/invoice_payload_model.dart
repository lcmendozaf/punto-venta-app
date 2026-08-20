import 'package:punto_venta_app/core/constants/ticket_types.dart';
import 'package:punto_venta_app/features/pos/data/models/cart_item_model.dart';
import 'package:punto_venta_app/features/pos/data/models/cart_log_entry_model.dart';
import 'package:punto_venta_app/features/pos/data/models/tax_model.dart';
import 'package:punto_venta_app/features/pos/data/models/payment_method_request_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_details.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method_input.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';

class InvoicePayload {
  final String? ticketId;
  final String timestamp;
  final int? cashier;
  final Map<String, dynamic>? client;
  final List<PaymentMethodRequestModel> paymentMethods;
  final double total;
  final List<TaxModel> totalTax;
  final List<Map<String, dynamic>> logItems;
  final String branchNumber;
  final int branchId;
  final int? externalId;
  final String? saleType;
  final String? typeCode;
  final String? description;
  final bool isAnnulled;
  final String? cae;
  final String? caeDueDate;
  final String? caeQrCode;

  InvoicePayload({
    this.ticketId,
    required this.timestamp,
    this.cashier,
    required this.client,
    required this.paymentMethods,
    required this.total,
    required this.totalTax,
    required this.logItems,
    required this.branchNumber,
    required this.branchId,
    this.externalId,
    this.saleType,
    this.typeCode,
    this.description,
    this.isAnnulled = false,
    this.cae,
    this.caeDueDate,
    this.caeQrCode,
  });

  static Map<String, dynamic> _serializeTax(TaxModel t) {
    return {
      'id': t.id,
      'percentage': t.percentage,
      'amount': t.amount,
      'province_id': t.provinceId,
    };
  }

  Map<String, dynamic> toJson() => {
        if (ticketId != null) 'ticketId': ticketId,
        'timestamp': timestamp,
        'cashier': cashier,
        'client': client,
        'paymentMethods': paymentMethods.map((pm) {
          final map = pm.toJson();
          if (pm.details != null) {
            map['details'] = pm.details!.toJson();
          }
          return map;
        }).toList(),
        'total': total,
        'branch_number': branchNumber,
        'branch_id': branchId,
        'totalTax':
            totalTax.map((t) => InvoicePayload._serializeTax(t)).toList(),
        'items': logItems,
        if (cae != null) 'cae': cae,
        if (caeDueDate != null) 'cae_due_date': caeDueDate,
        if (caeQrCode != null) 'cae_qr_code': caeQrCode,
      };

  factory InvoicePayload.fromJson(Map<String, dynamic> json) {
    final total = (json['total'] as num).toDouble();
    final paymentMethodsList = json['paymentMethods'] as List? ?? [];

    return InvoicePayload(
      ticketId: json['ticketId']?.toString(),
      timestamp: json['timestamp'] as String,
      cashier: json['cashier'] as int?,
      client: json['client'] as Map<String, dynamic>?,
      paymentMethods: (json['paymentMethods'] as List)
          .map((pm) =>
              PaymentMethodRequestModel.fromJson(pm as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toDouble(),
      totalTax: (json['totalTax'] as List)
          .map((t) => TaxModel.fromJson(t as Map<String, dynamic>))
          .toList(),
      logItems: (json['items'] as List)
          .map((item) => item as Map<String, dynamic>)
          .toList(),
      branchNumber: json['branch_number']?.toString() ?? '',
      branchId: json['branch_id'] as int? ?? 0,
      externalId: json['external_id'] as int?,
      saleType: json['sale_type'] as String?,
      typeCode: json['type_code'] as String?,
      description: json['description'] as String?,
      isAnnulled: json['is_annulled'] as bool? ?? false,
      cae: json['cae']?.toString(),
      caeDueDate: json['cae_due_date']?.toString(),
      caeQrCode: json['cae_qr_code']?.toString(),
    );
  }

  // Método de fábrica para crear un InvoicePayload a partir de un PrintJob y una lista de TaxModel
  factory InvoicePayload.fromPrintJob(PrintJob job, List<TaxModel> taxes) {
    if (taxes.isEmpty) {
      print(
          '[INVOICE_PAYLOAD] Lista de taxes está vacía. Los IDs de impuestos pueden ser incorrectos.');
    }

    // Helper para obtener el ID correcto del tax según el porcentaje
    int getTaxIdByPercentage(double percentage) {
      if (percentage == 0) return 0;
      if (percentage == 21) return 1;
      if (percentage == 10.5) return 2;
      if (percentage == 27) return 3;
      return 0;
    }

    Map<String, dynamic>? serializeClient(Client? c) {
      if (c == null) return null;

      String? doc = c.document;
      if (doc == null || doc.trim().isEmpty) {
        doc = c.cuit;
      }
      if (doc == null || doc.trim().isEmpty) {
        doc = c.dni;
      }
      if (doc == null || doc.trim().isEmpty) {
        doc = '';
      }

      return {
        'id': c.id,
        'name': c.name,
        'document': doc,
        'phone': c.phone,
        'email': c.email,
        'address': c.address,
      };
    }

    final Map<double, double> totalsByPercentage = {};

    Map<String, dynamic> serializeCartLogItem(CartLogEntry itemLog) {
      try {
        return (itemLog as dynamic).toJson() as Map<String, dynamic>;
      } catch (_) {
        final cartLogItem = CartLogEntryModel.fromEntity(itemLog);
        final itemModel = CartItemModel.fromEntity(itemLog.item);

        final unitPrice = itemModel.product.price ?? 0.0;
        final quantity = itemModel.quantity;
        final weightKg = itemLog.item.weightKg;
        final isWeighted = (itemLog.item.isWeighted == true);

        final double taxableBase = isWeighted
            ? (itemModel.pricePerKg ?? unitPrice)
            : unitPrice * quantity;

        final double taxPercentage = (itemModel.iva) + 0.0;
        final double taxAmount = taxableBase * (taxPercentage / 100.0);

        TaxModel? matchedTax;
        try {
          matchedTax = taxes.firstWhere((t) => t.percentage == taxPercentage);
        } catch (e) {
          final taxId = getTaxIdByPercentage(taxPercentage);
          matchedTax = TaxModel(
            id: taxId,
            percentage: taxPercentage,
            description: 'IVA $taxPercentage%',
          );
        }

        final List<TaxModel> itemTaxes = [
          TaxModel(
            id: matchedTax.id,
            percentage: taxPercentage,
            amount: double.parse(taxAmount.toStringAsFixed(2)),
            provinceId: null,
          ),
        ];

        final vatPerception = itemModel.product.vatPerception;
        if (job.vatPerception > 0 &&
            vatPerception != null &&
            vatPerception > 0) {
          final vatPerceptionAmount = taxableBase * (vatPerception / 100.0);
          itemTaxes.add(TaxModel(
            id: 6,
            percentage: vatPerception,
            amount: double.parse(vatPerceptionAmount.toStringAsFixed(2)),
            provinceId: null,
          ));
        }

        final internalTax = itemModel.product.internalTax;
        final internalTaxRate = itemModel.product.internalTaxRate;
        if (job.internalTax > 0 && internalTax != null && internalTax > 0) {
          final fractional = itemModel.product.fractional ?? 1;
          final itemTotalWithInternalTax =
              (internalTax + unitPrice) * quantity * fractional;
          final baseAmount = unitPrice * quantity * fractional;
          final internalTaxAmount = itemTotalWithInternalTax - baseAmount;

          itemTaxes.add(TaxModel(
            id: 7,
            percentage: internalTaxRate,
            amount: double.parse(internalTaxAmount.toStringAsFixed(2)),
            provinceId: null,
          ));
        }

        final isRemove = cartLogItem.type == 'remove';
        final double signedTaxAmount = isRemove ? -taxAmount : taxAmount;

        totalsByPercentage.update(
          taxPercentage,
          (prev) => prev + signedTaxAmount,
          ifAbsent: () => signedTaxAmount,
        );

        // "item"
        return {
          'id': cartLogItem.id,
          'type': cartLogItem.type.toString(),
          'productId': itemModel.product.id,
          'productName': itemModel.product.description,
          'quantity': quantity,
          'discount': 0,
          'unitPrice': unitPrice,
          'priceListId': job.priceListId,
          'taxes': itemTaxes
              .map((t) => {
                    'id': t.id,
                    'percentage': t.percentage,
                    'amount': t.amount,
                  })
              .toList(),
          'is_weighted': isWeighted ? "S" : "N",
          'net_weight': isWeighted ? itemModel.product.netWeight : null,
          'weight': isWeighted ? weightKg ?? 0.0 : null,
        };
      }
    }

    final logItems = job.logItems.map(serializeCartLogItem).toList();

    final totalTax = totalsByPercentage.entries.map((e) {
      final percentage = e.key;
      final amount = e.value;
      TaxModel? matchedTax;
      try {
        matchedTax = taxes.firstWhere((t) => t.percentage == percentage);
      } catch (e) {
        final taxId = getTaxIdByPercentage(percentage);
        matchedTax = TaxModel(
            id: taxId, percentage: percentage, description: 'IVA $percentage%');
      }
      return TaxModel(
        id: matchedTax.id,
        percentage: double.parse(percentage.toStringAsFixed(2)),
        amount: double.parse(amount.toStringAsFixed(2)),
        provinceId: null,
      );
    }).toList();

    // Agregar IIBB si existe
    if (job.iibbTax > 0) {
      TaxModel? iibbTaxModel;
      try {
        iibbTaxModel = taxes.firstWhere((t) => t.id == 4);
      } catch (e) {
        iibbTaxModel = const TaxModel(
          id: 4,
          description: 'IIBB',
          percentage: null,
        );
      }

      totalTax.add(TaxModel(
        id: iibbTaxModel.id,
        percentage: job.iibbTaxPercentage,
        amount: double.parse(job.iibbTax.toStringAsFixed(2)),
        provinceId: job.client?.provinceId,
      ));
    }

    if (job.vatPerception > 0) {
      TaxModel? vatPerceptionTaxModel;
      try {
        vatPerceptionTaxModel = taxes.firstWhere((t) => t.id == 6);
      } catch (e) {
        vatPerceptionTaxModel = const TaxModel(
          id: 6,
          description: 'Percep.IVA',
          percentage: null,
        );
      }

      totalTax.add(TaxModel(
        id: vatPerceptionTaxModel.id,
        percentage: null,
        amount: double.parse(job.vatPerception.toStringAsFixed(2)),
        provinceId: null,
      ));
    }

    if (job.internalTax > 0) {
      TaxModel? internalTaxModel;
      try {
        internalTaxModel = taxes.firstWhere((t) => t.id == 7);
      } catch (e) {
        internalTaxModel = const TaxModel(
          id: 7,
          description: 'IMPINT',
          percentage: null,
        );
      }

      totalTax.add(TaxModel(
        id: internalTaxModel.id,
        percentage: null,
        amount: double.parse(job.internalTax.toStringAsFixed(2)),
        provinceId: null,
      ));
    }

    final methods = job.paymentMethods ??
        (job.paymentMethod != null ? [job.paymentMethod!] : <PaymentMethod>[]);

    return InvoicePayload(
      ticketId: job.ticketId,
      timestamp: job.timestamp.toIso8601String(),
      cashier: job.cashierId,
      client: serializeClient(job.client),
      paymentMethods: methods.map((pm) {
        return PaymentMethodRequestModel(
          id: pm.id,
          amount: pm.amount,
          details: pm.details != null
              ? PaymentMethodDetailRequest(
                  accountOwner: pm.details!.accountOwner,
                  bankId: pm.details!.bankId,
                  checkNumber: pm.details!.checkNumber,
                  transferId: pm.details!.transferId,
                  verificationId: pm.details!.verificationId,
                )
              : null,
        );
      }).toList(),

      total: job.total,
      totalTax: totalTax,
      // "items"
      logItems: logItems,
      branchNumber: job.branchNumber,
      branchId: job.branchId ?? 0,
      saleType: TicketType.factura,
      typeCode: TicketType.factura,
      isAnnulled: false,
      cae: job.cae,
      caeDueDate: job.caeDueDate,
      caeQrCode: job.caeQrCode,
    );
  }
}
