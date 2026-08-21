import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';

abstract class ProductLabelsState extends Equatable {
  const ProductLabelsState();

  @override
  List<Object?> get props => [];
}

class ProductLabelsInitial extends ProductLabelsState {}

class ProductLabelsLoading extends ProductLabelsState {}

class ProductLabelsLoaded extends ProductLabelsState {
  final List<Product> allProducts;
  final List<Product> selectedProducts;
  final List<String> categories;
  final String? selectedCategoryId;
  final String searchQuery;

  const ProductLabelsLoaded({
    required this.allProducts,
    this.selectedProducts = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.searchQuery = '',
  });

  List<Product> get products {
    List<Product> filtered = allProducts;
    if (selectedCategoryId != null &&
        selectedCategoryId!.toLowerCase() != 'todo' &&
        selectedCategoryId!.toLowerCase() != 'all') {
      filtered = filtered
          .where((p) =>
              p.categoryDescription.toLowerCase() ==
              selectedCategoryId!.toLowerCase())
          .toList();
    }
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.description.toLowerCase().contains(query) ||
              p.id.toString().contains(query) ||
              (p.barcodes?.any((b) =>
                      b.barcode != null &&
                      b.barcode.toString().toLowerCase().contains(query)) ??
                  false))
          .toList();
    }
    return filtered;
  }

  @override
  List<Object?> get props => [
        allProducts,
        selectedProducts,
        categories,
        selectedCategoryId,
        searchQuery,
      ];

  ProductLabelsLoaded copyWith({
    List<Product>? allProducts,
    List<Product>? selectedProducts,
    List<String>? categories,
    String? selectedCategoryId,
    String? searchQuery,
  }) {
    return ProductLabelsLoaded(
      allProducts: allProducts ?? this.allProducts,
      selectedProducts: selectedProducts ?? this.selectedProducts,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ProductLabelsError extends ProductLabelsState {
  final String message;

  const ProductLabelsError(this.message);

  @override
  List<Object> get props => [message];
}

class ProductLabelsPrinting extends ProductLabelsState {
  final List<Product> products;

  const ProductLabelsPrinting(this.products);

  @override
  List<Object> get props => [products];
}

class ProductLabelsPrintSuccess extends ProductLabelsState {
  final int count;

  const ProductLabelsPrintSuccess(this.count);

  @override
  List<Object> get props => [count];
}

class ProductLabelsPrintError extends ProductLabelsState {
  final String message;

  const ProductLabelsPrintError(this.message);

  @override
  List<Object> get props => [message];
}
