import 'package:app/src/auth/forgot/forgot_phone_screen.dart';
import 'package:app/src/auth/forgot/forgot_type.dart';
import 'package:app/src/auth/login/totp_setup_dialog.dart';
import 'package:app/src/auth/register/otp_screen.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPasswordScreen extends StatefulWidget {
  final String? phoneNumber;

  /// Tài khoản đã bật Google Authenticator: ô tích đổi thành "gửi OTP qua email"
  final bool isTotpEnabled;
  const LoginPasswordScreen({
    super.key,
    this.phoneNumber,
    this.isTotpEnabled = false,
  });

  @override
  State<LoginPasswordScreen> createState() => _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends State<LoginPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AuthService _authService = AuthService();
  bool _hasError = false;
  bool _isHidePassword = true;
  bool _isLoading = false;
  String _msg = "";
  // Người dùng chọn dùng Google Authenticator ở các lần đăng nhập sau
  bool _useTotp = false;
  // Đã bật Google Authenticator và người dùng muốn quay lại OTP qua email
  bool _useEmail = false;
  // Mã QR đã tạo (otpauth_uri, secret); null nếu chưa tạo
  Map<String, String>? _totpSetup;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {
        if (_hasError) {
          _hasError = false;
        }
      });
    });
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_passwordController.text.isEmpty) {
      setState(() {
        _hasError = true;
        _msg = "Vui lòng nhập mật khẩu";
      });
      return;
    }
    if (!isValidPassword(_passwordController.text)) {
      setState(() {
        _hasError = true;
        _msg = "Mật khẩu phải có đúng 6 số";
      });
      return;
    }
    if (_useTotp && _totpSetup == null) {
      setState(() {
        _hasError = true;
        _msg = "Vui lòng quét mã QR để liên kết Google Authenticator";
      });
      return;
    }

    setState(() {
      _hasError = false;
      _isLoading = true;
    });

    final result = await _authService.loginWithPhoneAndPassword(
      widget.phoneNumber ?? "",
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (result['is_success'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            phoneNumber: widget.phoneNumber,
            email: result['masked_email'],
            isLogin: true,
            otpToken: result['otp_token'],
            // Tài khoản đã bật Google Authenticator thì nhập mã từ ứng dụng
            isTotp: result['otp_method'] == 'totp',
            // Đã quét QR: sau khi đăng nhập sẽ nhập mã đầu tiên để bật
            enableTotpAfterLogin:
                _useTotp &&
                _totpSetup != null &&
                result['otp_method'] != 'totp',
            // Đã nhập đúng mã Authenticator xong thì chuyển về OTP email
            disableTotpAfterLogin: _useEmail && result['otp_method'] == 'totp',
          ),
        ),
      );
    } else {
      setState(() {
        _msg = result['message'] ?? "Đăng nhập thất bại";
        _hasError = true;
      });
    }
  }

  bool get _optionChecked => widget.isTotpEnabled ? _useEmail : _useTotp;

  void _toggleOption(bool? value) {
    setState(() {
      final next = value ?? !_optionChecked;
      if (widget.isTotpEnabled) {
        _useEmail = next;
      } else {
        _useTotp = next;
      }
    });
  }

  Future<void> _openTotpSetup({bool recover = false}) async {
    final password = _passwordController.text;
    if (!isValidPassword(password)) {
      setState(() {
        _hasError = true;
        _msg = "Nhập mật khẩu 6 số trước khi lấy mã QR";
      });
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await showTotpSetupDialog(
      context,
      phone: widget.phoneNumber ?? "",
      password: password,
      cached: recover ? null : _totpSetup,
      recover: recover,
    );
    if (!recover && result != null && mounted) {
      setState(() => _totpSetup = result);
    }
  }

  // Khung bấm để mở dialog QR (dùng cho cả liên kết mới và lấy lại mã)
  Widget _buildQrBox({
    required String text,
    required IconData trailingIcon,
    required Color trailingColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.pink.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.pink.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.qr_code_2_rounded, color: Colors.pink, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.pink,
                  ),
                ),
              ),
              Icon(trailingIcon, color: trailingColor, size: 22),
            ],
          ),
        ),
      ),
    );
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
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.white.withValues(alpha: 0.95),
          appBar: AppBar(
            title: Text(
              "Nhập mật khẩu",
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.transparent,
            leading: Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 0, 10),
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.arrow_back, size: 20),
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
                    colors: [
                      Colors.blue.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Mật khẩu",
                                      style: GoogleFonts.dancingScript(
                                        color: Colors.pink,
                                        fontSize: 35,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: " của bạn",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 25,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: Container(
                                height: 55,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _hasError
                                        ? Colors.red
                                        : _focusNode.hasFocus
                                        ? Colors.pink
                                        : Colors.grey,
                                    width: _hasError
                                        ? 1
                                        : _focusNode.hasFocus
                                        ? 1
                                        : 0.5,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        textAlign: TextAlign.start,

                                        focusNode: _focusNode,
                                        controller: _passwordController,
                                        maxLength: 6,
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(fontSize: 20),
                                        decoration: InputDecoration(
                                          hintText: "Mật khẩu 6 số",
                                          hintStyle: GoogleFonts.roboto(
                                            color: Colors.grey,
                                          ),

                                          border: InputBorder.none,
                                          counterText: "",
                                          contentPadding: EdgeInsets.only(
                                            left: 10,
                                            top: 8,
                                          ),
                                          suffixIcon: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _isHidePassword =
                                                    !_isHidePassword;
                                              });
                                            },
                                            icon: Icon(
                                              _isHidePassword
                                                  ? Icons
                                                        .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                            ),
                                          ),
                                        ),
                                        obscureText: _isHidePassword,
                                        cursorColor: Colors.pink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_hasError) ...[
                              const SizedBox(height: 5),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.red,
                                      size: 15,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      _msg,
                                      style: GoogleFonts.roboto(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 8,
                              ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ForgotPhoneScreen(
                                        type: ForgotType.password,
                                        initialPhone: widget.phoneNumber,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Quên mật khẩu?',
                                    style: GoogleFonts.roboto(
                                      fontSize: 15,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // ----- Google Authenticator -----
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: InkWell(
                                onTap: () => _toggleOption(null),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _optionChecked,
                                        activeColor: Colors.pink,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        onChanged: _toggleOption,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        widget.isTotpEnabled
                                            ? 'Gửi OTP qua email thay cho Google '
                                                  'Authenticator ở các lần đăng nhập sau'
                                            : 'Dùng mã Google Authenticator thay cho OTP '
                                                  'qua email ở các lần đăng nhập sau',
                                        style: GoogleFonts.roboto(
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (widget.isTotpEnabled && _useEmail)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  56,
                                  6,
                                  24,
                                  0,
                                ),
                                child: Text(
                                  'Lần đăng nhập này bạn vẫn nhập mã Google '
                                  'Authenticator, từ lần sau sẽ nhận OTP qua email.',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12.5,
                                    height: 1.4,
                                    color: Colors.black.withValues(alpha: 0.55),
                                  ),
                                ),
                              ),
                            if (_useTotp && !widget.isTotpEnabled)
                              _buildQrBox(
                                text: _totpSetup == null
                                    ? 'Quét mã QR để liên kết Google Authenticator'
                                    : 'Đã tạo mã QR, nhấn để xem lại',
                                trailingIcon: _totpSetup == null
                                    ? Icons.chevron_right_rounded
                                    : Icons.check_circle_rounded,
                                trailingColor: _totpSetup == null
                                    ? Colors.pink
                                    : Colors.green,
                                onTap: _openTotpSetup,
                              ),

                            if (widget.isTotpEnabled)
                              _buildQrBox(
                                text: 'Hiển thị mã QR liên kết Google Authenticator',
                                trailingIcon: Icons.chevron_right_rounded,
                                trailingColor: Colors.pink,
                                onTap: () => _openTotpSetup(recover: true),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            disabledBackgroundColor: Colors.black.withValues(
                              alpha: 0.1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadiusGeometry.circular(10),
                            ),
                          ),

                          child: _isLoading
                              ? SizedBox(
                                  width: 25,
                                  height: 25,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Xác nhận",
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 25,
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
}

bool isValidPassword(String password) {
  if (password.isEmpty) {
    return false;
  }
  final RegExp phoneRegex = RegExp(r'^\d{6}$');
  return phoneRegex.hasMatch(password);
}
