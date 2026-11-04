import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/kyc/kyc_front_id_screen.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:app/src/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

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
                  const Icon(Iconsax.call, color: _pink, size: 17),
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
                Iconsax.user,
                Colors.pink.withValues(alpha: 0.12),
                Colors.pinkAccent,
                "Thông tin cá nhân",
                "Cập nhật thông tin cá nhân của bạn",
                () => _showConfirmUpdateKyc(context),
              ),
              _buildItem(
                context,
                Iconsax.shield_tick,
                Colors.purple.withValues(alpha: 0.12),
                Colors.purple,
                "Bảo mật",
                "Mật khẩu, PIN",
                () {},
              ),
              _buildItem(
                context,
                Iconsax.bank,
                Colors.blue.withValues(alpha: 0.12),
                Colors.blue,
                "Ngân hàng liên kết",
                "Quản lý các ngân hàng liên kết với ví",
                () {},
              ),
              _buildItem(
                context,
                Iconsax.chart_2,
                Colors.green.withValues(alpha: 0.12),
                Colors.green,
                "Hạn mức",
                "Xem hạn mức và sức chứa của ví",
                () {},
              ),
            ]),
            const SizedBox(height: 18),
            _buildSectionLabel("Chung"),
            _buildGroup([
              _buildItem(
                context,
                Iconsax.notification,
                Colors.amber.withValues(alpha: 0.18),
                Colors.amber.shade800,
                "Thông báo",
                "Quản lý các thông báo và cập nhật",
                () {},
              ),
              _buildItem(
                context,
                Iconsax.message_question,
                Colors.blueGrey.withValues(alpha: 0.14),
                Colors.blueGrey,
                "Hỗ trợ",
                "Nhận trợ giúp và liên hệ để được hỗ trợ",
                () {},
              ),
            ]),
            const SizedBox(height: 18),
            _buildGroup([
              _buildItem(
                context,
                Iconsax.logout,
                Colors.red.withValues(alpha: 0.12),
                Colors.red,
                "Đăng xuất",
                "Đăng xuất khỏi tài khoản",
                () => _showConfirmLogout(context),
                titleColor: Colors.red.shade600,
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
                    errorBuilder: (_, __, ___) => Container(
                      width: 96,
                      height: 96,
                      color: _pink.withValues(alpha: 0.12),
                      child: const Icon(Iconsax.user, color: _pink, size: 40),
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
    Color color,
    Color iconColor,
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
                color: color,
              ),
              child: Icon(icon, color: iconColor, size: 24),
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
              const Icon(Iconsax.arrow_right_3, color: _muted, size: 18),
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
            builder: (_) => const KycFrontIdScreen(isUpdate: true),
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