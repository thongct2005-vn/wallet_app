import 'dart:io';

import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/core/network/api_error_handler.dart';
import 'package:dio/dio.dart';

class PostpaidService {
  final api = ApiClient().dio;

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
    String? direction,
    int? minAmount,
    int? maxAmount,
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
          if (direction != null && direction.isNotEmpty)
            'direction': direction,
          'min_amount': ?minAmount,
          'max_amount': ?maxAmount,
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

  Future<Map<String, dynamic>> exportEntriesToEmail({
    required DateTime startDate,
    required DateTime endDate,
    String? keyword,
  }) async {
    try {
      final result = await api.post(
        ApiConfig.postpaidExportEmail,
        data: {
          'start_date': _dateOnly(startDate),
          'end_date': _dateOnly(endDate),
          if (keyword != null && keyword.trim().isNotEmpty)
            'keyword': keyword.trim(),
        },
        options: Options(receiveTimeout: const Duration(seconds: 30)),
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
  }) => _postWithPinToken(
    ApiConfig.postpaidRepay,
    idempotencyKey: idempotencyKey,
    pinToken: pinToken,
    data: {
      'amount': amount,
      if (fundingSource != 'MAIN_WALLET') 'funding_source': fundingSource,
      if (linkedBankAccountId != null && linkedBankAccountId.isNotEmpty)
        'linked_bank_account_id': linkedBankAccountId,
    },
  );

  Future<Map<String, dynamic>> getLatestUnlockRequest() async {
    try {
      final result = await api.get(ApiConfig.postpaidLatestUnlockRequest);
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
    required List<File> proofImages,
    String? userNote,
  }) async {
    if (proofImages.isEmpty || proofImages.length > 3) {
      return {
        'is_success': false,
        'message': 'Vui lòng chọn từ 1 đến 3 ảnh chứng minh thu nhập',
      };
    }

    try {
      final multipartFiles = <MultipartFile>[];
      for (var i = 0; i < proofImages.length; i++) {
        final file = proofImages[i];
        if (!file.existsSync()) {
          return {
            'is_success': false,
            'message': 'Tệp ảnh thứ ${i + 1} không tồn tại, vui lòng chọn lại',
          };
        }
        final bytes = file.lengthSync();
        if (bytes > 8 * 1024 * 1024) {
          return {
            'is_success': false,
            'message': 'Mỗi ảnh chứng minh thu nhập không được vượt quá 8MB',
          };
        }
        final lowerPath = file.path.toLowerCase();
        final isPng = lowerPath.endsWith('.png');
        final fileName = 'proof_${i + 1}.${isPng ? 'png' : 'jpg'}';
        multipartFiles.add(
          await MultipartFile.fromFile(
            file.path,
            filename: fileName,
            contentType: DioMediaType('image', isPng ? 'png' : 'jpeg'),
          ),
        );
      }

      final cleanNote = userNote?.trim() ?? '';
      final formData = FormData.fromMap({
        'proof_images': multipartFiles,
        if (cleanNote.isNotEmpty) 'user_note': cleanNote,
      });

      final result = await api.post(
        ApiConfig.postpaidUnlockRequests,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
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
}

