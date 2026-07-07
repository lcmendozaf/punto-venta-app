import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/auth/data/datasources/google_auth_datasource.dart';
import 'package:punto_venta_app/features/auth/data/datasources/firestore_user_datasource.dart';
import 'package:punto_venta_app/features/auth/data/datasources/user_api_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_local_datasource.dart';
import 'package:punto_venta_app/features/auth/data/models/enterprise_model.dart';
import 'package:punto_venta_app/features/auth/data/models/user_model.dart';
import 'package:punto_venta_app/features/auth/domain/entities/user.dart';
import 'package:punto_venta_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final GoogleAuthDataSource googleAuthDataSource;
  final FirestoreUserDataSource firestoreUserDataSource;
  final UserApiDataSource userApiDataSource;
  final PriceListLocalDataSource priceListLocalDataSource;

  AuthRepositoryImpl({
    required this.localDataSource,
    required this.googleAuthDataSource,
    required this.firestoreUserDataSource,
    required this.userApiDataSource,
    required this.priceListLocalDataSource,
  });

  @override
  Future<Map<String, dynamic>> loginWithGoogle() async {
    final googleEmail = await googleAuthDataSource.signInWithGoogle();

    if (googleEmail == null) {
      throw Exception('Inicio de sesión cancelado');
    }

    if (googleEmail.isEmpty) {
      throw Exception('No se pudo obtener el email del usuario');
    }

    try {
      final companies =
          await firestoreUserDataSource.getCompaniesByEmail(googleEmail);

      if (companies.isEmpty) {
        await googleAuthDataSource.signOut();
        throw Exception(
            'No hay empresas vinculadas a este correo. Por favor contacta al administrador.');
      }

      return {
        'email': googleEmail,
        'companies': companies.map((c) => c.toMap()).toList(),
        'autoSelected': companies.length == 1,
      };
    } catch (e) {
      await googleAuthDataSource.signOut();
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> loginWithEmail(String email) async {
    if (email.isEmpty) {
      throw Exception('El email no puede estar vacío');
    }

    try {
      final companies =
          await firestoreUserDataSource.getCompaniesByEmail(email);

      if (companies.isEmpty) {
        throw Exception(
            'No hay empresas vinculadas a este correo. Por favor contacta al administrador.');
      }

      return {
        'email': email,
        'companies': companies.map((c) => c.toMap()).toList(),
        'autoSelected': companies.length == 1,
      };
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> selectCompany(
      String email, int companyId) async {
    final companies = await firestoreUserDataSource.getCompaniesByEmail(email);

    final selectedCompany = companies.firstWhere(
      (c) => c.id.toString() == companyId.toString(),
      orElse: () => throw Exception('Empresa no encontrada'),
    );

    // Obtener PdvBaseUrl desde enterprisesLicense
    final pdvBaseUrl = await firestoreUserDataSource
        .getEnterpriseLicenseBaseUrl(selectedCompany.id);

    ApiConfig.updateCompanyConfig(
      selectedCompany.id.toString(),
      pdvBaseUrl ?? selectedCompany.baseUrl,
    );

    final enterpriseModel = EnterpriseModel(
      id: selectedCompany.id,
      name: selectedCompany.name,
      baseUrl: pdvBaseUrl ?? selectedCompany.baseUrl,
      listPriceId: selectedCompany.listPriceId,
    );

    await localDataSource.cacheEnterprise(enterpriseModel);
    await localDataSource.cacheEmail(email);
    await priceListLocalDataSource.savePriceList(1);
    // await priceListLocalDataSource
    //     .savePriceList(selectedCompany.listPriceId ?? 0);

    return {
      'email': email,
      'companyId': companyId,
      'companyName': selectedCompany.name,
      'listPriceId': 1,
      // 'listPriceId': selectedCompany.listPriceId,
    };
  }

  @override
  Future<User> authenticateUser(
    String userId,
    String password,
  ) async {
    final authData = await userApiDataSource.authenticateUser(userId, password);

    final token = authData['token'] as String;
    final userData = authData['user'] as Map<String, dynamic>;

    final user = User(
      id: userData['id']?.toString() ?? '',
      name: userData['name']?.toString() ?? '',
      password: userData['password']?.toString() ?? '',
      tipo: userData['role']?.toString() ?? '',
      isActive: userData['is_active'] ?? true,
      phoneNumber: userData['phone_number']?.toString() ?? '',
    );

    final userModel = UserModel.fromEntity(user);

    await localDataSource.cacheUser(userModel);
    await localDataSource.cacheToken(token);

    return user;
  }

  @override
  Future<void> logout() async {
    await googleAuthDataSource.signOut();
    await localDataSource.logout();
    await localDataSource.clearEnterprise();
    await localDataSource.clearEmail();
    await priceListLocalDataSource.clearPriceList();
    ApiConfig.resetCompanyId();
  }

  @override
  Future<void> changeCashier() async {
    await localDataSource.logout();
  }

  @override
  Future<User?> getCurrentUser() async {
    final userModel = await localDataSource.getCachedUser();
    return userModel?.toEntity();
  }

  @override
  Future<bool> isLoggedIn() async {
    final user = await localDataSource.getCachedUser();
    return user != null;
  }
}
