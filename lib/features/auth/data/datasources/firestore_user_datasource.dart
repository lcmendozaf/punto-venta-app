import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';

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

  @override
  Future<List<Company>> getCompaniesByEmail(String email) async {
    try {
      AppLogger.info('Firestore getCompaniesByEmail email=$email');
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
      AppLogger.error('Error al obtener empresas desde Firestore', e, stackTrace);
      throw Exception('Error al obtener empresas desde Firestore: $e');
    }
  }

  @override
  Future<String?> getEnterpriseLicenseBaseUrl(int enterpriseId) async {
    try {
      AppLogger.info('Firestore getEnterpriseLicenseBaseUrl id=$enterpriseId');
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
      AppLogger.error('Error al obtener PdvBaseUrl desde Firestore', e, stackTrace);
      throw Exception('Error al obtener PdvBaseUrl desde Firestore: $e');
    }
  }
}
