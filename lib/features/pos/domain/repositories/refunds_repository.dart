import 'package:punto_venta_app/features/pos/domain/entities/refund_reason.dart';
import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';

abstract class RefundsRepository {
  Future<List<RefundReason>> fetchRefundReasons();

  Future<CompletedOrder> processCashRefund({
    required int branchId,
    required double refundAmount,
    required int refundReasonId,
    int? clientId,
  });
}

