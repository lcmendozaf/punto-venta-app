import 'package:dio/dio.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

part 'user_api_datasource.g.dart';

@RestApi()
abstract class UserApiService {
  factory UserApiService(Dio dio, {String baseUrl}) = _UserApiService;

  @POST('/users/login-cashier')
  Future<dynamic> authenticateUser(@Body() Map<String, dynamic> body);
}

abstract class UserApiDataSource {
  Future<Map<String, dynamic>> authenticateUser(String userId, String password);
}

class UserApiDataSourceImpl implements UserApiDataSource {
  UserApiService get _apiService => di.sl<UserApiService>();

  UserApiDataSourceImpl();

  String _encode(String s) {
    int length = s.length;
    return String.fromCharCodes(s.runes.map((r) => r - length));
  }

  @override
  Future<Map<String, dynamic>> authenticateUser(
      String userId, String password) async {
    try {
      final encodedPassword = _encode(password);
      final Map<String, dynamic> response = await _apiService.authenticateUser({
        'id': userId,
        'password': encodedPassword,
      });

      return {
        'token': response['token'],
        'user': response['user'],
      };
    } catch (e, stackTrace) {
      AppLogger.error("[UserApiDataSource] authenticateUser", e,stackTrace);
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al autenticar usuario'));
    }
  }
}
