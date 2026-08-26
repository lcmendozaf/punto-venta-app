import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/auth/domain/usecases/authenticate_user_usecase.dart';
import 'package:punto_venta_app/features/auth/domain/usecases/change_chashier_usecase.dart';
import 'package:punto_venta_app/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:punto_venta_app/features/auth/domain/usecases/login_with_email_usecase.dart';
import 'package:punto_venta_app/features/auth/domain/usecases/select_company_usecase.dart';
import 'package:punto_venta_app/features/auth/domain/usecases/logout_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginWithGoogleUsecase loginWithGoogleUsecase;
  final LoginWithEmailUsecase loginWithEmailUsecase;
  final AuthenticateUserUseCase authenticateUserUseCase;
  final SelectCompanyUseCase selectCompanyUsecase;
  final LogoutUsecase logoutUsecase;
  final ChangeCashierUseCase changeCashierUseCase;

  AuthBloc({
    required this.loginWithGoogleUsecase,
    required this.loginWithEmailUsecase,
    required this.authenticateUserUseCase,
    required this.selectCompanyUsecase,
    required this.logoutUsecase,
    required this.changeCashierUseCase,
  }) : super(AuthInitial()) {
    on<LoginWithGoogleRequested>(_onLoginWithGoogleRequested);
    on<LoginWithEmailRequested>(_onLoginWithEmailRequested);
    on<CompanySelected>(_onCompanySelected);
    on<LogoutRequested>(_onLogoutRequested);
    on<LogoutEvent>(_onLogoutEvent);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<AuthenticateUserRequested>(_onUserAuthenticationRequested);
    on<ChangeCashierRequested>(_onChangeCashierRequested);
  }

  String _extractErrorMessage(dynamic error) {
    String message = error.toString();
    while (message.startsWith('Exception: ')) {
      message = message.replaceFirst('Exception: ', '');
    }
    return message;
  }

  Future<void> _onLoginWithGoogleRequested(
    LoginWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    AppLogger.info('AuthBloc: LoginWithGoogleRequested');
    try {
      final result = await loginWithGoogleUsecase();
      AppLogger.info(
        'AuthBloc: login Google result keys=${result.keys.toList()} autoSelected=${result['autoSelected']}',
      );

      if (result['autoSelected'] == true) {
        final company = result['companies'][0];
        AppLogger.info(
          'AuthBloc: autoSelect company id=${company['id']} (${company['id'].runtimeType}) name=${company['name']}',
        );
        final selectResult = await selectCompanyUsecase(
          result['email'],
          company['id'] is int
              ? company['id'] as int
              : int.parse(company['id'].toString()),
        );

        emit(AuthCompanySelected(
          email: selectResult['email'],
          companyId: selectResult['companyId'] is int
              ? selectResult['companyId'] as int
              : int.parse(selectResult['companyId'].toString()),
          companyName: selectResult['companyName'],
        ));
        AppLogger.info('AuthBloc: emit AuthCompanySelected (auto)');
      } else {
        emit(AuthCompanySelectionRequired(
          email: result['email'],
          companies: List<Map<String, dynamic>>.from(result['companies']),
          autoSelected: result['autoSelected'],
        ));
        AppLogger.info('AuthBloc: emit AuthCompanySelectionRequired');
      }

      // Para Debug, vista de multiples empresas siempre
      // emit(AuthCompanySelectionRequired(
      //     email: result['email'],
      //     companies: List<Map<String, dynamic>>.from(result['companies']),
      //     autoSelected: result['autoSelected'],
      //   ));
    } catch (e, stackTrace) {
      AppLogger.error('AuthBloc: LoginWithGoogleRequested falló', e, stackTrace);
      final errorMessage = _extractErrorMessage(e);
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onLoginWithEmailRequested(
    LoginWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await loginWithEmailUsecase(event.email);

      if (result['autoSelected'] == true) {
        final company = result['companies'][0];
        final selectResult = await selectCompanyUsecase(
          result['email'],
          company['id'],
        );

        emit(AuthCompanySelected(
          email: selectResult['email'],
          companyId: selectResult['companyId'],
          companyName: selectResult['companyName'],
        ));
      } else {
        emit(AuthCompanySelectionRequired(
          email: result['email'],
          companies: List<Map<String, dynamic>>.from(result['companies']),
          autoSelected: result['autoSelected'],
        ));
      }
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onCompanySelected(
    CompanySelected event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await selectCompanyUsecase(event.email, event.companyId);

      emit(AuthCompanySelected(
        email: result['email'],
        companyId: result['companyId'],
        companyName: result['companyName'],
      ));
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onUserAuthenticationRequested(
    AuthenticateUserRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authenticateUserUseCase(
        event.username,
        event.password,
      );

      emit(AuthAuthenticated(user: user));
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await logoutUsecase();
      emit(AuthUnauthenticated());
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onChangeCashierRequested(
    ChangeCashierRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await changeCashierUseCase();
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onLogoutEvent(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await logoutUsecase();
      emit(AuthUnauthenticated());
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthUnauthenticated());
  }
}
