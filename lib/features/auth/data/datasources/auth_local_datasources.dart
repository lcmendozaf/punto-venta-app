import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/enterprise_model.dart';
import 'dart:convert';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> cacheToken(String token);
  Future<String?> getToken();
  Future<void> cacheEnterprise(EnterpriseModel enterprise);
  Future<EnterpriseModel?> getCachedEnterprise();
  Future<void> cacheEmail(String email);
  Future<String?> getCachedEmail();
  Future<void> logout();
  Future<void> clearEnterprise();
  Future<void> clearEmail();
  Future<void> updateCachedUserPhoneNumber(String phoneNumber);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const cachedUserKey = 'CACHED_USER';
  static const cachedTokenKey = 'CACHED_TOKEN';
  static const cachedEnterpriseKey = 'CACHED_ENTERPRISE';
  static const cachedEmailKey = 'CACHED_EMAIL';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheUser(UserModel user) async {
    final jsonString = jsonEncode(user.toJson());
    await sharedPreferences.setString(cachedUserKey, jsonString);
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final jsonString = sharedPreferences.getString(cachedUserKey);
    if (jsonString != null) {
      return UserModel.fromJson(jsonDecode(jsonString));
    }
    return null;
  }

  @override
  Future<void> cacheToken(String token) async {
    await sharedPreferences.setString(cachedTokenKey, token);
  }

  @override
  Future<String?> getToken() async {
    return sharedPreferences.getString(cachedTokenKey);
  }

  @override
  Future<void> cacheEnterprise(EnterpriseModel enterprise) async {
    final jsonString = jsonEncode(enterprise.toJson());
    await sharedPreferences.setString(cachedEnterpriseKey, jsonString);
  }

  @override
  Future<EnterpriseModel?> getCachedEnterprise() async {
    final jsonString = sharedPreferences.getString(cachedEnterpriseKey);
    if (jsonString != null) {
      return EnterpriseModel.fromJson(jsonDecode(jsonString));
    }
    return null;
  }

  @override
  Future<void> cacheEmail(String email) async {
    await sharedPreferences.setString(cachedEmailKey, email);
  }

  @override
  Future<String?> getCachedEmail() async {
    return sharedPreferences.getString(cachedEmailKey);
  }

  @override
  Future<void> logout() async {
    await sharedPreferences.remove(cachedUserKey);
    await sharedPreferences.remove(cachedTokenKey);
  }

  @override
  Future<void> clearEnterprise() async {
    await sharedPreferences.remove(cachedEnterpriseKey);
  }

  @override
  Future<void> clearEmail() async {
    await sharedPreferences.remove(cachedEmailKey);
  }

  @override
  Future<void> updateCachedUserPhoneNumber(String phoneNumber) async {
    final user = await getCachedUser();
    if (user != null) {
      final updatedUser = UserModel(
        id: user.id,
        name: user.name,
        tipo: user.tipo,
        password: user.password,
        isActive: user.isActive,
        phoneNumber: phoneNumber,
      );
      await cacheUser(updatedUser);
    }
  }
}
