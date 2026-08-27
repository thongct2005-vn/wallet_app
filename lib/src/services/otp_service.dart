import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/core/network/api_error_handler.dart';
import 'package:flutter/rendering.dart';

class OtpService {
  final api = ApiClient().dio;

  Future<Map<String, dynamic>> generateOtp({
    String? phone,
    String? email,
  }) async {
    try {
      final result = await api.post(
        ApiConfig.sendOtp,
        data: {'phone': ?phone, 'email': ?email},
      );

      debugPrint('${result.data}================');
      return {
        'is_success': true,
        'message': result.data['message'],
        'data': result.data['data'],
      };
    } catch (e) {
         debugPrint('$e================');
      return ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    String? phone,
    String? email,
    required String otp,
  }) async {
    try {
      final result = await api.post(
        ApiConfig.verifyOtp,
        data: {'phone': ?phone, 'email': ?email, 'otp': otp},
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
