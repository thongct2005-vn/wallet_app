import 'package:app/core/network/api_error_handler.dart';
import 'package:app/src/services/bank_service.dart';
import 'package:app/src/services/postpaid_service.dart';
import 'package:app/src/services/wallet_service.dart';

const int kMinBankTransactionAmount = 10000;

class TransferFundingResolution {
  final bool canProceed;
  final String initialFundingSource;
  final String? initialLinkedBankAccountId;
  final String walletBalance;
  final List<Map<String, dynamic>> linkedBanks;
  final String? errorMessage;

  const TransferFundingResolution({
    required this.canProceed,
    required this.initialFundingSource,
    required this.walletBalance,
    required this.linkedBanks,
    this.initialLinkedBankAccountId,
    this.errorMessage,
  });
}

num? parseLinkedBankBalance(Map<String, dynamic> bank) {
  if (bank['is_show_balance'] != true) return null;
  final raw = bank['balance'];
  if (raw == null) return null;
  return num.tryParse(raw.toString());
}

bool isLinkedBankSelectable(
  Map<String, dynamic> bank,
  num neededAmount, {
  num? transactionAmount,
}) {
  final effectiveAmount = transactionAmount ?? neededAmount;
  if (effectiveAmount < kMinBankTransactionAmount) return false;
  if (bank['is_show_balance'] != true) return true;
  final bal = parseLinkedBankBalance(bank);
  return bal != null && bal >= neededAmount;
}

TransferFundingResolution resolveTransferFundingOption({
  required bool walletEligible,
  required String walletBalance,
  required num neededAmount,
  required List<Map<String, dynamic>> linkedBanks,
  bool postpaidEligible = false,
  num? transactionAmount,
}) {
  if (walletEligible) {
    return TransferFundingResolution(
      canProceed: true,
      initialFundingSource: 'MAIN_WALLET',
      walletBalance: walletBalance,
      linkedBanks: linkedBanks,
    );
  }

  if (postpaidEligible) {
    return TransferFundingResolution(
      canProceed: true,
      initialFundingSource: 'POSTPAID',
      walletBalance: walletBalance,
      linkedBanks: linkedBanks,
    );
  }

  final effectiveTxAmount = transactionAmount ?? neededAmount;
  final bankAmountAllowed = effectiveTxAmount >= kMinBankTransactionAmount;

  if (bankAmountAllowed) {
    String? visibleEnoughId;
    String? unshownId;
    for (final bank in linkedBanks) {
      final id = bank['id']?.toString();
      if (id == null || id.isEmpty) continue;
      if (bank['is_show_balance'] == true) {
        final bal = parseLinkedBankBalance(bank);
        if (bal != null && bal >= neededAmount && visibleEnoughId == null) {
          visibleEnoughId = id;
        }
      } else {
        unshownId ??= id;
      }
    }

    final fallbackBankId = visibleEnoughId ?? unshownId;
    if (fallbackBankId != null) {
      return TransferFundingResolution(
        canProceed: true,
        initialFundingSource: 'BANK',
        initialLinkedBankAccountId: fallbackBankId,
        walletBalance: walletBalance,
        linkedBanks: linkedBanks,
      );
    }
  }

  return TransferFundingResolution(
    canProceed: false,
    initialFundingSource: 'MAIN_WALLET',
    walletBalance: walletBalance,
    linkedBanks: linkedBanks,
    errorMessage: !bankAmountAllowed && linkedBanks.isNotEmpty
        ? 'Số dư trong ví không đủ (giao dịch qua ngân hàng liên kết tối thiểu 10.000đ)'
        : 'Số dư trong ví không đủ',
  );
}

Future<TransferFundingResolution> evaluateTransferFundingBeforeConfirm({
  required WalletService walletService,
  required BankService bankService,
  PostpaidService? postpaidService,
  required String rawAmount,
  required num neededAmount,
  required bool isQrPayment,
  bool isMerchant = false,
  num? transactionAmount,
}) async {
  final result = await walletService.checkTransferEligibility(rawAmount);
  if (result['is_success'] != true) {
    return TransferFundingResolution(
      canProceed: false,
      initialFundingSource: 'MAIN_WALLET',
      walletBalance: '0',
      linkedBanks: const [],
      errorMessage:
          result['message']?.toString() ?? ApiErrorHandler.noResponseMessage(),
    );
  }

  final walletBalance = result['wallet_balance']?.toString() ?? '0';
  final walletEligible = result['is_eligible'] == true;

  List<Map<String, dynamic>> linkedBanks = const [];
  final bankRes = await bankService.getBankLinkStatus();
  if (bankRes['is_success'] == true && bankRes['data'] is Map) {
    final accounts = (bankRes['data'] as Map)['linked_accounts'];
    if (accounts is List) {
      linkedBanks = accounts
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }

  bool canUsePostpaid = false;
  if (!walletEligible && isQrPayment && isMerchant) {
    final ppRes = await (postpaidService ?? PostpaidService()).getWallet();
    final ppData = ppRes['is_success'] == true && ppRes['data'] is Map
        ? ppRes['data'] as Map
        : null;
    canUsePostpaid =
        ppData != null &&
        ppData['activated'] == true &&
        ppData['status'] == 'ACTIVE' &&
        (num.tryParse(ppData['available_limit']?.toString() ?? '0') ?? 0) >=
            neededAmount;
  }

  return resolveTransferFundingOption(
    walletEligible: walletEligible,
    walletBalance: walletBalance,
    neededAmount: neededAmount,
    linkedBanks: linkedBanks,
    postpaidEligible: canUsePostpaid,
    transactionAmount: transactionAmount ?? neededAmount,
  );
}
