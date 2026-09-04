import 'package:freezed_annotation/freezed_annotation.dart';

part 'partial_return_request_model.freezed.dart';
part 'partial_return_request_model.g.dart';

@freezed
class PartialReturnRequestModel with _$PartialReturnRequestModel {
  @JsonSerializable(explicitToJson: true)
  const factory PartialReturnRequestModel({
    @JsonKey(name: 'reason_id') required int reasonId,
    @JsonKey(name: 'branch_id') required int branchId,
    @JsonKey(name: 'delivery_location_id') required int deliveryLocationId,
    @JsonKey(name: 'items', toJson: _itemsToJson)
    required List<PartialReturnItemModel> items,
  }) = _PartialReturnRequestModel;

  factory PartialReturnRequestModel.fromJson(Map<String, dynamic> json) =>
      _$PartialReturnRequestModelFromJson(json);
}

List<Map<String, dynamic>>? _itemsToJson(List<PartialReturnItemModel>? items) =>
    items?.map((e) => e.toJson()).toList();

@freezed
class PartialReturnItemModel with _$PartialReturnItemModel {
  const factory PartialReturnItemModel({
    @JsonKey(name: 'article_id') required int articleId,
    @JsonKey(name: 'quantity') required double quantity,
    @JsonKey(name: 'is_weighted') String? isWeighted,
    @JsonKey(name: 'net_weight') double? netWeight,
    @JsonKey(name: 'weight') double? weight,
  }) = _PartialReturnItemModel;

  factory PartialReturnItemModel.fromJson(Map<String, dynamic> json) =>
      _$PartialReturnItemModelFromJson(json);
}
