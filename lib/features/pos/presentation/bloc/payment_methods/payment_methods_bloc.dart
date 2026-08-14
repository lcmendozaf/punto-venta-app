import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_payment_methods_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_payment_methods_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/save_payment_methods_config_usecase.dart';
import 'payment_methods_event.dart';
import 'payment_methods_state.dart';

class PaymentMethodsBloc
    extends Bloc<PaymentMethodsEvent, PaymentMethodsState> {
  final FetchPaymentMethodsUsecase fetchPaymentMethods;
  final FetchPaymentMethodsConfigUsecase fetchPaymentMethodsConfig;
  final SavePaymentMethodsConfigUsecase savePaymentMethodsConfig;

  PaymentMethodsBloc({
    required this.fetchPaymentMethods,
    required this.fetchPaymentMethodsConfig,
    required this.savePaymentMethodsConfig,
  }) : super(PaymentMethodsInitial()) {
    on<LoadPaymentMethods>(_onLoadPaymentMethods);
    on<SelectPaymentMethodEvent>(_onSelectPaymentMethod);
    on<SavePaymentMethodsConfigEvent>(_onSavePaymentMethodsConfig);
  }

  Future<void> _onLoadPaymentMethods(
      LoadPaymentMethods event, Emitter<PaymentMethodsState> emit) async {
    final currentState = state;
    final currentSelectedPaymentMethod = currentState is PaymentMethodsLoaded
        ? currentState.selectedPaymentMethod
        : null;

    emit(PaymentMethodsLoading());
    try {
      final allPaymentMethods = await fetchPaymentMethods();
      final paymentMethods = allPaymentMethods
          .where((pm) => pm.deleteAt.isEmpty)
          .toList();

      var selectedPaymentMethod = currentSelectedPaymentMethod;
      if ((selectedPaymentMethod == null ||
              !paymentMethods.any((pm) => pm.id == selectedPaymentMethod!.id)) &&
          paymentMethods.isNotEmpty) {
        selectedPaymentMethod = paymentMethods.first;
      } else if (paymentMethods.isEmpty) {
        selectedPaymentMethod = null;
      }

      emit(PaymentMethodsLoaded(
        paymentMethods: paymentMethods,
        selectedPaymentMethod: selectedPaymentMethod,
      ));
    } catch (e) {
      emit(PaymentMethodsError(e.toString()));
    }
  }

  void _onSelectPaymentMethod(
      SelectPaymentMethodEvent event, Emitter<PaymentMethodsState> emit) {
    final current = state;
    if (current is PaymentMethodsLoaded) {
      emit(PaymentMethodsLoaded(
          paymentMethods: current.paymentMethods,
          selectedPaymentMethod: event.paymentMethod));
    } else {
      emit(PaymentMethodsLoaded(
          paymentMethods: [], selectedPaymentMethod: event.paymentMethod));
    }
  }

  Future<void> _onSavePaymentMethodsConfig(
      SavePaymentMethodsConfigEvent event,
      Emitter<PaymentMethodsState> emit) async {
    emit(PaymentMethodsSaving());
    try {
      await savePaymentMethodsConfig(event.config);
      emit(PaymentMethodsConfigSaved());
      add(LoadPaymentMethods());
    } catch (e) {
      emit(PaymentMethodsError(e.toString()));
    }
  }
}
