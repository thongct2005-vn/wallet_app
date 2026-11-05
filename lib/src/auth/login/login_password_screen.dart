import 'package:app/src/auth/auth_ui.dart';
import 'package:app/src/auth/forgot/forgot_phone_screen.dart';
import 'package:app/src/auth/forgot/forgot_type.dart';
import 'package:app/src/auth/login/totp_setup_dialog.dart';
import 'package:app/src/auth/register/otp_screen.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

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
  static final List<TextInputFormatter> _digitsOnly = [
    FilteringTextInputFormatter.digitsOnly,
  ];

  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();

  final ValueNotifier<String> _errorNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> _isHidePasswordNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasFocusNotifier = ValueNotifier<bool>(false);

  // Người dùng chọn dùng Google Authenticator ở các lần đăng nhập sau
  bool _useTotp = false;
  // Đã bật Google Authenticator và người dùng muốn quay lại OTP qua email
  bool _useEmail = false;
  // Mã QR đã tạo (otpauth_uri, secret); null nếu chưa tạo
  Map<String, String>? _totpSetup;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onPasswordChanged() {
    if (_errorNotifier.value.isNotEmpty) {
      _errorNotifier.value = '';
    }
  }

  void _onFocusChanged() {
    final focused = _focusNode.hasFocus;
    _hasFocusNotifier.value = focused;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = (focused ? 52.0 : 0.0).clamp(
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
    _passwordController.removeListener(_onPasswordChanged);
    _focusNode.removeListener(_onFocusChanged);
    _passwordController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _errorNotifier.dispose();
    _isHidePasswordNotifier.dispose();
    _isLoadingNotifier.dispose();
    _hasFocusNotifier.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      _errorNotifier.value = 'Vui lòng nhập mật khẩu';
      return;
    }
    if (!isValidPassword(password)) {
      _errorNotifier.value = 'Mật khẩu phải có đúng 6 số';
      return;
    }
    if (_useTotp && _totpSetup == null) {
      _errorNotifier.value =
          'Vui lòng quét mã QR để liên kết Google Authenticator';
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    _errorNotifier.value = '';
    _isLoadingNotifier.value = true;

    final result = await _authService.loginWithPhoneAndPassword(
      widget.phoneNumber ?? '',
      password,
    );

    if (!mounted) return;
    _isLoadingNotifier.value = false;

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
      _errorNotifier.value =
          result['message']?.toString() ?? 'Đăng nhập thất bại';
    }
  }

  bool get _optionChecked => widget.isTotpEnabled ? _useEmail : _useTotp;

  void _toggleOption([bool? value]) {
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
      _errorNotifier.value = 'Nhập mật khẩu 6 số trước khi lấy mã QR';
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await showTotpSetupDialog(
      context,
      phone: widget.phoneNumber ?? '',
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
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: kAuthPinkSoft.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kAuthPink.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: kAuthPinkDark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.roboto(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: kAuthPinkDark,
                    ),
                  ),
                ),
                Icon(trailingIcon, color: trailingColor, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phoneDisplay = (widget.phoneNumber ?? '').isNotEmpty
        ? 'SĐT: ${widget.phoneNumber}'
        : null;

    return AuthScaffold(
      appBarTitle: 'Nhập mật khẩu',
      onBack: () => Navigator.pop(context),
      scrollController: _scrollController,
      hasFocusListenable: _hasFocusNotifier,
      bottomBar: ValueListenableBuilder<bool>(
        valueListenable: _isLoadingNotifier,
        builder: (context, isLoading, _) {
          return AuthPrimaryButton(
            label: 'Xác nhận',
            loading: isLoading,
            onTap: _handleLogin,
          );
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          AuthHeroBanner(
            icon: Iconsax.security,
            badgeText: phoneDisplay,
            title: 'Nhập mật khẩu của bạn',
            subtitle:
                'Nhập mật khẩu gồm 6 chữ số để tiếp tục đăng nhập vào Ví Mio.',
          ),
          const SizedBox(height: 22),
          RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: authCardDeco(radius: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mật khẩu đăng nhập', style: kAuthSectionLabelStyle),
                      GestureDetector(
                        onTap: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ForgotPhoneScreen(
                                type: ForgotType.password,
                                initialPhone: widget.phoneNumber,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Quên mật khẩu?',
                          style: GoogleFonts.roboto(
                            fontSize: 13.5,
                            color: kAuthPinkDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<String>(
                    valueListenable: _errorNotifier,
                    builder: (context, err, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ValueListenableBuilder<bool>(
                            valueListenable: _isHidePasswordNotifier,
                            builder: (context, isHidden, _) {
                              return AuthTextField(
                                controller: _passwordController,
                                focusNode: _focusNode,
                                hintText: 'Nhập mật khẩu 6 số',
                                leadingIcon: Icons.lock_outline_rounded,
                                obscureText: isHidden,
                                onToggleObscure: () {
                                  _isHidePasswordNotifier.value = !isHidden;
                                },
                                hasError: err.isNotEmpty,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      signed: false,
                                      decimal: false,
                                    ),
                                inputFormatters: _digitsOnly,
                                maxLength: 6,
                                onSubmitted: (_) => _handleLogin(),
                              );
                            },
                          ),
                          if (err.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            AuthErrorBanner(message: err),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ----- Google Authenticator -----
          Container(
            padding: const EdgeInsets.all(16),
            decoration: authCardDeco(radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _toggleOption(),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 22,
                          width: 22,
                          child: Checkbox(
                            value: _optionChecked,
                            activeColor: kAuthPink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            side: const BorderSide(
                              color: kAuthMuted,
                              width: 1.4,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: _toggleOption,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.isTotpEnabled
                                ? 'Gửi OTP qua email thay cho Google Authenticator ở các lần đăng nhập sau'
                                : 'Dùng mã Google Authenticator thay cho OTP qua email ở các lần đăng nhập sau',
                            style: GoogleFonts.roboto(
                              fontSize: 13.5,
                              height: 1.4,
                              color: kAuthText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.isTotpEnabled && _useEmail)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 6, 4, 0),
                    child: Text(
                      'Lần đăng nhập này bạn vẫn nhập mã Google Authenticator, từ lần sau sẽ nhận OTP qua email.',
                      style: GoogleFonts.roboto(
                        fontSize: 12.5,
                        height: 1.4,
                        color: kAuthMuted,
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
                        ? kAuthPinkDark
                        : kAuthSuccess,
                    onTap: _openTotpSetup,
                  ),
                if (widget.isTotpEnabled)
                  _buildQrBox(
                    text: 'Hiển thị mã QR liên kết Google Authenticator',
                    trailingIcon: Icons.chevron_right_rounded,
                    trailingColor: kAuthPinkDark,
                    onTap: () => _openTotpSetup(recover: true),
                  ),
              ],
            ),
          ),
        ],
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
