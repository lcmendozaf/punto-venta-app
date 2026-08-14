import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cash_payment_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/payment_method_dialogs.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/payment_method_details_controllers.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/checkout_payment_row.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/checkout_payment_details_form.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/confirmation_helpers.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/multiple_payments_section.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/single_payment_section.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/payment_tax_breakdown.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout_confirmation/checkout_confirmation_cubit.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout_confirmation/checkout_confirmation_state.dart';

class CheckoutConfirmationView extends StatefulWidget {
  final double totalAmount;

  // Impuestos extra (IIBB, perc. IVA, imp. interno)
  final double iibbAmount;
  final double vatPerceptionAmount;
  final double internalTaxAmount;

  // Para el desglose de impuestos
  final double cartSubtotal;
  final double cartTotalIva;

  const CheckoutConfirmationView({
    super.key,
    required this.totalAmount,
    required this.iibbAmount,
    required this.vatPerceptionAmount,
    required this.internalTaxAmount,
    required this.cartSubtotal,
    required this.cartTotalIva,
  });

  @override
  State<CheckoutConfirmationView> createState() =>
      _CheckoutConfirmationViewState();
}

class _CheckoutConfirmationViewState extends State<CheckoutConfirmationView> {
  final List<TextEditingController> _amountControllers = [];
  final List<TextEditingController> _receivedControllers = [];
  final List<PaymentMethodDetailsControllers> _detailsControllers = [];

  @override
  void initState() {
    super.initState();
    final cubit = context.read<CheckoutConfirmationCubit>();
    _syncControllersAndText(cubit.state.selectedPayments);
  }

  @override
  void didUpdateWidget(covariant CheckoutConfirmationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.totalAmount != oldWidget.totalAmount) {
      final cubit = context.read<CheckoutConfirmationCubit>();
      _syncControllersAndText(cubit.state.selectedPayments);
    }
  }

  @override
  void dispose() {
    for (final controller in _amountControllers) {
      controller.dispose();
    }
    for (final controller in _receivedControllers) {
      controller.dispose();
    }
    for (final controller in _detailsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllersAndText(List<PaymentMethod> payments) {
    final formatter = NumberFormat('#,##0.00', 'es_AR');

    // 1. Sync length of amountControllers and pre-fill when newly created
    while (_amountControllers.length < payments.length) {
      final pm = payments[_amountControllers.length];
      _amountControllers.add(TextEditingController(
        text: pm.amount != null ? formatter.format(pm.amount!) : '',
      ));
    }
    while (_amountControllers.length > payments.length) {
      _amountControllers.last.dispose();
      _amountControllers.removeLast();
    }

    // 2. Sync length of receivedControllers and pre-fill when newly created
    while (_receivedControllers.length < payments.length) {
      final pm = payments[_receivedControllers.length];
      final isCash = pm.description.toLowerCase().contains('efectivo') ||
          pm.shortDescription.toLowerCase().contains('efectivo');
      _receivedControllers.add(TextEditingController(
        text: isCash
            ? formatter.format(pm.receivedAmount ?? pm.amount ?? 0.0)
            : '',
      ));
    }
    while (_receivedControllers.length > payments.length) {
      _receivedControllers.last.dispose();
      _receivedControllers.removeLast();
    }

    // 3. Sync length of detailsControllers
    while (_detailsControllers.length < payments.length) {
      _detailsControllers.add(PaymentMethodDetailsControllers());
    }
    while (_detailsControllers.length > payments.length) {
      _detailsControllers.last.dispose();
      _detailsControllers.removeLast();
    }

    // 4. Update text values if they differ from model to avoid losing focus/cursor position
    for (int i = 0; i < payments.length; i++) {
      final pm = payments[i];

      // Sync amount
      final double? modelAmount = pm.amount;
      final String controllerText = _amountControllers[i].text;
      final double? parsedAmount = controllerText.parseFormattedDouble();

      if (controllerText.isEmpty &&
          (modelAmount == null || modelAmount == 0.0)) {
        // No sobrescribir si el usuario borró todo y el modelo es nulo o cero
      } else if (parsedAmount != modelAmount) {
        _amountControllers[i].text =
            modelAmount != null ? formatter.format(modelAmount) : '';
      }

      // Sync received amount (for cash)
      final isCash = pm.description.toLowerCase().contains('efectivo') ||
          pm.shortDescription.toLowerCase().contains('efectivo');
      if (isCash) {
        final double rec = pm.receivedAmount ?? pm.amount ?? 0.0;
        final String recControllerText = _receivedControllers[i].text;
        final double? parsedRec = recControllerText.parseFormattedDouble();

        if (recControllerText.isEmpty && pm.receivedAmount == null) {
          // No sobrescribir si el usuario borró el valor recibido y el modelo es nulo
        } else if (parsedRec != rec) {
          _receivedControllers[i].text = formatter.format(rec);
        }
      }

      // Sync details controllers
      final details = pm.details ?? const PaymentMethodDetails();
      if (_detailsControllers[i].accountOwner.text !=
          (details.accountOwner ?? '')) {
        _detailsControllers[i].accountOwner.text = details.accountOwner ?? '';
      }
      if (_detailsControllers[i].bankId.text != (details.bankId ?? '')) {
        _detailsControllers[i].bankId.text = details.bankId ?? '';
      }
      if (_detailsControllers[i].checkNumber.text !=
          (details.checkNumber ?? '')) {
        _detailsControllers[i].checkNumber.text = details.checkNumber ?? '';
      }
      if (_detailsControllers[i].transferId.text !=
          (details.transferId ?? '')) {
        _detailsControllers[i].transferId.text = details.transferId ?? '';
      }
      if (_detailsControllers[i].verificationId.text !=
          (details.verificationId ?? '')) {
        _detailsControllers[i].verificationId.text =
            details.verificationId ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PaymentMethodsBloc, PaymentMethodsState>(
          listener: (context, pmState) {
            if (pmState is PaymentMethodsLoaded) {
              final selected = pmState.selectedPaymentMethod;
              if (selected != null) {
                context
                    .read<CheckoutConfirmationCubit>()
                    .selectSinglePaymentMethod(selected, widget.totalAmount);
              }
            }
          },
        ),
        BlocListener<CheckoutConfirmationCubit, CheckoutConfirmationState>(
          listenWhen: (previous, current) =>
              previous.selectedPayments != current.selectedPayments,
          listener: (context, state) {
            _syncControllersAndText(state.selectedPayments);
          },
        ),
      ],
      child: BlocBuilder<CheckoutConfirmationCubit, CheckoutConfirmationState>(
        builder: (context, confirmationState) {
          final selectedPayments = confirmationState.selectedPayments;
          final totalAllocated = confirmationState.totalAllocated;
          final change = confirmationState.change;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total a cobrar:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.totalAmount.formatToCurrency(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 36,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Métodos de Pago',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              BlocBuilder<PaymentMethodsBloc, PaymentMethodsState>(
                builder: (context, pmState) {
                  if (pmState is PaymentMethodsLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (pmState is PaymentMethodsError) {
                    return Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 20, color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Error al cargar métodos de pago: ${pmState.message}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (pmState is PaymentMethodsLoaded) {
                    final paymentMethods = pmState.paymentMethods;
                    final selected = pmState.selectedPaymentMethod;

                    if (paymentMethods.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingM),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning,
                                size: 20, color: AppColors.warning),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No hay métodos de pago disponibles',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (selectedPayments.length > 1) {
                      return MultiplePaymentsSection(
                        paymentRows: List.generate(
                          selectedPayments.length,
                          (index) {
                            final pm = selectedPayments[index];
                            final isCash = pm.description
                                    .toLowerCase()
                                    .contains('efectivo') ||
                                pm.shortDescription
                                    .toLowerCase()
                                    .contains('efectivo');
                            return CheckoutPaymentRow(
                              index: index,
                              paymentMethod: pm,
                              amountController: _amountControllers[index],
                              receivedController:
                                  isCash ? _receivedControllers[index] : null,
                              detailsControllers: _detailsControllers[index],
                              totalAmount: widget.totalAmount,
                            );
                          },
                        ),
                        onAddMethodPressed: () => showAddPaymentMethodDialog(
                          context: context,
                          allMethods: paymentMethods,
                          selectedPayments: selectedPayments,
                          totalAmount: widget.totalAmount,
                          totalAllocated: totalAllocated,
                          getPaymentMethodIcon: getPaymentMethodIcon,
                          onMethodAdded: (pm, defaultAmount) {
                            context
                                .read<CheckoutConfirmationCubit>()
                                .addPaymentMethod(
                                    pm, defaultAmount, widget.totalAmount);
                          },
                        ),
                        totalAmount: widget.totalAmount,
                        totalAllocated: totalAllocated,
                        change: change,
                      );
                    }

                    final isCash = selected?.description
                                .toLowerCase()
                                .contains('efectivo') ==
                            true ||
                        selected?.shortDescription
                                .toLowerCase()
                                .contains('efectivo') ==
                            true;

                    return SinglePaymentSection(
                      selectedPayment: selected,
                      onSelectorTap: () => showPaymentMethodsSelectorDialog(
                        context: context,
                        paymentMethods: paymentMethods,
                        selectedPaymentMethod: selected,
                        getPaymentMethodIcon: getPaymentMethodIcon,
                        onSelected: (pm) {
                          context
                              .read<PaymentMethodsBloc>()
                              .add(SelectPaymentMethodEvent(pm));
                        },
                      ),
                      detailsWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedPayments.isNotEmpty)
                            CheckoutPaymentDetailsForm(
                              index: 0,
                              paymentMethod: selectedPayments[0],
                              controllers: _detailsControllers[0],
                            ),
                          if (isCash) ...[
                            CashPaymentWidget(
                              key: ValueKey(widget.totalAmount),
                              totalAmount: widget.totalAmount,
                              onAmountChanged: (amount) {
                                context
                                    .read<CheckoutConfirmationCubit>()
                                    .updatePaymentReceivedAmount(
                                        0, amount, widget.totalAmount);
                              },
                              onChangeCalculated: (changeVal) {},
                            ),
                          ],
                        ],
                      ),
                      onAddMethodPressed: () => showAddPaymentMethodDialog(
                        context: context,
                        allMethods: paymentMethods,
                        selectedPayments: selectedPayments,
                        totalAmount: widget.totalAmount,
                        totalAllocated: totalAllocated,
                        getPaymentMethodIcon: getPaymentMethodIcon,
                        onMethodAdded: (pm, defaultAmount) {
                          context
                              .read<CheckoutConfirmationCubit>()
                              .addPaymentMethod(
                                  pm, defaultAmount, widget.totalAmount);
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              if (widget.iibbAmount > 0 ||
                  widget.vatPerceptionAmount > 0 ||
                  widget.internalTaxAmount > 0)
                PaymentTaxBreakdown(
                  cartSubtotal: widget.cartSubtotal,
                  cartTotalIva: widget.cartTotalIva,
                  iibbAmount: widget.iibbAmount,
                  vatPerceptionAmount: widget.vatPerceptionAmount,
                  internalTaxAmount: widget.internalTaxAmount,
                ),
            ],
          );
        },
      ),
    );
  }
}
