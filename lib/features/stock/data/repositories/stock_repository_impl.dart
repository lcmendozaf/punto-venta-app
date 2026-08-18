import 'package:uuid/uuid.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/product_repository.dart';
import 'package:punto_venta_app/features/stock/data/datasources/stock_local_datasource.dart';
import 'package:punto_venta_app/features/stock/data/models/stock_movement_model.dart';
import 'package:punto_venta_app/features/stock/domain/entities/stock_movement.dart';
import 'package:punto_venta_app/features/stock/domain/repositories/stock_repository.dart';

class StockRepositoryImpl implements StockRepository {
  final StockLocalDatasource localDatasource;
  final ProductRepository productRepository;
  final Uuid uuid;

  StockRepositoryImpl({
    required this.localDatasource,
    required this.productRepository,
    required this.uuid,
  });

  @override
  Future<List<Product>> getAllProducts() async {
    return await productRepository.getProducts().last;
  }

  @override
  Future<Product?> getProductByCodigo(int codigo) async {
    final products = await productRepository.getProducts().last;
    try {
      return products.firstWhere((p) => p.id == codigo);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Product> createProduct(Product product) async {
    return await productRepository.createProduct(product);
  }

  @override
  Future<Product> updateProduct(Product product) async {
    return await productRepository.updateProduct(product);
  }

  @override
  Future<void> deleteProduct(int codigo) async {
    return await productRepository.deleteProduct(codigo);
  }

  @override
  Future<int> getProductStock(int codigo) async {
    return await localDatasource.getProductStock(codigo);
  }

  @override
  Future<void> updateProductStock(int codigo, int newStock) async {
    await localDatasource.updateProductStock(codigo, newStock);
  }

  @override
  Future<void> addStock(
    int codigo,
    int quantity,
    String reason,
    String userId,
    String userName,
  ) async {
    if (quantity <= 0) {
      throw Exception('La cantidad debe ser mayor a 0');
    }

    final currentStock = await localDatasource.getProductStock(codigo);
    final newStock = currentStock + quantity;

    final movement = StockMovementModel(
      id: uuid.v4(),
      productCodigo: codigo,
      type: MovementType.entrada,
      quantity: quantity,
      previousStock: currentStock,
      newStock: newStock,
      reason: reason,
      userId: userId,
      userName: userName,
      createdAt: DateTime.now(),
    );

    await localDatasource.createMovement(movement);
    await localDatasource.updateProductStock(codigo, newStock);
  }

  @override
  Future<void> removeStock(
    int codigo,
    int quantity,
    String reason,
    String userId,
    String userName,
  ) async {
    if (quantity <= 0) {
      throw Exception('La cantidad debe ser mayor a 0');
    }

    final currentStock = await localDatasource.getProductStock(codigo);
    
    if (currentStock < quantity) {
      throw Exception('Stock insuficiente (disponible: $currentStock)');
    }

    final newStock = currentStock - quantity;

    final movement = StockMovementModel(
      id: uuid.v4(),
      productCodigo: codigo,
      type: MovementType.salida,
      quantity: quantity,
      previousStock: currentStock,
      newStock: newStock,
      reason: reason,
      userId: userId,
      userName: userName,
      createdAt: DateTime.now(),
    );

    await localDatasource.createMovement(movement);
    await localDatasource.updateProductStock(codigo, newStock);
  }

  @override
  Future<void> adjustStock(
    int codigo,
    int newStock,
    String reason,
    String userId,
    String userName,
  ) async {
    if (newStock < 0) {
      throw Exception('El stock no puede ser negativo');
    }

    final currentStock = await localDatasource.getProductStock(codigo);
    final quantity = (newStock - currentStock).abs();

    final movement = StockMovementModel(
      id: uuid.v4(),
      productCodigo: codigo,
      type: MovementType.ajuste,
      quantity: quantity,
      previousStock: currentStock,
      newStock: newStock,
      reason: reason,
      userId: userId,
      userName: userName,
      createdAt: DateTime.now(),
    );

    await localDatasource.createMovement(movement);
    await localDatasource.updateProductStock(codigo, newStock);
  }

  @override
  Future<List<StockMovement>> getProductMovements(int codigo) async {
    return await localDatasource.getProductMovements(codigo);
  }

  @override
  Future<List<StockMovement>> getAllMovements({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    return await localDatasource.getAllMovements(
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}