import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/features/pos/data/models/refund_reason_model.dart';
import 'package:punto_venta_app/features/pos/data/models/cash_refund_request_model.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

part 'refunds_remote_datasource.g.dart';

@RestApi()
abstract class RefundsService {
  factory RefundsService(Dio dio, {String baseUrl}) = _RefundsService;

  @GET('/refunds/reasons')
  Future<List<RefundReasonModel>> getRefundReasons();

  @POST('/refunds/cash')
  Future<dynamic> processCashRefund(@Body() Map<String, dynamic> body);
}

abstract class RefundsRemoteDataSource {
  Future<List<RefundReasonModel>> getRefundReasons();
  Future<void> processCashRefund(CashRefundRequestModel request);
}

class RefundsRemoteDataSourceImpl implements RefundsRemoteDataSource {
  RefundsService get _apiService => di.sl<RefundsService>();

  RefundsRemoteDataSourceImpl();

  @override
  Future<List<RefundReasonModel>> getRefundReasons() async {
    try {
      return await _apiService.getRefundReasons();
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener motivos de reintegro'));
    }
  }

  @override
  Future<void> processCashRefund(CashRefundRequestModel request) async {
    await _apiService.processCashRefund(request.toJson());
    try {} catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al procesar reintegro de dinero'));
    }
  }
}
