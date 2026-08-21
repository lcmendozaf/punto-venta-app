class CashRefundRequestModel {
  final int branchId;
  final double refundAmount;
  final int? clientId;
  final int refundReasonId;

  const CashRefundRequestModel({
    required this.branchId,
    required this.refundAmount,
    required this.refundReasonId,
    this.clientId,
  });

  Map<String, dynamic> toJson() => {
        'branch_id': branchId,
        'refund_amount': refundAmount,
        'client_id': clientId,
        'refund_reason_id': refundReasonId,
      };
}
