import 'dart:async';
import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/auth/login/totp_confirm_dialog.dart';
import 'package:app/src/home/home_screen.dart';
import 'package:app/src/kyc/kyc_front_id_screen.dart';
import 'package:app/src/services/app_data_service.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:app/src/services/kyc.service.dart';
import 'package:app/src/services/notification_service.dart';
import 'package:app/src/services/otp_service.dart';
import 'package:app/src/services/socket_service.dart';
import 'package:app/src/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );
  final OtpService _otpService = OtpService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final AppDataService _appDataService = AppDataService();
  final KYCService _kycService = KYCService();
  final UserController _userController = Get.put(
    UserController(),
    permanent: true,
  );
  bool _isLoading = false;
  bool _isResending = false;
  int _countdown = 0;
  String _msg = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    for (final node in _focusNodes) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }
    if (!widget.isTotp) _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              "Xác nhận OTP",
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPhoneScreen()),
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back, size: 20),
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              Container(
                width: double.infinity,
                height: 500,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Iconsax.security,
                                        color: Colors.pink,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Xác thực tài khoản",
                                        style: GoogleFonts.roboto(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        height: 1.5,
                                      ),
                                      children: widget.isTotp
                                          ? [
                                              const TextSpan(
                                                text:
                                                    "Mở ứng dụng Google Authenticator và nhập mã 6 số đang hiển thị cho tài khoản này.",
                                              ),
                                            ]
                                          : [
                                              const TextSpan(
                                                text:
                                                    "Mã xác thực sẽ được gửi đến email ",
                                              ),
                                              TextSpan(
                                                text: widget.email ?? "",
                                                style: GoogleFonts.roboto(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _otpLength,
                                (i) => Padding(
                                  padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                                  child: _buildOtpBox(context, i),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (!widget.isTotp)
                            TextButton(
                              onPressed: (_countdown > 0 || _isResending)
                                  ? null
                                  : _resendOtp,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.pink,
                                disabledForegroundColor: Colors.grey,
                              ),
                              child: _isResending
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.pink,
                                      ),
                                    )
                                  : Text(
                                      _countdown > 0
                                          ? "Gửi lại mã sau $_countdown s"
                                          : "Gửi lại mã",
                                      style: GoogleFonts.roboto(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                            if (_msg != "") ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _msg,
                                        style: GoogleFonts.roboto(
                                          color: Colors.red,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleVerify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            disabledBackgroundColor: Colors.pink.withValues(
                              alpha: 0.4,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Xác nhận",
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(BuildContext context, int index) {
    final bool isFirst = index == 0;
    final bool isLast = index == _otpLength - 1;
    return Container(
      height: 56,
      width: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? Colors.pink
              : Colors.grey.withValues(alpha: 0.4),
          width: _focusNodes[index].hasFocus ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          autofocus: isFirst,
          maxLength: 1,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          onTap: () {
            setState(() {
              _msg = "";
            });
          },
          onChanged: (value) {
            if (value.isNotEmpty && !isLast) {
              FocusScope.of(context).nextFocus();
            } else if (value.isEmpty && !isFirst) {
              FocusScope.of(context).previousFocus();
            }
            setState(() {
              _msg = "";
            });
          },
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: "",
          ),
          style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w600),
          cursorColor: Colors.pink,
        ),
      ),
    );
  }

  void _startCountdown() {
    setState(() {
      _countdown = _resendSeconds;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _currentCode() {
    return _controllers.map((c) => c.text.replaceAll(' ', '')).join();
  }

  void _clearOtpFields() {
    for (final controller in _controllers) {
      controller.clear();
    }
    FocusScope.of(context).requestFocus(_focusNodes[0]);
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
      _msg = "";
    });

    final result = widget.isLogin == true
        ? await _authService.resendLoginOtp(widget.otpToken ?? "")
        : await _otpService.generateOtp(phone: widget.phoneNumber, email: widget.email);

    if (!mounted) return;
    setState(() {
      _isResending = false;
    });

    if (result['is_success'] == true) {
      _startCountdown();
    } else {
      setState(() {
        _msg = result['message'] ?? "Không thể gửi lại mã, vui lòng thử lại";
      });
    }
  }

  Future<void> _handleVerify() async {
    final code = _currentCode();

    if (code.length != _otpLength) {
      setState(() {
        _msg = "Vui lòng nhập đủ $_otpLength số";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _msg = "";
    });

    if (widget.isLogin == true) {
      await _verifyLogin(code);
    } else {
      await _verifyRegister(code);
    }
  }

  Future<void> _verifyLogin(String code) async {
    final result = await _authService.verifyLoginOtp(
      widget.otpToken ?? "",
      code,
    );

    if (!mounted) return;

    if (result['is_success'] == true) {
      await _completeLogin(result);
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (result['status_code'] == 401) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPhoneScreen(
            isForceLogout: true,
            msg: result['message'] ?? "Phiên xác thực đã hết hạn",
          ),
        ),
        (r) => false,
      );
      return;
    }

    _clearOtpFields();
    setState(() {
      _msg = result['message'] ?? "OTP không chính xác";
    });
  }

  Future<void> _verifyRegister(String code) async {
    final result = await _authService.registerWithEmail(
      otpToken: widget.otpToken ?? "",
      otp: code,
      password: widget.password ?? "",
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

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
      setState(() {
        _msg = result['message'] ?? "Xác thực đăng ký thất bại";
      });
    }
  }

  Future<void> _completeLogin(Map<String, dynamic> result) async {
    final homeData = await _appDataService.fetchHomeData();

    _userController.setUserData(
      newId: result['user_id'],
      newPhone: result['phone'] ?? "",
      newFullName: result['full_name'] ?? "Không rõ tên",
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

    setState(() {
      _isLoading = false;
    });

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
        ? HomeScreen()
        : KycFrontIdScreen();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => next),
      (r) => false,
    );
  }
}