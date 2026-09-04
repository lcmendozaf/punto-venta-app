import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:punto_venta_app/core/constants/ticket_template_types.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/branch_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/vat_category_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/vat_category_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/fiscal_issuer_data.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/fiscal_issuer_data_repository.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/complete_order_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_ticket_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/send_invoice_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/ticket_template_resolver.dart';
import 'checkout_event.dart';
import 'checkout_state.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/process_partial_return_usecase.dart';
import 'package:punto_venta_app/features/pos/data/models/partial_return_request_model.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/calculate_order_taxes_usecase.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final AuthLocalDataSource authLocalDataSource;
  final PdvLocalDataSource pdvLocalDataSource;
  final PriceListLocalDataSource priceListLocalDataSource;
  final BranchLocalDataSource branchLocalDataSource;
  final VatCategoryLocalDataSource vatCategoryLocalDataSource;
  final FiscalIssuerDataRepository fiscalIssuerDataRepository;
  final CompleteOrderUsecase completeOrderUsecase;
  final GetTicketConfigUsecase getTicketConfigUsecase;
  final SendInvoiceUseCase sendInvoiceUseCase;
  final ProcessPartialReturnUseCase processPartialReturnUseCase;
  final CalculateOrderTaxesUseCase calculateOrderTaxesUseCase;
  final SharedPreferences sharedPreferences;

  CheckoutBloc({
    required this.authLocalDataSource,
    required this.pdvLocalDataSource,
    required this.priceListLocalDataSource,
    required this.branchLocalDataSource,
    required this.vatCategoryLocalDataSource,
    required this.fiscalIssuerDataRepository,
    required this.completeOrderUsecase,
    required this.getTicketConfigUsecase,
    required this.sendInvoiceUseCase,
    required this.processPartialReturnUseCase,
    required this.calculateOrderTaxesUseCase,
    required this.sharedPreferences,
  }) : super(const CheckoutInitial()) {
    on<ProcessSale>(_onProcessSale);
    on<ResetCheckout>(_onResetCheckout);
    on<ConfirmReturn>(_onConfirmReturn);
  }

  Future<void> _onProcessSale(
    ProcessSale event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(const CheckoutProcessing());

    try {
      // Obtener datos necesarios
      final user = await authLocalDataSource.getCachedUser();
      final priceList = await priceListLocalDataSource.getCurrentPriceList();
      final enterprise = await authLocalDataSource.getCachedEnterprise();
      final config = await pdvLocalDataSource.getPdvConfig();

      // Validar número de sucursal
      final branchNumber = config?.branchNumber ?? '';

      // Obtener información de la sucursal y categoría IVA para determinar plantillas
      final branchIdToUse = event.branchId ?? config?.branchId;
      final branch = branchIdToUse != null
          ? await branchLocalDataSource.getBranchById(branchIdToUse)
          : null;

      // Calcular impuestos usando el caso de uso centralizado
      final taxResult = await calculateOrderTaxesUseCase(
        items: event.items,
        subtotal: event.subtotal,
        totalIva: event.totalIva,
        client: event.client,
      );

      final iibbAmount = taxResult.iibbAmount;
      final iibbPercentage = taxResult.iibbPercentage;
      final vatPerceptionAmount = taxResult.vatPerceptionAmount;
      final vatPerceptionByRate = taxResult.vatPerceptionByRate;
      final internalTaxAmount = taxResult.internalTaxAmount;
      final internalTaxRate = taxResult.internalTaxRate;
      final totalWithIibb = taxResult.totalAmount;

      // Determinar template automáticamente
      TicketTemplateType templateType = TicketTemplateType.standard;

      templateType = TicketTemplateResolver.resolveTemplate(
        branchAfipAvailable: branch?.afipAvailable,
      );

      // Obtener datos fiscales del emisor si es operación en blanco
      FiscalIssuerData? fiscalData;
      if (branch?.afipAvailable == true && config?.branchId != null) {
        try {
          fiscalData = await fiscalIssuerDataRepository.getFiscalIssuerData();
        } catch (e) {
          print('Error al obtener datos fiscales: $e');
        }
      }

      final currentTicketId =
          sharedPreferences.getString('current_ticket_id') ?? const Uuid().v4();

      // Crear PrintJob (sin ticketId definitivo)
      final tempPrintJob = PrintJob(
        ticketId: currentTicketId,
        items: event.items,
        logItems: event.logItems,
        total: totalWithIibb,
        clientName: event.client?.name,
        client: event.client,
        priceListId: priceList,
        totalTax: event.totalIva,
        iibbTax: iibbAmount,
        iibbTaxPercentage: iibbPercentage,
        vatPerception: vatPerceptionAmount,
        vatPerceptionByRate: vatPerceptionByRate,
        internalTax: internalTaxAmount,
        internalTaxRate: internalTaxRate,
        paymentMethod: event.paymentMethod,
        paymentMethods: event.paymentMethods,
        cashierName: user?.name ?? 'Desconocido',
        cashierId: int.tryParse(user?.id ?? ''),
        timestamp: DateTime.now(),
        enterprise: enterprise,
        fiscalIssuerData: fiscalData,
        receivedAmount: event.receivedAmount,
        change: event.change,
        branchNumber: branchNumber,
        branchId: branchIdToUse,
        templateType: templateType,
      );

      // Enviar factura y obtener ticketId y description
      final invoiceResponse = await sendInvoiceUseCase(tempPrintJob);

      // Eliminar el ticketId de SharedPreferences tras una respuesta exitosa del backend
      await sharedPreferences.remove('current_ticket_id');

      final ticketId = invoiceResponse.ticketId;
      final description = invoiceResponse.description;
      final cae = invoiceResponse.cae;
      final caeDueDate = invoiceResponse.caeDueDate;
      final detailedTaxes = invoiceResponse.detailedTaxes;
      final caeQrCode = invoiceResponse.caeQrCode;

      // PrintJob final con el ticketId y description
      final finalPrintJob = PrintJob(
        ticketId: ticketId,
        items: event.items,
        logItems: event.logItems,
        total: totalWithIibb,
        clientName: event.client?.name,
        client: event.client,
        priceListId: priceList,
        totalTax: event.totalIva,
        iibbTax: iibbAmount,
        iibbTaxPercentage: iibbPercentage,
        vatPerception: vatPerceptionAmount,
        vatPerceptionByRate: vatPerceptionByRate,
        internalTax: internalTaxAmount,
        internalTaxRate: internalTaxRate,
        paymentMethod: event.paymentMethod,
        paymentMethods: event.paymentMethods,
        cashierName: user?.name ?? 'Desconocido',
        cashierId: int.tryParse(user?.id ?? ''),
        timestamp: tempPrintJob.timestamp,
        enterprise: enterprise,
        fiscalIssuerData: fiscalData,
        showSubtotalAndTax: detailedTaxes,
        showPricesWithTax: detailedTaxes,
        receivedAmount: event.receivedAmount,
        change: event.change,
        branchNumber: branchNumber,
        branchId: branchIdToUse,
        description: description,
        templateType: templateType,
        cae: cae,
        caeDueDate: caeDueDate,
        caeQrCode: caeQrCode,
      );

      await completeOrderUsecase.fromPrintJob(finalPrintJob);

      emit(CheckoutSuccess(printJob: finalPrintJob));
    } catch (e) {
      emit(CheckoutError(message: _extractErrorMessage(e)));
    }
  }

  Future<VatCategoryModel?> _getVatCategoryById(int vatCategoryId) async {
    final categories =
        await vatCategoryLocalDataSource.getCachedVatCategories();

    if (categories == null) {
      return null;
    }

    try {
      final found = categories.firstWhere((c) => c.id == vatCategoryId);
      return found;
    } catch (e) {
      return null;
    }
  }

  void _onResetCheckout(ResetCheckout event, Emitter<CheckoutState> emit) {
    emit(const CheckoutInitial());
  }

  String _extractErrorMessage(dynamic error) {
    String message = error.toString();
    while (message.startsWith('Exception: ')) {
      message = message.replaceFirst('Exception: ', '');
    }
    return message;
  }

  Future<void> _onConfirmReturn(
    ConfirmReturn event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(const CheckoutProcessing());

    try {
      final config = await pdvLocalDataSource.getPdvConfig();
      final priceList = await priceListLocalDataSource.getCurrentPriceList();
      final branchId = event.branchId ?? config?.branchId;
      final deliveryLocationId = config?.pdvId;

      // Obtener información de la sucursal y categoría IVA para determinar plantillas
      final branchIdToUse = event.branchId ?? config?.branchId;
      final branch = branchIdToUse != null
          ? await branchLocalDataSource.getBranchById(branchIdToUse)
          : null;

      if (branchId == null || deliveryLocationId == null) {
        emit(const CheckoutError(
          message:
              'Configure la sucursal y la ubicación antes de hacer devoluciones.',
        ));
        return;
      }

      final returnItems = event.items.map((item) {
        final isWeighted = item.isWeighted == true;
        return PartialReturnItemModel(
          articleId: item.product.id,
          priceListId: priceList,
          quantity: isWeighted ? 1.0 : item.quantity.toDouble(),
          isWeighted: isWeighted ? 'S' : 'N',
          netWeight: isWeighted ? item.product.netWeight : null,
          weight: isWeighted ? (item.weightKg ?? 0.0) : null,
        );
      }).toList();

      final request = PartialReturnRequestModel(
        reasonId: event.reasonId,
        branchId: branchId,
        deliveryLocationId: deliveryLocationId,
        items: returnItems,
      );

      final completedOrder = await processPartialReturnUseCase(request);

      if (completedOrder == null) {
        emit(const CheckoutError(
            message: 'Error al procesar la devolución. Intente nuevamente.'));
        return;
      }

      // Convertir completedOrder en un PrintJob
      final user = await authLocalDataSource.getCachedUser();
      final enterprise = await authLocalDataSource.getCachedEnterprise();

      // Obtener datos fiscales del emisor si es operación en blanco
      FiscalIssuerData? fiscalData;
      if (branch?.afipAvailable == true && config?.branchId != null) {
        try {
          fiscalData = await fiscalIssuerDataRepository.getFiscalIssuerData();
        } catch (e) {
          print('Error al obtener datos fiscales para devoluciones: $e');
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
      );

      emit(CheckoutSuccess(printJob: printJob));
    } catch (e) {
      emit(CheckoutError(message: _extractErrorMessage(e)));
    }
  }
}
