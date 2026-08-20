import 'package:equatable/equatable.dart';

class InvoiceResponse extends Equatable {
  final String ticketId;
  final String? description;
  final String? cae;
  final String? caeDueDate;
  final bool detailedTaxes;
  final String? caeQrCode;

  const InvoiceResponse({
    required this.ticketId,
    this.description,
    this.cae,
    this.caeDueDate,
    this.detailedTaxes = false,
    this.caeQrCode,
  });

  @override
  List<Object?> get props => [
        ticketId,
        description,
        cae,
        caeDueDate,
        detailedTaxes,
        caeQrCode,
      ];
}
