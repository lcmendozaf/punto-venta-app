import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'upload_fcm_token_model.freezed.dart';
part 'upload_fcm_token_model.g.dart';

Timestamp _timestampToJson(DateTime date) => Timestamp.fromDate(date);
DateTime _timestampFromJson(Timestamp timestamp) => timestamp.toDate();

@freezed
class UploadFcmTokenModel with _$UploadFcmTokenModel {
  const factory UploadFcmTokenModel({
    @JsonKey(name: 'token') required String token,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'user_name') String? userName,
    @JsonKey(name: 'phone') String? phone,
    @JsonKey(name: 'app_code') required String appCode,
    @JsonKey(name: 'device_os') required String deviceOs,
    @JsonKey(
      name: 'updated_at',
      fromJson: _timestampFromJson,
      toJson: _timestampToJson,
    )
    required DateTime updatedAt,
  }) = _UploadFcmTokenModel;

  factory UploadFcmTokenModel.fromJson(Map<String, dynamic> json) =>
      _$UploadFcmTokenModelFromJson(json);
}
