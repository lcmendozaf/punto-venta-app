import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RemoteConfigParams {
  static const String supportChatConfig = 'SUPPORT_CHAT_CONFIG';
}

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  final Map<String, String> _customRemoteValues = {};

  RemoteConfigService();

  Future<void> fetchConfig() async {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      await _fetchViaRest();
      return;
    }

    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: const Duration(seconds: 10),
      ));
      await _remoteConfig.fetch();
      await _remoteConfig.activate();
    } catch (e) {
      await _fetchViaRest();
    }
  }

  Future<void> _fetchViaRest() async {
    const projectId = 'keuken-mobile-fc114';
    const apiKey = 'AIzaSyB2bJ_35OLULPe3b8eyAlmUmuEBMMLpUFo';
    const appId = '1:532336033127:web:53b958f025628a4e1d03c2';

    try {
      final installationsUri = Uri.parse(
        'https://firebaseinstallations.googleapis.com/v1/projects/$projectId/installations',
      );
      final instResponse = await http.post(
        installationsUri,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: jsonEncode({
          'appId': appId,
          'sdkVersion': 't:1',
        }),
      );

      if (instResponse.statusCode != 200 && instResponse.statusCode != 201) {
        throw Exception(
            'Error al registrar instalación REST: ${instResponse.statusCode}');
      }

      final instData = jsonDecode(instResponse.body);
      final fid = instData['fid'];
      final token = instData['authToken']['token'];

      final remoteConfigUri = Uri.parse(
        'https://firebaseremoteconfig.googleapis.com/v1/projects/$projectId/namespaces/firebase:fetch?key=$apiKey',
      );

      final rcResponse = await http.post(
        remoteConfigUri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Firebase-Installations-Auth': token,
        },
        body: jsonEncode({
          'appId': appId,
          'appInstanceId': fid,
          'sdkVersion': 'web:10.0.0',
        }),
      );

      if (rcResponse.statusCode == 200) {
        final rcData = jsonDecode(rcResponse.body);
        final entries = rcData['entries'] as Map<String, dynamic>?;
        if (entries != null) {
          entries.forEach((key, value) {
            _customRemoteValues[key] = value.toString();
          });
        }
      } else {
        throw Exception('Error al hacer fetch REST: ${rcResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('RemoteConfig Fallback REST error: $e');
    }
  }

  String _getString(String key) {
    if (_customRemoteValues.containsKey(key)) {
      return _customRemoteValues[key]!;
    }
    return _remoteConfig.getString(key);
  }

  /// Reads [RemoteConfigParams.supportChatConfig] and returns the parsed config,
  /// or null if the key is absent, malformed, or [enterpriseId] is not in [enterprises].
  Map<String, dynamic>? getSupportChatConfig(int enterpriseId) {
    final configString = _getString(RemoteConfigParams.supportChatConfig);
    debugPrint('SUPPORT_CHAT_CONFIG raw string: "$configString"');
    if (configString.isEmpty) {
      debugPrint('SUPPORT_CHAT_CONFIG string is empty.');
      return null;
    }

    try {
      final Map<String, dynamic> config = jsonDecode(configString);
      final enterprises = (config['enterprises'] as List<dynamic>?)
              ?.map((e) => int.tryParse(e.toString()) ?? -1)
              .where((e) => e != -1)
              .toList() ??
          [];

      debugPrint(
          'Parsed enterprises: $enterprises, looking for: $enterpriseId');
      if (!enterprises.contains(enterpriseId)) {
        debugPrint(
            'Enterprise ID $enterpriseId not found in enterprises list.');
        return null;
      }
      return config;
    } catch (e) {
      debugPrint('Error parsing SUPPORT_CHAT_CONFIG: $e');
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
    // Support all variants of keys in the json config
    final apiKey = apiKeys['pos'];
    return apiKey is String && apiKey.isNotEmpty;
  }
}
