import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/dialogs/logout_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/pdv_settings_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/printer_settings_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/price_list_selector_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/payment_methods_settings_dialog.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        final currentList = state is ProductLoaded ? state.currentPriceList : 1;

        return AlertDialog(
          title: const Text('Configuración de administrador'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActionCard(
                    icon: Icons.print,
                    iconColor: Colors.teal,
                    backgroundColor: Colors.teal.withValues(alpha: 0.1),
                    title: 'Configurar impresoras',
                    subtitle: 'Configurar Ip de impresoras de tickets',
                    onTap: () {
                      final navigatorContext = Navigator.of(context).context;
                      Navigator.of(context).pop();
                      showPrinterSettingsDialog(navigatorContext);
                    },
                  ),
                  const SizedBox(height: 10),
                  ActionCard(
                    icon: Icons.attach_money,
                    iconColor: Colors.teal,
                    backgroundColor: Colors.teal.withValues(alpha: 0.1),
                    title: 'Lista de Precios',
                    subtitle:
                        'Cambiar lista de precios activa (Actual: Lista $currentList)',
                    onTap: () {
                      final navigatorContext = Navigator.of(context).context;
                      Navigator.of(context).pop();
                      showPriceListSelectorDialog(
                          navigatorContext, currentList);
                    },
                  ),
                  const SizedBox(height: 10),
                  ActionCard(
                    icon: Icons.point_of_sale,
                    iconColor: Colors.teal,
                    backgroundColor: Colors.teal.withValues(alpha: 0.1),
                    title: 'Configurar PDV',
                    subtitle: 'Configurar datos del punto de venta',
                    onTap: () {
                      final navigatorContext = Navigator.of(context).context;
                      Navigator.of(context).pop();
                      showPdvSettingsDialog(navigatorContext, true);
                    },
                  ),
                  const SizedBox(height: 10),
                  ActionCard(
                    icon: Icons.monetization_on_rounded,
                    iconColor: Colors.teal,
                    backgroundColor: Colors.teal.withValues(alpha: 0.1),
                    title: 'Configurar Metodos de Pago',
                    subtitle: 'Vincular metodos de pago con sucursales',
                    onTap: () {
                      final navigatorContext = Navigator.of(context).context;
                      Navigator.of(context).pop();
                      showPaymentMethodsSettingsDialog(navigatorContext);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}
