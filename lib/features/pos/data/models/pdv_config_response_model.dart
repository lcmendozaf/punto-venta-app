import 'package:freezed_annotation/freezed_annotation.dart';

part 'pdv_config_response_model.freezed.dart';
part 'pdv_config_response_model.g.dart';

@freezed
class PdvConfigResponseModel with _$PdvConfigResponseModel {
  const PdvConfigResponseModel._();

  const factory PdvConfigResponseModel({
    @JsonKey(name: 'company_id') int? companyId,
    @JsonKey(name: 'cuit') String? cuit,
    @JsonKey(name: 'delivery_location_id') int? deliveryLocationId,
    @JsonKey(name: 'customer_id') int? customerId,
    @JsonKey(name: 'wallet_id') int? walletId,
    @JsonKey(name: 'wallet_seller_id') int? walletSellerId,
    @JsonKey(name: 'distribution_channel_id') int? distributionChannelId,
    @JsonKey(name: 'customer_cuit') String? customerCuit,
    @JsonKey(name: 'sale_condition_id') String? saleConditionId,
    @JsonKey(name: 'type') String? type,
    @JsonKey(name: 'class_type') String? classType,
    @JsonKey(name: 'dni') String? dni,
    @JsonKey(name: 'vat_category_id') int? vatCategoryId,
    @JsonKey(name: 'shipment_id') int? shipmentId,
    @JsonKey(name: 'afip_voucher_type') String? afipVoucherType,
    @JsonKey(name: 'date') String? date,
    @JsonKey(name: 'afip_token') String? afipToken,
    @JsonKey(name: 'afip_sign') String? afipSign,
    @JsonKey(name: 'afip_token_expiration') String? afipTokenExpiration,
    @JsonKey(name: 'caea') String? caea,
    @JsonKey(name: 'period') int? period,
    @JsonKey(name: 'period_order') int? periodOrder,
    @JsonKey(name: 'valid_from') String? validFrom,
    @JsonKey(name: 'valid_to') String? validTo,
    @JsonKey(name: 'reporting_deadline') String? reportingDeadline,
    @JsonKey(name: 'process_date') String? processDate,
    @JsonKey(name: 'offline_mode') bool? offlineMode,
    @JsonKey(name: 'branch_id') int? branchId,
    @JsonKey(name: 'credit_note_days_limit') int? creditNoteDaysLimit,
    @JsonKey(name: 'id') int? id,
  }) = _PdvConfigResponseModel;

  factory PdvConfigResponseModel.fromJson(Map<String, dynamic> json) =>
      _$PdvConfigResponseModelFromJson(json);
}
