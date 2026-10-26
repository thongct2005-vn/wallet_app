import 'dart:async';

import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/src/auth/forgot/forgot_type.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/kyc/kyc_front_id_screen.dart';
import 'package:app/src/services/forgot_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

const int _resendSeconds = 60;

class ForgotOtpScreen extends StatefulWidget {
  final ForgotType type;
  final String phone;
  final String otpToken;
  final String maskedEmail;

  const ForgotOtpScreen({
    super.key,
    required this.type,
    required this.phone,
    required this.otpToken,
    required this.maskedEmail,
  });

  @override
  State<ForgotOtpScreen> createState() => _ForgotOtpScreenState();
}

class _ForgotOtpScreenState extends State<ForgotOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final ForgotService _forgotService = ForgotService();
  bool _isLoading = false;
  bool _isResending = false;
  int _countdown = 0;
  String _msg = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _countdown = _resendSeconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        t.cancel();
      }
    });
  }

  void _backToLogin(String message) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPhoneScreen(isForceLogout: true, msg: message),
      ),
      (r) => false,
    );
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _msg = '';
    });
    final result = await _forgotService.resendOtp(widget.otpToken);
    if (!mounted) return;
    setState(() => _isResending = false);

    if (result['is_success'] == true) {
      _startCountdown();
    } else if (result['status_code'] == 401) {
      _backToLogin(result['message'] ?? 'Phiên xác thực đã hết hạn');
    } else {
      setState(() => _msg = result['message'] ?? 'Không thể gửi lại mã');
    }
  }

  Future<void> _verify() async {
    final code = _otpController.text;
    if (code.length != 6) {
      setState(() => _msg = 'Vui lòng nhập đủ 6 số');
      return;
    }

    setState(() {
      _isLoading = true;
      _msg = '';
    });
    final result = await _forgotService.verifyOtp(
      otpToken: widget.otpToken,
      otp: code,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['is_success'] != true) {
      if (result['status_code'] == 401) {
        _backToLogin(result['message'] ?? 'Phiên xác thực đã hết hạn');
        return;
      }
      _otpController.clear();
      setState(() => _msg = result['message'] ?? 'Mã OTP không chính xác');
      return;
    }

    final hasKyc = result['has_kyc'] == true;
    await DialogUtils.showNotification(
      context,
      title: 'Xác minh danh tính',
      message: hasKyc
          ? 'Vui lòng chụp CCCD và khuôn mặt. Thông tin phải trùng với '
                'giấy tờ bạn đã dùng để định danh tài khoản.'
          : 'Tài khoản của bạn chưa được định danh. Vui lòng chụp CCCD và '
                'khuôn mặt để xác minh và hoàn tất định danh.',
      closeText: 'Tiếp tục',
    );
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KycFrontIdScreen(
          forgot: ForgotKycArgs(
            type: widget.type,
            kycToken: result['kyc_token'],
            phone: widget.phone,
            hasKyc: hasKyc,
          ),
        ),
      ),
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

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Xác nhận OTP',
            style: GoogleFonts.roboto(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        'Mã xác thực đã được gửi đến email ${widget.maskedEmail}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Pinput(
                        controller: _otpController,
                        length: 6,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        defaultPinTheme: pinTheme,
                        focusedPinTheme: pinTheme.copyWith(
                          decoration: pinTheme.decoration!.copyWith(
                            border: Border.all(color: Colors.pink, width: 2),
                          ),
                        ),
                        onChanged: (_) {
                          if (_msg.isNotEmpty) setState(() => _msg = '');
                        },
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: (_countdown > 0 || _isResending)
                            ? null
                            : _resend,
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
                                    ? 'Gửi lại mã sau $_countdown s'
                                    : 'Gửi lại mã',
                                style: GoogleFonts.roboto(fontSize: 15),
                              ),
                      ),
                      if (_msg.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _msg,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            color: Colors.red,
                            fontSize: 13,
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
                    onPressed: _isLoading ? null : _verify,
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
                            'Xác nhận',
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
      ),
    );
  }
}