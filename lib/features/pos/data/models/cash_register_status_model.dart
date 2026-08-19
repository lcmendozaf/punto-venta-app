import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cash_register_status.dart';

part 'cash_register_status_model.freezed.dart';
part 'cash_register_status_model.g.dart';

@freezed
class CashRegisterStatusModel with _$CashRegisterStatusModel {
  const CashRegisterStatusModel._();

  const factory CashRegisterStatusModel({
    @JsonKey(name: 'status') required String status,
  }) = _CashRegisterStatusModel;

  factory CashRegisterStatusModel.fromJson(Map<String, dynamic> json) =>
      _$CashRegisterStatusModelFromJson(json);

  factory CashRegisterStatusModel.fromEntity(CashRegisterStatus entity) {
    return CashRegisterStatusModel(
      status: entity.status,
    );
  }

  CashRegisterStatus toEntity() {
    return CashRegisterStatus(
      status: status,
    );
  }
}
