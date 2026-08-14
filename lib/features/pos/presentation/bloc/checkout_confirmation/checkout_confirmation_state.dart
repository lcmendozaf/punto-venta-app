import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/domain/entities/return_reason.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';

class CheckoutConfirmationState extends Equatable {
  final bool isLoading;
  final double iibbAmount;
  final double vatPerceptionAmount;
  final double internalTaxAmount;
  final double totalAmount;
  final List<ReturnReason> returnReasons;
  final int? selectedReturnReasonId;
  final String? errorMessage;
  final List<PaymentMethod> selectedPayments;
  final double receivedAmount;
  final double change;
  final int? activeBranchId;
  final String? activeBranchName;
  final List<Branch> allowedBranches;

  const CheckoutConfirmationState({
    this.isLoading = false,
    this.iibbAmount = 0.0,
    this.vatPerceptionAmount = 0.0,
    this.internalTaxAmount = 0.0,
    this.totalAmount = 0.0,
    this.returnReasons = const [],
    this.selectedReturnReasonId,
    this.errorMessage,
    this.selectedPayments = const [],
    this.receivedAmount = 0.0,
    this.change = 0.0,
    this.activeBranchId,
    this.activeBranchName,
    this.allowedBranches = const [],
  });

  double get totalAllocated =>
      selectedPayments.fold(0.0, (sum, pm) => sum + (pm.amount ?? 0.0));

  bool isValid(bool isReturnMode) {
    if (isReturnMode) {
      return selectedReturnReasonId != null;
    }
    if (selectedPayments.isEmpty) {
      return false;
    }
    if (selectedPayments.length > 1) {
      return double.parse(totalAllocated.toStringAsFixed(2)) ==
          double.parse(totalAmount.toStringAsFixed(2));
    }
    return true;
  }

  CheckoutConfirmationState copyWith({
    bool? isLoading,
    double? iibbAmount,
    double? vatPerceptionAmount,
    double? internalTaxAmount,
    double? totalAmount,
    List<ReturnReason>? returnReasons,
    int? selectedReturnReasonId,
    String? errorMessage,
    List<PaymentMethod>? selectedPayments,
    double? receivedAmount,
    double? change,
    int? activeBranchId,
    String? activeBranchName,
    List<Branch>? allowedBranches,
    bool resetActiveBranch = false,
  }) {
    return CheckoutConfirmationState(
      isLoading: isLoading ?? this.isLoading,
      iibbAmount: iibbAmount ?? this.iibbAmount,
      vatPerceptionAmount: vatPerceptionAmount ?? this.vatPerceptionAmount,
      internalTaxAmount: internalTaxAmount ?? this.internalTaxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      returnReasons: returnReasons ?? this.returnReasons,
      selectedReturnReasonId: selectedReturnReasonId ?? this.selectedReturnReasonId,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedPayments: selectedPayments ?? this.selectedPayments,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      change: change ?? this.change,
      activeBranchId: resetActiveBranch ? null : (activeBranchId ?? this.activeBranchId),
      activeBranchName: resetActiveBranch ? null : (activeBranchName ?? this.activeBranchName),
      allowedBranches: allowedBranches ?? this.allowedBranches,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        iibbAmount,
        vatPerceptionAmount,
        internalTaxAmount,
        totalAmount,
        returnReasons,
        selectedReturnReasonId,
        errorMessage,
        selectedPayments,
        receivedAmount,
        change,
        activeBranchId,
        activeBranchName,
        allowedBranches,
      ];
}
