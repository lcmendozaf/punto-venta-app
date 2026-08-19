import 'package:punto_venta_app/features/pos/domain/entities/cash_register_status.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/cash_register_repository.dart';

class OpenCashRegisterUseCase {
  final CashRegisterRepository repository;

  OpenCashRegisterUseCase(this.repository);

  Future<CashRegisterStatus> call() async {
    return await repository.openRegister();
  }
}
