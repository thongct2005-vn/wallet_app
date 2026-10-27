import 'package:app/src/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
}) {
  return showDialog<Map<String, String>?>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _TotpSetupDialog(phone: phone, password: password, cached: cached),
  );
}

class _TotpSetupDialog extends StatefulWidget {
  final String phone;
  final String password;
  final Map<String, String>? cached;

  const _TotpSetupDialog({
    required this.phone,
    required this.password,
    this.cached,
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
    final result = await _authService.setupTotp(
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.pink,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: GoogleFonts.roboto(fontSize: 13.5, height: 1.4)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.security_rounded, color: Colors.pink),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Liên kết Google Authenticator',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _step('1', 'Mở Google Authenticator, chọn dấu + rồi "Quét mã QR".'),
              _step('2', 'Quét mã bên dưới (hoặc chọn "Nhập khoá thiết lập").'),
              _step(
                '3',
                'Đăng nhập như bình thường. Sau khi vào được tài khoản, '
                'nhập mã 6 số trong ứng dụng để hoàn tất.',
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const SizedBox(
                  height: 220,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.pink),
                  ),
                )
              else if (_data != null) ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: QrImageView(
                      data: _data!['otpauth_uri']!,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Khoá thiết lập thủ công',
                  style: GoogleFonts.roboto(
                    fontSize: 12.5,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _groupSecret(_data!['secret']!),
                        style: GoogleFonts.robotoMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _copySecret,
                      tooltip: 'Sao chép',
                      icon: Icon(
                        _copied ? Icons.check_rounded : Icons.copy_rounded,
                        size: 20,
                        color: _copied ? Colors.green : Colors.pink,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _error,
                    style: GoogleFonts.roboto(color: Colors.red, fontSize: 14),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _load,
                    child: const Text('Thử lại'),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, _data),
                  style: TextButton.styleFrom(foregroundColor: Colors.pink),
                  child: Text(
                    'Đóng',
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}