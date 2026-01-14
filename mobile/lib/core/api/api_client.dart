import 'package:dio/dio.dart';

import '../errors/app_error.dart';

class ApiClient {
  ApiClient({required String baseUrl, required Future<String?> Function() getToken})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
          ),
        ) {
    dio.interceptors.add(_JwtAuthInterceptor(getToken));
  }

  final Dio dio;

  static AppError mapDioError(Object error) {
    if (error is AppError) return error;

    if (error is DioException) {
      final status = error.response?.statusCode;

      // Prefer backend-provided message if any.
      final data = error.response?.data;

      String? backendMessage;
      String? backendCode;

      if (data is Map) {
        final err = data['error'];
        if (err is Map) {
          if (err['message'] is String) backendMessage = err['message'] as String;
          if (err['code'] is String) backendCode = err['code'] as String;
        }

        backendMessage ??= (data['message'] is String) ? data['message'] as String : null;
      }

      final message = backendMessage ?? switch (error.type) {
        DioExceptionType.connectionTimeout => 'Connection timeout',
        DioExceptionType.sendTimeout => 'Request send timeout',
        DioExceptionType.receiveTimeout => 'Response timeout',
        DioExceptionType.badCertificate => 'Bad SSL certificate',
        DioExceptionType.cancel => 'Request cancelled',
        DioExceptionType.connectionError => 'Network connection error',
        DioExceptionType.badResponse =>
          'Server error${status != null ? ' ($status)' : ''}',
        DioExceptionType.unknown => 'Unknown network error',
      };

      return AppError(
        code: backendCode ?? status?.toString() ?? error.type.name,
        message: message,
      );
    }

    return AppError(code: 'unknown', message: error.toString());
  }
}

class _JwtAuthInterceptor extends Interceptor {
  _JwtAuthInterceptor(this._getToken);

  final Future<String?> Function() _getToken;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // DEBUG: trace whether Authorization header is attached (do NOT print token).
    // ignore: avoid_print
    print(
      '[dio] ${options.method} ${options.path} authHeader=${options.headers['Authorization'] != null}',
    );

    handler.next(options);
  }
}
