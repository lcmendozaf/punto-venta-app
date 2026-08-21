import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/refund/refund_dialog.dart';

class CartPanelHeader extends StatelessWidget {
  const CartPanelHeader({super.key});

  void _changeMode(BuildContext context, bool toReturnMode) {
    context.read<UiBloc>().add(ToggleReturnMode());
    context.read<CartBloc>().add(ClearCart());
  }

  void _showChangeModeConfirmation(BuildContext context, bool toReturnMode) {
    final cartState = context.read<CartBloc>().state;
    final hasItems = cartState is CartLoaded && cartState.items.isNotEmpty;

    if (!hasItems) {
      _changeMode(context, toReturnMode);
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Limpiar Pedido'),
        content: Text(
          'Al cambiar a modo ${toReturnMode ? "Devolución" : "Venta"}, '
          'se limpiará el pedido actual. ¿Desea continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _changeMode(context, toReturnMode);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showClearCartConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Limpiar Pedido'),
        content: const Text('¿Está seguro de que desea limpiar el carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<CartBloc>().add(ClearCart());
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          final total = cartState is CartLoaded ? cartState.totalConIva : 0.0;
          final hasItems =
              cartState is CartLoaded && cartState.items.isNotEmpty;

          return BlocBuilder<UiBloc, UiState>(
            builder: (context, uiState) {
              final isReturnMode =
                  uiState is UiLoaded ? uiState.isReturnMode : false;

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Lado izquierdo: Título y etiqueta de Modo
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppStrings.cartSummary,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                isReturnMode
                                    ? Icons.assignment_return_outlined
                                    : Icons.shopping_cart_outlined,
                                size: 14,
                                color: isReturnMode
                                    ? AppColors.warning
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isReturnMode ? 'Devolución' : 'Venta',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isReturnMode
                                      ? AppColors.warning
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Lado derecho: Total y Hamburguesa (Menú)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Total

                          const SizedBox(width: 12),
                          // Menú Hamburguesa
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.menu, color: Colors.black87),
                            tooltip: 'Cambiar modo / vaciar / reintegro',
                            onSelected: (value) {
                              if (value == 'venta' && isReturnMode) {
                                _showChangeModeConfirmation(context, false);
                              } else if (value == 'devolucion' &&
                                  !isReturnMode) {
                                _showChangeModeConfirmation(context, true);
                              } else if (value == 'vaciar') {
                                _showClearCartConfirmation(context);
                              } else if (value == 'reintegro') {
                                showRefundDialog(context);
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'venta',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.shopping_cart_outlined,
                                      color: !isReturnMode
                                          ? AppColors.primary
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Venta',
                                      style: TextStyle(
                                        fontWeight: !isReturnMode
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: !isReturnMode
                                            ? AppColors.primary
                                            : Colors.black87,
                                      ),
                                    ),
                                    if (!isReturnMode) ...[
                                      const Spacer(),
                                      const Icon(Icons.check,
                                          color: AppColors.primary, size: 18),
                                    ],
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'devolucion',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.assignment_return_outlined,
                                      color: isReturnMode
                                          ? AppColors.warning
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Devolución',
                                      style: TextStyle(
                                        fontWeight: isReturnMode
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isReturnMode
                                            ? AppColors.warning
                                            : Colors.black87,
                                      ),
                                    ),
                                    if (isReturnMode) ...[
                                      const Spacer(),
                                      const Icon(Icons.check,
                                          color: AppColors.warning, size: 18),
                                    ],
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'reintegro',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.monetization_on_outlined,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Reintegro de dinero',
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'vaciar',
                                enabled: hasItems,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: hasItems
                                          ? AppColors.error
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Vaciar',
                                      style: TextStyle(
                                        color: hasItems
                                            ? AppColors.error
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.paddingS),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        total.formatToCurrency(),
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 36,
                                ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
