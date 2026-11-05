import 'package:app/src/auth/forgot/forgot_type.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:app/src/kyc/kyc_guide_screen.dart';
import 'package:app/src/kyc/kyc_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class KycResultScreen extends StatelessWidget {
  final bool isSuccess;
  final String msg;
  final ForgotKycArgs? forgot;
  final bool isUpdate;
  const KycResultScreen({
    super.key,
    required this.isSuccess,
    required this.msg,
    this.forgot,
    this.isUpdate = false,
  });

  void _onPrimaryAction(BuildContext context) {
    // Luồng quên mật khẩu/PIN: thử lại về màn nhập OTP rồi chụp lại từ đầu
    if (forgot != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => KycGuideScreen(forgot: forgot),
        ),
        (r) => r.settings.name == kForgotOtpRoute || r.isFirst,
      );
      return;
    }
    if (isSuccess) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => KycGuideScreen(isUpdate: isUpdate),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = isSuccess ? kKycSuccess : kKycError;
    final badgeGradient = isSuccess
        ? const [Color(0xFF5BD08A), kKycSuccess]
        : const [Color(0xFFFF7070), kKycError];
    final titleText = isUpdate
        ? (isSuccess ? 'Cập nhật thành công' : 'Cập nhật thất bại')
        : (isSuccess ? 'Xác minh thành công' : 'Xác minh thất bại');
    final subtitleText = msg.trim().isNotEmpty
        ? msg
        : (isSuccess
              ? 'Hồ sơ định danh của bạn đã được ghi nhận trên hệ thống Ví Mio.'
              : 'Chưa thể đối chiếu thông tin. Vui lòng kiểm tra lại ảnh chụp và thử lại.');

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: kKycBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Kết quả xác thực',
          style: GoogleFonts.roboto(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: kKycText,
          ),
        ),
      ),
      body: Stack(
        children: [
          const KycHeaderGradient(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                                  color: kKycPink.withValues(alpha: 0.12),
                                  blurRadius: 26,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                58,
                                22,
                                24,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      isSuccess
                                          ? 'Định danh eKYC hoàn tất'
                                          : 'Chưa thể xác minh hồ sơ',
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    titleText,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.roboto(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: accentColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    subtitleText,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.roboto(
                                      fontSize: 14.5,
                                      color: kKycMuted,
                                      height: 1.5,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: KycDashedDivider(),
                                  ),
                                  if (isSuccess)
                                    _buildSuccessSummary()
                                  else
                                    _buildFailureSuggestions(),
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
                                      color: accentColor.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: badgeGradient,
                                    ),
                                  ),
                                  child: Icon(
                                    isSuccess
                                        ? Icons.check_rounded
                                        : Icons.close_rounded,
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
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: kKycPink.withValues(alpha: 0.08),
                        offset: const Offset(0, -4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: KycPrimaryButton(
                    label: isSuccess ? 'Về trang chủ' : 'Thực hiện lại',
                    icon: isSuccess ? Iconsax.home_2 : Iconsax.refresh,
                    onTap: () => _onPrimaryAction(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessSummary() {
    return Column(
      children: [
        _buildSummaryRow(
          label: 'Trạng thái tài khoản',
          value: 'Đã xác thực eKYC',
          valueColor: kKycSuccess,
          icon: Iconsax.shield_tick,
        ),
        const SizedBox(height: 12),
        _buildSummaryRow(
          label: 'Quyền lợi mở khóa',
          value: 'Chuyển tiền, Nạp/Rút & Ngân hàng',
        ),
      ],
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    Color? valueColor,
    IconData? icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 13.5,
            color: kKycMuted,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: valueColor ?? kKycText),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.roboto(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? kKycText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFailureSuggestions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kKycBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kKycPink.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Iconsax.info_circle,
                size: 17,
                color: kKycPinkDark,
              ),
              const SizedBox(width: 7),
              Text(
                'Gợi ý để xác thực thành công:',
                style: GoogleFonts.roboto(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: kKycText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRetryBullet('Chụp giấy tờ bản gốc rõ nét, đủ 4 góc, không lóa đèn.'),
          const SizedBox(height: 5),
          _buildRetryBullet('Giữ khuôn mặt ngay ngắn trong khung oval và đủ sáng.'),
        ],
      ),
    );
  }

  Widget _buildRetryBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 8),
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: kKycPink,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: 12.8,
              color: kKycText.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
