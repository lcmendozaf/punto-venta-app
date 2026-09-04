import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/usecases/manage_cart_usecase.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../domain/entities/cart_log_entry.dart';
import 'cart_event.dart';
import 'cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/internal_tax_calculator.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final ManageCartUsecase manageCartUsecase;
  final SharedPreferences sharedPreferences;

  CartBloc({
    required this.manageCartUsecase,
    required this.sharedPreferences,
  }) : super(CartInitial()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveQuantityFromCart>(_onRemoveQuantityFromCart);
    on<ClearCart>(_onClearCart);
    on<ReplaceCart>(_onReplaceCart);
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    final currentItems = _getCurrentItems();
    if (currentItems.isEmpty) {
      final ticketId = const Uuid().v4();
      sharedPreferences.setString('current_ticket_id', ticketId);
    }
    final newItems = manageCartUsecase.addToCart(
      currentItems,
      event.product,
      event.quantity,
      isWeighted: event.isWeighted ?? false,
      weightKg: event.weightKg,
      pricePerKg: event.pricePerKg,
    );
    
    final totalItems = manageCartUsecase.getTotalItems(newItems);

    final totals = _calculateSubtotalAndIva(newItems);
    final subtotal = totals['subtotal']!;
    final totalIva = totals['totalIva']!;
    final total = subtotal + totalIva;

    final internalTaxResult = InternalTaxCalculator.calculateInternalTax(
      items: newItems,
    );
    final internalTax = internalTaxResult['total'] ?? 0.0;
    final totalConIva = subtotal + totalIva + internalTax;

    final currentLog = _getCurrentLog();

    final entry = CartLogEntry(
      id: _randomId(),
      type: CartActionType.add,
      item: CartItem(
        product: event.product,
        quantity: event.quantity,
        iva: event.product.vat,
        isWeighted: event.isWeighted ?? false,
        weightKg: event.weightKg,
        pricePerKg: event.pricePerKg,
      ),
      timestamp: DateTime.now(),
    );

    final newLog = List<CartLogEntry>.from(currentLog)..add(entry);

    emit(CartLoaded(
      items: newItems,
      total: total,
      totalItems: totalItems,
      log: newLog,
      subtotal: subtotal,
      totalIva: totalIva,
      internalTax: internalTax,
      totalConIva: totalConIva,
    ));
  }

  void _onReplaceCart(ReplaceCart event, Emitter<CartState> emit) {
    final items = event.items;
    final log = event.log;
    final totalItems = manageCartUsecase.getTotalItems(items);

    if (event.ticketId != null) {
      sharedPreferences.setString('current_ticket_id', event.ticketId!);
    }

    final totals = _calculateSubtotalAndIva(items);
    final subtotal = totals['subtotal']!;
    final totalIva = totals['totalIva']!;
    final total = subtotal + totalIva;

    final internalTaxResult = InternalTaxCalculator.calculateInternalTax(
      items: items,
    );
    final internalTax = internalTaxResult['total'] ?? 0.0;
    final totalConIva = subtotal + totalIva + internalTax;

    emit(CartLoaded(
      items: items,
      total: total,
      totalItems: totalItems,
      log: log,
      subtotal: subtotal,
      totalIva: totalIva,
      internalTax: internalTax,
      totalConIva: totalConIva,
    ));
  }

  void _onRemoveQuantityFromCart(
      RemoveQuantityFromCart event, Emitter<CartState> emit) {
    final currentItems = _getCurrentItems();
    final newItems = manageCartUsecase.removeQuantityFromCart(
      currentItems,
      event.productId,
      event.quantity,
      isWeighted: event.isWeighted ?? false,
      weightKg: event.weightKg,
      pricePerKg: event.pricePerKg,
    );
    final totalItems = manageCartUsecase.getTotalItems(newItems);

    final existingProduct = currentItems.firstWhere(
      (it) => it.product.id.toString() == event.productId,
    );

    final currentLog = _getCurrentLog();
    final entry = CartLogEntry(
      id: _randomId(),
      type: CartActionType.remove,
      item: CartItem(
        product: existingProduct.product,
        quantity: event.quantity,
        iva: existingProduct.iva,
        isWeighted: event.isWeighted,
        weightKg: event.weightKg,
        pricePerKg: event.pricePerKg,
      ),
      timestamp: DateTime.now(),
    );
    final newLog = List<CartLogEntry>.from(currentLog)..add(entry);

    final totals = _calculateSubtotalAndIva(newItems);
    final subtotal = totals['subtotal']!;
    final totalIva = totals['totalIva']!;
    final total = subtotal + totalIva;

    final internalTaxResult = InternalTaxCalculator.calculateInternalTax(
      items: newItems,
    );
    final internalTax = internalTaxResult['total'] ?? 0.0;
    final totalConIva = subtotal + totalIva + internalTax;

    emit(CartLoaded(
      items: newItems,
      total: total,
      totalItems: totalItems,
      log: newLog,
      subtotal: subtotal,
      totalIva: totalIva,
      internalTax: internalTax,
      totalConIva: totalConIva,
    ));
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    sharedPreferences.remove('current_ticket_id');
    emit(const CartLoaded(
      items: [],
      total: 0.0,
      totalItems: 0,
      log: [],
      subtotal: 0.0,
      totalIva: 0.0,
      internalTax: 0.0,
      totalConIva: 0.0,
    ));
  }

  Map<String, double> _calculateSubtotalAndIva(List<CartItem> items) {
    double subtotal = 0;
    double totalIva = 0;
    for (final it in items) {
      final precio = it.product.price ?? 0;
      final isWeighted = it.isWeighted ?? false;
      final pricePerKg = it.pricePerKg ?? 0.0;
      final cantidad = it.quantity;
      final tasaIva = (it.iva) / 100;

      if (isWeighted) {
        final precioTotal = pricePerKg;
        final ivaArticulo = precioTotal * tasaIva;
        subtotal += precioTotal;
        totalIva += ivaArticulo;
      } else {
        final precioTotal = precio * cantidad;
        final ivaArticulo = precioTotal * tasaIva;
        subtotal += precioTotal;
        totalIva += ivaArticulo;
      }
    }
    return {'subtotal': subtotal, 'totalIva': totalIva};
  }

  List<CartItem> _getCurrentItems() {
    if (state is CartLoaded) {
      return (state as CartLoaded).items;
    }
    return [];
  }

  List<CartLogEntry> _getCurrentLog() {
    if (state is CartLoaded) {
      return (state as CartLoaded).log;
    }
    return [];
  }

  String _randomId() {
    return const Uuid().v4();
  }

  int getProductQuantityInCart(String productId) {
    final currentItems = _getCurrentItems();
    final found = currentItems.firstWhere(
      (it) => it.product.id.toString() == productId,
    );
    return found.quantity;
  }
}
