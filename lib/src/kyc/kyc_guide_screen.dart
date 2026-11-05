import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/src/auth/forgot/forgot_type.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/kyc/kyc_front_id_screen.dart';
import 'package:app/src/kyc/kyc_ui.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:app/src/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class KycGuideScreen extends StatelessWidget {
  final ForgotKycArgs? forgot;
  final bool isUpdate;

  const KycGuideScreen({
    super.key,
    this.forgot,
    this.isUpdate = false,
  });

  Future<void> _showConfirmLogout(BuildContext context) async {
    final isSuccess = await DialogUtils.showConfirmationAsync(
      context,
      title: "Xác nhận",
      message: "Bạn có chắc chắn muốn đăng xuất không?",
      cancelText: "Đóng",
      confirmText: "Đồng ý",
      errorMessage: "Có lỗi khi đăng xuất. Vui lòng thử lại",
      onConfirm: () async {
        final result = await AuthService().logout();
        SocketService().disconnect();
        await const FlutterSecureStorage().deleteAll();
        return result['is_success'] == true;
      },
    );

    if (isSuccess == true && context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPhoneScreen()),
        (routes) => false,
      );
    }
  }

  void _onContinue(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KycFrontIdScreen(
          forgot: forgot,
          isUpdate: isUpdate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showBackButton = forgot != null || isUpdate;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: kKycBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 56,
        leading: showBackButton
            ? KycCircleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          isUpdate ? 'Cập nhật danh tính' : 'Xác thực tài khoản',
          style: GoogleFonts.roboto(
            color: kKycText,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (!showBackButton)
            KycCircleButton(
              tooltip: 'Đăng xuất',
              icon: Iconsax.logout,
              iconColor: kKycPinkDark,
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              onPressed: () => _showConfirmLogout(context),
            ),
        ],
      ),
      body: Stack(
        children: [
          const KycHeaderGradient(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Hero
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 84,
                                    height: 84,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: kKycPink.withValues(
                                            alpha: 0.22,
                                          ),
                                          blurRadius: 22,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: DecoratedBox(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFF06292),
                                            kKycPinkDark,
                                          ],
                                        ),
                                      ),
                                      child: const Icon(
                                        Iconsax.personalcard,
                                        size: 34,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Iconsax.shield_tick,
                                        size: 17,
                                        color: kKycSuccess,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: kKycPinkSoft,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  '3 bước bảo mật • Khoảng 1 phút',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kKycPinkDark,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isUpdate
                                    ? 'Cập nhật hồ sơ định danh'
                                    : 'Xác thực danh tính (eKYC)',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.roboto(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  color: kKycText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'Chuẩn bị bản gốc CCCD/CMND còn hiệu lực để hoàn tất 3 bước xác minh nhanh chóng dưới đây:',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: kKycMuted,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Danh sách 3 bước
                        Container(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          decoration: kycCardDeco(radius: 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quy trình thực hiện',
                                style: GoogleFonts.roboto(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: kKycText,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildTimelineStep(
                                stepNumber: 1,
                                icon: Iconsax.card,
                                title: 'Chụp mặt trước CCCD / CMND',
                                description:
                                    'Đặt giấy tờ vừa vặn trong khung hình, rõ ảnh chân dung và số định danh.',
                                isLast: false,
                              ),
                              _buildTimelineStep(
                                stepNumber: 2,
                                icon: Iconsax.card_send,
                                title: 'Chụp mặt sau CCCD / CMND',
                                description:
                                    'Chụp rõ vùng chip điện tử, mã vạch / MRZ và thông tin ngày cấp.',
                                isLast: false,
                              ),
                              _buildTimelineStep(
                                stepNumber: 3,
                                icon: Iconsax.scan,
                                title: 'Xác thực khuôn mặt (Liveness)',
                                description:
                                    'Đưa khuôn mặt vào khung oval ngang tầm mắt và giữ yên 3 giây để chụp tự động.',
                                isLast: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Hộp lưu ý quan trọng
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: kycCardDeco(radius: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: kKycPinkSoft,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Iconsax.info_circle,
                                      size: 18,
                                      color: kKycPinkDark,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Lưu ý để duyệt nhanh ngay lần đầu',
                                      style: GoogleFonts.roboto(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: kKycText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTipItem(
                                'Sử dụng CCCD/CMND bản gốc chính chủ, còn hạn sử dụng.',
                              ),
                              _buildTipItem(
                                'Không chụp qua màn hình thiết bị khác hoặc bản photocopy.',
                              ),
                              _buildTipItem(
                                'Chọn nơi đủ ánh sáng, tránh bóng mờ hoặc đèn chiếu chói lóa.',
                              ),
                              _buildTipItem(
                                'Tháo kính râm, khẩu trang hoặc mũ khi quét khuôn mặt.',
                                isLast: true,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: KycDashedDivider(),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Iconsax.security,
                                    size: 16,
                                    color: kKycSuccess,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Thông tin của bạn được mã hóa và bảo mật theo tiêu chuẩn an toàn Ví Mio.',
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        color: kKycMuted,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Nút "Tiếp tục" cố định dưới đáy
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
                    label: 'Bắt đầu xác thực',
                    trailingIcon: Iconsax.arrow_right_3,
                    onTap: () => _onContinue(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required int stepNumber,
    required IconData icon,
    required String title,
    required String description,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kKycPinkSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: kKycPinkDark, size: 22),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: kKycPinkLight.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 2 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF06292), kKycPinkDark],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Bước $stepNumber',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.roboto(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: kKycText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: kKycMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2, right: 8),
            child: Icon(
              Iconsax.tick_circle,
              size: 16,
              color: kKycPink,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: kKycText.withValues(alpha: 0.82),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
