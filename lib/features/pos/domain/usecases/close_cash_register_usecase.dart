import 'package:punto_venta_app/features/pos/domain/entities/cash_register_status.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/cash_register_repository.dart';

class CloseCashRegisterUseCase {
  final CashRegisterRepository repository;

  CloseCashRegisterUseCase(this.repository);

  Future<CashRegisterStatus> call() async {
    return await repository.closeRegister();
  }
}
