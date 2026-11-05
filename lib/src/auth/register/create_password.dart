import 'package:app/src/auth/auth_ui.dart';
import 'package:app/src/auth/register/otp_screen.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class CreatePasswordScreen extends StatefulWidget {
  final String? phoneNumber;
  final String? email;
  const CreatePasswordScreen({super.key, this.phoneNumber, this.email});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  static final List<TextInputFormatter> _digitsOnly = [
    FilteringTextInputFormatter.digitsOnly,
  ];

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  final AuthService _authService = AuthService();
  final FocusNode _focusPassword = FocusNode();
  final FocusNode _focusConfirm = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final ValueNotifier<String> _errorNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> _isHidePasswordNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isHideConfirmNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasAnyFocusNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_clearError);
    _passwordConfirmController.addListener(_clearError);
    _focusPassword.addListener(_onFocusChanged);
    _focusConfirm.addListener(_onFocusChanged);
  }

  void _clearError() {
    if (_errorNotifier.value.isNotEmpty) {
      _errorNotifier.value = '';
    }
  }

  void _onFocusChanged() {
    final pwdFocused = _focusPassword.hasFocus;
    final confirmFocused = _focusConfirm.hasFocus;
    _hasAnyFocusNotifier.value = pwdFocused || confirmFocused;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final double target;
      if (confirmFocused) {
        target = 105.0;
      } else if (pwdFocused) {
        target = 50.0;
      } else {
        target = 0.0;
      }
      final clamped = target.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      if ((_scrollController.offset - clamped).abs() > 2.0) {
        _scrollController.animateTo(
          clamped,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_clearError);
    _passwordConfirmController.removeListener(_clearError);
    _focusPassword.removeListener(_onFocusChanged);
    _focusConfirm.removeListener(_onFocusChanged);
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _focusPassword.dispose();
    _focusConfirm.dispose();
    _scrollController.dispose();
    _errorNotifier.dispose();
    _isHidePasswordNotifier.dispose();
    _isHideConfirmNotifier.dispose();
    _isLoadingNotifier.dispose();
    _hasAnyFocusNotifier.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final pwd = _passwordController.text;
    final confirm = _passwordConfirmController.text;

    if (pwd.isEmpty) {
      _errorNotifier.value = 'Vui lòng nhập mật khẩu';
      return;
    }
    if (confirm.isEmpty) {
      _errorNotifier.value = 'Vui lòng nhập xác nhận mật khẩu';
      return;
    }
    if (!isValidPassword(pwd)) {
      _errorNotifier.value = 'Mật khẩu phải có đúng 6 số';
      return;
    }
    if (confirm != pwd) {
      _errorNotifier.value = 'Mật khẩu và mật khẩu xác nhận không khớp';
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    _errorNotifier.value = '';
    _isLoadingNotifier.value = true;

    final result = await _authService.register(
      widget.phoneNumber ?? '',
      widget.email ?? '',
    );

    if (!mounted) return;
    _isLoadingNotifier.value = false;

    if (result['is_success'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phoneNumber: widget.phoneNumber,
            email: widget.email,
            isLogin: false,
            otpToken: result['data']['otp_token'],
            password: pwd,
          ),
        ),
      );
    } else {
      _errorNotifier.value =
          result['message']?.toString() ?? 'Không thể tạo tài khoản';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      appBarTitle: 'Tạo mật khẩu',
      onBack: () => Navigator.pop(context),
      scrollController: _scrollController,
      hasFocusListenable: _hasAnyFocusNotifier,
      bottomBar: ValueListenableBuilder<bool>(
        valueListenable: _isLoadingNotifier,
        builder: (context, isLoading, _) {
          return AuthPrimaryButton(
            label: 'Tiếp tục',
            loading: isLoading,
            onTap: _onSubmit,
          );
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          const AuthHeroBanner(
            icon: Iconsax.security,
            badgeText: 'Bước 2/3 • Thiết lập bảo mật',
            title: 'Tạo mật khẩu đăng nhập',
            subtitle:
                'Thiết lập mật khẩu gồm 6 chữ số để bảo vệ tài khoản Ví Mio của bạn.',
          ),
          const SizedBox(height: 24),
          RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: authCardDeco(radius: 22),
              child: ValueListenableBuilder<String>(
                valueListenable: _errorNotifier,
                builder: (context, err, _) {
                  final hasErr = err.isNotEmpty;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mật khẩu mới (6 số)', style: kAuthSectionLabelStyle),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isHidePasswordNotifier,
                        builder: (context, isHidden, _) {
                          return AuthTextField(
                            controller: _passwordController,
                            focusNode: _focusPassword,
                            hintText: 'Nhập mật khẩu 6 số',
                            leadingIcon: Icons.lock_outline_rounded,
                            obscureText: isHidden,
                            onToggleObscure: () {
                              _isHidePasswordNotifier.value = !isHidden;
                            },
                            hasError: hasErr,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  signed: false,
                                  decimal: false,
                                ),
                            textInputAction: TextInputAction.next,
                            inputFormatters: _digitsOnly,
                            maxLength: 6,
                            onSubmitted: (_) =>
                                requestKeyboardFocus(_focusConfirm),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Xác nhận lại mật khẩu',
                        style: kAuthSectionLabelStyle,
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isHideConfirmNotifier,
                        builder: (context, isHidden, _) {
                          return AuthTextField(
                            controller: _passwordConfirmController,
                            focusNode: _focusConfirm,
                            hintText: 'Nhập lại mật khẩu 6 số',
                            leadingIcon: Icons.lock_reset_rounded,
                            obscureText: isHidden,
                            onToggleObscure: () {
                              _isHideConfirmNotifier.value = !isHidden;
                            },
                            hasError: hasErr,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  signed: false,
                                  decimal: false,
                                ),
                            inputFormatters: _digitsOnly,
                            maxLength: 6,
                            onSubmitted: (_) => _onSubmit(),
                          );
                        },
                      ),
                      if (hasErr) ...[
                        const SizedBox(height: 12),
                        AuthErrorBanner(message: err),
                      ],
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
                              'Không đặt mật khẩu trùng ngày sinh hoặc dãy số dễ đoán.',
                              style: GoogleFonts.roboto(
                                fontSize: 12.5,
                                color: kAuthMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
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
