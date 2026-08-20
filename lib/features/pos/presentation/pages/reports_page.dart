import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/app/routes/route_paths.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/ticket_types.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/report/date_range_picker.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/report/summary_row.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/report/ticket_preview_dialog.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();
  DateTime? selectedEndDate;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _ticketFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _scrollController.addListener(_onScroll);
    context.read<ReportsBloc>().add(LoadDailySummary(selectedDate));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      // Cargar más cuando llegue al 90% del scroll
      final state = context.read<ReportsBloc>().state;
      if (state is ReportsLoaded && !state.isLoadingMore && state.hasMoreData) {
        context.read<ReportsBloc>().add(const LoadMoreReports());
      }
    }
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _onTabChanged(_tabController.index);
    }
  }

  String? get _typeCodeForFilter {
    switch (_ticketFilter) {
      case 'invoices':
        return TicketType.factura;
      case 'credit_notes':
        return TicketType.notaCredito;
      default:
        return null;
    }
  }

  void _onTabChanged(int index) {
    // Resetear posición del scroll al cambiar de tab
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    if (index == 0) {
      setState(() => _ticketFilter = 'all');
      if (selectedEndDate != null) {
        context.read<ReportsBloc>().add(
              LoadReportsByDateRange(selectedDate, selectedEndDate!),
            );
      } else {
        context.read<ReportsBloc>().add(LoadDailySummary(selectedDate));
      }
    } else {
      // Limpiar buscador y cargar todos los tickets
      _searchController.clear();
      setState(() {});
      final typeCode = _typeCodeForFilter;
      context.read<ReportsBloc>().add(LoadAllReports(typeCode: typeCode));
    }
  }

  void _reloadCurrentView() {
    if (selectedEndDate != null) {
      context.read<ReportsBloc>().add(
            LoadReportsByDateRange(selectedDate, selectedEndDate!),
          );
    } else {
      context.read<ReportsBloc>().add(LoadDailySummary(selectedDate));
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pushReplacementNamed(RoutePaths.pos);
        }
      },
      child: BlocListener<ReportsBloc, ReportsState>(
        listener: (context, state) {
          if (state is TicketPrinted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is ReportsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Scaffold(
          body: Column(
            children: [
              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.calendar_today, size: 15),
                    text: 'Resumen Diario',
                    height: 50,
                  ),
                  Tab(
                    icon: Icon(Icons.history, size: 15),
                    text: 'Historial',
                    height: 50,
                  ),
                ],
                onTap: _onTabChanged,
              ),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDailySummaryTab(),
                    _buildHistoryTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailySummaryTab() {
    return Column(
      children: [
        // Date picker
        DateRangePicker(
          selectedDate: selectedDate,
          selectedEndDate: selectedEndDate,
          onStartDateChanged: (date) {
            setState(() {
              selectedDate = date;
            });
          },
          onEndDateChanged: (date) {
            setState(() {
              selectedEndDate = date;
            });
          },
          onUpdate: () {
            _reloadCurrentView();
          },
        ),

        // Summary and orders
        Expanded(
          child: BlocBuilder<ReportsBloc, ReportsState>(
            builder: (context, state) {
              if (state is ReportsLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ReportsLoaded) {
                return Column(
                  children: [
                    if (state.summary != null)
                      SummaryRow(summary: state.summary!),
                    Expanded(
                      child: _buildOrdersList(state.tickets,
                          showDate: selectedEndDate != null),
                    ),
                  ],
                );
              } else if (state is ReportsError) {
                return _buildErrorWidget(state.message);
              }
              return const Center(
                  child: Text('Selecciona una fecha para ver el reporte'));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
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
                selected: _ticketFilter == 'all',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _ticketFilter = 'all');
                    context.read<ReportsBloc>().add(const LoadAllReports());
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
                selected: _ticketFilter == 'invoices',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _ticketFilter = 'invoices');
                    context.read<ReportsBloc>().add(
                          const LoadAllReports(typeCode: TicketType.factura),
                        );
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
                selected: _ticketFilter == 'credit_notes',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _ticketFilter = 'credit_notes');
                    context.read<ReportsBloc>().add(
                          const LoadAllReports(
                              typeCode: TicketType.notaCredito),
                        );
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
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por ID de ticket...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
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
                final filteredTickets = _searchController.text.isEmpty
                    ? state.tickets
                    : state.tickets
                        .where((ticket) => (ticket.id)
                            .toLowerCase()
                            .contains(_searchController.text.toLowerCase()))
                        .toList();

                return _buildOrdersList(filteredTickets, showDate: true);
              } else if (state is ReportsError) {
                return _buildErrorWidget(state.message);
              }
              return const Center(child: Text('Cargando historial...'));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList(List<CompletedOrder> tickets,
      {required bool showDate}) {
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
          controller: _scrollController,
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          itemCount: tickets.length + (isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Mostrar indicador de carga al final
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

            // card del ticket
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

  Widget _buildErrorWidget(String message) {
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
            onPressed: () {
              if (_tabController.index == 0) {
                if (selectedEndDate != null) {
                  context.read<ReportsBloc>().add(
                        LoadReportsByDateRange(selectedDate, selectedEndDate!),
                      );
                } else {
                  context
                      .read<ReportsBloc>()
                      .add(LoadDailySummary(selectedDate));
                }
              } else {
                context
                    .read<ReportsBloc>()
                    .add(LoadAllReports(typeCode: _typeCodeForFilter));
              }
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
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
}
