import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/data/models/suppliers_models/supplier_payment_request.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_suppliers_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/make_supplier_payment_usecase.dart';
import 'supplier_payments_event.dart';
import 'supplier_payments_state.dart';

class SupplierPaymentsBloc
    extends Bloc<SupplierPaymentsEvent, SupplierPaymentsState> {
  final GetSuppliersUsecase getSuppliers;
  final MakeSupplierPaymentUsecase makePayment;

  SupplierPaymentsBloc({
    required this.getSuppliers,
    required this.makePayment,
  }) : super(SupplierPaymentsState.initial()) {
    on<LoadSuppliersEvent>(_onLoadSuppliers);
    on<SelectSupplierEvent>(_onSelectSupplier);
    on<AddProductToPaymentEvent>(_onAddProduct);
    on<RemoveProductFromPaymentEvent>(_onRemoveProduct);
    on<UpdateProductQuantityEvent>(_onUpdateQuantity);
    on<UpdatePaymentAmountsEvent>(_onUpdateAmounts);
    on<UpdateDocumentNumbersEvent>(_onUpdateDocuments);
    on<SubmitSupplierPaymentEvent>(_onSubmitPayment);
    on<ResetSupplierPaymentFormEvent>(_onResetForm);
    on<SaveSupplierDraftEvent>(_onSaveDraft);
    on<DiscardSupplierDraftEvent>(_onDiscardDraft);
  }

  Future<void> _onLoadSuppliers(
      LoadSuppliersEvent event, Emitter<SupplierPaymentsState> emit) async {
    emit(state.copyWith(status: SupplierPaymentStatus.loading));
    try {
      final list = await getSuppliers();
      emit(state.copyWith(
          status: SupplierPaymentStatus.initial, suppliers: list));
    } catch (e) {
      emit(state.copyWith(
          status: SupplierPaymentStatus.error, errorMessage: e.toString()));
    }
  }

  void _onSelectSupplier(
      SelectSupplierEvent event, Emitter<SupplierPaymentsState> emit) {
    if (event.supplier == null) {
      emit(state.copyWith(
        selectedSupplier: null,
        clearSelectedSupplier: true,
        items: const [],
        totalPaid: 0.0,
        total: 0.0,
        clearDocuments: true,
        status: SupplierPaymentStatus.initial,
      ));
      return;
    }

    final draft = state.drafts[event.supplier!.id];
    if (draft != null) {
      emit(state.copyWith(
        selectedSupplier: event.supplier,
        items: draft.items,
        totalPaid: draft.totalPaid,
        total: draft.total,
        remitoNumber: draft.remitoNumber,
        supplierTicket: draft.providerTicket,
        status: SupplierPaymentStatus.initial,
      ));
    } else {
      emit(state.copyWith(
        selectedSupplier: event.supplier,
        items: const [],
        totalPaid: 0.0,
        total: 0.0,
        clearDocuments: true,
        status: SupplierPaymentStatus.initial,
      ));
    }
  }

  void _onAddProduct(
      AddProductToPaymentEvent event, Emitter<SupplierPaymentsState> emit) {
    final existingIndex =
        state.items.indexWhere((i) => i.product.id == event.product.id);
    List<SelectedPaymentItem> updatedItems;
    final quantityToAdd = event.quantity ?? 1.0;
    if (existingIndex >= 0) {
      final currentItem = state.items[existingIndex];
      updatedItems = List.from(state.items)
        ..[existingIndex] = currentItem.copyWith(
            quantity: currentItem.quantity + quantityToAdd);
    } else {
      updatedItems = List.from(state.items)
        ..add(SelectedPaymentItem(
            product: event.product, quantity: quantityToAdd));
    }

    final newTotal =
        updatedItems.fold<double>(0, (sum, item) => sum + item.subtotal);

    emit(state.copyWith(
      items: updatedItems,
      total: newTotal,
      totalPaid: newTotal, // Default totalPaid to computed total
    ));
  }

  void _onRemoveProduct(RemoveProductFromPaymentEvent event,
      Emitter<SupplierPaymentsState> emit) {
    final updatedItems =
        state.items.where((i) => i.product.id != event.productId).toList();
    final newTotal =
        updatedItems.fold<double>(0, (sum, item) => sum + item.subtotal);
    emit(state.copyWith(
      items: updatedItems,
      total: newTotal,
      totalPaid: newTotal,
    ));
  }

  void _onUpdateQuantity(
      UpdateProductQuantityEvent event, Emitter<SupplierPaymentsState> emit) {
    final existingIndex =
        state.items.indexWhere((i) => i.product.id == event.productId);
    if (existingIndex >= 0) {
      final updatedItems = List<SelectedPaymentItem>.from(state.items);
      if (event.quantity <= 0) {
        updatedItems.removeAt(existingIndex);
      } else {
        updatedItems[existingIndex] =
            updatedItems[existingIndex].copyWith(quantity: event.quantity);
      }
      final newTotal =
          updatedItems.fold<double>(0, (sum, item) => sum + item.subtotal);
      emit(state.copyWith(
        items: updatedItems,
        total: newTotal,
        totalPaid: newTotal,
      ));
    }
  }

  void _onUpdateAmounts(
      UpdatePaymentAmountsEvent event, Emitter<SupplierPaymentsState> emit) {
    emit(state.copyWith(
      totalPaid: event.totalPaid,
      total: event.totalCharged,
    ));
  }

  void _onUpdateDocuments(
      UpdateDocumentNumbersEvent event, Emitter<SupplierPaymentsState> emit) {
    emit(state.copyWith(
      remitoNumber: event.remitoNumber,
      supplierTicket: event.supplierTicket,
    ));
  }

  Future<void> _onSubmitPayment(SubmitSupplierPaymentEvent event,
      Emitter<SupplierPaymentsState> emit) async {
    if (state.selectedSupplier == null) return;

    emit(state.copyWith(status: SupplierPaymentStatus.submitting));

    try {
      final paymentItems = state.items
          .map((i) => ItemSupplierRequest(
                itemId: i.product.id,
                quantity: i.quantity.round(),
              ))
          .toList();

      final request = SupplierPaymentRequest(
        userId: event.userId,
        timestamp: DateTime.now(),
        supplierId: state.selectedSupplier!.id,
        items: state.selectedSupplier!.isServiceProvider ? null : paymentItems,
        totalPaid: state.totalPaid,
      );

      await makePayment(request);

      final updatedDrafts = Map<int, SupplierPaymentDraft>.from(state.drafts);
      updatedDrafts.remove(state.selectedSupplier!.id);

      emit(state.copyWith(
        status: SupplierPaymentStatus.success,
        drafts: updatedDrafts,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: SupplierPaymentStatus.error, errorMessage: e.toString()));
    }
  }

  void _onResetForm(ResetSupplierPaymentFormEvent event,
      Emitter<SupplierPaymentsState> emit) {
    emit(state.copyWith(
      clearSelectedSupplier: true,
      items: const [],
      totalPaid: 0.0,
      total: 0.0,
      clearDocuments: true,
      status: SupplierPaymentStatus.initial,
    ));
  }

  void _onSaveDraft(
      SaveSupplierDraftEvent event, Emitter<SupplierPaymentsState> emit) {
    final updatedDrafts = Map<int, SupplierPaymentDraft>.from(state.drafts);
    updatedDrafts[event.supplierId] = SupplierPaymentDraft(
      items: event.items,
      totalPaid: event.totalPaid,
      total: event.total,
      remitoNumber: event.remitoNumber,
      providerTicket: event.supplierTicket,
    );
    emit(state.copyWith(drafts: updatedDrafts));
  }

  void _onDiscardDraft(
      DiscardSupplierDraftEvent event, Emitter<SupplierPaymentsState> emit) {
    final updatedDrafts = Map<int, SupplierPaymentDraft>.from(state.drafts);
    updatedDrafts.remove(event.supplierId);
    emit(state.copyWith(drafts: updatedDrafts));
  }
}
