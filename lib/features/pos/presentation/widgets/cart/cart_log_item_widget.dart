import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';

class CartLogItemWidget extends StatelessWidget {
  final CartLogEntry entry;

  const CartLogItemWidget({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isAdd = entry.type == CartActionType.add;
    final icon = isAdd ? Icons.add_circle_outline : Icons.remove_circle_outline;
    final color = isAdd ? AppColors.success : AppColors.error;
    final sign = isAdd ? '+' : '-';

    final product = entry.item.product;
    final basePrice = product.price ?? 0.0;
    final vatRate = product.vat / 100.0;
    final internalTax = product.internalTax;
    final fractional = product.fractional ?? 1;

    double displayedUnitPrice = basePrice * (1 + vatRate);
    if (internalTax > 0) {
      displayedUnitPrice += internalTax * fractional;
    }

    final isWeighted = entry.item.isWeighted ?? false;
    final double displayedRowTotal = isWeighted
        ? displayedUnitPrice * (entry.item.weightKg ?? 0.0)
        : displayedUnitPrice * entry.item.quantity;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.item.product.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        isWeighted
                            ? '$sign${entry.item.weightKg} kg'
                            : '$sign${entry.item.quantity}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Text(
                          '  • ${displayedUnitPrice.formatToCurrency()}${isWeighted ? ' / kg' : ''}  • ${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '$sign ${displayedRowTotal.formatToCurrency()}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
