import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout_confirmation/checkout_confirmation_cubit.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_event.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/checkout_payment_details_form.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/payment_method_details_controllers.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/payment_row_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/confirmation_helpers.dart';

class CheckoutPaymentRow extends StatelessWidget {
  final int index;
  final PaymentMethod paymentMethod;
  final TextEditingController amountController;
  final TextEditingController? receivedController;
  final PaymentMethodDetailsControllers detailsControllers;
  final double totalAmount;

  const CheckoutPaymentRow({
    super.key,
    required this.index,
    required this.paymentMethod,
    required this.amountController,
    this.receivedController,
    required this.detailsControllers,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final pm = paymentMethod;
    final isCash = pm.description.toLowerCase().contains('efectivo') ||
        pm.shortDescription.toLowerCase().contains('efectivo');

    final showDeleteButton = context
            .read<CheckoutConfirmationCubit>()
            .state
            .selectedPayments
            .length >
        1;

    return PaymentRowWidget(
      paymentMethod: pm,
      amountController: amountController,
      receivedController: isCash ? receivedController : null,
      icon: getPaymentMethodIcon(pm.description, pm.shortDescription),
      showDeleteButton: showDeleteButton,
      onDelete: () {
        context
            .read<CheckoutConfirmationCubit>()
            .removePaymentMethod(index, totalAmount);
        final nextPayments =
            context.read<CheckoutConfirmationCubit>().state.selectedPayments;
        if (nextPayments.length == 1) {
          context
              .read<PaymentMethodsBloc>()
              .add(SelectPaymentMethodEvent(nextPayments[0]));
        }
      },
      onAmountChanged: (val) {
        final double? parsed = val.parseFormattedDouble();
        context
            .read<CheckoutConfirmationCubit>()
            .updatePaymentAmount(index, parsed ?? 0.0, totalAmount);
      },
      onReceivedAmountChanged: (val) {
        final double? parsed = val.parseFormattedDouble();
        context
            .read<CheckoutConfirmationCubit>()
            .updatePaymentReceivedAmount(index, parsed, totalAmount);
      },
      detailsWidget: CheckoutPaymentDetailsForm(
        index: index,
        paymentMethod: pm,
        controllers: detailsControllers,
      ),
    );
  }
}
