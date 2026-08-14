import 'package:punto_venta_app/features/pos/data/datasources/pdv_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/branch_local_datasource.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/pdv_config_repository.dart';
import 'package:punto_venta_app/core/network/exceptions.dart';

class PdvConfigRepositoryImpl implements PdvConfigRepository {
  final PdvRemoteDataSource remoteDataSource;
  final PdvLocalDataSource localDataSource;
  final BranchLocalDataSource branchLocalDataSource;

  PdvConfigRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.branchLocalDataSource,
  });

  @override
  Future<PdvConfig> fetchPdvConfig() async {
    final localConfig = await localDataSource.getPdvConfig();
    
    try {
      final data = await remoteDataSource.fetchPdvConfig();

      final remoteConfig = PdvConfig(
        pdvId: data.deliveryLocationId,
        branchId: data.branchId,
        offlineMode: data.offlineMode,
      );

      final finalData = PdvConfig(
        pdvId: remoteConfig.pdvId ?? localConfig?.pdvId,
        branchId: remoteConfig.branchId ?? localConfig?.branchId,
        branchNumber: remoteConfig.branchNumber ?? localConfig?.branchNumber,
        offlineMode: remoteConfig.offlineMode ?? localConfig?.offlineMode,
      );
      await localDataSource.savePdvConfig(finalData);
      return finalData;
    } catch (e) {
      if (e is NotFoundException) {
        rethrow;
      }
      if (localConfig != null) {
        return localConfig;
      }
      throw Exception('Error al obtener configuración del PDV: $e');
    }
  }

  @override
  Future<PdvConfig?> getLocalPdvConfig() async {
    return await localDataSource.getPdvConfig();
  }

  @override
  Future<void> savePdvConfig(PdvConfig config) async {
    await remoteDataSource.updatePdvConfig(config);
    await localDataSource.savePdvConfig(config);
  }

  @override
  Future<void> updateOfflineMode(PdvConfig config) async {
    await remoteDataSource.updateOfflineMode(config);
    await localDataSource.savePdvConfig(config);
  }

  @override
  Future<List<Branch>> fetchBranches() async {
    try {
      final branches = await remoteDataSource.fetchBranches();
      
      await branchLocalDataSource.cacheBranches(branches);
      
      return branches.map((model) => Branch.fromModel(model)).toList();
    } catch (e) {
      throw Exception('Error al obtener sucursales: $e');
    }
  }
}
