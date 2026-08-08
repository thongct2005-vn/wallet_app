import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/core/network/api_error_handler.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:flutter/cupertino.dart';

class WalletService {
  final api = ApiClient().dio;

  Future<Map<String, dynamic>> getWalletBalance() async {
    try {
      final result = await api.get(ApiConfig.getWalletBalance);
      final balance = result.data['data']['balance'];
 

      return {
        'is_success': true,
        'message': result.data['message'],
        'balance': balance,
      };
    } catch (e) {
      debugPrint('Lỗi lấy số dư ví: $e');
      return ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> checkTransferEligibility(String amount) async {
    try {
      final numAmount = FormatUtils.formatAmountToNum(amount);
      final result = await api.post(
        ApiConfig.checkTransfer,

        data: {'amount': numAmount},
      );
      final data = result.data['data'];

      return {
        'is_eligible': data['is_eligible'],
        'wallet_balance': data['wallet_balance'],
        'is_success': true,
      };
    } catch (e) {
      debugPrint('Lỗi kiểm tra số dư: $e');
       return ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> checkPin(String pin) async {
    try {
      final result = await api.post(ApiConfig.checkPin, data: {'pin': pin});
      final data = result.data['data'];
      return {'is_correct': data['is_correct'], 'is_success': false};
    } catch (e) {
      debugPrint('Lỗi kiểm tra PIN: $e');
      return ApiErrorHandler.handleError(e);
    }
  }
}
