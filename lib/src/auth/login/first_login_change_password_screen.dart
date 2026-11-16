import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

/// Màn hình bắt buộc đổi mật khẩu ở lần đăng nhập đầu tiên cho tài khoản USER do ADMIN cấp.
class FirstLoginChangePasswordScreen extends StatefulWidget {
  final String changePasswordToken;
  final String? phoneNumber;
  final AuthService? authService;

  const FirstLoginChangePasswordScreen({
    super.key,
    required this.changePasswordToken,
    this.phoneNumber,
    this.authService,
  });

  @override
  State<FirstLoginChangePasswordScreen> createState() =>
      _FirstLoginChangePasswordScreenState();
}

class _FirstLoginChangePasswordScreenState
    extends State<FirstLoginChangePasswordScreen> {
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  late final AuthService _authService;

  bool _isLoading = false;
  bool _isHidden = true;
  String _msg = '';

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _toLogin(String message) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPhoneScreen(
          initialPhoneNumber: widget.phoneNumber,
          isForceLogout: true,
          msg: message,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _submit() async {
    final newPassword = _newController.text;
    final confirmPassword = _confirmController.text;

    if (!RegExp(r'^\d{6}$').hasMatch(newPassword)) {
      setState(() => _msg = 'Mật khẩu mới phải gồm đúng 6 chữ số');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _msg = 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() {
      _isLoading = true;
      _msg = '';
    });

    final result = await _authService.changeFirstLoginPassword(
      changePasswordToken: widget.changePasswordToken,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['is_success'] == true) {
      final serverMessage = result['message']?.toString();
      _toLogin(
        (serverMessage != null && serverMessage.isNotEmpty)
            ? serverMessage
            : 'Đổi mật khẩu thành công. Vui lòng đăng nhập lại bằng mật khẩu mới.',
      );
      return;
    }

    if (result['status_code'] == 401) {
      _toLogin(
        result['message']?.toString() ??
            'Phiên đổi mật khẩu đã hết hạn. Vui lòng đăng nhập lại.',
      );
      return;
    }

    setState(
      () => _msg =
          result['message']?.toString() ?? 'Không thể đổi mật khẩu. Vui lòng thử lại.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final pinTheme = PinTheme(
      width: 46,
      height: 56,
      textStyle: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
      ),
    );
    final focusedTheme = pinTheme.copyWith(
      decoration: pinTheme.decoration!.copyWith(
        border: Border.all(color: Colors.pink, width: 2),
      ),
    );

    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Đổi mật khẩu lần đầu',
              style: GoogleFonts.roboto(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.pink.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.pink.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            'Vì lý do bảo mật, bạn cần đổi mật khẩu tạm thời sang mật khẩu cá nhân mới (6 chữ số) trước khi tiếp tục sử dụng ví.',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Nhập mật khẩu mới (6 chữ số)',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Pinput(
                            key: const Key('first_login_new_password'),
                            controller: _newController,
                            length: 6,
                            autofocus: true,
                            obscureText: _isHidden,
                            keyboardType: TextInputType.number,
                            defaultPinTheme: pinTheme,
                            focusedPinTheme: focusedTheme,
                            onChanged: (_) {
                              if (_msg.isNotEmpty) setState(() => _msg = '');
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Xác nhận mật khẩu mới',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Pinput(
                            key: const Key('first_login_confirm_password'),
                            controller: _confirmController,
                            length: 6,
                            obscureText: _isHidden,
                            keyboardType: TextInputType.number,
                            defaultPinTheme: pinTheme,
                            focusedPinTheme: focusedTheme,
                            onChanged: (_) {
                              if (_msg.isNotEmpty) setState(() => _msg = '');
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _isHidden = !_isHidden),
                            icon: Icon(
                              _isHidden
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                            ),
                            label: Text(_isHidden ? 'Hiện' : 'Ẩn'),
                          ),
                        ),
                        if (_msg.isNotEmpty)
                          Container(
                            key: const Key('first_login_error_text'),
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _msg,
                              style: GoogleFonts.roboto(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          key: const Key('first_login_submit_button'),
                          onPressed: _isLoading ? null : _submit,
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
                                  'Xác nhận đổi mật khẩu',
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
