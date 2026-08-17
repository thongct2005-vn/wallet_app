import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 170 + MediaQuery.of(context).padding.top,
            child: Stack(
              children: [
                ClipPath(
                  clipper: CurvedHeaderClipper(),
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.pink.withValues(alpha: 0.75),
                          Colors.pink.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 70 + MediaQuery.of(context).padding.top,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(width: 5, color: Colors.white),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.network(
                          'https://api.dicebear.com/7.x/micah/png?seed='
                          '&backgroundColor=ffb6c1&borderRadius=50',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            "Phan Văn Thống",
            style: GoogleFonts.roboto(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.call, color: Colors.pink, size: 20),
              const SizedBox(width: 5),
              Text(
                "0855313437",
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  color: Colors.black.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.pink.withValues(alpha: 0.07),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.edit_2,
                      color: Colors.pinkAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "Chỉnh sửa",
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        color: Colors.pinkAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(15),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildItem(
                    context,
                    Iconsax.user,
                    Colors.pink.withValues(alpha: 0.15),
                    Colors.pinkAccent,
                    "Thông tin cá nhân",
                    "Cập nhật thông tin cá nhân của bạn",
                    () {},
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(50, 2, 20, 2),
                    child: Divider(
                      height: 0.1,
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  _buildItem(
                    context,
                    Iconsax.shield_tick,
                    Colors.purple.withValues(alpha: 0.15),
                    Colors.purple,
                    "Bảo mật",
                    "Mật khẩu, PIN",
                    () {},
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(50, 2, 20, 2),
                    child: Divider(
                      height: 0.1,
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  _buildItem(
                    context,
                    Iconsax.bank,
                    Colors.blue.withValues(alpha: 0.15),
                    Colors.blue,
                    "Ngân hàng liên kết",
                    "Quản lý các ngân hàng liên kết với ví",
                    () {},
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(50, 2, 20, 2),
                    child: Divider(
                      height: 0.1,
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  _buildItem(
                    context,
                    Iconsax.chart_2,
                    Colors.green.withValues(alpha: 0.15),
                    Colors.green,
                    "Hạn mức",
                    "Xem hạn mức và sức chứa của ví",
                    () {},
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(50, 2, 20, 2),
                    child: Divider(
                      height: 0.1,
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  _buildItem(
                    context,
                    Iconsax.notification,
                    Colors.yellow.withValues(alpha: 0.15),
                    Colors.yellow,
                    "Thông báo",
                    "Quản lý các thông báo và cập nhật",
                    () {},
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(50, 2, 20, 2),
                    child: Divider(
                      height: 0.1,
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  _buildItem(
                    context,
                    Iconsax.message_question,
                    Colors.grey.withValues(alpha: 0.15),
                    Colors.grey,
                    "Hỗ trợ",
                    "Nhận trợ giúp và liên hệ để được hỗ trợ",
                    () {},
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(50, 2, 20, 2),
                    child: Divider(
                      height: 0.1,
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  _buildItem(
                    context,
                    Iconsax.logout,
                    Colors.red.withValues(alpha: 0.15),
                    Colors.red,
                    "Đăng xuất",
                    "Đăng xuất khỏi tài khoản",

                    () => _showConfirmLogout(context),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    VoidCallback? onTap,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: color,
              ),
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Icon(icon, color: iconColor, size: 26),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_right, color: Colors.black.withValues(alpha: 0.5)),
          ],
        ),
      ),
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
    await _storage.deleteAll();
    if (result['is_success']) return true;
    return false;
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
