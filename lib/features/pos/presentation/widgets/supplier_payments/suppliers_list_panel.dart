import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_state.dart';

class SuppliersListPanel extends StatefulWidget {
  final VoidCallback onSupplierSelected;

  const SuppliersListPanel({
    super.key,
    required this.onSupplierSelected,
  });

  @override
  State<SuppliersListPanel> createState() => _SuppliersListPanelState();
}

class _SuppliersListPanelState extends State<SuppliersListPanel> {
  final TextEditingController _supplierSearchController =
      TextEditingController();
  String _selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _supplierSearchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _supplierSearchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Proveedores',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          TextField(
            controller: _supplierSearchController,
            decoration: InputDecoration(
              hintText: 'Buscar por Nombre, ID, CUIT/CUIL...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          _buildFilterTabs(isDark),
          const SizedBox(height: AppDimensions.paddingS),
          Expanded(
            child: BlocBuilder<SupplierPaymentsBloc, SupplierPaymentsState>(
              builder: (context, state) {
                if (state.status == SupplierPaymentStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final query =
                    _supplierSearchController.text.trim().toLowerCase();
                final filtered = state.suppliers.where((supplier) {
                  final matchesText = supplier.id.toString().contains(query) ||
                      supplier.name.toLowerCase().contains(query) ||
                      (supplier.cuit ?? '').contains(query);

                  bool matchesType = true;
                  if (_selectedFilter == 'Mercadería') {
                    matchesType = !supplier.isServiceProvider;
                  } else if (_selectedFilter == 'Servicios') {
                    matchesType = supplier.isServiceProvider;
                  }

                  return matchesText && matchesType;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No se encontraron proveedores',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final supplier = filtered[index];
                    final isSelected =
                        state.selectedSupplier?.id == supplier.id;

                    return Card(
                      color: isSelected
                          ? (isDark ? AppColors.greenDark : Colors.teal.shade50)
                          : (isDark ? AppColors.darkCard : Colors.grey.shade50),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () {
                          widget.onSupplierSelected();
                          context.read<SupplierPaymentsBloc>().add(
                                SelectSupplierEvent(
                                    isSelected ? null : supplier),
                              );
                        },
                        title: Text(
                          supplier.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ID: ${supplier.id} | Doc: ${supplier.cuit ?? 'Sin Documento'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: supplier.isServiceProvider
                                    ? Colors.blue.withValues(alpha: 0.15)
                                    : Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                supplier.isServiceProvider
                                    ? 'Servicio'
                                    : 'Mercadería',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: supplier.isServiceProvider
                                      ? Colors.blue
                                      : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: AppColors.primary)
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark) {
    final filters = ['Todos', 'Mercadería', 'Servicios'];
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
