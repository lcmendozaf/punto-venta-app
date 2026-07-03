import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/features/support_chat/data/models/support_message_model.dart';

part 'support_chat_event.freezed.dart';

@freezed
class SupportChatEvent with _$SupportChatEvent {
  const factory SupportChatEvent.loadMessages() = LoadMessages;

  const factory SupportChatEvent.sendMessage({
    required String text,
    String? imagePath,
  }) = SendMessage;

  const factory SupportChatEvent.pickImage() = PickImage;

  const factory SupportChatEvent.setPendingImage(String path) = SetPendingImage;

  const factory SupportChatEvent.clearImagePreview() = ClearImagePreview;

  const factory SupportChatEvent.messageReceived(
    SupportMessageModel message,
  ) = MessageReceived;

  const factory SupportChatEvent.messagesUpdated(
    List<SupportMessageModel> messages,
  ) = MessagesUpdated;
}
