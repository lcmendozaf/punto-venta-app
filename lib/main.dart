import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/themes/theme_cubit.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
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

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await AppLogger.init();
    _installGlobalErrorHandlers();

    AppLogger.info('Arranque: platform=$defaultTargetPlatform debug=$kDebugMode');
    _logEnvironment();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    AppLogger.info('DI init...');
    await di.init();

    AppLogger.info('Firebase.initializeApp...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info('Firebase inicializado proyecto=${Firebase.app().options.projectId}');
    _configureFirestore();
    await _signInAnonymously();

    AppLogger.info('runApp');
    AppLogger.startHeartbeat();
    runApp(const MyApp());
  }, (error, stackTrace) {
    AppLogger.error('Error no capturado (zona)', error, stackTrace);
  });
}

/// Windows puede matar el proceso al paginar el ejecutable si éste vive en una
/// unidad de red, un disco extraíble o una carpeta sincronizada (OneDrive).
void _logEnvironment() {
  try {
    final exePath = Platform.resolvedExecutable;
    final isUnc = exePath.startsWith(r'\\');
    final env = Platform.environment;

    AppLogger.info('SO: ${Platform.operatingSystemVersion}');
    AppLogger.info('Ejecutable: $exePath');
    AppLogger.info('Unidad: ${exePath.length >= 2 ? exePath.substring(0, 2) : '?'} rutaUNC=$isUnc');
    AppLogger.info('OneDrive env=${env['OneDrive'] ?? '(no definido)'}');
    AppLogger.info('Temp: ${Directory.systemTemp.path}');

    final exeDir = File(exePath).parent;
    final entries = exeDir.listSync().length;
    AppLogger.info('Carpeta del ejecutable legible, $entries entradas');
  } catch (e, stackTrace) {
    AppLogger.error('No se pudo inspeccionar el entorno', e, stackTrace);
  }
}

void _installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    AppLogger.error(
      'FlutterError: ${details.exceptionAsString()}',
      details.exception,
      details.stack,
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('PlatformDispatcher.onError', error, stack);
    return true;
  };

  ErrorWidget.builder = (details) {
    AppLogger.error('ErrorWidget', details.exception, details.stack);
    return Material(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText(
            'Error:\n${details.exceptionAsString()}\n\nLog: ${AppLogger.logPath}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    );
  };
}

/// En Windows la caché local (LevelDB) del SDK nativo de Firestore puede
/// tumbar el proceso sin dejar error en Dart, según permisos y ruta del perfil.
const bool _firestorePersistenceOnWindows =
    bool.fromEnvironment('FIRESTORE_PERSISTENCE', defaultValue: false);

void _configureFirestore() {
  try {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: _firestorePersistenceOnWindows,
      );
      AppLogger.info(
        'Firestore settings: persistenceEnabled=$_firestorePersistenceOnWindows',
      );
    }
  } catch (e, stackTrace) {
    AppLogger.error('No se pudieron aplicar los settings de Firestore', e, stackTrace);
  }
}

Future<void> _signInAnonymously() async {
  try {
    AppLogger.info('FirebaseAuth.signInAnonymously...');
    await FirebaseAuth.instance.signInAnonymously();
    AppLogger.info('FirebaseAuth anónimo OK uid=${FirebaseAuth.instance.currentUser?.uid}');
  } catch (e, stackTrace) {
    AppLogger.error('Error de autenticación anónima', e, stackTrace);
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
      ],
      child: const PosApp(),
    );
  }
}
