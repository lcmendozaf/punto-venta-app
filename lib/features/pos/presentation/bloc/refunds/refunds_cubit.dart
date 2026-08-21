import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/refunds_repository.dart';
import 'refunds_state.dart';

class RefundsCubit extends Cubit<RefundsState> {
  final RefundsRepository repository;

  RefundsCubit({required this.repository}) : super(const RefundsState());

  Future<void> loadReasons() async {
    emit(state.copyWith(status: RefundsStatus.loading, errorMessage: null));
    try {
      final reasons = await repository.fetchRefundReasons();
      emit(state.copyWith(
        status: RefundsStatus.loaded,
        reasons: reasons,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RefundsStatus.error,
        errorMessage: _extractErrorMessage(e),
      ));
    }
  }

  Future<void> submitRefund({
    required int branchId,
    required double refundAmount,
    required int refundReasonId,
    int? clientId,
  }) async {
    emit(state.copyWith(status: RefundsStatus.submitting, errorMessage: null));
    try {
      await repository.processCashRefund(
        branchId: branchId,
        refundAmount: refundAmount,
        refundReasonId: refundReasonId,
        clientId: clientId,
      );
      emit(state.copyWith(status: RefundsStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: RefundsStatus.error,
        errorMessage: _extractErrorMessage(e),
      ));
    }
  }

  String _extractErrorMessage(dynamic error) {
    String message = error.toString();
    while (message.startsWith('Exception: ')) {
      message = message.replaceFirst('Exception: ', '');
    }
    return message;
  }

}
