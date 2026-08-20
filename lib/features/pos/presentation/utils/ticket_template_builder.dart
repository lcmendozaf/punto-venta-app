import 'package:punto_venta_app/core/constants/ticket_template_types.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/templates/base_ticket_template.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/templates/standard_ticket_template.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/templates/black_market_ticket_template.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/templates/white_market_ticket_template.dart';

/// Factory que construye tickets usando el template apropiado
class TicketTemplateBuilder {
  final PrintJob printJob;

  TicketTemplateBuilder({
    required this.printJob,
  });

  /// Construye el contenido del ticket en formato de lista de comandos
  /// según el template configurado
  Future<List<TicketCommand>> build() async {
    final BaseTicketTemplate template = _getTemplate();
    return await template.build();
  }

  /// Obtiene la instancia del template apropiado según el tipo
  BaseTicketTemplate _getTemplate() {
    switch (printJob.templateType) {
      case TicketTemplateType.standard:
        return StandardTicketTemplate(printJob: printJob);
      case TicketTemplateType.blackMarket:
        return BlackMarketTicketTemplate(printJob: printJob);
      case TicketTemplateType.whiteMarket:
        return WhiteMarketTicketTemplate(printJob: printJob);
    }
  }
}
