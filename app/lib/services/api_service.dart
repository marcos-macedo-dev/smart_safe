import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/media.dart'; // <-- Import adicionado
import '../models/delegacia.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(baseUrl: 'http://10.214.43.103:3002/api'),
  );
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print(
            'Interceptor - Requesting: ${options.method} ${options.path}',
          ); // Added log
          if (options.path.endsWith('/login') ||
              options.path.endsWith('/users') ||
              options.path.endsWith('/auth/refresh-token')) {
            return handler.next(options);
          }
          String? token = await _secureStorage.read(key: 'token');
          print('Interceptor: Token lido do storage: $token'); // Debug print
          if (token != null) {
            print('Interceptor: Adicionando token ao cabeçalho.'); // Log
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            print(
              'Interceptor: Token é nulo, não adicionando ao cabeçalho.',
            ); // Log
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            String? refreshToken = await _secureStorage.read(
              key: 'refreshToken',
            );
            if (refreshToken != null) {
              try {
                final newTokens = await _refreshToken(refreshToken);
                if (newTokens != null) {
                  // Update tokens in storage
                  await _secureStorage.write(
                    key: 'token',
                    value: newTokens['token'],
                  );
                  await _secureStorage.write(
                    key: 'refreshToken',
                    value: newTokens['refreshToken'],
                  );

                  // Retry the original request with the new token
                  error.requestOptions.headers['Authorization'] =
                      'Bearer ${newTokens['token']}';
                  return handler.resolve(
                    await _dio.fetch(error.requestOptions),
                  );
                }
              } catch (e) {
                print('Erro ao tentar refresh do token: $e');
              }
            }
            // If refresh token is null or refresh failed, just let the request fail
            // Don't automatically logout - let the calling code handle authentication errors
            print(
              'Token expirado e não foi possível renovar. Requisição falhou com 401.',
            );
          }
          return handler.next(error);
        },
      ),
    );
  }

  static Future<Map<String, String>?> _refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );
      if (response.statusCode == 200 && response.data != null) {
        return {
          'token': response.data['token'],
          'refreshToken': response.data['refreshToken'],
        };
      }
      return null;
    } catch (e) {
      print('Erro na requisição de refresh token: $e');
      return null;
    }
  }

  static void initialize() {
    print('ApiService initialized.'); // Added log
    _setupInterceptors();
  }

  static Future<bool> register(User user) async {
    print('Payload de registro: ${user.toRegisterJson()}');
    try {
      Response response = await _dio.post(
        '/users',
        data: user.toRegisterJson(),
      );
      print('Registro - Status Code: ${response.statusCode}');
      return response.statusCode == 201;
    } catch (e) {
      print('Erro no registro: $e');
      return false;
    }
  }

  static Future<User?> login(String email, String senha) async {
    try {
      Response response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'senha': senha},
      );
      if (response.statusCode == 200) {
        // Ensure data is not null and is a Map
        if (response.data != null && response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>; // Cast to Map
          final token = data['token'] as String?;
          final refreshToken = data['refreshToken'] as String?;
          final userId = (data['user']?['id'] as int?)?.toString();

          if (token != null) {
            await _secureStorage.write(key: 'token', value: token);
          }
          if (refreshToken != null) {
            await _secureStorage.write(
              key: 'refreshToken',
              value: refreshToken,
            );
          }
          if (userId != null) {
            await _secureStorage.write(key: 'userId', value: userId);
          }

          return User.fromJson(data['user']);
        } else {
          print('Erro no login: Resposta de dados inválida.');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Erro no login: $e');
      return null;
    }
  }

  static Future<void> logout() async {
    await _secureStorage.deleteAll(); // Clear all stored tokens and user info
    // TODO: Implement navigation to login screen after logout
  }

  static Future<User?> getProfile() async {
    try {
      String? userId = await _secureStorage.read(key: 'userId');
      print('ApiService - userId do storage: $userId'); // Log para userId
      if (userId == null) {
        print('Erro ao buscar perfil: userId não encontrado no storage.');
        return null;
      }
      print('ApiService - URL da requisição: /users/$userId'); // Log para URL
      Response response = await _dio.get('/users/$userId');
      print(
        'ApiService - Resposta do backend: ${response.data}',
      ); // Log para resposta do backend
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar perfil: $e');
      return null;
    }
  }

  static Future<bool> updateUser(
    int userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      print(
        'ApiService - Enviando atualização para /users/$userId com dados: $userData',
      );
      Response response = await _dio.put('/users/$userId', data: userData);
      print('ApiService - Resposta de atualização: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao atualizar usuário: $e');
      return false;
    }
  }

  Future<Response> get(String path) async {
    return await _dio.get(path);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  static Future<Media?> uploadFile(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });
      final response = await _dio.post("/upload", data: formData);
      if (response.statusCode == 200 && response.data != null) {
        return Media.fromJson(response.data);
      }
      print(
        'ApiService: Falha no upload do arquivo. Status: ${response.statusCode}, Dados: ${response.data}',
      );
      return null;
    } catch (e) {
      print('ApiService: Erro ao fazer upload do arquivo: $e');
      return null;
    }
  }

  /// Buscar todas as delegacias
  static Future<List<Delegacia>> getDelegacias() async {
    try {
      final response = await _dio.get('/delegacias'); // endpoint da API
      if (response.statusCode == 200 && response.data != null) {
        final delegaciasData = _extractDelegaciaList(response.data);
        return delegaciasData.map((json) => Delegacia.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erro ao buscar delegacias: $e');
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

  /// Buscar delegacias próximas (opcional: latitude, longitude, radius em km)
  static Future<List<Delegacia>> getDelegaciasProximas({
    required double latitude,
    required double longitude,
    double radius = 5,
  }) async {
    try {
      final response = await _dio.get(
        '/delegacias/nearby',
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
      print('Erro ao buscar delegacias próximas: $e');
      return [];
    }
  }

  static Future<bool> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      // Consider success if the server returns 200 OK,
      // as the server should not reveal if the email is registered.
      return response.statusCode == 200;
    } catch (e) {
      print('Erro na solicitação de redefinição de senha: $e');
      // Return false on error, the UI will handle the user message.
      return false;
    }
  }

  static Future<bool> generateOTP(String email) async {
    try {
      final response = await _dio.post(
        '/auth/request-password-reset/user',
        data: {'email': email},
      );
      // Consider success if the server returns 200 OK,
      // as the server should not reveal if the email is registered.
      return response.statusCode == 200;
    } catch (e) {
      print('Erro na geração de OTP: $e');
      // Return false on error, the UI will handle the user message.
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
      print('Erro na redefinição de senha com OTP: $e');
      if (e.response?.data != null && e.response!.data['message'] != null) {
        return {'success': false, 'message': e.response!.data['message']};
      }
      return {'success': false, 'message': 'Erro desconhecido'};
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
      print('Erro na alteração de senha: $e');
      return false;
    }
  }
}
