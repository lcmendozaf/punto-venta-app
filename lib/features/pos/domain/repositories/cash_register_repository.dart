import 'package:punto_venta_app/features/pos/domain/entities/cash_register_status.dart';

abstract class CashRegisterRepository {
  Future<CashRegisterStatus> getStatus();
  Future<CashRegisterStatus> openRegister();
  Future<CashRegisterStatus> closeRegister();
}
