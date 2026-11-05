import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/src/auth/auth_ui.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// Hiện sau khi đăng nhập thành công để nhập mã đầu tiên và bật Google
/// Authenticator. Trả về true nếu đã bật; "Để sau" thì giữ nguyên OTP email.
Future<bool> showTotpConfirmDialog(BuildContext context) async {
  final enabled = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _TotpConfirmDialog(),
  );
  if (enabled == true && context.mounted) {
    SnackbarUtils.success(
      context,
      'Đã bật Google Authenticator cho các lần đăng nhập sau',
    );
  }
  return enabled == true;
}

class _TotpConfirmDialog extends StatefulWidget {
  const _TotpConfirmDialog();

  @override
  State<_TotpConfirmDialog> createState() => _TotpConfirmDialogState();
}

class _TotpConfirmDialogState extends State<_TotpConfirmDialog>
    with SmoothAutoFocusMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AuthService _authService = AuthService();

  final ValueNotifier<String> _msgNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);

  @override
  FocusNode get initialFocusNode => _focusNode;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _msgNotifier.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoadingNotifier.value) return;
    if (_controller.text.length != 6) {
      _msgNotifier.value = 'Vui lòng nhập đủ 6 số';
      return;
    }
    _isLoadingNotifier.value = true;
    _msgNotifier.value = '';

    final result = await _authService.enableTotp(_controller.text);
    if (!mounted) return;
    if (result['is_success'] == true) {
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.pop(context, true);
      return;
    }
    _controller.clear();
    _isLoadingNotifier.value = false;
    _msgNotifier.value =
        result['message']?.toString() ?? 'Mã không chính xác, vui lòng thử lại';
    requestKeyboardFocus(_focusNode);
  }

  @override
  Widget build(BuildContext context) {
    return FreezeKeyboardMediaQuery(
      child: KeyboardTranslate(
        subtractSafeArea: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: kAuthPinkSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Iconsax.shield_tick,
                              color: kAuthPinkDark,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Hoàn tất liên kết',
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: kAuthText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Nhập mã 6 số đang hiển thị trong Google Authenticator để bật đăng nhập bằng ứng dụng này.',
                        style: GoogleFonts.roboto(
                          fontSize: 13.8,
                          height: 1.45,
                          color: kAuthMuted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ValueListenableBuilder<String>(
                        valueListenable: _msgNotifier,
                        builder: (context, msg, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AuthOtpInputRow(
                                controller: _controller,
                                focusNode: _focusNode,
                                hasError: msg.isNotEmpty,
                                onChanged: (_) {
                                  if (_msgNotifier.value.isNotEmpty) {
                                    _msgNotifier.value = '';
                                  }
                                },
                                onCompleted: (_) => _submit(),
                              ),
                              if (msg.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                AuthErrorBanner(message: msg),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isLoadingNotifier,
                        builder: (context, isLoading, _) {
                          return Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: OutlinedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                          Navigator.pop(context, false);
                                        },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: kAuthMuted,
                                    minimumSize: const Size.fromHeight(48),
                                    side: const BorderSide(color: kAuthBorder),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    'Để sau',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 6,
                                child: SizedBox(
                                  height: 48,
                                  child: AuthPrimaryButton(
                                    label: 'Xác nhận',
                                    loading: isLoading,
                                    onTap: _submit,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
