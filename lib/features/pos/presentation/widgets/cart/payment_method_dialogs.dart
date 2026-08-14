import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';

/// Diálogo para seleccionar el método de pago principal (Flujo único)
void showPaymentMethodsSelectorDialog({
  required BuildContext context,
  required List<PaymentMethod> paymentMethods,
  required PaymentMethod? selectedPaymentMethod,
  required IconData Function(String description, String shortDescription)
      getPaymentMethodIcon,
  required Function(PaymentMethod pm) onSelected,
}) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text(
          'Seleccionar Método de Pago',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: paymentMethods.map((pm) {
                final isSelected = selectedPaymentMethod?.id == pm.id;
                final icon =
                    getPaymentMethodIcon(pm.description, pm.shortDescription);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      onSelected(pm);
                      Navigator.of(dialogContext).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              icon,
                              color:
                                  isSelected ? AppColors.primary : Colors.grey,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pm.description,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  pm.shortDescription,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}

/// Diálogo para agregar un nuevo método de pago (Flujo dividido)
void showAddPaymentMethodDialog({
  required BuildContext context,
  required List<PaymentMethod> allMethods,
  required List<PaymentMethod> selectedPayments,
  required double totalAmount,
  required double totalAllocated,
  required IconData Function(String description, String shortDescription)
      getPaymentMethodIcon,
  required Function(PaymentMethod pm, double defaultAmount) onMethodAdded,
}) {
  final selectedIds = selectedPayments.map((pm) => pm.id).toSet();

  final available = allMethods.where((pm) {
    final isCash = pm.description.toLowerCase().contains('efectivo') ||
        pm.shortDescription.toLowerCase().contains('efectivo');
    // Si es efectivo y ya está agregada exactamente esa misma opción (por ID), se filtra
    if (isCash && selectedIds.contains(pm.id)) {
      return false;
    }
    return true;
  }).toList();

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text(
          'Agregar Método de Pago',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: available.map((pm) {
                final icon =
                    getPaymentMethodIcon(pm.description, pm.shortDescription);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      // se pasa el restante al nuevo metodo de pago y se cierra el dialog.
                      final remaining = totalAmount - totalAllocated;
                      final defaultAmount = remaining > 0 ? remaining : 0.0;

                      onMethodAdded(pm, defaultAmount);

                      Navigator.of(dialogContext).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              icon,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pm.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  pm.shortDescription,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      );
    },
  );
}
