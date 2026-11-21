import 'package:app/src/auth/auth_ui.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// Màn hình bắt buộc đổi mật khẩu trong lần đăng nhập đầu tiên.
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
    extends State<FirstLoginChangePasswordScreen>
    with SmoothAutoFocusMixin {
  static final List<TextInputFormatter> _digitsOnly = [
    FilteringTextInputFormatter.digitsOnly,
  ];

  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _newFocusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final ValueNotifier<String> _errorNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> _isHideNewNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isHideConfirmNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasFocusNotifier = ValueNotifier<bool>(false);

  late final AuthService _authService;

  @override
  FocusNode get initialFocusNode => _newFocusNode;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _newController.addListener(_clearErrorOnEdit);
    _confirmController.addListener(_clearErrorOnEdit);
    _newFocusNode.addListener(_onFocusChanged);
    _confirmFocusNode.addListener(_onFocusChanged);
  }

  void _clearErrorOnEdit() {
    if (_errorNotifier.value.isNotEmpty) {
      _errorNotifier.value = '';
    }
  }

  void _onFocusChanged() {
    final focused = _newFocusNode.hasFocus || _confirmFocusNode.hasFocus;
    _hasFocusNotifier.value = focused;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target =
          (_confirmFocusNode.hasFocus
                  ? 84.0
                  : focused
                  ? 44.0
                  : 0.0)
              .clamp(0.0, _scrollController.position.maxScrollExtent);
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
    _newController.removeListener(_clearErrorOnEdit);
    _confirmController.removeListener(_clearErrorOnEdit);
    _newFocusNode.removeListener(_onFocusChanged);
    _confirmFocusNode.removeListener(_onFocusChanged);
    _newController.dispose();
    _confirmController.dispose();
    _newFocusNode.dispose();
    _confirmFocusNode.dispose();
    _scrollController.dispose();
    _errorNotifier.dispose();
    _isHideNewNotifier.dispose();
    _isHideConfirmNotifier.dispose();
    _isLoadingNotifier.dispose();
    _hasFocusNotifier.dispose();
    super.dispose();
  }

  void _navigateBackToLogin(String message) {
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

  Future<void> _handleSubmit() async {
    if (_isLoadingNotifier.value) return;

    final newPassword = _newController.text.trim();
    final confirmPassword = _confirmController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(newPassword)) {
      _errorNotifier.value = 'Mật khẩu mới phải gồm đúng 6 chữ số';
      return;
    }
    if (confirmPassword != newPassword) {
      _errorNotifier.value = 'Mật khẩu xác nhận không khớp';
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    _errorNotifier.value = '';
    _isLoadingNotifier.value = true;

    final result = await _authService.changeFirstLoginPassword(
      changePasswordToken: widget.changePasswordToken,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    if (!mounted) return;
    _isLoadingNotifier.value = false;

    if (result['is_success'] == true) {
      _navigateBackToLogin(
        result['message']?.toString() ??
            'Đổi mật khẩu thành công. Vui lòng đăng nhập lại bằng mật khẩu mới',
      );
      return;
    }

    if (result['status_code'] == 401) {
      _navigateBackToLogin(
        result['message']?.toString() ??
            'Phiên đổi mật khẩu lần đầu đã hết hạn, vui lòng đăng nhập lại',
      );
      return;
    }

    _errorNotifier.value =
        result['message']?.toString() ?? 'Không thể đổi mật khẩu mới';
  }

  @override
  Widget build(BuildContext context) {
    final phone = (widget.phoneNumber ?? '').trim();
    final badgeText = phone.isNotEmpty
        ? 'SĐT: $phone'
        : 'Lần đăng nhập đầu tiên';

    return PopScope(
      canPop: false,
      child: AuthScaffold(
        appBarTitle: 'Đổi mật khẩu lần đầu',
        scrollController: _scrollController,
        hasFocusListenable: _hasFocusNotifier,
        bottomBar: ValueListenableBuilder<bool>(
          valueListenable: _isLoadingNotifier,
          builder: (context, isLoading, _) {
            return AuthPrimaryButton(
              key: const Key('first_login_submit_button'),
              label: 'Xác nhận đổi mật khẩu',
              icon: Icons.check_circle_outline_rounded,
              loading: isLoading,
              onTap: _handleSubmit,
            );
          },
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            AuthHeroBanner(
              icon: Iconsax.shield_tick,
              badgeText: badgeText,
              title: 'Thiết lập mật khẩu mới',
              subtitle:
                  'Đây là lần đăng nhập đầu tiên. Vui lòng tạo mật khẩu mới gồm 6 chữ số để bảo vệ tài khoản Ví LumaPay.',
            ),
            const SizedBox(height: 22),
            RepaintBoundary(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: authCardDeco(radius: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mật khẩu mới', style: kAuthSectionLabelStyle),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<String>(
                      valueListenable: _errorNotifier,
                      builder: (context, err, _) {
                        final hasErr = err.isNotEmpty;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ValueListenableBuilder<bool>(
                              valueListenable: _isHideNewNotifier,
                              builder: (context, isHidden, _) {
                                return AuthTextField(
                                  key: const Key('first_login_new_password'),
                                  controller: _newController,
                                  focusNode: _newFocusNode,
                                  hintText: 'Nhập mật khẩu mới (6 số)',
                                  leadingIcon: Icons.lock_outline_rounded,
                                  obscureText: isHidden,
                                  onToggleObscure: () {
                                    _isHideNewNotifier.value = !isHidden;
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
                                      requestKeyboardFocus(_confirmFocusNode),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Xác nhận mật khẩu mới',
                              style: kAuthSectionLabelStyle,
                            ),
                            const SizedBox(height: 10),
                            ValueListenableBuilder<bool>(
                              valueListenable: _isHideConfirmNotifier,
                              builder: (context, isHidden, _) {
                                return AuthTextField(
                                  key: const Key(
                                    'first_login_confirm_password',
                                  ),
                                  controller: _confirmController,
                                  focusNode: _confirmFocusNode,
                                  hintText: 'Nhập lại mật khẩu mới (6 số)',
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
                                  textInputAction: TextInputAction.done,
                                  inputFormatters: _digitsOnly,
                                  maxLength: 6,
                                  onSubmitted: (_) => _handleSubmit(),
                                );
                              },
                            ),
                            if (hasErr) ...[
                              const SizedBox(height: 14),
                              AuthErrorBanner(
                                key: const Key('first_login_error_text'),
                                message: err,
                              ),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: kAuthPinkSoft.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kAuthPink.withValues(alpha: 0.18)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 17,
                      color: kAuthPinkDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mật khẩu mới gồm đúng 6 chữ số và không được trùng mật khẩu tạm thời đã được cấp. Sau khi đổi xong, bạn sẽ đăng nhập lại bằng mật khẩu mới.',
                      style: GoogleFonts.roboto(
                        fontSize: 12.5,
                        height: 1.45,
                        color: kAuthText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
