import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:punto_venta_app/features/support_chat/data/models/upload_fcm_token_model.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/floating_chat_overlay.dart';
import 'package:punto_venta_app/core/services/notification_service.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Manejando un mensaje en segundo plano: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      debugPrint('PushNotificationService omitido (no es Android)');
      return;
    }
    if (_initialized) return;

    // Initialize local notifications service
    await NotificationService().initialize();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Mensaje en primer plano recibido: ${message.data}');

      final title = message.notification?.title?.toLowerCase() ?? '';
      final isSupportMessage = message.data['type'] == 'support_chat' ||
          message.data['isFromSupport'] == 'true' ||
          message.data['isFromSupport'] == true ||
          title.contains('soporte') ||
          title.contains('fletero') ||
          title.contains('mensaje') ||
          title.contains('keuken') ||
          message.data.isNotEmpty;

      if (isSupportMessage) {
        if (FloatingChatOverlay.isExpandedNotifier.value) {
          debugPrint('Chat de soporte abierto; omitiendo notificación local.');
          return;
        }

        final bodyText = message.notification?.body ??
            message.data['body'] ??
            message.data['message'] ??
            'Nuevo mensaje de soporte';

        NotificationService().showSupportMessageNotification(
          title: 'Keuken Supervisores',
          body: bodyText,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notificación abierta desde background: ${message.data}');
      _handleNotificationTap(message);
    });

    _messaging.onTokenRefresh.listen((token) async {
      debugPrint('FCM Token renovado: $token');
      await updateTokenInFirestore(token);
    });

    _initialized = true;
    debugPrint('PushNotificationService inicializado');
  }

  Future<void> registerDeviceToken() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token obtenido: $token');
        await updateTokenInFirestore(token);
      }
    } catch (e) {
      debugPrint('Error al registrar token de FCM: $e');
    }
  }

  Future<void> updateTokenInFirestore(String token) async {
    try {
      final authLocalDataSource = di.sl<AuthLocalDataSource>();
      final cachedUser = await authLocalDataSource.getCachedUser();
      final cachedEnterprise = await authLocalDataSource.getCachedEnterprise();

      final phoneNumber = cachedUser?.phoneNumber ?? '';
      final enterpriseId = cachedEnterprise?.id.toString() ?? '';
      final userId = cachedUser?.id ?? '';
      final userName = cachedUser?.name ?? '';

      if (enterpriseId.isEmpty || userId.isEmpty) {
        debugPrint(
            'No se pudo actualizar el token en Firestore: enterpriseId o userId vacíos');
        return;
      }

      final deviceOs =
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      const appCode = 'pos';

      final tokenModel = UploadFcmTokenModel(
        token: token,
        userId: userId,
        userName: userName.isNotEmpty ? userName : null,
        phone: phoneNumber.isNotEmpty ? phoneNumber : null,
        appCode: appCode,
        deviceOs: deviceOs,
        updatedAt: DateTime.now().toUtc(),
      );

      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(enterpriseId)
          .collection('users')
          .doc('$userId-$appCode')
          .set(tokenModel.toJson(), SetOptions(merge: true));

      debugPrint(
          'Token de FCM actualizado exitosamente en Firestore: fcm_tokens/$enterpriseId/users/$userId-$appCode');
    } catch (e) {
      debugPrint('Error al guardar token de FCM en Firestore: $e');
    }
  }

  Future<void> checkForInitialMessage() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
            'App abierta desde estado terminado vía notificación: ${initialMessage.data}');
        Future.delayed(const Duration(milliseconds: 1500), () {
          _handleNotificationTap(initialMessage);
        });
      }
    } catch (e) {
      debugPrint('Error al verificar mensaje inicial: $e');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final title = message.notification?.title?.toLowerCase() ?? '';
    final isSupport = message.data['type'] == 'support_chat' ||
        title.contains('soporte') ||
        title.contains('fletero') ||
        title.contains('mensaje') ||
        title.contains('keuken') ||
        message.data.isNotEmpty;

    if (isSupport) {
      FloatingChatOverlay.isExpandedNotifier.value = true;
    }
  }
}
