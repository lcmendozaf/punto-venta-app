import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:punto_venta_app/features/support_chat/data/models/support_message_model.dart';
import 'package:punto_venta_app/features/support_chat/data/models/support_message_insert_model.dart';
import 'package:punto_venta_app/features/support_chat/domain/repositories/support_chat_repository.dart';

class SupportChatRepositoryImpl implements SupportChatRepository {
  static bool _initialized = false;

  /// Initializes the Supabase client. Prevents double initialization.
  @override
  Future<void> initialize({required String url, required String anonKey}) async {
    if (_initialized) return;
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    _initialized = true;
  }

  SupabaseClient get _client => Supabase.instance.client;

  /// Performs sign in or registers the user in Supabase Auth if the user doesn't exist yet.
  @override
  Future<Session> loginOrRegister({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res.session!;
    } on AuthException {
      // If user does not exist, sign up
      await _client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
      // Re-sign in to establish session
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res.session!;
    }
  }

  /// Fetches historical messages from whatsapp_messages table.
  @override
  Future<List<SupportMessageModel>> fetchMessageHistory() async {
    try {
      final List<dynamic> response = await _client
          .from('whatsapp_messages')
          .select('id, body, timestamp, is_outbound, status, sender_phone, media_kind, media_mime, media_storage_path, media_caption, sent_by_display_name')
          .order('timestamp', ascending: false)
          .limit(100);

      final List<Map<String, dynamic>> list = response
          .map((json) => Map<String, dynamic>.from(json as Map))
          .toList();

      final List<Future<void>> signFutures = [];
      for (final map in list) {
        final path = map['media_storage_path'] as String?;
        if (map['media_kind'] != 'text' && path != null && path.isNotEmpty) {
          signFutures.add(() async {
            try {
              final signedUrl = await _client.storage
                  .from('whatsapp-media')
                  .createSignedUrl(path, 3600);
              map['media_url'] = signedUrl;
            } catch (e) {
              debugPrint('Error signing URL for $path: $e');
            }
          }());
        }
      }
      await Future.wait(signFutures);

      return list
          .map((json) => SupportMessageModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener el historial de mensajes: $e');
    }
  }

  /// Returns a stream of real-time message changes.
  @override
  Stream<List<SupportMessageModel>> getMessagesStream() {
    return _client
        .from('whatsapp_messages')
        .stream(primaryKey: ['id'])
        .order('timestamp', ascending: false)
        .asyncMap((List<Map<String, dynamic>> maps) async {
          final List<Map<String, dynamic>> list = maps
              .map((json) => Map<String, dynamic>.from(json))
              .toList();

          final List<Future<void>> signFutures = [];
          for (final map in list) {
            final path = map['media_storage_path'] as String?;
            if (map['media_kind'] != 'text' && path != null && path.isNotEmpty) {
              signFutures.add(() async {
                try {
                  final signedUrl = await _client.storage
                      .from('whatsapp-media')
                      .createSignedUrl(path, 3600);
                  map['media_url'] = signedUrl;
                } catch (e) {
                  debugPrint('Error signing URL for stream path $path: $e');
                }
              }());
            }
          }
          await Future.wait(signFutures);

          return list
              .map((json) => SupportMessageModel.fromJson(json))
              .toList();
        });
  }

  /// Sends a message by inserting it into whatsapp_messages table.
  @override
  Future<void> sendMessage(SupportMessageInsertModel message) async {
    try {
      await _client
          .from('whatsapp_messages')
          .insert(message.toJson());
    } catch (e) {
      throw Exception('Error al enviar el mensaje: $e');
    }
  }

  /// Marks all incoming support messages (is_outbound = true) as read.
  @override
  Future<void> markMessagesAsRead() async {
    try {
      await _client
          .from('whatsapp_messages')
          .update({'status': 'read'})
          .eq('is_outbound', true)
          .neq('status', 'read');
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Uploads media binary to whatsapp-media bucket.
  @override
  Future<void> uploadMedia({
    required String localPath,
    required String destinationPath,
    required String contentType,
  }) async {
    try {
      final file = File(localPath);
      final bytes = await file.readAsBytes();

      await _client.storage
          .from('whatsapp-media')
          .uploadBinary(
            destinationPath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false,
            ),
          );
    } catch (e) {
      throw Exception('Error al subir el archivo multimedia: $e');
    }
  }
}
