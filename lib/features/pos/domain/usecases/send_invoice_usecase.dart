import 'package:punto_venta_app/features/pos/data/repositories/invoice_repository_impl.dart';
import 'package:punto_venta_app/features/pos/domain/entities/invoice_response.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';

class SendInvoiceUseCase {
  final InvoiceRepository repository;

  SendInvoiceUseCase(this.repository);

  Future<InvoiceResponse> call(PrintJob job) async {
    return await repository.sendInvoice(job);
  } 
}