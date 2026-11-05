import 'dart:math' as math;
import 'package:app/core/controller/user_controller.dart';
import 'package:app/src/history/transaction_model.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:app/src/topup_withdraw/topup_withdraw_screen.dart';
import 'package:app/src/transfer/amount_input_screen.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
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
    final bool isMerchant = transactionModel.type == "PAYMENT";
    final bool isTransfer = transactionModel.type == "TRANSFER";

    return Scaffold(
      backgroundColor: kTfBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: TransferCircleButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context),
        ),
        title: TransferAppBarTitle(isMerchant ? title : "Chi tiết giao dịch"),
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
                              child: Icon(icon, color: iconColor, size: 26),
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
                          color: kTfSuccess.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.roboto(
                            color: kTfSuccess,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    _infoRow("Thời gian", time),
                    _infoRow(
                      "Mã giao dịch",
                      null,
                      trailingWidget: Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                transactionCode,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: kTfPinkDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Iconsax.copy, size: 18, color: kTfPink),
                          ],
                        ),
                      ),
                    ),
                    if (isTransfer) ...[
                      _infoRow("Ví Mio", walletName),
                      _infoRow(
                        "Số điện thoại",
                        transactionModel.counterpartyPhone,
                      ),
                    ] else if (isMerchant) ...[
                      _infoRow("Cửa hàng", transactionModel.counterpartyName),
                      _infoRow("Nội dung", transactionModel.description ?? ''),
                      _infoRow(
                        "Mã đơn",
                        transactionModel.orderId ?? transactionCode,
                      ),
                    ] else ...[
                      _infoRow("Tài khoản/thẻ", walletName),
                    ],
                    _infoRow("Tổng phí", feeText, isLast: true),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
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
                                // Không cần xử lý logic, để cân đối giao diện
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