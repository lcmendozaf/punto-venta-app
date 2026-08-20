import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/app/routes/route_paths.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/widgets/loading_indicator.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_state.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/stock/presentation/bloc/stock_bloc.dart';
import 'package:punto_venta_app/features/stock/presentation/bloc/stock_event.dart';
import 'package:punto_venta_app/features/stock/presentation/bloc/stock_state.dart';
import 'package:punto_venta_app/features/stock/presentation/widgets/product_form_dialog.dart';
import 'package:punto_venta_app/features/stock/presentation/widgets/product_list_item.dart';
import 'package:punto_venta_app/features/stock/presentation/widgets/stock_movement_dialog.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

class StockManagementPage extends StatelessWidget {
  const StockManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = di.sl<StockBloc>();
        final authState = context.read<AuthBloc>().state;

        if (authState is AuthAuthenticated) {
          bloc.setCurrentUser(authState.user.id, authState.user.name);
        }

        bloc.add(LoadProducts());
        return bloc;
      },
      child: const _StockManagementView(),
    );
  }
}

class _StockManagementView extends StatefulWidget {
  const _StockManagementView();

  @override
  State<_StockManagementView> createState() => _StockManagementViewState();
}

class _StockManagementViewState extends State<_StockManagementView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pushReplacementNamed(RoutePaths.pos);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Stock'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => _showMovementsHistory(context),
              tooltip: 'Historial de movimientos',
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar producto...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadiusM),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadiusM),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Product list
            Expanded(
              child: BlocConsumer<StockBloc, StockState>(
                listener: (context, state) {
                  if (state is StockOperationSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else if (state is StockError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is StockLoading) {
                    return const LoadingIndicator();
                  }

                  if (state is StockError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                          Text(
                            state.message,
                            style: TextStyle(color: Colors.red.shade700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<StockBloc>().add(LoadProducts());
                            },
                            icon:
                                const Icon(Icons.refresh, color: Colors.white),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  List<Product> products = [];
                  if (state is StockLoaded) {
                    products = state.products;
                  } else if (state is StockOperationSuccess) {
                    products = state.products;
                  }

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                          Text(
                            'No hay productos registrados',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.paddingS),
                          Text(
                            'Agrega tu primer producto',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final filteredProducts = products
                      .where((product) =>
                          (product.description)
                              .toLowerCase()
                              .contains(_searchQuery) ||
                          (product.id.toString()).contains(_searchQuery) ||
                          (product.categoryDescription)
                              .toLowerCase()
                              .contains(_searchQuery))
                      .toList();

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                          Text(
                            'No se encontraron productos',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<StockBloc>().add(LoadProducts());
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      itemCount: filteredProducts.length,
                      separatorBuilder: (context, index) => const SizedBox(
                        height: AppDimensions.paddingS,
                      ),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return ProductListItem(
                          product: product,
                          onEdit: () => _showEditDialog(context, product),
                          onDelete: () =>
                              _showDeleteConfirmation(context, product),
                          onAddStock: () => _showStockDialog(
                            context,
                            product,
                            StockOperationType.add,
                          ),
                          onRemoveStock: () => _showStockDialog(
                            context,
                            product,
                            StockOperationType.remove,
                          ),
                          onAdjustStock: () => _showStockDialog(
                            context,
                            product,
                            StockOperationType.adjust,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo Producto'),
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<StockBloc>(),
        child: const ProductFormDialog(),
      ),
    );
  }

  void _showEditDialog(BuildContext context, dynamic product) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<StockBloc>(),
        child: ProductFormDialog(product: product),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, dynamic product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
            '¿Estás seguro de que deseas eliminar "${product.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // context.read<StockBloc>().add(DeleteProduct(product.id));
              // Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showStockDialog(
    BuildContext context,
    dynamic product,
    StockOperationType type,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<StockBloc>(),
        child: StockMovementDialog(
          product: product,
          operationType: type,
        ),
      ),
    );
  }

  void _showMovementsHistory(BuildContext context) {
    // TODO: Implementar página de historial
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Historial de movimientos - Próximamente'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
