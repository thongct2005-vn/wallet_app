import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';

class UserService {
  final api = ApiClient().dio;

  Future<bool> createPin(String pin) async {
    try {
      final result = await api.post(ApiConfig.createPin, data: {'pin': pin});
      if (result.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error createPin: $e');
      return false;
    }
  }

  Future<bool> checkPinStatus() async {
    try {
      final result = await api.get(ApiConfig.checkPinStatus);
      return result.data['data']['has_pin'] ?? false;
    } catch (e) {
      print('Error checkPinStatus: $e');
      return false;
    }
  }

}