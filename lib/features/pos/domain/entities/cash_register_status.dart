class CashRegisterStatus {
  final String status; // 'open' o 'closed'

  const CashRegisterStatus({
    required this.status,
  });

  bool get isOpen => status.toUpperCase() == 'OPEN';

  CashRegisterStatus copyWith({
    String? status,
  }) {
    return CashRegisterStatus(
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'status': status,
    };
  }
}
