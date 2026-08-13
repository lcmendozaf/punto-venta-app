import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/generate_credit_note_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_reports_usecase.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final GetReportsUsecase getReportsUsecase;
  final GenerateCreditNoteUsecase generateCreditNoteUsecase;

  // Paginación
  int _currentPage = 1;
  final int _pageSize = 10;
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;
  bool _isAllReportsMode = false;
  String? _currentTypeCode;

  ReportsBloc(
      {required this.getReportsUsecase,
      required this.generateCreditNoteUsecase})
      : super(ReportsInitial()) {
    on<LoadAllReports>(_onLoadAllReports);
    on<LoadMoreReports>(_onLoadMoreReports);
    on<LoadReportsByDateRange>(_onLoadReportsByDateRange);
    on<LoadDailySummary>(_onLoadDailySummary);
    on<GenerateCreditNote>(_convertToCreditNote);
  }

  Future<void> _onLoadAllReports(
    LoadAllReports event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());
    _currentPage = 1;
    _isAllReportsMode = true;
    _currentStartDate = null;
    _currentEndDate = null;
    _currentTypeCode = event.typeCode;

    try {
      // Se hace llamado a back si falla se usa local
      try {
        final skip = (_currentPage - 1) * _pageSize;
        final orders = await getReportsUsecase.getAllCompletedOrdersFromRemote(
            skip: skip, limit: _pageSize, typeCode: event.typeCode);
        emit(ReportsLoaded(orders, hasMoreData: orders.length >= _pageSize));
      } catch (remoteError) {
        // TODO: CAMBIAR PARA USAR EL MISMO MODELO TicketResponseModel

        // print('Error fetching from remote, using local data: $remoteError');
        // final orders = await getReportsUsecase.getAllCompletedOrders();
        // emit(ReportsLoaded(orders, hasMoreData: false));
      }
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }

  Future<void> _onLoadMoreReports(
    LoadMoreReports event,
    Emitter<ReportsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ReportsLoaded ||
        currentState.isLoadingMore ||
        !currentState.hasMoreData) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));
    _currentPage++;

    try {
      List<CompletedOrder> newOrders;
      final skip = (_currentPage - 1) * _pageSize;

      if (_isAllReportsMode) {
        newOrders = await getReportsUsecase.getAllCompletedOrdersFromRemote(
          skip: skip,
          limit: _pageSize,
          typeCode: _currentTypeCode,
        );
      } else if (_currentStartDate != null) {
        newOrders = await getReportsUsecase.getOrdersByDateRangeFromRemote(
          _currentStartDate!,
          endDate: _currentEndDate,
          skip: skip,
          limit: _pageSize,
          typeCode: _currentTypeCode,
        );
      } else {
        emit(currentState.copyWith(isLoadingMore: false));
        return;
      }

      final updatedOrders = List<CompletedOrder>.from(currentState.tickets)
        ..addAll(newOrders);

      emit(ReportsLoaded(
        updatedOrders,
        summary: currentState.summary,
        hasMoreData: newOrders.length >= _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      print('Error loading more reports: $e');
      emit(currentState.copyWith(isLoadingMore: false, hasMoreData: false));
    }
  }

  Future<void> _onLoadReportsByDateRange(
    LoadReportsByDateRange event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());
    _currentPage = 1;
    _isAllReportsMode = false;
    _currentStartDate = event.startDate;
    _currentEndDate = event.endDate;
    _currentTypeCode = event.typeCode;

    try {
      try {
        final skip = (_currentPage - 1) * _pageSize;

        final orders = await getReportsUsecase.getOrdersByDateRangeFromRemote(
            event.startDate,
            endDate: event.endDate,
            skip: skip,
            limit: _pageSize,
            typeCode: event.typeCode);
        emit(ReportsLoaded(orders, hasMoreData: orders.length >= _pageSize));
      } catch (remoteError) {
        // TODO: CAMBIAR PARA USAR EL MISMO MODELO TicketResponseModel

        // print('Error fetching from remote, using local data: $remoteError');
        // final orders = await getReportsUsecase.getOrdersByDateRange(
        //     event.startDate, event.endDate);
        // emit(ReportsLoaded(orders, hasMoreData: false));
      }
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }

  Future<void> _onLoadDailySummary(
    LoadDailySummary event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());
    _currentPage = 1;
    _isAllReportsMode = false;
    _currentStartDate =
        DateTime(event.date.year, event.date.month, event.date.day);
    _currentEndDate = null;
    _currentTypeCode = event.typeCode;

    try {
      try {
        final skip = (_currentPage - 1) * _pageSize;

        final summary = await getReportsUsecase.getDailySummaryFromRemote(
            event.date,
            skip: skip,
            limit: _pageSize,
            typeCode: event.typeCode);

        final orders = summary['orders'] as List<CompletedOrder>;

        emit(ReportsLoaded(orders,
            summary: summary, hasMoreData: orders.length >= _pageSize));
      } catch (remoteError) {
        // TODO: CAMBIAR PARA USAR EL MISMO MODELO TicketResponseModel

        // print('Error fetching from remote, using local data: $remoteError');
        // final summary = await getReportsUsecase.getDailySummary(event.date);
        // final orders = summary['orders'] as List<CompletedOrder>;
        // emit(ReportsLoaded(orders, summary: summary, hasMoreData: false));
      }
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }

  // Metodo para pasar un ticket (VE, venta) a (NC, nota de crédito)
  Future<void> _convertToCreditNote(
      GenerateCreditNote event, Emitter<ReportsState> emit) async {
    final currentState = state;

    try {
      await generateCreditNoteUsecase(event.ticketId, event.reasonId);

      emit(CreditNoteGenerated(
        ticketId: event.ticketId,
        message:
            'Se creó una nota de crédito vinculada al ticket ${event.ticketId}.',
      ));

      if (currentState is ReportsLoaded) {
        final updatedTickets = currentState.tickets.map((t) {
          if (t.id == event.ticketId) {
            return t.copyWith(isAnnulled: true);
          }
          return t;
        }).toList();

        emit(ReportsLoaded(
          updatedTickets,
          summary: currentState.summary,
          hasMoreData: currentState.hasMoreData,
          isLoadingMore: currentState.isLoadingMore,
        ));
      }
    } catch (e) {
      String message = e.toString();
      while (message.startsWith('Exception: ')) {
        message = message.replaceFirst('Exception: ', '');
      }

      emit(CreditNoteGenerationError(
        ticketId: event.ticketId,
        message: 'Error al generar nota de crédito: $message',
      ));

      if (currentState is ReportsLoaded) {
        emit(currentState);
      }
    }
  }
}
