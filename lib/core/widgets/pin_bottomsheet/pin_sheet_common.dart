import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

/// Đóng băng `viewInsets` và `padding` của `MediaQuery` cho toàn bộ cây widget bên dưới.
/// Khi bàn phím trượt lên/xuống, `MediaQuery.updateShouldNotify` luôn trả về `false`,
/// giúp `Scaffold`, `AppBar`, `SafeArea` và toàn bộ nội dung bên dưới KHÔNG bị rebuild
/// hay relayout ở bất kỳ frame nào trong suốt quá trình mở/đóng bàn phím.
class FreezePinMediaQuery extends StatelessWidget {
  final Widget child;
  const FreezePinMediaQuery({super.key, required this.child});

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

/// Dịch chuyển `child` theo chiều cao bàn phím hoàn toàn trên GPU (`Transform.translate`)
/// thông qua `WidgetsBindingObserver.didChangeMetrics`:
/// - Không phụ thuộc `MediaQuery`, không gây bất kỳ lượt `layout` hay `paint` lại nào.
/// - Trên Android 11+ / iOS (OS gửi `WindowInsetsAnimation` từng frame): bám sát 1:1
///   với mặt bàn phím gốc ở tần số 120Hz, độ trễ 0ms.
/// - Trên thiết bị Android cũ / bàn phím nhảy bậc tức thời trong 1 frame (`delta > 140dp`):
///   tự động nội suy mượt bằng `Curves.easeOutCubic` thay vì giật cục 1 frame.
class PinKeyboardTranslate extends StatefulWidget {
  final Widget child;
  final bool subtractSafeArea;

  const PinKeyboardTranslate({
    super.key,
    required this.child,
    this.subtractSafeArea = true,
  });

  @override
  State<PinKeyboardTranslate> createState() => _PinKeyboardTranslateState();
}

class _PinKeyboardTranslateState extends State<PinKeyboardTranslate>
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
    final next = rawInset > safeBottom ? (rawInset - safeBottom) : 0.0;
    final delta = (next - _rawTarget).abs();

    if (initial) {
      _rawTarget = next;
      _displayedInset = next;
      return;
    }

    if (delta <= 0.1) return;
    _rawTarget = next;

    // Nếu OS nhảy vọt toàn bộ chiều cao bàn phím trong 1 frame duy nhất (> 140dp),
    // dùng controller nội suy mượt trên GPU; ngược lại bám trực tiếp 1:1 theo OS.
    if (delta > 140.0 && !_fallbackController.isAnimating) {
      _animStartInset = _displayedInset;
      _animEndInset = next;
      _fallbackController.forward(from: 0.0);
    } else {
      if (_fallbackController.isAnimating) {
        // Nếu ngay frame kế tiếp OS gửi tiếp delta nhỏ -> OS đang tự animate WindowInsets,
        // hủy fallback để bám sát 1:1 không trễ.
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

/// Route chuyên dụng cho PIN Bottom Sheet đạt chuẩn 120Hz:
/// - Loại bỏ hoàn toàn `_ModalBottomSheetLayout` (`CustomSingleChildLayout`) và
///   hiện tượng nhân đôi tốc độ dịch chuyển `(sheetHeight + keyboardInset) * progress`.
/// - Không bọc `FadeTransition` (`saveLayer`) lên thân sheet: barrier tự mờ dần,
///   thân sheet giữ nguyên texture trắng sắc nét và chỉ dịch chuyển qua `TransformLayer`.
/// - Tự động đóng bàn phím đồng bộ ngay frame đầu tiên khi đóng sheet (`didPop`).
class _SmoothPinSheetRoute<T> extends PopupRoute<T> {
  final WidgetBuilder builder;

  _SmoothPinSheetRoute({required this.builder});

  @override
  Color? get barrierColor => Colors.black54;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 210);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  Animation<Offset>? _slideAnimation;

  @override
  bool didPop(T? result) {
    FocusManager.instance.primaryFocus?.unfocus();
    return super.didPop(result);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return FreezePinMediaQuery(
      child: Material(
        type: MaterialType.transparency,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: RepaintBoundary(child: builder(context)),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    _slideAnimation ??= Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    return PinKeyboardTranslate(
      child: SlideTransition(
        position: _slideAnimation!,
        child: child,
      ),
    );
  }
}

/// Hiển thị bottom sheet PIN mượt mà 120Hz.
Future<T?> showSmoothPinBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return Navigator.of(context).push<T>(_SmoothPinSheetRoute<T>(builder: builder));
}

/// Widget bọc nội dung PIN Bottom Sheet:
/// - Nếu đã nằm trong `_SmoothPinSheetRoute`, không dịch chuyển trùng lặp mà chỉ
///   cách ly repaint + chặn sự kiện chạm xuyên xuống barrier.
/// - Nếu được gắn độc lập bên ngoài `_SmoothPinSheetRoute`, tự động bật
///   `FreezePinMediaQuery` + `PinKeyboardTranslate`.
class SmoothKeyboardSheet extends StatelessWidget {
  final Widget child;
  const SmoothKeyboardSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: RepaintBoundary(child: child),
    );

    if (route is _SmoothPinSheetRoute) {
      return content;
    }

    return FreezePinMediaQuery(
      child: PinKeyboardTranslate(child: content),
    );
  }
}

/// Alias cho backward compatibility
typedef PinKeyboardInsetPadding = SmoothKeyboardSheet;

/// Ô nhập mã PIN 6 số siêu nhẹ cho tốc độ mở bàn phím tức thì 120Hz:
/// - Dùng trực tiếp `EditableText` ẩn kích thước 1x1 thay vì `Pinput` (loại bỏ hoàn toàn
///   6 `AnimatedContainer` + 6 `AnimatedSwitcher` + `FormField` + `InputDecorator`).
/// - Bật `enableSuggestions: false`, `autocorrect: false`, `enableIMEPersonalizedLearning: false`
///   để bàn phím Android (Gboard / Samsung Keyboard) bỏ qua khởi tạo thanh gợi ý từ,
///   giúp bàn phím số phản hồi nhanh hơn rõ rệt.
/// - Vùng chạm phủ kín toàn bộ viên thuốc cao 60px; kể cả khi người dùng bấm nút Back hệ thống
///   để ẩn bàn phím (lúc `focusNode.hasFocus` vẫn đang `true`), chạm lại vào bất kỳ vị trí nào
///   trên khung vẫn gọi trực tiếp `EditableTextState.requestKeyboard()` để bật bàn phím ngay lần chạm đầu.
/// - Khi gõ từng số, chỉ `ValueListenableBuilder` của 6 chấm tròn vẽ lại bên trong `RepaintBoundary` riêng.
class PinCodeInputPill extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  const PinCodeInputPill({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hasError = false,
    this.onChanged,
    this.onCompleted,
  });

  @override
  State<PinCodeInputPill> createState() => PinCodeInputPillState();
}

class PinCodeInputPillState extends State<PinCodeInputPill> {
  static final List<TextInputFormatter> _digitsFormatters = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(6),
  ];

  static const TextStyle _hiddenEditableStyle = TextStyle(
    color: Colors.transparent,
    fontSize: 1,
    height: 1,
  );

  static final BoxDecoration _emptyDotDeco = BoxDecoration(
    color: Colors.grey.shade400,
    shape: BoxShape.circle,
  );

  static const BoxDecoration _filledDotDeco = BoxDecoration(
    color: Colors.black,
    shape: BoxShape.circle,
  );

  final GlobalKey<EditableTextState> _editableKey =
      GlobalKey<EditableTextState>();
  final ValueNotifier<bool> _isShowPinNotifier = ValueNotifier<bool>(false);
  bool _completedTriggered = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant PinCodeInputPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
  }

  void _handleControllerChanged() {
    if (widget.controller.text.length < 6) {
      _completedTriggered = false;
    }
  }

  /// Mở bàn phím ngay lập tức, kể cả khi `focusNode.hasFocus` đang là `true`
  /// sau khi người dùng vừa ẩn bàn phím bằng phím Back hệ thống.
  void requestKeyboard() {
    if (!mounted) return;
    final textLen = widget.controller.text.length;
    if (widget.controller.selection.baseOffset != textLen ||
        widget.controller.selection.extentOffset != textLen) {
      widget.controller.selection = TextSelection.collapsed(offset: textLen);
    }
    final editable = _editableKey.currentState;
    if (editable != null) {
      editable.requestKeyboard();
    } else {
      widget.focusNode.requestFocus();
    }
  }

  void _onTextChanged(String value) {
    widget.onChanged?.call(value);
    if (value.length == 6 && !_completedTriggered) {
      _completedTriggered = true;
      widget.onCompleted?.call(value);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _isShowPinNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: requestKeyboard,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white,
            border: Border.all(
              width: 0.5,
              color: widget.hasError
                  ? Colors.red
                  : Colors.grey.withValues(alpha: 0.5),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // EditableText 1x1 ẩn dùng để kết nối trực tiếp với bàn phím gốc
              IgnorePointer(
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: EditableText(
                    key: _editableKey,
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    style: _hiddenEditableStyle,
                    cursorColor: Colors.transparent,
                    backgroundCursorColor: Colors.transparent,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: false,
                      decimal: false,
                    ),
                    textInputAction: TextInputAction.done,
                    inputFormatters: _digitsFormatters,
                    enableSuggestions: false,
                    autocorrect: false,
                    enableIMEPersonalizedLearning: false,
                    enableInteractiveSelection: false,
                    showCursor: false,
                    onChanged: _onTextChanged,
                  ),
                ),
              ),
              // 6 chấm tròn / chữ số hiển thị độc lập, không rebuild khi đóng/mở bàn phím
              ListenableBuilder(
                listenable: Listenable.merge([
                  widget.controller,
                  _isShowPinNotifier,
                ]),
                builder: (context, _) {
                  final text = widget.controller.text;
                  final showPin = _isShowPinNotifier.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(6, (index) {
                      final isFilled = index < text.length;
                      Widget dot;
                      if (!isFilled) {
                        dot = DecoratedBox(decoration: _emptyDotDeco);
                      } else if (showPin) {
                        dot = Center(
                          child: Text(
                            text[index],
                            style: PinSheetStyles.visiblePinText,
                          ),
                        );
                      } else {
                        dot = const DecoratedBox(decoration: _filledDotDeco);
                      }
                      return Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : 10),
                        child: SizedBox(width: 18, height: 18, child: dot),
                      );
                    }),
                  );
                },
              ),
              // Nút ẩn/hiện mã PIN bên phải
              Positioned(
                right: 5,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: widget.controller,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return ValueListenableBuilder<bool>(
                      valueListenable: _isShowPinNotifier,
                      builder: (context, showPin, _) {
                        return IconButton(
                          onPressed: () {
                            _isShowPinNotifier.value = !showPin;
                            requestKeyboard();
                          },
                          icon: Icon(
                            showPin
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Style và theme dùng chung cho PIN bottom sheet
class PinSheetStyles {
  PinSheetStyles._();

  static final TextStyle title = GoogleFonts.roboto(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );
  static final TextStyle subtitle = GoogleFonts.roboto(
    fontSize: 15,
    color: Colors.grey,
  );
  static final TextStyle error = GoogleFonts.roboto(
    color: Colors.red,
    fontSize: 12,
  );
  static final TextStyle forgot = GoogleFonts.roboto(
    fontSize: 15,
    color: Colors.blue,
    fontWeight: FontWeight.w500,
  );
  static final TextStyle reset = GoogleFonts.roboto(
    fontSize: 15,
    color: Colors.pink.shade600,
    fontWeight: FontWeight.w500,
  );
  static final TextStyle visiblePinText = GoogleFonts.roboto(
    fontSize: 15,
    color: Colors.black,
    fontWeight: FontWeight.w600,
  );

  /// Theme chấm tròn xám khi chưa nhập số
  static final PinTheme defaultPin = PinTheme(
    width: 18,
    height: 18,
    margin: const EdgeInsets.symmetric(horizontal: 1),
    textStyle: const TextStyle(color: Colors.transparent),
    decoration: BoxDecoration(
      color: Colors.grey.shade400,
      shape: BoxShape.circle,
    ),
  );

  /// Theme chấm tròn đen khi đã nhập số (ẩn số, chữ trong suốt)
  static final PinTheme submittedPin = defaultPin.copyWith(
    textStyle: const TextStyle(color: Colors.transparent),
    decoration: const BoxDecoration(
      color: Colors.black,
      shape: BoxShape.circle,
    ),
  );

  /// Theme hiện số rõ ràng khi nhấn nút con mắt
  static final PinTheme visiblePin = defaultPin.copyWith(
    textStyle: visiblePinText,
    decoration: const BoxDecoration(
      color: Colors.transparent,
      shape: BoxShape.circle,
    ),
  );
}
