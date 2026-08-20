import 'package:punto_venta_app/features/pos/domain/entities/invoice_response.dart';

class InvoiceResponseModel {
  final String ticketId;
  final String? description;
  final String? cae;
  final String? caeDueDate;
  final bool detailedTaxes;
  final String? caeQrCode;

  const InvoiceResponseModel({
    required this.ticketId,
    this.description,
    this.cae,
    this.caeDueDate,
    this.detailedTaxes = false,
    this.caeQrCode,
  });

  factory InvoiceResponseModel.fromJson(Map<String, dynamic> json,
      {String? defaultTicketId}) {
    final rawTicketId = json['ticketId'] ?? json['ticket_id'];
    final ticketId = rawTicketId?.toString() ?? defaultTicketId ?? '';

    final description = json['description']?.toString();
    final cae = json['cae']?.toString();
    final caeDueDate = (json['cae_due_date'] ??
            json['afip_cae_due_date'] ??
            json['afipCaeDueDate'])
        ?.toString();
    final caeQrCode = (json['cae_qr_code'] ?? json['caeQrCode'])?.toString();

    final rawDetailedTaxes = json['detailed_taxes'] ?? json['detailedTaxes'];
    bool detailedTaxes = false;
    if (rawDetailedTaxes is bool) {
      detailedTaxes = rawDetailedTaxes;
    } else if (rawDetailedTaxes is String) {
      detailedTaxes = rawDetailedTaxes.toLowerCase() == 'true';
    }

    return InvoiceResponseModel(
      ticketId: ticketId,
      description: description,
      cae: cae,
      caeDueDate: caeDueDate,
      detailedTaxes: detailedTaxes,
      caeQrCode: caeQrCode,
    );
  }

  InvoiceResponse toEntity() {
    return InvoiceResponse(
      ticketId: ticketId,
      description: description,
      cae: cae,
      caeDueDate: caeDueDate,
      detailedTaxes: detailedTaxes,
      caeQrCode: caeQrCode,
    );
  }
}
