import 'package:app/core/utils/format_utils.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/core/widgets/pin_bottomsheet/verify_pin_bottom_sheet.dart';
import 'package:app/src/link_bank/link_bank_screen.dart';
import 'package:app/src/services/transaction_service.dart';
import 'package:app/src/topup_withdraw/result_topup_withdraw_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/src/services/wallet_service.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

class ConfirmTopUpScreen extends StatefulWidget {
  final String amount;
  final List<dynamic> linkedBanks;
  final List<dynamic> bankList;
  const ConfirmTopUpScreen({
    super.key,
    required this.amount,
    required this.linkedBanks,
    required this.bankList,
  });

  @override
  State<ConfirmTopUpScreen> createState() => _ConfirmTopUpScreenState();
}

class _ConfirmTopUpScreenState extends State<ConfirmTopUpScreen> {
  final WalletService _walletService = WalletService();
  final TransactionService _transactionService = TransactionService();
  bool _isProcessing = false;
  final Uuid _uuid = const Uuid();
  late final String idempotencyKey;
  String? _selectedBankId;

  @override
  void initState() {
    super.initState();
    idempotencyKey = _uuid.v7();
    if (widget.linkedBanks.isNotEmpty) {
      _selectedBankId = widget.linkedBanks.first['id'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedBank = widget.linkedBanks.firstWhere(
      (b) => b['id'] == _selectedBankId,
      orElse: () => {'bank_name': ''},
    );

    return PopScope(
      canPop: !_isProcessing,
      child: Scaffold(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: EdgeInsets.fromLTRB(10, 15, 0, 15),
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, size: 20),
              ),
            ),
          ),
          title: Text(
            "Thanh toán an toàn",
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        body: Stack(
          children: [
            Container(
              height: 500,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.pink.shade200.withValues(alpha: 0.75),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(15, 10, 15, 15),
                      child: Column(
                        children: [
                          _buildContainerTopUpInfo(context, selectedBank),
                          const SizedBox(height: 15),
                          _buildContainerBankList(context),
                        ],
                      ),
                    ),
                  ),
                  _buildContainerConfirmButton(context),
                ],
              ),
            ),
            if (_isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerTopUpInfo(
    BuildContext context,
    Map<String, dynamic> selectedBank,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(Icons.credit_card, color: Colors.pink),
                SizedBox(width: 5),
                Text(
                  "Nạp tiền vào ví Mio",
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Divider(
              height: 1.2,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
          ),
          _buildInfoRow(
            label: 'Nguồn tiền',
            value: selectedBank['bank_name'] ?? '',
          ),
          _buildInfoRow(
            label: 'Số tiền',
            value:
                '${FormatUtils.formatDisplayNumber(FormatUtils.formatAmountToNum(widget.amount))}đ',
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              color: Colors.black.withValues(alpha: 0.4),
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(width: 100),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w500,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainerBankList(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(5, 5, 5, 10),
              child: Text(
                "Nạp từ tài khoản/thẻ",
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
            for (final bank in widget.linkedBanks) ...[
              _buildBankOption(bank),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        LinkBankScreen(bankList: widget.bankList),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    width: 0.5,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Iconsax.box_add, color: Colors.pink, size: 25),
                      const SizedBox(width: 10),
                      Text(
                        "Ngân hàng liên kết",
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Icon(Iconsax.arrow_right, size: 25),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankOption(Map<String, dynamic> bank) {
    final bool isSelected = _selectedBankId == bank['id'];
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBankId = bank['id'];
        });
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            width: isSelected ? 2 : 1,
            color: isSelected
                ? Colors.pink
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 25,
                  height: 25,
                  child: Image.network(
                    bank['logo_url'],
                    headers: const {'ngrok-skip-browser-warning': 'true'},
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: const SizedBox(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Iconsax.bank, size: 16),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bank['bank_name'] ?? '',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.pink : Colors.grey,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: isSelected
                    ? Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.pink,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContainerConfirmButton(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 15, 10, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Tổng tiền",
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    color: Colors.black.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  '${FormatUtils.formatDisplayNumber(FormatUtils.formatAmountToNum(widget.amount))}đ',
                  style: GoogleFonts.roboto(
                    fontSize: 35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _isProcessing || _selectedBankId == null
                  ? null
                  : () {
                      _showCheckPinDialog(context);
                    },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _isProcessing
                      ? Colors.black.withValues(alpha: 0.1)
                      : Colors.pinkAccent,
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isProcessing
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.lock_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                      const SizedBox(width: 10),
                      Text(
                        "Xác nhận",
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckPinDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CheckPinBottomSheet(
          onCheckPin: (pin) async {
            try {
              final res = await _walletService.checkPin(pin);
              return res;
            } catch (e) {
              return {};
            }
          },
          onSuccess: () async {
            await _handleTopUp();
          },
        );
      },
    );
  }

  Future<void> _handleTopUp() async {
    if (!mounted) return;
    setState(() => _isProcessing = true);
    final numAmount = FormatUtils.formatAmountToNum(widget.amount).toString();
    try {
      final result = await _transactionService.topupMoney(
        numAmount,
        _selectedBankId ?? "",
        idempotencyKey,
      );
      debugPrint('$result ========================');
      setState(() {
        _isProcessing = false;
      });
      if (!mounted) return;
      if (result['is_success']) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ResultTopupWithdrawScreen(result: result),
          ),
          (Route<dynamic> route) => false,
        );
      } else {
        SnackbarUtils.failure(context, result['message']);
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.failure(context, "Có lỗi xảy ra. Vui lòng thử lại");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
