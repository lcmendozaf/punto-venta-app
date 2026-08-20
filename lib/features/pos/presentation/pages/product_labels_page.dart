import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/app/routes/route_paths.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product_labels/product_labels_header.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product_labels/product_labels_grid.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

class ProductLabelsPage extends StatelessWidget {
  const ProductLabelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductLabelsBloc(
        getProductsUsecase: di.sl(),
        priceListLocalDataSource: di.sl(),
        printerDataSource: di.sl(),
        printerLocalDataSource: di.sl(),
      )..add(const LoadProducts()),
      child: const _ProductLabelsPageContent(),
    );
  }
}

class _ProductLabelsPageContent extends StatefulWidget {
  const _ProductLabelsPageContent();

  @override
  State<_ProductLabelsPageContent> createState() =>
      _ProductLabelsPageContentState();
}

class _ProductLabelsPageContentState extends State<_ProductLabelsPageContent> {
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
        body: Column(
          children: [
            const ProductLabelsHeader(),
            Expanded(
              child: BlocConsumer<ProductLabelsBloc, ProductLabelsState>(
                listener: _handleStateChanges,
                builder: _buildBody,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleStateChanges(BuildContext context, ProductLabelsState state) {
    if (state is ProductLabelsPrintSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Se imprimieron ${state.count} etiqueta(s) correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (state is ProductLabelsPrintError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al imprimir: ${state.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBody(BuildContext context, ProductLabelsState state) {
    if (state is ProductLabelsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ProductLabelsError) {
      return _buildErrorState(state);
    }

    if (state is ProductLabelsLoaded) {
      return ProductLabelsGrid(state: state);
    }

    if (state is ProductLabelsPrinting) {
      return _buildPrintingState(state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildErrorState(ProductLabelsError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: ${state.message}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<ProductLabelsBloc>().add(const LoadProducts());
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintingState(ProductLabelsPrinting state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Imprimiendo ${state.products.length} etiqueta(s)...'),
        ],
      ),
    );
  }
}
