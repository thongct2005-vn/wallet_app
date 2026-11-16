import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/core/network/api_error_handler.dart';
import 'package:dio/dio.dart';

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

  Future<Map<String, dynamic>> linkBankAccount(
    String bankId,
    String idempotencyKey,
    String pinToken,
  ) async {
    try {
      final result = await api.post(
        ApiConfig.linkBankAccount,
        data: {'bank_id': bankId},
        options: Options(
          headers: {
            'idempotency-key': idempotencyKey,
            'x-pin-token': pinToken,
          },
        ),
      );
      return {'is_success': true, 'message': result.data['message']};
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> enableShowBalance(
    String linkedBankAccountId,
    String idempotencyKey,
    String pinToken,
  ) async {
    try {
      final result = await api.patch(
        ApiConfig.enableBankShowBalance,
        data: {'linked_bank_account_id': linkedBankAccountId},
        options: Options(
          headers: {
            'idempotency-key': idempotencyKey,
            'x-pin-token': pinToken,
          },
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

  Future<Map<String, dynamic>> hideBalance(String linkedBankAccountId) async {
    try {
      final result = await api.patch(
        ApiConfig.hideBankBalance,
        data: {'linked_bank_account_id': linkedBankAccountId},
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

  Future<Map<String, dynamic>> unlinkBankAccount(
    String linkedBankAccountId,
    String idempotencyKey,
    String pinToken,
  ) async {
    try {
      final result = await api.post(
        ApiConfig.unlinkBankAccount,
        data: {'linked_bank_account_id': linkedBankAccountId},
        options: Options(
          headers: {
            'idempotency-key': idempotencyKey,
            'x-pin-token': pinToken,
          },
        ),
      );
      return {
        'is_success': true,
        'message': result.data['message'],
      };
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }
}