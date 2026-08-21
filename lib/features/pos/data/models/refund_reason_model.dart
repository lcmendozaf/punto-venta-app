import 'package:punto_venta_app/features/pos/domain/entities/refund_reason.dart';

class RefundReasonModel {
  final int id;
  final String? description;

  const RefundReasonModel({
    required this.id,
    this.description,
  });

  factory RefundReasonModel.fromJson(Map<String, dynamic> json) {
    return RefundReasonModel(
      id: json['id'] as int,
      description: (json['description']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
      };

  RefundReason toEntity() {
    return RefundReason(
      id: id,
      description: description ?? '',
    );
  }
}
