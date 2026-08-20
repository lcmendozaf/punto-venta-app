import 'package:punto_venta_app/core/constants/ticket_template_types.dart';
import 'package:punto_venta_app/features/pos/data/datasources/completed_orders_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/completed_orders_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/branch_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/vat_category_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/client_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/tax_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/completed_order_model.dart';
import 'package:punto_venta_app/features/pos/data/models/invoice_payload_model.dart';
import 'package:punto_venta_app/features/pos/data/models/product_model.dart';
import 'package:punto_venta_app/features/pos/data/models/vat_category_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/completed_orders_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/payment_method_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/tax_repository.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/ticket_template_resolver.dart';

class CompletedOrdersRepositoryImpl implements CompletedOrdersRepository {
  final CompletedOrdersLocalDataSource localDataSource;
  final CompletedOrdersRemoteDataSource? remoteDataSource;
  final BranchLocalDataSource branchLocalDataSource;
  final VatCategoryLocalDataSource vatCategoryLocalDataSource;
  final ClientLocalDataSource clientLocalDataSource;
  final TaxLocalDataSource taxLocalDataSource;
  final PaymentMethodRepository paymentMethodRepository;
  final TaxRepository taxRepository;

  CompletedOrdersRepositoryImpl({
    required this.localDataSource,
    this.remoteDataSource,
    required this.branchLocalDataSource,
    required this.vatCategoryLocalDataSource,
    required this.clientLocalDataSource,
    required this.taxLocalDataSource,
    required this.paymentMethodRepository,
    required this.taxRepository,
  });

  @override
  Future<List<CompletedOrder>> getCompletedOrders() async {
    try {
      final orderModels = await localDataSource.getCompletedOrders();
      final orders = orderModels.map((model) => model.toEntity()).toList();
      orders.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return orders;
    } catch (e) {
      throw Exception('Error al obtener órdenes completadas: $e');
    }
  }

  @override
  Future<void> saveCompletedOrder(CompletedOrder order) async {
    try {
      final orderModel = CompletedOrderModel.fromEntity(order);
      await localDataSource.saveCompletedOrder(orderModel);
    } catch (e) {
      throw Exception('Error al guardar orden completada: $e');
    }
  }

  @override
  Future<List<CompletedOrder>> getOrdersByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final orderModels =
          await localDataSource.getOrdersByDateRange(startDate, endDate);
      final orders = orderModels.map((model) => model.toEntity()).toList();
      orders.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return orders;
    } catch (e) {
      throw Exception('Error al obtener órdenes por rango de fechas: $e');
    }
  }

  @override
  Future<CompletedOrder?> getOrderById(String orderId) async {
    try {
      final orderModel = await localDataSource.getOrderById(orderId);
      return orderModel?.toEntity();
    } catch (e) {
      throw Exception('Error al obtener orden por ID: $e');
    }
  }

  @override
  Future<double> getTotalSalesByDate(DateTime date) async {
    try {
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final orders = await getOrdersByDateRange(startDate, endDate);

      double totalSales = 0.0;
      for (final order in orders) {
        totalSales += order.total;
      }

      return totalSales;
    } catch (e) {
      throw Exception('Error al calcular ventas totales por fecha: $e');
    }
  }

  // Remote methods  // TODO: cambiar el payload (al modelo de TicketResponseModel)
  @override
  Future<List<CompletedOrder>> getCompletedOrdersFromRemote(
      {int skip = 0, int limit = 10, String? typeCode}) async {
    if (remoteDataSource == null) {
      throw Exception('Remote data source not available');
    }

    try {
      final invoicePayloads = await remoteDataSource!
          .getAllTickets(skip: skip, limit: limit, typeCode: typeCode);

      final orders = await Future.wait(invoicePayloads
          .map((payload) => _convertInvoicePayloadToCompletedOrder(payload)));

      return orders;
    } catch (e) {
      throw Exception('Error al obtener órdenes desde el servidor: $e');
    }
  }

  @override
  Future<List<CompletedOrder>> getOrdersByDateRangeFromRemote(
      DateTime startDate,
      {DateTime? endDate,
      int skip = 0,
      int limit = 10,
      String? typeCode}) async {
    if (remoteDataSource == null) {
      throw Exception('Remote data source not available');
    }

    try {
      final invoicePayloads = await remoteDataSource!.getTicketsByDateRange(
          startDate,
          endDate: endDate,
          skip: skip,
          limit: limit,
          typeCode: typeCode);
      final orders = await Future.wait(invoicePayloads
          .map((payload) => _convertInvoicePayloadToCompletedOrder(payload)));

      return orders;
    } catch (e) {
      throw Exception(
          'Error al obtener órdenes por rango de fechas desde el servidor: $e');
    }
  }

  @override
  Future<CompletedOrder?> getOrderByIdFromRemote(String orderId) async {
    if (remoteDataSource == null) {
      throw Exception('Remote data source not available');
    }

    try {
      final payload = await remoteDataSource!.getTicketById(orderId);
      if (payload == null) return null;
      return await _convertInvoicePayloadToCompletedOrder(payload);
    } catch (e) {
      throw Exception('Error al obtener orden por ID desde el servidor: $e');
    }
  }

  // Helper method to convert InvoicePayload to CompletedOrder
  Future<CompletedOrder> _convertInvoicePayloadToCompletedOrder(
      InvoicePayload ticket) async {
    bool? branchAfipAvailable;
    bool? clientTaxDetails;

    // Obtener información de la sucursal
    try {
      final branch = await branchLocalDataSource.getBranchById(ticket.branchId);
      branchAfipAvailable = branch?.afipAvailable;
    } catch (e) {
      print('Error obteniendo branch: $e');
    }

    // Obtener información del cliente
    Client? client;
    if (ticket.client != null && ticket.client!['id'] != null) {
      try {
        final clientId = ticket.client!['id'].toString();
        client = await clientLocalDataSource.getClientById(clientId);

        if (client != null && client.vatCategoryId != null) {
          try {
            final clientVatCategoryId = client.vatCategoryId!;
            final vatCategories =
                await vatCategoryLocalDataSource.getCachedVatCategories();
            final vatCategory = vatCategories?.firstWhere(
              (cat) => cat.id == clientVatCategoryId,
              orElse: () => const VatCategoryModel(id: 0),
            );
            clientTaxDetails = vatCategory?.taxDetails;
          } catch (e) {
            print('Error obteniendo vatCategory: $e');
          }
        }

        client ??= Client(
          id: ticket.client!['id'],
          name: ticket.client!['name'] as String? ?? '',
          document: ticket.client!['document'] as String?,
          phone: ticket.client!['phone'] as String?,
          email: ticket.client!['email'] as String?,
          address: ticket.client!['address'] as String?,
        );
      } catch (e) {
        print('Error obteniendo client: $e');
        try {
          client = Client(
            id: ticket.client!['id'],
            name: ticket.client!['name'] as String? ?? '',
            document: ticket.client!['document'] as String?,
            phone: ticket.client!['phone'] as String?,
            email: ticket.client!['email'] as String?,
            address: ticket.client!['address'] as String?,
          );
        } catch (e2) {
          print('Error creating client from ticket: $e2');
        }
      }
    }

    // Obtener tipo de template
    final templateType = TicketTemplateResolver.resolveTemplate(
      branchAfipAvailable: branchAfipAvailable,
    );

    // Validar si el template es whiteMarket y no tiene detalles fiscales
    final hasClient = client != null;
    if (templateType == TicketTemplateType.whiteMarket &&
        hasClient &&
        clientTaxDetails == null) {
      clientTaxDetails = true;
    }

    // Determinar si el template muestra precios con impuestos
    final showPricesWithTax = TicketTemplateResolver.shouldShowPricesWithTax(
      templateType: templateType,
      clientTaxDetails: clientTaxDetails,
    );

    // Determinar si el template muestra subtotal e impuestos
    final showSubtotalAndTax = TicketTemplateResolver.shouldShowSubtotalAndTax(
      templateType: templateType,
      clientTaxDetails: clientTaxDetails,
      hasClient: hasClient,
    );

    // Convert log items to CartItems
    final List<CartItem> items = ticket.logItems.map((itemJson) {
      // Create a CartItemModel from the JSON
      final productId = itemJson['productId'] as int;
      final productName = itemJson['productName'] as String;
      final quantity = itemJson['quantity'] as int;
      final unitPriceNet = (itemJson['unitPrice'] as num).toDouble();
      final isWeighted = itemJson['is_weighted'] == 'S';
      final weightKg =
          isWeighted ? (itemJson['weight'] as num?)?.toDouble() : null;
      final netWeight =
          isWeighted ? (itemJson['net_weight'] as num?)?.toDouble() : null;

      // Extract tax percentage from taxes array
      double taxPercentage = 0.0;
      if (itemJson['taxes'] != null && (itemJson['taxes'] as List).isNotEmpty) {
        final firstTax = (itemJson['taxes'] as List)[0];
        taxPercentage = (firstTax['percentage'] as num?)?.toDouble() ?? 0.0;
      }

      // Precio Neto
      final finalPrice = unitPriceNet;

      // Create product using ProductModel and convert to entity
      final productModel = ProductModel(
        id: productId,
        description: productName,
        price: finalPrice,
        vat: taxPercentage,
        netWeight: netWeight,
        stock: 0,
        supplierId: 0,
        internalTax: 0,
        isWeighted: isWeighted ? 'S' : 'N',
        categoryId: '',
        suspendedForSale: 'N',
        suspendedForPurchase: 'N',
        isActive: 'S',
        categoryDescription: '',
        isOnSale: 0,
      );

      final cartItem = CartItem(
        product: productModel.toEntity(),
        quantity: quantity,
        iva: taxPercentage,
        isWeighted: isWeighted,
        weightKg: weightKg,
        pricePerKg: isWeighted ? finalPrice : null,
      );

      return cartItem;
    }).toList();

    // Convert log items to CartLogEntry
    final List<CartLogEntry> logs = ticket.logItems.map((itemJson) {
      final productId = itemJson['productId'] as int;
      final productName = itemJson['productName'] as String;
      final quantity = itemJson['quantity'] as int;
      final unitPriceNet = (itemJson['unitPrice'] as num).toDouble();
      final isWeighted = itemJson['is_weighted'] == 'S';
      final weightKg =
          isWeighted ? (itemJson['weight'] as num?)?.toDouble() : null;
      final netWeight =
          isWeighted ? (itemJson['net_weight'] as num?)?.toDouble() : null;
      double taxPercentage = 0.0;
      if (itemJson['taxes'] != null && (itemJson['taxes'] as List).isNotEmpty) {
        final firstTax = (itemJson['taxes'] as List)[0];
        taxPercentage = (firstTax['percentage'] as num?)?.toDouble() ?? 0.0;
      }

      // Precio neto
      final finalPrice = unitPriceNet;

      final productModel = ProductModel(
        id: productId,
        description: productName,
        price: finalPrice,
        vat: taxPercentage,
        netWeight: netWeight,
        stock: 0,
        supplierId: 0,
        internalTax: 0,
        isWeighted: isWeighted ? 'S' : 'N',
        categoryId: '',
        suspendedForSale: 'N',
        suspendedForPurchase: 'N',
        isActive: 'S',
        categoryDescription: '',
        isOnSale: 0,
      );

      final cartItem = CartItem(
        product: productModel.toEntity(),
        quantity: quantity,
        iva: taxPercentage,
        isWeighted: isWeighted,
        weightKg: weightKg,
        pricePerKg: isWeighted ? finalPrice : null,
      );

      return CartLogEntry(
        id: itemJson['id'] as String,
        timestamp: DateTime.parse(ticket.timestamp),
        item: cartItem,
        type: CartActionType.add, // Default to add
      );
    }).toList();

    var taxesFromBackend = await taxLocalDataSource.getCachedTaxes() ?? [];
    if (taxesFromBackend.isEmpty) {
      try {
        taxesFromBackend = await taxRepository.getTaxes();
      } catch (e) {
        print(
            'Error fetching taxes from remote in completed orders repository mapping: $e');
      }
    }

    final ivaTaxIds = <int>{};
    final iibbTaxIds = <int>{};
    final vatPerceptionTaxIds = <int>{};
    final internalTaxIds = <int>{};

    for (var tax in taxesFromBackend) {
      final description = (tax.description ?? '').toLowerCase();

      if (description.contains('iva') && !description.contains('percep')) {
        // IVA 0%, 10.5%, 21%, 27%
        ivaTaxIds.add(tax.id);
      } else if (description.contains('iibb')) {
        // Percep.IIBB
        iibbTaxIds.add(tax.id);
      } else if (description.contains('percep') &&
          description.contains('iva')) {
        // Percep.IVA
        vatPerceptionTaxIds.add(tax.id);
      } else if (description.contains('impint')) {
        // Impuesto Interno
        internalTaxIds.add(tax.id);
      }
    }

    // Parse totalTax array del ticket usando los IDs
    double iibbTax = 0.0;
    double? iibbTaxPercentage;
    double vatPerception = 0.0;
    Map<String, double>? vatPerceptionByRate;
    double internalTax = 0.0;
    double? internalTaxRate;
    double ivaTax = 0.0;

    for (var tax in ticket.totalTax) {
      final taxId = tax.id;
      final amount = tax.amount ?? 0.0;
      final percentage = tax.percentage ?? 0.0;
      final description = (tax.description ?? '').toLowerCase();

      bool isIva = false;
      bool isIibb = false;
      bool isVatPercep = false;
      bool isInternal = false;

      // 1. Clasificar por descripción si viene disponible
      if (description.isNotEmpty) {
        if (description.contains('iva') && !description.contains('percep')) {
          isIva = true;
        } else if (description.contains('iibb')) {
          isIibb = true;
        } else if (description.contains('percep') &&
            description.contains('iva')) {
          isVatPercep = true;
        } else if (description.contains('impint')) {
          isInternal = true;
        }
      }

      // 2. Si no pudimos clasificar por descripción, usar el ID contra las tasas del backend
      if (!isIva && !isIibb && !isVatPercep && !isInternal) {
        if (ivaTaxIds.contains(taxId)) {
          isIva = true;
        } else if (iibbTaxIds.contains(taxId)) {
          isIibb = true;
        } else if (vatPerceptionTaxIds.contains(taxId)) {
          isVatPercep = true;
        } else if (internalTaxIds.contains(taxId)) {
          isInternal = true;
        }
      }

      if (isIva) {
        ivaTax += amount;
      } else if (isIibb) {
        iibbTax += amount;
        iibbTaxPercentage = percentage > 0 ? percentage : null;
      } else if (isVatPercep) {
        vatPerception += amount;
        if (percentage > 0) {
          vatPerceptionByRate ??= {};
          vatPerceptionByRate[percentage.toString()] = amount;
        }
      } else if (isInternal) {
        internalTax += amount;
        internalTaxRate = percentage > 0 ? percentage : null;
      }
    }

    // Calculate total items
    final totalItems = items.fold(0, (sum, item) => sum + item.quantity);

    List<PaymentMethod> paymentMethods = [];
    try {
      final allMethods = await paymentMethodRepository.fetchPaymentMethods();
      paymentMethods = ticket.paymentMethods.map((reqPm) {
        final matched = allMethods.firstWhere(
          (m) => m.id == reqPm.id,
          orElse: () => PaymentMethod(
            id: reqPm.id ?? 0,
            description: 'Método ${reqPm.id}',
            shortDescription: 'MET-${reqPm.id}',
            deleteAt: '',
          ),
        );
        return matched.copyWith(
          amount: reqPm.amount,
          details: reqPm.details != null
              ? PaymentMethodDetails(
                  accountOwner: reqPm.details!.accountOwner,
                  bankId: reqPm.details!.bankId,
                  checkNumber: reqPm.details!.checkNumber,
                  transferId: reqPm.details!.transferId,
                  verificationId: reqPm.details!.verificationId,
                )
              : null,
        );
      }).toList();
    } catch (e) {
      print(
          'Error resolving payment methods in completed orders repository: $e');
      paymentMethods = ticket.paymentMethods.map((reqPm) {
        return PaymentMethod(
          id: reqPm.id ?? 0,
          description: 'Método ${reqPm.id}',
          shortDescription: 'MET-${reqPm.id}',
          deleteAt: '',
          amount: reqPm.amount,
          details: reqPm.details != null
              ? PaymentMethodDetails(
                  accountOwner: reqPm.details!.accountOwner,
                  bankId: reqPm.details!.bankId,
                  checkNumber: reqPm.details!.checkNumber,
                  transferId: reqPm.details!.transferId,
                  verificationId: reqPm.details!.verificationId,
                )
              : null,
        );
      }).toList();
    }

    PaymentMethod? paymentMethod =
        paymentMethods.isNotEmpty ? paymentMethods.first : null;

    // Generate order number from ticketId or timestamp
    final orderNumber = ticket.ticketId ??
        'ORD-${DateTime.parse(ticket.timestamp).millisecondsSinceEpoch}';

    return CompletedOrder(
      id: ticket.ticketId ??
          DateTime.parse(ticket.timestamp).millisecondsSinceEpoch.toString(),
      orderNumber: orderNumber,
      items: items,
      logs: logs,
      total: ticket.total,
      completedAt: DateTime.parse(ticket.timestamp),
      clientName: ticket.client?['name'] as String?,
      client: client,
      cashierName: 'Cajero ${ticket.cashier ?? ""}',
      cashierId: ticket.cashier,
      paymentMethod: paymentMethod,
      paymentMethods: paymentMethods,
      totalTax: ivaTax,
      totalItems: totalItems,
      showSubtotalAndTax: showSubtotalAndTax,
      showPricesWithTax: showPricesWithTax,
      typeCode: ticket.typeCode,
      description: ticket.description,
      templateType: templateType,
      iibbTax: iibbTax,
      iibbTaxPercentage: iibbTaxPercentage,
      vatPerception: vatPerception,
      vatPerceptionByRate: vatPerceptionByRate,
      internalTax: internalTax,
      internalTaxRate: internalTaxRate,
      branchNumber: ticket.branchNumber,
      branchId: ticket.branchId,
      externalId: ticket.externalId,
      isAnnulled: ticket.isAnnulled,
      cae: ticket.cae,
      caeDueDate: ticket.caeDueDate,
      caeQrCode: ticket.caeQrCode,
    );
  }

  @override
  Future<CompletedOrder> fromInvoicePayload(InvoicePayload payload) async {
    return _convertInvoicePayloadToCompletedOrder(payload);
  }

  Future<PaymentMethod> _resolvePaymentMethod(int paymentMethodId) async {
    try {
      final catalog = await paymentMethodRepository.fetchPaymentMethods();
      return catalog.firstWhere(
        (pm) => pm.id == paymentMethodId,
        orElse: () => PaymentMethod(
          id: paymentMethodId,
          description: '',
          shortDescription: '',
          deleteAt: '',
        ),
      );
    } catch (_) {
      return PaymentMethod(
        id: paymentMethodId,
        description: '',
        shortDescription: '',
        deleteAt: '',
      );
    }
  }
}
