import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/search_bar.dart/search_weight_helper.dart';

Future<double?> showWeightInputDialog(
  BuildContext context, {
  required Product product,
  bool isDeleteMode = false,
}) {
  return showDialog<double>(
    context: context,
    barrierDismissible: false,
    builder: (_) => WeightInputDialog(
      product: product,
      isDeleteMode: isDeleteMode,
    ),
  );
}

class WeightInputDialog extends StatefulWidget {
  final Product product;
  final bool isDeleteMode;

  const WeightInputDialog({
    super.key,
    required this.product,
    this.isDeleteMode = false,
  });

  @override
  State<WeightInputDialog> createState() => _WeightInputDialogState();
}

class _WeightInputDialogState extends State<WeightInputDialog> {
  final TextEditingController _weightController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int? get _parsedGrams {
    final raw = _weightController.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  double? get _weightKg {
    final grams = _parsedGrams;
    if (grams == null || grams <= 0) return null;
    return grams / 1000.0;
  }

  double get _lineTotal {
    final weightKg = _weightKg;
    if (weightKg == null) return 0;
    return calculateWeightedLineTotal(widget.product, weightKg);
  }

  void _submit() {
    final weightKg = _weightKg;
    if (weightKg == null) {
      setState(() {
        _errorText = 'Ingresá un peso en gramos mayor a 0';
      });
      return;
    }
    Navigator.of(context).pop(weightKg);
  }

  @override
  Widget build(BuildContext context) {
    final unitPrice = widget.product.netWeight > 0
        ? (widget.product.price ?? 0.0)
        : 0.0;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
      ),
      title: const Row(
        children: [
          Icon(Icons.scale, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(child: Text('Ingresar pesaje')),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.product.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Precio: ${unitPrice.formatToCurrency()} / kg',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            TextField(
              controller: _weightController,
              focusNode: _focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                labelText: 'Peso (gramos)',
                hintText: '250',
                errorText: _errorText,
                suffixText: 'g',
                helperText: _weightKg == null
                    ? 'Ej: 250 = 0,250 kg'
                    : '${_parsedGrams} g = ${_weightKg!.toStringAsFixed(3)} kg',
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                } else {
                  setState(() {});
                }
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusS),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isDeleteMode ? 'A descontar' : 'Total',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _lineTotal.formatToCurrency(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: widget.isDeleteMode
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                widget.isDeleteMode ? AppColors.error : AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.isDeleteMode ? 'Quitar' : 'Agregar'),
        ),
      ],
    );
  }
}
