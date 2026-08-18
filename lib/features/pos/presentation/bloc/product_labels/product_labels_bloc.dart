import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_products_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/label_image_builder.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/templates/base_ticket_template.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_socket_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_local_datasource.dart';
import 'product_labels_event.dart';
import 'product_labels_state.dart';

class ProductLabelsBloc extends Bloc<ProductLabelsEvent, ProductLabelsState> {
  final GetProductsUsecase getProductsUsecase;
  final PriceListLocalDataSource priceListLocalDataSource;
  final PrinterSocketDatasource? printerDataSource;
  final PrinterLocalDataSource printerLocalDataSource;

  ProductLabelsBloc({
    required this.getProductsUsecase,
    required this.priceListLocalDataSource,
    this.printerDataSource,
    required this.printerLocalDataSource,
  }) : super(ProductLabelsInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<LoadProductsByCategory>(_onLoadProductsByCategory);
    on<SearchProducts>(_onSearchProducts);
    on<ToggleProductSelection>(_onToggleProductSelection);
    on<ClearSelection>(_onClearSelection);
    on<PrintSelectedLabels>(_onPrintSelectedLabels);
    on<SelectAllVisibleProducts>(_onSelectAllVisibleProducts);
  }

  Future<void> _onSelectAllVisibleProducts(
    SelectAllVisibleProducts event,
    Emitter<ProductLabelsState> emit,
  ) async {
    if (state is! ProductLabelsLoaded) return;
    final currentState = state as ProductLabelsLoaded;
    emit(currentState.copyWith(
        selectedProducts: List<Product>.from(currentState.products)));
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductLabelsState> emit,
  ) async {
    emit(ProductLabelsLoading());
    try {
      int currentList = await priceListLocalDataSource.getCurrentPriceList();
      if (currentList <= 0) {
        currentList = 1;
        await priceListLocalDataSource.savePriceList(currentList);
      }

      await getProductsUsecase.updatePriceList(currentList);

      final products = await getProductsUsecase().last;
      final categories = await getProductsUsecase.getCategories();

      emit(ProductLabelsLoaded(
        products: products,
        categories: categories,
        selectedProducts: const [],
      ));
    } catch (e) {
      emit(ProductLabelsError(e.toString()));
    }
  }

  Future<void> _onLoadProductsByCategory(
    LoadProductsByCategory event,
    Emitter<ProductLabelsState> emit,
  ) async {
    if (state is! ProductLabelsLoaded) return;

    final currentState = state as ProductLabelsLoaded;
    emit(ProductLabelsLoading());

    try {
      final products = await getProductsUsecase.getByCategory(event.categoryId);

      emit(ProductLabelsLoaded(
        products: products,
        categories: currentState.categories,
        selectedProducts: currentState.selectedProducts,
        selectedCategoryId: event.categoryId,
      ));
    } catch (e) {
      emit(ProductLabelsError(e.toString()));
    }
  }

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<ProductLabelsState> emit,
  ) async {
    if (state is! ProductLabelsLoaded) return;

    final currentState = state as ProductLabelsLoaded;
    emit(ProductLabelsLoading());

    try {
      final products = await getProductsUsecase.search(event.query);

      emit(ProductLabelsLoaded(
        products: products,
        categories: currentState.categories,
        selectedProducts: currentState.selectedProducts,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(ProductLabelsError(e.toString()));
    }
  }

  Future<void> _onToggleProductSelection(
    ToggleProductSelection event,
    Emitter<ProductLabelsState> emit,
  ) async {
    if (state is! ProductLabelsLoaded) return;

    final currentState = state as ProductLabelsLoaded;
    final selectedProducts = List<Product>.from(currentState.selectedProducts);

    if (selectedProducts.any((p) => p.id == event.product.id)) {
      selectedProducts.removeWhere((p) => p.id == event.product.id);
    } else {
      selectedProducts.add(event.product);
    }

    emit(currentState.copyWith(selectedProducts: selectedProducts));
  }

  Future<void> _onClearSelection(
    ClearSelection event,
    Emitter<ProductLabelsState> emit,
  ) async {
    if (state is! ProductLabelsLoaded) return;

    final currentState = state as ProductLabelsLoaded;
    emit(currentState.copyWith(selectedProducts: []));
  }

  Future<void> _onPrintSelectedLabels(
    PrintSelectedLabels event,
    Emitter<ProductLabelsState> emit,
  ) async {
    if (state is! ProductLabelsLoaded) return;

    final currentState = state as ProductLabelsLoaded;
    final selectedProducts = currentState.selectedProducts;

    if (selectedProducts.isEmpty) {
      emit(const ProductLabelsPrintError(
          'No hay productos seleccionados para imprimir'));
      emit(currentState);
      return;
    }

    emit(ProductLabelsPrinting(selectedProducts));

    try {
      if (printerDataSource == null) {
        throw Exception('Impresora no configurada');
      }

      // Obtener configuración de la impresora
      final config = await printerLocalDataSource.getPrinterConfig();

      if (config.ip.isEmpty) {
        throw Exception(
            'No hay una dirección IP configurada para la impresora');
      }

      // Conectar a la impresora
      final connected = await printerDataSource!.connect(config);
      if (!connected) {
        throw Exception('No se pudo conectar con la impresora');
      }

      int labelSize = config.labelType == 0 ? 8 * 72 : 8 * 52;

      // Imprimir etiquetas
      for (final product in selectedProducts) {
        // Generar imagen de la etiqueta
        final imageBytes =
            await LabelImageBuilder.buildProductLabelImage(product);

        final commands = [
          TicketCommand.image(imageBytes, labelSize),
          TicketCommand.feedLine(),
          TicketCommand.cutPaper(),
        ];

        final success = await printerDataSource!.printCommands(commands);
        if (!success) {
          throw Exception('Error al imprimir etiqueta de ${product.name}');
        }
      }

      // Desconectar de la impresora
      await printerDataSource!.disconnect();

      emit(ProductLabelsPrintSuccess(selectedProducts.length));

      emit(currentState.copyWith(selectedProducts: []));
    } catch (e) {
      // Asegurar desconexión en caso de error
      try {
        await printerDataSource?.disconnect();
      } catch (_) {}

      emit(ProductLabelsPrintError(e.toString()));
      emit(currentState);
    }
  }
}
