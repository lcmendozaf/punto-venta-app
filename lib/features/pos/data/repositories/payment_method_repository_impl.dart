import 'package:punto_venta_app/features/pos/data/datasources/payment_method_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/payment_methods_config_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/payment_method_repository.dart';

class PaymentMethodRepositoryImpl implements PaymentMethodRepository {
  final PaymentMethodRemoteDatasource remoteDataSource;

  PaymentMethodRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<PaymentMethod>> fetchPaymentMethods() async {
    try {
      final models = await remoteDataSource.getPaymentMethods();
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw Exception('Error al cargar métodos de pago: $e');
    }
  }

  @override
  Future<PaymentMethodsConfig> fetchPaymentMethodsConfig() async {
    try {
      final model = await remoteDataSource.getPaymentMethodsConfig();
      return model.toEntity();
    } catch (e) {
      // Retornar configuración vacía si falla o no existe en el backend
      return const PaymentMethodsConfig(paymentMethodsConfig: []);
    }
  }

  @override
  Future<void> savePaymentMethodsConfig(PaymentMethodsConfig config) async {
    try {
      final model = PaymentMethodsConfigModel.fromEntity(config);
      await remoteDataSource.updatePaymentMethodsConfig(model);
    } catch (e) {
      throw Exception('Error al guardar la configuración de métodos de pago: $e');
    }
  }
}
