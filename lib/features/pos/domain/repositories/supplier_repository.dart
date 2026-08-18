import 'package:punto_venta_app/features/pos/data/models/suppliers_models/supplier_payment_request.dart';
import 'package:punto_venta_app/features/pos/domain/entities/supplier.dart';

abstract class SupplierRepository {
  Future<List<Supplier>> getSuppliers();
  Future<void> makePayment(SupplierPaymentRequest request);
}
