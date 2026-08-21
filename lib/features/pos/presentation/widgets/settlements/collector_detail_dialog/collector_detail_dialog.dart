import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/settlements/settlements_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/settlements/settlements_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/settlements/settlements_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/settlements/collector_detail_dialog/settlement_payments_breakdown.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/settlements/collector_detail_dialog/settlement_summary_grid.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

class CollectorDetailDialog extends StatelessWidget {
  final String collectorId;
  final String collectorName;
  final String date;

  const CollectorDetailDialog({
    super.key,
    required this.collectorId,
    required this.collectorName,
    required this.date
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<SettlementsBloc>()
        ..add(FetchPendingCollectorDetail(collectorId: collectorId, date: date)),
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: _CollectorDetailDialogContent(
            collectorId: collectorId,
            collectorName: collectorName,
            date: date,
          ),
        ),
      ),
    );
  }
}

class _CollectorDetailDialogContent extends StatelessWidget {
  final String collectorId;
  final String collectorName;
  final String date;

  const _CollectorDetailDialogContent({
    required this.collectorId,
    required this.collectorName,
    required this.date
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color:
              isDark ? AppColors.sidebarDarkBackground : Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingM,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalle de Rendición',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      collectorName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ],
          ),
        ),
        Flexible(
          child: BlocBuilder<SettlementsBloc, SettlementsState>(
            builder: (context, state) {
              if (state is SettlementsLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppDimensions.paddingXL),
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (state is SettlementsError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingXL),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        Text(
                          'Error al obtener detalles',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingS),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<SettlementsBloc>().add(
                                  FetchPendingCollectorDetail(
                                      collectorId: collectorId, date: date),
                                );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (state is PendingCollectorsDetailLoaded) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettlementSummaryGrid(
                        detail: state.pendingCollectorsDetail,
                      ),
                      const SizedBox(height: AppDimensions.paddingL),
                      Text(
                        'Desglose de Cobros',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingS),
                      SettlementPaymentsBreakdown(
                        payments:
                            state.pendingCollectorsDetail.paymentsBreakdown,
                      ),
                    ],
                  ),
                );
              }

              return const Center(child: Text('Estado desconocido'));
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.sidebarDarkBackground : Colors.grey.shade50,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkDivider : Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
