import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/kyc/kyc_guide_screen.dart';
import 'package:app/src/link_bank/manage_linked_banks_screen.dart';
import 'package:app/src/profile/security_screen.dart';
import 'package:app/src/profile/transaction_limits_screen.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:app/src/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final UserController _userController = Get.find<UserController>();
  static const Color _pink = Color(0xFFEC407A);
  static const Color _pinkDark = Color(0xFFD81B60);
  static const Color _bg = Color(0xFFFAF6F8);
  static const Color _text = Color(0xFF1F1B24);
  static const Color _muted = Color(0xFF8A8590);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return ColoredBox(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(
          children: [
            _buildHeader(context, top),
            const SizedBox(height: 14),
            Text(
              _userController.fullName.value,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _text,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_rounded, color: _pink, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _userController.phone.value,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: _text.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _buildSectionLabel("Tài khoản"),
            _buildGroup([
              _buildItem(
                context,
                Icons.person_rounded,
                const [Color(0xFFF472B6), Color(0xFFDB2777)],
                const Color(0xFFDB2777),
                "Thông tin cá nhân",
                "Cập nhật thông tin cá nhân của bạn",
                () => _showConfirmUpdateKyc(context),
              ),
              _buildItem(
                context,
                Icons.verified_user_rounded,
                const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                const Color(0xFF7C3AED),
                "Bảo mật",
                "Mật khẩu, PIN, vân tay",
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SecurityScreen(),
                    ),
                  );
                },
              ),
              _buildItem(
                context,
                Icons.account_balance_rounded,
                const [Color(0xFF38BDF8), Color(0xFF0284C7)],
                const Color(0xFF0284C7),
                "Ngân hàng liên kết",
                "Quản lý các ngân hàng liên kết với ví",
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageLinkedBanksScreen(),
                    ),
                  );
                },
              ),
              _buildItem(
                context,
                Icons.bar_chart_rounded,
                const [Color(0xFF34D399), Color(0xFF059669)],
                const Color(0xFF059669),
                "Hạn mức",
                "Xem hạn mức và sức chứa của ví",
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TransactionLimitsScreen(),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 18),
            _buildSectionLabel("Chung"),
            _buildGroup([
              _buildItem(
                context,
                Icons.notifications_rounded,
                const [Color(0xFFFBBF24), Color(0xFFD97706)],
                const Color(0xFFD97706),
                "Thông báo",
                "Quản lý các thông báo và cập nhật",
                () => SnackbarUtils.developing(context),
              ),
              _buildItem(
                context,
                Icons.support_agent_rounded,
                const [Color(0xFF818CF8), Color(0xFF4F46E5)],
                const Color(0xFF4F46E5),
                "Hỗ trợ",
                "Nhận trợ giúp và liên hệ để được hỗ trợ",
                () => SnackbarUtils.developing(context),
              ),
            ]),
            const SizedBox(height: 18),
            _buildGroup([
              _buildItem(
                context,
                Icons.logout_rounded,
                const [Color(0xFFF87171), Color(0xFFDC2626)],
                const Color(0xFFDC2626),
                "Đăng xuất",
                "Đăng xuất khỏi tài khoản",
                () => _showConfirmLogout(context),
                titleColor: const Color(0xFFDC2626),
                showChevron: false,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double top) {
    return SizedBox(
      height: 170 + top,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipPath(
            clipper: CurvedHeaderClipper(),
            child: Container(
              height: 150 + top,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF48FB1), _pinkDark],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -40,
                    bottom: 10,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 60 + top,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 106,
                height: 106,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _pinkDark.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(5),
                child: ClipOval(
                  child: Image.network(
                    'https://orectic-noctilucent-ronan.ngrok-free.dev/images/avatar/default_avatar.png',
                    headers: const {'ngrok-skip-browser-warning': 'true'},
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 96,
                      height: 96,
                      color: _pink.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.person_rounded,
                        color: _pink,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 0, 20, 8),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.roboto(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: _muted,
          ),
        ),
      ),
    );
  }

  Widget _buildGroup(List<Widget> items) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      children.add(items[i]);
      if (i != items.length - 1) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 70, right: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ),
        );
      }
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _pink.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white,
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    IconData icon,
    List<Color> gradientColors,
    Color accentColor,
    String title,
    String description,
    VoidCallback? onTap, {
    Color? titleColor,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.24),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(icon, color: Colors.white, size: 21),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? _text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: _muted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F1F4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: _muted,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showConfirmUpdateKyc(BuildContext context) {
    DialogUtils.showConfirmation(
      context,
      title: "Cập nhật thông tin",
      message: "Bạn có muốn cập nhật thông tin cá nhân không?",
      cancelText: "Không",
      confirmText: "Có",
      onConfirm: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const KycGuideScreen(isUpdate: true),
          ),
        );
      },
    );
  }

  Future<void> _showConfirmLogout(BuildContext context) async {
    final isSuccess = await DialogUtils.showConfirmationAsync(
      context,
      title: "Xác nhận",
      message: "Bạn có chắc chắn muốn đăng xuất",
      cancelText: "Đóng",
      confirmText: "Đồng ý",
      errorMessage: "Có lỗi khi đăng xuất. Vui lòng thử lại",
      onConfirm: () => _logout(),
    );

    if (isSuccess == true && context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPhoneScreen()),
        (routes) => false,
      );
    }
  }

  Future<bool> _logout() async {
  final result = await _authService.logout();
  SocketService().disconnect();   
  await _storage.deleteAll();
  return result['is_success'] == true;
}
}

class CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}