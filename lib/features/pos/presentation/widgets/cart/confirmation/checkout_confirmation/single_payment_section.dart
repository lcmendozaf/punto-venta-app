import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/add_payment_method_outlined_button.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/confirmation_helpers.dart';

class SinglePaymentSection extends StatelessWidget {
  final PaymentMethod? selectedPayment;
  final VoidCallback onSelectorTap;
  final Widget? detailsWidget;
  final VoidCallback onAddMethodPressed;

  const SinglePaymentSection({
    super.key,
    this.selectedPayment,
    required this.onSelectorTap,
    this.detailsWidget,
    required this.onAddMethodPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onSelectorTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    getPaymentMethodIcon(
                      selectedPayment?.description ?? '',
                      selectedPayment?.shortDescription ?? '',
                    ),
                    color: AppColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedPayment?.description ??
                            'Seleccionar método de pago',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (selectedPayment != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          selectedPayment!.shortDescription,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
        if (detailsWidget != null) ...[
          detailsWidget!,
          const SizedBox(height: 12),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: AddPaymentMethodOutlinedButton(
              onPressed: onAddMethodPressed,
            ),
          ),
        ),
      ],
    );
  }
}
