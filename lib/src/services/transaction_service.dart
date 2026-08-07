import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

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

      if (result.statusCode == 200) {
        return {
          'is_success': true,
          'message': result.data['message'],
          'data': result.data['data'],
        };
      }
      return {
        'is_success': false,
        'message': result.data['message'] ?? "Hệ thống đang bảo trì",
        'data': {},
      };
    } catch (e) {
      debugPrint('$e');
      return {
        'is_success': false,
        'message': "Hệ thống đang bảo trì",
        'data': {},
      };
    }
  }
}
