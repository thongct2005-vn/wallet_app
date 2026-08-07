import 'package:app/core/utils/currency_formatter.dart';
import 'package:app/core/utils/format_utils.dart';
import 'package:app/src/transfer/confirm_tranfer_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/src/services/wallet_service.dart';

class AmountInputScreen extends StatefulWidget {
  final String? receiverPhone;
  final String? receiverFullName;
  final String? receiverId;
  const AmountInputScreen({
    super.key,
    this.receiverPhone,
    this.receiverFullName,
    this.receiverId,
  });
  @override
  State<AmountInputScreen> createState() => _AmountInputScreenState();
}

class _AmountInputScreenState extends State<AmountInputScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final WalletService _walletService = WalletService();
  bool _isSelectedFirstDesHint = false;
  bool _isSelectedSecondDesHint = false;
  String? _msg = '';
  String? _amountHintOne = '';
  String? _amountHintTwo = '';
  String? _amountHintThree = '';
  bool _isAmountFocus = false;
  String _walletBalance = '0';
  bool _isLoading = false;
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
              height: 500,
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
                  _buildContainerAmountHintButtonAndTranferButton(context),
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
                FormatUtils.formatAvatar(widget.receiverFullName??"?"),
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
                  widget.receiverFullName ?? "Không rõ tên",
                  style: GoogleFonts.roboto(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  widget.receiverPhone ?? "***",
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
    final bool _isEnable = _amountController.text.isNotEmpty && _msg == '';
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
                              String newText = _amountHintTwo!.isEmpty
                                  ? '10.000'
                                  : _amountHintTwo!.replaceAll('đ', '');
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
              onTap: _isEnable
                  ? () async {
                      setState(() {
                        _isLoading = true;
                      });
                      final result = await _walletService
                          .checkTransferEligibility(_amountController.text);
                      setState(() {
                        _isLoading = false;
                      });
                      if (!result['has_error']) {
                        if (!result['is_eligible']) {
                          setState(() {
                            _msg = 'Số dư trong ví không đủ';
                          });
                        } else {
                          setState(() {
                            _walletBalance = result['wallet_balance'];
                          });
                        }
                      } else {
                        _msg = 'Hệ thống đang bảo trì. Vui lòng thử lại sau';
                      }
                      if (!context.mounted) return;
                      if (_msg!.isEmpty) {
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
                            ),
                          ),
                        );
                      }
                    }
                  : null,
              child: Container(
                alignment: Alignment.center,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _isEnable
                      ? _isLoading
                            ? Colors.black.withValues(alpha: 0.1)
                            : Colors.pinkAccent
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(top: 8, bottom: 8),
                  child: _isLoading
                      ? SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),)
                      : Text(
                          "Chuyển tiền",
                          style: GoogleFonts.roboto(
                            color: _isEnable
                                ? Colors.white
                                : Colors.grey.withValues(alpha: 0.5),
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

  void _handleAmountChanged(String value) {
    num amountNum = FormatUtils.formatAmountToNum(value);
    if (amountNum == 0) {
      setState(() {
        _amountHintOne = '';
        _amountHintTwo = '';
        _amountHintThree = '';
        _msg = 'Vui lòng nhập số tiền';
      });
    } else {
      if (amountNum < 1000) {
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
