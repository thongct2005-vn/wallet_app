import 'package:app/core/controller/user_controller.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:app/core/widgets/pin_bottomsheet/pin_sheet_common.dart';
import 'package:app/src/services/payment_service.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/utils/currency_formatter.dart';

class CreateQRScreen extends StatefulWidget {
  const CreateQRScreen({super.key});
  @override
  State<CreateQRScreen> createState() => _CreateQRScreenState();
}

class _CreateQRScreenState extends State<CreateQRScreen> {
  static final TextStyle _amountMeasureStyle = GoogleFonts.roboto(fontSize: 40);
  static final TextStyle _amountInputStyle = GoogleFonts.roboto(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: kTfText,
  );
  static final TextStyle _amountHintStyle = GoogleFonts.roboto(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: Colors.grey.withValues(alpha: 0.4),
  );
  static final TextStyle _mioBrandStyle = GoogleFonts.baloo2(
    color: kTfPink,
    fontWeight: FontWeight.w700,
    fontSize: 26,
  );
  static final TextStyle _avatarTextStyle = GoogleFonts.roboto(
    color: kTfPinkDark,
    fontWeight: FontWeight.w700,
    fontSize: 16,
  );
  static final TextStyle _addAmountBtnStyle = GoogleFonts.roboto(
    color: kTfPinkDark,
    fontWeight: FontWeight.w700,
    fontSize: 16,
  );
  static final TextStyle _qrDesStyle = GoogleFonts.roboto(
    color: kTfMuted,
    fontWeight: FontWeight.w500,
    fontSize: 15,
  );
  static final TextStyle _actionLabelStyle = GoogleFonts.roboto(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: kTfText,
  );
  static final TextStyle _sheetTitleStyle = GoogleFonts.roboto(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: kTfText,
  );
  static final TextStyle _currencySuffixStyle = GoogleFonts.roboto(
    fontSize: 20,
    color: kTfMuted,
  );
  static final TextStyle _errorTextStyle = GoogleFonts.roboto(
    fontSize: 14,
    color: Colors.redAccent,
  );
  static final TextStyle _desInputStyle = GoogleFonts.roboto(
    fontSize: 16,
    color: kTfText,
  );
  static final TextStyle _desHintStyle = GoogleFonts.roboto(
    fontSize: 16,
    color: kTfMuted,
  );
  static final TextStyle _counterTextStyle = GoogleFonts.roboto(
    fontSize: 12,
    color: kTfMuted,
  );
  static final List<CurrencyFormatter> _currencyFormatters = [
    CurrencyFormatter(),
  ];

  final PaymentService _paymentService = PaymentService();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _desController = TextEditingController();
  final UserController _userController = Get.find<UserController>();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _desFocusNode = FocusNode();
  final ValueNotifier<String> _amountMsgNotifier = ValueNotifier<String>('');

  // Các ValueNotifier chỉ phát tín hiệu khi text thực sự thay đổi (bỏ qua sự kiện nhấp nháy con trỏ / đóng mở bàn phím)
  late final ValueNotifier<double> _amountWidthNotifier;
  final ValueNotifier<bool> _hasAmountTextNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> _desLengthNotifier = ValueNotifier<int>(0);

  String _lastAmountText = '';
  String _lastDesText = '';

  String _qrData = "";
  String? _phone = '';
  String? _fullName = '';
  String? _avatar = '';
  int? _amount = 0;
  String? _description = '';

  @override
  void initState() {
    super.initState();
    _amountWidthNotifier = ValueNotifier<double>(_measureAmountWidth(''));
    _amountController.addListener(_onAmountControllerChanged);
    _desController.addListener(_onDesControllerChanged);
    _phone = _userController.phone.value;
    _fullName = _userController.fullName.value;
    _avatar = FormatUtils.formatAvatar(_fullName ?? '?');
    _loadStaticQRToken();
  }

  void _onAmountControllerChanged() {
    final text = _amountController.text;
    if (text == _lastAmountText) return;
    _lastAmountText = text;
    _amountWidthNotifier.value = _measureAmountWidth(text);
    _hasAmountTextNotifier.value = text.isNotEmpty;
  }

  void _onDesControllerChanged() {
    final text = _desController.text;
    if (text == _lastDesText) return;
    _lastDesText = text;
    _desLengthNotifier.value = text.length;
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountControllerChanged);
    _desController.removeListener(_onDesControllerChanged);
    _textController.dispose();
    _amountController.dispose();
    _desController.dispose();
    _amountFocusNode.dispose();
    _desFocusNode.dispose();
    _amountMsgNotifier.dispose();
    _amountWidthNotifier.dispose();
    _hasAmountTextNotifier.dispose();
    _desLengthNotifier.dispose();
    super.dispose();
  }

  static double _measureAmountWidth(String text) {
    final painter = TextPainter(
      text: TextSpan(
        text: text.isEmpty ? '0' : text,
        style: _amountMeasureStyle,
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final width = painter.width + 30;
    painter.dispose();
    return width < 50 ? 50 : width;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAmount = _amount != null && _amount != 0;

    return FreezeKeyboardMediaQuery(
      child: Scaffold(
        backgroundColor: kTfBg,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: TransferCircleButton(
            icon: Icons.arrow_back,
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(context);
            },
          ),
          title: const TransferAppBarTitle('Nhận tiền'),
        ),
        body: Stack(
          children: [
            const RepaintBoundary(child: TransferHeaderGradient()),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: kTfPink.withValues(alpha: 0.12),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildQrPanel(hasAmount),
                      const SizedBox(height: 18),
                      _buildActionRow(),
                      const SizedBox(height: 18),
                      const TransferDashedDivider(),
                      const SizedBox(height: 14),
                      _buildRow('Tên người nhận', _fullName ?? "?"),
                      _buildRow('Ngân hàng', "Mio"),
                      _buildRow('Số tài khoản', _phone ?? "0xxxxxxxxx"),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TransferInfoRow(label: label, value: value, maxLines: 2),
    );
  }

  Widget _buildQrPanel(bool hasAmount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: kTfPink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(width: 1, color: kTfPink.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text("Mio", style: _mioBrandStyle),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: kTfPink.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _qrData.isEmpty
                ? const SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(
                      child: CircularProgressIndicator(color: kTfPink),
                    ),
                  )
                : RepaintBoundary(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 220.0,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kTfPink.withValues(alpha: 0.12),
                            ),
                            child: Text(_avatar ?? '?', style: _avatarTextStyle),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _showAmountBottomSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  width: 1,
                  color: kTfPink.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasAmount ? Icons.edit_outlined : Icons.add,
                    size: 16,
                    color: kTfPink,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      hasAmount
                          ? "${FormatUtils.formatDisplayNumber(_amount!)}đ"
                          : "Thêm số tiền",
                      overflow: TextOverflow.ellipsis,
                      style: _addAmountBtnStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_desController.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _desController.text,
              textAlign: TextAlign.center,
              style: _qrDesStyle,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    Widget item(IconData icon, String label) {
      return Expanded(
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: kTfPink.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: kTfPink, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label, style: _actionLabelStyle),
          ],
        ),
      );
    }

    return Row(
      children: [
        item(Icons.download_outlined, "Tải xuống"),
        item(Icons.settings_outlined, "Tùy chỉnh"),
        item(Icons.share_outlined, "Chia sẻ"),
      ],
    );
  }

  void _showAmountBottomSheet() {
    // Đợi frame đầu của BottomSheet dựng xong mới mở bàn phím để tránh giật frame đầu tiên
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        requestKeyboardFocus(_amountFocusNode);
      }
    });

    showSmoothPinBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SmoothKeyboardSheet(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        "Thêm số tiền",
                        textAlign: TextAlign.center,
                        style: _sheetTitleStyle,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => requestKeyboardFocus(_amountFocusNode),
                      child: SizedBox(
                        width: double.infinity,
                        child: Center(
                          child: RepaintBoundary(
                            child: ValueListenableBuilder<double>(
                              valueListenable: _amountWidthNotifier,
                              child: TextField(
                                controller: _amountController,
                                focusNode: _amountFocusNode,
                                inputFormatters: _currencyFormatters,
                                maxLength: 10,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      signed: false,
                                      decimal: false,
                                    ),
                                enableSuggestions: false,
                                autocorrect: false,
                                enableIMEPersonalizedLearning: false,
                                textAlign: TextAlign.center,
                                style: _amountInputStyle,
                                cursorColor: kTfPink,
                                cursorHeight: 46,
                                onChanged: (val) {
                                  final amountNum =
                                      FormatUtils.formatAmountToNum(val);
                                  if (amountNum == 0) {
                                    _amountMsgNotifier.value =
                                        'Vui lòng nhập số tiền';
                                  } else if (amountNum < 1000) {
                                    _amountMsgNotifier.value =
                                        'Số tiền tối thiểu là 1000đ';
                                  } else if (amountNum > 50000000) {
                                    _amountMsgNotifier.value =
                                        'Số tiền tối đa là 50.000.000đ';
                                  } else {
                                    _amountMsgNotifier.value = '';
                                  }
                                },
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.only(
                                    bottom: 2,
                                  ),
                                  counterText: '',
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: '0',
                                  hintStyle: _amountHintStyle,
                                  suffixIcon: Transform.translate(
                                    offset: const Offset(-2, -4),
                                    child: Text(
                                      'đ',
                                      style: _currencySuffixStyle,
                                    ),
                                  ),
                                  suffixIconConstraints: const BoxConstraints(
                                    minWidth: 0,
                                    minHeight: 0,
                                  ),
                                ),
                              ),
                              builder: (context, width, child) {
                                return ListenableBuilder(
                                  listenable: _amountFocusNode,
                                  child: child,
                                  builder: (context, innerChild) {
                                    final hasFocus = _amountFocusNode.hasFocus;
                                    return DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: hasFocus
                                                ? kTfPink
                                                : Colors.grey.withValues(
                                                    alpha: 0.35,
                                                  ),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      child: SizedBox(
                                        width: width,
                                        child: innerChild,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    ValueListenableBuilder<String>(
                      valueListenable: _amountMsgNotifier,
                      builder: (context, msg, _) {
                        if (msg.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Center(
                            child: Text(msg, style: _errorTextStyle),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    RepaintBoundary(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => requestKeyboardFocus(_desFocusNode),
                        child: ListenableBuilder(
                          listenable: _desFocusNode,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  focusNode: _desFocusNode,
                                  controller: _desController,
                                  maxLength: 50,
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  style: _desInputStyle,
                                  cursorColor: kTfPink,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    counterText: '',
                                    isDense: true,
                                    hintText: 'Thêm lời nhắn',
                                    hintStyle: _desHintStyle,
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              ValueListenableBuilder<int>(
                                valueListenable: _desLengthNotifier,
                                builder: (context, length, _) {
                                  if (length == 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return GestureDetector(
                                    onTap: _desController.clear,
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.cancel,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          builder: (context, child) {
                            final hasFocus = _desFocusNode.hasFocus;
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                color: kTfBg,
                                borderRadius: BorderRadius.circular(16),
                                // Giữ cố định width: 1.5 để không gây relayout khi focus/unfocus ô mô tả
                                border: Border.all(
                                  width: 1.5,
                                  color: hasFocus
                                      ? kTfPink
                                      : Colors.transparent,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                child: child,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: ValueListenableBuilder<int>(
                          valueListenable: _desLengthNotifier,
                          builder: (context, length, _) {
                            return Text("$length/50", style: _counterTextStyle);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    RepaintBoundary(
                      child: ListenableBuilder(
                        listenable: Listenable.merge([
                          _hasAmountTextNotifier,
                          _amountMsgNotifier,
                        ]),
                        builder: (btnContext, _) {
                          final enabled =
                              _amountMsgNotifier.value.isEmpty &&
                              _hasAmountTextNotifier.value;
                          return TransferPrimaryButton(
                            label: "Xác nhận",
                            enabled: enabled,
                            onTap: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              final amountNum = FormatUtils.formatAmountToNum(
                                _amountController.text,
                              );
                              setState(() {
                                _amount = amountNum.toInt();
                                _description = _desController.text.trim();
                              });
                              Navigator.pop(sheetContext);
                              _loadDynamicQRToken(
                                amountNum.toInt(),
                                _description ?? '',
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
          ),
        );
      },
    );
  }

  Future<void> _loadStaticQRToken() async {
    try {
      final result = await _paymentService.getStaticQRToken();
      final token = result['token'];
      if (mounted) {
        setState(() {
          _qrData = token ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _qrData = '';
        });
      }
    }
  }

  Future<void> _loadDynamicQRToken(int amount, String description) async {
    try {
      final result = await _paymentService.createDynamicQRToken(
        amount,
        description,
      );

      final token = result['token']['reference_code'];

      if (mounted) {
        setState(() {
          _amount = amount;
          _description = description;
          _qrData = token ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _qrData = '';
        });
      }
    }
  }
}


