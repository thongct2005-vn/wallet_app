import 'dart:async';
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

  Completer<String?>? _refreshCompleter;

  factory ApiClient() => _instance;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await _storage.read(key: 'access_token');
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode != 401) {
            return handler.next(e);
          }

          try {
      
            final newAccessToken = await _getValidAccessToken();

            if (newAccessToken == null) {
              await _logout();
              return handler.next(e);
            }

            e.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
            final retryResponse = await dio.fetch(e.requestOptions);
            return handler.resolve(retryResponse);
          } catch (err) {
            await _logout();
            return handler.next(e);
          }
        },
      ),
    );
  }

  Future<String?> _getValidAccessToken() async {
   
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        _refreshCompleter!.complete(null);
        return null;
      }

      final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
      final response = await refreshDio.post(
        ApiConfig.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['data']['token']['access_token'];
      final newRefreshToken = response.data['data']['token']['refresh_token'];

      await _storage.write(key: 'access_token', value: newAccessToken);
      await _storage.write(key: 'refresh_token', value: newRefreshToken);

      _refreshCompleter!.complete(newAccessToken);
      return newAccessToken;
    } catch (e) {
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _logout() async {
    await _storage.deleteAll();
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPhoneScreen()),
        (route) => false,
      );
    }
  }
}
