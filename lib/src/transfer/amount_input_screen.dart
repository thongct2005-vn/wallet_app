import 'package:app/core/utils/currency_formatter.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:app/src/transfer/confirm_tranfer_screen.dart';
import 'package:app/src/transfer/transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:app/src/services/wallet_service.dart';

class AmountInputScreen extends StatefulWidget {
  final String? receiverPhone;
  final String? receiverFullName;
  final String? receiverId;
  final String? amount;
  final String? description;
  final String? referenceCode;
  final bool isMerchant;
  final String? orderId;
  const AmountInputScreen({
    super.key,
    this.receiverPhone,
    this.receiverFullName,
    this.receiverId,
    this.amount,
    this.description,
    this.referenceCode,
    this.isMerchant = false,
    this.orderId,
  });
  @override
  State<AmountInputScreen> createState() => _AmountInputScreenState();
}

class _AmountInputScreenState extends State<AmountInputScreen> {
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
  static final TextStyle _receiverNameStyle = GoogleFonts.roboto(
    color: kTfText,
    fontWeight: FontWeight.w700,
    fontSize: 18,
  );
  static final TextStyle _receiverPhoneStyle = GoogleFonts.roboto(
    color: kTfMuted,
    fontSize: 15,
  );
  static final TextStyle _labelMutedStyle = GoogleFonts.roboto(
    fontSize: 14,
    color: kTfMuted,
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
  static final TextStyle _chipSelectedStyle = GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: kTfPinkDark,
  );
  static final TextStyle _chipUnselectedStyle = GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: kTfText,
  );
  static final TextStyle _amountHintChipStyle = GoogleFonts.roboto(
    fontWeight: FontWeight.w700,
    fontSize: 15,
    color: kTfPinkDark,
  );
  static final List<CurrencyFormatter> _currencyFormatters = [
    CurrencyFormatter(),
  ];

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _desFocusNode = FocusNode();
  final WalletService _walletService = WalletService();

  final ValueNotifier<String> _msgNotifier = ValueNotifier<String>('');
  final ValueNotifier<int> _selectedDesHint = ValueNotifier<int>(0);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);

  // Chỉ thông báo khi text thực sự thay đổi (tránh rebuild khi con trỏ nhấp nháy hoặc đóng/mở bàn phím)
  late final ValueNotifier<double> _amountWidthNotifier;
  final ValueNotifier<String> _amountTextNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> _hasDesTextNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasAmountFocusNotifier = ValueNotifier<bool>(
    false,
  );
  final ValueNotifier<bool> _hasAnyFocusNotifier = ValueNotifier<bool>(false);

  bool get _isFixedAmount => widget.amount != null && widget.amount!.isNotEmpty;
  bool get _isFixedDescription =>
      widget.description != null && widget.description!.isNotEmpty;

  String? _amountHintOne = '';
  String? _amountHintTwo = '';
  String? _amountHintThree = '';
  String _walletBalance = '0';
  String _lastMeasuredAmountText = '';

  @override
  void initState() {
    super.initState();
    final initialAmount = _isFixedAmount ? widget.amount! : '';
    _lastMeasuredAmountText = initialAmount;
    _amountWidthNotifier = ValueNotifier<double>(
      _measureAmountWidth(initialAmount),
    );
    _amountTextNotifier.value = initialAmount;

    if (_isFixedAmount) {
      _amountController.text = initialAmount;
      _handleAmountChanged(initialAmount);
    }
    if (_isFixedDescription) {
      _descriptionController.text = widget.description!;
      _hasDesTextNotifier.value = widget.description!.isNotEmpty;
    }

    _amountFocusNode.addListener(_onFocusChanged);
    _desFocusNode.addListener(_onFocusChanged);
    _amountController.addListener(_onAmountControllerChanged);
    _descriptionController.addListener(_onDescriptionControllerChanged);
  }

  void _onFocusChanged() {
    final amountFocused = _amountFocusNode.hasFocus;
    final desFocused = _desFocusNode.hasFocus;
    _hasAmountFocusNotifier.value = amountFocused;
    _hasAnyFocusNotifier.value = amountFocused || desFocused;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final double targetOffset;
      if (desFocused) {
        targetOffset = 115.0;
      } else if (amountFocused) {
        targetOffset = 65.0;
      } else {
        targetOffset = 0.0;
      }
      final clamped = targetOffset.clamp(
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

  void _onAmountControllerChanged() {
    final text = _amountController.text;
    if (text == _lastMeasuredAmountText) return;
    _lastMeasuredAmountText = text;
    _amountWidthNotifier.value = _measureAmountWidth(text);
    _amountTextNotifier.value = text;
  }

  void _onDescriptionControllerChanged() {
    final hasText = _descriptionController.text.isNotEmpty;
    if (_hasDesTextNotifier.value != hasText) {
      _hasDesTextNotifier.value = hasText;
    }
  }

  @override
  void dispose() {
    _amountFocusNode.removeListener(_onFocusChanged);
    _desFocusNode.removeListener(_onFocusChanged);
    _amountController.removeListener(_onAmountControllerChanged);
    _descriptionController.removeListener(_onDescriptionControllerChanged);
    _scrollController.dispose();
    _amountFocusNode.dispose();
    _desFocusNode.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _msgNotifier.dispose();
    _selectedDesHint.dispose();
    _isLoadingNotifier.dispose();
    _amountWidthNotifier.dispose();
    _amountTextNotifier.dispose();
    _hasDesTextNotifier.dispose();
    _hasAmountFocusNotifier.dispose();
    _hasAnyFocusNotifier.dispose();
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
    return FreezeKeyboardMediaQuery(
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: kTfBg,
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: TransferCircleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.pop(context);
              },
            ),
            title: TransferAppBarTitle(
              widget.isMerchant ? "Thanh toán tới" : "Chuyển tiền tới",
            ),
          ),
          body: Stack(
            children: [
              const RepaintBoundary(child: TransferHeaderGradient()),
              SafeArea(
                bottom: false,
                child: SizedBox.expand(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Column(
                      children: [
                        RepaintBoundary(
                          child: _buildContainerReceiverInfo(context),
                        ),
                        const SizedBox(height: 16),
                        RepaintBoundary(
                          child: _buildContainerAmountInputAndDescription(
                            context,
                          ),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: _hasAnyFocusNotifier,
                          builder: (context, hasFocus, _) {
                            return SizedBox(height: hasFocus ? 420 : 140);
                          },
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
                child: KeyboardTranslate(
                  child: RepaintBoundary(
                    child: _buildContainerAmountHintButtonAndTranferButton(
                      context,
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

  Widget _buildContainerReceiverInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: transferCardDeco(),
      child: Row(
        children: [
          TransferAvatar(name: widget.receiverFullName ?? "?", size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.receiverFullName ?? "Không rõ tên",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _receiverNameStyle,
                ),
                if (!widget.isMerchant) ...[
                  const SizedBox(height: 3),
                  Text(
                    widget.receiverPhone ?? "***",
                    style: _receiverPhoneStyle,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Iconsax.tick_circle, color: kTfSuccess, size: 22),
        ],
      ),
    );
  }

  Widget _buildContainerAmountInputAndDescription(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: transferCardDeco(),
      child: Column(
        children: [
          Text("Nhập số tiền", style: _labelMutedStyle),
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isFixedAmount
                ? null
                : () => requestKeyboardFocus(_amountFocusNode),
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: RepaintBoundary(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _amountWidthNotifier,
                    child: TextField(
                      readOnly: _isFixedAmount,
                      focusNode: _amountFocusNode,
                      inputFormatters: _currencyFormatters,
                      maxLength: 10,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: false,
                        decimal: false,
                      ),
                      enableSuggestions: false,
                      autocorrect: false,
                      enableIMEPersonalizedLearning: false,
                      controller: _amountController,
                      textAlign: TextAlign.center,
                      style: _amountInputStyle,
                      cursorColor: kTfPink,
                      cursorHeight: 46,
                      onChanged: _handleAmountChanged,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.only(bottom: 2),
                        counterText: '',
                        isDense: true,
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: _amountHintStyle,
                        suffixIcon: Transform.translate(
                          offset: const Offset(-2, -4),
                          child: Text('đ', style: _currencySuffixStyle),
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
                                      : Colors.grey.withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: SizedBox(width: width, child: innerChild),
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
            valueListenable: _msgNotifier,
            builder: (context, msg, _) {
              if (msg.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: _errorTextStyle,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          RepaintBoundary(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isFixedDescription
                  ? null
                  : () => requestKeyboardFocus(_desFocusNode),
              child: ListenableBuilder(
                listenable: _desFocusNode,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.message_text, size: 20, color: kTfMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        readOnly: _isFixedDescription,
                        focusNode: _desFocusNode,
                        maxLength: 100,
                        controller: _descriptionController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: _desInputStyle,
                        cursorColor: kTfPink,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          counterText: '',
                          isDense: true,
                          hintText: 'Thêm lời nhắn',
                          hintStyle: _desHintStyle,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (!_isFixedDescription)
                      ValueListenableBuilder<bool>(
                        valueListenable: _hasDesTextNotifier,
                        builder: (context, hasText, _) {
                          if (!hasText) return const SizedBox.shrink();
                          return GestureDetector(
                            onTap: () {
                              _descriptionController.clear();
                              _selectedDesHint.value = 0;
                            },
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
                      border: Border.all(
                        width: 1.5,
                        color: hasFocus ? kTfPink : Colors.transparent,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: child,
                    ),
                  );
                },
              ),
            ),
          ),
          if (!_isFixedDescription) ...[
            const SizedBox(height: 14),
            ValueListenableBuilder<int>(
              valueListenable: _selectedDesHint,
              builder: (context, selectedHint, _) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDescriptionChip(
                      'Mình chuyển tiền nhé 💵',
                      selectedHint == 1,
                      _toggleFirstDesHint,
                    ),
                    _buildDescriptionChip(
                      'Cảm ơn nha 👍🫰',
                      selectedHint == 2,
                      _toggleSecondDesHint,
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected ? kTfPink.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          // Giữ cố định width: 1.5 để không kích hoạt relayout khi chọn chip
          border: Border.all(
            width: 1.5,
            color: isSelected ? kTfPink : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: isSelected ? _chipSelectedStyle : _chipUnselectedStyle,
          ),
        ),
      ),
    );
  }

  void _toggleFirstDesHint() {
    final bool isSelected = _selectedDesHint.value != 1;
    _selectedDesHint.value = isSelected ? 1 : 0;
    if (isSelected) {
      if (_descriptionController.text.contains('Cảm ơn nha 👍🫰')) {
        _descriptionController.text = _descriptionController.text.replaceAll(
          'Cảm ơn nha 👍🫰',
          'Mình chuyển tiền nhé 💵',
        );
      } else {
        _descriptionController.text =
            '${_descriptionController.text} Mình chuyển tiền nhé 💵';
      }
    } else {
      if (_descriptionController.text.contains(' Mình chuyển tiền nhé 💵')) {
        _descriptionController.text = _descriptionController.text.replaceAll(
          ' Mình chuyển tiền nhé 💵',
          '',
        );
      }
    }
  }

  void _toggleSecondDesHint() {
    final bool isSelected = _selectedDesHint.value != 2;
    _selectedDesHint.value = isSelected ? 2 : 0;
    if (isSelected) {
      if (_descriptionController.text.contains('Mình chuyển tiền nhé 💵')) {
        _descriptionController.text = _descriptionController.text.replaceAll(
          'Mình chuyển tiền nhé 💵',
          'Cảm ơn nha 👍🫰',
        );
      } else {
        _descriptionController.text =
            '${_descriptionController.text} Cảm ơn nha 👍🫰';
      }
    } else {
      if (_descriptionController.text.contains(' Cảm ơn nha 👍🫰')) {
        _descriptionController.text = _descriptionController.text.replaceAll(
          ' Cảm ơn nha 👍🫰',
          '',
        );
      }
    }
  }

  // Chip gợi ý số tiền (x10, x100, x1000...)
  Widget _buildAmountHintChip(
    String? hintValue,
    String defaultText,
    bool isAmountEmpty,
  ) {
    final String hint = hintValue ?? '';
    if (hint == 'NAN') return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        String newText = hint.isEmpty ? defaultText : hint.replaceAll('đ', '');
        _amountController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
        _handleAmountChanged(newText);
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: kTfPink.withValues(alpha: 0.08),
        ),
        child: Text(
          isAmountEmpty ? '${defaultText}đ' : hint,
          style: _amountHintChipStyle,
        ),
      ),
    );
  }

  Widget _buildContainerAmountHintButtonAndTranferButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isFixedAmount)
                RepaintBoundary(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      _amountTextNotifier,
                      _hasAmountFocusNotifier,
                    ]),
                    builder: (context, _) {
                      if (!_hasAmountFocusNotifier.value) {
                        return const SizedBox.shrink();
                      }
                      final bool isAmountEmpty =
                          _amountTextNotifier.value.isEmpty;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildAmountHintChip(
                                _amountHintOne,
                                '1.000',
                                isAmountEmpty,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildAmountHintChip(
                                _amountHintTwo,
                                '10.000',
                                isAmountEmpty,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildAmountHintChip(
                                _amountHintThree,
                                '100.000',
                                isAmountEmpty,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              RepaintBoundary(
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    _amountTextNotifier,
                    _msgNotifier,
                    _isLoadingNotifier,
                  ]),
                  builder: (context, _) {
                    final bool isEnable =
                        _amountTextNotifier.value.isNotEmpty &&
                        _msgNotifier.value.isEmpty;
                    return TransferPrimaryButton(
                      label: widget.isMerchant ? "Thanh toán" : "Chuyển tiền",
                      enabled: isEnable,
                      loading: _isLoadingNotifier.value,
                      onTap: () async {
                        FocusManager.instance.primaryFocus?.unfocus();
                        _isLoadingNotifier.value = true;
                        final result = await _walletService
                            .checkTransferEligibility(_amountController.text);
                        _isLoadingNotifier.value = false;
                        if (result['is_success']) {
                          if (!result['is_eligible']) {
                            _msgNotifier.value = 'Số dư trong ví không đủ';
                          } else {
                            _walletBalance = result['wallet_balance'];
                          }
                        } else {
                          _msgNotifier.value =
                              'Hệ thống đang bảo trì. Vui lòng thử lại sau';
                        }
                        if (!context.mounted) return;
                        if (_msgNotifier.value.isEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConfirmTranferScreen(
                                receiverId: widget.receiverId,
                                receiverName: widget.receiverFullName,
                                receiverPhone: widget.receiverPhone,
                                amount: _amountController.text,
                                description: _descriptionController.text,
                                walletBalance: _walletBalance,
                                referenceCode: widget.referenceCode,
                                isMerchant: widget.isMerchant,
                                orderId: widget.orderId,
                              ),
                            ),
                          );
                        }
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

  void _handleAmountChanged(String value) {
    num amountNum = FormatUtils.formatAmountToNum(value);
    if (amountNum == 0) {
      _amountHintOne = '';
      _amountHintTwo = '';
      _amountHintThree = '';
      _msgNotifier.value = 'Vui lòng nhập số tiền';
    } else {
      _amountHintOne = _calculateHint(amountNum, 1000, 10);
      _amountHintTwo = _calculateHint(amountNum, 10000, 100);
      _amountHintThree = _calculateHint(amountNum, 100000, 1000);
      if (amountNum < 1000) {
        _msgNotifier.value = 'Số tiền tối thiểu là 1000đ';
      } else if (amountNum > 50000000) {
        _msgNotifier.value = 'Số tiền tối đa là 50.000.000đ';
      } else {
        _msgNotifier.value = '';
      }
    }
  }
}

String _calculateHint(
  num baseAmount,
  num multiplyIfSmall,
  num multiplyIfLarge,
) {
  if (baseAmount == 0) return '';

  num calculatedAmount = (baseAmount < 1000)
      ? baseAmount * multiplyIfSmall
      : baseAmount * multiplyIfLarge;
  if (calculatedAmount <= 50000000) {
    return '${FormatUtils.formatDisplayNumber(calculatedAmount)}đ';
  }

  return 'NAN';
}
