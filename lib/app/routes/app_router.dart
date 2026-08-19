import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/widgets/sidebar/sidebar.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_event.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_state.dart';
import 'package:punto_venta_app/features/auth/prensetation/pages/company_selection_page.dart';
import 'package:punto_venta_app/features/auth/prensetation/pages/credentials_page.dart';
import 'package:punto_venta_app/features/auth/prensetation/pages/login_page.dart';
import 'package:punto_venta_app/features/auth/domain/entities/user.dart';
import 'package:punto_venta_app/features/pos/presentation/pages/pending_settlements_page.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/settlements/settlements_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/pages/pos_main_page.dart';
import 'package:punto_venta_app/features/pos/presentation/pages/reports_page.dart';
import 'package:punto_venta_app/features/pos/presentation/pages/product_labels_page.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_bloc.dart';
import 'package:punto_venta_app/features/splash/presentation/pages/splash_page.dart';
import 'package:punto_venta_app/features/stock/presentation/pages/stock_management_page.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import 'route_paths.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/supplier_payments/supplier_payments_event.dart';
import 'package:punto_venta_app/features/pos/presentation/pages/supplier_payments_page.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cash_register/cash_register_cubit.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.splash,
    routes: [
      // Auth routes (sin sidebar)
      GoRoute(
        path: RoutePaths.splash,
        builder: (BuildContext context, GoRouterState state) {
          return const SplashPage();
        },
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (BuildContext context, GoRouterState state) {
          return const LoginPage();
        },
      ),
      GoRoute(
        path: RoutePaths.companySelection,
        builder: (context, state) => const CompanySelectionPage(),
      ),
      GoRoute(
        path: RoutePaths.credentials,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CredentialsPage(
            email: extra['email'] as String,
            companyId: extra['companyId'] as int,
            companyName: extra['companyName'] as String,
          );
        },
      ),

      // Main app routes (con sidebar)
      ShellRoute(
        builder: (context, state, child) {
          return MainLayoutShell(
            currentRoute: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: RoutePaths.pos,
            builder: (BuildContext context, GoRouterState state) {
              return BlocProvider(
                create: (_) => di.sl<CashRegisterCubit>()..fetchStatus(),
                child: const PosMainPage(),
              );
            },
          ),
          GoRoute(
            path: RoutePaths.stock,
            builder: (BuildContext context, GoRouterState state) {
              return const StockManagementPage();
            },
          ),
          GoRoute(
            path: RoutePaths.reports,
            builder: (BuildContext context, GoRouterState state) {
              return BlocProvider(
                create: (_) => di.sl<ReportsBloc>(),
                child: const ReportsPage(),
              );
            },
          ),
          GoRoute(
            path: RoutePaths.productLabels,
            builder: (BuildContext context, GoRouterState state) {
              return const ProductLabelsPage();
            },
          ),
          GoRoute(
            path: RoutePaths.pendingSettlements,
            builder: (BuildContext context, GoRouterState state) {
              return BlocProvider(
                create: (_) => di.sl<SettlementsBloc>(),
                child: const PendingSettlementsPage(),
              );
            },
          ),
          GoRoute(
            path: RoutePaths.supplierPayments,
            builder: (BuildContext context, GoRouterState state) {
              return BlocProvider(
                create: (_) =>
                    di.sl<SupplierPaymentsBloc>()..add(LoadSuppliersEvent()),
                child: const SupplierPaymentsPage(),
              );
            },
          ),
          GoRoute(
            path: RoutePaths.settings,
            builder: (BuildContext context, GoRouterState state) {
              // TODO: Crear SettingsPage
              return const Scaffold(
                body: Center(child: Text('Configuración - Próximamente')),
              );
            },
          ),
        ],
      ),
    ],
  );
}

/// Shell wrapper que provee el MainLayout con sidebar
class MainLayoutShell extends StatelessWidget {
  final String currentRoute;
  final Widget child;

  const MainLayoutShell({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;
        final isAdmin = user?.role == UserRole.admin;

        return MainLayout(
          currentRoute: currentRoute,
          isAdmin: isAdmin,
          onLogout: () {
            context.read<AuthBloc>().add(LogoutEvent());
            context.go(RoutePaths.login);
          },
          child: child,
        );
      },
    );
  }
}
