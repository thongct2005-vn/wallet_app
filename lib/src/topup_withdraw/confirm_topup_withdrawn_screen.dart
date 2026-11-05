import 'package:app/core/utils/format_utils.dart';
import 'package:app/core/utils/loading_util.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/core/widgets/pin_bottomsheet/verify_pin_bottom_sheet.dart';
import 'package:app/src/link_bank/link_bank_screen.dart';
import 'package:app/src/services/bank_service.dart';
import 'package:app/src/services/transaction_service.dart';
import 'package:app/src/topup_withdraw/result_topup_withdraw_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/src/services/wallet_service.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

const Color _kPink = Color(0xFFEC407A);
const Color _kPinkDark = Color(0xFFD81B60);
const Color _kPinkLight = Color(0xFFF48FB1);
const Color _kText = Color(0xFF1F1B24);
const Color _kMuted = Color(0xFF8A8590);
const Color _kBg = Color(0xFFFAF6F8);

BoxDecoration _cardDeco() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(22),
  boxShadow: [
    BoxShadow(
      color: _kPink.withValues(alpha: 0.08),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ],
);

class ConfirmTopUpWithdrawScreen extends StatefulWidget {
  final String amount;
  final List<dynamic> linkedBanks;
  final bool isTopUpTab;
  const ConfirmTopUpWithdrawScreen({
    super.key,
    required this.amount,
    required this.linkedBanks,
    required this.isTopUpTab,
  });

  @override
  State<ConfirmTopUpWithdrawScreen> createState() =>
      _ConfirmTopUpWithdrawScreenState();
}

class _ConfirmTopUpWithdrawScreenState
    extends State<ConfirmTopUpWithdrawScreen> {
  final WalletService _walletService = WalletService();
  final TransactionService _transactionService = TransactionService();
  final BankService _bankService = BankService();
  bool _isProcessing = false;
  final Uuid _uuid = const Uuid();
  // Mã idempotency gắn với đúng một giao dịch (số tiền + ngân hàng). Đổi ngân
  // hàng thì phải tạo mã mới, nếu không server báo "Mã đã được sử dụng với dữ liệu khác"
  late String idempotencyKey;
  String? _selectedBankId;
  bool isLoadingLinkedBanks = false;

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

    return FreezePinMediaQuery(
      child: PopScope(
        canPop: !_isProcessing,
        child: Scaffold(
          backgroundColor: _kBg,
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kPink.withValues(alpha: 0.14),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: _isProcessing ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 20, color: _kText),
                ),
              ),
            ),
            title: Text(
              "Thanh toán an toàn",
              style: GoogleFonts.roboto(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: _kText,
              ),
            ),
          ),
          body: !isLoadingLinkedBanks
              ? Stack(
                  children: [
                    RepaintBoundary(
                      child: Container(
                        height: 380,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _kPink.withValues(alpha: 0.24),
                              _kPinkLight.withValues(alpha: 0.08),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Column(
                        children: [
                          Expanded(
                            child: RepaintBoundary(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  children: [
                                    _buildContainerTopUpInfo(
                                      context,
                                      selectedBank,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildContainerBankList(context),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          RepaintBoundary(
                            child: _buildContainerConfirmButton(context),
                          ),
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
                )
              : Center(
                  child: FireworkStarSpinner(
                    size: 70,
                    color: Colors.pinkAccent,
                    starCount: 8,
                  ),
                ),
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kPink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Iconsax.wallet_1, color: _kPink, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.isTopUpTab
                      ? "Nạp tiền vào ví Mio"
                      : "Rút tiền về ngân hàng",
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                    color: _kText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.black.withValues(alpha: 0.07)),
          _buildInfoRow(
            label: widget.isTopUpTab ? 'Nguồn tiền' : 'Rút về NH liên kết',
            value: selectedBank['bank_name'] ?? '',
          ),
          _buildInfoRow(
            label: 'Số tiền',
            value:
                '${FormatUtils.formatDisplayNumber(FormatUtils.formatAmountToNum(widget.amount))}đ',
            bold: true,
          ),
          if (!widget.isTopUpTab) ...[
            _buildInfoRow(label: 'Phí giao dịch', value: 'Miễn phí'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              color: _kMuted,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                fontSize: 16,
                color: bold ? _kPinkDark : _kText,
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
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
            child: Text(
              widget.isTopUpTab ? "Nạp từ tài khoản/thẻ" : "Rút về tài khoản/thẻ",
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: _kText,
              ),
            ),
          ),
          for (final bank in widget.linkedBanks) ...[
            _buildBankOption(bank),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              setState(() {
                isLoadingLinkedBanks = true;
              });
              final result = await _getLinkedBanks();
              setState(() {
                isLoadingLinkedBanks = false;
              });
              if (!context.mounted) return;
              if (result['is_success']) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LinkBankScreen(
                      bankList: result['data']['available_banks'],
                    ),
                  ),
                );
              } else {
                SnackbarUtils.failure(context, result['message']);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _kPink.withValues(alpha: 0.05),
                border: Border.all(
                  width: 1,
                  color: _kPink.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.box_add, color: _kPink, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    "Ngân hàng liên kết",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kPinkDark,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Iconsax.arrow_right_3, size: 18, color: _kPink),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankOption(Map<String, dynamic> bank) {
    final bool isSelected = _selectedBankId == bank['id'];
    return GestureDetector(
      onTap: () {
        if (_selectedBankId == bank['id']) return;
        setState(() {
          _selectedBankId = bank['id'];
          // Đổi nguồn tiền = giao dịch mới nên cần mã idempotency mới
          idempotencyKey = _uuid.v7();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? _kPink.withValues(alpha: 0.05) : Colors.white,
          border: Border.all(
            width: isSelected ? 1.5 : 1,
            color: isSelected ? _kPink : Colors.grey.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 36,
                height: 36,
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
                      child: const Icon(Iconsax.bank, size: 18),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                bank['bank_name'] ?? '',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kText,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _kPink : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? Container(
                      width: 11,
                      height: 11,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kPink,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerConfirmButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
                    fontSize: 16,
                    color: _kMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${FormatUtils.formatDisplayNumber(FormatUtils.formatAmountToNum(widget.amount))}đ',
                      style: GoogleFonts.roboto(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: _kText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _isProcessing || _selectedBankId == null
                  ? null
                  : () {
                      _showCheckPinDialog(context);
                    },
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: _isProcessing
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFF06292), _kPinkDark],
                        ),
                  color: _isProcessing
                      ? Colors.black.withValues(alpha: 0.1)
                      : null,
                  boxShadow: _isProcessing
                      ? null
                      : [
                          BoxShadow(
                            color: _kPink.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.lock_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                    const SizedBox(width: 10),
                    Text(
                      "Xác nhận",
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckPinDialog(BuildContext context) {
    showSmoothPinBottomSheet(
      context: context,
      builder: (context) {
        return CheckPinBottomSheet(
          onCheckPin: (pin) async {
            try {
              final numAmount =
                  FormatUtils.formatAmountToNum(widget.amount).toString();
              final res = await _walletService.checkPin(
                pin,
                idempotencyKey,
                action: widget.isTopUpTab ? 'TOPUP' : 'WITHDRAW',
                params: {
                  'linked_bank_account_id': _selectedBankId ?? '',
                  'amount': numAmount,
                },
              );
              return res;
            } catch (e) {
              return {'is_success': false};
            }
          },
          onSuccess: (pinToken) async {
            await _handleTopUpWithdraw(pinToken);
          },
        );
      },
    );
  }

  Future<void> _handleTopUpWithdraw(String pinToken) async {
    if (!mounted) return;
    setState(() => _isProcessing = true);
    final numAmount = FormatUtils.formatAmountToNum(widget.amount).toString();
    try {
      final result = widget.isTopUpTab
          ? await _transactionService.topupMoney(
              numAmount,
              _selectedBankId ?? "",
              idempotencyKey,
              pinToken,
            )
          : await _transactionService.withdrawMoney(
              numAmount,
              _selectedBankId ?? "",
              idempotencyKey,
              pinToken,
            );

      setState(() {
        _isProcessing = false;
      });
      if (!mounted) return;
      if (result['is_success']) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ResultTopupWithdrawScreen(
              result: result,
              isTopUpTab: widget.isTopUpTab,
            ),
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

  Future<Map<String, dynamic>> _getLinkedBanks() async {
    try {
      final result = await _bankService.getBankLinkStatus();
      return result;
    } catch (e) {
      if (mounted) {
        SnackbarUtils.failure(
          context,
          "Hệ thống đang bảo trì. Vui lòng thử lại sau",
        );
      }
      return {};
    }
  }
}
