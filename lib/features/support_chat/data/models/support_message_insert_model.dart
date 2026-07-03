// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'support_message_insert_model.freezed.dart';
part 'support_message_insert_model.g.dart';

@freezed
class SupportMessageInsertModel with _$SupportMessageInsertModel {
  const factory SupportMessageInsertModel({
    @JsonKey(name: 'body') String? body,
    @JsonKey(name: 'message_channel') @Default('') String messageChannel,
    @JsonKey(name: 'source_app') @Default('') String sourceApp,
    @JsonKey(name: 'sender_phone') @Default('') String senderPhone,
    @JsonKey(name: 'is_outbound') @Default(false) bool isOutbound,
    @JsonKey(name: 'status') required String status,
    @JsonKey(name: 'timestamp') required String timestamp,
    @JsonKey(name: 'whatsapp_id') @Default('') String whatsappId,
    @JsonKey(name: 'media_kind') String? mediaKind,
    @JsonKey(name: 'media_mime') String? mediaMime,
    @JsonKey(name: 'media_storage_path') String? mediaStoragePath,
    @JsonKey(name: 'media_caption') String? mediaCaption,
    @JsonKey(name: 'media_size_bytes') int? mediaSizeBytes,
  }) = _SupportMessageInsertModel;

  factory SupportMessageInsertModel.fromJson(Map<String, dynamic> json) =>
      _$SupportMessageInsertModelFromJson(json);
}
