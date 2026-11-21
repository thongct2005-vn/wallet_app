import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/core/widgets/pin_bottomsheet/create_pin_bottom_sheet.dart';
import 'package:app/core/widgets/pin_bottomsheet/verify_pin_bottom_sheet.dart';
import 'package:app/src/auth/auth_ui.dart';
import 'package:app/src/auth/forgot/forgot_type.dart';
import 'package:app/src/profile/change_secret_screen.dart';
import 'package:app/src/services/biometric_service.dart';
import 'package:app/src/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final UserController _userController = Get.find<UserController>();
  final UserService _userService = UserService();
  final BiometricService _biometricService = BiometricService();

  bool _biometricEnabled = false;
  bool _isCheckingBiometric = true;
  bool _isProcessingToggle = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final enabled = await _biometricService.isEnabled();
    final hasPin = await _userService.checkPinStatus();
    _userController.hasPin.value = hasPin;
    if (!mounted) return;
    setState(() {
      _biometricEnabled = enabled && hasPin;
      _isCheckingBiometric = false;
    });
  }

  Future<bool> _ensureHasPin() async {
    if (_userController.hasPin.value) return true;
    final hasPin = await _userService.checkPinStatus();
    if (hasPin) {
      _userController.hasPin.value = true;
      return true;
    }
    if (!mounted) return false;
    bool created = false;
    await showCreatePinDialog(
      context: context,
      onCreatePin: (pin) => _userService.createPin(pin),
      onSuccess: () {
        created = true;
        _userController.hasPin.value = true;
      },
    );
    return created;
  }

  Future<void> _onTapChangePin() async {
    bool hadPinBefore = _userController.hasPin.value;
    if (!hadPinBefore) {
      hadPinBefore = await _userService.checkPinStatus();
      if (hadPinBefore) {
        _userController.hasPin.value = true;
      }
    }
    final ready = hadPinBefore ? true : await _ensureHasPin();
    if (!ready || !mounted) return;
    if (!hadPinBefore) {
      SnackbarUtils.success(context, 'Tạo mã PIN thành công');
      await _loadBiometricState();
      return;
    }
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ChangeSecretVerifyOldScreen(
          type: ForgotType.pin,
        ),
      ),
    );
    await _loadBiometricState();
  }

  Future<void> _onTapChangePassword() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ChangeSecretVerifyOldScreen(
          type: ForgotType.password,
        ),
      ),
    );
  }

  Future<void> _onToggleBiometric(bool targetEnable) async {
    if (_isProcessingToggle) return;

    if (targetEnable) {
      final hasPin = await _ensureHasPin();
      if (!hasPin || !mounted) return;

      final available = await _biometricService.isBiometricAvailable();
      if (!mounted) return;
      if (!available) {
        SnackbarUtils.failure(
          context,
          'Thiết bị chưa đăng ký hoặc không hỗ trợ vân tay. Vui lòng thiết lập vân tay trong Cài đặt thiết bị.',
        );
        return;
      }

      // Bước 1: Nhập đúng mã PIN hiện tại
      String? verifiedPin;
      await showCheckPinDialog(
        context: context,
        allowBiometric: false,
        customTitle: 'Nhập mã PIN để bật vân tay',
        onCheckPin: (pin) async {
          final res = await _userService.verifyPin(pin);
          return {
            ...res,
            'pin_token': pin,
          };
        },
        onSuccess: (pinToken) async {
          verifiedPin = pinToken;
        },
      );

      if (verifiedPin == null || verifiedPin!.length != 6 || !mounted) {
        return;
      }

      // Bước 2: Đưa vân tay vào để xác nhận bật
      setState(() => _isProcessingToggle = true);
      final authRes = await _biometricService.authenticate(
        reason: 'Đặt vân tay để bật xác thực sinh trắc học khi giao dịch',
      );
      if (!mounted) return;
      setState(() => _isProcessingToggle = false);

      if (authRes.isSuccess) {
        await _biometricService.enableWithPin(verifiedPin!);
        if (!mounted) return;
        setState(() => _biometricEnabled = true);
        SnackbarUtils.success(
          context,
          'Đã bật xác thực bằng vân tay khi giao dịch',
        );
      } else if (authRes.message != null) {
        SnackbarUtils.failure(context, authRes.message!);
      }
    } else {
      // Muốn tắt: đưa vân tay vào đúng là tắt
      setState(() => _isProcessingToggle = true);
      final authRes = await _biometricService.authenticate(
        reason: 'Đặt vân tay để tắt xác thực sinh trắc học',
      );
      if (!mounted) return;
      setState(() => _isProcessingToggle = false);

      if (authRes.isSuccess) {
        await _biometricService.disableBiometric();
        if (!mounted) return;
        setState(() => _biometricEnabled = false);
        SnackbarUtils.info(
          context,
          'Đã tắt xác thực bằng vân tay khi giao dịch',
        );
      } else if (authRes.message != null) {
        SnackbarUtils.failure(context, authRes.message!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      appBarTitle: 'Bảo mật',
      onBack: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          const AuthHeroBanner(
            icon: Iconsax.shield_security,
            badgeText: 'An toàn tài khoản',
            title: 'Quản lý bảo mật Ví LumaPay',
            subtitle:
                'Quản lý mã PIN giao dịch, mật khẩu đăng nhập và cài đặt xác thực bằng vân tay.',
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: authCardDeco(radius: 22),
            child: Column(
              children: [
                Obx(() {
                  final hasPin = _userController.hasPin.value;
                  return _buildActionItem(
                    icon: Iconsax.key,
                    title: hasPin ? 'Đổi mã PIN' : 'Tạo mã PIN',
                    subtitle: hasPin
                        ? 'Thay đổi mã PIN 6 số dùng khi giao dịch'
                        : 'Thiết lập mã PIN 6 số dùng khi giao dịch',
                    onTap: _onTapChangePin,
                  );
                }),
                _buildDivider(),
                _buildActionItem(
                  icon: Iconsax.lock_1,
                  title: 'Đổi mật khẩu',
                  subtitle: 'Thay đổi mật khẩu 6 số dùng khi đăng nhập',
                  onTap: _onTapChangePassword,
                ),
                _buildDivider(),
                _buildBiometricItem(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kAuthPinkSoft.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: kAuthPink.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.fingerprint_rounded,
                  color: kAuthPinkDark,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Khi bật xác thực vân tay, bạn có thể dùng vân tay thay cho mã PIN 6 số mỗi khi chuyển tiền, nạp tiền hoặc rút tiền.',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      height: 1.45,
                      color: kAuthText.withValues(alpha: 0.85),
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

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.6,
      indent: 68,
      endIndent: 16,
      color: Colors.black.withValues(alpha: 0.06),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kAuthPink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: kAuthPinkDark, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: kAuthText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.roboto(
                        fontSize: 12.5,
                        color: kAuthMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Iconsax.arrow_right_3,
                size: 18,
                color: kAuthMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricItem() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (_isCheckingBiometric || _isProcessingToggle)
            ? null
            : () => _onToggleBiometric(!_biometricEnabled),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kAuthPink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: kAuthPinkDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xác thực bằng vân tay',
                      style: GoogleFonts.roboto(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: kAuthText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _biometricEnabled
                          ? 'Đang bật • Dùng vân tay thay PIN khi giao dịch'
                          : 'Dùng vân tay thay mã PIN khi giao dịch',
                      style: GoogleFonts.roboto(
                        fontSize: 12.5,
                        color: _biometricEnabled ? kAuthSuccess : kAuthMuted,
                        fontWeight: _biometricEnabled
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (_isCheckingBiometric || _isProcessingToggle)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: kAuthPink,
                  ),
                )
              else
                _LumaPayCompactSwitch(
                  value: _biometricEnabled,
                  onChanged: _onToggleBiometric,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LumaPayCompactSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LumaPayCompactSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: value
              ? const LinearGradient(
                  colors: [Color(0xFFF06292), Color(0xFFD81B60)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: value ? null : const Color(0xFFE4DFE8),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: kAuthPink.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

