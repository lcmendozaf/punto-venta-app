import 'package:punto_venta_app/features/pos/data/models/suppliers_models/supplier_payment_request.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/supplier_repository.dart';

class MakeSupplierPaymentUsecase {
  final SupplierRepository repository;
  MakeSupplierPaymentUsecase(this.repository);

  Future<void> call(SupplierPaymentRequest request) async {
    await repository.makePayment(request);
  }
}
