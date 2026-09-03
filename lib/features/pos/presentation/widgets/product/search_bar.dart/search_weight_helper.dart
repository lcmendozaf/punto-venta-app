import 'package:punto_venta_app/features/pos/domain/entities/product.dart';

class WeightBarcodeResult {
  final Product product;
  final double weightKg;
  final double calculatedUnitPrice;

  WeightBarcodeResult({
    required this.product,
    required this.weightKg,
    required this.calculatedUnitPrice,
  });

  bool get hasEmbeddedWeight => weightKg > 0;
}

/// EAN-13 de balanza: prefijo 20/21, PLU en [2..7), peso en gramos en [7..12).
WeightBarcodeResult? parseWeightBarcode(String code, List<Product> products) {
  if (!(code.length == 13 &&
      (code.startsWith('20') || code.startsWith('21')))) {
    return null;
  }

  final weightString = code.substring(7, 12);
  final codeString = code.substring(2, 7);
  final weightInt = int.tryParse(weightString) ?? 0;
  final weightKg = weightInt / 1000.0;

  final found = products.cast<Product?>().firstWhere(
    (p) {
      final pcode = p?.code ?? '';
      if (pcode == codeString) return true;
      try {
        final idFromCode = int.parse(codeString);
        if (p?.id == idFromCode) return true;
      } catch (_) {}
      if (pcode.endsWith(codeString)) return true;
      return false;
    },
    orElse: () => null,
  );

  if (found == null) return null;

  return WeightBarcodeResult(
    product: found,
    weightKg: weightKg,
    calculatedUnitPrice: calculateWeightedLineTotal(found, weightKg),
  );
}

bool isProductWeighted(Product product) {
  return product.isWeighted.toUpperCase() == 'S';
}

/// Precio de lista se trata como $/kg cuando el producto tiene netWeight configurado.
double calculateWeightedLineTotal(Product product, double weightKg) {
  final pricePerKg = product.netWeight > 0 ? (product.price ?? 0.0) : 0.0;
  return pricePerKg * weightKg;
}
