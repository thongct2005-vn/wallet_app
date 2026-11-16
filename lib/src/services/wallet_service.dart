import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/core/network/api_error_handler.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:dio/dio.dart';

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
       return ApiErrorHandler.handleError(e);
    }
  }

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
        'challenge_required': data['challenge_required'] == true,
        'challenge_token': data['challenge_token'],
        'otp_method': data['otp_method'],
        'masked_email': data['masked_email'],
        'is_success': true,
      };
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifyPinChallenge({
    required String challengeToken,
    required String otp,
  }) async {
    try {
      final result = await api.post(
        ApiConfig.verifyPinChallenge,
        data: {'otp': otp},
        options: Options(headers: {'x-otp-token': challengeToken}),
      );
      final data = result.data['data'];
      return {
        'is_success': true,
        'is_correct': data['is_correct'],
        'pin_token': data['pin_token'],
      };
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> resendPinChallenge({
    required String challengeToken,
  }) async {
    try {
      final result = await api.post(
        ApiConfig.resendPinChallenge,
        options: Options(headers: {'x-otp-token': challengeToken}),
      );
      final data = result.data['data'];
      return {
        'is_success': true,
        'message': result.data['message'],
        'masked_email': data?['masked_email'],
      };
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }
}