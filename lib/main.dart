import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/services/remote_config_service.dart';
import 'package:punto_venta_app/features/support_chat/presentation/bloc/support_chat_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/themes/theme_cubit.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pdv_config/pdv_config_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_bloc.dart';
import 'package:punto_venta_app/firebase_options.dart';

import 'app/app.dart';
import 'features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'features/pos/presentation/bloc/product/product_bloc.dart';
import 'features/pos/presentation/bloc/saved_orders/saved_orders_bloc.dart';
import 'features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'features/splash/presentation/bloc/splash_bloc.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await di.init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _signInAnonymously();

  // Initialize and fetch Remote Config parameters
  await di.sl<RemoteConfigService>().fetchConfig();

  runApp(const MyApp());
}

Future<void> _signInAnonymously() async {
  try {
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e) {
    print('Error de autenticación anónima: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => di.sl<SplashBloc>()),
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
        BlocProvider(create: (_) => di.sl<ProductBloc>()),
        BlocProvider(create: (_) => di.sl<CartBloc>()),
        BlocProvider(create: (_) => di.sl<UiBloc>()),
        BlocProvider(create: (_) => di.sl<SavedOrdersBloc>()),
        BlocProvider(create: (_) => di.sl<ReportsBloc>()),
        BlocProvider(create: (_) => di.sl<ClientsBloc>()),
        BlocProvider(create: (_) => di.sl<PrinterBloc>()),
        BlocProvider(create: (_) => di.sl<PaymentMethodsBloc>()),
        BlocProvider(create: (_) => di.sl<PdvConfigBloc>()),
        BlocProvider(create: (_) => di.sl<CheckoutBloc>()),
        BlocProvider(create: (_) => di.sl<SupportChatBloc>()),
      ],
      child: const PosApp(),
    );
  }
}
