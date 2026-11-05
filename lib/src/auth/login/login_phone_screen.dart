import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/src/auth/auth_ui.dart';
import 'package:app/src/auth/register/register_email.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:app/src/services/otp_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'login_password_screen.dart';

class LoginPhoneScreen extends StatefulWidget {
  final String? initialPhoneNumber;
  final bool? isRegisterSucess;
  final bool? isForceLogout;
  final String? msg;
  const LoginPhoneScreen({
    super.key,
    this.initialPhoneNumber,
    this.isRegisterSucess,
    this.isForceLogout,
    this.msg,
  });

  @override
  State<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends State<LoginPhoneScreen> {
  static final RegExp _phoneRegex = RegExp(r'^(0|)[3|5|7|8|9][0-9]{8}$');

  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final OtpService _otpService = OtpService();
  final AuthService _authService = AuthService();

  final ValueNotifier<String> _errorNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isSendingOtpNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasFocusNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.initialPhoneNumber ?? '';
    _phoneController.addListener(_onPhoneChanged);
    _focusNode.addListener(_onFocusChanged);

    if (widget.isRegisterSucess == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          SnackbarUtils.success(context, 'Tạo ví thành công');
        }
      });
    }
    if (widget.isForceLogout == true && widget.msg != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          DialogUtils.showNotification(
            context,
            title: 'Thông báo',
            message: widget.msg!,
          );
        }
      });
    }
  }

  void _onPhoneChanged() {
    if (_errorNotifier.value.isNotEmpty) {
      _errorNotifier.value = '';
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
    _errorNotifier.dispose();
    _isLoadingNotifier.dispose();
    _isSendingOtpNotifier.dispose();
    _hasFocusNotifier.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _errorNotifier.value = 'Vui lòng nhập số điện thoại';
      return;
    }
    if (!_isValidPhoneNumber(phone)) {
      _errorNotifier.value = 'Số điện thoại không hợp lệ';
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    _errorNotifier.value = '';
    _isLoadingNotifier.value = true;

    final result = await _authService.checkPhoneExist(phone);
    if (!mounted) return;
    _isLoadingNotifier.value = false;

    if (result['is_success'] == true) {
      final bool isPhoneExists = result['data']['is_phone_exists'] == true;
      if (!isPhoneExists) {
        DialogUtils.showConfirmation(
          context,
          title: 'Đăng ký tài khoản mới',
          message:
              'Bạn có muốn dùng số điện thoại $phone để đăng ký tài khoản Ví Mio không?',
          cancelText: 'Đổi SĐT',
          confirmText: 'Xác nhận',
          onConfirm: () async {
            _isSendingOtpNotifier.value = true;
            await _otpService.generateOtp(phone: phone, email: null);
            if (!mounted) return;
            _isSendingOtpNotifier.value = false;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RegisterEmailScreen(initialEmail: null, phone: phone),
              ),
            );
          },
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoginPasswordScreen(
              phoneNumber: phone,
              // Server báo tài khoản đã bật Google Authenticator
              isTotpEnabled: result['data']['otp_method'] == 'totp',
            ),
          ),
        );
      }
    } else {
      SnackbarUtils.failure(
        context,
        result['message']?.toString() ?? 'Có lỗi xảy ra, vui lòng thử lại',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AuthScaffold(
        appBarTitle: 'Đăng nhập / Đăng ký',
        scrollController: _scrollController,
        hasFocusListenable: _hasFocusNotifier,
        bottomBar: ValueListenableBuilder<bool>(
          valueListenable: _isLoadingNotifier,
          builder: (context, isLoading, _) {
            return AuthPrimaryButton(
              label: 'Tiếp tục',
              loading: isLoading,
              onTap: _onContinue,
            );
          },
        ),
        overlay: ValueListenableBuilder<bool>(
          valueListenable: _isSendingOtpNotifier,
          builder: (context, isSending, _) {
            if (!isSending) return const SizedBox.shrink();
            return const AuthLoadingOverlay(label: 'Đang khởi tạo đăng ký...');
          },
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const AuthHeroBanner(
              icon: Iconsax.wallet_3,
              badgeText: 'Ví điện tử Mio',
              title: 'Bắt đầu với số điện thoại',
              subtitle:
                  'Nhập số điện thoại để đăng nhập hoặc mở ví mới hoàn toàn miễn phí chỉ trong 1 phút.',
            ),
            const SizedBox(height: 24),
            RepaintBoundary(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: authCardDeco(radius: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Số điện thoại của bạn', style: kAuthSectionLabelStyle),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<String>(
                      valueListenable: _errorNotifier,
                      builder: (context, err, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AuthPhoneField(
                              controller: _phoneController,
                              focusNode: _focusNode,
                              hasError: err.isNotEmpty,
                              onSubmitted: (_) => _onContinue(),
                            ),
                            if (err.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              AuthErrorBanner(message: err),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Iconsax.shield_tick,
                          size: 16,
                          color: kAuthSuccess,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Kết nối được bảo vệ bằng xác thực hai lớp an toàn.',
                            style: GoogleFonts.roboto(
                              fontSize: 12.5,
                              color: kAuthMuted,
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

  bool _isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return false;
    return _phoneRegex.hasMatch(phone);
  }
}
