import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/features/pos/domain/entities/supplier.dart';

part 'supplier_response_model.freezed.dart';
part 'supplier_response_model.g.dart';

@freezed
class SupplierResponseModel with _$SupplierResponseModel {
  const SupplierResponseModel._();

  const factory SupplierResponseModel({
    @JsonKey(name: 'id') int? id,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'cuit') String? cuit,
    @JsonKey(name: 'is_service_provider') bool? isServiceProvider,
  }) = _SupplierResponseModel;

  factory SupplierResponseModel.fromJson(Map<String, dynamic> json) =>
      _$SupplierResponseModelFromJson(json);

  Supplier toEntity() {
    return Supplier(
      id: id ?? 0,
      name: name ?? '',
      cuit: cuit,
      isServiceProvider: isServiceProvider ?? false,
    );
  }
}
