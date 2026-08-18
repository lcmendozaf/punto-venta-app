import 'package:equatable/equatable.dart';
import '../../../domain/entities/supplier.dart';
import '../../../domain/entities/product.dart';

enum SupplierPaymentStatus { initial, loading, success, error, submitting }

class SelectedPaymentItem extends Equatable {
  final Product product;
  final double quantity;

  const SelectedPaymentItem({required this.product, required this.quantity});

  double get subtotal => quantity * (product.purchasePrice ?? 0.0);

  SelectedPaymentItem copyWith({Product? product, double? quantity}) {
    return SelectedPaymentItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}

class SupplierPaymentsState extends Equatable {
  final SupplierPaymentStatus status;
  final String? errorMessage;
  final List<Supplier> suppliers;
  final Supplier? selectedSupplier;
  final List<SelectedPaymentItem> items;
  final double totalPaid;
  final double total;
  final int? remitoNumber;
  final int? providerTicket;

  const SupplierPaymentsState({
    required this.status,
    this.errorMessage,
    required this.suppliers,
    this.selectedSupplier,
    required this.items,
    required this.totalPaid,
    required this.total,
    this.remitoNumber,
    this.providerTicket,
  });

  factory SupplierPaymentsState.initial() {
    return const SupplierPaymentsState(
      status: SupplierPaymentStatus.initial,
      suppliers: [],
      items: [],
      totalPaid: 0.0,
      total: 0.0,
    );
  }

  SupplierPaymentsState copyWith({
    SupplierPaymentStatus? status,
    String? errorMessage,
    List<Supplier>? suppliers,
    Supplier? selectedSupplier,
    bool clearSelectedSupplier = false,
    List<SelectedPaymentItem>? items,
    double? totalPaid,
    double? total,
    int? remitoNumber,
    int? supplierTicket,
    bool clearDocuments = false,
  }) {
    return SupplierPaymentsState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      suppliers: suppliers ?? this.suppliers,
      selectedSupplier: clearSelectedSupplier
          ? null
          : (selectedSupplier ?? this.selectedSupplier),
      items: items ?? this.items,
      totalPaid: totalPaid ?? this.totalPaid,
      total: total ?? this.total,
      remitoNumber: clearDocuments ? null : (remitoNumber ?? this.remitoNumber),
      providerTicket:
          clearDocuments ? null : (supplierTicket ?? providerTicket),
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        suppliers,
        selectedSupplier,
        items,
        totalPaid,
        total,
        remitoNumber,
        providerTicket,
      ];
}
