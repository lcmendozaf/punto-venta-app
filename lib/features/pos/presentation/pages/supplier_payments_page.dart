import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/supplier_payments/suppliers_list_panel.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/supplier_payments/supplier_payment_header.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/supplier_payments/service_provider_flow.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/supplier_payments/merchandise_supplier_flow.dart';

class SupplierPaymentsPage extends StatefulWidget {
  const SupplierPaymentsPage({super.key});

  @override
  State<SupplierPaymentsPage> createState() => _SupplierPaymentsPageState();
}

class _SupplierPaymentsPageState extends State<SupplierPaymentsPage> {
  final TextEditingController _remitoController = TextEditingController();
  final TextEditingController _ticketController = TextEditingController();
  final TextEditingController _totalPaidController = TextEditingController();
  final TextEditingController _totalChargedController = TextEditingController();

  @override
  void dispose() {
    _remitoController.dispose();
    _ticketController.dispose();
    _totalPaidController.dispose();
    _totalChargedController.dispose();
    super.dispose();
  }

  void _resetForms() {
    _remitoController.clear();
    _ticketController.clear();
    _totalPaidController.clear();
    _totalChargedController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: BlocListener<SupplierPaymentsBloc, SupplierPaymentsState>(
        listener: (context, state) {
          if (state.status == SupplierPaymentStatus.success) {
            _resetForms();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pago a proveedor registrado con éxito'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context
                .read<SupplierPaymentsBloc>()
                .add(ResetSupplierPaymentFormEvent());
          } else if (state.status == SupplierPaymentStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(state.errorMessage ?? 'Error al procesar el pago'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: SuppliersListPanel(
                onSupplierSelected: _resetForms,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: isDark ? AppColors.darkDivider : Colors.grey.shade300,
            ),
            Expanded(
              flex: 8,
              child: _buildFormPanel(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPanel(bool isDark) {
    return BlocBuilder<SupplierPaymentsBloc, SupplierPaymentsState>(
      builder: (context, state) {
        final provider = state.selectedSupplier;
        if (provider == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 64,
                  color: isDark
                      ? AppColors.darkTextSecondary.withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                ),
                const SizedBox(height: AppDimensions.paddingM),
                Text(
                  'Selecciona un proveedor para iniciar el flujo de pago',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              SupplierPaymentHeader(
                supplier: provider,
                onDeselected: _resetForms,
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Form fields & flow content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Document numbers (disabled for now)
                      // ProviderDocumentSection(
                      //   remitoController: _remitoController,
                      //   ticketController: _ticketController,
                      // ),
                      // const SizedBox(height: AppDimensions.paddingM),

                      // Flow depending on provider type
                      if (provider.isServiceProvider)
                        ServiceProviderFlow(
                          totalPaidController: _totalPaidController,
                        )
                      else
                        MerchandiseSupplierFlow(
                          state: state,
                          totalPaidController: _totalPaidController,
                        ),
                    ],
                  ),
                ),
              ),

              // Submit / Cancel actions
              const SizedBox(height: AppDimensions.paddingM),
              _buildActionBar(state, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionBar(SupplierPaymentsState state, bool isDark) {
    final isSubmitting = state.status == SupplierPaymentStatus.submitting;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(
              color: isDark ? AppColors.darkDivider : Colors.grey.shade300,
            ),
          ),
          onPressed: isSubmitting
              ? null
              : () {
                  _resetForms();
                  context
                      .read<SupplierPaymentsBloc>()
                      .add(ResetSupplierPaymentFormEvent());
                },
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.paddingM),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          onPressed: isSubmitting ? null : () => _submitPayment(state),
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Confirmar Pago',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  void _submitPayment(SupplierPaymentsState state) {
    if (state.selectedSupplier == null) return;

    // Validation
    if (state.selectedSupplier!.isServiceProvider) {
      if (state.totalPaid <= 0) {
        _showErrorSnackBar('El monto que se entrega debe ser mayor a 0');
        return;
      }
    } else {
      if (state.items.isEmpty) {
        _showErrorSnackBar('Debes agregar al menos un producto');
        return;
      }
    }

    // Retrieve Cashier and Branch IDs from Blocs
    final authState = context.read<AuthBloc>().state;

    final user = authState is AuthAuthenticated ? authState.user : null;

    final userId = int.tryParse(user?.id ?? '') ?? 1;

    context.read<SupplierPaymentsBloc>().add(
          SubmitSupplierPaymentEvent(
            userId: userId,
          ),
        );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
