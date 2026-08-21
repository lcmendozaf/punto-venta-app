import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/ticket_types.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/report/ticket_preview_dialog.dart';

class HistoryView extends StatefulWidget {
  final String ticketFilter;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onRetry;

  const HistoryView({
    super.key,
    required this.ticketFilter,
    required this.searchController,
    required this.scrollController,
    required this.onFilterChanged,
    required this.onRetry,
  });

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingS,
          ),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Todos'),
                selected: widget.ticketFilter == 'all',
                onSelected: (selected) {
                  if (selected) {
                    widget.onFilterChanged('all');
                  }
                },
                selectedColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingS),
              FilterChip(
                label: const Text('Facturas'),
                selected: widget.ticketFilter == 'invoices',
                onSelected: (selected) {
                  if (selected) {
                    widget.onFilterChanged('invoices');
                  }
                },
                selectedColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingS),
              FilterChip(
                label: const Text('Notas de Crédito'),
                selected: widget.ticketFilter == 'credit_notes',
                onSelected: (selected) {
                  if (selected) {
                    widget.onFilterChanged('credit_notes');
                  }
                },
                selectedColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Buscador
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: TextField(
            controller: widget.searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por ID de ticket o cliente...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: widget.searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        widget.searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusS),
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),

        // Lista de órdenes
        Expanded(
          child: BlocBuilder<ReportsBloc, ReportsState>(
            builder: (context, state) {
              if (state is ReportsLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ReportsLoaded) {
                final filteredTickets = widget.searchController.text.isEmpty
                    ? state.tickets
                    : state.tickets
                        .where((ticket) =>
                            (ticket.description ?? '')
                                .toLowerCase()
                                .contains(widget.searchController.text.toLowerCase()) ||
                            (ticket.clientName ?? '')
                                .toLowerCase()
                                .contains(widget.searchController.text.toLowerCase()))
                        .toList();

                return _buildOrdersList(
                  filteredTickets,
                  showDate: true,
                  scrollController: widget.scrollController,
                );
              } else if (state is ReportsError) {
                return _buildErrorWidget(state.message, widget.onRetry);
              }

              return const Center(child: Text('Cargando historial...'));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList(
    List<CompletedOrder> tickets, {
    required bool showDate,
    required ScrollController scrollController,
  }) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'No hay órdenes completadas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<ReportsBloc, ReportsState>(
      builder: (context, state) {
        final isLoadingMore = state is ReportsLoaded && state.isLoadingMore;

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          itemCount: tickets.length + (isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == tickets.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.paddingM),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final ticket = tickets[index];
            final isCreditNote = TicketType.isNotaCredito(ticket.typeCode);
            final isAnnulled =
                ticket.isAnnulled && TicketType.isFactura(ticket.typeCode);

            return GestureDetector(
              onTap: () => _showTicketPreview(ticket),
              child: Card(
                margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
                color: isCreditNote ? Colors.red.shade50 : null,
                child: ListTile(
                  leading: Icon(
                    isCreditNote ? Icons.receipt_long : Icons.receipt,
                    color:
                        isCreditNote ? Colors.red.shade700 : AppColors.primary,
                    size: 32,
                  ),
                  title: Row(
                    children: [
                      if (isCreditNote)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'N.C',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isCreditNote)
                        const SizedBox(width: AppDimensions.paddingS),
                      if (isAnnulled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade500,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Anulada',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isAnnulled)
                        const SizedBox(width: AppDimensions.paddingS),
                      Expanded(
                        child: Text(
                          showDate
                              ? "${ticket.description} | ${DateFormat('dd/MM/yyyy HH:mm').format(ticket.completedAt)}"
                              : "${ticket.description} | ${DateFormat('HH:mm').format(ticket.completedAt)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCreditNote ? Colors.grey.shade900 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ticket.clientName != null)
                        Text(
                          'Cliente: ${ticket.clientName}',
                          style: isCreditNote
                              ? TextStyle(color: Colors.grey.shade900)
                              : null,
                        ),
                      Text(
                        '${ticket.items.length} artículos',
                        style: isCreditNote
                            ? TextStyle(color: Colors.grey.shade900)
                            : null,
                      ),
                      if (ticket.paymentMethods != null)
                        Text(
                          'Pago: ${ticket.paymentMethods!.map((e) => e.description).join(', ')}',
                          style: isCreditNote
                              ? TextStyle(color: Colors.grey.shade900)
                              : null,
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (ticket.total).formatToCurrency(),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isCreditNote
                                      ? Colors.red.shade700
                                      : AppColors.primary,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTicketPreview(CompletedOrder ticket) {
    final reportsBloc = context.read<ReportsBloc>();
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: reportsBloc,
        child: TicketPreviewDialog(ticket: ticket),
      ),
    );
  }

  Widget _buildErrorWidget(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: AppColors.error, size: 64),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            'Error al cargar reportes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(message),
          const SizedBox(height: AppDimensions.paddingM),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
