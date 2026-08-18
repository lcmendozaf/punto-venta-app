import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_event.dart';

class SupplierDocumentSection extends StatelessWidget {
  final TextEditingController remitoController;
  final TextEditingController ticketController;

  const SupplierDocumentSection({
    super.key,
    required this.remitoController,
    required this.ticketController,
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
            'Documentos del Proveedor',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: remitoController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Número de Remito',
                    hintText: 'Ej: 12345',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) {
                    final num = int.tryParse(val);
                    context.read<SupplierPaymentsBloc>().add(
                          UpdateDocumentNumbersEvent(remitoNumber: num),
                        );
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: TextField(
                  controller: ticketController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Factura / Ticket Proveedor',
                    hintText: 'Ej: 9876',
                    prefixIcon: const Icon(Icons.receipt_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) {
                    final num = int.tryParse(val);
                    context.read<SupplierPaymentsBloc>().add(
                          UpdateDocumentNumbersEvent(supplierTicket: num),
                        );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
