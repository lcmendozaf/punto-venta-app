import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Product> allProducts;
  final List<String> categories;
  final String selectedCategory;
  final String searchQuery;
  final int currentPriceList;

  const ProductLoaded({
    required this.allProducts,
    required this.categories,
    this.selectedCategory = 'Todo',
    this.searchQuery = '',
    required this.currentPriceList,
  });

  List<Product> get products {
    List<Product> filtered = allProducts;
    if (selectedCategory.toLowerCase() != 'todo' &&
        selectedCategory.toLowerCase() != 'all') {
      filtered = filtered
          .where((p) =>
              p.categoryDescription.toLowerCase() ==
              selectedCategory.toLowerCase())
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

  ProductLoaded copyWith({
    List<Product>? allProducts,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
    int? currentPriceList,
  }) {
    return ProductLoaded(
      allProducts: allProducts ?? this.allProducts,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPriceList: currentPriceList ?? this.currentPriceList,
    );
  }

  @override
  List<Object> get props => [
        allProducts,
        categories,
        selectedCategory,
        searchQuery,
        currentPriceList,
      ];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object> get props => [message];
}
