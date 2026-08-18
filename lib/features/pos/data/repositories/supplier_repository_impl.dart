import 'dart:async';
import 'package:punto_venta_app/features/pos/data/datasources/supplier_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/supplier_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/suppliers_models/supplier_payment_request.dart';
import 'package:punto_venta_app/features/pos/domain/entities/supplier.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/supplier_repository.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final SupplierLocalDataSource localDataSource;
  final SupplierRemoteDataSource remoteDataSource;

  SupplierRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<Supplier>> getSuppliers() async {
    try {
      final remoteModels = await remoteDataSource.getSuppliers();
      unawaited(
        localDataSource.saveSuppliers(remoteModels).catchError(
              (Object e) =>
                  print('Error al guardar proveedores en caché local: $e'),
            ),
      );
      return remoteModels.map((m) => m.toEntity()).toList();
    } catch (e) {
      print(
          'Error al cargar proveedores del backend: $e. Usando caché local...');
    }
    final localModels = await localDataSource.getSuppliers();
    return localModels.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> makePayment(SupplierPaymentRequest request) async {
    await remoteDataSource.makePayment(request);
  }
}
