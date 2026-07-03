import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:punto_venta_app/features/support_chat/data/models/support_message_model.dart';
import 'package:punto_venta_app/features/support_chat/data/models/support_message_insert_model.dart';

abstract class SupportChatRepository {
  Future<void> initialize({required String url, required String anonKey});
  Future<Session> loginOrRegister({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  });
  Future<List<SupportMessageModel>> fetchMessageHistory();
  Stream<List<SupportMessageModel>> getMessagesStream();
  Future<void> sendMessage(SupportMessageInsertModel message);
  Future<void> markMessagesAsRead();
  Future<void> uploadMedia({
    required String localPath,
    required String destinationPath,
    required String contentType,
  });
}
