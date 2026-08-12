import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object> get props => [];
}

class AddToCart extends CartEvent {
  final Product product;
  final int quantity;
  final bool? isWeighted;
  final double? weightKg;
  final double? pricePerKg;

  const AddToCart(this.product, {this.quantity = 1, this.isWeighted, this.weightKg, this.pricePerKg});
  @override
  List<Object> get props => [product, quantity, weightKg ?? 0, pricePerKg ?? 0];
}

class ReplaceCart extends CartEvent {
  final List<CartItem> items;
  final List<CartLogEntry> log;
  final String? ticketId;

  const ReplaceCart({required this.items, this.log = const [], this.ticketId});

  @override
  List<Object> get props => [items, log, ticketId ?? ''];
}

class RemoveQuantityFromCart extends CartEvent {
  final String productId;
  final int quantity;
  final bool? isWeighted;
  final double? weightKg;
  final double? pricePerKg;

  const RemoveQuantityFromCart(this.productId, this.quantity, {this.isWeighted, this.weightKg, this.pricePerKg});

  @override
  List<Object> get props => [productId, quantity, weightKg ?? 0, pricePerKg ?? 0];
}

class ClearCart extends CartEvent {}
