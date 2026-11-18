import 'package:app/core/utils/format_utils.dart';
import 'package:app/src/transfer/transfer_funding_helper.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class PayNowFundingSelector extends StatelessWidget {
  final num mainBalance;
  final num totalPay;
  final num? transactionAmount;
  final String fundingSource;
  final String? selectedLinkedBankAccountId;
  final List<Map<String, dynamic>> linkedBanks;
  final bool isLoadingBanks;
  final VoidCallback onSelectMainWallet;
  final ValueChanged<String> onSelectBank;
  final List<Widget> extraSections;

  const PayNowFundingSelector({
    super.key,
    required this.mainBalance,
    required this.totalPay,
    this.transactionAmount,
    required this.fundingSource,
    required this.selectedLinkedBankAccountId,
    required this.linkedBanks,
    required this.isLoadingBanks,
    required this.onSelectMainWallet,
    required this.onSelectBank,
    this.extraSections = const [],
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTxAmount = transactionAmount ?? totalPay;
    final bankAmountAllowed = effectiveTxAmount >= kMinBankTransactionAmount;
    final mainSelected = fundingSource == 'MAIN_WALLET';
    final mainEnough = mainBalance >= totalPay;

    final Widget mainWalletCard = Opacity(
      opacity: mainEnough ? 1.0 : 0.48,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: mainEnough ? onSelectMainWallet : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: mainSelected
                ? kTfPink.withValues(alpha: 0.05)
                : Colors.grey.shade50,
            border: Border.all(
              width: mainSelected ? 1.5 : 1,
              color: mainSelected
                  ? kTfPink
                  : Colors.grey.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: [
              Container(
                alignment: Alignment.center,
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: kTfPink,
                ),
                child: Text(
                  'Mio',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ví Mio',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: kTfMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${FormatUtils.formatDisplayNumber(mainBalance)}đ',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: kTfText,
                      ),
                    ),
                  ],
                ),
              ),
              SourceRadioDot(selected: mainSelected),
            ],
          ),
        ),
      ),
    );

    final List<Widget> eligiblePayNowOptions = [];
    final List<Widget> insufficientPayNowOptions = [];

    if (mainEnough) {
      eligiblePayNowOptions.add(mainWalletCard);
    } else {
      insufficientPayNowOptions.add(mainWalletCard);
    }

    for (final bank in linkedBanks) {
      final optionWidget = _buildLinkedBankOption(bank, effectiveTxAmount);
      if (isLinkedBankSelectable(
        bank,
        totalPay,
        transactionAmount: effectiveTxAmount,
      )) {
        eligiblePayNowOptions.add(optionWidget);
      } else {
        insufficientPayNowOptions.add(optionWidget);
      }
    }

    final List<Widget> orderedPayNowOptions = [
      ...eligiblePayNowOptions,
      ...insufficientPayNowOptions,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: transferCardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
            child: Text(
              "Trả ngay",
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: kTfText,
              ),
            ),
          ),
          for (int i = 0; i < orderedPayNowOptions.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            orderedPayNowOptions[i],
          ],
          if (!bankAmountAllowed && linkedBanks.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Ngân hàng liên kết áp dụng cho giao dịch từ 10.000đ',
                style: GoogleFonts.roboto(
                  fontSize: 12.5,
                  color: kTfMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          if (isLoadingBanks && linkedBanks.isEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                'Đang tải ngân hàng liên kết...',
                style: GoogleFonts.roboto(fontSize: 13, color: kTfMuted),
              ),
            ),
          ],
          ...extraSections,
        ],
      ),
    );
  }

  Widget _buildLinkedBankOption(Map<String, dynamic> bank, num effectiveTxAmount) {
    final bankId = bank['id']?.toString() ?? '';
    final bankName = bank['bank_name']?.toString() ?? 'Ngân hàng liên kết';
    final logoUrl = bank['logo_url']?.toString() ?? '';
    final isShowBalance = bank['is_show_balance'] == true;
    final bankBalance = parseLinkedBankBalance(bank);
    final bankEnough = isLinkedBankSelectable(
      bank,
      totalPay,
      transactionAmount: effectiveTxAmount,
    );
    final bankSelected =
        fundingSource == 'BANK' && selectedLinkedBankAccountId == bankId;

    final String subtitleText;
    if (isShowBalance && bankBalance != null) {
      subtitleText = 'Số dư: ${FormatUtils.formatDisplayNumber(bankBalance)}đ';
    } else {
      subtitleText = 'Tài khoản ngân hàng liên kết';
    }

    return Opacity(
      opacity: bankEnough ? 1.0 : 0.48,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: bankEnough ? () => onSelectBank(bankId) : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: bankSelected
                ? kTfPink.withValues(alpha: 0.05)
                : Colors.grey.shade50,
            border: Border.all(
              width: bankSelected ? 1.5 : 1,
              color: bankSelected
                  ? kTfPink
                  : Colors.grey.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: logoUrl.isNotEmpty
                      ? Image.network(
                          logoUrl,
                          headers: const {'ngrok-skip-browser-warning': 'true'},
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Iconsax.bank, size: 18),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Iconsax.bank, size: 18),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bankName,
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kTfText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      style: GoogleFonts.roboto(
                        fontWeight:
                            isShowBalance ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13.5,
                        color: isShowBalance
                            ? const Color(0xFF1B7A3D)
                            : kTfMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SourceRadioDot(selected: bankSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class SourceRadioDot extends StatelessWidget {
  final bool selected;

  const SourceRadioDot({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? kTfPink : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: selected
          ? Container(
              width: 11,
              height: 11,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: kTfPink,
              ),
            )
          : null,
    );
  }
}

