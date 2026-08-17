import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/core/network/api_error_handler.dart';

class BankService {
  final api = ApiClient().dio;
  Future<Map<String, dynamic>> getBankLinkStatus() async {
    try {
      final result = await api.get(ApiConfig.getBankLinkStatus);
      return {
        'is_success': true,
        'message': result.data['message'],
        'data': result.data['data'],
      };
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> linkBankAccount(String bankId) async {
    try {
      final result = await api.post(
        ApiConfig.linkBankAccount,
        data: {'bank_id': bankId},
      );
      return {'is_success': true, 'message': result.data['message']};
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }
}
