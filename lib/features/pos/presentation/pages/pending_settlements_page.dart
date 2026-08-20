import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/app/routes/route_paths.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/settlements/settlements_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/settlements/settlements_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/settlements/settlements_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/settlements/collector_detail_dialog/collector_detail_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/settlements/collector_list_item.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/settlements/settlement_date_picker_bar.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/settlements/settlement_empty_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/settlements/settlement_error_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/settlements/settlement_search_field.dart';

class PendingSettlementsPage extends StatefulWidget {
  const PendingSettlementsPage({super.key});

  @override
  State<PendingSettlementsPage> createState() => _PendingSettlementsPageState();
}

class _PendingSettlementsPageState extends State<PendingSettlementsPage> {
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCollectors();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _fetchCollectors() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    context.read<SettlementsBloc>().add(FetchPendingCollectors(date: dateStr));
  }

  void _showCollectorDetail(
      BuildContext context, String collectorId, String name) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => CollectorDetailDialog(
        collectorId: collectorId,
        collectorName: name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pushReplacementNamed(RoutePaths.pos);
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(isDark),
            SettlementDatePickerBar(
              selectedDate: _selectedDate,
              onDateChanged: (newDate) {
                setState(() {
                  _selectedDate = newDate;
                });
                _fetchCollectors();
              },
            ),
            SettlementSearchField(
              controller: _searchController,
            ),
            Expanded(
              child: BlocBuilder<SettlementsBloc, SettlementsState>(
                builder: (context, state) {
                  if (state is SettlementsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is SettlementsError) {
                    return SettlementErrorWidget(
                      message: state.message,
                      onRetry: _fetchCollectors,
                    );
                  } else if (state is SettlementsLoaded) {
                    final allCollectors = state.pendingCollectors;

                    if (allCollectors.isEmpty) {
                      return const SettlementEmptyWidget(
                        icon: Icons.assignment_turned_in,
                        message:
                            'No hay cobradores con liquidaciones pendientes para esta fecha',
                      );
                    }
                    final query = _searchController.text.trim().toLowerCase();
                    final filteredCollectors = allCollectors.where((collector) {
                      final name = (collector.name ?? '').toLowerCase();
                      final id = (collector.userId ?? '').toString();
                      return name.contains(query) || id.contains(query);
                    }).toList();

                    if (filteredCollectors.isEmpty) {
                      return const SettlementEmptyWidget(
                        icon: Icons.search_off,
                        message:
                            'No se encontraron cobradores que coincidan con la búsqueda',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        _fetchCollectors();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingM,
                          vertical: AppDimensions.paddingS,
                        ),
                        itemCount: filteredCollectors.length,
                        itemBuilder: (context, index) {
                          final collector = filteredCollectors[index];
                          return CollectorListItem(
                            collector: collector,
                            onTap: () => _showCollectorDetail(
                              context,
                              (collector.userId ?? '').toString(),
                              collector.name ?? 'Sin Nombre',
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return const Center(child: Text('Cargando liquidaciones...'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      color: isDark
          ? AppColors.sidebarDarkBackground
          : AppColors.sidebarLightSurface,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Liquidación de Cobradores',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Visualiza las ventas y cobros pendientes de rendición por cada cobrador.',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
