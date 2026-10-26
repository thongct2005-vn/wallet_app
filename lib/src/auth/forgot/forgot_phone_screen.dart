
import 'package:app/src/auth/forgot/forgot_otp_screen.dart';
import 'package:app/src/auth/forgot/forgot_type.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/services/forgot_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';


class ForgotPhoneScreen extends StatefulWidget {
  final ForgotType type;
  final String? initialPhone;

  /// Khoá ô số điện thoại (dùng cho quên PIN, vì đã biết tài khoản)
  final bool lockPhone;

  const ForgotPhoneScreen({
    super.key,
    required this.type,
    this.initialPhone,
    this.lockPhone = false,
  });

  @override
  State<ForgotPhoneScreen> createState() => _ForgotPhoneScreenState();
}

class _ForgotPhoneScreenState extends State<ForgotPhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final ForgotService _forgotService = ForgotService();
  bool _isLoading = false;
  String _msg = '';

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.initialPhone ?? '';
    _phoneController.addListener(() {
      if (_msg.isNotEmpty) setState(() => _msg = '');
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) =>
      RegExp(r'^(0|)[3|5|7|8|9][0-9]{8}$').hasMatch(phone);

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPhoneScreen()),
        (r) => false,
      );
    }
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _msg = 'Vui lòng nhập số điện thoại');
      return;
    }
    if (!_isValidPhone(phone)) {
      setState(() => _msg = 'Số điện thoại không hợp lệ');
      return;
    }

    setState(() {
      _isLoading = true;
      _msg = '';
    });
    final result = await _forgotService.request(phone: phone, type: widget.type);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['is_success'] != true) {
      setState(() => _msg = result['message'] ?? 'Không thể gửi mã OTP');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: kForgotOtpRoute),
        builder: (_) => ForgotOtpScreen(
          type: widget.type,
          phone: phone,
          otpToken: result['otp_token'],
          maskedEmail: result['masked_email'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white.withValues(alpha: 0.95),
          appBar: AppBar(
            title: Text(
              widget.type.title,
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: IconButton(
              onPressed: _goBack,
              icon: const Icon(Icons.arrow_back, size: 22),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          'Đặt lại ${widget.type.label}',
                          style: GoogleFonts.roboto(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nhập số điện thoại của tài khoản. Chúng tôi sẽ gửi mã OTP '
                          'về email đã đăng ký, sau đó bạn cần xác minh bằng CCCD và khuôn mặt.',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          height: 55,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: widget.lockPhone
                                ? Colors.grey.shade100
                                : Colors.white,
                            border: Border.all(
                              color: _msg.isNotEmpty ? Colors.red : Colors.grey,
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _phoneController,
                            readOnly: widget.lockPhone,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(fontSize: 20),
                            cursorColor: Colors.pink,
                            decoration: const InputDecoration(
                              hintText: 'Số điện thoại',
                              border: InputBorder.none,
                              counterText: '',
                            ),
                          ),
                        ),
                        if (_msg.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Colors.red,
                                size: 15,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  _msg,
                                  style: GoogleFonts.roboto(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        disabledBackgroundColor: Colors.black.withValues(
                          alpha: 0.1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 25,
                              width: 25,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Gửi mã OTP',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 22,
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
    );
  }
}