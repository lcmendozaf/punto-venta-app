import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/firebase_options.dart';

class Company {
  final int id;
  final String name;
  final String? baseUrl;
  final int? listPriceId;

  Company({
    required this.id,
    required this.name,
    this.baseUrl,
    this.listPriceId,
  });

  factory Company.fromFirestore(
    Map<String, dynamic> data,
  ) {
    final rawId = data['id'];
    AppLogger.info(
      'Company.fromFirestore keys=${data.keys.toList()} id=$rawId (${rawId.runtimeType}) name=${data['name']}',
    );
    return Company(
      id: rawId is int ? rawId : int.parse(rawId.toString()),
      name: data['name']?.toString() ?? '',
      baseUrl: data['baseUrl']?.toString(),
      listPriceId: data['listPriceId'] is int
          ? data['listPriceId'] as int
          : int.tryParse(data['listPriceId']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'listPriceId': listPriceId,
    };
  }
}

abstract class FirestoreUserDataSource {
  Future<List<Company>> getCompaniesByEmail(String email);
  Future<String?> getEnterpriseLicenseBaseUrl(int enterpriseId);
}

class FirestoreUserDataSourceImpl implements FirestoreUserDataSource {
  static const Duration _queryTimeout = Duration(seconds: 20);

  final FirebaseFirestore _firestore;

  FirestoreUserDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  Future<List<Company>> getCompaniesByEmail(String email) async {
    AppLogger.info('Firestore getCompaniesByEmail email=$email isWindows=$_isWindows');
    if (_isWindows) {
      return _getCompaniesByEmailRest(email);
    }

    try {
      // validar si el usuario está habilitado
      final userDoc = await _firestore
          .collection('usersEmail')
          .doc(email)
          .get()
          .timeout(_queryTimeout);
      AppLogger.info(
        'Firestore usersEmail exists=${userDoc.exists} fromCache=${userDoc.metadata.isFromCache}',
      );

      if (!userDoc.exists) {
        return [];
      }

      final userData = userDoc.data();
      final isEnabled = userData?['enabled'] ?? false;
      AppLogger.info('Firestore usersEmail enabled=$isEnabled');

      if (!isEnabled) {
        throw Exception(
            'Usuario no habilitado. Por favor contacta al administrador.');
      }

      // Si está habilitado, obtener las empresas
      AppLogger.info('Firestore leyendo subcolección enterprises...');
      final enterprisesSnapshot = await _firestore
          .collection('usersEmail')
          .doc(email)
          .collection('enterprises')
          .get()
          .timeout(_queryTimeout);

      if (enterprisesSnapshot.docs.isEmpty) {
        AppLogger.warn('Firestore: sin empresas para $email');
        return [];
      }

      AppLogger.info(
        'Firestore: ${enterprisesSnapshot.docs.length} empresa(s) para $email',
      );
      return enterprisesSnapshot.docs.map((doc) {
        return Company.fromFirestore(doc.data());
      }).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error al obtener empresas desde Firestore Nativo, intentando REST...', e, stackTrace);
      return _getCompaniesByEmailRest(email);
    }
  }

  @override
  Future<String?> getEnterpriseLicenseBaseUrl(int enterpriseId) async {
    AppLogger.info('Firestore getEnterpriseLicenseBaseUrl id=$enterpriseId isWindows=$_isWindows');
    if (_isWindows) {
      return _getEnterpriseLicenseBaseUrlRest(enterpriseId);
    }

    try {
      final licenseDoc = await _firestore
          .collection('enterprisesLicense')
          .doc(enterpriseId.toString())
          .get()
          .timeout(_queryTimeout);

      if (!licenseDoc.exists) {
        return null;
      }

      final data = licenseDoc.data();
      return data?['pointOfSaleUrl']?.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Error al obtener PdvBaseUrl desde Firestore Nativo, intentando REST...', e, stackTrace);
      return _getEnterpriseLicenseBaseUrlRest(enterpriseId);
    }
  }

  /// Obtiene un token anónimo REST de Firebase Auth para llamadas REST a Firestore.
  Future<String?> _getAuthToken() async {
    try {
      final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
      final response = await http.post(
        Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'returnSecureToken': true}),
      ).timeout(_queryTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['idToken'] as String?;
      } else {
        AppLogger.warn('Firebase Auth REST signup código status=${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('Error al obtener REST ID Token de Firebase', e, stack);
    }
    return null;
  }

  /// Parsea los campos formateados del documento REST de Firestore a un Map llaves-valores estándar.
  Map<String, dynamic> _parseFirestoreRestFields(Map<String, dynamic>? fields) {
    if (fields == null) return {};
    final result = <String, dynamic>{};
    fields.forEach((key, valMap) {
      if (valMap is Map<String, dynamic>) {
        if (valMap.containsKey('stringValue')) {
          result[key] = valMap['stringValue'];
        } else if (valMap.containsKey('integerValue')) {
          result[key] = int.tryParse(valMap['integerValue'].toString()) ?? 0;
        } else if (valMap.containsKey('doubleValue')) {
          result[key] = double.tryParse(valMap['doubleValue'].toString()) ?? 0.0;
        } else if (valMap.containsKey('booleanValue')) {
          result[key] = valMap['booleanValue'];
        } else if (valMap.containsKey('nullValue')) {
          result[key] = null;
        } else if (valMap.containsKey('mapValue')) {
          final subMap = (valMap['mapValue'] as Map<String, dynamic>)['fields'] as Map<String, dynamic>?;
          result[key] = _parseFirestoreRestFields(subMap);
        }
      }
    });
    return result;
  }

  Future<List<Company>> _getCompaniesByEmailRest(String email) async {
    try {
      AppLogger.info('Firestore REST getCompaniesByEmail email=$email');
      final token = await _getAuthToken();
      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
      final userUri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/usersEmail/$email',
      );

      final userResponse = await http.get(userUri, headers: headers).timeout(_queryTimeout);
      AppLogger.info('Firestore REST usersEmail statusCode=${userResponse.statusCode}');

      if (userResponse.statusCode == 404) {
        return [];
      }

      if (userResponse.statusCode != 200) {
        throw Exception('HTTP ${userResponse.statusCode}: ${userResponse.body}');
      }

      final userJson = json.decode(userResponse.body) as Map<String, dynamic>;
      final userFields = _parseFirestoreRestFields(userJson['fields'] as Map<String, dynamic>?);
      final isEnabled = userFields['enabled'] == true;
      AppLogger.info('Firestore REST usersEmail enabled=$isEnabled');

      if (!isEnabled) {
        throw Exception('Usuario no habilitado. Por favor contacta al administrador.');
      }

      final enterprisesUri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/usersEmail/$email/enterprises',
      );

      final entResponse = await http.get(enterprisesUri, headers: headers).timeout(_queryTimeout);
      AppLogger.info('Firestore REST enterprises statusCode=${entResponse.statusCode}');

      if (entResponse.statusCode != 200) {
        AppLogger.warn('Firestore REST: sin empresas para $email');
        return [];
      }

      final entJson = json.decode(entResponse.body) as Map<String, dynamic>;
      final docs = entJson['documents'] as List<dynamic>? ?? [];

      if (docs.isEmpty) {
        AppLogger.warn('Firestore REST: array de empresas vacío para $email');
        return [];
      }

      AppLogger.info('Firestore REST: ${docs.length} empresa(s) para $email');
      return docs.map((docItem) {
        final docMap = docItem as Map<String, dynamic>;
        final fields = _parseFirestoreRestFields(docMap['fields'] as Map<String, dynamic>?);
        return Company.fromFirestore(fields);
      }).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error al obtener empresas via Firestore REST', e, stackTrace);
      throw Exception('Error al obtener empresas desde Firestore: $e');
    }
  }

  Future<String?> _getEnterpriseLicenseBaseUrlRest(int enterpriseId) async {
    try {
      AppLogger.info('Firestore REST getEnterpriseLicenseBaseUrl id=$enterpriseId');
      final token = await _getAuthToken();
      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
      final uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/enterprisesLicense/$enterpriseId',
      );

      final response = await http.get(uri, headers: headers).timeout(_queryTimeout);
      AppLogger.info('Firestore REST enterprisesLicense statusCode=${response.statusCode}');

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final fields = _parseFirestoreRestFields(data['fields'] as Map<String, dynamic>?);
      return fields['pointOfSaleUrl']?.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Error al obtener PdvBaseUrl via Firestore REST', e, stackTrace);
      throw Exception('Error al obtener PdvBaseUrl desde Firestore: $e');
    }
  }
}

