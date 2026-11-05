import 'package:app/src/auth/auth_ui.dart';
import 'package:app/src/auth/forgot/forgot_type.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/services/forgot_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// Bước cuối: nhập mật khẩu / mã PIN mới (6 số) bằng reset token.
class ForgotNewSecretScreen extends StatefulWidget {
  final ForgotType type;
  final String resetToken;
  final String phone;

  const ForgotNewSecretScreen({
    super.key,
    required this.type,
    required this.resetToken,
    required this.phone,
  });

  @override
  State<ForgotNewSecretScreen> createState() => _ForgotNewSecretScreenState();
}

class _ForgotNewSecretScreenState extends State<ForgotNewSecretScreen>
    with SmoothAutoFocusMixin {
  static final RegExp _sixDigitsRegex = RegExp(r'^\d{6}$');

  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _newFocusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ForgotService _forgotService = ForgotService();

  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isHiddenNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<String> _msgNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> _hasAnyFocusNotifier = ValueNotifier<bool>(false);

  @override
  FocusNode get initialFocusNode => _newFocusNode;

  @override
  void initState() {
    super.initState();
    _newFocusNode.addListener(_onFocusChanged);
    _confirmFocusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    final newFocused = _newFocusNode.hasFocus;
    final confirmFocused = _confirmFocusNode.hasFocus;
    _hasAnyFocusNotifier.value = newFocused || confirmFocused;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final double target;
      if (confirmFocused) {
        target = 105.0;
      } else if (newFocused) {
        target = 45.0;
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
    _newFocusNode.removeListener(_onFocusChanged);
    _confirmFocusNode.removeListener(_onFocusChanged);
    _newController.dispose();
    _confirmController.dispose();
    _newFocusNode.dispose();
    _confirmFocusNode.dispose();
    _scrollController.dispose();
    _isLoadingNotifier.dispose();
    _isHiddenNotifier.dispose();
    _msgNotifier.dispose();
    _hasAnyFocusNotifier.dispose();
    super.dispose();
  }

  void _toLogin(String message) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPhoneScreen(
          initialPhoneNumber: widget.phone,
          isForceLogout: true,
          msg: message,
        ),
      ),
      (r) => false,
    );
  }

  Future<void> _submit() async {
    if (_isLoadingNotifier.value) return;
    final value = _newController.text;
    if (!_sixDigitsRegex.hasMatch(value)) {
      _msgNotifier.value = 'Vui lòng nhập đúng 6 số';
      return;
    }
    if (value != _confirmController.text) {
      _msgNotifier.value = 'Hai lần nhập không khớp';
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    _isLoadingNotifier.value = true;
    _msgNotifier.value = '';

    final result = await _forgotService.resetSecret(
      type: widget.type,
      resetToken: widget.resetToken,
      value: value,
    );
    if (!mounted) return;
    _isLoadingNotifier.value = false;

    if (result['is_success'] == true) {
      _toLogin(
        'Đặt lại ${widget.type.label} thành công. Vui lòng đăng nhập lại.',
      );
      return;
    }
    // Token hết hạn hoặc đã dùng: phải làm lại từ đầu
    if (result['status_code'] == 401) {
      _toLogin(result['message'] ?? 'Phiên đặt lại đã hết hạn');
      return;
    }
    _msgNotifier.value =
        result['message']?.toString() ?? 'Không thể đặt lại';
  }

  @override
  Widget build(BuildContext context) {
    final capitalizedLabel =
        '${widget.type.label[0].toUpperCase()}${widget.type.label.substring(1)}';

    return AuthScaffold(
      appBarTitle: '$capitalizedLabel mới',
      onBack: Navigator.canPop(context) ? () => Navigator.pop(context) : null,
      scrollController: _scrollController,
      hasFocusListenable: _hasAnyFocusNotifier,
      bottomBar: ValueListenableBuilder<bool>(
        valueListenable: _isLoadingNotifier,
        builder: (context, isLoading, _) {
          return AuthPrimaryButton(
            label: 'Xác nhận',
            icon: Iconsax.tick_circle,
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
            badgeText: 'Hoàn tất khôi phục',
            title: 'Thiết lập ${widget.type.label} mới',
            subtitle:
                'Nhập ${widget.type.label} mới gồm 6 chữ số để hoàn tất quá trình đặt lại.',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            decoration: authCardDeco(radius: 22),
            child: ValueListenableBuilder<String>(
              valueListenable: _msgNotifier,
              builder: (context, msg, _) {
                final hasErr = msg.isNotEmpty;
                return ValueListenableBuilder<bool>(
                  valueListenable: _isHiddenNotifier,
                  builder: (context, isHidden, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Nhập ${widget.type.label} mới',
                              style: kAuthSectionLabelStyle,
                            ),
                            InkWell(
                              onTap: () => _isHiddenNotifier.value = !isHidden,
                              borderRadius: BorderRadius.circular(99),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isHidden
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 17,
                                      color: kAuthPinkDark,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isHidden ? 'Hiện số' : 'Ẩn số',
                                      style: GoogleFonts.roboto(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: kAuthPinkDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        AuthOtpInputRow(
                          controller: _newController,
                          focusNode: _newFocusNode,
                          obscureText: isHidden,
                          hasError: hasErr,
                          onChanged: (_) {
                            if (_msgNotifier.value.isNotEmpty) {
                              _msgNotifier.value = '';
                            }
                          },
                          onCompleted: (_) {
                            requestKeyboardFocus(_confirmFocusNode);
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Nhập lại ${widget.type.label} mới',
                          style: kAuthSectionLabelStyle,
                        ),
                        const SizedBox(height: 10),
                        AuthOtpInputRow(
                          controller: _confirmController,
                          focusNode: _confirmFocusNode,
                          obscureText: isHidden,
                          hasError: hasErr,
                          onChanged: (_) {
                            if (_msgNotifier.value.isNotEmpty) {
                              _msgNotifier.value = '';
                            }
                          },
                        ),
                        if (hasErr) ...[
                          const SizedBox(height: 14),
                          AuthErrorBanner(message: msg),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
