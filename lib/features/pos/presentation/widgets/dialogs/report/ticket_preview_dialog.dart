import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/ticket_template_types.dart';
import 'package:punto_venta_app/core/constants/ticket_types.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/domain/entities/fiscal_issuer_data.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/fiscal_issuer_data_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/payment_method_repository.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_state.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_return_reasons_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_returns_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/report/print_type_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/report/return_reason_dialog.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

class TicketPreviewDialog extends StatelessWidget {
  final CompletedOrder ticket;

  const TicketPreviewDialog({
    super.key,
    required this.ticket,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<PrinterBloc>(),
      child: _TicketPreviewContent(ticket: ticket),
    );
  }
}

class _TicketPreviewContent extends StatefulWidget {
  final CompletedOrder ticket;

  const _TicketPreviewContent({required this.ticket});

  @override
  State<_TicketPreviewContent> createState() => _TicketPreviewContentState();
}

class _TicketPreviewContentState extends State<_TicketPreviewContent> {
  PrintJob? _printJob;
  CompletedOrder? _recalculatedTicket;
  String _paymentMethodName = 'Desconocido';
  bool _isGeneratingCreditNote = false;
  int? _originalSaleId;
  String? _returnReasonDescription;

  bool get _isCreditNote => TicketType.isNotaCredito(widget.ticket.typeCode);

  bool get _isAnnulledFactura =>
      widget.ticket.isAnnulled && TicketType.isFactura(widget.ticket.typeCode);

  @override
  void initState() {
    super.initState();
    _initializePrintJob();
    _loadPaymentMethod();
    if (TicketType.isNotaCredito(widget.ticket.typeCode)) {
      _loadReturnMetadata();
    }
  }

  Future<void> _loadReturnMetadata() async {
    try {
      final ticketId = int.tryParse(widget.ticket.id);
      if (ticketId == null) return;

      final returns = await di.sl<FetchReturnsUsecase>()(
        date: widget.ticket.completedAt,
      );
      final matches = returns.where((r) => r.ncSaleId == ticketId).toList();
      if (matches.isEmpty || !mounted) return;
      final match = matches.first;

      final reasons = await di.sl<FetchReturnReasonsUsecase>()();
      final reasonMatches =
          reasons.where((r) => r.id == match.reasonId).toList();
      final reasonDescription =
          reasonMatches.isNotEmpty ? reasonMatches.first.description : null;

      if (mounted) {
        setState(() {
          _originalSaleId = match.saleId;
          _returnReasonDescription = reasonDescription;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPaymentMethod() async {
    try {
      final paymentMethodRepo = di.sl<PaymentMethodRepository>();
      final paymentMethods = await paymentMethodRepo.fetchPaymentMethods();

      final paymentMethod = paymentMethods.firstWhere(
        (pm) => pm.id == widget.ticket.paymentMethod,
        orElse: () => paymentMethods.first,
      );

      if (mounted) {
        setState(() {
          _paymentMethodName = paymentMethod.shortDescription;
        });
      }
    } catch (e) {}
  }

  // Construir el PrintJob a partir de la orden completada
  Future<void> _initializePrintJob() async {
    final localDs = di.sl<AuthLocalDataSource>();
    final enterprise = await localDs.getCachedEnterprise();
    CompletedOrder ticketToUse = widget.ticket;

    final iibbAmount = ticketToUse.iibbTax;
    final iibbPercentage = ticketToUse.iibbTaxPercentage;
    final vatPerceptionAmount = ticketToUse.vatPerception;
    final vatPerceptionByRate = ticketToUse.vatPerceptionByRate;
    final internalTaxAmount = ticketToUse.internalTax;
    final internalTaxRate = ticketToUse.internalTaxRate;
    final ivaAmount = ticketToUse.totalTax;
    final branchNumber = ticketToUse.branchNumber;
    final branchId = ticketToUse.branchId;
    final priceListId = ticketToUse.priceListId;
    final cashierId = ticketToUse.cashierId;
    final client = ticketToUse.client;

    final templateType = ticketToUse.templateType;

    FiscalIssuerData? fiscalData;
    if (templateType == TicketTemplateType.whiteMarket && branchId != null) {
      try {
        final fiscalRepo = di.sl<FiscalIssuerDataRepository>();
        fiscalData = await fiscalRepo.getFiscalIssuerData();
      } catch (e) {
        print('Error al obtener datos fiscales para reimpresión: $e');
      }
    }

    final printJob = PrintJob(
      items: ticketToUse.items,
      logItems: ticketToUse.logs,
      total: ticketToUse.total,
      clientName: ticketToUse.clientName,
      client: client,
      priceListId: priceListId,
      totalTax: ivaAmount,
      iibbTax: iibbAmount,
      iibbTaxPercentage: iibbPercentage,
      vatPerception: vatPerceptionAmount,
      vatPerceptionByRate: vatPerceptionByRate,
      internalTax: internalTaxAmount,
      internalTaxRate: internalTaxRate,
      paymentMethod: ticketToUse.paymentMethod,
      paymentMethods: ticketToUse.paymentMethods,
      cashierName: ticketToUse.cashierName,
      cashierId: cashierId,
      timestamp: ticketToUse.completedAt,
      ticketId: ticketToUse.id,
      enterprise: enterprise,
      fiscalIssuerData: fiscalData,
      showSubtotalAndTax: ticketToUse.showSubtotalAndTax,
      showPricesWithTax: ticketToUse.showPricesWithTax,
      change: ticketToUse.change,
      receivedAmount: ticketToUse.receivedAmount,
      branchNumber: branchNumber ?? '',
      branchId: branchId,
      description: ticketToUse.description,
      templateType: templateType,
      isCopy: false,
      isCreditNote: _isCreditNote,
      cae: ticketToUse.cae,
      caeDueDate: ticketToUse.caeDueDate,
      caeQrCode: ticketToUse.caeQrCode,
    );

    if (mounted) {
      setState(() {
        _printJob = printJob;
        _recalculatedTicket = ticketToUse;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_printJob == null) {
      return const Dialog(
        child: SizedBox(
          width: 450,
          height: 200,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<PrinterBloc, PrinterState>(
          listener: (context, state) {
            if (state is PrinterSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is PrinterError) {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Atención'),
                    ],
                  ),
                  content: Text(state.message),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            }
          },
        ),
        BlocListener<ReportsBloc, ReportsState>(
          listener: (context, state) {
            if (state is CreditNoteGenerated &&
                state.ticketId == widget.ticket.id) {
              if (mounted) {
                setState(() => _isGeneratingCreditNote = false);
              }
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is CreditNoteGenerationError &&
                state.ticketId == widget.ticket.id) {
              if (mounted) {
                setState(() => _isGeneratingCreditNote = false);
              }
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Atención'),
                    ],
                  ),
                  content: Text(state.message),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ],
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusL),
          side: _isCreditNote
              ? const BorderSide(color: Colors.red, width: 2)
              : _isAnnulledFactura
                  ? BorderSide(color: Colors.grey.shade500, width: 2)
                  : BorderSide.none,
        ),
        child: Container(
          width: 450,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: _isCreditNote
                      ? Colors.red.shade50
                      : _isAnnulledFactura
                          ? Colors.grey.shade100
                          : null,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.borderRadiusL),
                    topRight: Radius.circular(AppDimensions.borderRadiusL),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isCreditNote ? Icons.receipt_long : Icons.receipt,
                      color: _isCreditNote
                          ? Colors.red.shade700
                          : _isAnnulledFactura
                              ? Colors.grey.shade600
                              : AppColors.primary,
                    ),
                    const SizedBox(width: AppDimensions.paddingS),
                    if (_isCreditNote)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NOTA DE CRÉDITO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (_isCreditNote)
                      const SizedBox(width: AppDimensions.paddingS),
                    if (_isAnnulledFactura)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade500,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ANULADA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (_isAnnulledFactura)
                      const SizedBox(width: AppDimensions.paddingS),
                    Expanded(
                      child: Text(
                        '${widget.ticket.description}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _isCreditNote || _isAnnulledFactura
                                  ? Colors.grey.shade900
                                  : null,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Ticket content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: _buildTicketContent(context),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: BlocBuilder<PrinterBloc, PrinterState>(
                  builder: (context, state) {
                    final isPrinting = state is PrinterPrinting;
                    final isBusy = isPrinting || _isGeneratingCreditNote;
                    final isCreditNote = _isCreditNote;
                    final canAnnul = !isCreditNote && !widget.ticket.isAnnulled;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed:
                              isBusy ? null : () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        ),
                        const Spacer(),
                        if (canAnnul)
                          ElevatedButton.icon(
                            onPressed: isBusy
                                ? null
                                : () => _handleConvertToCreditNote(context),
                            icon: isBusy && _isGeneratingCreditNote
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(
                                    Icons.receipt,
                                    color: Colors.white,
                                  ),
                            label: Text(_isGeneratingCreditNote
                                ? 'Anulando...'
                                : 'Anular Ticket'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        if (canAnnul)
                          const SizedBox(width: AppDimensions.paddingS),
                        ElevatedButton.icon(
                          onPressed:
                              isBusy ? null : () => _handlePrint(context),
                          icon: isPrinting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(
                                  Icons.print,
                                  color: Colors.white,
                                ),
                          label:
                              Text(isPrinting ? 'Imprimiendo...' : 'Imprimir'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePrint(BuildContext context) async {
    if (_printJob == null) return;

    bool? isCopy = false;

    if (_printJob!.templateType == TicketTemplateType.whiteMarket) {
      isCopy = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PrintTypeDialog(),
      );

      if (isCopy == null) return;
    }

    final printJobWithCopyFlag = PrintJob(
      items: _printJob!.items,
      logItems: _printJob!.logItems,
      total: _printJob!.total,
      clientName: _printJob!.clientName,
      client: _printJob!.client,
      priceListId: _printJob!.priceListId,
      totalTax: _printJob!.totalTax,
      iibbTax: _printJob!.iibbTax,
      iibbTaxPercentage: _printJob!.iibbTaxPercentage,
      vatPerception: _printJob!.vatPerception,
      vatPerceptionByRate: _printJob!.vatPerceptionByRate,
      internalTax: _printJob!.internalTax,
      internalTaxRate: _printJob!.internalTaxRate,
      paymentMethod: _printJob!.paymentMethod,
      cashierName: _printJob!.cashierName,
      cashierId: _printJob!.cashierId,
      timestamp: _printJob!.timestamp,
      ticketId: _printJob!.ticketId,
      enterprise: _printJob!.enterprise,
      fiscalIssuerData: _printJob!.fiscalIssuerData,
      showSubtotalAndTax: _printJob!.showSubtotalAndTax,
      showPricesWithTax: _printJob!.showPricesWithTax,
      receivedAmount: _printJob!.receivedAmount,
      change: _printJob!.change,
      branchNumber: _printJob!.branchNumber,
      branchId: _printJob!.branchId,
      description: _printJob!.description,
      templateType: _printJob!.templateType,
      isCopy: isCopy,
      isCreditNote: _printJob!.isCreditNote,
      cae: _printJob!.cae,
      caeDueDate: _printJob!.caeDueDate,
      caeQrCode: _printJob!.caeQrCode,
      paymentMethods: _printJob!.paymentMethods,
    );

    // Disparar evento de impresión
    context.read<PrinterBloc>().add(PrintTicket(
          printJob: printJobWithCopyFlag,
        ));
  }

  Future<void> _handleConvertToCreditNote(BuildContext context) async {
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final reasons = await di.sl<FetchReturnReasonsUsecase>()();

      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (reasons.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay motivos de devolución configurados'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final selectedReasonId = await showDialog<int>(
        context: context,
        builder: (_) => ReturnReasonDialog(reasons: reasons),
      );

      if (selectedReasonId == null || !context.mounted) return;

      setState(() => _isGeneratingCreditNote = true);
      context.read<ReportsBloc>().add(
            GenerateCreditNote(widget.ticket.id, selectedReasonId),
          );
    } catch (e) {
      if (!context.mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar motivos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTicketContent(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  // Si es whiteMarket con datos fiscales, mostrar header completo
                  if (_printJob!.templateType ==
                          TicketTemplateType.whiteMarket &&
                      _printJob!.fiscalIssuerData != null) ...[
                    if (_printJob!.fiscalIssuerData!.fiscalName != null)
                      Text(
                        _printJob!.fiscalIssuerData!.fiscalName!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 4),
                    if (_printJob!.fiscalIssuerData!.cuit != null)
                      Text(
                          'C.U.I.T. Nro.: ${_printJob!.fiscalIssuerData!.cuit}'),
                    if (_printJob!.fiscalIssuerData!.iibbCuit != null)
                      Text(
                          'Ing. Brutos: ${_printJob!.fiscalIssuerData!.iibbCuit}'),
                    if (_printJob!.fiscalIssuerData!.address != null)
                      Text(
                          'Domicilio: ${_printJob!.fiscalIssuerData!.address}'),
                    if (_printJob!.fiscalIssuerData!.postalCode != null)
                      Text(_printJob!.fiscalIssuerData!.postalCode!),
                    if (_printJob!.fiscalIssuerData!.activityStartDate != null)
                      Text(
                          'Inicio de Actividades: ${_printJob!.fiscalIssuerData!.activityStartDate}'),
                    if (_printJob!.fiscalIssuerData!.vatCondition != null)
                      Text(_printJob!.fiscalIssuerData!.vatCondition!),
                    const SizedBox(height: 8),
                    Text(
                      _isCreditNote
                          ? 'NOTA DE CREDITO'
                          : 'DOCUMENTO VALIDO COMO FACTURA',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    Text(
                      _printJob!.enterprise?.name ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Sistema de Punto de Venta'),
                    Text(
                      _isCreditNote
                          ? 'NOTA DE CREDITO'
                          : (_printJob!.templateType ==
                                  TicketTemplateType.whiteMarket)
                              ? ''
                              : 'comprobante no valido como factura',
                      style: _isCreditNote
                          ? const TextStyle(fontWeight: FontWeight.bold)
                          : null,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.black,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ],
              ),
            ),

            // Información de la orden
            Text('Orden: ${widget.ticket.id}'),
            Text(widget.ticket.description!),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy').format(widget.ticket.completedAt)}'),
                Text(
                    'Hora: ${DateFormat('HH:mm:ss').format(widget.ticket.completedAt)}'),
              ],
            ),
            Text('Cajero: ${widget.ticket.cashierName}'),
            if (TicketType.isNotaCredito(widget.ticket.typeCode) &&
                (_originalSaleId != null ||
                    _returnReasonDescription != null)) ...[
              const SizedBox(height: 8),
              if (_originalSaleId != null)
                Text('Factura original: #$_originalSaleId'),
              if (_returnReasonDescription != null)
                Text('Motivo: $_returnReasonDescription'),
            ],
            if (widget.ticket.clientName != null &&
                widget.ticket.clientName!.isNotEmpty) ...[
              Text('Cliente: ${widget.ticket.clientName}'),
              if (widget.ticket.client?.document != null &&
                  widget.ticket.client!.document!.isNotEmpty)
                Text('Documento: ${widget.ticket.client!.document}'),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                color: Colors.black,
              ),
            ),

            // Items
            ...(_recalculatedTicket ?? widget.ticket).items.map((item) {
              final basePrice = item.pricePerKg ?? item.product.price ?? 0.0;
              final displayPrice = _getDisplayUnitPrice(
                item,
                basePrice,
                showPricesWithTax: _printJob!.showPricesWithTax,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.description,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (item.isWeighted == true)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '  ${item.weightKg ?? '-'} kg x ${displayPrice.formatToCurrency()}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            ((item.weightKg ?? 0.0) * displayPrice)
                                .formatToCurrency(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    if (item.isWeighted != true)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '  ${item.quantity} x ${displayPrice.formatToCurrency()}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            (item.quantity * displayPrice).formatToCurrency(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }).toList(),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                color: Colors.black,
              ),
            ),

            // Totales - Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text(((_recalculatedTicket ?? widget.ticket).total -
                        _printJob!.totalTax -
                        _printJob!.iibbTax -
                        _printJob!.vatPerception -
                        _printJob!.internalTax)
                    .formatToCurrency()),
              ],
            ),

            // IVA
            if (_printJob!.totalTax > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('IVA:'),
                  Text(_printJob!.totalTax.formatToCurrency()),
                ],
              ),
            ],

            // IIBB
            if (_printJob!.iibbTax > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_printJob!.iibbTaxPercentage != null &&
                          _printJob!.iibbTaxPercentage! > 0
                      ? 'Percep. IIBB (${_printJob!.iibbTaxPercentage!.toStringAsFixed(1)}%):'
                      : 'Percep. IIBB:'),
                  Text(_printJob!.iibbTax.formatToCurrency()),
                ],
              ),
            ],

            // VAT Perception
            if (_printJob!.vatPerception > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Percep. IVA:'),
                  Text(_printJob!.vatPerception.formatToCurrency()),
                ],
              ),
            ],

            // Impuesto Interno
            if (_printJob!.internalTax > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_printJob!.internalTaxRate != null &&
                          _printJob!.internalTaxRate! > 0
                      ? 'Imp. Interno (${_printJob!.internalTaxRate!.toStringAsFixed(1)}%):'
                      : 'Imp. Interno:'),
                  Text(_printJob!.internalTax.formatToCurrency()),
                ],
              ),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                color: Colors.black,
                thickness: 2,
              ),
            ),
            if (widget.ticket.receivedAmount != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recibido:'),
                  Text(widget.ticket.receivedAmount!.formatToCurrency()),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cambio:'),
                  Text(widget.ticket.change != null
                      ? widget.ticket.change!.formatToCurrency()
                      : '-'),
                ],
              ),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.ticket.total.formatToCurrency(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                color: Colors.black,
                thickness: 2,
              ),
            ),

            const SizedBox(height: 8),

            // Información adicional
            if (!_isCreditNote) ...[
              if (widget.ticket.paymentMethods != null &&
                  widget.ticket.paymentMethods!.isNotEmpty) ...[
                const Text(
                  'Métodos de pago:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...widget.ticket.paymentMethods!.map((pm) => Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('  - ${pm.description}:'),
                          Text(pm.amount != null
                              ? pm.amount!.formatToCurrency()
                              : '-'),
                        ],
                      ),
                    )),
              ] else ...[
                Text('Método de pago: $_paymentMethodName'),
              ],
            ],
            Text(
                'Total de artículos: ${widget.ticket.items.fold(0, (previousValue, element) => previousValue + element.quantity)}'),

            if (widget.ticket.templateType ==
                TicketTemplateType.whiteMarket) ...[
              const SizedBox(height: 8),
              if (widget.ticket.cae != null) ...[
                Text('CAE: ${widget.ticket.cae}'),
              ],
              if (widget.ticket.caeDueDate != null) ...[
                Text('Vencimiento CAE: ${widget.ticket.caeDueDate}'),
              ],
              const SizedBox(height: 8),
              const Text("Orientacion al Consumidor"),
              const Text("Provincia de Buenos Aires"),
              const Text("0800-222-9042 (Ley 13133)"),
            ],

            const SizedBox(height: 16),
            const Center(
              child: Text(
                '¡Gracias por su compra!',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculatePriceWithTax(double price, double? taxPercentage) {
    final tax = (taxPercentage ?? 0.0) / 100;
    return price * (1 + tax);
  }

  double _getDisplayUnitPrice(CartItem item, double basePrice,
      {required bool showPricesWithTax}) {
    if (showPricesWithTax) {
      return basePrice;
    }
    double priceWithTax = _calculatePriceWithTax(basePrice, item.product.vat);
    if (item.product.internalTax > 0) {
      final fractional = item.product.fractional ?? 1;
      priceWithTax += item.product.internalTax * fractional;
    }
    return priceWithTax;
  }
}
