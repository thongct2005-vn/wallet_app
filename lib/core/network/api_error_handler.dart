import 'dart:io';

import 'package:app/core/services/connectivity_service.dart';
import 'package:dio/dio.dart';

class ApiErrorHandler {
  static const String offlineMessage =
      'Không có kết nối internet. Vui lòng kiểm tra lại mạng và thử lại.';
  static const String timeoutMessage =
      'Kết nối quá hạn. Vui lòng kiểm tra lại mạng và thử lại.';
  static const String maintenanceMessage =
      'Hệ thống đang bảo trì. Vui lòng thử lại sau.';

  static bool isOfflineError(
    dynamic e, {
    bool? isConnectedOverride,
  }) {
    final connected =
        isConnectedOverride ?? ConnectivityService.instance.isConnected;
    if (!connected) return true;
    if (e is SocketException) return true;
    if (e is DioException && e.error is SocketException) return true;
    return false;
  }

  static String noResponseMessage({
    DioException? exception,
    bool? isConnectedOverride,
  }) {
    if (isOfflineError(
      exception,
      isConnectedOverride: isConnectedOverride,
    )) {
      return offlineMessage;
    }

    if (exception != null &&
        (exception.type == DioExceptionType.connectionTimeout ||
            exception.type == DioExceptionType.sendTimeout ||
            exception.type == DioExceptionType.receiveTimeout)) {
      return timeoutMessage;
    }

    return maintenanceMessage;
  }

  static Map<String, dynamic> handleError(
    dynamic e, {
    bool? isConnectedOverride,
  }) {
    if (e is DioException) {
      if (e.response == null) {
        final offline = isOfflineError(
          e,
          isConnectedOverride: isConnectedOverride,
        );
        return {
          'is_success': false,
          'is_offline': offline,
          'message': noResponseMessage(
            exception: e,
            isConnectedOverride: isConnectedOverride,
          ),
        };
      }

      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        return {'is_success': false, 'message': data['message']};
      }

      return {
        'is_success': false,
        'message': maintenanceMessage,
      };
    }

    if (isOfflineError(e, isConnectedOverride: isConnectedOverride)) {
      return {
        'is_success': false,
        'is_offline': true,
        'message': offlineMessage,
      };
    }

    return {
      'is_success': false,
      'message': 'Đã có lỗi xảy ra, vui lòng thử lại sau.',
    };
  }
}
