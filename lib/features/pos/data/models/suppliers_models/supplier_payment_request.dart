import 'package:freezed_annotation/freezed_annotation.dart';

part 'supplier_payment_request.freezed.dart';
part 'supplier_payment_request.g.dart';

@freezed
class SupplierPaymentRequest with _$SupplierPaymentRequest {
  const SupplierPaymentRequest._();

  const factory SupplierPaymentRequest({
    @JsonKey(name: 'timestamp') DateTime? timestamp,
    @JsonKey(name: 'user_id') int? userId,
    @JsonKey(name: 'supplier_id') int? supplierId,
    @JsonKey(name: 'items', toJson: _itemsToJson)
    List<ItemSupplierRequest>?
        items, // modelo de item (del ticket pero solo debe tener codigo y cantidad)
    @JsonKey(name: 'total_paid') double? totalPaid,
    // @JsonKey(name: 'remito_number') int? remitoNumber,
    // @JsonKey(name: 'provider_ticket') int? providerTicket,
  }) = _SupplierPaymentRequest;

  factory SupplierPaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$SupplierPaymentRequestFromJson(json);

  Map<String, dynamic> toJson();
}

List<Map<String, dynamic>>? _itemsToJson(List<ItemSupplierRequest>? items) =>
    items?.map((e) => e.toJson()).toList();

@freezed
class ItemSupplierRequest with _$ItemSupplierRequest {
  const ItemSupplierRequest._();

  const factory ItemSupplierRequest({
    @JsonKey(name: 'item_id') int? itemId,
    @JsonKey(name: 'quantity') int? quantity,
  }) = _ItemSupplierRequest;

  factory ItemSupplierRequest.fromJson(Map<String, dynamic> json) =>
      _$ItemSupplierRequestFromJson(json);

  Map<String, dynamic> toJson();
}
