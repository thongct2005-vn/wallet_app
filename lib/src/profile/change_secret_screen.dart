import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/dialog_utils.dart';
import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/main.dart';
import 'package:app/src/auth/auth_ui.dart';
import 'package:app/src/auth/forgot/forgot_phone_screen.dart';
import 'package:app/src/auth/forgot/forgot_type.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:app/src/services/biometric_service.dart';
import 'package:app/src/services/socket_service.dart';
import 'package:app/src/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// Màn hình Bước 1: Nhập mã PIN cũ hoặc mật khẩu cũ.
/// Phía dưới có dòng chữ xanh "Quên mã PIN?" / "Quên mật khẩu?" tái sử dụng luồng quên có sẵn.
/// Khi nhập đúng sẽ chuyển sang màn hình Tạo mới & Xác nhận.
class ChangeSecretVerifyOldScreen extends StatefulWidget {
  final ForgotType type;

  const ChangeSecretVerifyOldScreen({
    super.key,
    required this.type,
  });

  @override
  State<ChangeSecretVerifyOldScreen> createState() =>
      _ChangeSecretVerifyOldScreenState();
}

class _ChangeSecretVerifyOldScreenState
    extends State<ChangeSecretVerifyOldScreen>
    with SmoothAutoFocusMixin {
  static final List<TextInputFormatter> _digitsOnly = [
    FilteringTextInputFormatter.digitsOnly,
  ];
  static final RegExp _sixDigitsRegex = RegExp(r'^\d{6}$');

  final TextEditingController _oldController = TextEditingController();
  final FocusNode _oldFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final UserService _userService = UserService();

  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isHiddenNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<String> _errorNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> _hasFocusNotifier = ValueNotifier<bool>(false);

  bool get _isPin => widget.type == ForgotType.pin;

  @override
  FocusNode get initialFocusNode => _oldFocusNode;

  @override
  void initState() {
    super.initState();
    _oldController.addListener(_clearError);
    _oldFocusNode.addListener(_onFocusChanged);
  }

  void _clearError() {
    if (_errorNotifier.value.isNotEmpty) {
      _errorNotifier.value = '';
    }
  }

  void _onFocusChanged() {
    final focused = _oldFocusNode.hasFocus;
    _hasFocusNotifier.value = focused;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = (focused ? 45.0 : 0.0).clamp(
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
    _oldController.removeListener(_clearError);
    _oldFocusNode.removeListener(_onFocusChanged);
    _oldController.dispose();
    _oldFocusNode.dispose();
    _scrollController.dispose();
    _isLoadingNotifier.dispose();
    _isHiddenNotifier.dispose();
    _errorNotifier.dispose();
    _hasFocusNotifier.dispose();
    super.dispose();
  }

  Future<bool> _logoutForForgotFlow() async {
    final result = await AuthService().logout();
    if (result['is_success'] != true) return false;
    await const FlutterSecureStorage().deleteAll();
    SocketService().disconnect();
    return true;
  }

  Future<void> _onTapForgot() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final phone = Get.isRegistered<UserController>()
        ? Get.find<UserController>().phone.value
        : '';
    final secretLabel = _isPin ? 'mã PIN' : 'mật khẩu';

    final confirmed = await DialogUtils.showConfirmationAsync(
      context,
      title: 'Xác nhận',
      message: 'Bạn có chắc chắn muốn đăng xuất để đặt lại $secretLabel không?',
      cancelText: 'Hủy',
      confirmText: 'Xác nhận',
      errorMessage: 'Có lỗi khi đăng xuất. Vui lòng thử lại',
      onConfirm: _logoutForForgotFlow,
    );

    if (confirmed != true) {
      if (mounted) {
        requestKeyboardFocus(_oldFocusNode);
      }
      return;
    }

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ForgotPhoneScreen(
          type: widget.type,
          initialPhone: phone,
          lockPhone: phone.isNotEmpty,
        ),
      ),
      (r) => false,
    );
  }

  Future<void> _onVerifyOld() async {
    if (_isLoadingNotifier.value) return;
    final oldValue = _oldController.text.trim();
    final label = _isPin ? 'Mã PIN' : 'Mật khẩu';

    if (oldValue.isEmpty) {
      _errorNotifier.value = 'Vui lòng nhập ${label.toLowerCase()} hiện tại';
      return;
    }
    if (!_sixDigitsRegex.hasMatch(oldValue)) {
      _errorNotifier.value = '$label phải gồm đúng 6 chữ số';
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    _errorNotifier.value = '';
    _isLoadingNotifier.value = true;

    final result = _isPin
        ? await _userService.verifyPin(oldValue)
        : await _userService.verifyPassword(oldValue);

    if (!mounted) return;
    _isLoadingNotifier.value = false;

    if (result['is_success'] == true) {
      if (result['is_correct'] == true) {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeSecretNewScreen(
              type: widget.type,
              oldSecret: oldValue,
            ),
          ),
        );
        if (changed == true && mounted) {
          Navigator.pop(context, true);
        }
        return;
      }

      final remaining = result['remaining_attempts'];
      _errorNotifier.value = remaining != null
          ? '$label hiện tại không chính xác. Còn $remaining lần thử.'
          : '$label hiện tại không chính xác. Vui lòng thử lại.';
      _oldController.clear();
      requestKeyboardFocus(_oldFocusNode);
      return;
    }

    _errorNotifier.value =
        result['message']?.toString() ?? 'Không thể xác thực $label hiện tại';
    _oldController.clear();
    requestKeyboardFocus(_oldFocusNode);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isPin ? 'Đổi mã PIN' : 'Đổi mật khẩu';
    final bannerTitle =
        _isPin ? 'Nhập mã PIN hiện tại' : 'Nhập mật khẩu hiện tại';
    final bannerSub = _isPin
        ? 'Xác nhận mã PIN 6 chữ số đang sử dụng trước khi thiết lập mã PIN mới.'
        : 'Xác nhận mật khẩu 6 chữ số đang sử dụng trước khi thiết lập mật khẩu mới.';
    final sectionLabel =
        _isPin ? 'Mã PIN hiện tại' : 'Mật khẩu hiện tại';
    final hintText =
        _isPin ? 'Nhập mã PIN 6 số hiện tại' : 'Nhập mật khẩu 6 số hiện tại';
    final forgotText = _isPin ? 'Quên mã PIN?' : 'Quên mật khẩu?';

    return AuthScaffold(
      appBarTitle: title,
      onBack: () => Navigator.pop(context),
      scrollController: _scrollController,
      hasFocusListenable: _hasFocusNotifier,
      bottomBar: ValueListenableBuilder<bool>(
        valueListenable: _isLoadingNotifier,
        builder: (context, isLoading, _) {
          return AuthPrimaryButton(
            label: 'Tiếp tục',
            loading: isLoading,
            onTap: _onVerifyOld,
          );
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          AuthHeroBanner(
            icon: _isPin ? Iconsax.key : Iconsax.lock_1,
            badgeText: 'Bước 1/2 • Xác thực bảo mật',
            title: bannerTitle,
            subtitle: bannerSub,
          ),
          const SizedBox(height: 22),
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
                      Text(sectionLabel, style: kAuthSectionLabelStyle),
                      const SizedBox(height: 10),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isHiddenNotifier,
                        builder: (context, isHidden, _) {
                          return AuthTextField(
                            controller: _oldController,
                            focusNode: _oldFocusNode,
                            hintText: hintText,
                            leadingIcon: _isPin
                                ? Icons.pin_outlined
                                : Icons.lock_outline_rounded,
                            obscureText: isHidden,
                            onToggleObscure: () {
                              _isHiddenNotifier.value = !isHidden;
                            },
                            hasError: hasErr,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              signed: false,
                              decimal: false,
                            ),
                            inputFormatters: _digitsOnly,
                            maxLength: 6,
                            onSubmitted: (_) => _onVerifyOld(),
                          );
                        },
                      ),
                      if (hasErr) ...[
                        const SizedBox(height: 12),
                        AuthErrorBanner(message: err),
                      ],
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _onTapForgot,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 2,
                            ),
                            child: Text(
                              forgotText,
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1565C0),
                              ),
                            ),
                          ),
                        ),
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

/// Màn hình Bước 2: Tạo mã PIN / mật khẩu mới & Xác nhận lại.
class ChangeSecretNewScreen extends StatefulWidget {
  final ForgotType type;
  final String oldSecret;

  const ChangeSecretNewScreen({
    super.key,
    required this.type,
    required this.oldSecret,
  });

  @override
  State<ChangeSecretNewScreen> createState() => _ChangeSecretNewScreenState();
}

class _ChangeSecretNewScreenState extends State<ChangeSecretNewScreen>
    with SmoothAutoFocusMixin {
  static final List<TextInputFormatter> _digitsOnly = [
    FilteringTextInputFormatter.digitsOnly,
  ];
  static final RegExp _sixDigitsRegex = RegExp(r'^\d{6}$');

  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _newFocusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final UserService _userService = UserService();

  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isHiddenNewNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isHiddenConfirmNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<String> _errorNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> _hasAnyFocusNotifier = ValueNotifier<bool>(false);

  bool get _isPin => widget.type == ForgotType.pin;

  @override
  FocusNode get initialFocusNode => _newFocusNode;

  @override
  void initState() {
    super.initState();
    _newController.addListener(_clearError);
    _confirmController.addListener(_clearError);
    _newFocusNode.addListener(_onFocusChanged);
    _confirmFocusNode.addListener(_onFocusChanged);
  }

  void _clearError() {
    if (_errorNotifier.value.isNotEmpty) {
      _errorNotifier.value = '';
    }
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
    _newController.removeListener(_clearError);
    _confirmController.removeListener(_clearError);
    _newFocusNode.removeListener(_onFocusChanged);
    _confirmFocusNode.removeListener(_onFocusChanged);
    _newController.dispose();
    _confirmController.dispose();
    _newFocusNode.dispose();
    _confirmFocusNode.dispose();
    _scrollController.dispose();
    _isLoadingNotifier.dispose();
    _isHiddenNewNotifier.dispose();
    _isHiddenConfirmNotifier.dispose();
    _errorNotifier.dispose();
    _hasAnyFocusNotifier.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_isLoadingNotifier.value) return;
    final newVal = _newController.text.trim();
    final confirmVal = _confirmController.text.trim();
    final label = _isPin ? 'Mã PIN' : 'Mật khẩu';

    if (newVal.isEmpty) {
      _errorNotifier.value = 'Vui lòng nhập ${label.toLowerCase()} mới';
      return;
    }
    if (!_sixDigitsRegex.hasMatch(newVal)) {
      _errorNotifier.value = '$label mới phải gồm đúng 6 chữ số';
      return;
    }
    if (confirmVal.isEmpty) {
      _errorNotifier.value = 'Vui lòng xác nhận lại ${label.toLowerCase()} mới';
      return;
    }
    if (newVal != confirmVal) {
      _errorNotifier.value = '$label mới và xác nhận không khớp';
      return;
    }
    if (newVal == widget.oldSecret) {
      _errorNotifier.value =
          '$label mới không được trùng ${label.toLowerCase()} hiện tại';
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    _errorNotifier.value = '';
    _isLoadingNotifier.value = true;

    final result = _isPin
        ? await _userService.changePin(
            oldPin: widget.oldSecret,
            newPin: newVal,
          )
        : await _userService.changePassword(
            oldPassword: widget.oldSecret,
            newPassword: newVal,
          );

    if (!mounted) return;
    _isLoadingNotifier.value = false;

    if (result['is_success'] == true) {
      if (_isPin) {
        await BiometricService().updatePinIfEnabled(newVal);
      }
      if (!mounted) return;
      SnackbarUtils.success(
        context,
        result['message']?.toString() ?? 'Đổi ${label.toLowerCase()} thành công',
      );
      Navigator.pop(context, true);
      return;
    }

    _errorNotifier.value =
        result['message']?.toString() ?? 'Không thể đổi ${label.toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final title = _isPin ? 'Tạo mã PIN mới' : 'Tạo mật khẩu mới';
    final bannerTitle =
        _isPin ? 'Thiết lập mã PIN mới' : 'Thiết lập mật khẩu mới';
    final bannerSub = _isPin
        ? 'Nhập mã PIN mới gồm 6 chữ số và xác nhận lại để hoàn tất thay đổi.'
        : 'Nhập mật khẩu mới gồm 6 chữ số và xác nhận lại để hoàn tất thay đổi.';
    final newLabel = _isPin ? 'Mã PIN mới (6 số)' : 'Mật khẩu mới (6 số)';
    final confirmLabel =
        _isPin ? 'Xác nhận mã PIN mới' : 'Xác nhận mật khẩu mới';
    final newHint = _isPin ? 'Nhập mã PIN 6 số mới' : 'Nhập mật khẩu 6 số mới';
    final confirmHint =
        _isPin ? 'Nhập lại mã PIN 6 số mới' : 'Nhập lại mật khẩu 6 số mới';

    return AuthScaffold(
      appBarTitle: title,
      onBack: () => Navigator.pop(context),
      scrollController: _scrollController,
      hasFocusListenable: _hasAnyFocusNotifier,
      bottomBar: ValueListenableBuilder<bool>(
        valueListenable: _isLoadingNotifier,
        builder: (context, isLoading, _) {
          return AuthPrimaryButton(
            label: 'Xác nhận thay đổi',
            loading: isLoading,
            onTap: _onSubmit,
          );
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          AuthHeroBanner(
            icon: _isPin ? Iconsax.shield_tick : Iconsax.security_safe,
            badgeText: 'Bước 2/2 • Thiết lập mới',
            title: bannerTitle,
            subtitle: bannerSub,
          ),
          const SizedBox(height: 22),
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
                      Text(newLabel, style: kAuthSectionLabelStyle),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isHiddenNewNotifier,
                        builder: (context, isHidden, _) {
                          return AuthTextField(
                            controller: _newController,
                            focusNode: _newFocusNode,
                            hintText: newHint,
                            leadingIcon: _isPin
                                ? Icons.pin_outlined
                                : Icons.lock_outline_rounded,
                            obscureText: isHidden,
                            onToggleObscure: () {
                              _isHiddenNewNotifier.value = !isHidden;
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
                      Text(confirmLabel, style: kAuthSectionLabelStyle),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isHiddenConfirmNotifier,
                        builder: (context, isHidden, _) {
                          return AuthTextField(
                            controller: _confirmController,
                            focusNode: _confirmFocusNode,
                            hintText: confirmHint,
                            leadingIcon: Icons.lock_reset_rounded,
                            obscureText: isHidden,
                            onToggleObscure: () {
                              _isHiddenConfirmNotifier.value = !isHidden;
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
                              _isPin
                                  ? 'Mã PIN mới không được trùng mã PIN cũ hoặc mật khẩu đăng nhập.'
                                  : 'Mật khẩu mới không được trùng mật khẩu cũ hoặc mã PIN giao dịch.',
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

