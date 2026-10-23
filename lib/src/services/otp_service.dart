import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/core/network/api_error_handler.dart';
import 'package:dio/dio.dart';

class OtpService {
  final api = ApiClient().dio;

  Options get _public => Options(extra: {'skipAuth': true});

  Future<Map<String, dynamic>> generateOtp({
    String? phone,
    String? email,
  }) async {
    try {
      final result = await api.post(
        ApiConfig.sendOtp,
        data: {'phone': ?phone, 'email': ?email},
        options: _public,
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
        options: otpToken == null
            ? _public
            : Options(
                extra: {'skipAuth': true},
                headers: {'x-otp-token': otpToken},
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