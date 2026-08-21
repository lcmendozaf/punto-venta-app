import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/app/routes/route_paths.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/ticket_types.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/report/daily_summary_view.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/report/history_view.dart';

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
  final ScrollController _dailyScrollController = ScrollController();
  final ScrollController _historyScrollController = ScrollController();
  String _ticketFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _dailyScrollController.addListener(_onDailyScroll);
    _historyScrollController.addListener(_onHistoryScroll);
    context.read<ReportsBloc>().add(LoadDailySummary(selectedDate));
  }

  void _onDailyScroll() {
    if (_dailyScrollController.hasClients &&
        _dailyScrollController.position.pixels >=
            _dailyScrollController.position.maxScrollExtent * 0.9) {
      final state = context.read<ReportsBloc>().state;
      if (state is ReportsLoaded && !state.isLoadingMore && state.hasMoreData) {
        context.read<ReportsBloc>().add(const LoadMoreReports());
      }
    }
  }

  void _onHistoryScroll() {
    if (_historyScrollController.hasClients &&
        _historyScrollController.position.pixels >=
            _historyScrollController.position.maxScrollExtent * 0.9) {
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
    if (_dailyScrollController.hasClients) {
      _dailyScrollController.jumpTo(0);
    }
    if (_historyScrollController.hasClients) {
      _historyScrollController.jumpTo(0);
    }

    _searchController.clear();

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
    _dailyScrollController.dispose();
    _historyScrollController.dispose();
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
                    DailySummaryView(
                      selectedDate: selectedDate,
                      selectedEndDate: selectedEndDate,
                      searchController: _searchController,
                      scrollController: _dailyScrollController,
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
                      onRetry: () {
                        _reloadCurrentView();
                      },
                    ),
                    HistoryView(
                      ticketFilter: _ticketFilter,
                      searchController: _searchController,
                      scrollController: _historyScrollController,
                      onFilterChanged: (filter) {
                        setState(() => _ticketFilter = filter);
                        context.read<ReportsBloc>().add(
                              LoadAllReports(typeCode: _typeCodeForFilter),
                            );
                      },
                      onRetry: () {
                        context.read<ReportsBloc>().add(
                              LoadAllReports(typeCode: _typeCodeForFilter),
                            );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
