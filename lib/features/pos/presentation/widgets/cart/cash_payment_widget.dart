import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';

class CashPaymentWidget extends StatefulWidget {
  final double totalAmount;
  final ValueChanged<double?> onAmountChanged;
  final ValueChanged<double?> onChangeCalculated;
  final bool showTotalAmount;

  const CashPaymentWidget({
    super.key,
    required this.totalAmount,
    required this.onAmountChanged,
    required this.onChangeCalculated,
    this.showTotalAmount = false,
  });

  @override
  State<CashPaymentWidget> createState() => _CashPaymentWidgetState();
}

class _CashPaymentWidgetState extends State<CashPaymentWidget> {
  late TextEditingController _amountController;
  double _change = 0.0;

  @override
  void initState() {
    super.initState();
    final formatter = NumberFormat('#,##0.00', 'es_AR');
    _amountController = TextEditingController(
      text: formatter.format(widget.totalAmount),
    );
    _amountController.addListener(_calculateChange);
    // Calcular el vuelto inicial de forma diferida para evitar llamadas asincronas en initState
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateChange());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    final text = _amountController.text.trim();
    final enteredAmount = text.parseFormattedDouble();

    double changeValue = 0.0;
    if (enteredAmount != null) {
      final calculated =
          double.parse((enteredAmount - widget.totalAmount).toStringAsFixed(2));
      changeValue = calculated >= 0 ? calculated : 0.0;
    }

    setState(() {
      _change = enteredAmount == null ? 0.0 : changeValue;
    });

    widget.onAmountChanged(enteredAmount);
    widget.onChangeCalculated(enteredAmount == null ? null : changeValue);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTotalAmount) ...[
          const SizedBox(height: 12),
          // Total a cobrar
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total a cobrar:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  widget.totalAmount.formatToCurrency(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 18,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 12),

        // Paga con
        Text(
          'Paga con:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          inputFormatters: [CurrencyInputFormatter()],
          onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.attach_money,
              color: AppColors.success,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            hintText: 'Ingrese el monto recibido',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          style: const TextStyle(fontSize: 16),
          onTap: () {
            _amountController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _amountController.text.length,
            );
          },
        ),
        const SizedBox(height: 16),

        // Vuelto
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: _change > 0
                ? AppColors.success.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _change > 0
                  ? AppColors.success.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt,
                    color: _change > 0 ? AppColors.success : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cambio:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: _change > 0 ? null : Colors.grey,
                        ),
                  ),
                ],
              ),
              Text(
                _change.formatToCurrency(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _change > 0 ? AppColors.success : Colors.grey,
                      fontSize: 18,
                    ),
              ),
            ],
          ),
        ),

        // Indicador de estado
        if (_amountController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildStatusIndicator(),
        ],
      ],
    );
  }

  Widget _buildStatusIndicator() {
    final enteredAmount =
        _amountController.text.trim().parseFormattedDouble() ?? 0.0;
    final roundedEntered = double.parse(enteredAmount.toStringAsFixed(2));
    final roundedTotal = double.parse(widget.totalAmount.toStringAsFixed(2));

    final isInsufficient = roundedEntered < roundedTotal;
    final isPerfect = roundedEntered == roundedTotal;

    if (isInsufficient) {
      final missing = roundedTotal - roundedEntered;
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning,
              size: 18,
              color: AppColors.warning,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Falta: ${missing.formatToCurrency()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    if (isPerfect) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 18,
              color: AppColors.success,
            ),
            const SizedBox(width: 8),
            Text(
              'Monto exacto',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
