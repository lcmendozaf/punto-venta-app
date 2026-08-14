import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method_config.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_branches_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_payment_methods_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_payment_methods_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/confirmation_helpers.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

Future<void> showPaymentMethodsSettingsDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const PaymentMethodsSettingsDialog(),
  );
}

class PaymentMethodsSettingsDialog extends StatefulWidget {
  const PaymentMethodsSettingsDialog({super.key});

  @override
  State<PaymentMethodsSettingsDialog> createState() =>
      _PaymentMethodsSettingsDialogState();
}

class _PaymentMethodsSettingsDialogState
    extends State<PaymentMethodsSettingsDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Branch> _branches = [];
  List<PaymentMethod> _paymentMethods = [];
  final Map<int, List<int>> _selectedBranches = {};
  final Map<int, int?> _minBranchPriorities = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final pmBloc = context.read<PaymentMethodsBloc>();
    try {
      final branchesFuture = di.sl<FetchBranchesUsecase>()();
      final configFuture = di.sl<FetchPaymentMethodsConfigUsecase>()();
      final pmFuture = di.sl<FetchPaymentMethodsUsecase>()();

      final results = await Future.wait([branchesFuture, configFuture, pmFuture]);
      final branches = results[0] as List<Branch>;
      final config = results[1] as PaymentMethodsConfig;
      final paymentMethods = results[2] as List<PaymentMethod>;

      if (pmBloc.state is! PaymentMethodsLoaded) {
        pmBloc.add(LoadPaymentMethods());
      }

      if (!mounted) return;
      setState(() {
        _branches = branches;
        _paymentMethods = paymentMethods;
        for (final item in config.paymentMethodsConfig) {
          _selectedBranches[item.paymentMethodId] =
              List<int>.from(item.branchesSelected);
          _minBranchPriorities[item.paymentMethodId] = item.minBranchPriority;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los datos: $e';
        _isLoading = false;
      });
    }
  }

  void _onSave() {
    final list = _paymentMethods.map((pm) {
      return PaymentMethodConfig(
        paymentMethodId: pm.id,
        branchesSelected: _selectedBranches[pm.id] ?? [],
        minBranchPriority: _minBranchPriorities[pm.id],
      );
    }).toList();

    final config = PaymentMethodsConfig(paymentMethodsConfig: list);
    context
        .read<PaymentMethodsBloc>()
        .add(SavePaymentMethodsConfigEvent(config));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentMethodsBloc, PaymentMethodsState>(
      listener: (context, state) {
        if (state is PaymentMethodsConfigSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Configuración de métodos de pago guardada'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is PaymentMethodsError) {
          setState(() {
            _errorMessage = state.message;
          });
        }
      },
      builder: (context, state) {
        final isSaving = state is PaymentMethodsSaving;
        final showLoading = _isLoading || state is PaymentMethodsLoading;

        return AlertDialog(
          title: const Text('Configurar Métodos de Pago'),
          content: SizedBox(
            width: 500,
            child: showLoading
                ? const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Info banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Selecciona las sucursales en las que cada método de pago estará habilitado.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingM),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.red.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                        ],

                        if (_paymentMethods.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text('No hay métodos de pago activos.'),
                            ),
                          )
                        else
                          ..._paymentMethods.map((pm) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      child: Icon(
                                        getPaymentMethodIcon(
                                          pm.description,
                                          pm.shortDescription,
                                        ),
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    title: Text(
                                      pm.shortDescription,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(pm.description),
                                  ),
                                  const Divider(height: 1),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Wrap(
                                      spacing: 8.0,
                                      runSpacing: 6.0,
                                      children: _branches.map((branch) {
                                        final branchIds =
                                            _selectedBranches[pm.id] ?? [];
                                        final isSelected =
                                            branchIds.contains(branch.id);
                                        return FilterChip(
                                          label: Text(branch.name),
                                          selected: isSelected,
                                          onSelected: isSaving
                                              ? null
                                              : (selected) {
                                                  setState(() {
                                                    if (selected) {
                                                      _selectedBranches[pm.id] =
                                                          [
                                                        ...branchIds,
                                                        branch.id
                                                      ];
                                                    } else {
                                                      _selectedBranches[pm.id] =
                                                          branchIds
                                                              .where(
                                                                (id) =>
                                                                    id !=
                                                                    branch.id,
                                                              )
                                                              .toList();
                                                    }
                                                  });
                                                },
                                          selectedColor: AppColors.primary
                                              .withValues(alpha: 0.15),
                                          checkmarkColor: AppColors.primary,
                                          labelStyle: TextStyle(
                                            color: isSelected
                                                ? AppColors.primary
                                                : Colors.black87,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            side: BorderSide(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: showLoading || isSaving ? null : _onSave,
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}
