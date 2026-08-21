import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_settlements_usecase.dart';
import 'settlements_event.dart';
import 'settlements_state.dart';

class SettlementsBloc extends Bloc<SettlementsEvent, SettlementsState> {
  final GetSettlementsUsecase getSettlementsUsecase;

  SettlementsBloc({required this.getSettlementsUsecase})
      : super(SettlementsInitial()) {
    on<FetchPendingCollectors>(_fetchPendingCollectors);
    on<FetchPendingCollectorDetail>(_fetchPendingCollectorDetail);
  }

  Future<void> _fetchPendingCollectors(
    FetchPendingCollectors event,
    Emitter<SettlementsState> emit,
  ) async {
    emit(SettlementsLoading());

    try {
      final pendingCollectors =
          await getSettlementsUsecase.getAllSettlementsPendingCollectors(event.date);

      emit(SettlementsLoaded(pendingCollectors));
    } catch (e) {
      emit(SettlementsError(e.toString()));
    }
  }

  Future<void> _fetchPendingCollectorDetail(
    FetchPendingCollectorDetail event,
    Emitter<SettlementsState> emit,
  ) async {
    emit(SettlementsLoading());

    try {
      final pendingCollectorDetail = await getSettlementsUsecase
          .getPendingCollectorDetail(event.collectorId, event.date);

      emit(PendingCollectorsDetailLoaded(pendingCollectorDetail));
    } catch (e) {
      emit(SettlementsError(e.toString()));
    }
  }
}
