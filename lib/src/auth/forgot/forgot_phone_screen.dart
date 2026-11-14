import 'package:app/core/utils/format_utils.dart';
import 'package:app/src/auth/auth_ui.dart';
import 'package:app/src/auth/forgot/forgot_otp_screen.dart';
import 'package:app/src/auth/forgot/forgot_type.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/services/forgot_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

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
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ForgotService _forgotService = ForgotService();

  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> _msgNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> _hasFocusNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.initialPhone ?? '';
    _phoneController.addListener(_onPhoneChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onPhoneChanged() {
    if (_msgNotifier.value.isNotEmpty) {
      _msgNotifier.value = '';
    }
  }

  void _onFocusChanged() {
    final focused = _focusNode.hasFocus;
    _hasFocusNotifier.value = focused;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = (focused ? 48.0 : 0.0).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      if ((_scrollController.offset - target).abs() > 2.0) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _focusNode.removeListener(_onFocusChanged);
    _phoneController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _isLoadingNotifier.dispose();
    _msgNotifier.dispose();
    _hasFocusNotifier.dispose();
    super.dispose();
  }

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
      _msgNotifier.value = 'Vui lòng nhập số điện thoại';
      return;
    }
    if (!FormatUtils.isValidPhone(phone)) {
      _msgNotifier.value = 'Số điện thoại không hợp lệ';
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    _isLoadingNotifier.value = true;
    _msgNotifier.value = '';

    final result = await _forgotService.request(phone: phone, type: widget.type);
    if (!mounted) return;
    _isLoadingNotifier.value = false;

    if (result['is_success'] != true) {
      _msgNotifier.value =
          result['message']?.toString() ?? 'Không thể gửi mã OTP';
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
      child: AuthScaffold(
        appBarTitle: widget.type.title,
        onBack: _goBack,
        scrollController: _scrollController,
        hasFocusListenable: _hasFocusNotifier,
        bottomBar: ValueListenableBuilder<bool>(
          valueListenable: _isLoadingNotifier,
          builder: (context, isLoading, _) {
            return AuthPrimaryButton(
              label: 'Gửi mã OTP',
              loading: isLoading,
              onTap: _submit,
            );
          },
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            AuthHeroBanner(
              icon: Iconsax.security,
              badgeText: 'Khôi phục tài khoản',
              title: 'Đặt lại ${widget.type.label}',
              subtitle:
                  'Xác nhận số điện thoại tài khoản để nhận mã OTP qua email đã liên kết, sau đó xác minh nhanh bằng CCCD và khuôn mặt.',
            ),
            const SizedBox(height: 24),
            RepaintBoundary(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: authCardDeco(radius: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Số điện thoại đăng ký',
                      style: kAuthSectionLabelStyle,
                    ),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<String>(
                      valueListenable: _msgNotifier,
                      builder: (context, msg, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AuthPhoneField(
                              controller: _phoneController,
                              focusNode: _focusNode,
                              readOnly: widget.lockPhone,
                              hasError: msg.isNotEmpty,
                              onSubmitted: (_) => _submit(),
                            ),
                            if (msg.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              AuthErrorBanner(message: msg),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Iconsax.shield_tick,
                            size: 16,
                            color: kAuthPink,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Quy trình khôi phục yêu cầu xác thực sinh trắc học eKYC nhằm bảo vệ an toàn số dư của bạn.',
                            style: GoogleFonts.roboto(
                              fontSize: 12.5,
                              color: kAuthMuted,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
