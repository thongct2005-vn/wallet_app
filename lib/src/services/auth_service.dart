import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/core/network/api_error_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';



class AuthService {
  final api = ApiClient().dio;
  static const _storage = FlutterSecureStorage();
  Future<Map<String, dynamic>> checkPhoneExist(String phone) async {
    try {
      final result = await api.post(
        ApiConfig.checkPhoneExists,
        data: {'phone': phone},
      );
      return {
        'is_success': true,
        'data': result.data['data'], 
      };
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final result = await api.post(ApiConfig.sendOtp, data: {'phone': phone});
       return {
        'is_success': true,
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
      );
     

      final data = result.data;
       debugPrint('$data');
      final accessToken = data['data']['token']['access_token'];
      final refreshToken = data['data']['token']['refresh_token'];
      final fullName = data['data']['user_info']['full_name'];
      final phoneResponse = data['data']['user_info']['phone'];
      final userId = data['data']['user_info']['user_id'];
      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);

      return {
        'is_success': true,
        'message': data['message'],
        'user_id':userId,
        'full_name': fullName,
        'phone':phoneResponse
      };
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> logout() async{
    try {
      final result = await api.post(
        ApiConfig.logout
      );
      return {
        'is_success': true,
        'message':result.data['message'], 
      };
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }
  
}
