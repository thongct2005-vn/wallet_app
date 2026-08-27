import 'dart:io';

import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/core/network/api_error_handler.dart';
import 'package:dio/dio.dart';

class KYCService {
  final api = ApiClient().dio;
  Future<Map<String, dynamic>> checkUserKYC() async {
    try {
      final result = await api.get(ApiConfig.checkUserKYC);
      return {
        'is_success': true,
        'message': result.data['message'],
        'data': result.data['data'],
      };
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifyKYC(
    File frontIdImage,
    File backIdImage,
    File faceImage,
  ) async {
    try {
      FormData formData = FormData.fromMap({
        'front_id': await MultipartFile.fromFile(frontIdImage.path),
        'back_id': await MultipartFile.fromFile(backIdImage.path),
        'face': await MultipartFile.fromFile(faceImage.path),
      });

      final result = await api.post(ApiConfig.verifyKYC, data: formData);

      return {'is_success': true, 'message': result.data['message']};
    } catch (e) {
      return ApiErrorHandler.handleError(e);
    }
  }
}
