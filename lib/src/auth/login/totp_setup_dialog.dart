import 'package:app/src/auth/auth_ui.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Hiện dialog chứa mã QR để quét bằng Google Authenticator.
/// Trả về {'otpauth_uri', 'secret'} khi đã tạo được mã, null nếu người dùng đóng
/// mà chưa tạo được. Truyền [cached] để xem lại mã đã tạo (không gọi API lần nữa,
/// vì mỗi lần gọi server sẽ tạo khoá mới làm mã cũ trong ứng dụng hết tác dụng).
Future<Map<String, String>?> showTotpSetupDialog(
  BuildContext context, {
  required String phone,
  required String password,
  Map<String, String>? cached,
  bool recover = false,
}) {
  return showDialog<Map<String, String>?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _TotpSetupDialog(
      phone: phone,
      password: password,
      cached: cached,
      recover: recover,
    ),
  );
}

class _TotpSetupDialog extends StatefulWidget {
  final String phone;
  final String password;
  final Map<String, String>? cached;
  // true: lấy lại mã QR đã liên kết (tài khoản đã bật Google Authenticator)
  final bool recover;

  const _TotpSetupDialog({
    required this.phone,
    required this.password,
    this.cached,
    this.recover = false,
  });

  @override
  State<_TotpSetupDialog> createState() => _TotpSetupDialogState();
}

class _TotpSetupDialogState extends State<_TotpSetupDialog> {
  final AuthService _authService = AuthService();
  Map<String, String>? _data;
  bool _isLoading = false;
  bool _copied = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _data = widget.cached;
    if (_data == null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final result = widget.recover
        ? await _authService.recoverTotp(
            phone: widget.phone,
            password: widget.password,
          )
        : await _authService.setupTotp(
            phone: widget.phone,
            password: widget.password,
          );
    if (!mounted) return;
    if (result['is_success'] == true) {
      setState(() {
        _isLoading = false;
        _data = {
          'otpauth_uri': '${result['otpauth_uri']}',
          'secret': '${result['secret']}',
        };
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = result['message'] ?? 'Không thể tạo mã QR, vui lòng thử lại';
      });
    }
  }

  // Chia khoá thành nhóm 4 ký tự cho dễ nhập tay
  String _groupSecret(String secret) {
    final buffer = StringBuffer();
    for (var i = 0; i < secret.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(secret[i]);
    }
    return buffer.toString();
  }

  Future<void> _copySecret() async {
    await Clipboard.setData(ClipboardData(text: _data!['secret']!));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: kAuthPinkSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: GoogleFonts.roboto(
                color: kAuthPinkDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.roboto(
                fontSize: 13.2,
                height: 1.4,
                color: kAuthText.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ hiện nút "Thử lại" khi tải mã thất bại
    final bool showRetry = !_isLoading && _data == null;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
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
                      Iconsax.security,
                      color: kAuthPinkDark,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.recover
                          ? 'Lấy lại mã Google Authenticator'
                          : 'Liên kết Google Authenticator',
                      style: GoogleFonts.roboto(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w700,
                        color: kAuthText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _step(
                '1',
                'Mở Google Authenticator, chọn dấu + rồi "Quét mã QR".',
              ),
              _step('2', 'Quét mã bên dưới (hoặc chọn "Nhập khoá thiết lập").'),
              _step(
                '3',
                widget.recover
                    ? 'Đóng cửa sổ này, bấm "Xác nhận" rồi nhập mã 6 số trong ứng dụng để đăng nhập.'
                    : 'Đăng nhập như bình thường. Sau khi vào được tài khoản, nhập mã 6 số trong ứng dụng để hoàn tất.',
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const SizedBox(
                  height: 210,
                  child: Center(
                    child: CircularProgressIndicator(color: kAuthPink),
                  ),
                )
              else if (_data != null) ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: kAuthBorder),
                      boxShadow: [
                        BoxShadow(
                          color: kAuthPink.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _data!['otpauth_uri']!,
                      version: QrVersions.auto,
                      size: 192,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Khoá thiết lập thủ công',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kAuthMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                  decoration: BoxDecoration(
                    color: kAuthBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kAuthBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          _groupSecret(_data!['secret']!),
                          style: GoogleFonts.robotoMono(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: kAuthText,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _copySecret,
                        style: TextButton.styleFrom(
                          foregroundColor:
                              _copied ? kAuthSuccess : kAuthPinkDark,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          _copied ? Icons.check_rounded : Iconsax.copy,
                          size: 16,
                        ),
                        label: Text(
                          _copied ? 'Đã chép' : 'Sao chép',
                          style: GoogleFonts.roboto(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: AuthErrorBanner(message: _error),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  // "Thử lại" nằm góc trái, cùng hàng với "Đóng"
                  if (showRetry) ...[
                    Expanded(
                      child: AuthPrimaryButton(
                        label: 'Thử lại',
                        onTap: _load,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, _data),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kAuthPinkDark,
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(
                          color: kAuthPink.withValues(alpha: 0.45),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Đóng',
                        style: GoogleFonts.roboto(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
