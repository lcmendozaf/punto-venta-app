import 'package:punto_venta_app/features/pos/domain/entities/fiscal_issuer_data.dart';

abstract class FiscalIssuerDataRepository {
  Future<FiscalIssuerData> getFiscalIssuerData();

  Future<void> clearFiscalIssuerDataCache();
}
