import 'package:app/core/utils/format_utils.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:app/src/transfer/amount_input_screen.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class ResultTranferScreen extends StatefulWidget {
  final Map<String, dynamic>? result;
  final bool isMerchant;
  const ResultTranferScreen({super.key, this.result, this.isMerchant = false});
  @override
  State<ResultTranferScreen> createState() => _ResultTranferScreenState();
}

class _ResultTranferScreenState extends State<ResultTranferScreen> {
  late dynamic data;
  late dynamic amount;
  late dynamic createdAt;

  @override
  void initState() {
    super.initState();
    setState(() {
      data = (widget.result?['data'] as Map<String, dynamic>?) ?? {};
      amount = FormatUtils.formatDisplayNumber(
        num.tryParse(data['amount']?.toString() ?? '0') ?? 0,
      );
      createdAt = data['createdAt'] == null
          ? ''
          : FormatUtils.formatCustomDateTime(data['createdAt'].toString());
    });
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: kTfBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const TransferAppBarTitle("Kết quả giao dịch"),
          actions: [
            TransferCircleButton(
              icon: Iconsax.home_2,
              onPressed: _goHome,
              padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            ),
          ],
        ),
        body: Stack(
          children: [
            const TransferHeaderGradient(),
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
                            color: kTfPink.withValues(alpha: 0.12),
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
                                color: kTfSuccess,
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
                                  color: kTfText,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const TransferDashedDivider(),
                            const SizedBox(height: 20),
                            _buildReceivedBanner(),
                            const SizedBox(height: 16),
                            TransferInfoRow(
                              label: "Dịch vụ/ Cửa hàng",
                              value: widget.isMerchant
                                  ? "Thanh toán qua Mio"
                                  : "Chuyển tiền qua Mio",
                            ),
                            const SizedBox(height: 16),
                            TransferInfoRow(
                              label: "Giao dịch",
                              value: "${data['transactionId'] ?? ''}",
                              valueColor: kTfPinkDark,
                              trailingIcon: Icons.chevron_right,
                            ),
                            const SizedBox(height: 16),
                            TransferInfoRow(
                              label: "Thời gian thanh toán",
                              value: createdAt,
                            ),
                            const SizedBox(height: 20),
                            _buildReceipt(),
                            const SizedBox(height: 26),
                            _buildButtons(),
                          ],
                        ),
                      ),
                    ),
                    Positioned(top: 0, child: _buildSuccessBadge()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBadge() {
    return TweenAnimationBuilder<double>(
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
              color: kTfSuccess.withValues(alpha: 0.25),
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
              colors: [Color(0xFF5BD08A), kTfSuccess],
            ),
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 42),
        ),
      ),
    );
  }

  Widget _buildReceivedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kTfSuccess.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(width: 1, color: kTfSuccess.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.tick_circle, color: kTfSuccess, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "${data['destinationUserName'] ?? ''} đã nhận được tiền qua Mio",
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kTfText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceipt() {
    final String sourceName = "${data['sourceUserName'] ?? ''}";
    final String destName = "${data['destinationUserName'] ?? ''}";
    final String description = "${data['description'] ?? ''}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kTfPink.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(width: 1, color: kTfPink.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                alignment: Alignment.center,
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: kTfPink,
                ),
                child: Text(
                  'Mio',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Biên lại chuyển tiền",
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kTfText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const TransferDashedDivider(),
          const SizedBox(height: 14),
          Row(
            children: [
              TransferAvatar(name: sourceName, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sourceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kTfText,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: kTfMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Đường nối giữa người gửi và người nhận
          SizedBox(
            width: 42, // bằng kích thước avatar để căn đúng tâm
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (int i = 0; i < 3; i++)
                  Container(
                    width: 2,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: kTfPink.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: kTfPink,
                ),
              ],
            ),
          ),
          Row(
            children: [
              TransferAvatar(name: destName, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kTfText,
                      ),
                    ),
                    if (!widget.isMerchant)
                      Text(
                        "${data['destinationPhone'] ?? ''}",
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: kTfMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    final Widget homeButton = OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: kTfPink, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: _goHome,
      child: Text(
        "Màn hình chính",
        style: GoogleFonts.roboto(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: kTfPink,
        ),
      ),
    );

    if (widget.isMerchant) {
      return SizedBox(width: double.infinity, child: homeButton);
    }

    return Row(
      children: [
        Expanded(child: homeButton),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kTfPink,
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AmountInputScreen(
                    receiverFullName: data['destinationUserName'],
                    receiverId: data['destinationId'],
                    receiverPhone: data['destinationPhone'],
                  ),
                ),
              );
            },
            child: Text(
              "Chuyển thêm",
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}