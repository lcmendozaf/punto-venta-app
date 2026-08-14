import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method_config.dart';

part 'payment_methods_config_model.freezed.dart';
part 'payment_methods_config_model.g.dart';

@freezed
class PaymentMethodsConfigModel with _$PaymentMethodsConfigModel {
  const PaymentMethodsConfigModel._();

  const factory PaymentMethodsConfigModel({
    @JsonKey(
      name: 'payment_methods_config',
      toJson: _paymentMethodsConfigToJson,
    )
    required List<PaymentMethodConfigModel> paymentMethodsConfig,
  }) = _PaymentMethodsConfigModel;

  factory PaymentMethodsConfigModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodsConfigModelFromJson(json);

  Map<String, dynamic> toJson();

  factory PaymentMethodsConfigModel.fromEntity(PaymentMethodsConfig entity) {
    return PaymentMethodsConfigModel(
      paymentMethodsConfig: entity.paymentMethodsConfig
          .map((e) => PaymentMethodConfigModel.fromEntity(e))
          .toList(),
    );
  }

  PaymentMethodsConfig toEntity() {
    return PaymentMethodsConfig(
      paymentMethodsConfig:
          paymentMethodsConfig.map((e) => e.toEntity()).toList(),
    );
  }
}

List<Map<String, dynamic>>? _paymentMethodsConfigToJson(
        List<PaymentMethodConfigModel>? paymentMethodsConfig) =>
    paymentMethodsConfig?.map((e) => e.toJson()).toList();

@freezed
class PaymentMethodConfigModel with _$PaymentMethodConfigModel {
  const PaymentMethodConfigModel._();

  const factory PaymentMethodConfigModel({
    @JsonKey(name: 'payment_method_id') required int paymentMethodId,
    @JsonKey(name: 'branches_selected') required List<int> branchesSelected,
    @JsonKey(name: 'min_branch_priority', includeToJson: false) int? minBranchPriority,
  }) = _PaymentMethodConfigModel;

  factory PaymentMethodConfigModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodConfigModelFromJson(json);

  factory PaymentMethodConfigModel.fromEntity(PaymentMethodConfig entity) {
    return PaymentMethodConfigModel(
      paymentMethodId: entity.paymentMethodId,
      branchesSelected: entity.branchesSelected,
      minBranchPriority: entity.minBranchPriority,
    );
  }

  PaymentMethodConfig toEntity() {
    return PaymentMethodConfig(
      paymentMethodId: paymentMethodId,
      branchesSelected: branchesSelected,
      minBranchPriority: minBranchPriority,
    );
  }
}
