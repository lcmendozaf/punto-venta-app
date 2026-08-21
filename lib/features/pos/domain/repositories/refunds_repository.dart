import 'package:punto_venta_app/features/pos/domain/entities/refund_reason.dart';

abstract class RefundsRepository {
  Future<List<RefundReason>> fetchRefundReasons();

  Future<void> processCashRefund({
    required int branchId,
    required double refundAmount,
    required int refundReasonId,
    int? clientId,
  });
}
