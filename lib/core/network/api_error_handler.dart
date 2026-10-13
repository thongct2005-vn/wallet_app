import 'package:dio/dio.dart';

class ApiErrorHandler {
  static Map<String, dynamic> handleError(dynamic e) {
    if (e is DioException) {
      if (e.response == null) {
        return {
          'is_success': false,
          'message': 'Hệ thống đang bảo trì. vui lòng thử lại sau.',
        };
      }

      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        return {'is_success': false, 'message': data['message']};
      }

      return {
        'is_success': false,
        'message': 'Hệ thống đang bảo trì, vui lòng thử lại sau.',
      };
    }
    return {
      'is_success': false,
      'message': 'Đã có lỗi xảy ra, vui lòng thử lại sau.',
    };
  }
}
