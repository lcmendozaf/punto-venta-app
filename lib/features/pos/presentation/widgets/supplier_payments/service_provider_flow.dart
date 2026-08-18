import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_event.dart';

class ServiceProviderFlow extends StatelessWidget {
  final TextEditingController totalPaidController;

  const ServiceProviderFlow({
    super.key,
    required this.totalPaidController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 0.5,
          color: isDark ? AppColors.darkDivider : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalle de Pago por Servicios',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          TextField(
            controller: totalPaidController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [CurrencyInputFormatter()],
            decoration: InputDecoration(
              labelText: 'Monto del Adelanto',
              hintText: '\$ 0.00',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (val) {
              final amount = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
              context.read<SupplierPaymentsBloc>().add(
                    UpdatePaymentAmountsEvent(totalPaid: amount),
                  );
            },
          ),
        ],
      ),
    );
  }
}
