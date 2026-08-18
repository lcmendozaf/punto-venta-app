import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/features/pos/data/models/barcode_model.dart';
import '../../domain/entities/product.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
class ProductModel with _$ProductModel {
  const ProductModel._();

  const factory ProductModel({
    @JsonKey(name: 'id') int? id,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'fractional') int? fractional,
    @JsonKey(name: 'stock') int? stock,
    @JsonKey(name: 'supplier_id') int? supplierId,
    @JsonKey(name: 'vat') double? vat,
    @JsonKey(name: 'vat_perception') double? vatPerception,
    @JsonKey(name: 'internal_tax') double? internalTax,
    @JsonKey(name: 'internal_tax_rate') double? internalTaxRate,
    @JsonKey(name: 'is_weighted') String? isWeighted,
    @JsonKey(name: 'net_weight') double? netWeight,
    @JsonKey(name: 'category_id') String? categoryId,
    @JsonKey(name: 'suspended_for_sale') String? suspendedForSale,
    @JsonKey(name: 'suspended_for_purchase') String? suspendedForPurchase,
    @JsonKey(name: 'is_active') String? isActive,
    @JsonKey(name: 'category_description') String? categoryDescription,
    @JsonKey(name: 'purchase_price', fromJson: _doubleFromJson) double? purchasePrice,

    // Se agregan despues con un copywith (depende de la lista de precios actual)
    @JsonKey(name: 'regular_price', fromJson: _doubleFromJson)
    double?
        regularPrice, // precio anterior (solo mostrar tachado si hay oferta)
    @JsonKey(name: 'price', fromJson: _doubleFromJson)
    double? price, // precio actual (siempre mostrar este)
    @JsonKey(name: 'is_on_sale', fromJson: _intFromJson) int? isOnSale, // 1 si está en oferta, 0 si no
    @JsonKey(name: 'barcodes') List<BarcodeModel>? barcodes,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Product toEntity() {
    double? priceValue;
    try {
      if (price != null) {
        priceValue = price;
      }
    } catch (e) {
      priceValue = null;
    }

    return Product(
      id: id ?? 0,
      description: description ?? '',
      fractional: fractional ?? 0,
      stock: stock ?? 0,
      supplierId: supplierId ?? 0,
      vat: vat ?? 0.0,
      vatPerception: vatPerception,
      internalTax: internalTax ?? 0.0,
      internalTaxRate: internalTaxRate,
      isWeighted: isWeighted ?? '',
      netWeight: netWeight ?? 0.0,
      categoryId: categoryId ?? '',
      suspendedForSale: suspendedForSale ?? 'N',
      suspendedForPurchase: suspendedForPurchase ?? 'N',
      isActive: isActive ?? 'S',
      categoryDescription: categoryDescription ?? '',
      price: priceValue,
      regularPrice: regularPrice,
      isOnSale: (isOnSale ?? 0) == 1,
      barcodes: barcodes,
      purchasePrice: purchasePrice,
    );
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      description: product.description,
      fractional: product.fractional,
      stock: product.stock,
      supplierId: product.supplierId,
      vat: product.vat,
      vatPerception: product.vatPerception,
      internalTax: product.internalTax,
      internalTaxRate: product.internalTaxRate,
      isWeighted: product.isWeighted,
      netWeight: product.netWeight,
      categoryId: product.categoryId,
      suspendedForSale: product.suspendedForSale,
      suspendedForPurchase: product.suspendedForPurchase,
      isActive: product.isActive,
      categoryDescription: product.categoryDescription,
      price: product.price,
      isOnSale: product.isOnSale ? 1 : 0,
      barcodes: product.barcodes,
      purchasePrice: product.purchasePrice,
    );
  }
}

double? _doubleFromJson(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) {
    if (val == '-' || val == 'null' || val.trim().isEmpty) return null;
    return double.tryParse(val);
  }
  return null;
}

int? _intFromJson(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toInt();
  if (val is String) {
    return int.tryParse(val);
  }
  return null;
}
