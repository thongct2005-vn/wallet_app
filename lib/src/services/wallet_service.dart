import 'dart:math';

import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_config.dart';
import 'package:app/core/utils/format_utils.dart';

class WalletService {
  final api = ApiClient().dio;

  Future<Map<String, dynamic>> getWalletBalance() async {
    try {
      final result = await api.get(ApiConfig.getWalletBalance);
      final balance = result.data['data']['balance'];
      final numBalance = num.tryParse(balance.toString());
      final formattedBalance =
          '${FormatUtils.formatDisplayNumber(numBalance ?? 0)}đ';

      return {
        'is_success': true,
        'message': result.data['message'],
        'balance': formattedBalance,
      };
    } catch (e) {
      print('$e');
      return {'is_success': false};
    }
  }

  Future<Map<String, dynamic>> checkTransferEligibility(String amount) async {
    try {
      final numAmount = FormatUtils.formatAmountToNum(amount);
      final result = await api.post(
        ApiConfig.checkTransfer,

        data: {'amount': numAmount},
      );
      final data = result.data['data'];

      return {
        'is_eligible': data['is_eligible'],
        'wallet_balance': data['wallet_balance'],
        'has_error': false,
      };
    } catch (e) {
      print(e);
      return {'has_error': true};
    }
  }

  Future<Map<String, dynamic>> checkPin(String pin) async {
    try {
      final result = await api.post(ApiConfig.checkPin, data: {'pin': pin});
      final data = result.data['data'];
      return {
        'is_correct':data['is_correct'],
        'has_error':false
      };
    } catch (e) {
      print(e);
      return{
        'has_error':true
      };
    }
  }
}
