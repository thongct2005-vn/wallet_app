import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class AmountInputScreen extends StatefulWidget {
  final String? phone;
  final String? fullName;
  final String? avatarName;
  const AmountInputScreen({
    super.key,
    this.phone,
    this.fullName,
    this.avatarName,
  });
  @override
  State<AmountInputScreen> createState() => _AmountInputScreenState();
}

class _AmountInputScreenState extends State<AmountInputScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSelectedFirstDesHint = false;
  bool _isSelectedSecondDesHint = false;
  String? _msg = '';
  String? _amountHintOne = '';
  String? _amountHintTwo = '';
  String? _amountHintThree = '';
  final FocusNode _amountFocusNode = FocusNode();
  bool _isAmountFocus = false;
  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(() {
      setState(() {
        _isAmountFocus = _amountFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _amountFocusNode.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: EdgeInsets.fromLTRB(10, 15, 0, 15),
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.arrow_back, size: 20),
              ),
            ),
          ),
          title: Text(
            "Chuyển tiền tới",
            style: GoogleFonts.roboto(fontSize: 20),
          ),
        ),
        body: Stack(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.pink.shade200.withValues(alpha: 0.75),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: _buildContainerReceiverInfo(context),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: _buildContainerAmountInputAndDescription(context),
                  ),
                  const Spacer(),
                  _buildContainerAmountHintButtonAndTranferButton(context)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerReceiverInfo(BuildContext context) {
    return Container(
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(width: 1, color: Colors.green),
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.pink.shade50.withValues(alpha: 0.6),
              child: Text(
                widget.avatarName ?? "?",
                style: GoogleFonts.roboto(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.fullName ?? "Không rõ tên",
                  style: GoogleFonts.roboto(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  widget.phone ?? "***",
                  style: GoogleFonts.roboto(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerAmountInputAndDescription(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(width: 1, color: Colors.white),
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Center(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _amountController,
                builder: (context, value, child) {
                  return IntrinsicWidth(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          constraints: BoxConstraints(minWidth: 50),
                          child: Text(
                            value.text.isEmpty ? '0' : value.text,
                            style: GoogleFonts.roboto(
                              fontSize: 40,
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: TextField(
                            focusNode: _amountFocusNode,
                            inputFormatters: [CurrencyFormatter()],
                            maxLength: 10,
                            keyboardType: TextInputType.number,
                            controller: _amountController,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                            ),
                            cursorColor: Colors.pink,
                            cursorHeight: 50,
                            onChanged: (value) {
                              _handleAmountChanged(value);
                            },
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.only(bottom: 0),
                              counterText: '',
                              isDense: true,
                              hintText: '0',
                              hintStyle: GoogleFonts.roboto(
                                fontSize: 40,
                                color: Colors.grey,
                              ),

                              suffixIcon: Transform.translate(
                                offset: const Offset(-2, -4),
                                child: Text(
                                  'đ',
                                  style: GoogleFonts.roboto(
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                ),
                              ),

                              suffixIconConstraints: const BoxConstraints(
                                minWidth: 0,
                                minHeight: 0,
                              ),

                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.pink,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_msg != '') ...[
              SizedBox(height: 10),
              Text(
                _msg ?? '',
                style: GoogleFonts.roboto(fontSize: 18, color: Colors.red),
              ),
            ],
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),

              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  TextField(
                    maxLength: 100,
                    controller: _descriptionController,
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      setState(() {});
                    },
                    maxLines: null,
                    keyboardType: TextInputType.multiline,

                    style: GoogleFonts.roboto(fontSize: 20),
                    cursorColor: Colors.pink,
                    cursorHeight: 20,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.only(right: 30),
                      counterText: '',
                      isDense: true,
                      hintText: 'Thêm lời nhắn',
                      hintStyle: GoogleFonts.roboto(
                        fontSize: 20,
                        color: Colors.grey,
                      ),
                      border: UnderlineInputBorder(borderSide: BorderSide.none),
                    ),
                  ),
                  if (_descriptionController.text.isNotEmpty)
                    Positioned(
                      right: -6,
                      child: IconButton(
                        constraints: BoxConstraints(),
                        padding: EdgeInsets.all(10),
                        onPressed: () {
                          setState(() {
                            _descriptionController.text = '';
                          });
                        },
                        icon: Icon(Icons.cancel, size: 16, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Divider(height: 0.5, color: Colors.grey.withValues(alpha: 0.1)),
            const SizedBox(height: 10),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSelectedFirstDesHint = !_isSelectedFirstDesHint;
                      _isSelectedSecondDesHint = false;
                      if (_isSelectedFirstDesHint) {
                        if (_descriptionController.text.contains(
                          'Cảm ơn nha 👍🫰',
                        )) {
                          _descriptionController.text = _descriptionController
                              .text
                              .replaceAll(
                                'Cảm ơn nha 👍🫰',
                                'Mình chuyển tiền nhé 💵',
                              );
                        } else {
                          _descriptionController.text =
                              _descriptionController.text +
                              ' Mình chuyển tiền nhé 💵'.toString();
                        }
                      } else {
                        if (_descriptionController.text.contains(
                          ' Mình chuyển tiền nhé 💵',
                        )) {
                          _descriptionController.text = _descriptionController
                              .text
                              .replaceAll(' Mình chuyển tiền nhé 💵', '');
                        }
                      }
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    height: 35,
                    decoration: BoxDecoration(
                      color: _isSelectedFirstDesHint
                          ? Colors.pink.shade100.withValues(alpha: 0.5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        width: 1,
                        color: _isSelectedFirstDesHint
                            ? Colors.pink
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(left: 5, right: 5),
                      child: Text(
                        'Mình chuyển tiền nhé 💵',
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSelectedSecondDesHint = !_isSelectedSecondDesHint;
                      _isSelectedFirstDesHint = false;
                      if (_isSelectedSecondDesHint) {
                        if (_descriptionController.text.contains(
                          'Mình chuyển tiền nhé 💵',
                        )) {
                          _descriptionController.text = _descriptionController
                              .text
                              .replaceAll(
                                'Mình chuyển tiền nhé 💵',
                                'Cảm ơn nha 👍🫰',
                              );
                        } else {
                          _descriptionController.text =
                              _descriptionController.text +
                              ' Cảm ơn nha 👍🫰'.toString();
                        }
                      } else {
                        if (_descriptionController.text.contains(
                          ' Cảm ơn nha 👍🫰',
                        )) {
                          _descriptionController.text = _descriptionController
                              .text
                              .replaceAll(' Cảm ơn nha 👍🫰', '');
                        }
                      }
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    height: 35,
                    decoration: BoxDecoration(
                      color: _isSelectedSecondDesHint
                          ? Colors.pink.shade100.withValues(alpha: 0.5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        width: 1,
                        color: _isSelectedSecondDesHint
                            ? Colors.pink
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(left: 5, right: 5),
                      child: Text(
                        'Cảm ơn nha 👍🫰',
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
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

  Widget _buildContainerAmountHintButtonAndTranferButton(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            if (_isAmountFocus)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _amountHintOne != 'NAN'
                        ? GestureDetector(
                            onTap: () {
                              String newText = _amountHintOne!.isEmpty
                                  ? '1.000'
                                  : _amountHintOne!.replaceAll('đ', '');

                              _amountController.value = TextEditingValue(
                                text: newText,
                                selection: TextSelection.collapsed(
                                  offset: newText.length,
                                ),
                              );

                              _handleAmountChanged(newText);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(5),
                                child: Text(
                                  _amountController.text.isEmpty
                                      ? '1.000đ'
                                      : _amountHintOne!,
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  SizedBox(width: 5),

                  Expanded(
                    child: _amountHintTwo != 'NAN'
                        ? GestureDetector(
                            onTap: () {
                              String newText = _amountHintThree!.isEmpty
                                  ? '100.000'
                                  : _amountHintThree!.replaceAll('đ', '');
                              _amountController.value = TextEditingValue(
                                text: newText,
                                selection: TextSelection.collapsed(
                                  offset: newText.length,
                                ),
                              );
                              _handleAmountChanged(newText);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(5),
                                child: Text(
                                  _amountController.text.isEmpty
                                      ? '10.000đ'
                                      : _amountHintTwo!,
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  SizedBox(width: 5),

                  Expanded(
                    child: _amountHintThree != 'NAN'
                        ? GestureDetector(
                            onTap: () {
                              String newText = _amountHintThree!.isEmpty
                                  ? '100.000'
                                  : _amountHintThree!.replaceAll('đ', '');
                              _amountController.value = TextEditingValue(
                                text: newText,
                                selection: TextSelection.collapsed(
                                  offset: newText.length,
                                ),
                              );
                              _handleAmountChanged(newText);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(5),
                                child: Text(
                                  _amountController.text.isEmpty
                                      ? '100.000đ'
                                      : _amountHintThree!,
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {},
              child: Container(
                alignment: Alignment.center,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(top: 8, bottom: 8),
                  child: Text(
                    "Chuyển tiền",
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  num _formatAmountToNum(String amount) {
    if (amount.isEmpty) return 0;
    final newAmount = amount.replaceAll('.', '');
    num amountNum = num.tryParse(newAmount) ?? 0;
    return amountNum;
  }

  void _handleAmountChanged(String value) {
    num amountNum = _formatAmountToNum(value);
    if (amountNum == 0) {
      setState(() {
        _amountHintOne = '';
        _amountHintTwo = '';
        _amountHintThree = '';
        _msg = 'Vui lòng nhập số tiền';
      });
    } else {
      if (amountNum < 1001) {
        setState(() => _msg = 'Số tiền tối thiểu là 1000đ');
      } else if (amountNum > 50000000) {
        setState(() => _msg = 'Số tiền tối đa là 50.000.000đ');
      } else {
        setState(() => _msg = '');
      }

      setState(() {
        _amountHintOne = _calculateHint(amountNum, 1000, 10);
        _amountHintTwo = _calculateHint(amountNum, 10000, 100);
        _amountHintThree = _calculateHint(amountNum, 100000, 1000);
      });
    }
  }
}

String _formatDisplayNumber(num amount) {
  if (amount == 0) return '0';

  String numberString = amount.toStringAsFixed(0);
  final buffer = StringBuffer();

  for (int i = 0; i < numberString.length; i++) {
    buffer.write(numberString[i]);
    int nonZeroIndex = numberString.length - 1 - i;
    if (nonZeroIndex % 3 == 0 && nonZeroIndex != 0) {
      buffer.write('.');
    }
  }
  return buffer.toString();
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
    return '${_formatDisplayNumber(calculatedAmount)}đ';
  }

  return 'NAN';
}

class CurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');

    String numbericOnly = newValue.text
        .replaceAll(RegExp(r'[^0-9]'), '')
        .replaceFirst(RegExp(r'^0+'), '');
    if (numbericOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final buffer = StringBuffer();
    for (int i = 0; i < numbericOnly.length; i++) {
      buffer.write(numbericOnly[i]);
      int nonZeroIndex = numbericOnly.length - 1 - i;
      if (nonZeroIndex % 3 == 0 && nonZeroIndex != 0) {
        buffer.write('.');
      }
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.toString().length),
    );
  }
}
