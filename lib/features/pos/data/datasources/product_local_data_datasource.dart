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
    if (_listaActual == lista) return;
    _listaActual = lista;
    clearCache();
  }

  // ---------------------------------------------------------------------------
  // Core Business Methods
  // ---------------------------------------------------------------------------

  @override
  Stream<List<ProductModel>> getProducts() async* {
    print('DEBUG: ProductLocalDataSourceImpl.getProducts() started');
    if (_cachedMappedProducts != null && _cachedMappedProducts!.isNotEmpty) {
      print('DEBUG: getProducts() yielding cached products. Count: ${_cachedMappedProducts!.length}');
      yield _cachedMappedProducts!;
    }

    print('DEBUG: getProducts() fetching barcodes...');
    final barcodes = await _fetchBarcodes();
    print('DEBUG: getProducts() barcodes fetched. Count: ${barcodes.length}');

    // Agrupar los códigos de barras por id de producto para una asociación rápida
    final barcodesByProduct = <int, List<BarcodeModel>>{};
    for (var barcode in barcodes) {
      final articleId = barcode.articleId;
      if (articleId != null) {
        if (!barcodesByProduct.containsKey(articleId)) {
          barcodesByProduct[articleId] = [];
        }
        barcodesByProduct[articleId]!.add(barcode);
      }
    }

    const int chunkSize = 300;
    int skip = 0;
    bool hasMore = true;
    final Set<int> seenIds = {};

    // Inicializar cachés si es la primera carga
    _cachedMappedProducts ??= [];
    _cachedBarcodeToProductMap ??= {};

    print('DEBUG: getProducts() chunk loop starting...');
    while (hasMore) {
      try {
        print('DEBUG: getProducts() requesting chunk skip: $skip, limit: $chunkSize');
        final productsChunk = await _apiService.getProducts(
          skip: skip,
          limit: chunkSize,
          listId: _listaActual,
          isSuspendedSale: 'N',
        );
        print('DEBUG: getProducts() chunk received. Count: ${productsChunk.length}');

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

        // Si el caché fue limpiado en medio de la petición asíncrona, abortamos para evitar excepciones de nulo
        if (_cachedMappedProducts == null || _cachedBarcodeToProductMap == null) {
          hasMore = false;
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
            if (barcodeObj.barcode != null && _cachedBarcodeToProductMap != null) {
              _cachedBarcodeToProductMap![barcodeObj.barcode.toString()] =
                  mappedProduct;
            }
          }

          return mappedProduct;
        }).toList();

        // Evitar duplicados por concurrencia y verificar nulabilidad del caché, actualizando si ya existe
        if (_cachedMappedProducts != null) {
          for (var p in mappedChunk) {
            final existingIndex =
                _cachedMappedProducts!.indexWhere((cached) => cached.id == p.id);
            if (existingIndex != -1) {
              _cachedMappedProducts![existingIndex] = p;
            } else {
              _cachedMappedProducts!.add(p);
            }
          }
          yield List<ProductModel>.from(_cachedMappedProducts!);
        } else {
          hasMore = false;
          break;
        }

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
    print('DEBUG: _fetchBarcodes() started');
    if (_cachedBarcodes != null) {
      print('DEBUG: _fetchBarcodes() returning cached barcodes. Count: ${_cachedBarcodes!.length}');
      return _cachedBarcodes!;
    }

    try {
      print('DEBUG: _fetchBarcodes() calling API getBarcodes...');
      _cachedBarcodes = await _apiService.getBarcodes();
      print('DEBUG: _fetchBarcodes() API call success. Count: ${_cachedBarcodes!.length}');
      return _cachedBarcodes!;
    } catch (e) {
      print('DEBUG: _fetchBarcodes() API call failed. Error: $e');
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
