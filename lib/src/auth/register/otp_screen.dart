import 'dart:async';

import 'package:app/core/widgets/circle_back_button.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/auth/register/create_password.dart';
import 'package:app/src/services/otp_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class OtpScreen extends StatefulWidget {
  final String? phoneNumber;
  const OtpScreen({super.key, this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _numberA = TextEditingController();
  final TextEditingController _numberB = TextEditingController();
  final TextEditingController _numberC = TextEditingController();
  final TextEditingController _numberD = TextEditingController();
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final OtpService _otpService = OtpService();
  bool _isLoading = false;
  bool _isResending = false;
  int _countdown = 0;
  String _msg = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _numberA.dispose();
    _numberB.dispose();
    _numberC.dispose();
    _numberD.dispose();
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
                  onPressed: () => Navigator.pushReplacement(
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
                                        "Xác thực số điện thoại",
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
                                      children: [
                                        const TextSpan(
                                          text:
                                              "Mã xác thực sẽ được gửi đến số điện thoại ",
                                        ),
                                        TextSpan(
                                          text: widget.phoneNumber ?? "",
                                          style: GoogleFonts.roboto(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const TextSpan(
                                          text:
                                              ". Nếu không nhận được mã vui lòng bấm gửi lại mã.",
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
                              children: [
                                _buildOtpBox(context, _numberA, index: 0),
                                const SizedBox(width: 12),
                                _buildOtpBox(context, _numberB, index: 1),
                                const SizedBox(width: 12),
                                _buildOtpBox(context, _numberC, index: 2),
                                const SizedBox(width: 12),
                                _buildOtpBox(context, _numberD, index: 3),
                              ],
                            ),
                            const SizedBox(height: 24),
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

  Widget _buildOtpBox(
    BuildContext context,
    TextEditingController controller, {
    required int index,
  }) {
    final bool isFirst = index == 0;
    final bool isLast = index == 3;
    return Container(
      height: 64,
      width: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          controller: controller,
          focusNode: _focusNodes[index],
          autofocus: isFirst,
          maxLength: 1,
          keyboardType: TextInputType.number,
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
          style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.w600),
          cursorColor: Colors.pink,
        ),
      ),
    );
  }

  void _startCountdown() {
    setState(() {
      _countdown = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formattCode(String a, String b, String c, String d) {
    return a.replaceAll(' ', '') +
        b.replaceAll(' ', '') +
        c.replaceAll(' ', '') +
        d.replaceAll(' ', '');
  }

  void _clearOtpFields() {
    _numberA.clear();
    _numberB.clear();
    _numberC.clear();
    _numberD.clear();
    FocusScope.of(context).requestFocus(_focusNodes[0]);
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
      _msg = "";
    });

    final result = await _otpService.generateOtp(phone: widget.phoneNumber);

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
    final code = _formattCode(
      _numberA.text,
      _numberB.text,
      _numberC.text,
      _numberD.text,
    );

    if (code.length != 4) {
      setState(() {
        _msg = "Vui lòng nhập đủ 4 số";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _msg = "";
    });

    final result = await _otpService.verifyOtp(
      phone: widget.phoneNumber,
      otp: code,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['is_success'] == true) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CreatePasswordScreen(phoneNumber: widget.phoneNumber),
        ),
      );
    } else {
      _clearOtpFields();
      setState(() {
        _msg = result['message'] ?? "OTP không chính xác";
      });
    }
  }
}
