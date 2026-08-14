import 'package:equatable/equatable.dart';
import '../../../domain/entities/payment_method.dart';

abstract class PaymentMethodsState extends Equatable {
  const PaymentMethodsState();
  @override
  List<Object?> get props => [];
}

class PaymentMethodsInitial extends PaymentMethodsState {}

class PaymentMethodsLoading extends PaymentMethodsState {}

class PaymentMethodsSaving extends PaymentMethodsState {}

class PaymentMethodsConfigSaved extends PaymentMethodsState {}

class PaymentMethodsLoaded extends PaymentMethodsState {
  final List<PaymentMethod> paymentMethods;
  final PaymentMethod? selectedPaymentMethod;

  const PaymentMethodsLoaded({required this.paymentMethods, this.selectedPaymentMethod});
  @override
  List<Object?> get props => [paymentMethods, selectedPaymentMethod];
}

class PaymentMethodsError extends PaymentMethodsState {
  final String message;
  const PaymentMethodsError(this.message);
  @override
  List<Object?> get props => [message];
}
