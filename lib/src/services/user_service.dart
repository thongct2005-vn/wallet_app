import 'dart:convert';
import 'package:app/core/controller/user_controller.dart';
import 'package:crypto/crypto.dart';
import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class UserService {
  final api = ApiClient().dio;

  String _hashPhone(String phone) {
    return sha256.convert(utf8.encode(phone)).toString();
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final result = await api.get(ApiConfig.getMe);
      if (result.statusCode == 200) {
        return {
          'is_success': true,
          'message': result.data['message'],
          'phone': result.data['data']['user_info']['phone'],
          'full_name': result.data['data']['user_info']['full_name'],
        };
      }
      return {'is_success': false, 'message': result.data['message']};
    } catch (e) {
      debugPrint('$e');
      return {
        'is_success': false,
        'message': "Lỗi xác thực danh tính. Vui lòng thử lại",
      };
    }
  }

  Future<bool> createPin(String pin) async {
    try {
      final result = await api.post(ApiConfig.createPin, data: {'pin': pin});
      if (result.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi tạo mã PIN: $e');
      return false;
    }
  }

  Future<bool> checkPinStatus() async {
    try {
      final result = await api.get(ApiConfig.checkPinStatus);
      return result.data['data']['has_pin'] ?? false;
    } catch (e) {
      debugPrint('Lỗi kiểm tra trạng thái pin: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchContactAndCheckAppUser() async {
    try {
      if (await Permission.contacts.request().isGranted) {
        List<Contact> contacts = await FlutterContacts.getAll(
          properties: {ContactProperty.phone},
        );

        final myPhone = Get.find<UserController>().phone.value;

        List<String> phoneNumbers = [];
        for (var contact in contacts) {
          if (contact.phones.isNotEmpty) {
            String rawPhone = contact.phones.first.number.replaceAll(
              RegExp(r'\D'),
              '',
            );
            if (rawPhone.startsWith('84')) {
              rawPhone = '0${rawPhone.substring(2)}';
            }
            if (rawPhone.length == 10) {
              phoneNumbers.add(rawPhone);
            }
          }
        }

        List<String> uniquePhones = phoneNumbers.toSet().toList();
        uniquePhones.remove(myPhone);
        List<String> hashedPhones = uniquePhones.map(_hashPhone).toList();

        List<dynamic> allFoundUsers = [];
        final api = ApiClient().dio;

        int chunkSize = 500;

        for (int i = 0; i < hashedPhones.length; i += chunkSize) {
          int end = (i + chunkSize < hashedPhones.length)
              ? i + chunkSize
              : hashedPhones.length;

          List<String> chunk = hashedPhones.sublist(i, end);

          try {
            final response = await api.post(
              ApiConfig.checkContact,
              data: {'phones': chunk},
            );

            final responseData = response.data;
            if (responseData != null && responseData['data'] != null) {
              allFoundUsers.addAll(responseData['data']);
            }
          } catch (apiError) {
            debugPrint('Lỗi khi gọi API chunk $i: $apiError');
            return {
              'success': false,
              'data': [],
              'message': "Có lỗi khi lấy danh sách",
            };
          }
        }

        return {
          'success': true,
          'data': allFoundUsers,
          'message': "Lấy danh sách thành công",
        };
      } else {
        return {
          'success': false,
          'data': [],
          'message': "Vui lòng cấp quyền đọc danh bạ",
        };
      }
    } catch (e) {
      debugPrint('Lỗi lấy danh sách người dùng từ danh bạ: $e');
      return {
        'success': false,
        'data': [],
        'message': "Có lỗi khi lấy danh sách",
      };
    }
  }

  Future<void> updateFcmToken(String token) async {
    try {
      api.patch(ApiConfig.updateFcmToken, data: {'fcm_token': token});
    } catch (e) {
      debugPrint('Lỗi cập nhật FCM token: $e');
    }
  }
}
