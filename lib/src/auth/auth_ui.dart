import 'package:app/src/transfer/transfer_ui.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

export 'package:app/src/transfer/transfer_ui.dart'
    show FreezeKeyboardMediaQuery, KeyboardTranslate, requestKeyboardFocus;

// Bảng màu thống nhất cho toàn bộ luồng Xác thực (Auth) của Ví Mio.
const Color kAuthPink = Color(0xFFEC407A);
const Color kAuthPinkDark = Color(0xFFD81B60);
const Color kAuthPinkLight = Color(0xFFF48FB1);
const Color kAuthPinkSoft = Color(0xFFFCE4EC);
const Color kAuthBg = Color(0xFFFAF6F8);
const Color kAuthText = Color(0xFF1F1B24);
const Color kAuthMuted = Color(0xFF8A8590);
const Color kAuthSuccess = Color(0xFF2E9E5B);
const Color kAuthError = Color(0xFFE53935);
const Color kAuthBorder = Color(0xFFE6DFE4);

// Cache sẵn toàn bộ TextStyle để tránh cấp phát lại GoogleFonts trong các frame trượt bàn phím.
final TextStyle kAuthAppBarTitleStyle = GoogleFonts.roboto(
  fontSize: 19,
  fontWeight: FontWeight.w700,
  color: kAuthText,
);

final TextStyle kAuthHeadingStyle = GoogleFonts.roboto(
  fontSize: 23,
  fontWeight: FontWeight.w800,
  color: kAuthText,
  height: 1.25,
);

final TextStyle kAuthSubtitleStyle = GoogleFonts.roboto(
  fontSize: 14.5,
  fontWeight: FontWeight.w400,
  color: kAuthMuted,
  height: 1.45,
);

final TextStyle kAuthSectionLabelStyle = GoogleFonts.roboto(
  fontSize: 13.5,
  fontWeight: FontWeight.w600,
  color: kAuthText,
);

final TextStyle kAuthInputTextStyle = GoogleFonts.roboto(
  fontSize: 17,
  fontWeight: FontWeight.w600,
  color: kAuthText,
);

final TextStyle kAuthInputHintStyle = GoogleFonts.roboto(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  color: kAuthMuted.withValues(alpha: 0.75),
);

final TextStyle kAuthErrorStyle = GoogleFonts.roboto(
  fontSize: 13,
  fontWeight: FontWeight.w500,
  color: kAuthError,
  height: 1.35,
);

final TextStyle kAuthBtnEnabledStyle = GoogleFonts.roboto(
  fontSize: 16.5,
  fontWeight: FontWeight.w700,
  color: Colors.white,
  letterSpacing: 0.2,
);

final TextStyle kAuthBtnDisabledStyle = GoogleFonts.roboto(
  fontSize: 16.5,
  fontWeight: FontWeight.w700,
  color: Colors.grey.withValues(alpha: 0.65),
);

/// Thẻ trắng bo góc, đổ bóng hồng dịu đồng bộ toàn bộ màn Auth.
BoxDecoration authCardDeco({double radius = 22}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  boxShadow: [
    BoxShadow(
      color: kAuthPink.withValues(alpha: 0.08),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ],
);

/// Dải nền chuyển sắc hồng phía trên cùng màn hình Auth.
class AuthHeaderGradient extends StatelessWidget {
  const AuthHeaderGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            kAuthPink.withValues(alpha: 0.24),
            kAuthPinkLight.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

/// Nút tròn quay lại trên AppBar của các màn Auth.
class AuthCircleBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const AuthCircleBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: kAuthPink.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            onPressed();
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: kAuthText,
          ),
        ),
      ),
    );
  }
}

/// Khung màn hình Auth tối ưu mở/đóng bàn phím mượt 120Hz (giống màn Nhập số tiền):
/// - Đóng băng `MediaQuery.viewInsets` bằng `FreezeKeyboardMediaQuery` để tránh relayout toàn màn hình.
/// - Thanh nút dưới đáy trượt trên GPU bằng `KeyboardTranslate` (`Transform.translate`).
class AuthScaffold extends StatelessWidget {
  final String appBarTitle;
  final VoidCallback? onBack;
  final ScrollController? scrollController;
  final Widget child;
  final Widget? bottomBar;
  final Widget? overlay;
  final ValueListenable<bool>? hasFocusListenable;

  const AuthScaffold({
    super.key,
    required this.appBarTitle,
    required this.child,
    this.onBack,
    this.scrollController,
    this.bottomBar,
    this.overlay,
    this.hasFocusListenable,
  });

  @override
  Widget build(BuildContext context) {
    return FreezeKeyboardMediaQuery(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: kAuthBg,
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            leadingWidth: 56,
            leading: onBack != null
                ? AuthCircleBackButton(onPressed: onBack!)
                : null,
            title: Text(appBarTitle, style: kAuthAppBarTitleStyle),
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              const Align(
                alignment: Alignment.topCenter,
                child: RepaintBoundary(child: AuthHeaderGradient()),
              ),
              SafeArea(
                bottom: false,
                child: SizedBox.expand(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        child,
                        if (hasFocusListenable != null)
                          ValueListenableBuilder<bool>(
                            valueListenable: hasFocusListenable!,
                            builder: (context, focused, _) =>
                                SizedBox(height: focused ? 340 : 120),
                          )
                        else
                          const SizedBox(height: 130),
                      ],
                    ),
                  ),
                ),
              ),
              if (bottomBar != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: KeyboardTranslate(
                    child: RepaintBoundary(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              kAuthBg.withValues(alpha: 0.0),
                              kAuthBg.withValues(alpha: 0.92),
                              kAuthBg,
                            ],
                            stops: const [0.0, 0.28, 1.0],
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                            child: bottomBar!,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (overlay != null) Positioned.fill(child: overlay!),
            ],
          ),
        ),
      ),
    );
  }
}

/// Phần đầu trang (Icon huy hiệu + Nhãn bước + Tiêu đề + Mô tả).
class AuthHeroBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badgeText;

  const AuthHeroBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kAuthPink.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF06292), kAuthPinkDark],
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
              decoration: BoxDecoration(
                color: kAuthPinkSoft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                badgeText!,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kAuthPinkDark,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: kAuthHeadingStyle),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: kAuthSubtitleStyle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút chính dạng gradient hồng chuẩn Ví Mio.
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool loading;
  final IconData? icon;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = enabled && !loading && onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: active ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFFF06292), kAuthPinkDark],
                  )
                : null,
            color: active ? null : Colors.black.withValues(alpha: 0.09),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: kAuthPink.withValues(alpha: 0.34),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.3,
                  ),
                )
              else ...[
                Text(
                  label,
                  style: active ? kAuthBtnEnabledStyle : kAuthBtnDisabledStyle,
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    icon,
                    size: 18,
                    color: active
                        ? Colors.white
                        : Colors.grey.withValues(alpha: 0.65),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Khung thông báo lỗi gọn gàng dùng chung cho toàn bộ luồng Auth.
class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kAuthError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kAuthError.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              color: kAuthError,
              size: 17,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: kAuthErrorStyle)),
        ],
      ),
    );
  }
}

/// Lớp phủ chờ toàn màn hình (ví dụ khi đang tạo mã OTP).
class AuthLoadingOverlay extends StatelessWidget {
  final String label;
  const AuthLoadingOverlay({super.key, this.label = 'Đang xử lý...'});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.35),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kAuthPink.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: kAuthPink,
                  strokeWidth: 2.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kAuthText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ô nhập số điện thoại +84 cách ly repaint:
/// - Cờ Việt Nam (`CountryFlag`) được bọc `RepaintBoundary` riêng nên không bao giờ vẽ lại khi gõ phím.
/// - Chỉ viền của khung tự đổi màu theo `focusNode`, không làm rebuild màn hình cha.
class AuthPhoneField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool readOnly;
  final ValueChanged<String>? onSubmitted;

  const AuthPhoneField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hasError = false,
    this.readOnly = false,
    this.onSubmitted,
  });

  @override
  State<AuthPhoneField> createState() => _AuthPhoneFieldState();
}

class _AuthPhoneFieldState extends State<AuthPhoneField> {
  static final List<TextInputFormatter> _digitsOnly = [
    FilteringTextInputFormatter.digitsOnly,
  ];

  static final TextStyle _prefixStyle = GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: kAuthText,
  );

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AuthPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus && !widget.readOnly;
    final borderColor = widget.hasError
        ? kAuthError
        : isFocused
        ? kAuthPink
        : kAuthBorder;

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.readOnly
            ? null
            : () => requestKeyboardFocus(widget.focusNode),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: widget.readOnly
                ? const Color(0xFFF3EFF2)
                : const Color(0xFFFCFAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: (widget.hasError || isFocused) ? 1.6 : 1.1,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: kAuthPink.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              RepaintBoundary(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 26,
                    height: 18,
                    child: CountryFlag.fromCountryCode('VN'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('+84', style: _prefixStyle),
              Container(
                width: 1,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: kAuthBorder,
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  readOnly: widget.readOnly,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onSubmitted: widget.onSubmitted,
                  enableSuggestions: false,
                  autocorrect: false,
                  enableIMEPersonalizedLearning: false,
                  inputFormatters: _digitsOnly,
                  maxLength: 10,
                  cursorColor: kAuthPink,
                  style: kAuthInputTextStyle,
                  decoration: InputDecoration(
                    hintText: 'Nhập số điện thoại',
                    hintStyle: kAuthInputHintStyle,
                    border: InputBorder.none,
                    isDense: true,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (widget.readOnly)
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: kAuthMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ô nhập văn bản / mật khẩu cách ly repaint cho tốc độ mở bàn phím tức thì.
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final IconData leadingIcon;
  final bool hasError;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final ValueChanged<String>? onSubmitted;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.leadingIcon,
    this.hasError = false,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.inputFormatters,
    this.maxLength,
    this.onSubmitted,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AuthTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;
    final borderColor = widget.hasError
        ? kAuthError
        : isFocused
        ? kAuthPink
        : kAuthBorder;

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => requestKeyboardFocus(widget.focusNode),
        child: Container(
          height: 56,
          padding: const EdgeInsets.only(left: 14, right: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: (widget.hasError || isFocused) ? 1.6 : 1.1,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: kAuthPink.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.leadingIcon,
                size: 20,
                color: isFocused ? kAuthPink : kAuthMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  inputFormatters: widget.inputFormatters,
                  maxLength: widget.maxLength,
                  onSubmitted: widget.onSubmitted,
                  enableSuggestions: false,
                  autocorrect: false,
                  enableIMEPersonalizedLearning: false,
                  cursorColor: kAuthPink,
                  style: kAuthInputTextStyle.copyWith(
                    letterSpacing: widget.obscureText ? 3.0 : 0.0,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: kAuthInputHintStyle.copyWith(letterSpacing: 0),
                    border: InputBorder.none,
                    isDense: true,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (widget.onToggleObscure != null)
                IconButton(
                  onPressed: widget.onToggleObscure,
                  splashRadius: 20,
                  icon: Icon(
                    widget.obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: kAuthMuted,
                  ),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dãy 6 ô nhập mã OTP / mã bí mật siêu nhẹ (dùng 1 `EditableText` ẩn thay vì 6 `TextField` hay `Pinput`):
/// - Mở bàn phím số tức thì ở 120Hz, không tốn chi phí đóng/mở kết nối IME khi chuyển giữa các ô.
/// - Hỗ trợ dán mã 6 số, xoá lùi mượt mà và chế độ ẩn chấm tròn (`obscureText`).
class AuthOtpInputRow extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool obscureText;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  const AuthOtpInputRow({
    super.key,
    required this.controller,
    required this.focusNode,
    this.length = 6,
    this.obscureText = false,
    this.hasError = false,
    this.onChanged,
    this.onCompleted,
  });

  @override
  State<AuthOtpInputRow> createState() => _AuthOtpInputRowState();
}

class _AuthOtpInputRowState extends State<AuthOtpInputRow> {
  static final TextStyle _hiddenStyle = const TextStyle(
    fontSize: 1,
    color: Colors.transparent,
    height: 1,
  );

  static final TextStyle _digitStyle = GoogleFonts.roboto(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: kAuthText,
  );

  final GlobalKey<EditableTextState> _editableKey =
      GlobalKey<EditableTextState>();
  late final List<TextInputFormatter> _formatters;
  late final Listenable _mergedListenable;
  String _prevText = '';

  @override
  void initState() {
    super.initState();
    _prevText = widget.controller.text;
    _formatters = [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(widget.length),
    ];
    _mergedListenable = Listenable.merge([widget.controller, widget.focusNode]);
  }

  @override
  void didUpdateWidget(covariant AuthOtpInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.focusNode != widget.focusNode) {
      _mergedListenable = Listenable.merge([
        widget.controller,
        widget.focusNode,
      ]);
    }
  }

  void _openKeyboard() {
    if (!widget.focusNode.hasFocus) {
      widget.focusNode.requestFocus();
    } else {
      _editableKey.currentState?.requestKeyboard();
    }
    final text = widget.controller.text;
    widget.controller.selection = TextSelection.collapsed(offset: text.length);
  }

  void _handleChanged(String value) {
    if (value == _prevText) return;
    final wasShorter = _prevText.length < widget.length;
    _prevText = value;
    widget.onChanged?.call(value);
    if (wasShorter && value.length == widget.length) {
      widget.onCompleted?.call(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openKeyboard,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.0,
              child: SizedBox(
                width: 1,
                height: 1,
                child: EditableText(
                  key: _editableKey,
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  style: _hiddenStyle,
                  cursorColor: Colors.transparent,
                  backgroundCursorColor: Colors.transparent,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: false,
                  ),
                  inputFormatters: _formatters,
                  enableSuggestions: false,
                  autocorrect: false,
                  enableIMEPersonalizedLearning: false,
                  enableInteractiveSelection: false,
                  onChanged: _handleChanged,
                ),
              ),
            ),
            ListenableBuilder(
              listenable: _mergedListenable,
              builder: (context, _) {
                final text = widget.controller.text;
                final isFocused = widget.focusNode.hasFocus;
                final activeIndex = text.length < widget.length
                    ? text.length
                    : widget.length - 1;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(widget.length, (index) {
                    final hasChar = index < text.length;
                    final isCurrentCell = isFocused && index == activeIndex;
                    final Color borderColor;
                    if (widget.hasError) {
                      borderColor = kAuthError;
                    } else if (isCurrentCell) {
                      borderColor = kAuthPink;
                    } else if (hasChar) {
                      borderColor = kAuthPink.withValues(alpha: 0.45);
                    } else {
                      borderColor = kAuthBorder;
                    }

                    return Expanded(
                      child: Container(
                        height: 54,
                        margin: EdgeInsets.only(
                          left: index == 0 ? 0 : 4,
                          right: index == widget.length - 1 ? 0 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentCell
                              ? Colors.white
                              : hasChar
                              ? kAuthPinkSoft.withValues(alpha: 0.25)
                              : const Color(0xFFFCFAFB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: borderColor,
                            width: (isCurrentCell || widget.hasError)
                                ? 1.8
                                : 1.1,
                          ),
                          boxShadow: isCurrentCell
                              ? [
                                  BoxShadow(
                                    color: kAuthPink.withValues(alpha: 0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: hasChar
                              ? (widget.obscureText
                                    ? Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: kAuthPinkDark,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : Text(text[index], style: _digitStyle))
                              : isCurrentCell
                              ? Container(
                                  width: 2,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: kAuthPink,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Mixin kích hoạt bàn phím mượt mà SAU KHI hiệu ứng chuyển màn hình (`ModalRoute`) hoàn tất,
/// tránh xung đột giữa animation mở trang và animation trượt bàn phím.
mixin SmoothAutoFocusMixin<T extends StatefulWidget> on State<T> {
  Animation<double>? _routeAnim;
  bool _didRequestInitialFocus = false;

  FocusNode get initialFocusNode;
  bool get enableInitialAutoFocus => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!enableInitialAutoFocus || _didRequestInitialFocus) return;

    final anim = ModalRoute.of(context)?.animation;
    if (anim != null && anim.status == AnimationStatus.forward) {
      _routeAnim?.removeStatusListener(_onRouteStatus);
      _routeAnim = anim;
      _routeAnim!.addStatusListener(_onRouteStatus);
    } else {
      _didRequestInitialFocus = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) requestKeyboardFocus(initialFocusNode);
      });
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_didRequestInitialFocus) {
      _didRequestInitialFocus = true;
      _routeAnim?.removeStatusListener(_onRouteStatus);
      if (mounted) requestKeyboardFocus(initialFocusNode);
    }
  }

  @override
  void dispose() {
    _routeAnim?.removeStatusListener(_onRouteStatus);
    super.dispose();
  }
}
