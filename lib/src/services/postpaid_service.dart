import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/core/network/api_error_handler.dart';
import 'package:dio/dio.dart';

class PostpaidService {
  PostpaidService({Dio? api}) : api = api ?? ApiClient().dio;

  final Dio api;

  Future<Map<String, dynamic>> getWalletInfo() async {
    try {
      final result = await api.get(ApiConfig.postpaidInfo);
      return {
        'is_success': true,
        'message': result.data['message'],
        'data': result.data['data'],
      };
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> getWallet() async {
    try {
      final result = await api.get(ApiConfig.postpaidWallet);
      return {
        'is_success': true,
        'message': result.data['message'],
        'data': result.data['data'],
      };
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> _postWithPinToken(
    String url, {
    required String idempotencyKey,
    required String pinToken,
    Map<String, dynamic> data = const <String, dynamic>{},
  }) async {
    try {
      final result = await api.post(
        url,
        data: data,
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

  Future<Map<String, dynamic>> activate({
    required String idempotencyKey,
    required String pinToken,
  }) => _postWithPinToken(
    ApiConfig.postpaidActivate,
    idempotencyKey: idempotencyKey,
    pinToken: pinToken,
  );

  Future<Map<String, dynamic>> freezeWallet({
    required String idempotencyKey,
    required String pinToken,
  }) => _postWithPinToken(
    ApiConfig.postpaidFreeze,
    idempotencyKey: idempotencyKey,
    pinToken: pinToken,
  );

  Future<Map<String, dynamic>> unfreezeWallet({
    required String idempotencyKey,
    required String pinToken,
  }) => _postWithPinToken(
    ApiConfig.postpaidUnfreeze,
    idempotencyKey: idempotencyKey,
    pinToken: pinToken,
  );

  Future<Map<String, dynamic>> closeWallet({
    required String idempotencyKey,
    required String pinToken,
    String? reason,
  }) {
    final trimmedReason = reason?.trim();
    return _postWithPinToken(
      ApiConfig.postpaidClose,
      idempotencyKey: idempotencyKey,
      pinToken: pinToken,
      data: trimmedReason != null && trimmedReason.isNotEmpty
          ? {'reason': trimmedReason}
          : const <String, dynamic>{},
    );
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<Map<String, dynamic>> getEntries({
    String? cursorId,
    int limit = 20,
    String? keyword,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = await api.get(
        ApiConfig.postpaidEntries,
        queryParameters: {
          if (cursorId != null && cursorId.isNotEmpty) 'cursor_id': cursorId,
          'limit': limit,
          if (keyword != null && keyword.trim().isNotEmpty)
            'keyword': keyword.trim(),
          if (action != null && action.isNotEmpty) 'action': action,
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

  Future<Map<String, dynamic>> repayDebt({
    required int amount,
    required String idempotencyKey,
    required String pinToken,
    String fundingSource = 'MAIN_WALLET',
    String? linkedBankAccountId,
  }) async {
    try {
      final normalizedFunding = fundingSource.trim().toUpperCase();
      final payload = <String, dynamic>{
        'amount': amount,
        'funding_source': normalizedFunding,
        if (normalizedFunding == 'BANK' &&
            linkedBankAccountId != null &&
            linkedBankAccountId.trim().isNotEmpty)
          'linked_bank_account_id': linkedBankAccountId.trim(),
      };
      final result = await api.post(
        ApiConfig.postpaidRepay,
        data: payload,
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

  Future<Map<String, dynamic>> getLatestUnlockRequest() async {
    try {
      final result = await api.get(ApiConfig.postpaidUnlockRequestsLatest);
      return {
        'is_success': true,
        'message': result.data['message'],
        'data': result.data['data'],
      };
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> submitUnlockRequest({
    required List<String> filePaths,
    String? userNote,
  }) async {
    try {
      final files = <MultipartFile>[];
      for (final p in filePaths) {
        files.add(await MultipartFile.fromFile(p));
      }

      final map = <String, dynamic>{
        'proof_images': files,
        if (userNote != null && userNote.trim().isNotEmpty)
          'user_note': userNote.trim(),
      };
      final formData = FormData.fromMap(map);

      final result = await api.post(
        ApiConfig.postpaidUnlockRequests,
        data: formData,
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
