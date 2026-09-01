import 'package:punto_venta_app/features/pos/data/datasources/fiscal_issuer_data_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/fiscal_issuer_data_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/domain/entities/fiscal_issuer_data.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/fiscal_issuer_data_repository.dart';

class FiscalIssuerDataRepositoryImpl implements FiscalIssuerDataRepository {
  final FiscalIssuerDataRemoteDatasource remoteDatasource;
  final FiscalIssuerDataLocalDatasource localDatasource;

  FiscalIssuerDataRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
  });

  @override
  Future<FiscalIssuerData> getFiscalIssuerData() async {
    try {
      // final cachedData = await localDatasource.getCachedFiscalIssuerData(branchId);
      // if (cachedData != null) {
      //   return cachedData.toEntity();
      // }

      final remoteData = await remoteDatasource.getFiscalIssuerData();

      await localDatasource.cacheFiscalIssuerData(remoteData);

      return remoteData.toEntity();
    } catch (e) {
      throw Exception('Error al obtener datos fiscales del emisor: $e');
    }
  }

  @override
  Future<void> clearFiscalIssuerDataCache() async {
    try {
      await localDatasource.clearCache();
    } catch (e) {
      throw Exception('Error al limpiar caché de datos fiscales: $e');
    }
  }
}
