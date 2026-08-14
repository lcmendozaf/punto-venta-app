import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_return_reasons_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/calculate_order_taxes_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_event.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/confirmation_helpers.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method_config.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_branches_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_payment_methods_config_usecase.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_local_datasource.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import 'checkout_confirmation_state.dart';

class CheckoutConfirmationCubit extends Cubit<CheckoutConfirmationState> {
  final FetchReturnReasonsUsecase fetchReturnReasonsUsecase;
  final CalculateOrderTaxesUseCase calculateOrderTaxesUseCase;
  final CartBloc cartBloc;
  final ClientsBloc clientsBloc;

  late final StreamSubscription _cartSubscription;
  late final StreamSubscription _clientsSubscription;

  List<Branch> _allBranches = [];
  PaymentMethodsConfig? _paymentMethodsConfig;
  PdvConfig? _pdvConfig;
  bool _isReturnMode = false;

  CheckoutConfirmationCubit({
    required this.fetchReturnReasonsUsecase,
    required this.calculateOrderTaxesUseCase,
    required this.cartBloc,
    required this.clientsBloc,
  }) : super(const CheckoutConfirmationState()) {
    _cartSubscription = cartBloc.stream.listen((cartState) {
      _calculateTaxes(cartState, clientsBloc.state);
    });

    _clientsSubscription = clientsBloc.stream.listen((clientsState) {
      _calculateTaxes(cartBloc.state, clientsState);
    });
  }

  Future<void> load(PaymentMethod? defaultPaymentMethod, {bool isReturnMode = false}) async {
    _isReturnMode = isReturnMode;
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      // 1. Fetch return reasons
      final reasons = await fetchReturnReasonsUsecase();
      final defaultReasonId = reasons.isNotEmpty ? reasons.first.id : null;

      // Cargar datos de sucursales y configuraciones de métodos de pago
      _allBranches = await di.sl<FetchBranchesUsecase>()();
      _paymentMethodsConfig = await di.sl<FetchPaymentMethodsConfigUsecase>()();
      _pdvConfig = await di.sl<PdvLocalDataSource>().getPdvConfig();

      emit(state.copyWith(
        returnReasons: reasons,
        selectedReturnReasonId: defaultReasonId,
      ));

      // 2. Calculate taxes using injected UseCase
      await _calculateTaxes(cartBloc.state, clientsBloc.state,
          defaultPaymentMethod: defaultPaymentMethod);
      _updateActiveBranch();
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void selectReturnReason(int reasonId) {
    emit(state.copyWith(selectedReturnReasonId: reasonId));
  }

  void initializePayments(
      PaymentMethod? defaultPaymentMethod, double totalAmount) {
    if (state.selectedPayments.isNotEmpty) return;
    if (defaultPaymentMethod != null) {
      final payments = [defaultPaymentMethod.copyWith(amount: totalAmount)];
      final result = calculateChangeAndAmounts(payments, totalAmount);
      emit(state.copyWith(
        selectedPayments: payments,
        receivedAmount: result.receivedAmount,
        change: result.change,
      ));
      _updateActiveBranch();
    }
  }

  void selectSinglePaymentMethod(PaymentMethod method, double totalAmount) {
    if (state.selectedPayments.isEmpty ||
        (state.selectedPayments.length == 1 &&
            state.selectedPayments.first.id != method.id)) {
      final payments = [method.copyWith(amount: totalAmount)];
      final result = calculateChangeAndAmounts(payments, totalAmount);
      emit(state.copyWith(
        selectedPayments: payments,
        receivedAmount: result.receivedAmount,
        change: result.change,
        // Al cambiar de método de pago único, forzamos a recalcular la sucursal por defecto
        resetActiveBranch: true,
      ));
      _updateActiveBranch();
    }
  }

  void addPaymentMethod(
      PaymentMethod method, double defaultAmount, double totalAmount) {
    final updated = List<PaymentMethod>.from(state.selectedPayments);
    updated.add(method.copyWith(amount: defaultAmount));
    final result = calculateChangeAndAmounts(updated, totalAmount);
    emit(state.copyWith(
      selectedPayments: updated,
      receivedAmount: result.receivedAmount,
      change: result.change,
    ));
    _updateActiveBranch();
  }

  void removePaymentMethod(int index, double totalAmount) {
    if (index >= state.selectedPayments.length) return;
    final updated = List<PaymentMethod>.from(state.selectedPayments);
    updated.removeAt(index);

    if (updated.length == 1) {
      updated[0] = updated[0].copyWith(amount: totalAmount);
    }

    final result = calculateChangeAndAmounts(updated, totalAmount);
    emit(state.copyWith(
      selectedPayments: updated,
      receivedAmount: result.receivedAmount,
      change: result.change,
      // Si volvemos a un único método de pago, forzamos a recalcular la sucursal por defecto
      resetActiveBranch: updated.length == 1,
    ));
    _updateActiveBranch();
  }

  void updatePaymentAmount(int index, double amount, double totalAmount) {
    if (index >= state.selectedPayments.length) return;
    final updated = List<PaymentMethod>.from(state.selectedPayments);
    updated[index] = updated[index].copyWith(amount: amount);

    _rebalanceRemainingAmount(updated, index, totalAmount);

    final result = calculateChangeAndAmounts(updated, totalAmount);
    emit(state.copyWith(
      selectedPayments: updated,
      receivedAmount: result.receivedAmount,
      change: result.change,
    ));
  }

  void updatePaymentReceivedAmount(
      int index, double? receivedAmount, double totalAmount) {
    if (index >= state.selectedPayments.length) return;
    final updated = List<PaymentMethod>.from(state.selectedPayments);

    // Para evitar un bucle de retroalimentación donde el monto se limita por el balanceo
    // calculado en la pulsación anterior, calculamos el tope máximo (cap) sumando únicamente
    // los métodos que no son ni el actual (index) ni el que va a recibir el balanceo (targetIndex).
    double fixedSum = 0.0;
    int targetIndex = index;
    if (updated.length > 1) {
      targetIndex = (index + 1) % updated.length;
      for (int j = 0; j < updated.length; j++) {
        if (j != index && j != targetIndex) {
          fixedSum += updated[j].amount ?? 0.0;
        }
      }
    }
    double cap = totalAmount - fixedSum;
    if (cap < 0.0) cap = 0.0;

    final pm = updated[index];
    final isCash = _isCashMethod(pm);

    double? newAmount = pm.amount;
    if (isCash) {
      if (receivedAmount == null) {
        newAmount = 0.0;
      } else {
        newAmount = receivedAmount < cap ? receivedAmount : cap;
      }
    }

    updated[index] = updated[index].copyWith(
      amount: newAmount,
      receivedAmount: receivedAmount,
      clearReceivedAmount: receivedAmount == null,
    );

    _rebalanceRemainingAmount(updated, index, totalAmount);

    final result = calculateChangeAndAmounts(updated, totalAmount);
    emit(state.copyWith(
      selectedPayments: updated,
      receivedAmount: result.receivedAmount,
      change: result.change,
    ));
  }

  void updatePaymentDetails(int index, PaymentMethodDetails details) {
    if (index >= state.selectedPayments.length) return;
    final updated = List<PaymentMethod>.from(state.selectedPayments);
    updated[index] = updated[index].copyWith(details: details);

    emit(state.copyWith(
      selectedPayments: updated,
    ));
  }

  bool _isCashMethod(PaymentMethod pm) {
    return pm.description.toLowerCase().contains('efectivo') ||
        pm.shortDescription.toLowerCase().contains('efectivo');
  }

  void _rebalanceRemainingAmount(
      List<PaymentMethod> updated, int sourceIndex, double totalAmount) {
    if (updated.length <= 1) return;

    final targetIndex = (sourceIndex + 1) % updated.length;
    double sumOthers = 0.0;
    for (int j = 0; j < updated.length; j++) {
      if (j != targetIndex) {
        sumOthers += updated[j].amount ?? 0.0;
      }
    }
    double remaining = totalAmount - sumOthers;
    if (remaining < 0.0) remaining = 0.0;

    final targetPm = updated[targetIndex];
    updated[targetIndex] = targetPm.copyWith(
      amount: double.parse(remaining.toStringAsFixed(2)),
      clearReceivedAmount: _isCashMethod(targetPm),
    );
  }

  Future<void> _calculateTaxes(
    CartState cartState,
    ClientsState clientsState, {
    PaymentMethod? defaultPaymentMethod,
  }) async {
    if (cartState is! CartLoaded) {
      emit(state.copyWith(
        isLoading: false,
        iibbAmount: 0.0,
        vatPerceptionAmount: 0.0,
        internalTaxAmount: 0.0,
        totalAmount: 0.0,
      ));
      return;
    }

    final cartLoaded = cartState;
    final selectedClient =
        clientsState is ClientsLoaded ? clientsState.selectedClient : null;

    final taxResult = await calculateOrderTaxesUseCase(
      items: cartLoaded.items,
      subtotal: cartLoaded.subtotal,
      totalIva: cartLoaded.totalIva,
      client: selectedClient,
    );

    List<PaymentMethod> updatedPayments =
        List<PaymentMethod>.from(state.selectedPayments);
    if (updatedPayments.isEmpty && defaultPaymentMethod != null) {
      updatedPayments = [
        defaultPaymentMethod.copyWith(amount: taxResult.totalAmount)
      ];
    } else if (updatedPayments.length == 1) {
      updatedPayments[0] =
          updatedPayments[0].copyWith(amount: taxResult.totalAmount);
    }

    final result =
        calculateChangeAndAmounts(updatedPayments, taxResult.totalAmount);

    emit(state.copyWith(
      isLoading: false,
      iibbAmount: taxResult.iibbAmount,
      vatPerceptionAmount: taxResult.vatPerceptionAmount,
      internalTaxAmount: taxResult.internalTaxAmount,
      totalAmount: taxResult.totalAmount,
      selectedPayments: updatedPayments,
      receivedAmount: result.receivedAmount,
      change: result.change,
    ));
    _updateActiveBranch();
  }

  ProcessSale buildProcessSaleEvent({PaymentMethod? fallbackPaymentMethod}) {
    final cartState = cartBloc.state;
    final clientsState = clientsBloc.state;

    final items =
        cartState is CartLoaded ? cartState.items : const <CartItem>[];
    final logItems =
        cartState is CartLoaded ? cartState.log : const <CartLogEntry>[];
    final total = cartState is CartLoaded ? cartState.total : 0.0;
    final totalIva = cartState is CartLoaded ? cartState.totalIva : 0.0;
    final subtotal = cartState is CartLoaded ? cartState.subtotal : 0.0;

    final selectedClient =
        clientsState is ClientsLoaded ? clientsState.selectedClient : null;

    return ProcessSale(
      items: items,
      logItems: logItems,
      total: total,
      totalIva: totalIva,
      subtotal: subtotal,
      client: selectedClient,
      paymentMethod: state.selectedPayments.isNotEmpty
          ? state.selectedPayments.first
          : fallbackPaymentMethod,
      paymentMethods:
          state.selectedPayments.isNotEmpty ? state.selectedPayments : null,
      receivedAmount: state.receivedAmount,
      change: state.change,
      branchId: state.activeBranchId,
    );
  }

  void selectBranch(int branchId) {
    final branch = _allBranches.firstWhere(
      (b) => b.id == branchId,
      orElse: () => const Branch(
          id: -1,
          name: '',
          afipAvailable: false,
          applyPerIibb: false,
          applyPerVat: false),
    );
    if (branch.id != -1) {
      emit(state.copyWith(
        activeBranchId: branchId,
        activeBranchName: branch.name,
      ));
    }
  }

  void _updateActiveBranch() {
    if (_allBranches.isEmpty || _pdvConfig == null) return;

    final payments = state.selectedPayments;
    int? activeBranchId;
    String? activeBranchName;
    List<Branch> allowedBranches = [];

    // Si es devolución o no hay métodos de pago seleccionados, permitimos seleccionar todas las sucursales, seleccionando por defecto la del PDV
    if (_isReturnMode || payments.isEmpty) {
      allowedBranches = List<Branch>.from(_allBranches);
      if (state.activeBranchId != null &&
          allowedBranches.any((b) => b.id == state.activeBranchId)) {
        activeBranchId = state.activeBranchId;
      } else {
        activeBranchId = _pdvConfig?.branchId;
      }
    } else {
      // 1. Obtener la prioridad mínima más alta entre los métodos elegidos
      int maxMinPriority = 0;
      for (final payment in payments) {
        final pmConfig = _paymentMethodsConfig?.paymentMethodsConfig.firstWhere(
          (c) => c.paymentMethodId == payment.id,
          orElse: () => const PaymentMethodConfig(
              paymentMethodId: -1, branchesSelected: []),
        );
        if (pmConfig != null &&
            pmConfig.paymentMethodId != -1 &&
            pmConfig.minBranchPriority != null) {
          if (pmConfig.minBranchPriority! > maxMinPriority) {
            maxMinPriority = pmConfig.minBranchPriority!;
          }
        }
      }

      // 2. Calcular la intersección de sucursales habilitadas que cumplan con la condición de prioridad mínima
      // Los métodos de pago con una prioridad mínima menor que el máximo requerido no restringen la selección.
      Set<int>? commonBranchIds;

      for (final payment in payments) {
        final pmConfig = _paymentMethodsConfig?.paymentMethodsConfig.firstWhere(
          (c) => c.paymentMethodId == payment.id,
          orElse: () => const PaymentMethodConfig(
              paymentMethodId: -1, branchesSelected: []),
        );

        final pmPriority = pmConfig?.minBranchPriority ?? 0;
        if (pmPriority < maxMinPriority) {
          continue;
        }

        final Set<int> allowedForMethod = {};

        if (pmConfig != null && pmConfig.paymentMethodId != -1) {
          // Si tiene sucursales explícitas configuradas
          if (pmConfig.branchesSelected.isNotEmpty) {
            final validBranches = pmConfig.branchesSelected.where((branchId) {
              final branch = _allBranches.firstWhere(
                (b) => b.id == branchId,
                orElse: () => const Branch(
                  id: -1,
                  name: '',
                  afipAvailable: false,
                  applyPerIibb: false,
                  applyPerVat: false,
                ),
              );
              if (branch.id == -1) return false;
              return (branch.priority ?? 0) >= maxMinPriority;
            });
            allowedForMethod.addAll(validBranches);
          } else {
            // Si la lista de sucursales está vacía pero tiene prioridad mínima configurada
            final matchingBranches = _allBranches
                .where((b) => (b.priority ?? 0) >= maxMinPriority)
                .map((b) => b.id);
            allowedForMethod.addAll(matchingBranches);
          }
        } else {
          // Si no hay configuración para este método de pago, permite todas las sucursales que cumplan con la prioridad mínima
          final matchingBranches = _allBranches
              .where((b) => (b.priority ?? 0) >= maxMinPriority)
              .map((b) => b.id);
          allowedForMethod.addAll(matchingBranches);
        }

        // Realizar la intersección de sucursales comunes
        if (commonBranchIds == null) {
          commonBranchIds = allowedForMethod;
        } else {
          commonBranchIds = commonBranchIds.intersection(allowedForMethod);
        }
      }

      // 3. Mapear los IDs comunes a objetos de tipo Branch
      if (commonBranchIds != null && commonBranchIds.isNotEmpty) {
        allowedBranches =
            _allBranches.where((b) => commonBranchIds!.contains(b.id)).toList();
      }

      // 4. Determinar la sucursal activa
      if (allowedBranches.isEmpty) {
        // Si no hay intersección o no hay coincidencia, retrocedemos al default del PDV
        final defaultBranch = _allBranches.firstWhere(
          (b) => b.id == _pdvConfig?.branchId,
          orElse: () => const Branch(
              id: -1,
              name: '',
              afipAvailable: false,
              applyPerIibb: false,
              applyPerVat: false),
        );
        if (defaultBranch.id != -1) {
          allowedBranches = [defaultBranch];
        }
        activeBranchId = _pdvConfig?.branchId;
      } else {
        // Si la sucursal seleccionada anteriormente sigue siendo válida dentro del nuevo conjunto, la conservamos
        final currentActiveInAllowed =
            allowedBranches.any((b) => b.id == state.activeBranchId);
        if (!currentActiveInAllowed) {
          // De lo contrario, seleccionamos por defecto la de la configuración del PDV si está entre las permitidas
          final hasPdvBranch = allowedBranches.any((b) => b.id == _pdvConfig?.branchId);
          if (hasPdvBranch) {
            activeBranchId = _pdvConfig?.branchId;
          } else {
            // Sino, seleccionamos la que tenga mayor prioridad
            Branch? bestBranch;
            for (final branch in allowedBranches) {
              if (bestBranch == null ||
                  (branch.priority ?? 0) > (bestBranch.priority ?? 0)) {
                bestBranch = branch;
              }
            }
            activeBranchId = bestBranch?.id;
          }
        } else {
          activeBranchId = state.activeBranchId;
        }
      }
    }

    // Buscar el nombre de la sucursal activa seleccionada para mostrar en el panel de confirmación
    if (activeBranchId != null) {
      final activeBranch = _allBranches.firstWhere(
        (b) => b.id == activeBranchId,
        orElse: () => const Branch(
            id: -1,
            name: '',
            afipAvailable: false,
            applyPerIibb: false,
            applyPerVat: false),
      );
      if (activeBranch.id != -1) {
        activeBranchName = activeBranch.name;
      }
    }

    emit(state.copyWith(
      activeBranchId: activeBranchId,
      activeBranchName: activeBranchName,
      allowedBranches: allowedBranches,
    ));
  }

  ConfirmReturn buildConfirmReturnEvent() {
    final cartState = cartBloc.state;
    final items =
        cartState is CartLoaded ? cartState.items : const <CartItem>[];
    final logItems =
        cartState is CartLoaded ? cartState.log : const <CartLogEntry>[];

    return ConfirmReturn(
      reasonId: state.selectedReturnReasonId ?? -1,
      items: items,
      logItems: logItems,
      branchId: state.activeBranchId,
    );
  }

  @override
  Future<void> close() {
    _cartSubscription.cancel();
    _clientsSubscription.cancel();
    return super.close();
  }
}
