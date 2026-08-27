import 'dart:math' as math;
import 'package:app/core/controller/user_controller.dart';
import 'package:app/src/history/transaction_model.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:app/src/topup_withdraw/topup_withdraw_screen.dart';
import 'package:app/src/transfer/amount_input_screen.dart';
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
    final UserController _userController = Get.find<UserController>();
    return Scaffold(
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      extendBodyBehindAppBar: true,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 15, 20),
                  child: Row(
                    children: [
                      Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 1,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.arrow_back, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Chi Tiết Giao Dịch",
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 1,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomeScreen(),
                              ),
                              (r) => false,
                            );
                          },
                          padding: EdgeInsets.zero,
                          icon: const Icon(Iconsax.home_2, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SnakeBorderCard(
                                borderRadius: 14,
                                borderWidth: 1.5,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  color: Colors.white,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: iconColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          icon,
                                          color: iconColor,
                                          size: 25,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title.toUpperCase(),
                                            style: GoogleFonts.roboto(
                                              fontSize: 16,
                                              color: Colors.black54,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            amount,
                                            style: GoogleFonts.roboto(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _infoRow(
                                "Trạng thái",
                                null,
                                trailingWidget: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.lightGreenAccent.withValues(
                                      alpha: 0.3,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status,
                                    style: GoogleFonts.roboto(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              _infoRow("Thời gian", time),
                              _infoRow(
                                "Mã giao dịch",
                                null,
                                trailingWidget: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      transactionCode,
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Iconsax.copy,
                                      size: 18,
                                      color: Colors.pink.shade300,
                                    ),
                                  ],
                                ),
                              ),
                              _infoRow("Tài khoản/thẻ", walletName),
                              _infoRow("Tổng phí", feeText, isLast: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  side: BorderSide(color: Colors.pink.shade200),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  "Liên hệ CSKH",
                                  style: GoogleFonts.roboto(
                                    color: Colors.pink,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (textBtn == "Chuyển thêm" ||
                                      textBtn == "Chuyển lại") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AmountInputScreen(
                                          receiverPhone: transactionModel.counterpartyPhone,
                                          receiverFullName: transactionModel.counterpartyName,
                                          receiverId: transactionModel.counterpartyId,
                                        ),
                                      ),
                                    );
                                  } else if (textBtn == "Nạp thêm") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TopUpWithdrawScreen(
                                              walletBalance:
                                                  _userController.balance.value,
                                              isTopUpTab: true,
                                            ),
                                      ),
                                    );
                                  } else if (textBtn == "Rút thêm") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TopUpWithdrawScreen(
                                              walletBalance:
                                                  _userController.balance.value,
                                              isTopUpTab: false,
                                            ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pinkAccent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  textBtn,
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
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
              ],
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
              trailingWidget ??
                  Text(
                    value ?? '',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
            ],
          ),
        ),
      ],
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
