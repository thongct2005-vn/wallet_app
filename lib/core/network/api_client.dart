import 'package:app/core/network/api_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;
  final storage = const FlutterSecureStorage();
  factory ApiClient() {
    return _instance;
  }
  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          String? accessToken = await storage.read(key: 'access_token');
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onResponse: ((response, handler) {
          return handler.next(response);
        }),

        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            String? refreshToken = await storage.read(key: 'refresh_token');
            if (refreshToken != null) {
              try {
                final refreshDio = Dio(
                  BaseOptions(baseUrl: dio.options.baseUrl),
                );
                final refreshResponse = await refreshDio.post(
                  ApiConfig.refreshToken,
                  data: {'refresh_token': refreshToken},
                );

                final newAccessToken =
                    refreshResponse.data['data']['token']['access_token'];
                final newRefreshToken =
                    refreshResponse.data['data']['token']['refresh_token'];

                await storage.write(key: 'access_token', value: newAccessToken);
                await storage.write(
                  key: 'refresh_token',
                  value: newRefreshToken,
                );

                e.requestOptions.headers['Authorization'] =
                    'Bearer $newAccessToken';

                final retryResponse = await dio.fetch(e.requestOptions);
                return handler.resolve(retryResponse);
              } catch (e) {}
            } else {
              await storage.deleteAll();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }
}
