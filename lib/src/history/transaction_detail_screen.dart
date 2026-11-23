import 'dart:async';
import 'dart:math' as math;
import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/src/history/transaction_model.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:app/src/postpaid/postpaid_screen.dart';
import 'package:app/src/topup_withdraw/topup_withdraw_screen.dart';
import 'package:app/src/transfer/amount_input_screen.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transactionModel;
  final String title;
  final String amount;
  final String status;
  final String time;
  final String transactionCode;
  final String walletName;
  final String feeText;
  final String bankName;
  final IconData icon;
  final Color iconColor;
  final String textBtn;

  const TransactionDetailScreen({
    super.key,
    required this.title,
    required this.amount,
    required this.status,
    required this.time,
    required this.transactionCode,
    required this.walletName,
    required this.feeText,
    required this.bankName,
    required this.icon,
    required this.iconColor,
    required this.textBtn,
    required this.transactionModel,
  });

  @override
  Widget build(BuildContext context) {
    final UserController userController = Get.find<UserController>();
    final bool isFailed = transactionModel.isFailed;
    final bool isPending = transactionModel.isPending;
    final bool isPostpaidRepay =
        transactionModel.fundingSource == 'POSTPAID' &&
        (transactionModel.postpaidAction == 'REPAY_PRINCIPAL' ||
            transactionModel.postpaidAction == 'REPAY_LATE_FEE' ||
            transactionModel.postpaidAction == 'REPAY_SERVICE_FEE');
    final String postpaidServiceName =
        transactionModel.counterpartyName.trim().isNotEmpty &&
                transactionModel.counterpartyName.trim() != 'Người nhận'
            ? transactionModel.counterpartyName.trim()
            : 'Ví trả sau';
    final bool isPostpaidRefund =
        transactionModel.fundingSource == 'POSTPAID' &&
        (transactionModel.postpaidAction == 'REFUND' ||
            transactionModel.type == 'REFUND');
    final bool isWalletRefund =
        transactionModel.type == "REFUND" && !isPostpaidRefund;
    final bool isMerchant =
        transactionModel.type == "PAYMENT" && !isPostpaidRepay;
    final bool isTransfer =
        transactionModel.type == "TRANSFER" && !isPostpaidRefund;
    final String transferMessage = isTransfer
        ? (isFailed
              ? (transactionModel.userMessage ?? '').trim()
              : (transactionModel.description ?? '').trim())
        : '';
    final String failureReason =
        (transactionModel.description ?? '').trim().isNotEmpty
        ? transactionModel.description!.trim()
        : 'Giao dịch không thể thực hiện. Vui lòng thử lại.';
    final Color statusBgColor = isFailed
        ? const Color(0xFFFEE2E2)
        : (isPending
              ? const Color(0xFFFEF3C7)
              : kTfSuccess.withValues(alpha: 0.12));
    final Color statusTextColor = isFailed
        ? const Color(0xFFDC2626)
        : (isPending ? const Color(0xFFD97706) : kTfSuccess);
    final String statusText = status.trim().isNotEmpty
        ? status.trim()
        : (isFailed ? 'Thất bại' : (isPending ? 'Đang xử lý' : 'Thành công'));

    return Scaffold(
      backgroundColor: kTfBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: TransferCircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onPressed: () => Navigator.pop(context),
        ),
        title: TransferAppBarTitle(
          (isMerchant || isPostpaidRepay || isPostpaidRefund || isWalletRefund)
              ? title
              : "Chi tiết giao dịch",
        ),
        actions: [
          TransferCircleButton(
            icon: Iconsax.home_2,
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (r) => false,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const TransferHeaderGradient(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: kTfPink.withValues(alpha: 0.12),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SnakeBorderCard(
                      borderRadius: 16,
                      borderWidth: 1.5,
                      colors: isFailed
                          ? const [
                              Colors.transparent,
                              Color(0xFFDC2626),
                              Color(0xFFFCA5A5),
                              Colors.transparent,
                            ]
                          : isPending
                          ? const [
                              Colors.transparent,
                              Color(0xFFD97706),
                              Color(0xFFFDE68A),
                              Colors.transparent,
                            ]
                          : const [
                              Colors.transparent,
                              Colors.green,
                              Colors.lightGreenAccent,
                              Colors.transparent,
                            ],
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Icon(icon, color: iconColor, size: 26),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title.toUpperCase(),
                                    style: GoogleFonts.roboto(
                                      fontSize: 13,
                                      color: kTfMuted,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      amount,
                                      style: GoogleFonts.roboto(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: kTfText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isFailed) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFECDD3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.cancel_outlined,
                                size: 18,
                                color: Color(0xFFE11D48),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                failureReason,
                                style: GoogleFonts.roboto(
                                  fontSize: 13.5,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF881337),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const TransferDashedDivider(),
                    const SizedBox(height: 6),
                    _infoRow(
                      "Trạng thái",
                      null,
                      trailingWidget: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: GoogleFonts.roboto(
                            color: statusTextColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    _infoRow("Thời gian", time),
                    _copyableInfoRow(
                      "Mã giao dịch",
                      transactionCode,
                      copySubject: "mã giao dịch",
                    ),
                    if ((isPostpaidRefund || isWalletRefund) &&
                        (transactionModel.originalTransactionId ?? '')
                            .trim()
                            .isNotEmpty)
                      _copyableInfoRow(
                        "Mã giao dịch gốc",
                        transactionModel.originalTransactionId!.trim(),
                        copySubject: "mã giao dịch gốc",
                      ),
                    if (isTransfer) ...[
                      _infoRow(
                        transactionModel.fundingSource == 'BANK'
                            ? "Tài khoản/thẻ"
                            : "Ví LumaPay",
                        walletName,
                      ),
                      if (transactionModel.counterpartyPhone.isNotEmpty)
                        _infoRow(
                          "Số điện thoại",
                          transactionModel.counterpartyPhone,
                        ),
                    ] else if (isPostpaidRefund) ...[
                      _infoRow("Tài khoản hoàn", walletName),
                      _infoRow("Cửa hàng", transactionModel.counterpartyName),
                      if (!isFailed &&
                          (transactionModel.description ?? '')
                              .trim()
                              .isNotEmpty)
                        _infoRow("Nội dung", transactionModel.description!),
                      if ((transactionModel.orderId ?? '').trim().isNotEmpty)
                        _infoRow("Mã đơn", transactionModel.orderId!),
                    ] else if (isWalletRefund) ...[
                      _infoRow(
                        transactionModel.direction == 'OUT'
                            ? "Ví hoàn tiền"
                            : "Ví nhận hoàn",
                        walletName,
                      ),
                      if (transactionModel.counterpartyName.trim().isNotEmpty)
                        _infoRow(
                          transactionModel.direction == 'OUT'
                              ? "Khách hàng"
                              : "Cửa hàng",
                          transactionModel.counterpartyName,
                        ),
                      if (!isFailed &&
                          (transactionModel.description ?? '')
                              .trim()
                              .isNotEmpty)
                        _infoRow("Nội dung", transactionModel.description!),
                      if ((transactionModel.orderId ?? '').trim().isNotEmpty)
                        _infoRow("Mã đơn", transactionModel.orderId!),
                    ] else if (isPostpaidRepay) ...[
                      _infoRow("Nguồn thanh toán", walletName),
                      _infoRow("Dịch vụ", postpaidServiceName),
                      if (!isFailed &&
                          (transactionModel.description ?? '')
                              .trim()
                              .isNotEmpty)
                        _infoRow("Nội dung", transactionModel.description!),
                    ] else if (isMerchant) ...[
                      if (transactionModel.fundingSource == 'BANK' &&
                          walletName.trim().isNotEmpty)
                        _infoRow("Tài khoản/thẻ", walletName),
                      _infoRow("Cửa hàng", transactionModel.counterpartyName),
                      if (!isFailed &&
                          (transactionModel.description ?? '')
                              .trim()
                              .isNotEmpty)
                        _infoRow("Nội dung", transactionModel.description!),
                      if ((transactionModel.orderId ?? '').trim().isNotEmpty ||
                          !isFailed)
                        _infoRow(
                          "Mã đơn",
                          (transactionModel.orderId ?? '').trim().isNotEmpty
                              ? transactionModel.orderId!
                              : transactionCode,
                        ),
                    ] else ...[
                      _infoRow("Tài khoản/thẻ", walletName),
                    ],
                    _infoRow("Tổng phí", feeText, isLast: true),
                    if (transferMessage.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildTransferMessageBox(transferMessage),
                    ],
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              SnackbarUtils.developing(
                                context,
                                message: 'Tính năng đang phát triển',
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: kTfPink, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              "Liên hệ CSKH",
                              style: GoogleFonts.roboto(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: kTfPink,
                              ),
                            ),
                          ),
                        ),
                        if (!isFailed && textBtn.trim().isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (textBtn == "Chuyển thêm" ||
                                    textBtn == "Chuyển lại") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AmountInputScreen(
                                        receiverPhone:
                                            transactionModel.counterpartyPhone,
                                        receiverFullName:
                                            transactionModel.counterpartyName,
                                        receiverId:
                                            transactionModel.counterpartyId,
                                      ),
                                    ),
                                  );
                                } else if (textBtn == "Nạp thêm") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TopUpWithdrawScreen(
                                        walletBalance:
                                            userController.balance.value,
                                        isTopUpTab: true,
                                      ),
                                    ),
                                  );
                                } else if (textBtn == "Rút thêm") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TopUpWithdrawScreen(
                                        walletBalance:
                                            userController.balance.value,
                                        isTopUpTab: false,
                                      ),
                                    ),
                                  );
                                } else if (textBtn == "Chia tiền") {
                                  SnackbarUtils.developing(
                                    context,
                                    message: 'Tính năng đang phát triển',
                                  );
                                } else if (textBtn == "Quản lý ví") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PostpaidScreen(),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kTfPink,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                textBtn,
                                style: GoogleFonts.roboto(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferMessageBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kTfPink.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kTfPink.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: kTfPink.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Iconsax.message_text,
              size: 17,
              color: kTfPink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Lời nhắn",
                  style: GoogleFonts.roboto(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: kTfMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.roboto(
                    fontSize: 14.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: kTfText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _copyableInfoRow(
    String label,
    String value, {
    required String copySubject,
  }) {
    return _infoRow(
      label,
      null,
      trailingWidget: Flexible(
        child: _CopyableCodeText(
          value: value,
          successMessage: 'Đã sao chép $copySubject',
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String? value, {
    Widget? trailingWidget,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.roboto(fontSize: 15, color: kTfMuted)),
          const SizedBox(width: 16),
          trailingWidget ??
              Flexible(
                child: Text(
                  value ?? '',
                  textAlign: TextAlign.end,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kTfText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        ],
      ),
    );
  }
}

class _CopyableCodeText extends StatefulWidget {
  final String value;
  final String successMessage;

  const _CopyableCodeText({
    required this.value,
    required this.successMessage,
  });

  @override
  State<_CopyableCodeText> createState() => _CopyableCodeTextState();
}

class _CopyableCodeTextState extends State<_CopyableCodeText> {
  bool _copied = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    HapticFeedback.lightImpact();
    _resetTimer?.cancel();
    if (!mounted) return;
    setState(() => _copied = true);
    SnackbarUtils.success(context, '${widget.successMessage}: ${widget.value}');
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _copy,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.value,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kTfPinkDark,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                _copied ? Icons.check_rounded : Iconsax.copy,
                size: 18,
                color: _copied ? kTfSuccess : kTfPink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SnakeBorderCard extends StatefulWidget {
  const SnakeBorderCard({
    super.key,
    required this.child,
    this.borderRadius = 14,
    this.borderWidth = 2,
    this.duration = const Duration(seconds: 1),
    this.colors = const [
      Colors.transparent,
      Colors.green,
      Colors.lightGreenAccent,
      Colors.transparent,
    ],
  });

  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final Duration duration;
  final List<Color> colors;

  @override
  State<SnakeBorderCard> createState() => _SnakeBorderCardState();
}

class _SnakeBorderCardState extends State<SnakeBorderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _SnakeBorderPainter(
            progress: _controller.value,
            radius: widget.borderRadius,
            strokeWidth: widget.borderWidth,
            colors: widget.colors,
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.borderWidth + 2),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius - 2),
        child: widget.child,
      ),
    );
  }
}

class _SnakeBorderPainter extends CustomPainter {
  _SnakeBorderPainter({
    required this.progress,
    required this.radius,
    required this.strokeWidth,
    required this.colors,
  });

  final double progress;
  final double radius;
  final double strokeWidth;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );

    final gradient = SweepGradient(
      colors: colors,
      startAngle: 0,
      endAngle: math.pi * 2,
      transform: GradientRotation(progress * math.pi * 2),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _SnakeBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}