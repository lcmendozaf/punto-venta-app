import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/support_chat/data/models/support_message_model.dart';
import 'package:punto_venta_app/features/support_chat/data/models/support_message_insert_model.dart';
import 'package:punto_venta_app/features/support_chat/presentation/bloc/support_chat_event.dart';
import 'package:punto_venta_app/features/support_chat/presentation/bloc/support_chat_state.dart';
import 'package:punto_venta_app/features/support_chat/domain/repositories/support_chat_repository.dart';
import 'package:punto_venta_app/core/services/remote_config_service.dart';
import 'package:punto_venta_app/core/services/push_notification_service.dart';
import 'package:punto_venta_app/core/utils/error_parser.dart';

export 'support_chat_event.dart';
export 'support_chat_state.dart';

class SupportChatBloc extends Bloc<SupportChatEvent, SupportChatState> {
  final SupportChatRepository _repository;
  final AuthLocalDataSource _authLocalDataSource;
  final RemoteConfigService _remoteConfigService;
  final PushNotificationService _pushNotificationService;
  StreamSubscription<List<SupportMessageModel>>? _messageSubscription;

  SupportChatBloc({
    required SupportChatRepository repository,
    required AuthLocalDataSource authLocalDataSource,
    required RemoteConfigService remoteConfigService,
    required PushNotificationService pushNotificationService,
  })  : _repository = repository,
        _authLocalDataSource = authLocalDataSource,
        _remoteConfigService = remoteConfigService,
        _pushNotificationService = pushNotificationService,
        super(SupportChatState.initial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<PickImage>(_onPickImage);
    on<SetPendingImage>(_onSetPendingImage);
    on<ClearImagePreview>(_onClearImagePreview);
    on<MessageReceived>(_onMessageReceived);
    on<MessagesUpdated>(_onMessagesUpdated);
    on<SubmitPhoneNumber>(_onSubmitPhoneNumber);
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }

  void _onMessagesUpdated(
    MessagesUpdated event,
    Emitter<SupportChatState> emit,
  ) {
    emit(state.copyWith(
      messages: event.messages,
      messagesState: MessagesState.loaded(event.messages),
    ));
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<SupportChatState> emit,
  ) async {
    emit(state.copyWith(messagesState: const MessagesState.loading()));

    try {
      final cachedEnterprise = await _authLocalDataSource.getCachedEnterprise();
      final enterpriseId = cachedEnterprise?.id ?? -1;
      final enterpriseIdStr = enterpriseId.toString();

      debugPrint(
          'SupportChatBloc: Loading messages for enterpriseId: $enterpriseId');

      final config = _remoteConfigService.getSupportChatConfig(enterpriseId);
      if (config == null) {
        debugPrint(
            'SupportChatBloc: SUPPORT_CHAT_CONFIG config is null for enterpriseId: $enterpriseId');
        emit(state.copyWith(
          messagesState: const MessagesState.error(
              "El chat de soporte no está habilitado para esta empresa."),
        ));
        return;
      }

      final baseUrl = config['baseUrl'] as String?;
      final apiKeys = config['apiKeys'];
      String? apiKey;
      if (apiKeys is Map) {
        apiKey = (apiKeys['pos']) as String?;
      }

      debugPrint('SupportChatBloc: baseUrl is "$baseUrl", apiKey is "$apiKey"');

      if (baseUrl == null ||
          apiKey == null ||
          baseUrl.isEmpty ||
          apiKey.isEmpty) {
        emit(state.copyWith(
          messagesState:
              const MessagesState.error("Configuración de servidor no válida."),
        ));
        return;
      }

      // Initialize Supabase
      debugPrint('SupportChatBloc: Initializing Supabase...');
      await _repository.initialize(url: baseUrl, anonKey: apiKey);

      final cachedUser = await _authLocalDataSource.getCachedUser();
      final cachedEmail = await _authLocalDataSource.getCachedEmail();
      final userId = cachedUser?.id ?? '';
      final userName = cachedUser?.name ?? '';
      final phoneNumber = cachedUser?.phoneNumber ?? '';
      var cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');

      if (userId.isEmpty) {
        emit(state.copyWith(
          messagesState: const MessagesState.error(
              "No se pudo obtener información del usuario."),
        ));
        return;
      }

      if (cleanPhone.isEmpty) {
        emit(state.copyWith(
          messagesState: const MessagesState.needsPhoneNumber(),
        ));
        return;
      }

      // Metadata for signup/login
      final metadata = {
        'actor': 'ecosystem',
        'app_code': 'pos',
        'enterprise_code': enterpriseIdStr,
        'user_id': userId,
        'thread_phone': cleanPhone,
        'display_name': userName.isEmpty ? 'Cajero' : userName,
        'full_name': userName.isEmpty ? 'Cajero' : userName,
      };

      // Authenticate
      final email = cachedEmail ?? 'pos$userId@$enterpriseIdStr.com';
      const password = 'keuken8761';
      await _repository.loginOrRegister(
        email: email,
        password: password,
        metadata: metadata,
      );

      final history = await _repository.fetchMessageHistory();
      emit(state.copyWith(
        messages: history,
        messagesState: MessagesState.loaded(history),
      ));

      _repository.markMessagesAsRead();

      await _messageSubscription?.cancel();
      _messageSubscription = _repository.getMessagesStream().listen(
        (messages) {
          add(MessagesUpdated(messages));

          final hasUnreadSupport = messages.any(
            (m) => m.direction == true && m.status != 'read',
          );
          if (hasUnreadSupport) {
            _repository.markMessagesAsRead();
          }
        },
        onError: (error) {},
      );
    } catch (e) {
      emit(state.copyWith(
        messagesState: MessagesState.error(ErrorParser.getCleanErrorMessage(e)),
      ));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<SupportChatState> emit,
  ) async {
    if (event.text.trim().isEmpty && event.imagePath == null) return;

    emit(state.copyWith(
      sendState: const SendMessageState.sending(),
      pendingImagePath: null,
    ));

    try {
      final cachedEnterprise = await _authLocalDataSource.getCachedEnterprise();
      final enterpriseIdStr = (cachedEnterprise?.id ?? -1).toString();

      final cachedUser = await _authLocalDataSource.getCachedUser();
      final phoneNumber = cachedUser?.phoneNumber ?? '';
      var cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');

      final clientMessageId = const Uuid().v4();

      String? relativeStoragePath;
      String? ext;
      int? mediaSizeBytes;
      if (event.imagePath != null) {
        ext = event.imagePath!.substring(event.imagePath!.lastIndexOf('.'));
        relativeStoragePath =
            'integration/$enterpriseIdStr/pos/$cleanPhone/$clientMessageId$ext';

        final mime = ext.toLowerCase() == '.png' ? 'image/png' : 'image/jpeg';
        await _repository.uploadMedia(
          localPath: event.imagePath!,
          destinationPath: relativeStoragePath,
          contentType: mime,
        );

        try {
          mediaSizeBytes = await File(event.imagePath!).length();
        } catch (_) {}
      }

      final insertMsg = SupportMessageInsertModel(
        body: event.text.trim().isEmpty ? null : event.text.trim(),
        messageChannel: 'integration',
        sourceApp: 'pos',
        senderPhone: cleanPhone,
        isOutbound: false,
        status: 'received',
        timestamp: DateTime.now().toUtc().toIso8601String(),
        mediaKind: event.imagePath != null ? 'image' : 'text',
        mediaStoragePath: relativeStoragePath,
        mediaMime: event.imagePath != null
            ? (ext?.toLowerCase() == '.png' ? 'image/png' : 'image/jpeg')
            : null,
        mediaSizeBytes: mediaSizeBytes,
        whatsappId: 'integration:$enterpriseIdStr:pos:$clientMessageId',
      );

      await _repository.sendMessage(insertMsg);

      emit(state.copyWith(sendState: const SendMessageState.sent()));
      await Future.delayed(const Duration(milliseconds: 200));
      emit(state.copyWith(sendState: const SendMessageState.idle()));
    } catch (e) {
      emit(state.copyWith(
          sendState:
              SendMessageState.error(ErrorParser.getCleanErrorMessage(e))));
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(sendState: const SendMessageState.idle()));
    }
  }

  void _onPickImage(
    PickImage event,
    Emitter<SupportChatState> emit,
  ) {}

  void _onSetPendingImage(
    SetPendingImage event,
    Emitter<SupportChatState> emit,
  ) {
    emit(state.copyWith(pendingImagePath: event.path));
  }

  void _onClearImagePreview(
    ClearImagePreview event,
    Emitter<SupportChatState> emit,
  ) {
    emit(state.copyWith(pendingImagePath: null));
  }

  void _onMessageReceived(
    MessageReceived event,
    Emitter<SupportChatState> emit,
  ) {
    final updated = [event.message, ...state.messages];
    emit(state.copyWith(
      messages: updated,
      messagesState: MessagesState.loaded(updated),
    ));
  }

  Future<void> _onSubmitPhoneNumber(
    SubmitPhoneNumber event,
    Emitter<SupportChatState> emit,
  ) async {
    emit(state.copyWith(messagesState: const MessagesState.loading()));
    try {
      final cleanPhone = event.phoneNumber.replaceAll(RegExp(r'\D'), '');
      await _authLocalDataSource.updateCachedUserPhoneNumber(cleanPhone);

      try {
        await _pushNotificationService.registerDeviceToken();
      } catch (e) {
        debugPrint('Error al registrar token de push al guardar teléfono: $e');
      }

      add(const LoadMessages());
    } catch (e) {
      emit(state.copyWith(
        messagesState: MessagesState.error(ErrorParser.getCleanErrorMessage(e)),
      ));
    }
  }
}
