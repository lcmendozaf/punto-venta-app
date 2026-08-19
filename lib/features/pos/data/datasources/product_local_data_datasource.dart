import 'package:dio/dio.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/features/pos/data/models/barcode_model.dart';
import 'package:punto_venta_app/features/pos/data/models/category_model.dart';
import 'package:punto_venta_app/features/pos/data/models/precio_articulo_model.dart';
import 'package:punto_venta_app/features/pos/data/models/product_model.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import 'package:retrofit/retrofit.dart';

part 'product_local_data_datasource.g.dart';

// =============================================================================
// Retrofit API Service
// =============================================================================

@RestApi()
abstract class ProductService {
  factory ProductService(Dio dio, {String baseUrl}) = _ProductService;

  @GET('/articles/')
  Future<List<ProductModel>> getProducts({
    @Query('skip') int skip = 0,
    @Query('limit') int limit = 1000,
    @Query('is_suspended_sale') String? isSuspendedSale,
    @Query('list_id') int? listId,
  });

  @GET('/barcodes/')
  Future<List<BarcodeModel>> getBarcodes({
    @Query('skip') int skip = 0,
    @Query('limit') int limit = 10000,
  });

  @GET('/prices_list/')
  Future<List<PrecioArticuloModel>> getPricesList({
    @Query('skip') int skip = 0,
    @Query('limit') int limit = 10000,
  });

  @GET('/categories/')
  Future<List<CategoryModel>> getCategories({
    @Query('skip') int skip = 0,
    @Query('limit') int limit = 10000,
  });
}

// =============================================================================
// Local Data Source Interface
// =============================================================================

abstract class ProductLocalDataSource {
  Stream<List<ProductModel>> getProducts();
  Future<List<ProductModel>> getProductsByCategory(String category);
  Future<List<ProductModel>> searchProducts(String query);
  Future<ProductModel?> searchByBarcode(String barcode);
  Future<List<CategoryModel>> getCategories();

  // Legacy / Compatibility methods
  Future<List<PrecioArticuloModel>> getPreciosArticulos();
  Future<Map<int, PrecioArticuloModel>> getPreciosByLista(int listaPrecio);

  void setListaPrecio(int lista);
  int getListaPrecio();
}

// =============================================================================
// Local Data Source Implementation
// =============================================================================

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final ProductService _apiService;
  int _listaActual;

  // Raw API response caches
  List<ProductModel>? _cachedProducts;
  List<BarcodeModel>? _cachedBarcodes;
  List<PrecioArticuloModel>? _cachedPrecios;
  List<CategoryModel>? _cachedCategories;

  // Optimized lookup caches
  List<ProductModel>? _cachedMappedProducts;
  Map<String, ProductModel>? _cachedBarcodeToProductMap;
  bool _isAllProductsLoaded = false;

  ProductLocalDataSourceImpl({
    int listaInicial = 1,
    ProductService? apiService,
  })  : _listaActual = listaInicial,
        _apiService = apiService ?? di.sl<ProductService>();

  // ---------------------------------------------------------------------------
  // Price List Getters & Setters
  // ---------------------------------------------------------------------------

  @override
  int getListaPrecio() => _listaActual;

  @override
  void setListaPrecio(int lista) {
    _listaActual = lista;
    clearCache();
  }

  // ---------------------------------------------------------------------------
  // Core Business Methods
  // ---------------------------------------------------------------------------

  @override
  Stream<List<ProductModel>> getProducts() async* {
    if (_cachedMappedProducts != null && _isAllProductsLoaded) {
      yield _cachedMappedProducts!;
      return;
    }

    // Se traen todos los códigos de barras en paralelo una única vez
    final barcodes = await _fetchBarcodes();

    // Agrupar los códigos de barras por id de producto para una asociación rápida
    final barcodesByProduct = <int, List<BarcodeModel>>{};
    for (var barcode in barcodes) {
      if (!barcodesByProduct.containsKey(barcode.articleId)) {
        barcodesByProduct[barcode.articleId ?? 0] = [];
      }
      barcodesByProduct[barcode.articleId]!.add(barcode);
    }

    const int chunkSize = 300;
    int skip = 0;
    bool hasMore = true;
    final Set<int> seenIds = {};

    // Inicializar cachés si es la primera carga
    _cachedMappedProducts ??= [];
    _cachedBarcodeToProductMap ??= {};

    while (hasMore) {
      try {
        final productsChunk = await _apiService.getProducts(
          skip: skip,
          limit: chunkSize,
          listId: _listaActual,
          isSuspendedSale: 'N',
        );

        if (productsChunk.isEmpty) {
          hasMore = false;
          _isAllProductsLoaded = true;
          break;
        }

        bool hasNewProduct = false;
        for (var p in productsChunk) {
          if (p.id != null && !seenIds.contains(p.id)) {
            seenIds.add(p.id!);
            hasNewProduct = true;
          }
        }

        if (!hasNewProduct) {
          hasMore = false;
          _isAllProductsLoaded = true;
          break;
        }

        final mappedChunk = productsChunk.map((product) {
          final productBarcodes = barcodesByProduct[product.id] ?? [];
          final fractional = product.fractional ?? 1;

          final productPrice =
              product.price == null ? null : product.price! * fractional;

          final productRegularPrice = product.regularPrice == null
              ? null
              : product.regularPrice! * fractional;

          final mappedProduct = product.copyWith(
            barcodes: productBarcodes,
            price: productPrice,
            regularPrice: productRegularPrice,
          );

          // Poblar el mapa de búsqueda rápida por código de barras
          for (var barcodeObj in productBarcodes) {
            if (barcodeObj.barcode != null) {
              _cachedBarcodeToProductMap![barcodeObj.barcode.toString()] =
                  mappedProduct;
            }
          }

          return mappedProduct;
        }).toList();

        _cachedMappedProducts!.addAll(mappedChunk);
        yield List<ProductModel>.from(_cachedMappedProducts!);

        if (productsChunk.length < chunkSize) {
          hasMore = false;
          _isAllProductsLoaded = true;
        } else {
          skip += chunkSize;
        }
      } catch (e) {
        hasMore = false;
        rethrow;
      }
    }
  }

  @override
  Future<ProductModel?> searchByBarcode(String barcode) async {
    if (_cachedBarcodeToProductMap == null || !_isAllProductsLoaded) {
      await getProducts().last;
    }
    return _cachedBarcodeToProductMap?[barcode];
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    if (_cachedMappedProducts == null || !_isAllProductsLoaded) {
      await getProducts().last;
    }
    final products = _cachedMappedProducts ?? [];

    if (category.toLowerCase() == 'todo' || category.toLowerCase() == 'all') {
      return products;
    }

    return products
        .where((product) =>
            product.categoryDescription?.toLowerCase() ==
            category.toLowerCase())
        .toList();
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    if (_cachedMappedProducts == null || !_isAllProductsLoaded) {
      await getProducts().last;
    }
    final products = _cachedMappedProducts ?? [];

    if (query.isEmpty) return products;

    final lowerQuery = query.toLowerCase();
    return products
        .where((product) =>
            (product.description ?? "").toLowerCase().contains(lowerQuery) ||
            product.id.toString().contains(lowerQuery) ||
            (product.categoryDescription ?? "")
                .toLowerCase()
                .contains(lowerQuery) ||
            _hasMatchingBarcode(product, lowerQuery))
        .toList();
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    if (_cachedCategories != null) {
      return _cachedCategories!;
    }

    try {
      _cachedCategories = await _apiService.getCategories();
      return _cachedCategories!;
    } catch (e) {
      _cachedCategories = [];
      return _cachedCategories!;
    }
  }

  // ---------------------------------------------------------------------------
  // Helper / Private Fetching Methods
  // ---------------------------------------------------------------------------

  Future<List<BarcodeModel>> _fetchBarcodes() async {
    if (_cachedBarcodes != null) {
      return _cachedBarcodes!;
    }

    try {
      _cachedBarcodes = await _apiService.getBarcodes();
      return _cachedBarcodes!;
    } catch (e) {
      _cachedBarcodes = [];
      return _cachedBarcodes!;
    }
  }

  bool _hasMatchingBarcode(ProductModel product, String query) {
    if (product.barcodes == null) return false;
    return product.barcodes!
        .any((barcode) => barcode.barcode.toString().contains(query));
  }

  // ---------------------------------------------------------------------------
  // Cache Management
  // ---------------------------------------------------------------------------

  void clearCache() {
    _cachedProducts = null;
    _cachedPrecios = null;
    _cachedBarcodes = null;
    _cachedCategories = null;
    _cachedMappedProducts = null;
    _cachedBarcodeToProductMap = null;
    _isAllProductsLoaded = false;
  }

  // ---------------------------------------------------------------------------
  // Legacy / Compatibility Methods (Prices list are now handled by backend)
  // ---------------------------------------------------------------------------

  @override
  Future<List<PrecioArticuloModel>> getPreciosArticulos() async {
    if (_cachedPrecios != null) {
      return _cachedPrecios!;
    }

    try {
      _cachedPrecios = await _apiService.getPricesList();
      return _cachedPrecios!;
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al cargar precios'));
    }
  }

  @override
  Future<Map<int, PrecioArticuloModel>> getPreciosByLista(
      int listaPrecio) async {
    final precios = await getPreciosArticulos();
    final preciosByProducto = <int, PrecioArticuloModel>{};

    for (var precio in precios) {
      if (precio.listId == listaPrecio) {
        preciosByProducto[precio.productId] = precio;
      }
    }

    return preciosByProducto;
  }
}
