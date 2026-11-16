import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/src/auth/auth_ui.dart';
import 'package:app/src/auth/register/create_password.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class RegisterEmailScreen extends StatefulWidget {
  final String? initialEmail;
  final String? phone;
  const RegisterEmailScreen({
    super.key,
    this.initialEmail,
    this.phone,
  });

  @override
  State<RegisterEmailScreen> createState() => _RegisterEmailScreenState();
}

class _RegisterEmailScreenState extends State<RegisterEmailScreen> {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final TextEditingController _emailController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();

  final ValueNotifier<String> _errorNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasFocusNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail ?? '';
    _emailController.addListener(_onEmailChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onEmailChanged() {
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
    _emailController.removeListener(_onEmailChanged);
    _focusNode.removeListener(_onFocusChanged);
    _emailController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _errorNotifier.dispose();
    _isLoadingNotifier.dispose();
    _hasFocusNotifier.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _errorNotifier.value = 'Vui lòng nhập email';
      return;
    }
    if (!_isValidEmail(email)) {
      _errorNotifier.value = 'Email không hợp lệ';
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    _errorNotifier.value = '';
    _isLoadingNotifier.value = true;

    final result = await _authService.checkEmailExist(email);
    if (!mounted) return;
    _isLoadingNotifier.value = false;

    if (result['is_success'] == true) {
      final bool isEmailExists = result['data']['is_email_exists'] == true;
      if (!isEmailExists) {
        DialogUtils.showConfirmation(
          context,
          title: 'Xác nhận địa chỉ Email',
          message:
              'Bạn có muốn dùng email $email để liên kết và đăng ký tài khoản không?',
          cancelText: 'Đổi Email',
          confirmText: 'Xác nhận',
          onConfirm: () {
            // Chuyển thẳng sang màn hình Tạo mật khẩu sau khi xác nhận email
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CreatePasswordScreen(phoneNumber: widget.phone, email: email),
              ),
            );
          },
        );
      } else {
        SnackbarUtils.failure(context, 'Email này đã được sử dụng');
      }
    } else {
      SnackbarUtils.failure(
        context,
        result['message']?.toString() ?? 'Không thể kiểm tra email',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      appBarTitle: 'Liên kết Email',
      onBack: () => Navigator.pop(context),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          const AuthHeroBanner(
            icon: Icons.alternate_email_rounded,
            badgeText: 'Bước 1/3 • Đăng ký tài khoản',
            title: 'Email liên kết của bạn',
            subtitle:
                'Email dùng để nhận mã xác thực OTP, khôi phục tài khoản và nhận sao kê giao dịch.',
          ),
          const SizedBox(height: 24),
          RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: authCardDeco(radius: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Địa chỉ Email', style: kAuthSectionLabelStyle),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<String>(
                    valueListenable: _errorNotifier,
                    builder: (context, err, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AuthTextField(
                            controller: _emailController,
                            focusNode: _focusNode,
                            hintText: 'vidu@gmail.com',
                            leadingIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Iconsax.info_circle,
                          size: 16,
                          color: kAuthPink,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Hãy nhập email bạn đang sử dụng thường xuyên để nhận mã OTP ngay bước tiếp theo.',
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
    );
  }

  bool _isValidEmail(String email) {
    if (email.isEmpty) return false;
    return _emailRegex.hasMatch(email);
  }
}
