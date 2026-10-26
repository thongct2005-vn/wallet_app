import 'dart:io';

import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/core/network/api_error_handler.dart';
import 'package:app/src/auth/forgot/forgot_type.dart';
import 'package:dio/dio.dart';

class ForgotService {
  final api = ApiClient().dio;
  static const Duration _mailTimeout = Duration(seconds: 30);

  Options _opts({Map<String, String>? headers, Duration? timeout}) => Options(
    extra: {'skipAuth': true},
    headers: headers,
    receiveTimeout: timeout,
    sendTimeout: timeout,
  );

  Map<String, dynamic> _error(Object e) {
    final result = <String, dynamic>{...ApiErrorHandler.handleError(e)};
    if (e is DioException) {
      result['status_code'] = e.response?.statusCode;
    }
    return result;
  }

  Future<Map<String, dynamic>> request({
    required String phone,
    required ForgotType type,
  }) async {
    try {
      final result = await api.post(
        ApiConfig.forgotRequest,
        data: {'phone': phone, 'type': type.apiValue},
        options: _opts(timeout: _mailTimeout),
      );
      final data = result.data['data'];
      return {
        'is_success': true,
        'message': result.data['message'],
        'otp_token': data['otp_token'],
        'masked_email': data['masked_email'],
      };
    } catch (e) {
      return _error(e);
    }
  }

  Future<Map<String, dynamic>> resendOtp(String otpToken) async {
    try {
      final result = await api.post(
        ApiConfig.forgotResendOtp,
        data: {},
        options: _opts(
          headers: {'x-otp-token': otpToken},
          timeout: _mailTimeout,
        ),
      );
      return {'is_success': true, 'message': result.data['message']};
    } catch (e) {
      return _error(e);
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String otpToken,
    required String otp,
  }) async {
    try {
      final result = await api.post(
        ApiConfig.forgotVerifyOtp,
        data: {'otp': otp},
        options: _opts(headers: {'x-otp-token': otpToken}),
      );
      final data = result.data['data'];
      return {
        'is_success': true,
        'message': result.data['message'],
        'kyc_token': data['kyc_token'],
        'has_kyc': data['has_kyc'] == true,
      };
    } catch (e) {
      return _error(e);
    }
  }

  Future<Map<String, dynamic>> verifyKyc({
    required String kycToken,
    required File frontIdImage,
    required File backIdImage,
    required File faceImage,
  }) async {
    try {
      final formData = FormData.fromMap({
        'front_id': await MultipartFile.fromFile(frontIdImage.path),
        'back_id': await MultipartFile.fromFile(backIdImage.path),
        'face': await MultipartFile.fromFile(faceImage.path),
      });
      final result = await api.post(
        ApiConfig.forgotKyc,
        data: formData,
        options: _opts(
          headers: {'x-forgot-token': kycToken},
          timeout: const Duration(seconds: 90),
        ),
      );
      return {
        'is_success': true,
        'message': result.data['message'],
        'reset_token': result.data['data']['reset_token'],
      };
    } catch (e) {
      return _error(e);
    }
  }

  Future<Map<String, dynamic>> resetSecret({
    required ForgotType type,
    required String resetToken,
    required String value,
  }) async {
    try {
      final isPin = type == ForgotType.pin;
      final result = await api.patch(
        isPin ? ApiConfig.resetPin : ApiConfig.resetPassword,
        data: isPin ? {'pin': value} : {'password': value},
        options: _opts(headers: {'x-reset-token': resetToken}),
      );
      return {'is_success': true, 'message': result.data['message']};
    } catch (e) {
      return _error(e);
    }
  }
}