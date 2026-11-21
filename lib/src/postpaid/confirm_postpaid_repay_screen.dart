import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/core/widgets/pin_bottomsheet/verify_pin_bottom_sheet.dart';
import 'package:app/src/services/bank_service.dart';
import 'package:app/src/services/postpaid_service.dart';
import 'package:app/src/services/wallet_service.dart';
import 'package:app/src/transfer/pay_now_funding_selector.dart';
import 'package:app/src/transfer/transfer_funding_helper.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

class ConfirmPostpaidRepayScreen extends StatefulWidget {
  final int amount;
  final int mainBalance;
  final bool isServiceFeeOnly;
  final String initialFundingSource;
  final String? initialLinkedBankAccountId;
  final List<Map<String, dynamic>>? initialLinkedBanks;
  final PostpaidService? postpaidService;
  final WalletService? walletService;
  final BankService? bankService;

  const ConfirmPostpaidRepayScreen({
    super.key,
    required this.amount,
    required this.mainBalance,
    this.isServiceFeeOnly = false,
    this.initialFundingSource = 'MAIN_WALLET',
    this.initialLinkedBankAccountId,
    this.initialLinkedBanks,
    this.postpaidService,
    this.walletService,
    this.bankService,
  });

  @override
  State<ConfirmPostpaidRepayScreen> createState() =>
      _ConfirmPostpaidRepayScreenState();
}

class _ConfirmPostpaidRepayScreenState
    extends State<ConfirmPostpaidRepayScreen> {
  late final PostpaidService _postpaidService =
      widget.postpaidService ?? PostpaidService();
  late final WalletService _walletService =
      widget.walletService ?? WalletService();
  late final BankService _bankService = widget.bankService ?? BankService();
  final Uuid _uuid = const Uuid();

  late String _idempotencyKey;
  late String _fundingSource;
  String? _selectedLinkedBankAccountId;
  List<Map<String, dynamic>> _linkedBanks = [];
  bool _isLoadingBanks = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _idempotencyKey = _uuid.v7();
    _fundingSource = widget.initialFundingSource == 'BANK'
        ? 'BANK'
        : 'MAIN_WALLET';
    _selectedLinkedBankAccountId = widget.initialLinkedBankAccountId;
    if (widget.initialLinkedBanks != null) {
      _linkedBanks = List<Map<String, dynamic>>.from(widget.initialLinkedBanks!);
    } else {
      _loadLinkedBanks();
    }
  }

  Future<void> _loadLinkedBanks() async {
    if (mounted) {
      setState(() => _isLoadingBanks = true);
    }
    final res = await _bankService.getBankLinkStatus();
    if (!mounted) return;
    setState(() {
      _isLoadingBanks = false;
      if (res['is_success'] == true && res['data'] is Map) {
        final accounts = (res['data'] as Map)['linked_accounts'];
        if (accounts is List) {
          _linkedBanks = accounts
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          if (_fundingSource == 'BANK' &&
              (_selectedLinkedBankAccountId == null ||
                  _selectedLinkedBankAccountId!.isEmpty) &&
              _linkedBanks.isNotEmpty) {
            final preferred = _linkedBanks.firstWhere(
              (b) => isLinkedBankSelectable(
                b,
                widget.amount,
                transactionAmount: widget.amount,
              ),
              orElse: () => _linkedBanks.first,
            );
            _selectedLinkedBankAccountId = preferred['id']?.toString();
          }
        }
      }
    });
  }

  Map<String, dynamic>? get _selectedLinkedBank {
    if (_selectedLinkedBankAccountId == null) return null;
    for (final bank in _linkedBanks) {
      if (bank['id']?.toString() == _selectedLinkedBankAccountId) {
        return bank;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.isServiceFeeOnly
        ? 'Thanh toán phí dịch vụ Ví trả sau'
        : 'Thanh toán dư nợ Ví trả sau';
    final amountFormatted = FormatUtils.formatDisplayNumber(widget.amount);

    final bool canConfirm;
    if (_fundingSource == 'BANK') {
      final selectedBank = _selectedLinkedBank;
      canConfirm =
          selectedBank != null &&
          isLinkedBankSelectable(
            selectedBank,
            widget.amount,
            transactionAmount: widget.amount,
          );
    } else {
      canConfirm = widget.mainBalance >= widget.amount;
    }

    return FreezeKeyboardMediaQuery(
      child: PopScope(
        canPop: !_isProcessing,
        child: Scaffold(
          backgroundColor: kTfBg,
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: TransferCircleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onPressed: _isProcessing ? null : () => Navigator.pop(context),
            ),
            title: const TransferAppBarTitle("Xác nhận thanh toán"),
          ),
          body: Stack(
            children: [
              const RepaintBoundary(child: TransferHeaderGradient()),
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(
                          children: [
                            _buildSummaryCard(titleText, amountFormatted),
                            const SizedBox(height: 16),
                            PayNowFundingSelector(
                              mainBalance: widget.mainBalance,
                              totalPay: widget.amount,
                              transactionAmount: widget.amount,
                              fundingSource: _fundingSource,
                              selectedLinkedBankAccountId:
                                  _selectedLinkedBankAccountId,
                              linkedBanks: _linkedBanks,
                              isLoadingBanks: _isLoadingBanks,
                              onSelectMainWallet: () => setState(() {
                                _fundingSource = 'MAIN_WALLET';
                              }),
                              onSelectBank: (bankId) => setState(() {
                                _fundingSource = 'BANK';
                                _selectedLinkedBankAccountId = bankId;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildConfirmBottomBar(amountFormatted, canConfirm),
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
      ),
    );
  }

  Widget _buildSummaryCard(String titleText, String amountFormatted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: transferCardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kTfPink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.credit_score_rounded,
                  color: kTfPink,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titleText,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w700,
                    fontSize: 17.5,
                    color: kTfText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.black.withValues(alpha: 0.07)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: TransferInfoRow(
              label: 'Số tiền',
              value: '$amountFormattedđ',
              bold: true,
              valueColor: kTfPinkDark,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: TransferInfoRow(
              label: 'Phí giao dịch',
              value: 'Miễn phí',
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: TransferInfoRow(
              label: 'Dịch vụ',
              value: 'Ví trả sau',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmBottomBar(String amountFormatted, bool canConfirm) {
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Tổng tiền",
                  style: GoogleFonts.roboto(fontSize: 16, color: kTfMuted),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$amountFormattedđ',
                      style: GoogleFonts.roboto(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: kTfText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TransferPrimaryButton(
              label: "Xác nhận",
              icon: Icons.lock_outline,
              enabled: canConfirm,
              loading: _isProcessing,
              onTap: () => _showCheckPinDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckPinDialog(BuildContext context) {
    showCheckPinDialog(
      context: context,
      customTitle:
          'Nhập mã Pin xác thực',
      onCheckPin: (pin) => _walletService.checkPin(
        pin,
        _idempotencyKey,
        action: 'POSTPAID_REPAY',
        params: {'amount': widget.amount},
      ),
      onSuccess: _handleRepay,
    );
  }

  Future<void> _handleRepay(String pinToken) async {
    if (!mounted || _isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final res = await _postpaidService.repayDebt(
        amount: widget.amount,
        idempotencyKey: _idempotencyKey,
        pinToken: pinToken,
        fundingSource: _fundingSource,
        linkedBankAccountId: _fundingSource == 'BANK'
            ? _selectedLinkedBankAccountId
            : null,
      );
      if (!mounted) return;
      if (res['is_success'] == true) {
        final data = res['data'];
        if (data is Map &&
            data['mainBalanceAfter'] != null &&
            Get.isRegistered<UserController>()) {
          Get.find<UserController>().balance.value =
              data['mainBalanceAfter'].toString();
        }
        Navigator.pop(context, res);
      } else {
        _idempotencyKey = _uuid.v7();
        SnackbarUtils.failure(
          context,
          res['message'] ?? 'Thanh toán dư nợ thất bại',
        );
      }
    } catch (_) {
      if (!mounted) return;
      _idempotencyKey = _uuid.v7();
      SnackbarUtils.failure(context, 'Có lỗi xảy ra. Vui lòng thử lại');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

