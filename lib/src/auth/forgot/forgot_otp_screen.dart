import 'dart:async';
import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/src/auth/auth_ui.dart';
import 'package:app/src/auth/forgot/forgot_type.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/kyc/kyc_guide_screen.dart';
import 'package:app/src/services/forgot_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

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

class _ForgotOtpScreenState extends State<ForgotOtpScreen>
    with SmoothAutoFocusMixin {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ForgotService _forgotService = ForgotService();

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
    _startCountdown();
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
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdownNotifier.value > 0) {
        _countdownNotifier.value = _countdownNotifier.value - 1;
      } else {
        t.cancel();
      }
    });
  }

  void _backToLogin(String message) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPhoneScreen(isForceLogout: true, msg: message),
      ),
      (r) => false,
    );
  }

  Future<void> _resend() async {
    _isResendingNotifier.value = true;
    _msgNotifier.value = '';

    final result = await _forgotService.resendOtp(widget.otpToken);
    if (!mounted) return;
    _isResendingNotifier.value = false;

    if (result['is_success'] == true) {
      _startCountdown();
      SnackbarUtils.success(context, 'Đã gửi lại mã OTP');
    } else if (result['status_code'] == 401) {
      _backToLogin(result['message'] ?? 'Phiên xác thực đã hết hạn');
    } else {
      _msgNotifier.value =
          result['message']?.toString() ?? 'Không thể gửi lại mã';
    }
  }

  Future<void> _verify() async {
    if (_isLoadingNotifier.value) return;
    final code = _otpController.text.trim();
    if (code.length != 6) {
      _msgNotifier.value = 'Vui lòng nhập đủ 6 số';
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    _isLoadingNotifier.value = true;
    _msgNotifier.value = '';

    final result = await _forgotService.verifyOtp(
      otpToken: widget.otpToken,
      otp: code,
    );
    if (!mounted) return;
    _isLoadingNotifier.value = false;

    if (result['is_success'] != true) {
      if (result['status_code'] == 401) {
        _backToLogin(result['message'] ?? 'Phiên xác thực đã hết hạn');
        return;
      }
      _otpController.clear();
      _msgNotifier.value =
          result['message']?.toString() ?? 'Mã OTP không chính xác';
      requestKeyboardFocus(_otpFocusNode);
      return;
    }

    final hasKyc = result['has_kyc'] == true;
    await DialogUtils.showNotification(
      context,
      title: 'Xác minh danh tính',
      message: hasKyc
          ? 'Vui lòng chụp CCCD và khuôn mặt. Thông tin phải trùng với giấy tờ bạn đã dùng để định danh tài khoản.'
          : 'Tài khoản của bạn chưa được định danh. Vui lòng chụp CCCD và khuôn mặt để xác minh và hoàn tất định danh.',
      closeText: 'Tiếp tục',
    );
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KycGuideScreen(
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
            onTap: _verify,
          );
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          AuthHeroBanner(
            icon: Iconsax.shield_tick,
            badgeText: 'Khôi phục ${widget.type.label}',
            title: 'Nhập mã xác thực OTP',
            subtitle:
                'Mã xác thực gồm 6 chữ số đã được gửi đến email ${widget.maskedEmail}',
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
                          hasError: msg.isNotEmpty,
                          onChanged: (_) {
                            if (_msgNotifier.value.isNotEmpty) {
                              _msgNotifier.value = '';
                            }
                          },
                          onCompleted: (_) => _verify(),
                        ),
                        if (msg.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          AuthErrorBanner(message: msg),
                        ],
                      ],
                    );
                  },
                ),
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
                          onPressed: canResend ? _resend : null,
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
            ),
          ),
        ],
      ),
    );
  }
}
