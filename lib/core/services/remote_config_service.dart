import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigParams {
  static const String supportChatConfig = 'SUPPORT_CHAT_CONFIG';
}

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  RemoteConfigService();

  Future<void> fetchConfig() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      print('RemoteConfig fetch error: $e');
    }
  }

  /// Reads [RemoteConfigParams.supportChatConfig] and returns the parsed config,
  /// or null if the key is absent, malformed, or [enterpriseId] is not in [enterprises].
  Map<String, dynamic>? getSupportChatConfig(int enterpriseId) {
    final configString =
        _remoteConfig.getString(RemoteConfigParams.supportChatConfig);
    if (configString.isEmpty) return null;

    try {
      final Map<String, dynamic> config = jsonDecode(configString);
      final enterprises = (config['enterprises'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList();
      if (enterprises == null || !enterprises.contains(enterpriseId)) {
        return null;
      }
      return config;
    } catch (e) {
      print('Error parsing SUPPORT_CHAT_CONFIG: $e');
      return null;
    }
  }

  /// Returns whether the support chat is active for a given [enterpriseId].
  /// It checks if the config is not null and has a non-empty POS/deliveries API Key.
  bool isSupportChatActive(int enterpriseId) {
    final config = getSupportChatConfig(enterpriseId);
    if (config == null) return false;
    final apiKeys = config['apiKeys'];
    if (apiKeys is! Map) return false;
    final apiKey = apiKeys['pos'] ?? apiKeys['deliveries'];
    return apiKey is String && apiKey.isNotEmpty;
  }
}
