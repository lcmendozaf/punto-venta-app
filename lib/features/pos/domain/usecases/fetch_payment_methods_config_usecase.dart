import 'package:punto_venta_app/features/pos/domain/entities/payment_method_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/payment_method_repository.dart';

class FetchPaymentMethodsConfigUsecase {
  final PaymentMethodRepository repository;

  FetchPaymentMethodsConfigUsecase(this.repository);

  Future<PaymentMethodsConfig> call() async {
    return await repository.fetchPaymentMethodsConfig();
  }
}
