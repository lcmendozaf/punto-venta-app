import 'package:punto_venta_app/features/pos/domain/entities/payment_method_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/payment_method_repository.dart';

class SavePaymentMethodsConfigUsecase {
  final PaymentMethodRepository repository;

  SavePaymentMethodsConfigUsecase(this.repository);

  Future<void> call(PaymentMethodsConfig config) async {
    return await repository.savePaymentMethodsConfig(config);
  }
}
