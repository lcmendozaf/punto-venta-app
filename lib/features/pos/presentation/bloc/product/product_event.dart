import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {
  final int? priceListId;

  const LoadProducts({this.priceListId});

  @override
  List<Object?> get props => [priceListId];
}

class ProductsUpdated extends ProductEvent {
  final List<Product> products;
  final List<String> categories;
  final int priceListId;

  const ProductsUpdated({
    required this.products,
    required this.categories,
    required this.priceListId,
  });

  @override
  List<Object> get props => [products, categories, priceListId];
}

class ProductsErrorOccurred extends ProductEvent {
  final String error;

  const ProductsErrorOccurred(this.error);

  @override
  List<Object> get props => [error];
}

class LoadProductsByCategory extends ProductEvent {
  final String category;

  const LoadProductsByCategory(this.category);

  @override
  List<Object> get props => [category];
}

class SearchProducts extends ProductEvent {
  final String query;

  const SearchProducts(this.query);

  @override
  List<Object> get props => [query];
}

class LoadCategories extends ProductEvent {}

class ChangePriceList extends ProductEvent {
  final int listId;

  const ChangePriceList(this.listId);

  @override
  List<Object> get props => [listId];
}
