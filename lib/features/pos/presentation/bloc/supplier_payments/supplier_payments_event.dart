import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_state.dart';
import '../../../domain/entities/supplier.dart';
import '../../../domain/entities/product.dart';

abstract class SupplierPaymentsEvent extends Equatable {
  const SupplierPaymentsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSuppliersEvent extends SupplierPaymentsEvent {}

class SelectSupplierEvent extends SupplierPaymentsEvent {
  final Supplier? supplier;
  const SelectSupplierEvent(this.supplier);

  @override
  List<Object?> get props => [supplier];
}

class AddProductToPaymentEvent extends SupplierPaymentsEvent {
  final Product product;
  final double? quantity;
  const AddProductToPaymentEvent(this.product, {this.quantity});

  @override
  List<Object?> get props => [product, quantity];
}

class RemoveProductFromPaymentEvent extends SupplierPaymentsEvent {
  final int productId;
  const RemoveProductFromPaymentEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

class UpdateProductQuantityEvent extends SupplierPaymentsEvent {
  final int productId;
  final double quantity;
  const UpdateProductQuantityEvent(this.productId, this.quantity);

  @override
  List<Object?> get props => [productId, quantity];
}

class UpdatePaymentAmountsEvent extends SupplierPaymentsEvent {
  final double? totalPaid;
  final double? totalCharged;
  const UpdatePaymentAmountsEvent({this.totalPaid, this.totalCharged});

  @override
  List<Object?> get props => [totalPaid, totalCharged];
}

class UpdateDocumentNumbersEvent extends SupplierPaymentsEvent {
  final int? remitoNumber;
  final int? supplierTicket;
  const UpdateDocumentNumbersEvent({this.remitoNumber, this.supplierTicket});

  @override
  List<Object?> get props => [remitoNumber, supplierTicket];
}

class SubmitSupplierPaymentEvent extends SupplierPaymentsEvent {
  final int userId;
  const SubmitSupplierPaymentEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class ResetSupplierPaymentFormEvent extends SupplierPaymentsEvent {}

class SaveSupplierDraftEvent extends SupplierPaymentsEvent {
  final int supplierId;
  final List<SelectedPaymentItem> items;
  final double totalPaid;
  final double total;
  final int? remitoNumber;
  final int? supplierTicket;

  const SaveSupplierDraftEvent({
    required this.supplierId,
    required this.items,
    required this.totalPaid,
    required this.total,
    this.remitoNumber,
    this.supplierTicket,
  });

  @override
  List<Object?> get props => [
        supplierId,
        items,
        totalPaid,
        total,
        remitoNumber,
        supplierTicket,
      ];
}

class DiscardSupplierDraftEvent extends SupplierPaymentsEvent {
  final int supplierId;

  const DiscardSupplierDraftEvent({required this.supplierId});

  @override
  List<Object?> get props => [supplierId];
}
