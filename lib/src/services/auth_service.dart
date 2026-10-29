import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/core/network/api_error_handler.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final api = ApiClient().dio;
  static const _storage = FlutterSecureStorage();

  Options get _public => Options(extra: {'skipAuth': true});

  // otp_token gửi qua header, không gửi trong body
  Options _withOtpToken(String otpToken) => Options(
    extra: {'skipAuth': true},
    headers: {'x-otp-token': otpToken},
  );

  Map<String, dynamic> _errorWithStatus(Object e) {
    final result = <String, dynamic>{...ApiErrorHandler.handleError(e)};
    if (e is DioException) {
      result['status_code'] = e.response?.statusCode;
    }
    return result;
  }

  Future<Map<String, dynamic>> checkPhoneExist(String phone) async {
    try {
      final result = await api.post(
        ApiConfig.checkPhoneExists,
        data: {'phone': phone},
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

  Future<Map<String, dynamic>> loginWithPhoneAndPassword(
    String phone,
    String password,
  ) async {
    try {
      final result = await api.post(
        ApiConfig.login,
        data: {'phone': phone, 'password': password},
        options: _public,
      );

      return {
        'is_success': true,
        'message': result.data['message'],
        'otp_token': result.data['data']['otp_token'],
        'masked_email': result.data['data']['masked_email'],
        // 'email' (mặc định) hoặc 'totp' khi tài khoản đã bật Google Authenticator
        'otp_method': result.data['data']['otp_method'] ?? 'email',
      };
    } catch (e) {
      return _errorWithStatus(e);
    }
  }

  Future<Map<String, dynamic>> verifyLoginOtp(
    String otpToken,
    String otp,
  ) async {
    try {
      final result = await api.post(
        ApiConfig.verifyLoginOtp,
        data: {'otp': otp},
        options: _withOtpToken(otpToken),
      );

      final data = result.data['data'];
      await _storage.write(
        key: 'access_token',
        value: data['token']['access_token'],
      );
      await _storage.write(
        key: 'refresh_token',
        value: data['token']['refresh_token'],
      );

      final user = data['user_info'];
      return {
        'is_success': true,
        'message': result.data['message'],
        'user_id': user['user_id'],
        'full_name': user['full_name'],
        'phone': user['phone'],
      };
    } catch (e) {
      return _errorWithStatus(e);
    }
  }

  // Lấy mã QR (otpauth uri) để thêm tài khoản vào Google Authenticator.
  // Server kiểm tra số điện thoại + mật khẩu; chưa bật chính thức cho tới khi
  // người dùng đăng nhập xong và nhập mã đầu tiên (enableTotp).
  Future<Map<String, dynamic>> setupTotp({
    required String phone,
    required String password,
  }) async {
    try {
      final result = await api.post(
        ApiConfig.totpSetup,
        data: {'phone': phone, 'password': password},
        options: _public,
      );
      final data = result.data['data'];
      return {
        'is_success': true,
        'message': result.data['message'],
        'otpauth_uri': data['otpauth_uri'],
        'secret': data['secret'],
      };
    } catch (e) {
      return _errorWithStatus(e);
    }
  }

  // Lấy lại mã QR đã liên kết (lỡ xoá mã trong Google Authenticator).
  // Cần đúng mật khẩu; server trả về khoá cũ chứ không tạo khoá mới.
  Future<Map<String, dynamic>> recoverTotp({
    required String phone,
    required String password,
  }) async {
    try {
      final result = await api.post(
        ApiConfig.totpRecover,
        data: {'phone': phone, 'password': password},
        options: _public,
      );
      final data = result.data['data'];
      return {
        'is_success': true,
        'message': result.data['message'],
        'otpauth_uri': data['otpauth_uri'],
        'secret': data['secret'],
      };
    } catch (e) {
      return _errorWithStatus(e);
    }
  }

  // Gọi sau khi đăng nhập (có access token): xác nhận mã đầu tiên để bật TOTP
  Future<Map<String, dynamic>> enableTotp(String code) async {
    try {
      final result = await api.post(ApiConfig.totpEnable, data: {'code': code});
      return {'is_success': true, 'message': result.data['message']};
    } catch (e) {
      return _errorWithStatus(e);
    }
  }

  // Gọi sau khi đăng nhập: tắt Google Authenticator, quay lại OTP qua email
  Future<Map<String, dynamic>> disableTotp() async {
    try {
      final result = await api.post(ApiConfig.totpDisable, data: {});
      return {'is_success': true, 'message': result.data['message']};
    } catch (e) {
      return _errorWithStatus(e);
    }
  }

  Future<Map<String, dynamic>> resendLoginOtp(String otpToken) async {
    try {
      final result = await api.post(
        ApiConfig.resendLoginOtp,
        data: {},
        options: _withOtpToken(otpToken),
      );
      return {'is_success': true, 'message': result.data['message']};
    } catch (e) {
      return _errorWithStatus(e);
    }
  }

  Future<Map<String, dynamic>> checkEmailExist(String email) async {
    try {
      final result = await api.post(
        ApiConfig.checkEmailExists,
        data: {'email': email},
        options: _public,
      );
      return {
        'is_success': true,
        'message': result.data['message'],
        'data': result.data['data'],
      };
    } catch (e) {
      return _errorWithStatus(e);
    }
  }

  Future<Map<String, dynamic>> registerWithEmail({
    required String otpToken,
    required String otp,
    required String password,
  }) async {
    try {
      final result = await api.post(
        ApiConfig.verifyRegister,
        data: {'otp': otp, 'password': password},
        options: _withOtpToken(otpToken),
      );

      final data = result.data['data'];
      await _storage.write(
        key: 'access_token',
        value: data['token']['access_token'],
      );
      await _storage.write(
        key: 'refresh_token',
        value: data['token']['refresh_token'],
      );

      final user = data['user_info'];
      return {
        'is_success': true,
        'message': result.data['message'],
        'user_id': user['user_id'],
        'email': user['email'],
        'phone': user['phone'],
      };
    } catch (e) {
      return _errorWithStatus(e);
    }
  }

  Future<Map<String, dynamic>> register(String phone, String email) async {
    try {
      final result = await api.post(
        ApiConfig.register,
        data: {'phone': phone, 'email': email},
        options: _public,
      );
      return {'is_success': true, 'message': result.data['message'], 'data':result.data['data']};
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final result = await api.post(ApiConfig.logout);
      return {'is_success': true, 'message': result.data['message']};
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }
}