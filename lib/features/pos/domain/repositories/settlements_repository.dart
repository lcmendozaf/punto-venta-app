import 'package:punto_venta_app/features/pos/data/models/pending_collectors_detail_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pending_collectors_response_model.dart';

abstract class SettlementsRepository {
  Future<List<PendingCollectorsResponseModel>> fetchPendingCollectors(String date);
  Future<PendingCollectorsDetailResponseModel> getPendingCollectorDetail(
      String collectorId, String date);
}
