import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/core/network/api_error_handler.dart';
import 'package:dio/dio.dart';

class TransactionService {
  final api = ApiClient().dio;
  Future<Map<String, dynamic>> transferMoney(
    String destinationUserId,
    String amount,
    String description,
    String idempotencyKey,
  ) async {
    try {
      final result = await api.post(
        ApiConfig.transfer,
        data: {
          'destination_user_id': destinationUserId,
          'amount': amount,
          'description': description,
        },
        options: Options(headers: {'idempotency-key': idempotencyKey}),
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

  Future<Map<String, dynamic>> topupMoney(
    String amount,
    String linkedBankAccountId,
    String idempotencyKey,
  ) async {
    try {
      final result = await api.post(
        ApiConfig.topup,
        data: {
          'linked_bank_account_id': linkedBankAccountId,
          'amount': amount,
        },
        options: Options(headers: {'idempotency-key': idempotencyKey}),
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

  Future<Map<String, dynamic>> processQRPayment(
    String referenceCode,
    String idempotencyKey,
  ) async {
    try {
      final result = await api.post(
        ApiConfig.payment,
        data: {'reference_code': referenceCode},
        options: Options(headers: {'idempotency-key': idempotencyKey}),
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

  Future<Map<String, dynamic>> getTransferHistory(
    String? cursorId,
    int? limit,
  ) async {
    try {
      final result = await api.get(
        ApiConfig.history,
        queryParameters: {'cursor_id': cursorId, 'limit': limit},
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
