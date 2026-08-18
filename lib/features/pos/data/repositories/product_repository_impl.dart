import 'package:punto_venta_app/features/pos/data/datasources/product_local_data_datasource.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource localDataSource;

  ProductRepositoryImpl({required this.localDataSource});

  @override
  Stream<List<Product>> getProducts() {
    return localDataSource.getProducts().map(
          (productModels) =>
              productModels.map((model) => model.toEntity()).toList(),
        );
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    final productModels = await localDataSource.getProductsByCategory(category);
    return productModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    final productModels = await localDataSource.searchProducts(query);
    return productModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<String>> getCategories() async {
    final categoryModels = await localDataSource.getCategories();
    return categoryModels
        .map((category) => category.description ?? '')
        .toList();
  }

  @override
  Future<void> updatePriceList(int listId) async {
    if (localDataSource is ProductLocalDataSourceImpl) {
      (localDataSource as ProductLocalDataSourceImpl).setListaPrecio(listId);
    }
  }

  @override
  Future<Product> createProduct(Product product) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteProduct(int codigo) {
    throw UnimplementedError();
  }

  @override
  Future<Product> updateProduct(Product product) {
    throw UnimplementedError();
  }
}
