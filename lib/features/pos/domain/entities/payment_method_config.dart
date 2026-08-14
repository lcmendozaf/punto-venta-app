class PaymentMethodConfig {
  final int paymentMethodId;
  final List<int> branchesSelected;
  final int? minBranchPriority;

  const PaymentMethodConfig({
    required this.paymentMethodId,
    required this.branchesSelected,
    this.minBranchPriority,
  });

  factory PaymentMethodConfig.fromJson(Map<String, dynamic> json) {
    return PaymentMethodConfig(
      paymentMethodId: json['paymentMethodId'] as int,
      branchesSelected: List<int>.from(json['branchesSelected'] as List),
      minBranchPriority: json['minBranchPriority'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'paymentMethodId': paymentMethodId,
        'branchesSelected': branchesSelected,
        'minBranchPriority': minBranchPriority,
      };
}

class PaymentMethodsConfig {
  final List<PaymentMethodConfig> paymentMethodsConfig;

  const PaymentMethodsConfig({
    required this.paymentMethodsConfig,
  });
}
