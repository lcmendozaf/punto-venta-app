import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/themes/theme_cubit.dart';
import 'package:punto_venta_app/core/widgets/scroll_bottom_extension.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_empty_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_log_item_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_panel_header.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_summary_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation_panel.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/scanner_mode_content_widget.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/common/error_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cash_register/cash_register_cubit.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cash_register/cash_register_state.dart';

class CartPanel extends StatefulWidget {
  const CartPanel({super.key});

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  final ScrollController _scrollController = ScrollController();
  int _lastLogLength = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CheckoutBloc, CheckoutState>(
          listener: (context, checkoutState) {
            if (checkoutState is CheckoutSuccess) {
              final uiState = context.read<UiBloc>().state;
              final isReturnMode =
                  uiState is UiLoaded ? uiState.isReturnMode : false;

              // Imprimir ticket de venta
              if (!isReturnMode) {
                context.read<PrinterBloc>().add(PrintTicket(
                      printJob: checkoutState.printJob,
                    ));
              }

              // Limpiar el carrito y cerrar el panel de confirmación
              context.read<CartBloc>().add(ClearCart());
              context.read<CheckoutBloc>().add(const ResetCheckout());
              context.read<ClientsBloc>().add(ResetToDefaultClientEvent());

              if (isReturnMode) {
                context.read<UiBloc>().add(ToggleReturnMode());
              }
              context.read<UiBloc>().add(CloseConfirmationPanel());

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isReturnMode
                      ? 'Devolución procesada exitosamente'
                      : 'Venta procesada exitosamente'),
                  backgroundColor: AppColors.success,
                ),
              );
            } else if (checkoutState is CheckoutError) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext dialogContext) {
                  return ErrorDialog(
                    message: checkoutState.message,
                    onAccept: () {
                      context.read<CheckoutBloc>().add(const ResetCheckout());
                    },
                  );
                },
              );
            }
          },
        ),
        BlocListener<PrinterBloc, PrinterState>(
          listener: (context, printerState) {
            if (printerState is PrinterSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(printerState.message),
                  backgroundColor: AppColors.success,
                ),
              );
            } else if (printerState is PrinterError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(printerState.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<UiBloc, UiState>(
        builder: (context, uiState) {
          final isBarcodeMode =
              uiState is UiLoaded ? uiState.isBarcodeSearchEnabled : true;
          final isReturnMode =
              uiState is UiLoaded ? uiState.isReturnMode : false;
          final showConfirmation =
              uiState is UiLoaded ? uiState.showConfirmationPanel : false;

          return BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) {
              final isDark = mode == ThemeMode.dark;
              final backgroundColor = isDark
                  ? AppColors.sidebarDarkBackground
                  : AppColors.sidebarLightBackground;
              final borderColor = isDark
                  ? AppColors.sidebarDarkDivider
                  : AppColors.sidebarLightDivider;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final panelWidth = constraints.maxWidth;
                  return Stack(
                    children: [
                      // Panel principal del carrito
                      Container(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                        ),
                        child: Column(
                          children: [
                            const CartPanelHeader(),
                            // Contenido del panel
                            Expanded(
                              child: BlocConsumer<CartBloc, CartState>(
                                listener: (context, state) {
                                  if (state is CartLoaded && !isBarcodeMode) {
                                    if (state.log.length != _lastLogLength) {
                                      _lastLogLength = state.log.length;
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (_scrollController.hasClients) {
                                          _scrollController.scrollToBottom();
                                        }
                                      });
                                    }
                                  } else {
                                    _lastLogLength = 0;
                                  }
                                },
                                builder: (context, state) {
                                  if (state is CartLoaded) {
                                    if (!isBarcodeMode &&
                                        state.log.isNotEmpty) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (_scrollController.hasClients) {
                                          _scrollController.scrollToBottom();
                                        }
                                      });
                                    }
                                    final subtotal = state.subtotal;
                                    final totalIva = state.totalIva;
                                    final totalConIva = state.totalConIva;

                                    return Column(
                                      children: [
                                        // Área principal: logs o mensaje según el modo
                                        Expanded(
                                          child: isBarcodeMode
                                              ? const ScannerModeContent()
                                              : Padding(
                                                  padding: const EdgeInsets.all(
                                                      AppDimensions.paddingS),
                                                  child: state.log.isEmpty
                                                      ? const CartEmptyWidget()
                                                      : ListView.builder(
                                                          controller:
                                                              _scrollController,
                                                          itemCount:
                                                              state.log.length,
                                                          itemBuilder:
                                                              (context, index) {
                                                            final entry = state
                                                                .log[index];
                                                            return CartLogItemWidget(
                                                                entry: entry);
                                                          },
                                                        ),
                                                ),
                                        ),
                                        const Divider(height: 1),
                                        // monto, botones de cartPanel ( confirmar venta o devolucion)
                                        BlocBuilder<CashRegisterCubit,
                                            CashRegisterState>(
                                          builder: (context, registerState) {
                                            final isConfirmEnabled =
                                                registerState
                                                        is CashRegisterLoaded &&
                                                    registerState.status.isOpen;

                                            return CartSummary(
                                              subtotal: subtotal,
                                              totalIva: totalIva,
                                              totalConIva: totalConIva,
                                              isReturnMode: isReturnMode,
                                              isConfirmEnabled:
                                                  isConfirmEnabled,
                                              onClear: () {
                                                showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                            'Limpiar Pedido'),
                                                        content: const Text(
                                                            '¿Está seguro de que desea limpiar el carrito?'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                                'Cancelar'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                              context
                                                                  .read<
                                                                      CartBloc>()
                                                                  .add(
                                                                      ClearCart());
                                                            },
                                                            child: const Text(
                                                                'Confirmar'),
                                                          ),
                                                        ],
                                                      );
                                                    });
                                              },
                                              onConfirm: () {
                                                if (state.items.isNotEmpty) {
                                                  if (!isBarcodeMode) {
                                                    context.read<UiBloc>().add(
                                                        ToggleBarcodeSearch());
                                                  }
                                                  context.read<UiBloc>().add(
                                                      OpenConfirmationPanel());
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  }
                                  return const CartEmptyWidget();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Panel de confirmación expandido ( dependiendo de showConfirmation)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        right: showConfirmation ? 0 : -panelWidth,
                        top: 0,
                        bottom: 0,
                        width: panelWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            border: Border(
                              left: BorderSide(color: borderColor, width: 2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(-2, 0),
                              ),
                            ],
                          ),
                          child: ConfirmationPanel(
                            key: ValueKey(showConfirmation),
                            onClose: () {
                              context
                                  .read<UiBloc>()
                                  .add(CloseConfirmationPanel());
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
