import 'package:punto_venta_app/features/pos/data/datasources/invoice_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/domain/entities/invoice_response.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';

abstract class InvoiceRepository {
  Future<InvoiceResponse> sendInvoice(PrintJob job);
}

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDataSource remote;

  InvoiceRepositoryImpl({required this.remote});

  @override
  Future<InvoiceResponse> sendInvoice(PrintJob job) async {
    final responseModel = await remote.sendInvoice(job);
    return responseModel.toEntity();
  }
}