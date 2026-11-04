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
    String pinToken,
  ) async {
    try {
      final result = await api.post(
        ApiConfig.transfer,
        data: {
          'destination_user_id': destinationUserId,
          'amount': amount,
          'description': description,
        },
        options: Options(
          headers: {'idempotency-key': idempotencyKey, 'x-pin-token': pinToken},
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

  Future<Map<String, dynamic>> topupMoney(
    String amount,
    String linkedBankAccountId,
    String idempotencyKey,
    String pinToken,
  ) async {
    try {
      final result = await api.post(
        ApiConfig.topup,
        data: {'linked_bank_account_id': linkedBankAccountId, 'amount': amount},
        options: Options(
          headers: {'idempotency-key': idempotencyKey, 'x-pin-token': pinToken},
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

  Future<Map<String, dynamic>> withdrawMoney(
    String amount,
    String linkedBankAccountId,
    String idempotencyKey,
    String pinToken,
  ) async {
    try {
      final result = await api.post(
        ApiConfig.withdraw,
        data: {'linked_bank_account_id': linkedBankAccountId, 'amount': amount},
        options: Options(
          headers: {'idempotency-key': idempotencyKey, 'x-pin-token': pinToken},
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

  Future<Map<String, dynamic>> processQRPayment(
    String referenceCode,
    String idempotencyKey,
    String pinToken,
  ) async {
    try {
      final result = await api.post(
        ApiConfig.payment,
        data: {'reference_code': referenceCode},
        options: Options(
          headers: {'idempotency-key': idempotencyKey, 'x-pin-token': pinToken},
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

  Future<Map<String, dynamic>> getTransferHistory(
    String? cursorId,
    int? limit, {
    String? keyword,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = await api.get(
        ApiConfig.history,
        queryParameters: {
          'cursor_id': cursorId,
          'limit': limit,
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          if (startDate != null) 'start_date': _dateOnly(startDate),
          if (endDate != null) 'end_date': _dateOnly(endDate),
        },
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

  Future<Map<String, dynamic>> getCurrentMonthSummary() async {
  try {
    final result = await api.get(ApiConfig.historySummary);
    return {
      'is_success': true,
      'message': result.data['message'],
      'data': result.data['data'],
    };
  } catch (e) {
    return ApiErrorHandler.handleError(e);
  }
}

  /// Server chỉ nhận ngày dạng YYYY-MM-DD (giờ Việt Nam)
  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Yêu cầu server tạo file Excel và gửi đến email đã đăng ký.
  /// Thành công: data = {'email': <email đã che>, 'row_count': <số giao dịch>}
  Future<Map<String, dynamic>> exportHistoryToEmail({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final result = await api.post(
        ApiConfig.historyExportEmail,
        data: {
          'start_date': _dateOnly(startDate),
          'end_date': _dateOnly(endDate),
        },
        // Tạo file và gửi mail có thể lâu hơn mức 5 giây mặc định của ApiClient
        options: Options(receiveTimeout: const Duration(seconds: 40)),
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