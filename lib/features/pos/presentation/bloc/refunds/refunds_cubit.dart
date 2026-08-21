import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/domain/entities/fiscal_issuer_data.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/fiscal_issuer_data_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/refunds_repository.dart';
import 'refunds_state.dart';

class RefundsCubit extends Cubit<RefundsState> {
  final RefundsRepository repository;
  final AuthLocalDataSource authLocalDataSource;
  final FiscalIssuerDataRepository fiscalIssuerDataRepository;

  RefundsCubit({
    required this.repository,
    required this.authLocalDataSource,
    required this.fiscalIssuerDataRepository,
  }) : super(const RefundsState());

  Future<void> loadReasons() async {
    emit(state.copyWith(status: RefundsStatus.loading, errorMessage: null));
    try {
      final reasons = await repository.fetchRefundReasons();
      emit(state.copyWith(
        status: RefundsStatus.loaded,
        reasons: reasons,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RefundsStatus.error,
        errorMessage: _extractErrorMessage(e),
      ));
    }
  }

  Future<void> submitRefund({
    required int branchId,
    required double refundAmount,
    required int refundReasonId,
    int? clientId,
  }) async {
    emit(state.copyWith(status: RefundsStatus.submitting, errorMessage: null));
    try {
      final completedOrder = await repository.processCashRefund(
        branchId: branchId,
        refundAmount: refundAmount,
        refundReasonId: refundReasonId,
        clientId: clientId,
      );

      final user = await authLocalDataSource.getCachedUser();
      final enterprise = await authLocalDataSource.getCachedEnterprise();

      FiscalIssuerData? fiscalData;
      if (completedOrder.branchId != null) {
        try {
          fiscalData = await fiscalIssuerDataRepository
              .getFiscalIssuerData(completedOrder.branchId!);
        } catch (e) {
          print('Error al obtener datos fiscales para devolución en cash: $e');
        }
      }

      final printJob = PrintJob(
        ticketId: completedOrder.id,
        items: completedOrder.items,
        logItems: completedOrder.logs,
        total: completedOrder.total,
        clientName: completedOrder.clientName,
        client: completedOrder.client,
        priceListId: completedOrder.priceListId,
        totalTax: completedOrder.totalTax,
        iibbTax: completedOrder.iibbTax,
        iibbTaxPercentage: completedOrder.iibbTaxPercentage,
        vatPerception: completedOrder.vatPerception,
        vatPerceptionByRate: completedOrder.vatPerceptionByRate,
        internalTax: completedOrder.internalTax,
        internalTaxRate: completedOrder.internalTaxRate,
        paymentMethod: completedOrder.paymentMethod,
        paymentMethods: completedOrder.paymentMethods,
        cashierName: completedOrder.cashierName,
        cashierId: completedOrder.cashierId ?? int.tryParse(user?.id ?? ''),
        timestamp: completedOrder.completedAt,
        enterprise: enterprise,
        fiscalIssuerData: fiscalData,
        showSubtotalAndTax: completedOrder.showSubtotalAndTax,
        showPricesWithTax: completedOrder.showPricesWithTax,
        receivedAmount: completedOrder.receivedAmount,
        change: completedOrder.change,
        branchNumber: completedOrder.branchNumber ?? '',
        branchId: completedOrder.branchId,
        description: completedOrder.description,
        templateType: completedOrder.templateType,
        isCreditNote: true,
        cae: completedOrder.cae,
        caeDueDate: completedOrder.caeDueDate,
        caeQrCode: completedOrder.caeQrCode,
      );

      emit(state.copyWith(
        status: RefundsStatus.success,
        printJob: printJob,
      ));
    } catch (e, stack) {
      debugPrint('[RefundsCubit] submitRefund Exception: $e');
      debugPrint('[RefundsCubit] submitRefund StackTrace: $stack');
      emit(state.copyWith(
        status: RefundsStatus.error,
        errorMessage: _extractErrorMessage(e),
      ));
    }
  }

  String _extractErrorMessage(dynamic error) {
    String message = error.toString();
    while (message.startsWith('Exception: ')) {
      message = message.replaceFirst('Exception: ', '');
    }
    return message;
  }
}
