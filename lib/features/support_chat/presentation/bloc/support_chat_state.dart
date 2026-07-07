import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/features/support_chat/data/models/support_message_model.dart';

part 'support_chat_state.freezed.dart';

@freezed
class SupportChatState with _$SupportChatState {
  const factory SupportChatState({
    required MessagesState messagesState,
    required SendMessageState sendState,
    @Default([]) List<SupportMessageModel> messages,
    String? pendingImagePath,
  }) = _SupportChatState;

  factory SupportChatState.initial() => const SupportChatState(
        messagesState: MessagesState.initial(),
        sendState: SendMessageState.idle(),
      );
}

@freezed
class MessagesState with _$MessagesState {
  const factory MessagesState.initial() = MessagesInitial;
  const factory MessagesState.loading() = MessagesLoading;
  const factory MessagesState.loaded(List<SupportMessageModel> messages) =
      MessagesLoaded;
  const factory MessagesState.error(String message) = MessagesError;
  const factory MessagesState.needsPhoneNumber() = MessagesNeedsPhoneNumber;
}

@freezed
class SendMessageState with _$SendMessageState {
  const factory SendMessageState.idle() = SendIdle;
  const factory SendMessageState.sending() = SendSending;
  const factory SendMessageState.sent() = SendSent;
  const factory SendMessageState.error(String message) = SendError;
}
