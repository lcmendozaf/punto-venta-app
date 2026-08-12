import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/load_ordes_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/save_order_usecase.dart';
import 'saved_orders_event.dart';
import 'saved_orders_state.dart';

class SavedOrdersBloc extends Bloc<SavedOrdersEvent, SavedOrdersState> {
  final SaveOrderUsecase saveOrderUsecase;
  final LoadSavedOrdersUsecase loadSavedOrdersUsecase;
  final SharedPreferences sharedPreferences;

  SavedOrdersBloc({
    required this.saveOrderUsecase,
    required this.loadSavedOrdersUsecase,
    required this.sharedPreferences,
  }) : super(SavedOrdersInitial()) {
    on<LoadSavedOrders>(_onLoadSavedOrders);
    on<SaveCurrentOrder>(_onSaveCurrentOrder);
    on<DeleteSavedOrder>(_onDeleteSavedOrder);
    on<LoadOrderById>(_onLoadOrderById);
  }

  Future<void> _onLoadSavedOrders(
    LoadSavedOrders event,
    Emitter<SavedOrdersState> emit,
  ) async {
    emit(SavedOrdersLoading());
    try {
      final orders = await loadSavedOrdersUsecase();
      emit(SavedOrdersLoaded(orders));
    } catch (e) {
      emit(SavedOrdersError(e.toString()));
    }
  }

  Future<void> _onSaveCurrentOrder(
    SaveCurrentOrder event,
    Emitter<SavedOrdersState> emit,
  ) async {
    try {
      final ticketId = sharedPreferences.getString('current_ticket_id');
      await saveOrderUsecase(
        name: event.name,
        items: event.items,
        logs: event.logItems,
        total: event.total,
        clientName: event.clientName,
        ticketId: ticketId,
      );
      emit(const OrderSaved('Pedido guardado exitosamente'));

      // Recargar la lista de pedidos guardados
      final orders = await loadSavedOrdersUsecase();
      emit(SavedOrdersLoaded(orders));
    } catch (e) {
      emit(SavedOrdersError(e.toString()));
    }
  }

  Future<void> _onDeleteSavedOrder(
    DeleteSavedOrder event,
    Emitter<SavedOrdersState> emit,
  ) async {
    try {
      await loadSavedOrdersUsecase.deleteOrder(event.orderId);
      emit(const OrderDeleted('Pedido eliminado exitosamente'));

      // Recargar la lista de pedidos guardados
      final orders = await loadSavedOrdersUsecase();
      emit(SavedOrdersLoaded(orders));
    } catch (e) {
      emit(SavedOrdersError(e.toString()));
    }
  }

  Future<void> _onLoadOrderById(
    LoadOrderById event,
    Emitter<SavedOrdersState> emit,
  ) async {
    try {
      final order = await loadSavedOrdersUsecase.getOrderById(event.orderId);
      if (order != null) {
        emit(OrderLoadedById(order));
      } else {
        emit(const SavedOrdersError('Pedido no encontrado'));
      }
    } catch (e) {
      emit(SavedOrdersError(e.toString()));
    }
  }
}
