import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/features/pos/data/models/suppliers_models/supplier_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/suppliers_models/supplier_payment_request.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

part 'supplier_remote_datasource.g.dart';

@RestApi()
abstract class SupplierService {
  factory SupplierService(Dio dio, {String baseUrl}) = _SupplierService;

  @GET('/suppliers/')
  Future<List<SupplierResponseModel>> getSuppliers(
      {@Query('skip') int skip = 0, @Query('limit') int limit = 10000});

  @POST('/suppliers/reception/')
  Future<void> makePayment(@Body() SupplierPaymentRequest request);
}

abstract class SupplierRemoteDataSource {
  Future<List<SupplierResponseModel>> getSuppliers();
  Future<void> makePayment(SupplierPaymentRequest request);
}

class SupplierRemoteDataSourceImpl implements SupplierRemoteDataSource {
  SupplierService get _apiService => di.sl<SupplierService>();

  SupplierRemoteDataSourceImpl();

  @override
  Future<List<SupplierResponseModel>> getSuppliers() async {
    try {
      return await _apiService.getSuppliers();
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener proveedores'));
    }
  }

  @override
  Future<void> makePayment(SupplierPaymentRequest request) async {
    try {
      await _apiService.makePayment(request);
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al registrar el pago al proveedor'));
    }
  }
}
