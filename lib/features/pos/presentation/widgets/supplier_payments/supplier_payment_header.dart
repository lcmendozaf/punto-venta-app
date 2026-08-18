import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/supplier.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_event.dart';

class SupplierPaymentHeader extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onDeselected;

  const SupplierPaymentHeader({
    super.key,
    required this.supplier,
    required this.onDeselected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 0.5,
          color: isDark ? AppColors.darkDivider : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: supplier.isServiceProvider
                ? Colors.blue.shade100
                : Colors.orange.shade100,
            radius: 24,
            child: Icon(
              supplier.isServiceProvider
                  ? Icons.build_outlined
                  : Icons.inventory_2_outlined,
              color: supplier.isServiceProvider ? Colors.blue : Colors.orange,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplier.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'ID: ${supplier.id} | CUIT: ${supplier.cuit ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDark ? AppColors.darkBackground : Colors.grey.shade200,
              foregroundColor:
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              onDeselected();
              context
                  .read<SupplierPaymentsBloc>()
                  .add(const SelectSupplierEvent(null));
            },
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Deseleccionar'),
          ),
        ],
      ),
    );
  }
}
