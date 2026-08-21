import 'package:punto_venta_app/features/pos/data/datasources/refunds_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/cash_refund_request_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/refund_reason.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/refunds_repository.dart';

class RefundsRepositoryImpl implements RefundsRepository {
  final RefundsRemoteDataSource remoteDataSource;

  RefundsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<RefundReason>> fetchRefundReasons() async {
    final models = await remoteDataSource.getRefundReasons();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> processCashRefund({
    required int branchId,
    required double refundAmount,
    required int refundReasonId,
    int? clientId,
  }) async {
    final request = CashRefundRequestModel(
      branchId: branchId,
      refundAmount: refundAmount,
      refundReasonId: refundReasonId,
      clientId: clientId,
    );
    await remoteDataSource.processCashRefund(request);
  }
}
