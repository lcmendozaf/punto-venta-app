import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';

class PaymentRowWidget extends StatelessWidget {
  final PaymentMethod paymentMethod;
  final TextEditingController amountController;
  final TextEditingController? receivedController;
  final IconData icon;
  final bool showDeleteButton;
  final VoidCallback? onDelete;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<String>? onReceivedAmountChanged;
  final Widget? detailsWidget;

  const PaymentRowWidget({
    super.key,
    required this.paymentMethod,
    required this.amountController,
    this.receivedController,
    required this.icon,
    required this.showDeleteButton,
    this.onDelete,
    required this.onAmountChanged,
    this.onReceivedAmountChanged,
    this.detailsWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isCash = paymentMethod.description.toLowerCase().contains('efectivo') ||
        paymentMethod.shortDescription.toLowerCase().contains('efectivo');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paymentMethod.description,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        paymentMethod.shortDescription,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (showDeleteButton)
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isCash)
                  Expanded(
                    child: TextFormField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [CurrencyInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Monto a pagar',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: onAmountChanged,
                      onTap: () {
                        amountController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: amountController.text.length,
                        );
                      },
                    ),
                  )
                else if (receivedController != null)
                  Expanded(
                    child: TextFormField(
                      controller: receivedController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [CurrencyInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Paga con (Recibido)',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: onReceivedAmountChanged,
                      onTap: () {
                        receivedController!.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: receivedController!.text.length,
                        );
                      },
                    ),
                  ),
              ],
            ),
            if (detailsWidget != null) detailsWidget!,
          ],
        ),
      ),
    );
  }
}
