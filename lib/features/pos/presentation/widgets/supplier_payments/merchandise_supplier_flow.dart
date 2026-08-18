import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_state.dart';

class MerchandiseSupplierFlow extends StatefulWidget {
  final SupplierPaymentsState state;
  final TextEditingController totalPaidController;

  const MerchandiseSupplierFlow({
    super.key,
    required this.state,
    required this.totalPaidController,
  });

  @override
  State<MerchandiseSupplierFlow> createState() =>
      _MerchandiseSupplierFlowState();
}

class _MerchandiseSupplierFlowState extends State<MerchandiseSupplierFlow> {
  final TextEditingController _productSearchController =
      TextEditingController();

  int? _editingProductId;
  final TextEditingController _editingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productSearchController.addListener(_onProductSearchChanged);
  }

  @override
  void dispose() {
    _productSearchController.dispose();
    _editingController.dispose();
    super.dispose();
  }

  void _onProductSearchChanged() {
    setState(() {});
  }

  void _commitQuantity(int productId, String value) {
    final qty = double.tryParse(value.replaceAll(',', '.')) ?? 1.0;
    final finalQty = qty > 0 ? qty : 1.0;
    context.read<SupplierPaymentsBloc>().add(
          UpdateProductQuantityEvent(productId, finalQty),
        );
    setState(() {
      _editingProductId = null;
    });
  }

  void _checkAutomaticBarcodeMatch(String value) {
    final query = value.trim();
    if (query.isEmpty) return;

    final isNumeric = RegExp(r'^\d+$').hasMatch(query);
    if (!isNumeric || query.length < 8) return;

    final prodState = context.read<ProductBloc>().state;
    if (prodState is ProductLoaded) {
      try {
        final product = prodState.products.firstWhere(
          (p) =>
              p.supplierId == widget.state.selectedSupplier?.id &&
              (p.barcodes?.any((b) => b.barcode.toString() == query) ?? false),
        );

        final barcodeMatch =
            product.barcodes?.firstWhere((b) => b.barcode.toString() == query);
        final barcodeUnits = barcodeMatch?.units?.toDouble() ?? 1.0;

        context
            .read<SupplierPaymentsBloc>()
            .add(AddProductToPaymentEvent(product, quantity: barcodeUnits));

        _productSearchController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Producto "${product.description}" ($barcodeUnits un.) agregado por código de barras'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (_) {}
    }
  }

  void _onBarcodeOrProductSubmitted(String value) {
    final query = value.trim();
    if (query.isEmpty) return;

    final prodState = context.read<ProductBloc>().state;
    if (prodState is ProductLoaded) {
      Product? matchedProduct;
      double units = 1.0;

      try {
        matchedProduct = prodState.products.firstWhere(
          (p) =>
              p.supplierId == widget.state.selectedSupplier?.id &&
              (p.barcodes?.any((b) => b.barcode.toString() == query) ?? false),
        );
        final barcodeMatch = matchedProduct.barcodes
            ?.firstWhere((b) => b.barcode.toString() == query);
        units = barcodeMatch?.units?.toDouble() ?? 1.0;
      } catch (_) {}

      if (matchedProduct == null) {
        try {
          final parsedId = int.tryParse(query);
          if (parsedId != null) {
            matchedProduct = prodState.products.firstWhere(
              (p) =>
                  p.supplierId == widget.state.selectedSupplier?.id &&
                  p.id == parsedId,
            );
            units = 1.0;
          }
        } catch (_) {}
      }

      if (matchedProduct != null) {
        context
            .read<SupplierPaymentsBloc>()
            .add(AddProductToPaymentEvent(matchedProduct, quantity: units));
        _productSearchController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró ningún producto con ese código'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: 0.5,
              color: isDark ? AppColors.darkDivider : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agregar Productos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingS),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _productSearchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar producto por nombre o código...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _productSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _productSearchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (val) {
                      _checkAutomaticBarcodeMatch(val);
                      _onProductSearchChanged();
                    },
                    onSubmitted: (val) {
                      _onBarcodeOrProductSubmitted(val);
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildProductDropdown(isDark),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: 0.5,
              color: isDark ? AppColors.darkDivider : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Artículos en este remito',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingS),
              if (widget.state.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No hay productos agregados',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ...widget.state.items
                    .map((item) => _buildCartItemRow(item, isDark)),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Calculado:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    widget.state.total.formatToCurrency(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingS),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Adelanto proveedor:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 48,
                      child: TextField(
                        controller: widget.totalPaidController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [CurrencyInputFormatter()],
                        decoration: InputDecoration(
                          hintText: "Monto del adelanto",
                          prefixText: "\$ ",
                          prefixIcon:
                              const Icon(Icons.payments_outlined, size: 20),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (val) {
                          final amount =
                              val.trim().parseFormattedDouble() ?? 0.0;
                          context.read<SupplierPaymentsBloc>().add(
                                UpdatePaymentAmountsEvent(totalPaid: amount),
                              );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductDropdown(bool isDark) {
    return Card(
      elevation: 8,
      color: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: isDark ? AppColors.darkDivider : Colors.grey.shade200),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 250),
        child: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, prodState) {
            if (prodState is ProductLoading) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (prodState is ProductLoaded) {
              final query = _productSearchController.text.toLowerCase();
              final List<Product> filteredProducts;
              final isQueryEmpty = query.isEmpty;

              if (isQueryEmpty) {
                filteredProducts = prodState.products
                    .where((p) =>
                        p.supplierId == widget.state.selectedSupplier?.id)
                    .take(5)
                    .toList();
              } else {
                filteredProducts = prodState.products.where((p) {
                  final matchesSupplier =
                      p.supplierId == widget.state.selectedSupplier?.id;
                  final matchesQuery = p.description
                          .toLowerCase()
                          .contains(query) ||
                      p.id.toString().contains(query) ||
                      (p.barcodes?.any(
                              (b) => b.barcode.toString().contains(query)) ??
                          false);
                  return matchesSupplier && matchesQuery;
                }).toList();
              }

              if (filteredProducts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      isQueryEmpty
                          ? 'No hay productos registrados para este proveedor'
                          : 'No se encontraron productos',
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: filteredProducts.length + (isQueryEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (isQueryEmpty && index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
                      child: Text(
                        'PRODUCTOS SUGERIDOS DEL PROVEEDOR:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color:
                              isDark ? Colors.teal.shade300 : AppColors.primary,
                        ),
                      ),
                    );
                  }

                  final product =
                      filteredProducts[isQueryEmpty ? index - 1 : index];
                  final purchasePrice = product.purchasePrice ?? 0.0;

                  final existingItemIndex = widget.state.items
                      .indexWhere((i) => i.product.id == product.id);
                  final double quantityInCart = existingItemIndex >= 0
                      ? widget.state.items[existingItemIndex].quantity
                      : 0.0;

                  return ListTile(
                    onTap: () {
                      context.read<SupplierPaymentsBloc>().add(
                            AddProductToPaymentEvent(product),
                          );
                      _productSearchController.clear();
                    },
                    title: Text(
                      product.description,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Código: ${product.id} | Costo: ${purchasePrice.formatToCurrency()}',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (quantityInCart > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.primary, width: 1),
                            ),
                            child: Text(
                              '${quantityInCart % 1 == 0 ? quantityInCart.toInt() : quantityInCart} unid.',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Icon(Icons.add, color: AppColors.primary),
                      ],
                    ),
                  );
                },
              );
            }
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Inicia una búsqueda de catálogo')),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCartItemRow(SelectedPaymentItem item, bool isDark) {
    final cost = item.product.purchasePrice ?? 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkDivider : Colors.grey.shade100,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.description,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Costo Unitario: ${cost.formatToCurrency()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    context.read<SupplierPaymentsBloc>().add(
                          UpdateProductQuantityEvent(
                              item.product.id, item.quantity - 1),
                        );
                  },
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                ),
                _editingProductId == item.product.id
                    ? SizedBox(
                        width: 40,
                        child: TextField(
                          controller: _editingController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          autofocus: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            border: UnderlineInputBorder(),
                          ),
                          onSubmitted: (val) {
                            _commitQuantity(item.product.id, val);
                          },
                          onTapOutside: (_) {
                            _commitQuantity(
                                item.product.id, _editingController.text);
                          },
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          setState(() {
                            _editingProductId = item.product.id;
                            _editingController.text =
                                item.quantity.toStringAsFixed(0);
                            _editingController.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: _editingController.text.length,
                            );
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.quantity.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                IconButton(
                  onPressed: () {
                    context.read<SupplierPaymentsBloc>().add(
                          UpdateProductQuantityEvent(
                              item.product.id, item.quantity + 1),
                        );
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              context.read<SupplierPaymentsBloc>().add(
                    RemoveProductFromPaymentEvent(item.product.id),
                  );
            },
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
