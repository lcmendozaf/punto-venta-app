import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_string.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../core/widgets/custom_button.dart';

class CartSummary extends StatelessWidget {
  final double subtotal;
  final double totalIva;
  final double totalConIva;
  final bool isReturnMode;
  final VoidCallback onClear;
  final VoidCallback onConfirm;

  const CartSummary({
    super.key,
    required this.subtotal,
    required this.totalIva,
    required this.totalConIva,
    this.isReturnMode = false,
    required this.onClear,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.paddingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.total,
                  style: Theme.of(context).textTheme.bodyMedium),
              Text(
                totalConIva.formatToCurrency(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 25,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingS),
          CustomButton(
            height: 30,
            width: double.infinity,
            text: AppStrings.empty,
            onPressed: onClear,
            backgroundColor: AppColors.error,
          ),
          const SizedBox(height: AppDimensions.paddingS),
          // cobrar
          CustomButton(
            height: 30,
            width: double.infinity,
            text: isReturnMode ? 'Devolución' : AppStrings.confirm,
            onPressed: onConfirm,
            backgroundColor: isReturnMode ? AppColors.warning : AppColors.green,
          ),
        ],
      ),
    );
  }
}
