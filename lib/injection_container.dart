import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:punto_venta_app/core/database/database_helper.dart';
import 'package:punto_venta_app/core/network/dio_client.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/auth/data/datasources/google_auth_datasource.dart';
import 'package:punto_venta_app/features/auth/data/datasources/firestore_user_datasource.dart';
import 'package:punto_venta_app/features/auth/data/datasources/user_api_datasource.dart';
import 'package:punto_venta_app/features/auth/data/repositories/auth_repositories_impl.dart';
import 'package:punto_venta_app/features/auth/domain/usecases/authenticate_user_usecase.dart';
import 'package:punto_venta_app/features/auth/domain/usecases/change_chashier_usecase.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:punto_venta_app/features/pos/data/datasources/client_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/client_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_types_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_types_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/tax_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/tax_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/vat_category_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/vat_category_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/fiscal_issuer_data_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/fiscal_issuer_data_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/branch_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/completed_orders_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/completed_orders_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/returns_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/refunds_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/repositories/returns_repository_impl.dart';
import 'package:punto_venta_app/features/pos/data/repositories/refunds_repository_impl.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/returns_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/refunds_repository.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/refunds/refunds_cubit.dart';
import 'package:punto_venta_app/features/pos/data/datasources/invoice_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/ticket_config_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/ticket_config_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/payment_method_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_socket_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/product_local_data_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/saved_orders_local_dasource.dart';
import 'package:punto_venta_app/features/pos/data/repositories/client_repository_impl.dart';
import 'package:punto_venta_app/features/pos/data/repositories/price_list_types_repository_impl.dart';
import 'package:punto_venta_app/features/pos/data/repositories/tax_repository_impl.dart';
import 'package:punto_venta_app/features/pos/data/repositories/vat_category_repository_impl.dart';
import 'package:punto_venta_app/features/pos/data/repositories/fiscal_issuer_data_repository_impl.dart';
import 'package:punto_venta_app/features/pos/data/repositories/completed_orders_repository_impl.dart';
import 'package:punto_venta_app/features/pos/data/repositories/invoice_repository_impl.dart';
import 'package:punto_venta_app/features/pos/data/repositories/ticket_config_repository_impl.dart';
import 'package:punto_venta_app/features/pos/data/repositories/pdv_config_repository_impl.dart';
import 'package:punto_venta_app/features/pos/data/repositories/payment_method_repository_impl.dart';
import 'package:punto_venta_app/features/pos/data/repositories/printer_repository_impl.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/client_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/price_list_types_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/tax_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/vat_category_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/fiscal_issuer_data_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/completed_orders_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/ticket_config_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/pdv_config_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/payment_method_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/printer_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/product_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/saved_orders_repository.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/add_client_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/complete_order_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/delete_client_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_branches_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_price_list_types_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_ticket_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_pdv_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_payment_methods_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_payment_methods_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/save_payment_methods_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_return_reasons_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_returns_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/generate_credit_note_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/process_partial_return_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_clients_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_taxes_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_vat_categories_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_ticket_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_reports_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/load_ordes_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/print_ticket_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/send_invoice_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/update_ticket_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/calculate_order_taxes_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pdv_config/pdv_config_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/price_list_types/price_list_types_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_bloc.dart';
import 'package:punto_venta_app/features/stock/data/datasources/stock_local_datasource.dart';
import 'package:punto_venta_app/features/stock/data/repositories/stock_repository_impl.dart';
import 'package:punto_venta_app/features/stock/domain/repositories/stock_repository.dart';
import 'package:punto_venta_app/features/stock/domain/usecases/add_stock_usecase.dart';
import 'package:punto_venta_app/features/stock/domain/usecases/adjust_stock_usecase.dart';
import 'package:punto_venta_app/features/stock/domain/usecases/create_product_usecase.dart';
import 'package:punto_venta_app/features/stock/domain/usecases/delete_product_usecase.dart';

import 'package:punto_venta_app/features/stock/domain/usecases/get_all_products_usecase.dart';
import 'package:punto_venta_app/features/stock/domain/usecases/get_product_stock_usecase.dart';
import 'package:punto_venta_app/features/stock/domain/usecases/get_stock_movements_usecase.dart';
import 'package:punto_venta_app/features/stock/domain/usecases/remove_stock_usecase.dart';
import 'package:punto_venta_app/features/stock/domain/usecases/update_product_usecase.dart';
import 'package:punto_venta_app/features/stock/presentation/bloc/stock_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:punto_venta_app/features/pos/data/datasources/printer_web_datasource.dart';
import 'package:uuid/uuid.dart';

import 'features/splash/presentation/bloc/splash_bloc.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_with_google_usecase.dart';
import 'features/auth/domain/usecases/login_with_email_usecase.dart';
import 'features/auth/domain/usecases/select_company_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/pos/data/repositories/product_repository_impl.dart';

import 'package:punto_venta_app/features/pos/data/datasources/supplier_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/supplier_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/repositories/supplier_repository_impl.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/supplier_repository.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_suppliers_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/make_supplier_payment_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_bloc.dart';
import 'features/pos/data/repositories/saved_orders_repository_impl.dart';
import 'features/pos/domain/usecases/get_products_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/cash_register_repository.dart';
import 'package:punto_venta_app/features/pos/data/repositories/cash_register_repository_impl.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_cash_register_status_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/open_cash_register_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/close_cash_register_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cash_register/cash_register_cubit.dart';
import 'features/pos/domain/usecases/manage_cart_usecase.dart';
import 'features/pos/domain/usecases/save_order_usecase.dart';
import 'features/pos/presentation/bloc/product/product_bloc.dart';
import 'features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/saved_orders/saved_orders_bloc.dart';
import 'package:punto_venta_app/features/pos/data/datasources/settlements_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/repositories/settlements_repository_impl.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/settlements_repository.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_settlements_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/settlements/settlements_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Splash
  sl.registerFactory(() => SplashBloc());

  //! Features - Auth
  // Bloc
  sl.registerFactory(() => AuthBloc(
        loginWithGoogleUsecase: sl(),
        loginWithEmailUsecase: sl(),
        selectCompanyUsecase: sl(),
        authenticateUserUseCase: sl(),
        logoutUsecase: sl(),
        changeCashierUseCase: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => LoginWithGoogleUsecase(sl()));
  sl.registerLazySingleton(() => LoginWithEmailUsecase(sl()));
  sl.registerLazySingleton(() => SelectCompanyUseCase(sl()));
  sl.registerLazySingleton(() => AuthenticateUserUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUsecase(sl()));
  sl.registerLazySingleton(() => ChangeCashierUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      localDataSource: sl(),
      googleAuthDataSource: sl(),
      firestoreUserDataSource: sl(),
      userApiDataSource: sl(),
      priceListLocalDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<GoogleAuthDataSource>(
    () => GoogleAuthDataSourceImpl(),
  );
  sl.registerLazySingleton<FirestoreUserDataSource>(
    () => FirestoreUserDataSourceImpl(),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<UserApiService>(
    () => UserApiService(sl()),
  );
  sl.registerLazySingleton<UserApiDataSource>(
    () => UserApiDataSourceImpl(),
  );
  sl.registerLazySingleton<PrinterLocalDataSource>(
    () => PrinterLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<PdvLocalDataSource>(
    () => PdvLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<PdvService>(
    () => PdvService(sl()),
  );
  sl.registerLazySingleton<PdvRemoteDataSource>(
    () => PdvRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<PriceListTypesService>(
    () => PriceListTypesService(sl()),
  );
  sl.registerLazySingleton<PriceListTypesRemoteDataSource>(
    () => PriceListTypesRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<PriceListTypesLocalDataSource>(
    () => PriceListTypesLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Features - POS
  // Bloc
  sl.registerFactory(() => CashRegisterCubit(
        getStatusUseCase: sl(),
        openUseCase: sl(),
        closeUseCase: sl(),
      ));
  sl.registerFactory(() =>
      ProductBloc(getProductsUsecase: sl(), priceListLocalDataSource: sl()));
  sl.registerFactory(() => CartBloc(
        manageCartUsecase: sl(),
        sharedPreferences: sl(),
      ));
  sl.registerFactory(() => UiBloc());
  sl.registerFactory(() => SavedOrdersBloc(
        saveOrderUsecase: sl(),
        loadSavedOrdersUsecase: sl(),
        sharedPreferences: sl(),
      ));
  sl.registerFactory(() => RefundsCubit(
        repository: sl(),
      ));
  sl.registerFactory(() =>
      ReportsBloc(getReportsUsecase: sl(), generateCreditNoteUsecase: sl()));
  sl.registerFactory(() => SettlementsBloc(getSettlementsUsecase: sl()));
  sl.registerFactory(() => ClientsBloc(
        getClients: sl(),
        addClient: sl(),
        deleteClient: sl(),
        priceListLocalDataSource: sl(),
        pdvLocalDataSource: sl(),
      ));
  sl.registerFactory(() => SupplierPaymentsBloc(
        getSuppliers: sl(),
        makePayment: sl(),
      ));
  sl.registerFactory(() => PaymentMethodsBloc(
        fetchPaymentMethods: sl(),
        fetchPaymentMethodsConfig: sl(),
        savePaymentMethodsConfig: sl(),
      ));
  sl.registerLazySingleton(() => PriceListTypesBloc(
        fetchPriceListTypesUsecase: sl(),
        repository: sl(),
      ));
  sl.registerLazySingleton(() => PdvConfigBloc(
        fetchPdvConfigUsecase: sl(),
        fetchBranchesUsecase: sl(),
        getVatCategoriesUsecase: sl(),
        repository: sl(),
      ));
  sl.registerFactory(() => CheckoutBloc(
        authLocalDataSource: sl(),
        pdvLocalDataSource: sl(),
        priceListLocalDataSource: sl(),
        branchLocalDataSource: sl(),
        vatCategoryLocalDataSource: sl(),
        fiscalIssuerDataRepository: sl(),
        completeOrderUsecase: sl(),
        getTicketConfigUsecase: sl(),
        sendInvoiceUseCase: sl(),
        processPartialReturnUseCase: sl(),
        calculateOrderTaxesUseCase: sl(),
        sharedPreferences: sl(),
      ));

  sl.registerLazySingleton(() => CalculateOrderTaxesUseCase(
        pdvLocalDataSource: sl(),
        branchLocalDataSource: sl(),
        vatCategoryLocalDataSource: sl(),
      ));

  // sl.registerFactory(() => PrinterBloc(printTicketUsecase: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetProductsUsecase(sl()));
  sl.registerLazySingleton(() => ManageCartUsecase());
  sl.registerLazySingleton(() => SaveOrderUsecase(sl()));
  sl.registerLazySingleton(() => LoadSavedOrdersUsecase(sl()));
  sl.registerLazySingleton(() => CompleteOrderUsecase(sl()));
  sl.registerLazySingleton(() => GetReportsUsecase(sl()));
  sl.registerLazySingleton(() => GetSettlementsUsecase(sl()));
  sl.registerLazySingleton(() => GetClientsUsecase(sl()));
  sl.registerLazySingleton(() => AddClientUsecase(sl()));
  sl.registerLazySingleton(() => DeleteClientUsecase(sl()));
  sl.registerLazySingleton(() => GetSuppliersUsecase(sl()));
  sl.registerLazySingleton(() => MakeSupplierPaymentUsecase(sl()));
  sl.registerLazySingleton(() => GetTaxesUsecase(sl()));
  sl.registerLazySingleton(() => GetVatCategoriesUsecase(sl()));
  sl.registerLazySingleton(() => SendInvoiceUseCase(sl()));
  sl.registerLazySingleton(() => GetTicketConfigUsecase(sl()));
  sl.registerLazySingleton(() => FetchTicketConfigUsecase(sl()));
  sl.registerLazySingleton(() => UpdateTicketConfigUsecase(sl()));
  sl.registerLazySingleton(() => FetchPaymentMethodsUsecase(sl()));
  sl.registerLazySingleton(() => FetchPaymentMethodsConfigUsecase(sl()));
  sl.registerLazySingleton(() => SavePaymentMethodsConfigUsecase(sl()));
  sl.registerLazySingleton(() => FetchPdvConfigUsecase(sl()));
  sl.registerLazySingleton(() => GetCashRegisterStatusUseCase(sl()));
  sl.registerLazySingleton(() => OpenCashRegisterUseCase(sl()));
  sl.registerLazySingleton(() => CloseCashRegisterUseCase(sl()));
  sl.registerLazySingleton(() => FetchPriceListTypesUsecase(sl()));
  sl.registerLazySingleton(() => FetchBranchesUsecase(sl()));
  sl.registerLazySingleton(() => FetchReturnReasonsUsecase(sl()));
  sl.registerLazySingleton(() => FetchReturnsUsecase(sl()));
  sl.registerLazySingleton(() => GenerateCreditNoteUsecase(
        returnsRepository: sl(),
        completedOrdersRepository: sl(),
      ));
  sl.registerLazySingleton(() => ProcessPartialReturnUseCase(
        returnsRepository: sl(),
        completedOrdersRepository: sl(),
      ));

  // sl.registerLazySingleton(() => PrintTicketUsecase(sl()));

  // Repository
  sl.registerLazySingleton<CashRegisterRepository>(
    () => CashRegisterRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<SavedOrdersRepository>(
    () => SavedOrdersRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<ReturnsRepository>(
    () => ReturnsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<RefundsRepository>(
    () => RefundsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<SettlementsRepository>(
    () => SettlementsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<CompletedOrdersRepository>(
    () => CompletedOrdersRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      branchLocalDataSource: sl(),
      vatCategoryLocalDataSource: sl(),
      clientLocalDataSource: sl(),
      taxLocalDataSource: sl(),
      paymentMethodRepository: sl(),
      taxRepository: sl(),
    ),
  );
  sl.registerLazySingleton<ClientRepository>(
    () => ClientRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<SupplierRepository>(
    () => SupplierRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<TaxRepository>(
    () => TaxRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<VatCategoryRepository>(
    () => VatCategoryRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<FiscalIssuerDataRepository>(
    () => FiscalIssuerDataRepositoryImpl(
      remoteDatasource: sl(),
      localDatasource: sl(),
    ),
  );
  sl.registerLazySingleton<InvoiceRepository>(
    () => InvoiceRepositoryImpl(remote: sl()),
  );
  sl.registerLazySingleton<TicketConfigRepository>(
    () => TicketConfigRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<PaymentMethodRepository>(
    () => PaymentMethodRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<PdvConfigRepository>(
    () => PdvConfigRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      branchLocalDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<PriceListTypesRepository>(
    () => PriceListTypesRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );

  // ===== PRINTER =====
  if (kIsWeb) {
    // Datasource para Web
    sl.registerLazySingleton<PrinterWebDatasource>(
      () => PrinterWebDatasourceImpl(
        proxyUrl: 'http://localhost:3000',
      ),
    );

    // Repository para Web
    sl.registerLazySingleton<PrinterRepository>(
      () => PrinterRepositoryImpl(
        webDatasource: sl(),
      ),
    );
  } else {
    // Datasource para Desktop/Mobile
    sl.registerLazySingleton<PrinterSocketDatasource>(
      () => PrinterSocketDatasourceImpl(),
    );

    // Repository para Desktop/Mobile
    sl.registerLazySingleton<PrinterRepository>(
      () => PrinterRepositoryImpl(
        printerDatasource: sl(),
      ),
    );
  }

  // UseCase (compartido)
  sl.registerLazySingleton(
    () => PrintTicketUsecase(sl()),
  );

  // Bloc (compartido)
  sl.registerFactory(
    () => PrinterBloc(
      printTicketUsecase: sl(),
      printerLocalDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<ProductService>(
    () => ProductService(sl()),
  );
  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<SavedOrdersLocalDataSource>(
    () => SavedOrdersLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<CompletedOrdersLocalDataSource>(
    () => CompletedOrdersLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<ReturnsService>(
    () => ReturnsService(sl()),
  );
  sl.registerLazySingleton<ReturnsRemoteDataSource>(
    () => ReturnsRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<RefundsService>(
    () => RefundsService(sl()),
  );
  sl.registerLazySingleton<RefundsRemoteDataSource>(
    () => RefundsRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<SettlementsService>(
    () => SettlementsService(sl()),
  );
  sl.registerLazySingleton<SettlementsRemoteDataSource>(
    () => SettlementsRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<CompletedOrdersService>(
    () => CompletedOrdersService(sl()),
  );
  sl.registerLazySingleton<CompletedOrdersRemoteDataSource>(
    () => CompletedOrdersRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<ClientLocalDataSource>(
      () => ClientLocalDataSourceImpl(sharedPreferences: sl()));
  sl.registerLazySingleton<ClientService>(
    () => ClientService(sl()),
  );
  sl.registerLazySingleton<ClientRemoteDataSource>(
    () => ClientRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<SupplierLocalDataSource>(
      () => SupplierLocalDataSourceImpl(sharedPreferences: sl()));
  sl.registerLazySingleton<SupplierService>(
    () => SupplierService(sl()),
  );
  sl.registerLazySingleton<SupplierRemoteDataSource>(
    () => SupplierRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<TaxLocalDataSource>(
      () => TaxLocalDataSourceImpl(sharedPreferences: sl()));
  sl.registerLazySingleton<TaxService>(
    () => TaxService(sl()),
  );
  sl.registerLazySingleton<TaxRemoteDataSource>(
    () => TaxRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<VatCategoryLocalDataSource>(
      () => VatCategoryLocalDataSourceImpl(sharedPreferences: sl()));
  sl.registerLazySingleton<VatCategoryService>(
    () => VatCategoryService(sl()),
  );
  sl.registerLazySingleton<VatCategoryRemoteDataSource>(
    () => VatCategoryRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<FiscalIssuerDataLocalDatasource>(
      () => FiscalIssuerDataLocalDatasourceImpl(sharedPreferences: sl()));
  sl.registerLazySingleton<FiscalIssuerDataRemoteDatasource>(
      () => FiscalIssuerDataRemoteDatasourceImpl());
  sl.registerLazySingleton<BranchLocalDataSource>(
      () => BranchLocalDataSourceImpl(sharedPreferences: sl()));
  sl.registerLazySingleton<InvoiceService>(
    () => InvoiceService(sl()),
  );
  sl.registerLazySingleton<InvoiceRemoteDataSource>(
    () => InvoiceRemoteDataSourceImpl(taxRepository: sl()),
  );
  sl.registerLazySingleton<TicketConfigLocalDataSource>(
    () => TicketConfigLocalDataSourceImpl(dbHelper: sl()),
  );
  sl.registerLazySingleton<TicketConfigService>(
    () => TicketConfigService(sl()),
  );
  sl.registerLazySingleton<TicketConfigRemoteDataSource>(
    () => TicketConfigRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<PriceListLocalDataSource>(
    () => PriceListLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<PaymentMethodService>(
    () => PaymentMethodService(sl()),
  );
  sl.registerLazySingleton<PaymentMethodRemoteDatasource>(
    () => PaymentMethodRemoteDatasourceImpl(),
  );

  //! Features - Stock
  // Bloc
  sl.registerFactory(() => StockBloc(
        getAllProductsUsecase: sl(),
        getProductStockUsecase: sl(),
        // createProductUsecase: sl(),
        // updateProductUsecase: sl(),
        // deleteProductUsecase: sl(),
        addStockUsecase: sl(),
        removeStockUsecase: sl(),
        adjustStockUsecase: sl(),
        getStockMovementsUsecase: sl(),
      ));

  // Usecases
  sl.registerLazySingleton(() => CreateProductUsecase(sl()));
  sl.registerLazySingleton(() => UpdateProductUsecase(sl()));
  sl.registerLazySingleton(() => DeleteProductUsecase(sl()));

  sl.registerLazySingleton(() => GetProductStockUsecase(sl()));
  sl.registerLazySingleton(() => GetAllProductsUsecase(sl()));
  sl.registerLazySingleton(() => AddStockUsecase(sl()));
  sl.registerLazySingleton(() => RemoveStockUsecase(sl()));
  sl.registerLazySingleton(() => AdjustStockUsecase(sl()));
  sl.registerLazySingleton(() => GetStockMovementsUsecase(sl()));

  // Repository
  sl.registerLazySingleton<StockRepository>(
    () => StockRepositoryImpl(
      productRepository: sl(),
      localDatasource: sl(),
      uuid: sl(),
    ),
  );

  // Datasource
  sl.registerLazySingleton<StockLocalDatasource>(
    () => StockLocalDatasourceImpl(
      databaseHelper: sl(),
      uuid: sl(),
    ),
  );

  // Database
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton<Uuid>(() => const Uuid());
  sl.registerLazySingleton<Dio>(() => DioClient.instance);

  // HTTP client
  sl.registerLazySingleton(() => http.Client());
}
