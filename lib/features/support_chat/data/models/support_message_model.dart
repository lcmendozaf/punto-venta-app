// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/core/utils/enums.dart';

part 'support_message_model.freezed.dart';
part 'support_message_model.g.dart';

@freezed
class SupportMessageModel with _$SupportMessageModel {
  const SupportMessageModel._();

  const factory SupportMessageModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'is_outbound') bool? direction,
    @JsonKey(name: 'media_kind') SupportMessageKind? kind,
    @JsonKey(name: 'timestamp') String? sentAt,
    @JsonKey(name: 'body') String? body,
    @JsonKey(name: 'media_url') String? mediaUrl,
    @JsonKey(name: 'media_thumb_url') String? mediaThumbUrl,
    @JsonKey(name: 'media_mime') String? mediaMime,
    @JsonKey(name: 'media_name') String? mediaName,
    @JsonKey(name: 'media_size_bytes') int? mediaSizeBytes,
    @JsonKey(name: 'media_storage_path') String? mediaStoragePath,
    @JsonKey(name: 'media_caption') String? mediaCaption,
    @JsonKey(name: 'whatsapp_id') String? whatsappId,
    @JsonKey(name: 'reactions') Map<String, String>? reactions,
    @JsonKey(name: 'status') String? status,
    @JsonKey(name: 'backendStatus') String? backendStatus,
    @JsonKey(name: 'sent_by_user_id') String? sentByUserId,
    @JsonKey(name: 'sent_by_display_name') String? sentByDisplayName,
    @JsonKey(name: 'replyToMessageId') int? replyToMessageId,
    @JsonKey(name: 'panelCommandId') String? panelCommandId,
    @JsonKey(name: 'commandLabel') String? commandLabel,
    @JsonKey(name: 'commandRunId') int? commandRunId,
    @JsonKey(name: 'responseSummary') String? responseSummary,
    @JsonKey(name: 'panelCommandStatus') String? panelCommandStatus,
    @JsonKey(name: 'commandTenantId') int? commandTenantId,
    @JsonKey(name: 'commandMobileUserId') int? commandMobileUserId,
    @JsonKey(name: 'ticketLifecycleEvent') String? ticketLifecycleEvent,
    @JsonKey(name: 'ticketId') int? ticketId,
    @JsonKey(name: 'ticketTitle') String? ticketTitle,
    @JsonKey(name: 'anchorMessageId') int? anchorMessageId,
    @JsonKey(name: 'ticketShareId') int? ticketShareId,
    @JsonKey(name: 'shareId') String? shareId,
  }) = _SupportMessageModel;

  factory SupportMessageModel.fromJson(Map<String, dynamic> json) =>
      _$SupportMessageModelFromJson(json);

  bool get isFromUser => direction != true;

  bool get hasMedia =>
      mediaUrl != null || mediaThumbUrl != null || mediaStoragePath != null;

  bool get isImageKind =>
      kind == SupportMessageKind.image || kind == SupportMessageKind.sticker;

  bool get isAudioKind =>
      kind == SupportMessageKind.audio ||
      (mediaMime?.startsWith('audio/') ?? false) ||
      (mediaStoragePath?.toLowerCase().endsWith('.mp3') ?? false) ||
      (mediaStoragePath?.toLowerCase().endsWith('.webm') ?? false) ||
      (mediaStoragePath?.toLowerCase().endsWith('.ogg') ?? false);

  MessageStatus? get messageStatus => MessageStatus.fromString(status);
}
