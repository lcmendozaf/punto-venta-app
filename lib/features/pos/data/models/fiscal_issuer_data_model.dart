import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/features/pos/domain/entities/fiscal_issuer_data.dart';

part 'fiscal_issuer_data_model.freezed.dart';
part 'fiscal_issuer_data_model.g.dart';

@freezed
class FiscalIssuerDataModel with _$FiscalIssuerDataModel {
  const FiscalIssuerDataModel._();

  const factory FiscalIssuerDataModel({
    @JsonKey(name: 'name') String? fiscalName,
    @JsonKey(name: 'cuit') String? cuit,
    @JsonKey(name: 'perception_iiibb') String? iibbCuit,
    @JsonKey(name: 'address') String? address,
    @JsonKey(name: 'city') String? postalCode,
    @JsonKey(name: 'business_start_date') String? activityStartDate,
    @JsonKey(name: 'vat_category') String? vatCondition,
  }) = _FiscalIssuerDataModel;

  factory FiscalIssuerDataModel.fromJson(Map<String, dynamic> json) =>
      _$FiscalIssuerDataModelFromJson(json);

  /// Convierte el modelo a la entidad de dominio
  FiscalIssuerData toEntity() {
    return FiscalIssuerData(
      fiscalName: fiscalName,
      cuit: cuit,
      iibbCuit: iibbCuit,
      address: address,
      postalCode: postalCode,
      activityStartDate: activityStartDate,
      vatCondition: vatCondition,
    );
  }
}
