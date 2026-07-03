import 'package:freezed_annotation/freezed_annotation.dart';

enum SupportMessageKind {
  @JsonValue('text') text,
  @JsonValue('image') image,
  @JsonValue('video') video,
  @JsonValue('audio') audio,
  @JsonValue('document') document,
  @JsonValue('sticker') sticker,
  @JsonValue('location') location,
  @JsonValue('contacts') contacts,
  @JsonValue('unknown') unknown,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  received,
  error;

  static MessageStatus? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'received':
        return MessageStatus.received;
      case 'error':
      case 'failed':
        return MessageStatus.error;
      default:
        return null;
    }
  }
}
