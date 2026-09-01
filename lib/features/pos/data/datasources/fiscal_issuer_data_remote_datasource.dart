import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import '../models/fiscal_issuer_data_model.dart';

part 'fiscal_issuer_data_remote_datasource.g.dart';

@RestApi()
abstract class FiscalIssuerDataService {
  factory FiscalIssuerDataService(Dio dio, {String baseUrl}) =
      _FiscalIssuerDataService;

  @GET('configuration/fiscal-data')
  Future<FiscalIssuerDataModel> getFiscalIssuerData();
}

abstract class FiscalIssuerDataRemoteDatasource {
  Future<FiscalIssuerDataModel> getFiscalIssuerData();
}

class FiscalIssuerDataRemoteDatasourceImpl
    implements FiscalIssuerDataRemoteDatasource {
  FiscalIssuerDataService get _apiService => di.sl<FiscalIssuerDataService>();

  FiscalIssuerDataRemoteDatasourceImpl();

  @override
  Future<FiscalIssuerDataModel> getFiscalIssuerData() async {
    try {
      final response = await _apiService.getFiscalIssuerData();

      print(response.toString());

      return response;
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener datos fiscales del emisor'));
    }
  }
}
