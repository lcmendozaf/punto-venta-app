import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/features/pos/data/models/invoice_payload_model.dart';
import 'package:punto_venta_app/features/pos/data/models/tax_model.dart';
import 'package:punto_venta_app/features/pos/data/models/invoice_response_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/tax_repository.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

part 'invoice_remote_datasource.g.dart';

@RestApi()
abstract class InvoiceService {
  factory InvoiceService(Dio dio, {String baseUrl}) = _InvoiceService;

  @POST('/tickets/')
  Future<dynamic> sendInvoice(@Body() Map<String, dynamic> body);
}

abstract class InvoiceRemoteDataSource {
  Future<InvoiceResponseModel> sendInvoice(PrintJob job);
}

class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  InvoiceService get _apiService => di.sl<InvoiceService>();
  final TaxRepository taxRepository;

  InvoiceRemoteDataSourceImpl({
    required this.taxRepository,
  });

  @override
  Future<InvoiceResponseModel> sendInvoice(PrintJob job) async {
    List<TaxModel> taxes = [];
    try {
      taxes = await taxRepository.getTaxes();
    } catch (e) {
      print(' [INVOICE] Error al obtener taxes, usando lista vacía: $e');
    }

    final payload = InvoicePayload.fromPrintJob(job, taxes).toJson();

    try {
      final Map<String, dynamic> data = await _apiService.sendInvoice(payload);

      return InvoiceResponseModel.fromJson(data, defaultTicketId: job.ticketId);
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al enviar factura'));
    }
  }
}
