import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:app/src/topup_withdraw/topup_withdraw_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

const Color _kPink = Color(0xFFEC407A);
const Color _kPinkDark = Color(0xFFD81B60);
const Color _kPinkLight = Color(0xFFF48FB1);
const Color _kText = Color(0xFF1F1B24);
const Color _kMuted = Color(0xFF8A8590);
const Color _kSuccess = Color(0xFF2E9E5B);

class ResultTopupWithdrawScreen extends StatefulWidget {
  final Map<String, dynamic>? result;
  final bool isTopUpTab;
  const ResultTopupWithdrawScreen({
    super.key,
    this.result,
    required this.isTopUpTab,
  });

  @override
  State<ResultTopupWithdrawScreen> createState() =>
      _ResultWithdrawScreenState();
}

class _ResultWithdrawScreenState extends State<ResultTopupWithdrawScreen> {
  late dynamic data;
  late dynamic amount;
  late dynamic createdAt;
 final UserController _userController = Get.find<UserController>();
  @override
  void initState() {
    super.initState();
    setState(() {
      data = (widget.result?['data'] as Map<String, dynamic>?) ?? {};
      amount = FormatUtils.formatDisplayNumber(
        num.tryParse(data['amount']?.toString() ?? '0') ?? 0,
      );
      createdAt = FormatUtils.formatCustomDateTime(data['createdAt']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: const Color(0xFFFAF6F8),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text(
            "Kết quả giao dịch",
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  },
                  padding: EdgeInsets.zero,
                  icon: const Icon(Iconsax.home_2, size: 20, color: _kText),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
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
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 44),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _kPink.withValues(alpha: 0.12),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 56, 18, 22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Giao dịch thành công",
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _kSuccess,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "$amountđ",
                                style: GoogleFonts.roboto(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: _kText,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const _DashedDivider(),
                            const SizedBox(height: 20),

                            _buildInfoRow(
                              "Dịch vụ/ Cửa hàng",
                              widget.isTopUpTab
                                  ? "Nạp tiền từ ngân hàng"
                                  : "Rút tiền về ngân hàng",
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              "Giao dịch",
                              "${data['transactionId'] ?? ''}",
                              valueColor: _kPinkDark,
                              trailingIcon: Icons.chevron_right,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow("Thời gian thanh toán", createdAt),
                            if ((num.tryParse(data['feeAmount']?.toString() ?? '0') ?? 0) > 0) ...[
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                "Phí giao dịch",
                                "${FormatUtils.formatDisplayNumber(num.tryParse(data['feeAmount'].toString()) ?? 0)}đ",
                              ),
                            ],

                            const SizedBox(height: 26),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: _kPink,
                                        width: 1.5,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => HomeScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      "Màn hình chính",
                                      style: GoogleFonts.roboto(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: _kPink,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _kPink,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder:(_)=> TopUpWithdrawScreen(walletBalance: _userController.balance.value, isTopUpTab: widget.isTopUpTab)), (r)=>false);
                                    },
                                    child: Text(
                                      "Tạo giao dịch mới",
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

                    Positioned(
                      top: 0,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) =>
                            Transform.scale(scale: value, child: child),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _kSuccess.withValues(alpha: 0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF5BD08A), _kSuccess],
                              ),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                        ),
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

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    IconData? trailingIcon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 15, color: _kMuted),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? _kText,
                  ),
                ),
              ),
              if (trailingIcon != null)
                Icon(trailingIcon, size: 18, color: valueColor ?? _kText),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace))
            .floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.pink.withValues(alpha: 0.15),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}