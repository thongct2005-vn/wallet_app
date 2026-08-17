import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/core/network/api_error_handler.dart';

class PaymentService {
  final api = ApiClient().dio;
  Future<Map<String, dynamic>> getStaticQRToken() async {
    try {
      final result = await api.get(ApiConfig.createStaticQRToken);

      return {
        'is_success': true,
        'message': result.data['message'],
        'token': result.data['data'],
      };
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> getUserInfoByStaticQR(String token) async {
    try {
      final result = await api.get(
        ApiConfig.getUserInfoByStaticQR,
        queryParameters: {'static_qr_token': token},
      );

      return {
        'is_success': true,
        'message': result.data['message'],
        'user_info': result.data['data'],
      };
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> createDynamicQRToken(
    int amount,
    String description,
  ) async {
    try {
      final result = await api.post(
        ApiConfig.createDynamicQRToken,
        data: {'amount': amount, 'description': description},
      );
      return {
        'is_success': true,
        'message': result.data['message'],
        'token': result.data['data'],
      };
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> getUserInfoByDynamicQR(String token) async {
    try {
      final result = await api.get(
        ApiConfig.getDynamicQRToken,
        queryParameters: {'reference_code': token},
      );

      return {
        'is_success': true,
        'message': result.data['message'],
        'user_info': result.data['data'],
      };
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }
}
