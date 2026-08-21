import 'package:punto_venta_app/features/pos/data/models/pending_collectors_detail_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pending_collectors_response_model.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/settlements_repository.dart';

class GetSettlementsUsecase {
  final SettlementsRepository repository;

  GetSettlementsUsecase(this.repository);

  Future<List<PendingCollectorsResponseModel>>
      getAllSettlementsPendingCollectors(String date) async {
    return await repository.fetchPendingCollectors(date);
  }

  Future<PendingCollectorsDetailResponseModel> getPendingCollectorDetail(
      String collectorId, String date) async {
    return await repository.getPendingCollectorDetail(collectorId, date);
  }
}
