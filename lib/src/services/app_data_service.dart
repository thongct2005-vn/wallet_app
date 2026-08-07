import 'package:app/core/network/api_error_handler.dart';
import 'package:app/src/services/wallet_service.dart';
import 'package:app/src/services/user_service.dart';

class AppDataService {
  final WalletService _walletService = WalletService();
  final UserService _userService = UserService();

  Future<Map<String, dynamic>> fetchHomeData() async {
    try {
      final results = await Future.wait([
        _walletService.getWalletBalance(),
        _userService.checkPinStatus(),
      ]);

      final balanceResult = results[0] as Map<String, dynamic>;
      final hasPin = results[1] as bool;

      String balance = '0';
      if (balanceResult['is_success'] == true) {
        balance = balanceResult['balance'].toString();
      }

      return {
        'is_success': true,
        'balance': balance,
        'has_pin': hasPin,
      };
    } catch (e) {
     
      final errorResult = ApiErrorHandler.handleError(e);
      errorResult['balance'] = '0';
      errorResult['has_pin'] = false;
      return errorResult;
    }
  }
}