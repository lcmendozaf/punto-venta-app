import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout_confirmation/checkout_confirmation_cubit.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/payment_additional_details_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/payment_method_details_controllers.dart';

class CheckoutPaymentDetailsForm extends StatefulWidget {
  final int index;
  final PaymentMethod paymentMethod;
  final PaymentMethodDetailsControllers controllers;

  const CheckoutPaymentDetailsForm({
    super.key,
    required this.index,
    required this.paymentMethod,
    required this.controllers,
  });

  @override
  State<CheckoutPaymentDetailsForm> createState() =>
      _CheckoutPaymentDetailsFormState();
}

class _CheckoutPaymentDetailsFormState
    extends State<CheckoutPaymentDetailsForm> {
  bool _isExpanded = false;

  void _updatePaymentDetails(
      PaymentMethodDetails Function(PaymentMethodDetails d) updateFn) {
    final currentDetails =
        widget.paymentMethod.details ?? const PaymentMethodDetails();
    final updatedDetails = updateFn(currentDetails);
    context
        .read<CheckoutConfirmationCubit>()
        .updatePaymentDetails(widget.index, updatedDetails);
  }

  @override
  Widget build(BuildContext context) {
    return PaymentAdditionalDetailsWidget(
      paymentMethod: widget.paymentMethod,
      controllers: widget.controllers,
      isExpanded: _isExpanded,
      onExpansionToggled: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      onCheckNumberChanged: (val) {
        _updatePaymentDetails((d) => d.copyWith(checkNumber: val));
      },
      onTransferIdChanged: (val) {
        _updatePaymentDetails((d) => d.copyWith(transferId: val));
      },
      onVerificationIdChanged: (val) {
        _updatePaymentDetails((d) => d.copyWith(verificationId: val));
      },
    );
  }
}
