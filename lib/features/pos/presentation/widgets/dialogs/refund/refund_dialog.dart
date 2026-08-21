import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_branches_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_pdv_config_usecase.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_local_datasource.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/refunds/refunds_cubit.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/refunds/refunds_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/common/error_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_event.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

void showRefundDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => BlocProvider(
      create: (context) => di.sl<RefundsCubit>()..loadReasons(),
      child: const RefundDialog(),
    ),
  );
}

class RefundDialog extends StatefulWidget {
  const RefundDialog({super.key});

  @override
  State<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<RefundDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  List<Branch> _branches = [];
  int? _selectedBranchId;
  int? _selectedReasonId;
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final branches = await di.sl<FetchBranchesUsecase>()();
      PdvConfig? pdvConfig;
      try {
        pdvConfig = await di.sl<FetchPdvConfigUsecase>()();
      } catch (_) {
        pdvConfig = await di.sl<PdvLocalDataSource>().getPdvConfig();
      }

      if (mounted) {
        setState(() {
          _branches = branches;
          _selectedBranchId = pdvConfig?.branchId ??
              (branches.isNotEmpty ? branches.first.id : null);
          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access current client
    final clientsState = context.read<ClientsBloc>().state;
    final client =
        clientsState is ClientsLoaded ? clientsState.selectedClient : null;

    return BlocConsumer<RefundsCubit, RefundsState>(
      listener: (context, state) {
        if (state.status == RefundsStatus.success) {
          // if (state.printJob != null) {
          //   context.read<PrinterBloc>().add(PrintTicket(
          //         printJob: state.printJob!,
          //       ));
          // }
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reintegro de dinero procesado con éxito.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.status == RefundsStatus.error &&
            state.errorMessage != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogCtx) => ErrorDialog(
              message: state.errorMessage!,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoadingReasons = state.status == RefundsStatus.loading;
        final isSubmitting = state.status == RefundsStatus.submitting;
        final showLoading = _loadingData || isLoadingReasons;

        // Auto select first reason when loaded
        if (state.status == RefundsStatus.loaded &&
            _selectedReasonId == null &&
            state.reasons.isNotEmpty) {
          _selectedReasonId = state.reasons.first.id;
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          title: const Row(
            children: [
              Icon(Icons.monetization_on_outlined, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Reintegro de Dinero'),
            ],
          ),
          content: showLoading
              ? const SizedBox(
                  height: 150,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : SizedBox(
                  width: 420,
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Banner de Cliente Actual
                          Container(
                            padding: const EdgeInsets.all(
                                AppDimensions.paddingS + 4),
                            decoration: BoxDecoration(
                              color: client == null
                                  ? AppColors.warning.withValues(alpha: 0.1)
                                  : AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: client == null
                                    ? AppColors.warning.withValues(alpha: 0.3)
                                    : AppColors.success.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  client == null
                                      ? Icons.person_off
                                      : Icons.person,
                                  color: client == null
                                      ? AppColors.warning
                                      : AppColors.success,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    client == null
                                        ? 'Cliente: CONSUMIDOR FINAL'
                                        : 'Cliente: ${client.name} (ID: ${client.id})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: client == null
                                          ? AppColors.warning
                                          : AppColors.success,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppDimensions.paddingM),

                          // Dropdown de Sucursal
                          DropdownButtonFormField<int>(
                            initialValue: _selectedBranchId,
                            decoration: const InputDecoration(
                              labelText: 'Sucursal',
                              border: OutlineInputBorder(),
                              prefixIcon:
                                  Icon(Icons.business_rounded, size: 20),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            items: _branches
                                .map((branch) => DropdownMenuItem<int>(
                                      value: branch.id,
                                      child: Text(branch.name),
                                    ))
                                .toList(),
                            onChanged: isSubmitting
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedBranchId = value;
                                    });
                                  },
                            validator: (value) => value == null
                                ? 'Seleccione una sucursal'
                                : null,
                          ),
                          const SizedBox(height: AppDimensions.paddingM),

                          // Campo de Monto a Reintegrar
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            enabled: !isSubmitting,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [CurrencyInputFormatter()],
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).unfocus(),
                            decoration: const InputDecoration(
                              labelText: 'Monto a Reintegrar',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(
                                Icons.attach_money,
                                color: AppColors.success,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            onTap: () {
                              _amountController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _amountController.text.length,
                              );
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese un monto';
                              }
                              final amount =
                                  value.trim().parseFormattedDouble();
                              if (amount == null || amount <= 0) {
                                return 'Ingrese un monto válido mayor a 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppDimensions.paddingM),

                          // Dropdown de Motivos
                          DropdownButtonFormField<int>(
                            initialValue: _selectedReasonId,
                            decoration: const InputDecoration(
                              labelText: 'Motivo de Reingreso',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.info_outline, size: 20),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            items: state.reasons
                                .map((reason) => DropdownMenuItem<int>(
                                      value: reason.id,
                                      child: Text(reason.description),
                                    ))
                                .toList(),
                            onChanged: isSubmitting
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedReasonId = value;
                                    });
                                  },
                            validator: (value) =>
                                value == null ? 'Seleccione un motivo' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          actions: [
            TextButton(
              onPressed:
                  isSubmitting ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isSubmitting || showLoading
                  ? null
                  : () {
                      if (_formKey.currentState?.validate() ?? false) {
                        final amount = _amountController.text
                                .trim()
                                .parseFormattedDouble() ??
                            0.0;
                        context.read<RefundsCubit>().submitRefund(
                              branchId: _selectedBranchId!,
                              refundAmount: amount,
                              refundReasonId: _selectedReasonId!,
                              clientId: client?.id,
                            );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }
}
