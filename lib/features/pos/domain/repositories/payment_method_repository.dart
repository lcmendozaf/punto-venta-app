import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method_config.dart';

abstract class PaymentMethodRepository {
  Future<List<PaymentMethod>> fetchPaymentMethods();
  Future<PaymentMethodsConfig> fetchPaymentMethodsConfig();
  Future<void> savePaymentMethodsConfig(PaymentMethodsConfig config);
}