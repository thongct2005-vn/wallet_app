import 'dart:async';
import 'package:app/core/network/api_config.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/services/socket_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/main.dart';
import 'package:uuid/uuid.dart';

enum _RefreshStatus { refreshed, sessionExpired, transientError }

class _RefreshOutcome {
  final _RefreshStatus status;
  final String? accessToken;

  const _RefreshOutcome._(this.status, [this.accessToken]);

  const _RefreshOutcome.refreshed(String token)
      : this._(_RefreshStatus.refreshed, token);

  const _RefreshOutcome.sessionExpired()
      : this._(_RefreshStatus.sessionExpired);

  const _RefreshOutcome.transientError()
      : this._(_RefreshStatus.transientError);
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;
  final _storage = const FlutterSecureStorage();
  String? _cachedDeviceId;
  Future<String>? _deviceIdFuture;
  bool _isLoggingOut = false;

  static const Map<String, String> _ngrokHeaders = {
    'ngrok-skip-browser-warning': 'true',
    'User-Agent': 'LumaPayWallet/2.1.0 (Flutter)',
  };

  Completer<_RefreshOutcome>? _refreshCompleter;

  factory ApiClient() => _instance;

  Future<String> _getOrCreateDeviceId() {
    if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty) {
      return Future.value(_cachedDeviceId!);
    }
    return _deviceIdFuture ??= () async {
      try {
        String? stored = await _storage.read(key: 'device_id');
        if (stored == null || stored.isEmpty) {
          stored = 'dev-${const Uuid().v4()}';
          await _storage.write(key: 'device_id', value: stored);
        }
        _cachedDeviceId = stored;
        return stored;
      } finally {
        _deviceIdFuture = null;
      }
    }();
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
              e.requestOptions.extra['skipAuth'] == true ||
              e.requestOptions.extra['_authRetried'] == true ||
              e.requestOptions.path.contains('/auth/refresh-token')) {
            return handler.next(e);
          }

          final failedAuth = e.requestOptions.headers['Authorization']
              ?.toString();
          final failedToken =
              (failedAuth != null && failedAuth.startsWith('Bearer '))
              ? failedAuth.substring(7).trim()
              : null;

          final outcome = await _getValidAccessToken(
            failedAccessToken: failedToken,
          );

          if (outcome.status == _RefreshStatus.sessionExpired) {
            await _logout();
            return handler.next(e);
          }

          if (outcome.status != _RefreshStatus.refreshed ||
              outcome.accessToken == null) {
            return handler.next(e);
          }

          final requestOptions = e.requestOptions;
          requestOptions.extra['_authRetried'] = true;
          requestOptions.headers['Authorization'] =
              'Bearer ${outcome.accessToken}';

          try {
            final retryResponse = await dio.fetch(requestOptions);
            return handler.resolve(retryResponse);
          } on DioException catch (retryErr) {
            // Request retry thất bại do lỗi nghiệp vụ (409, 400, 404, 422, 5xx...)
            // không phải hết hạn phiên đăng nhập nên tuyệt đối không đăng xuất.
            if (retryErr.response?.statusCode == 401) {
              await _logout();
            }
            return handler.next(retryErr);
          } catch (_) {
            return handler.next(e);
          }
        },
      ),
    );
  }

  Future<_RefreshOutcome> _getValidAccessToken({
    String? failedAccessToken,
  }) async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<_RefreshOutcome>();
    _refreshCompleter = completer;

    try {
      final storedAccessToken = await _storage.read(key: 'access_token');
      if (storedAccessToken != null &&
          storedAccessToken.isNotEmpty &&
          failedAccessToken != null &&
          failedAccessToken.isNotEmpty &&
          storedAccessToken != failedAccessToken) {
        final outcome = _RefreshOutcome.refreshed(storedAccessToken);
        completer.complete(outcome);
        return outcome;
      }

      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        const outcome = _RefreshOutcome.sessionExpired();
        completer.complete(outcome);
        return outcome;
      }

      final deviceId = await _getOrCreateDeviceId();
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          headers: {..._ngrokHeaders, 'X-Device-Id': deviceId},
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final response = await refreshDio.post(
        ApiConfig.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final responseData = response.data;
      final dataMap = responseData is Map ? responseData['data'] : null;
      final tokenData = dataMap is Map ? dataMap['token'] : null;
      final newAccessToken = tokenData is Map
          ? tokenData['access_token']?.toString()
          : null;
      final newRefreshToken = tokenData is Map
          ? tokenData['refresh_token']?.toString()
          : null;

      if (newAccessToken == null ||
          newAccessToken.isEmpty ||
          newRefreshToken == null ||
          newRefreshToken.isEmpty) {
        const outcome = _RefreshOutcome.sessionExpired();
        completer.complete(outcome);
        return outcome;
      }

      await _storage.write(key: 'access_token', value: newAccessToken);
      await _storage.write(key: 'refresh_token', value: newRefreshToken);
      SocketService().syncAuthToken(newAccessToken).catchError((_) {});

      final outcome = _RefreshOutcome.refreshed(newAccessToken);
      completer.complete(outcome);
      return outcome;
    } on DioException catch (err) {
      final code = err.response?.statusCode;
      final outcome = (code == 401 || code == 403)
          ? const _RefreshOutcome.sessionExpired()
          : const _RefreshOutcome.transientError();
      completer.complete(outcome);
      return outcome;
    } catch (_) {
      const outcome = _RefreshOutcome.transientError();
      completer.complete(outcome);
      return outcome;
    } finally {
      if (identical(_refreshCompleter, completer)) {
        _refreshCompleter = null;
      }
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    try {
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
    } finally {
      _isLoggingOut = false;
    }
  }
}