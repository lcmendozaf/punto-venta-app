import 'package:punto_venta_app/features/pos/domain/entities/supplier.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/supplier_repository.dart';

class GetSuppliersUsecase {
  final SupplierRepository repository;
  GetSuppliersUsecase(this.repository);

  Future<List<Supplier>> call() async {
    return await repository.getSuppliers();
  }
}
