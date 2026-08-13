import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';

class PdvSelectedClientStatus extends StatelessWidget {
  final Client? selectedClient;
  final bool isAdmin;

  const PdvSelectedClientStatus({
    super.key,
    required this.selectedClient,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final String message;
    final Color bgColor = AppColors.primary.withValues(alpha: 0.1);
    final Color borderColor = AppColors.primary.withValues(alpha: 0.3);
    final IconData icon;
    const Color iconColor = AppColors.primary;
    final Color textColor;

    if (selectedClient != null) {
      message =
          'Cliente seleccionado: ${selectedClient!.name} [${selectedClient!.id}]';
      icon = Icons.check_circle;
      textColor = Colors.black87;
    } else if (isAdmin) {
      message = 'Selecciona un cliente default';
      icon = Icons.warning_amber;
      textColor = Colors.black87;
    } else {
      message =
          'No se ha guardado el Cliente Default. Por favor, pide a un Admin que lo configure.';
      icon = Icons.error_outline;
      textColor = Colors.red.shade700;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: selectedClient == null && !isAdmin
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
