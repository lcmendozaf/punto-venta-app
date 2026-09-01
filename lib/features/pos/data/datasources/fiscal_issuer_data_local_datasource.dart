import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:punto_venta_app/features/pos/data/models/fiscal_issuer_data_model.dart';

abstract class FiscalIssuerDataLocalDatasource {
  Future<void> cacheFiscalIssuerData(FiscalIssuerDataModel data);
  Future<FiscalIssuerDataModel?> getCachedFiscalIssuerData();
  Future<void> clearCache();
}

class FiscalIssuerDataLocalDatasourceImpl
    implements FiscalIssuerDataLocalDatasource {
  final SharedPreferences sharedPreferences;

  static const String _keyPrefix = 'CACHED_FISCAL_ISSUER_DATA_';

  FiscalIssuerDataLocalDatasourceImpl({
    required this.sharedPreferences,
  });

  @override
  Future<void> cacheFiscalIssuerData(FiscalIssuerDataModel data) async {

    const key = _keyPrefix;
    final jsonString = jsonEncode(data.toJson());
    await sharedPreferences.setString(key, jsonString);
  }

  @override
  Future<FiscalIssuerDataModel?> getCachedFiscalIssuerData() async {
    const key = _keyPrefix;
    final jsonString = sharedPreferences.getString(key);
    
    if (jsonString == null) return null;
    
    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return FiscalIssuerDataModel.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    final keys = sharedPreferences.getKeys();
    for (final key in keys) {
      if (key.startsWith(_keyPrefix)) {
        await sharedPreferences.remove(key);
      }
    }
  }
}
