import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_products_usecase.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_local_datasource.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUsecase getProductsUsecase;
  final PriceListLocalDataSource priceListLocalDataSource;
  StreamSubscription<List<Product>>? _productsSubscription;

  ProductBloc({
    required this.getProductsUsecase,
    required this.priceListLocalDataSource,
  }) : super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<ProductsUpdated>(_onProductsUpdated);
    on<ProductsErrorOccurred>(_onProductsErrorOccurred);
    on<LoadProductsByCategory>(_onLoadProductsByCategory);
    on<SearchProducts>(_onSearchProducts);
    on<LoadCategories>(_onLoadCategories);
    on<ChangePriceList>(_onChangePriceList);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    await _productsSubscription?.cancel();
    _productsSubscription = null;

    emit(ProductLoading());
    try {
      int currentList;
      if (event.priceListId != null && event.priceListId! > 0) {
        currentList = event.priceListId!;
      } else {
        currentList = await priceListLocalDataSource.getCurrentPriceList();
        if (currentList <= 0) {
          currentList = 1;
          await priceListLocalDataSource.savePriceList(currentList);
        }
      }

      // se actualiza la lista de precios en el usecase para que los productos se traigan con los precios correctos
      await getProductsUsecase.updatePriceList(currentList);

      // se traen las categorías primero
      final categories = await getProductsUsecase.getCategories();

      _productsSubscription = getProductsUsecase().listen(
        (products) {
          add(ProductsUpdated(
            products: products,
            categories: categories,
            priceListId: currentList,
          ));
        },
        onError: (error, stackTrace) {
          add(ProductsErrorOccurred(error.toString()));
        },
      );
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  void _onProductsUpdated(
    ProductsUpdated event,
    Emitter<ProductState> emit,
  ) {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      if (currentState.currentPriceList == event.priceListId) {
        emit(currentState.copyWith(
          allProducts: event.products,
          categories: event.categories,
        ));
      }
    } else {
      emit(ProductLoaded(
        allProducts: event.products,
        categories: event.categories,
        currentPriceList: event.priceListId,
      ));
    }
  }

  void _onProductsErrorOccurred(
    ProductsErrorOccurred event,
    Emitter<ProductState> emit,
  ) {
    if (state is! ProductLoaded) {
      emit(ProductError(event.error));
    }
  }

  Future<void> _onLoadProductsByCategory(
    LoadProductsByCategory event,
    Emitter<ProductState> emit,
  ) async {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      emit(currentState.copyWith(
        selectedCategory: event.category,
        searchQuery: '',
      ));
    }
  }

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<ProductState> emit,
  ) async {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      emit(currentState.copyWith(
        searchQuery: event.query,
        selectedCategory:
            event.query.isEmpty ? currentState.selectedCategory : 'Todo',
      ));
    }
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<ProductState> emit,
  ) async {
    try {
      final categories = await getProductsUsecase.getCategories();

      if (state is ProductLoaded) {
        final currentState = state as ProductLoaded;
        emit(currentState.copyWith(categories: categories));
      }
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onChangePriceList(
    ChangePriceList event,
    Emitter<ProductState> emit,
  ) async {
    await _productsSubscription?.cancel();
    _productsSubscription = null;

    emit(ProductLoading());

    try {
      final listId = event.listId > 0 ? event.listId : 1;

      await priceListLocalDataSource.savePriceList(listId);
      await getProductsUsecase.updatePriceList(listId);

      // se traen las categorías primero
      final categories = await getProductsUsecase.getCategories();

      _productsSubscription = getProductsUsecase().listen(
        (products) {
          add(ProductsUpdated(
            products: products,
            categories: categories,
            priceListId: listId,
          ));
        },
        onError: (error, stackTrace) {
          add(ProductsErrorOccurred(error.toString()));
        },
      );
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _productsSubscription?.cancel();
    return super.close();
  }
}
