
import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';

abstract class ProductLabelsEvent extends Equatable {
  const ProductLabelsEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductLabelsEvent {
  const LoadProducts();
}

class ProductsUpdated extends ProductLabelsEvent {
  final List<Product> products;
  final List<String> categories;

  const ProductsUpdated({required this.products, required this.categories});

  @override
  List<Object> get props => [products, categories];
}

class ProductsErrorOccurred extends ProductLabelsEvent {
  final String error;

  const ProductsErrorOccurred(this.error);

  @override
  List<Object> get props => [error];
}

class LoadProductsByCategory extends ProductLabelsEvent {
  final String categoryId;

  const LoadProductsByCategory(this.categoryId);

  @override
  List<Object> get props => [categoryId];
}

class SearchProducts extends ProductLabelsEvent {
  final String query;

  const SearchProducts(this.query);

  @override
  List<Object> get props => [query];
}

class ToggleProductSelection extends ProductLabelsEvent {
  final Product product;

  const ToggleProductSelection(this.product);

  @override
  List<Object> get props => [product];
}

class ClearSelection extends ProductLabelsEvent {
  const ClearSelection();
}

class PrintSelectedLabels extends ProductLabelsEvent {
  const PrintSelectedLabels();
}

class SelectAllVisibleProducts extends ProductLabelsEvent {
  const SelectAllVisibleProducts();
}