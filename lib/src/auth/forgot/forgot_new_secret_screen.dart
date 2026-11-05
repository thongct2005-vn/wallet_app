import 'package:app/core/widgets/pin_bottomsheet/pin_sheet_common.dart';
import 'package:app/src/auth/forgot/forgot_type.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/services/forgot_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

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

class _ForgotNewSecretScreenState extends State<ForgotNewSecretScreen> {
  static final List<TextInputFormatter> _digitsFormatters = [
    FilteringTextInputFormatter.digitsOnly,
  ];

  static final PinTheme _pinTheme = PinTheme(
    width: 46,
    height: 56,
    textStyle: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w600),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
    ),
  );

  static final PinTheme _focusedTheme = _pinTheme.copyWith(
    decoration: _pinTheme.decoration!.copyWith(
      border: Border.all(color: Colors.pink, width: 2),
    ),
  );

  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _newFocusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();
  final ForgotService _forgotService = ForgotService();

  Animation<double>? _routeAnimation;
  bool _initialFocusRequested = false;
  bool _isLoading = false;
  bool _isHidden = true;
  String _msg = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialFocusRequested) return;

    final anim = ModalRoute.of(context)?.animation;
    if (anim != null && anim.status == AnimationStatus.forward) {
      // Đợi hiệu ứng chuyển trang hoàn tất rồi mới bật bàn phím để không gây giật frame
      _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
      _routeAnimation = anim;
      _routeAnimation!.addStatusListener(_onRouteAnimationStatus);
    } else {
      _initialFocusRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _newFocusNode.requestFocus();
        }
      });
    }
  }

  void _onRouteAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_initialFocusRequested) {
      _initialFocusRequested = true;
      _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
      if (mounted) {
        _newFocusNode.requestFocus();
      }
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
    _newController.dispose();
    _confirmController.dispose();
    _newFocusNode.dispose();
    _confirmFocusNode.dispose();
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
    final value = _newController.text;
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      setState(() => _msg = 'Vui lòng nhập đúng 6 số');
      return;
    }
    if (value != _confirmController.text) {
      setState(() => _msg = 'Hai lần nhập không khớp');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isLoading = true;
      _msg = '';
    });
    final result = await _forgotService.resetSecret(
      type: widget.type,
      resetToken: widget.resetToken,
      value: value,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

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
    setState(() => _msg = result['message'] ?? 'Không thể đặt lại');
  }

  @override
  Widget build(BuildContext context) {
    return FreezePinMediaQuery(
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: Text(
              '${widget.type.label[0].toUpperCase()}${widget.type.label.substring(1)} mới',
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: SizedBox.expand(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nhập ${widget.type.label} mới gồm 6 chữ số',
                          style: GoogleFonts.roboto(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: RepaintBoundary(
                            child: Pinput(
                              controller: _newController,
                              focusNode: _newFocusNode,
                              length: 6,
                              obscureText: _isHidden,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: false,
                                    decimal: false,
                                  ),
                              inputFormatters: _digitsFormatters,
                              pinAnimationType: PinAnimationType.none,
                              animationDuration: Duration.zero,
                              closeKeyboardWhenCompleted: false,
                              defaultPinTheme: _pinTheme,
                              focusedPinTheme: _focusedTheme,
                              onChanged: (_) {
                                if (_msg.isNotEmpty) setState(() => _msg = '');
                              },
                              onCompleted: (_) {
                                _confirmFocusNode.requestFocus();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Nhập lại ${widget.type.label} mới',
                          style: GoogleFonts.roboto(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: RepaintBoundary(
                            child: Pinput(
                              controller: _confirmController,
                              focusNode: _confirmFocusNode,
                              length: 6,
                              obscureText: _isHidden,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: false,
                                    decimal: false,
                                  ),
                              inputFormatters: _digitsFormatters,
                              pinAnimationType: PinAnimationType.none,
                              animationDuration: Duration.zero,
                              defaultPinTheme: _pinTheme,
                              focusedPinTheme: _focusedTheme,
                              onChanged: (_) {
                                if (_msg.isNotEmpty) setState(() => _msg = '');
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _isHidden = !_isHidden),
                            icon: Icon(
                              _isHidden
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                            ),
                            label: Text(_isHidden ? 'Hiện' : 'Ẩn'),
                          ),
                        ),
                        if (_msg.isNotEmpty)
                          Text(
                            _msg,
                            style: GoogleFonts.roboto(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: PinKeyboardTranslate(
                  child: ColoredBox(
                    color: Colors.white,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              disabledBackgroundColor: Colors.pink.withValues(
                                alpha: 0.4,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Xác nhận',
                                    style: GoogleFonts.roboto(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
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
