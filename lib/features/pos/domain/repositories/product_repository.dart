import 'package:punto_venta_app/features/pos/domain/entities/product.dart';

abstract class ProductRepository {
  Stream<List<Product>> getProducts();
  Future<List<Product>> getProductsByCategory(String category);
  Future<List<Product>> searchProducts(String query);
  Future<List<String>> getCategories();
  Future<Product> createProduct(Product product);  
  Future<Product> updateProduct(Product product);  
  Future<void> deleteProduct(int codigo);
  Future<void> updatePriceList(int listId); 
}
