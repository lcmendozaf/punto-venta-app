import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_cash_register_status_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/open_cash_register_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/close_cash_register_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cash_register_status.dart';
import 'cash_register_state.dart';

class CashRegisterCubit extends Cubit<CashRegisterState> {
  final GetCashRegisterStatusUseCase getStatusUseCase;
  final OpenCashRegisterUseCase openUseCase;
  final CloseCashRegisterUseCase closeUseCase;

  CashRegisterStatus? _lastStatus;

  CashRegisterStatus? get currentStatus => _lastStatus;

  CashRegisterCubit({
    required this.getStatusUseCase,
    required this.openUseCase,
    required this.closeUseCase,
  }) : super(CashRegisterInitial());

  Future<void> fetchStatus() async {
    emit(CashRegisterLoading());
    try {
      final status = await getStatusUseCase();
      _lastStatus = status;
      emit(CashRegisterLoaded(status));
    } catch (e) {
      emit(CashRegisterError(e.toString(), lastStatus: _lastStatus));
    }
  }

  Future<void> openRegister() async {
    emit(CashRegisterLoading());
    try {
      final status = await openUseCase();
      _lastStatus = status;
      emit(CashRegisterLoaded(status));
    } catch (e) {
      emit(CashRegisterError(e.toString(), lastStatus: _lastStatus));
    }
  }

  Future<void> closeRegister() async {
    emit(CashRegisterLoading());
    try {
      final status = await closeUseCase();
      _lastStatus = status;
      emit(CashRegisterLoaded(status));
    } catch (e) {
      emit(CashRegisterError(e.toString(), lastStatus: _lastStatus));
    }
  }
}
