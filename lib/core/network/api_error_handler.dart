import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

class ApiErrorHandler {
  static Map<String, dynamic> handleError(dynamic e) {
    if (e is DioException) {
      if (e.response != null && e.response?.data != null) {
        final message = e.response?.data['message'] ?? 'Máy chủ đang bảo trì';
        return {'is_success': false, 'message': message};
      }
      return {
        'is_success': false,
        'message': 'Lỗi kết nối mạng',
      };
    }

    debugPrint('Lỗi: $e');
    return {
      'is_success': false,
      'message': 'Đã có lỗi xảy ra, vui lòng thử lại sau.',
    };
  }
}
