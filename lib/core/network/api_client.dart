import 'dart:async';
import 'package:app/core/network/api_config.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/services/socket_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/main.dart';
import 'package:uuid/uuid.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;
  final _storage = const FlutterSecureStorage();
  String? _cachedDeviceId;

  static const Map<String, String> _ngrokHeaders = {
    'ngrok-skip-browser-warning': 'true',
    'User-Agent': 'MioWallet/2.1.0 (Flutter)',
  };

  Completer<String?>? _refreshCompleter;

  factory ApiClient() => _instance;

  Future<String> _getOrCreateDeviceId() async {
    if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty) {
      return _cachedDeviceId!;
    }
    String? stored = await _storage.read(key: 'device_id');
    if (stored == null || stored.isEmpty) {
      stored = 'dev-${const Uuid().v4()}';
      await _storage.write(key: 'device_id', value: stored);
    }
    _cachedDeviceId = stored;
    return stored;
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: _ngrokHeaders,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final deviceId = await _getOrCreateDeviceId();
          options.headers['X-Device-Id'] = deviceId;
          if (options.extra['skipAuth'] != true) {
            final accessToken = await _storage.read(key: 'access_token');
            if (accessToken != null) {
              options.headers['Authorization'] = 'Bearer $accessToken';
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode != 401 ||
              e.requestOptions.extra['skipAuth'] == true) {
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

      final refreshDio = Dio(
        BaseOptions(baseUrl: dio.options.baseUrl, headers: _ngrokHeaders),
      );
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
    SocketService().disconnect();
    final deviceId = await _storage.read(key: 'device_id');
    await _storage.deleteAll();
    if (deviceId != null && deviceId.isNotEmpty) {
      await _storage.write(key: 'device_id', value: deviceId);
    }
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPhoneScreen()),
        (route) => false,
      );
    }
  }
}