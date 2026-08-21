import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/features/pos/data/models/pending_collectors_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pending_collectors_detail_response_model.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

part 'settlements_remote_datasource.g.dart';

@RestApi()
abstract class SettlementsService {
  factory SettlementsService(Dio dio, {String baseUrl}) = _SettlementsService;

  @GET('/settlements/pending/collectors')
  Future<List<PendingCollectorsResponseModel>> getPendingCollectors(
      {@Query('date') required String date});

  @GET('/settlements/pending/{collector_id}')
  Future<PendingCollectorsDetailResponseModel> getPendingCollectorDetail(
      {@Path('collector_id') required String collectorId,
        @Query('date') required String date
      });
}

abstract class SettlementsRemoteDataSource {
  Future<List<PendingCollectorsResponseModel>> getPendingCollectors(
      {required String date});
  Future<PendingCollectorsDetailResponseModel> getPendingCollectorDetail(
      {required String collectorId, required String date});
}

class SettlementsRemoteDataSourceImpl implements SettlementsRemoteDataSource {
  SettlementsService get _apiService => di.sl<SettlementsService>();

  SettlementsRemoteDataSourceImpl();

  @override
  Future<List<PendingCollectorsResponseModel>> getPendingCollectors(
      {required String date}) async {
    try {
      return await _apiService.getPendingCollectors(date: date);
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener cobradores pendientes'));
    }
  }

  @override
  Future<PendingCollectorsDetailResponseModel> getPendingCollectorDetail(
      {required String collectorId, required String date}) async {
    try {
      return await _apiService.getPendingCollectorDetail(
          collectorId: collectorId,
      date: date);
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener detalle de cobrador'));
    }
  }
}
