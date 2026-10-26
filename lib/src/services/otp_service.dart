import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/core/network/api_error_handler.dart';
import 'package:dio/dio.dart';

class OtpService {
  final api = ApiClient().dio;
  static const Duration _otpTimeout = Duration(seconds: 30);

  Options _opts({Map<String, String>? headers}) => Options(
    extra: {'skipAuth': true},
    headers: headers,
    receiveTimeout: _otpTimeout,
    sendTimeout: _otpTimeout,
  );

  Future<Map<String, dynamic>> generateOtp({
    String? phone,
    String? email,
  }) async {
    try {
      final result = await api.post(
        ApiConfig.sendOtp,
        data: {'phone': ?phone, 'email': ?email},
        options: _opts(),
      );

      return {
        'is_success': true,
        'message': result.data['message'],
        'data': result.data['data'],
      };
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    String? phone,
    String? email,
    String? otpToken,
    required String otp,
  }) async {
    try {
      final result = await api.post(
        ApiConfig.verifyOtp,
        data: {'phone': ?phone, 'email': ?email, 'otp': otp},
        options: _opts(
          headers: otpToken == null ? null : {'x-otp-token': otpToken},
        ),
      );
      return {
        'is_success': true,
        'message': result.data['message'],
        'data': result.data['data'],
      };
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }
}