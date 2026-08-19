import 'package:equatable/equatable.dart';

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
