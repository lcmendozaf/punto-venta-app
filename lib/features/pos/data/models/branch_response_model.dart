import 'package:freezed_annotation/freezed_annotation.dart';

part 'branch_response_model.freezed.dart';
part 'branch_response_model.g.dart';

@freezed
class BranchResponseModel with _$BranchResponseModel {
  const BranchResponseModel._();

  const factory BranchResponseModel({
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'afip_available') bool? afipAvailable,
    @JsonKey(name: 'apply_per_iibb') bool? applyPerIibb,
    @JsonKey(name: 'per_iibb_amount') int? perIibbAmount,
    @JsonKey(name: 'apply_per_vat') bool? applyPerVat,
    @JsonKey(name: 'per_vat_amount') int? perVatAmount,
    @JsonKey(name: 'default_iibb_tax_rate') int? defaultIibbTaxRate,
    @JsonKey(name: 'province_id') int? provinceId,
    @JsonKey(name: 'priority') int? priority,
    @JsonKey(name: 'id') int? branchId,
  }) = _BranchResponseModel;

  factory BranchResponseModel.fromJson(Map<String, dynamic> json) =>
      _$BranchResponseModelFromJson(json);
}
