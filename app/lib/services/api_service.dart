import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config.dart';
import '../models/delegacia.dart';
import '../models/media.dart';
import '../models/user.dart';

/// Centraliza a comunicação HTTP com a API do backend,
/// incluindo autenticação, interceptors e endpoints específicos.
class ApiService {
  ApiService._internal();

  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    initialize();
    return _instance;
  }

  // ---------------------------------------------------------------------------
  // Base configuration
  // ---------------------------------------------------------------------------

  static const String _baseUrl = apiBaseUrl;
  static const Set<String> _authBypassPaths = {
    '/auth/login',
    '/auth/refresh-token',
    '/users',
  };

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(
        seconds: 10,
      ), // Timeout de conexão otimizado
      receiveTimeout: const Duration(
        seconds: 15,
      ), // Timeout de recebimento otimizado
      sendTimeout: const Duration(seconds: 15), // Timeout de envio otimizado
    ),
  );
  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  static bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  static void initialize() {
    if (_initialized) return;
    _setupInterceptors();
    _initialized = true;
    debugPrint('ApiService initialized with baseUrl=$_baseUrl');
  }

  static void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_shouldBypassAuth(options.path)) {
            return handler.next(options);
          }

          final token = await _secureStorage.read(key: 'token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode != 401) {
            return handler.next(error);
          }

          final refreshToken = await _secureStorage.read(key: 'refreshToken');
          if (refreshToken == null) {
            return handler.next(error);
          }

          final newTokens = await _refreshToken(refreshToken);
          if (newTokens == null) {
            return handler.next(error);
          }

          await _persistTokens(newTokens);
          error.requestOptions.headers['Authorization'] =
              'Bearer ${newTokens['token']}';
          return handler.resolve(await _dio.fetch(error.requestOptions));
        },
      ),
    );
  }

  static bool _shouldBypassAuth(String path) =>
      _authBypassPaths.any((value) => path.endsWith(value));

  // ---------------------------------------------------------------------------
  // Token helpers
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>?> _refreshToken(
    String refreshToken,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final payload = response.data as Map<String, dynamic>;
        final data = payload['data'];
        if (payload['success'] == true && data is Map<String, dynamic>) {
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      debugPrint('Erro na requisição de refresh token: $e');
    }
    return null;
  }

  static Future<void> _persistTokens(Map<String, dynamic> tokens) async {
    final token = tokens['token'] as String?;
    final refresh = tokens['refreshToken'] as String?;

    if (token != null) {
      await _secureStorage.write(key: 'token', value: token);
    }
    if (refresh != null) {
      await _secureStorage.write(key: 'refreshToken', value: refresh);
    }
  }

  static Future<void> _persistSession(Map<String, dynamic> payload) async {
    await _persistTokens(payload);
    final user = payload['user'] as Map<String, dynamic>?;
    final userId = user?['id']?.toString();
    if (userId != null) {
      await _secureStorage.write(key: 'userId', value: userId);
    }
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  static Future<User?> login(String email, String senha) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'senha': senha},
      );

      if (response.statusCode != 200) {
        return null;
      }

      // Novo formato: { accessToken, refreshToken, user: {...} }
      final payload = response.data as Map<String, dynamic>;

      // Mapeando para o formato esperado pelo _persistSession
      // O app usa internamente a chave 'token', mas a API manda 'accessToken'
      final sessionData = {
        'token': payload['accessToken'],
        'refreshToken': payload['refreshToken'],
        'user': payload['user'],
      };

      await _persistSession(sessionData);

      final userData = payload['user'] as Map<String, dynamic>?;
      return userData != null ? User.fromJson(userData) : null;
    } catch (e) {
      debugPrint('Erro no login: $e');
      return null;
    }
  }

  static Future<void> logout() async {
    await _secureStorage.deleteAll();
  }

  static Future<bool> register(User user) async {
    try {
      final response = await _dio.post('/users', data: user.toRegisterJson());
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Erro no registro: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // User Profile
  // ---------------------------------------------------------------------------

  static Future<User?> getProfile() async {
    try {
      final userId = await _secureStorage.read(key: 'userId');
      if (userId == null) {
        debugPrint('getProfile: userId não encontrado no storage');
        return null;
      }

      debugPrint('getProfile: Buscando perfil do usuário $userId');
      final response = await _dio.get('/users/$userId');

      if (response.statusCode == 200) {
        debugPrint('getProfile: Resposta da API: ${response.data}');

        if (response.data == null) {
          debugPrint('getProfile: response.data é null');
          return null;
        }

        try {
          // A API agora retorna o objeto usuário diretamente
          final userData = response.data as Map<String, dynamic>;

          final user = User.fromJson(userData);
          debugPrint(
            'getProfile: User criado com sucesso: ${user.nome_completo}',
          );
          return user;
        } catch (e, stackTrace) {
          debugPrint('getProfile: Erro ao criar User a partir do JSON: $e');
          debugPrint('getProfile: Stack trace: $stackTrace');
          debugPrint('getProfile: JSON recebido: ${response.data}');
          return null;
        }
      }

      debugPrint(
        'getProfile: Status code diferente de 200: ${response.statusCode}',
      );
      return null;
    } catch (e, stackTrace) {
      debugPrint('Erro ao buscar perfil: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<bool> updateUser(
    int userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await _dio.put('/users/$userId', data: userData);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro ao atualizar usuário: $e');
      return false;
    }
  }

  // Instance HTTP helpers
  Future<Response> get(String path, {Map<String, dynamic>? query}) =>
      _dio.get(path, queryParameters: query);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  // ---------------------------------------------------------------------------
  // Media
  // ---------------------------------------------------------------------------

  static Future<Media?> uploadFile(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });
      final response = await _dio.post('/upload', data: formData);
      if (response.statusCode == 200 && response.data != null) {
        return Media.fromJson(response.data);
      }
      debugPrint(
        'ApiService: Falha no upload. Status: ${response.statusCode}, Dados: ${response.data}',
      );
      return null;
    } catch (e) {
      debugPrint('ApiService: Erro ao fazer upload do arquivo: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Delegacias
  // ---------------------------------------------------------------------------

  static Future<List<Delegacia>> getDelegacias() async {
    try {
      final response = await _dio.get('/delegacias');
      if (response.statusCode == 200 && response.data != null) {
        final delegaciasData = _extractDelegaciaList(response.data);
        return delegaciasData.map((json) => Delegacia.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao buscar delegacias: $e');
      return [];
    }
  }

  static Future<List<Delegacia>> getDelegaciasProximas({
    required double latitude,
    required double longitude,
    double radius = 5,
  }) async {
    try {
      final response = await _dio.get(
        '/delegacias/proximas',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final List data = response.data;
        return data.map((json) => Delegacia.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao buscar delegacias próximas: $e');
      return [];
    }
  }

  static List<dynamic> _extractDelegaciaList(dynamic rawData) {
    if (rawData is List) return rawData;
    if (rawData is Map<String, dynamic>) {
      final nested = rawData['delegacias'];
      if (nested is List) return nested;
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // Password flows
  // ---------------------------------------------------------------------------

  static Future<bool> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro na solicitação de redefinição de senha: $e');
      return false;
    }
  }

  static Future<bool> generateOTP(String email) async {
    try {
      final response = await _dio.post(
        '/auth/request-password-reset/user',
        data: {'email': email},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro na geração de OTP: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> resetPasswordWithOTP(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password/otp',
        data: {'email': email, 'otp': otp, 'newPassword': newPassword},
      );
      return {'success': response.statusCode == 200};
    } on DioException catch (e) {
      debugPrint('Erro na redefinição de senha com OTP: $e');
      final message =
          e.response?.data != null && e.response!.data['message'] != null
          ? e.response!.data['message']
          : 'Erro desconhecido';
      return {'success': false, 'message': message};
    }
  }

  static Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro na alteração de senha: $e');
      return false;
    }
  }
}
