import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/entities/refund_reason.dart';

enum RefundsStatus { initial, loading, loaded, submitting, success, error }

class RefundsState extends Equatable {
  final RefundsStatus status;
  final List<RefundReason> reasons;
  final String? errorMessage;
  final PrintJob? printJob;

  const RefundsState({
    this.status = RefundsStatus.initial,
    this.reasons = const [],
    this.errorMessage,
    this.printJob,
  });

  RefundsState copyWith({
    RefundsStatus? status,
    List<RefundReason>? reasons,
    String? errorMessage,
    PrintJob? printJob,
  }) {
    return RefundsState(
      status: status ?? this.status,
      reasons: reasons ?? this.reasons,
      errorMessage: errorMessage ?? this.errorMessage,
      printJob: printJob ?? this.printJob,
    );
  }

  @override
  List<Object?> get props => [status, reasons, errorMessage, printJob];
}

