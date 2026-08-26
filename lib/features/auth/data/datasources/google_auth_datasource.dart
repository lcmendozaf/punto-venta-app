import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_html_templates.dart';
import 'package:punto_venta_app/core/config/google_auth_config.dart';
import 'package:punto_venta_app/core/config/pkce_helper.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';

abstract class GoogleAuthDataSource {
  Future<String?> signInWithGoogle();
  Future<void> signOut();
}

class GoogleAuthDataSourceImpl implements GoogleAuthDataSource {
  final GoogleSignIn _googleSignIn;

  GoogleAuthDataSourceImpl({
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email'],
              signInOption: SignInOption.standard,
            );

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  Future<String?> signInWithGoogle() async {
    AppLogger.info('signInWithGoogle isWindows=$_isWindows');
    if (_isWindows) {
      return _signInWithGoogleWindows();
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      return googleUser.email;
    } catch (e) {
      throw Exception('Error al iniciar sesión con Google: $e');
    }
  }

  @override
  Future<void> signOut() async {
    if (_isWindows) {
      return;
    }

    try {
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  Future<String?> _signInWithGoogleWindows() async {
    HttpServer? server;
    try {
      final hasClientId = GoogleAuthConfig.windowsClientId.isNotEmpty;
      final hasClientSecret = GoogleAuthConfig.windowsClientSecret.isNotEmpty;
      AppLogger.info(
        'OAuth Windows: clientIdConfigurado=$hasClientId secretConfigurado=$hasClientSecret',
      );
      if (!hasClientId || !hasClientSecret) {
        throw Exception(
          'Faltan GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET en el build de Windows.',
        );
      }

      // Iniciar servidor local en puerto aleatorio
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final int port = server.port;
      AppLogger.info('Servidor OAuth local en http://127.0.0.1:$port');

      // Generar PKCE verifier y challenge
      final String codeVerifier = PkceHelper.generateCodeVerifier();
      final String codeChallenge =
          PkceHelper.generateCodeChallenge(codeVerifier);

      // Construir URL de autorización de Google
      final Uri authorizationUri =
          Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': GoogleAuthConfig.windowsClientId,
        'redirect_uri': 'http://127.0.0.1:$port',
        'response_type': 'code',
        'scope': 'openid email profile',
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      });

      // Abrir URL en navegador externo
      if (await canLaunchUrl(authorizationUri)) {
        AppLogger.info('Abriendo navegador para Google Sign-In...');
        await launchUrl(authorizationUri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No se pudo abrir el navegador web del sistema.');
      }

      // Escuchar la respuesta del servidor local (redirección de Google)
      String? authCode;
      await for (var request in server) {
        final uri = request.uri;
        AppLogger.info(
          'Callback OAuth: path=${uri.path} params=${uri.queryParameters.keys.toList()} error=${uri.queryParameters['error']}',
        );
        authCode = uri.queryParameters['code'];

        // Enviar respuesta de éxito al navegador
        request.response.headers.contentType = ContentType.html;
        request.response.write(AuthHtmlTemplates.successPage);
        await request.response.close();
        break;
      }

      if (authCode == null) {
        throw Exception('El inicio de sesión fue cancelado o falló.');
      }

      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        body: {
          'client_id': GoogleAuthConfig.windowsClientId,
          'client_secret': GoogleAuthConfig.windowsClientSecret,
          'redirect_uri': 'http://127.0.0.1:$port',
          'code': authCode,
          'code_verifier': codeVerifier,
          'grant_type': 'authorization_code',
        },
      );

      AppLogger.info('Intercambio de tokens HTTP ${tokenResponse.statusCode}');
      if (tokenResponse.statusCode != 200) {
        throw Exception(
            'Error al obtener tokens de Google: ${tokenResponse.body}');
      }

      final Map<String, dynamic> tokenData = json.decode(tokenResponse.body);
      final String? idToken = tokenData['id_token'];

      if (idToken == null) {
        throw Exception('No se recibió el token de identidad.');
      }

      // Decodificar el id_token (JWT payload) para extraer el email
      final parts = idToken.split('.');
      if (parts.length != 3) {
        throw Exception('Formato de id_token inválido.');
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> claims = json.decode(decoded);

      final String? email = claims['email'];
      if (email == null || email.isEmpty) {
        throw Exception('No se pudo encontrar el correo electrónico.');
      }

      AppLogger.info('Google Sign-In Windows OK email=$email');
      return email;
    } catch (e, stackTrace) {
      AppLogger.error('Error en Google Sign-In Desktop', e, stackTrace);
      throw Exception('Error en Google Sign-In Desktop: $e');
    } finally {
      await server?.close(force: true);
    }
  }
}
