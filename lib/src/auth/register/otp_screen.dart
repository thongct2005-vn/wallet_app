import 'dart:async';
import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/src/auth/auth_ui.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/auth/login/totp_confirm_dialog.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:app/src/kyc/kyc_guide_screen.dart';
import 'package:app/src/services/app_data_service.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:app/src/services/kyc.service.dart';
import 'package:app/src/services/notification_service.dart';
import 'package:app/src/services/otp_service.dart';
import 'package:app/src/services/socket_service.dart';
import 'package:app/src/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

const int _otpLength = 6;
const int _resendSeconds = 60;

class OtpScreen extends StatefulWidget {
  final String? phoneNumber;
  final String? email;
  final bool? isLogin;
  final String? otpToken;
  final String? password;

  /// true: tài khoản dùng Google Authenticator, nhập mã từ ứng dụng thay vì email
  final bool isTotp;

  /// true: sau khi đăng nhập xong, hỏi mã Google Authenticator để bật tính năng
  final bool enableTotpAfterLogin;

  /// true: sau khi đăng nhập xong, tắt Google Authenticator (quay về OTP email)
  final bool disableTotpAfterLogin;
  const OtpScreen({
    super.key,
    this.phoneNumber,
    this.email,
    this.isLogin,
    this.otpToken,
    this.password,
    this.isTotp = false,
    this.enableTotpAfterLogin = false,
    this.disableTotpAfterLogin = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with SmoothAutoFocusMixin {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final OtpService _otpService = OtpService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final AppDataService _appDataService = AppDataService();
  final KYCService _kycService = KYCService();
  final UserController _userController = Get.put(
    UserController(),
    permanent: true,
  );

  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isResendingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> _countdownNotifier = ValueNotifier<int>(0);
  final ValueNotifier<String> _msgNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> _hasFocusNotifier = ValueNotifier<bool>(false);
  Timer? _timer;

  @override
  FocusNode get initialFocusNode => _otpFocusNode;

  @override
  void initState() {
    super.initState();
    _otpFocusNode.addListener(_onFocusChanged);
    if (!widget.isTotp) _startCountdown();
  }

  void _onFocusChanged() {
    _hasFocusNotifier.value = _otpFocusNode.hasFocus;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpFocusNode.removeListener(_onFocusChanged);
    _otpController.dispose();
    _otpFocusNode.dispose();
    _scrollController.dispose();
    _isLoadingNotifier.dispose();
    _isResendingNotifier.dispose();
    _countdownNotifier.dispose();
    _msgNotifier.dispose();
    _hasFocusNotifier.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownNotifier.value = _resendSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownNotifier.value > 0) {
        _countdownNotifier.value = _countdownNotifier.value - 1;
      } else {
        timer.cancel();
      }
    });
  }

  void _clearOtpFields() {
    _otpController.clear();
    requestKeyboardFocus(_otpFocusNode);
  }

  Future<void> _resendOtp() async {
    _isResendingNotifier.value = true;
    _msgNotifier.value = '';

    final result = widget.isLogin == true
        ? await _authService.resendLoginOtp(widget.otpToken ?? '')
        : await _otpService.generateOtp(
            phone: widget.phoneNumber,
            email: widget.email,
          );

    if (!mounted) return;
    _isResendingNotifier.value = false;

    if (result['is_success'] == true) {
      _startCountdown();
      SnackbarUtils.success(context, 'Đã gửi lại mã xác thực');
    } else {
      _msgNotifier.value =
          result['message']?.toString() ??
          'Không thể gửi lại mã, vui lòng thử lại';
    }
  }

  Future<void> _handleVerify() async {
    if (_isLoadingNotifier.value) return;
    final code = _otpController.text.trim();

    if (code.length != _otpLength) {
      _msgNotifier.value = 'Vui lòng nhập đủ $_otpLength số';
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    _isLoadingNotifier.value = true;
    _msgNotifier.value = '';

    if (widget.isLogin == true) {
      await _verifyLogin(code);
    } else {
      await _verifyRegister(code);
    }
  }

  Future<void> _verifyLogin(String code) async {
    final result = await _authService.verifyLoginOtp(
      widget.otpToken ?? '',
      code,
    );

    if (!mounted) return;

    if (result['is_success'] == true) {
      await _completeLogin(result);
      return;
    }

    _isLoadingNotifier.value = false;

    if (result['status_code'] == 401) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPhoneScreen(
            isForceLogout: true,
            msg: result['message'] ?? 'Phiên xác thực đã hết hạn',
          ),
        ),
        (r) => false,
      );
      return;
    }

    _clearOtpFields();
    _msgNotifier.value = result['message'] ?? 'OTP không chính xác';
  }

  Future<void> _verifyRegister(String code) async {
    final result = await _authService.registerWithEmail(
      otpToken: widget.otpToken ?? '',
      otp: code,
      password: widget.password ?? '',
    );

    if (!mounted) return;
    _isLoadingNotifier.value = false;

    if (result['is_success'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPhoneScreen(
            initialPhoneNumber: widget.phoneNumber,
            isRegisterSucess: true,
          ),
        ),
        (r) => false,
      );
    } else {
      _clearOtpFields();
      _msgNotifier.value = result['message'] ?? 'Xác thực đăng ký thất bại';
    }
  }

  Future<void> _completeLogin(Map<String, dynamic> result) async {
    final homeData = await _appDataService.fetchHomeData();

    _userController.setUserData(
      newId: result['user_id'],
      newPhone: result['phone'] ?? '',
      newFullName: result['full_name'] ?? 'Không rõ tên',
      newBalance: homeData['balance'],
      newHasPin: homeData['has_pin'],
    );
    final userKYC = await _kycService.checkUserKYC();

    await SocketService().connect();
    final fcmToken = await NotificationService().init();

    if (fcmToken != null) {
      await _userService.updateFcmToken(fcmToken);
    }
    if (!mounted) return;

    _isLoadingNotifier.value = false;

    // Người dùng đã chọn dùng Google Authenticator: nhập mã đầu tiên để bật
    if (widget.enableTotpAfterLogin) {
      await showTotpConfirmDialog(context);
      if (!mounted) return;
    }

    // Người dùng chọn quay về OTP qua email: tắt Google Authenticator
    if (widget.disableTotpAfterLogin) {
      final off = await _authService.disableTotp();
      if (!mounted) return;
      if (off['is_success'] == true) {
        SnackbarUtils.success(context, 'Đã chuyển sang nhận OTP qua email');
      } else {
        SnackbarUtils.failure(
          context,
          off['message'] ?? 'Không thể chuyển sang OTP email, vui lòng thử lại',
        );
      }
    }

    final Widget next = userKYC['data']['is_kyc']
        ? const HomeScreen()
        : const KycGuideScreen();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => next),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRegisterFlow = widget.isLogin != true;

    return AuthScaffold(
      appBarTitle: 'Xác nhận OTP',
      onBack: () => Navigator.pop(context),
      scrollController: _scrollController,
      hasFocusListenable: _hasFocusNotifier,
      bottomBar: ValueListenableBuilder<bool>(
        valueListenable: _isLoadingNotifier,
        builder: (context, isLoading, _) {
          return AuthPrimaryButton(
            label: 'Xác nhận',
            loading: isLoading,
            onTap: _handleVerify,
          );
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          AuthHeroBanner(
            icon: Iconsax.shield_tick,
            badgeText: isRegisterFlow
                ? 'Bước 3/3 • Hoàn tất mở ví'
                : (widget.isTotp ? 'Google Authenticator' : 'Bảo mật 2 lớp'),
            title: widget.isTotp ? 'Nhập mã Authenticator' : 'Nhập mã xác thực',
            subtitle: widget.isTotp
                ? 'Mở ứng dụng Google Authenticator và nhập mã 6 số đang hiển thị cho tài khoản này.'
                : 'Mã xác thực 6 chữ số đã được gửi tới địa chỉ email ${widget.email ?? ''}',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
            decoration: authCardDeco(radius: 22),
            child: Column(
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: _msgNotifier,
                  builder: (context, msg, _) {
                    return Column(
                      children: [
                        AuthOtpInputRow(
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          length: _otpLength,
                          hasError: msg.isNotEmpty,
                          onChanged: (_) {
                            if (_msgNotifier.value.isNotEmpty) {
                              _msgNotifier.value = '';
                            }
                          },
                          onCompleted: (_) => _handleVerify(),
                        ),
                        if (msg.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          AuthErrorBanner(message: msg),
                        ],
                      ],
                    );
                  },
                ),
                if (!widget.isTotp) ...[
                  const SizedBox(height: 18),
                  ValueListenableBuilder<bool>(
                    valueListenable: _isResendingNotifier,
                    builder: (context, isResending, _) {
                      if (isResending) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: kAuthPink,
                            ),
                          ),
                        );
                      }
                      return ValueListenableBuilder<int>(
                        valueListenable: _countdownNotifier,
                        builder: (context, seconds, _) {
                          final canResend = seconds <= 0;
                          return TextButton.icon(
                            onPressed: canResend ? _resendOtp : null,
                            style: TextButton.styleFrom(
                              foregroundColor: kAuthPinkDark,
                              disabledForegroundColor: kAuthMuted,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            icon: Icon(
                              Iconsax.refresh,
                              size: 16,
                              color: canResend ? kAuthPinkDark : kAuthMuted,
                            ),
                            label: Text(
                              canResend
                                  ? 'Gửi lại mã OTP'
                                  : 'Gửi lại mã sau ${seconds}s',
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
