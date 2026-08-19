import 'package:punto_venta_app/features/pos/domain/entities/cash_register_status.dart';

abstract class CashRegisterState {}

class CashRegisterInitial extends CashRegisterState {}

class CashRegisterLoading extends CashRegisterState {}

class CashRegisterLoaded extends CashRegisterState {
  final CashRegisterStatus status;

  CashRegisterLoaded(this.status);
}

class CashRegisterError extends CashRegisterState {
  final String message;
  final CashRegisterStatus? lastStatus;

  CashRegisterError(this.message, {this.lastStatus});
}
