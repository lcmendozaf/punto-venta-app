import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/suppliers_models/supplier_response_model.dart';

abstract class SupplierLocalDataSource {
  Future<List<SupplierResponseModel>> getSuppliers();
  Future<void> saveSuppliers(List<SupplierResponseModel> suppliers);
}

class SupplierLocalDataSourceImpl implements SupplierLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String suppliersKey = 'POS_SUPPLIERS';

  SupplierLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<SupplierResponseModel>> getSuppliers() async {
    final jsonString = sharedPreferences.getString(suppliersKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    final List<dynamic> list = json.decode(jsonString) as List<dynamic>;
    return list
        .map((e) => SupplierResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveSuppliers(List<SupplierResponseModel> suppliers) async {
    final jsonString = json.encode(suppliers.map((p) => p.toJson()).toList());
    await sharedPreferences.setString(suppliersKey, jsonString);
  }
}
