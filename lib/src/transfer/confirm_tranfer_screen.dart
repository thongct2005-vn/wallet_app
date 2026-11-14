import 'package:app/core/utils/format_utils.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/core/widgets/pin_bottomsheet/verify_pin_bottom_sheet.dart';
import 'package:app/src/services/transaction_service.dart';
import 'package:app/src/transfer/result_tranfer_screen.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/src/services/wallet_service.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

class ConfirmTranferScreen extends StatefulWidget {
  final String? receiverId;
  final String? receiverName;
  final String? receiverPhone;
  final String? amount;
  final String? description;
  final String? walletBalance;
  final String? referenceCode;
  final bool isMerchant;
  final String? orderId;

  const ConfirmTranferScreen({
    super.key,
    this.receiverId,
    this.receiverName,
    this.receiverPhone,
    this.amount,
    this.description,
    this.walletBalance,
    this.referenceCode,
    this.isMerchant = false,
    this.orderId,
  });

  @override
  State<ConfirmTranferScreen> createState() => _ConfirmTranferScreenState();
}

class _ConfirmTranferScreenState extends State<ConfirmTranferScreen> {
  final WalletService _walletService = WalletService();
  final TransactionService _transactionService = TransactionService();
  bool _isProcessingTransfer = false;
  bool _isLoadingFeePreview = false;
  Map<String, dynamic>? _feePreview;
  final Uuid _uuid = const Uuid();
  late final String idempotencyKey;

  @override
  void initState() {
    super.initState();
    idempotencyKey = _uuid.v7();
    _loadFeePreview();
  }

  Future<void> _loadFeePreview() async {
    final numAmount = FormatUtils.formatAmountToNum(widget.amount ?? '0');
    if (numAmount <= 0) return;
    if (mounted) {
      setState(() => _isLoadingFeePreview = true);
    }
    final isQrPayment =
        widget.referenceCode != null && widget.referenceCode!.isNotEmpty;
    final res = await _transactionService.previewFee(
      transactionType: widget.isMerchant || isQrPayment
          ? 'QR_PAYMENT'
          : 'TRANSFER',
      amount: numAmount,
      merchantUserId: widget.isMerchant ? widget.receiverId : null,
      referenceCode: widget.referenceCode,
    );
    if (!mounted) return;
    setState(() {
      _isLoadingFeePreview = false;
      if (res['is_success'] == true && res['data'] is Map) {
        _feePreview = Map<String, dynamic>.from(res['data'] as Map);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FreezeKeyboardMediaQuery(
      child: PopScope(
        canPop: !_isProcessingTransfer,
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
              onPressed: _isProcessingTransfer
                  ? null
                  : () => Navigator.pop(context),
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
                      child: RepaintBoundary(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Column(
                            children: [
                              _buildContainerReceiverInfo(context),
                              const SizedBox(height: 16),
                              _buildContainerVoucher(context),
                              const SizedBox(height: 16),
                              _buildContainerWalletInfo(context),
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
              if (_isProcessingTransfer)
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

  Widget _buildInfoRow({
    required String label,
    required String value,
    bool isMultiLine = false,
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TransferInfoRow(
        label: label,
        value: value,
        maxLines: isMultiLine ? 3 : 1,
        bold: bold,
        valueColor: valueColor,
      ),
    );
  }

  Widget _buildContainerReceiverInfo(BuildContext context) {
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
                child: const Icon(Iconsax.send_1, color: kTfPink, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.isMerchant ? "Thanh toán" : "Chuyển tiền",
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                    color: kTfText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.black.withValues(alpha: 0.07)),
          _buildInfoRow(
            label: 'Số tiền',
            value: '${widget.amount}đ',
            bold: true,
            valueColor: kTfPinkDark,
          ),
          _buildInfoRow(
            label: 'Phí giao dịch',
            value: _isLoadingFeePreview
                ? 'Đang tính...'
                : (!widget.isMerchant &&
                      _feePreview?['fee_payer']?.toString() == 'SENDER' &&
                      ((_feePreview?['fee_amount'] as num?) ?? 0) > 0)
                ? '${FormatUtils.formatDisplayNumber((_feePreview?['fee_amount'] as num?) ?? 0)}đ'
                : 'Miễn phí (0đ)',
          ),
          _buildInfoRow(
            label: widget.isMerchant ? 'Cửa hàng' : 'Người nhận',
            value: widget.receiverName ?? 'Không rõ tên',
            isMultiLine: widget.isMerchant,
          ),
          if (!widget.isMerchant)
            _buildInfoRow(
              label: 'Số điện thoại',
              value: widget.receiverPhone ?? '',
            ),
          if ((widget.description ?? '').isNotEmpty)
            _buildInfoRow(
              label: widget.isMerchant ? 'Nội dung' : 'Lời nhắn',
              value: widget.description ?? '',
              isMultiLine: true,
            ),
          if (widget.isMerchant && (widget.orderId ?? '').isNotEmpty)
            _buildInfoRow(
              label: 'Mã hóa đơn',
              value: widget.orderId ?? '',
              isMultiLine: true,
            ),
        ],
      ),
    );
  }

  Widget _buildContainerVoucher(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: transferCardDeco(),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Iconsax.receipt_discount,
                color: Colors.amber.shade800,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Ưu đãi",
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: kTfText,
              ),
            ),
            const Spacer(),
            Text(
              "Chọn hoặc nhập mã",
              style: GoogleFonts.roboto(fontSize: 14, color: kTfMuted),
            ),
            const Icon(Icons.chevron_right, color: kTfMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerWalletInfo(BuildContext context) {
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: kTfPink.withValues(alpha: 0.05),
              border: Border.all(width: 1.5, color: kTfPink),
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
                        '${FormatUtils.formatDisplayNumber(num.tryParse(widget.walletBalance ?? '0') ?? 0)}đ',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: kTfText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kTfPink, width: 2),
                  ),
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: kTfPink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainerConfirmButton(BuildContext context) {
    final baseAmount = FormatUtils.formatAmountToNum(widget.amount ?? '0');
    final isSenderPayer =
        !widget.isMerchant &&
        _feePreview?['fee_payer']?.toString() == 'SENDER';
    final payerFee = isSenderPayer
        ? ((_feePreview?['fee_amount'] as num?) ?? 0)
        : 0;
    final totalPay = isSenderPayer
        ? ((_feePreview?['total_debit_from_payer'] as num?) ??
              (baseAmount + payerFee))
        : baseAmount;

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
                      '${FormatUtils.formatDisplayNumber(totalPay)}đ',
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
              loading: _isProcessingTransfer,
              onTap: () => _showCheckPinDialog(context),
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
              final numAmount = FormatUtils.formatAmountToNum(
                widget.amount ?? '0',
              ).toString();
              final isQr = widget.referenceCode != null;
              final res = await _walletService.checkPin(
                pin,
                idempotencyKey,
                action: isQr ? 'QR_PAYMENT' : 'TRANSFER',
                params: isQr
                    ? {'reference_code': widget.referenceCode!}
                    : {
                        'destination_user_id': widget.receiverId ?? '',
                        'amount': numAmount,
                      },
              );
              return res;
            } catch (e) {
              return {'is_success': false};
            }
          },
          onSuccess: (pinToken) async {
            await _handleTransfer(pinToken);
          },
        );
      },
    );
  }

  Future<void> _handleTransfer(String pinToken) async {
    if (!mounted) return;
    setState(() => _isProcessingTransfer = true);
    final numAmount = FormatUtils.formatAmountToNum(
      widget.amount ?? '0',
    ).toString();
    try {
      final result = widget.referenceCode == null
          ? await _transactionService.transferMoney(
              widget.receiverId ?? "",
              numAmount,
              widget.description ?? "",
              idempotencyKey,
              pinToken,
            )
          : await _transactionService.processQRPayment(
              widget.referenceCode!,
              idempotencyKey,
              pinToken,
            );
      setState(() {
        _isProcessingTransfer = false;
      });
      if (!mounted) return;
      if (result['is_success']) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ResultTranferScreen(
              result: result,
              isMerchant: widget.isMerchant,
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
      if (mounted) setState(() => _isProcessingTransfer = false);
    }
  }
}
