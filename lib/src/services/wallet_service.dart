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

  /// [action] và [params] cho server biết PIN này xác nhận giao dịch nào, để pin_token
  /// chỉ dùng được cho đúng giao dịch đó (đổi số tiền/người nhận sẽ bị từ chối):
  ///   TRANSFER   -> destination_user_id, amount
  ///   TOPUP / WITHDRAW -> linked_bank_account_id, amount
  ///   QR_PAYMENT -> reference_code
  ///   BANK_LINK  -> bank_id
  Future<Map<String, dynamic>> checkPin(
    String pin,
    String idempotencyKey, {
    required String action,
    required Map<String, dynamic> params,
  }) async {
    try {
      final result = await api.post(
        ApiConfig.checkPin,
        data: {
          'pin': pin,
          'idempotency_key': idempotencyKey,
          'action': action,
          'params': params,
        },
      );
      final data = result.data['data'];
      return {
        'is_correct': data['is_correct'],
        'pin_token': data['pin_token'],
        'remaining_attempts': data['remaining_attempts'],
        'is_success': true,
      };
    } catch (e) {
      debugPrint('Lỗi kiểm tra PIN: $e');
      return ApiErrorHandler.handleError(e);
    }
  }
}