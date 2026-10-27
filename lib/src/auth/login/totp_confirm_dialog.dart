import 'package:app/core/utils/snackbar_utils.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

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

class _TotpConfirmDialogState extends State<_TotpConfirmDialog> {
  final TextEditingController _controller = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _msg = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.length != 6) {
      setState(() => _msg = 'Vui lòng nhập đủ 6 số');
      return;
    }
    setState(() {
      _isLoading = true;
      _msg = '';
    });
    final result = await _authService.enableTotp(_controller.text);
    if (!mounted) return;
    if (result['is_success'] == true) {
      Navigator.pop(context, true);
      return;
    }
    _controller.clear();
    setState(() {
      _isLoading = false;
      _msg = result['message'] ?? 'Mã không chính xác, vui lòng thử lại';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = PinTheme(
      width: 42,
      height: 52,
      textStyle: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
      ),
    );

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoàn tất liên kết',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhập mã 6 số đang hiển thị trong Google Authenticator để bật '
              'đăng nhập bằng ứng dụng này.',
              style: GoogleFonts.roboto(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            Center(
              child: Pinput(
                controller: _controller,
                length: 6,
                autofocus: true,
                keyboardType: TextInputType.number,
                defaultPinTheme: theme,
                focusedPinTheme: theme.copyWith(
                  decoration: theme.decoration!.copyWith(
                    border: Border.all(color: Colors.pink, width: 2),
                  ),
                ),
                onChanged: (_) {
                  if (_msg.isNotEmpty) setState(() => _msg = '');
                },
                onCompleted: (_) => _submit(),
              ),
            ),
            if (_msg.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _msg,
                style: GoogleFonts.roboto(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                  child: Text('Để sau', style: GoogleFonts.roboto(fontSize: 15)),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Xác nhận',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}