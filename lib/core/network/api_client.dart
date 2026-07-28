import 'package:app/core/network/api_config.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/main.dart';
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;
  final _storage = const FlutterSecureStorage();
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
          String? accessToken = await _storage.read(key: 'access_token');
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
            String? refreshToken = await _storage.read(key: 'refresh_token');
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

                await _storage.write(key: 'access_token', value: newAccessToken);
                await _storage.write(
                  key: 'refresh_token',
                  value: newRefreshToken,
                );

                e.requestOptions.headers['Authorization'] =
                    'Bearer $newAccessToken';

                final retryResponse = await dio.fetch(e.requestOptions);
                return handler.resolve(retryResponse);
              } catch (e) {
                print(e);
                await _storage.deleteAll();

                if (navigatorKey.currentState != null) {
                  navigatorKey.currentState!.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPhoneScreen()),
                    (route) => false,
                  );
                }
              }
            } else {
              await _storage.deleteAll();
              if (navigatorKey.currentState != null) {
                  navigatorKey.currentState!.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPhoneScreen()),
                    (route) => false,
                  );
                }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }
}
