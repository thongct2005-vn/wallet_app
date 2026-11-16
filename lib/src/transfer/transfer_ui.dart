import 'package:app/core/utils/format_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Bảng màu dùng chung cho luồng chuyển tiền.
// Giữ đúng giá trị với màn hình nạp/rút để hai luồng đồng bộ.
const Color kTfPink = Color(0xFFEC407A);
const Color kTfPinkDark = Color(0xFFD81B60);
const Color kTfPinkLight = Color(0xFFF48FB1);
const Color kTfText = Color(0xFF1F1B24);
const Color kTfMuted = Color(0xFF8A8590);
const Color kTfSuccess = Color(0xFF2E9E5B);
const Color kTfBg = Color(0xFFFAF6F8);

final TextStyle _kAppBarTitleStyle = GoogleFonts.roboto(
  fontSize: 19,
  fontWeight: FontWeight.w700,
  color: kTfText,
);

final TextStyle _kPrimaryBtnEnabledStyle = GoogleFonts.roboto(
  fontSize: 18,
  color: Colors.white,
  fontWeight: FontWeight.w700,
);

final TextStyle _kPrimaryBtnDisabledStyle = GoogleFonts.roboto(
  fontSize: 18,
  color: Colors.grey.withValues(alpha: 0.6),
  fontWeight: FontWeight.w700,
);

final TextStyle _kInfoLabelStyle = GoogleFonts.roboto(
  fontSize: 15,
  color: kTfMuted,
);

/// Thẻ trắng bo góc, đổ bóng hồng nhạt.
BoxDecoration transferCardDeco({double radius = 22}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  boxShadow: [
    BoxShadow(
      color: kTfPink.withValues(alpha: 0.08),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ],
);

/// Dải gradient hồng phía trên cùng của màn hình.
class TransferHeaderGradient extends StatelessWidget {
  const TransferHeaderGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            kTfPink.withValues(alpha: 0.24),
            kTfPinkLight.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

/// Nút tròn trắng có bóng, dùng cho nút back / home trên AppBar.
class TransferCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  const TransferCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 0, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: kTfPink.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          icon: Icon(icon, size: 20, color: kTfText),
        ),
      ),
    );
  }
}

/// Tiêu đề AppBar thống nhất.
class TransferAppBarTitle extends StatelessWidget {
  final String text;
  const TransferAppBarTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: _kAppBarTitleStyle);
  }
}

/// Nút chính dạng gradient hồng, giống nút "Xác nhận" của nạp/rút.
class TransferPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool loading;
  final IconData? icon;
  const TransferPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = enabled && !loading;
    return GestureDetector(
      onTap: active ? onTap : null,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: active
              ? const LinearGradient(colors: [Color(0xFFF06292), kTfPinkDark])
              : null,
          color: active ? null : Colors.black.withValues(alpha: 0.1),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: kTfPink.withValues(alpha: 0.35),
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
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else if (icon != null)
              Icon(icon, color: Colors.white, size: 20),
            if (loading || icon != null) const SizedBox(width: 10),
            Text(
              label,
              style: enabled
                  ? _kPrimaryBtnEnabledStyle
                  : _kPrimaryBtnDisabledStyle,
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar chữ cái đầu của tên.
class TransferAvatar extends StatelessWidget {
  final String name;
  final double size;
  const TransferAvatar({super.key, required this.name, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kTfPinkLight.withValues(alpha: 0.35),
            kTfPink.withValues(alpha: 0.18),
          ],
        ),
      ),
      child: Text(
        FormatUtils.formatAvatar(name),
        style: GoogleFonts.roboto(
          color: kTfPinkDark,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

/// Đường kẻ đứt nét, giống màn kết quả nạp/rút.
class TransferDashedDivider extends StatelessWidget {
  const TransferDashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace))
            .floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.pink.withValues(alpha: 0.15),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Một dòng "nhãn - giá trị" dùng cho màn xác nhận và kết quả.
class TransferInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  final int maxLines;
  final IconData? trailingIcon;
  const TransferInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
    this.maxLines = 1,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: maxLines > 1
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(label, style: _kInfoLabelStyle),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                    color: valueColor ?? kTfText,
                  ),
                ),
              ),
              if (trailingIcon != null)
                Icon(trailingIcon, size: 18, color: valueColor ?? kTfText),
            ],
          ),
        ),
      ],
    );
  }
}

/// Đóng băng `viewInsets` và `padding` của `MediaQuery` cho toàn bộ cây widget bên dưới.
/// Khi bàn phím trượt lên/xuống, `data.copyWith(...)` giữ nguyên giá trị không đổi giữa các frame,
/// giúp `MediaQuery.updateShouldNotify` trả về `false` -> `Scaffold`, `AppBar`, `SafeArea`
/// hoàn toàn KHÔNG bị rebuild hay relayout bất kỳ frame nào.
class FreezeKeyboardMediaQuery extends StatelessWidget {
  final Widget child;
  const FreezeKeyboardMediaQuery({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    return MediaQuery(
      data: data.copyWith(
        viewInsets: EdgeInsets.zero,
        padding: data.viewPadding,
        viewPadding: data.viewPadding,
      ),
      child: child,
    );
  }
}

/// Mở bàn phím ngay lập tức cho `focusNode`, kể cả khi người dùng vừa bấm nút Back
/// hệ thống để ẩn bàn phím (khi đó `focusNode.hasFocus` vẫn đang là `true`).
void requestKeyboardFocus(FocusNode focusNode) {
  if (!focusNode.hasFocus) {
    focusNode.requestFocus();
  } else {
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }
}

/// Dịch chuyển `child` lên/xuống theo chiều cao bàn phím hoàn toàn trên GPU (`Transform.translate`)
/// thông qua `WidgetsBindingObserver.didChangeMetrics`, không phụ thuộc vào `MediaQuery`
/// và không gây ra bất kỳ lượt `layout` nào:
/// - Trên Android 11+ / iOS (OS gửi `WindowInsetsAnimation` từng frame): bám 1:1 ở 120Hz, trễ 0ms.
/// - Trên thiết bị Android cũ / bàn phím nhảy bậc tức thời trong 1 frame (`delta > 140dp`):
///   nội suy mượt bằng `Curves.easeOutCubic` thay vì giật cục.
class KeyboardTranslate extends StatefulWidget {
  final Widget child;
  final bool subtractSafeArea;
  const KeyboardTranslate({
    super.key,
    required this.child,
    this.subtractSafeArea = true,
  });

  @override
  State<KeyboardTranslate> createState() => _KeyboardTranslateState();
}

class _KeyboardTranslateState extends State<KeyboardTranslate>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _fallbackController;
  double _displayedInset = 0.0;
  double _rawTarget = 0.0;
  double _animStartInset = 0.0;
  double _animEndInset = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fallbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(_onFallbackTick);
  }

  void _onFallbackTick() {
    final t = Curves.easeOutCubic.transform(_fallbackController.value);
    final value = _animStartInset + (_animEndInset - _animStartInset) * t;
    if ((value - _displayedInset).abs() > 0.05) {
      setState(() {
        _displayedInset = value;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncInset(initial: true);
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    _syncInset(initial: false);
  }

  void _syncInset({required bool initial}) {
    final view = View.of(context);
    final dpr = view.devicePixelRatio;
    final rawInset = view.viewInsets.bottom / dpr;
    final safeBottom = widget.subtractSafeArea
        ? (view.viewPadding.bottom / dpr)
        : 0.0;
    // Trừ đi chiều cao thanh điều hướng (SafeArea bottom) vì child bên trong đã có SafeArea,
    // giúp thanh nút nằm sát khít ngay trên mặt bàn phím mà không bị dư khoảng trắng.
    final next = rawInset > safeBottom ? (rawInset - safeBottom) : 0.0;
    final delta = (next - _rawTarget).abs();

    if (initial) {
      _rawTarget = next;
      _displayedInset = next;
      return;
    }

    if (delta <= 0.1) return;
    _rawTarget = next;

    if (delta > 140.0 && !_fallbackController.isAnimating) {
      _animStartInset = _displayedInset;
      _animEndInset = next;
      _fallbackController.forward(from: 0.0);
    } else {
      if (_fallbackController.isAnimating) {
        if (delta <= 140.0) {
          _fallbackController.stop();
          setState(() {
            _displayedInset = next;
          });
        } else {
          _animStartInset = _displayedInset;
          _animEndInset = next;
          _fallbackController.forward(from: 0.0);
        }
      } else {
        setState(() {
          _displayedInset = next;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fallbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -_displayedInset),
      child: RepaintBoundary(child: widget.child),
    );
  }
}

